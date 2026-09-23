"""Primitive kanban board + bridge to the HG SDLC framework.

Board: New / To do / In progress / Need review / Done,
each task = reporter, task text, timestamp.
Humans drag cards between New, To do, Need review and Done;
In progress belongs to the framework.
Bridge: picks the oldest "to do" task, launches a framework run with the task
text as the feature request, follows the run and moves the card to Done
(published) or Need review (run failed, nothing published).
Python stdlib only; data lives in /shared/board/tasks.json.
"""
import json
import os
import threading
import time
import traceback
import urllib.error
import urllib.request
import uuid
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

DATA = Path(os.environ.get("BOARD_DATA", "/shared/board/tasks.json"))
API = os.environ.get("FRAMEWORK_API", "http://framework:8080/api")
PUBLIC_URL = os.environ.get("FRAMEWORK_PUBLIC_URL", "http://localhost:8080")
PROJECT_NAME = os.environ.get("PROJECT_NAME", "demo-webapp")
FLOW = os.environ.get("FLOW", "webapp-change@1.0")
POLL = float(os.environ.get("POLL_SECONDS", "3"))
GATE_MODE = os.environ.get("GATE_MODE", "require_all_gates")

lock = threading.Lock()


# ---------- storage ----------

def load():
    try:
        return json.loads(DATA.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return []


def save(tasks):
    DATA.parent.mkdir(parents=True, exist_ok=True)
    tmp = DATA.with_suffix(".tmp")
    tmp.write_text(json.dumps(tasks, indent=2, ensure_ascii=False))
    tmp.replace(DATA)


def update(task_id, **fields):
    with lock:
        tasks = load()
        for t in tasks:
            if t["id"] == task_id:
                t.update(fields)
        save(tasks)


# ---------- framework client ----------

class Framework:
    def __init__(self):
        self.token = None
        self.project_id = None

    def request(self, method, path, body=None, auth=True):
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(API + path, data=data, method=method)
        req.add_header("Content-Type", "application/json")
        req.add_header("Idempotency-Key", str(uuid.uuid4()))
        if auth:
            req.add_header("Authorization", f"Bearer {self.token}")
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                raw = r.read()
        except urllib.error.HTTPError as e:
            if e.code == 401 and auth:
                self.token = None
            raise RuntimeError(f"{method} {path} -> {e.code}: {e.read().decode()[:500]}") from None
        payload = json.loads(raw) if raw else None
        # the framework wraps every /api response as {"status": "ok", "data": ..., "meta": ...}
        if isinstance(payload, dict) and payload.get("status") == "ok" and "data" in payload:
            payload = payload["data"]
        return payload

    def ready(self):
        if not self.token:
            self.token = self.request("POST", "/auth/login",
                                      {"username": "admin", "password": "admin"}, auth=False)["token"]
        if not self.project_id:
            projects = self.request("GET", "/projects")
            items = projects if isinstance(projects, list) else projects.get("items", [])
            match = [p for p in items if p.get("name") == PROJECT_NAME]
            if not match:
                raise RuntimeError(f"project {PROJECT_NAME} not configured yet")
            self.project_id = match[0]["id"]

    def launch(self, task):
        self.ready()
        request = (f"{task['task']}\n\n"
                   f"(reported by {task['reporter']} at {task['created_at']})")
        run = self.request("POST", "/runs", {
            "project_id": self.project_id,
            "flow_canonical_name": FLOW,
            "feature_request": request,
            "publish_mode": "direct_push",            # straight to main -> live site
            "ai_session_mode": "isolated_attempt_sessions",
            "gate_mode": GATE_MODE,
        })
        return run["run_id"]

    def run(self, run_id):
        self.ready()
        return self.request("GET", f"/runs/{run_id}")


fw = Framework()
FAILED = {"FAILED", "CRASHED", "CANCELLED", "PUBLISH_FAILED"}
MANUAL = {"new", "todo", "review", "done"}  # columns a human may drop a card into


def bridge():
    while True:
        try:
            tick()
        except Exception as e:  # keep the loop alive, show the reason on the board
            print("[bridge]", e, flush=True)
            if not isinstance(e, RuntimeError):
                traceback.print_exc()
        time.sleep(POLL)


def tick():
    tasks = load()
    active = [t for t in tasks if t["status"] == "in_progress"]
    for t in active:
        try:
            run = fw.run(t["run_id"])
        except RuntimeError as e:
            if "-> 404" not in str(e):
                raise
            # the framework keeps runs in memory: a restart mid-run loses the run
            update(t["id"], status="review", note="run lost: framework restarted", failed=True, finished_at=now())
            continue
        status = (run.get("status") or "?").upper()
        node = run.get("current_node_id") or ""
        if status == "COMPLETED":
            update(t["id"], status="done", note="published", finished_at=now(), stats=stats(run))
        elif status in FAILED:
            reason = run.get("error_code") or status.lower()
            update(t["id"], status="review", note=f"failed: {reason}", failed=True, finished_at=now(),
                   stats=stats(run))
        else:
            update(t["id"], note=f"{status.lower()}{' · ' + node if node else ''}")
    for t in tasks:  # backfill stats for cards finished before stats (or cached-token counts) existed
        st = t.get("stats")
        stale = st is None or ("tokens_total" in st and "tokens_cached" not in st)
        if t["status"] in ("done", "review") and t.get("run_id") and stale:
            try:
                update(t["id"], stats=stats(fw.run(t["run_id"])))
            except RuntimeError:  # run no longer known (framework restarted)
                update(t["id"], stats={})
    if active:
        return  # one change at a time: every run edits the same repo
    todo = [t for t in tasks if t["status"] == "todo"]
    if todo:
        t = min(todo, key=lambda x: x["created_at"])
        update(t["id"], note="handing to framework…")
        try:
            run_id = fw.launch(t)
        except Exception as e:
            update(t["id"], note=f"waiting for framework: {str(e)[:160]}")
            raise
        update(t["id"], status="in_progress", run_id=run_id,
               run_url=f"{PUBLIC_URL}/run-console?runId={run_id}", note="run created")


def stats(run):
    """run duration and token usage as reported by the framework"""
    out = {}
    start = run.get("started_at") or run.get("created_at")
    end = run.get("finished_at")
    if start and end:
        parse = lambda v: datetime.fromisoformat(v.replace("Z", "+00:00"))
        out["duration_s"] = round((parse(end) - parse(start)).total_seconds())
    usage = run.get("token_usage") or {}
    if usage.get("known"):
        cached = sum(usage.get(k, 0) for k in
                     ("cached_input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))
        out["tokens_in"] = usage.get("input_tokens", 0) + cached
        out["tokens_cached"] = cached
        out["tokens_out"] = usage.get("output_tokens", 0)
        out["tokens_total"] = usage.get("total_tokens", 0)
    return out


def now():
    return datetime.now().astimezone().isoformat(timespec="seconds")


# ---------- web ----------

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def send(self, code, body, ctype="application/json"):
        data = body if isinstance(body, bytes) else body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/api/tasks":
            self.send(200, json.dumps(load(), ensure_ascii=False))
        elif self.path in ("/", "/index.html"):
            self.send(200, (Path(__file__).parent / "index.html").read_bytes(), "text/html; charset=utf-8")
        else:
            self.send(404, '{"error":"not found"}')

    def do_POST(self):
        if self.path != "/api/tasks":
            return self.send(404, '{"error":"not found"}')
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
        reporter = (body.get("reporter") or "").strip()
        text = (body.get("task") or "").strip()
        if not reporter or not text:
            return self.send(400, '{"error":"reporter and task are required"}')
        task = {
            "id": uuid.uuid4().hex[:8],
            "reporter": reporter,
            "task": text,
            "created_at": body.get("created_at") or now(),
            "status": "new",
            "note": "",
        }
        with lock:
            tasks = load()
            tasks.append(task)
            save(tasks)
        self.send(201, json.dumps(task, ensure_ascii=False))

    def do_PATCH(self):  # manual move: {"status": "todo" | ...}
        task_id = self.path.rsplit("/", 1)[-1]
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
        target = body.get("status")
        if target not in MANUAL:
            return self.send(400, '{"error":"status must be one of new, todo, review, done"}')
        with lock:
            tasks = load()
            task = next((t for t in tasks if t["id"] == task_id), None)
            if not task:
                return self.send(404, '{"error":"not found"}')
            if task["status"] == "in_progress":
                return self.send(409, '{"error":"task is being worked on by the framework"}')
            if target == "todo" and task["status"] != "todo":
                # (re)queue: forget the previous run
                for k in ("run_id", "run_url", "failed", "finished_at", "stats"):
                    task.pop(k, None)
                task["note"] = ""
            elif target == "done" and task["status"] == "review":
                task["note"] = "accepted by reviewer"
                task.pop("failed", None)
            task["status"] = target
            save(tasks)
        self.send(200, json.dumps(task, ensure_ascii=False))

    def do_DELETE(self):
        task_id = self.path.rsplit("/", 1)[-1]
        with lock:
            save([t for t in load() if not (t["id"] == task_id and t["status"] in ("new", "todo"))])
        self.send(204, b"")


if __name__ == "__main__":
    threading.Thread(target=bridge, daemon=True).start()
    port = int(os.environ.get("PORT", "8081"))
    print(f"task board on :{port}, framework api {API}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
