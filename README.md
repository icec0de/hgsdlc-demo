# HG SDLC demo: intent → code → live site

A 30-second walkthrough is in [screencast/hgsdlc_screencast.mp4](screencast/hgsdlc_screencast.mp4).

Three containers share one folder (`./shared`):

| Tab | URL | Container | What it is |
|---|---|---|---|
| 1 | http://localhost:8081 | `taskboard` | Simple kanban board (New / To do / In progress / Need review / Done). Each task has a reporter, the task text and a date/time. |
| 2 | http://localhost:8080 | `framework` | [Human Guided SDLC](https://gitverse.ru/kakvsbere/hgsdlc) (backend and UI) with the OpenCode CLI connected to OpenRouter. Log in as `admin` / `admin`. |
| 3 | http://localhost:8082 | `webapp` | The client-facing web app ("Acme Coffee") that the framework changes. |

```
task board ──(REST: launch run)──▶ HG SDLC ──(git push main)──▶ git://webapp/webapp.git ──▶ nginx serves it
     ▲                                  │
     └──────(polls run status)──────────┘
```

## Run

```bash
git clone --recurse-submodules https://github.com/icec0de/hgsdlc-demo.git && cd hgsdlc-demo
cp .env.example .env        # put your OpenRouter key in it
make start                  # build if needed, start, wait until ready, open the 3 tabs in Safari
make stop                   # stop the containers; containers and all data are kept
make restart                # stop + start; nothing is lost
make reset                  # asks for confirmation, then removes containers AND wipes all data
```

Other targets: `make open` (reopen the tabs), `make status`, `make logs`.

You need Docker; on macOS OrbStack works. `make start` fetches the framework submodule if it's missing. The first build takes about 5 minutes, because it compiles the framework from `./hgsdlc`.

## Demo script

1. **Tab 1:** add a task, for example *"Add a 'Contact us' button next to 'Order now'"* or *"Make the Order button green"*. It lands in **New**.
2. Drag the card to **To do**. Within about 3 seconds the framework picks it up and the card moves to **In progress**. Its **open run ↗** link opens that run in tab 2.
3. **Tab 2:** the Run Console shows the flow graph, the live agent log, artifacts (`change-summary.md`), the diff and the audit trail.
4. When the run finishes, the framework commits and pushes to `main`. **Tab 3** reloads itself with the change, and the card moves to **Done**.
5. If the run fails, nothing is published and the card goes to **Need review** with the error code. From there, drag it back to **To do** to retry, or to **Done** to accept it.

Done and Need review cards show the run's duration and token usage (total, input including cached, and output), as reported by the framework.

Tasks run one at a time in the order they were created.

## What is where

```
framework/
  Dockerfile              builds hgsdlc (backend + UI) and installs OpenCode CLI
  entrypoint.sh           points opencode at OpenRouter, starts the backend, runs setup.sh
  setup.sh                configures the framework through its REST API:
                          runtime agent/model, flow, SCM provider, project
  flow/webapp-change.yaml the flow: implement (AI) → smoke-check (command) → finish
taskboard/
  app.py                  board + bridge (python stdlib, no deps)
  index.html              board UI
webapp/
  site/                   initial web app (seeded into the git repo on first start)
  sync.sh                 creates the repo, runs git daemon, checks out main into shared/site
hgsdlc/                   framework source: git submodule of gitverse.ru/kakvsbere/hgsdlc (pinned commit)
shared/                   all state, created at runtime (make reset deletes it)
  webapp.git              the web app's git repo (the framework clones and pushes here)
  site/                   what nginx serves
  board/tasks.json        board data
  framework/db            framework database (H2 file)
  framework/workspace     framework run workspaces (logs, artifacts)
```

## Notes

- **Model:** set `MODEL` in `.env` to any OpenRouter model ID. The default is `z-ai/glm-5.3`. For faster runs, try `z-ai/glm-5.3-flash`. The framework uses whatever model the agent reports over ACP. If `MODEL` isn't in that list, setup prints a warning and the board shows the launch error.
- **Coding agent:** OpenCode, not Qwen. The framework's stock Qwen image only offers Qwen's own OAuth model over ACP, so it can't use an OpenRouter key.
- **Human gate:** to add a human approval step, insert a `human_approval` node between `smoke-check` and `finish` in `framework/flow/webapp-change.yaml`. Approvals then appear in the framework's Gates inbox, and the card shows `waiting_gate` while it waits.
- **Persistence:** all state lives in `./shared` on your Mac: the web app repo (`webapp.git`) and what nginx serves (`site/`), the board (`board/tasks.json`), and the framework's database and run workspaces (`framework/`). `stop`, `restart` and rebuilding the images keep all of it, including run history and **open run ↗** links. Only `make reset` wipes it.
- **Changing the flow:** setup only publishes the flow if that version isn't published yet. After editing `framework/flow/webapp-change.yaml`, bump `version` and `canonical_name`, and set `FLOW` for the board in `docker-compose.yml` to the new version.
- **Lost runs:** if a run is ever lost, for example after a reset of the framework data only, its card moves to **Need review** ("run lost: framework restarted").
- **Deviations from a stock install:** the flow is team-scoped, so it's published straight to the framework DB without a git catalog or PR. The SCM provider is a placeholder whose host (`webapp`) matches the `git://` repo URL. The framework applies credentials only to http(s) remotes.

The design, decisions and scope are in [spec.md](spec.md).

## License

Copyright 2026 icec0de. Licensed under the [Apache License 2.0](LICENSE).

The framework in `hgsdlc/` is a separate project ([Human Guided SDLC](https://gitverse.ru/kakvsbere/hgsdlc)), also under Apache 2.0.
