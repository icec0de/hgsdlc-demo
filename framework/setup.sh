#!/usr/bin/env bash
# demo configuration through the framework's own REST API
# runs on every start: settings are re-applied (so .env changes take effect),
# flow / scm provider / project are only created when missing
set -euo pipefail

API=http://127.0.0.1:8080/api
MODEL="${AGENT_MODEL:-openrouter/z-ai/glm-5.3}"
REPO_URL="${WEBAPP_REPO:-git://webapp/webapp.git}"
REPO_HOST=$(echo "$REPO_URL" | sed -E 's#^[a-z]+://([^/:]+).*#\1#')
PROJECT_NAME="${PROJECT_NAME:-demo-webapp}"

log() { echo "[setup] $*"; }

call() { # method path [json]  (as $TOKEN)
  local args=(-sS --fail-with-body -X "$1" "$API$2" -H "Authorization: Bearer $TOKEN"
    -H 'Content-Type: application/json' -H "Idempotency-Key: $(cat /proc/sys/kernel/random/uuid)")
  [ -n "${3:-}" ] && args+=(-d "$3")
  local out
  if ! out=$(curl "${args[@]}"); then echo "[setup] $1 $2 failed: $out" >&2; return 1; fi
  echo "$out"
}

log "waiting for backend"
until curl -fsS "${API%/api}/actuator/health" >/dev/null 2>&1; do sleep 2; done
TOKEN=$(curl -fsS -X POST "$API/auth/login" -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin"}' | jq -r '.data.token')

log "runtime: coding agent opencode, model ${MODEL}"
# materialized into each run workspace as opencode.json
AGENT_SETTINGS=$(jq -n --arg m "$MODEL" '{
  "$schema": "https://opencode.ai/config.json",
  model: $m,
  permission: {edit: "allow", bash: "allow", skill: {"*": "allow"}}
}' | jq -c . | jq -Rs .)
call PUT /settings/runtime "{
  \"workspace_root\": \"${WORKSPACE_ROOT:-/tmp/workspace}\",
  \"coding_agent\": \"opencode\",
  \"default_coding_model\": \"${MODEL}\",
  \"agent_launch_command\": \"opencode acp\",
  \"agent_settings_json\": ${AGENT_SETTINGS},
  \"agent_settings_json_enabled\": true,
  \"ai_timeout_seconds\": 900,
  \"disk_min_free_gb\": 0,
  \"prompt_language\": \"en\"
}" >/dev/null

# the framework picks the model from the list the agent reports over ACP;
# fail loudly instead of silently running on another model
if ! call GET "/settings/coding-agent/models?coding_agent=opencode" | jq -e --arg m "$MODEL" '[.data.models[]? | (.model_id // .id // .name)] | index($m)' >/dev/null; then
  echo "[setup] WARNING: ${MODEL} is not in the models opencode reports:" >&2
  call GET "/settings/coding-agent/models?coding_agent=opencode" | jq -c '.data' | cut -c1-600 >&2
fi

log "git identity for published commits"
call PUT /settings/catalog '{"publish_mode":"local","local_git_username":"hgsdlc-bot","local_git_email":"bot@hgsdlc.local"}' >/dev/null

# team scope: flows live in the framework db, no git catalog / PR needed
# every framework/flow/*.yaml is published; to change one, bump version and canonical_name
for FLOW_FILE in /app/flow/*.yaml; do
  FLOW_ID=$(sed -nE 's/^id: *"?([^"]*)"?$/\1/p' "$FLOW_FILE")
  FLOW_VERSION=$(sed -nE 's/^version: *"?([^"]*)"?$/\1/p' "$FLOW_FILE")
  if call GET "/flows/${FLOW_ID}/versions" 2>/dev/null \
      | jq -e --arg v "$FLOW_VERSION" '.data[] | select(.version == $v and .status == "published")' >/dev/null; then
    log "flow: ${FLOW_ID}@${FLOW_VERSION} already published"
    continue
  fi
  log "flow: ${FLOW_ID}@${FLOW_VERSION}"
  FLOW_YAML=$(jq -Rs . < "$FLOW_FILE")
  call POST "/flows/${FLOW_ID}/save" "{
    \"flow_id\": \"${FLOW_ID}\",
    \"coding_agent\": \"opencode\",
    \"platform_code\": \"FRONT\",
    \"resource_version\": 0,
    \"flow_kind\": \"delivery\",
    \"risk_level\": \"low\",
    \"scope\": \"team\",
    \"tags\": [\"demo\"],
    \"flow_yaml\": ${FLOW_YAML},
    \"publish\": true,
    \"release\": true
  }" >/dev/null
done

# every project needs an SCM provider whose host matches the repo url;
# git:// urls get no credentials, so the token is a placeholder
SCM_ID=$(call GET /settings/scm-providers | jq -r '[.data[]? | select(.name == "demo-git") | .id][0] // empty')
if [ -n "$SCM_ID" ]; then
  log "scm provider: demo-git already exists"
else
  log "scm provider: ${REPO_HOST}"
  SCM_ID=$(call POST /settings/scm-providers "{
    \"name\": \"demo-git\",
    \"scm_provider\": \"gitea\",
    \"api_base_url\": \"http://${REPO_HOST}\",
    \"username\": \"hgsdlc-bot\",
    \"api_token\": \"unused\"
  }" | jq -r '.data.id')
fi

if call GET /projects | jq -e --arg n "$PROJECT_NAME" \
    '[.data | if type == "array" then .[] else .items[]? end | select(.name == $n)] | length > 0' >/dev/null; then
  log "project: ${PROJECT_NAME} already exists"
else
  log "project: ${PROJECT_NAME} -> ${REPO_URL}"
  call POST /projects "{
    \"scm_provider_id\": \"${SCM_ID}\",
    \"name\": \"${PROJECT_NAME}\",
    \"description\": \"Client-facing web app changed by tasks from the board\",
    \"repositories\": [{\"alias\": \"main\", \"repo_url\": \"${REPO_URL}\", \"default_branch\": \"main\"}]
  }" >/dev/null
fi

log "done - framework ready at http://localhost:${FRAMEWORK_PORT:-8080} (admin / admin)"
