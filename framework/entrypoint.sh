#!/usr/bin/env bash
# start HG SDLC, then configure it for the demo (agent, flow, project)
# state lives in /shared/framework (see docker-compose.yml)
set -euo pipefail

: "${OPENROUTER_API_KEY:?set OPENROUTER_API_KEY in .env}"
export OPENROUTER_API_KEY
# opencode model ids are <provider>/<model>
export AGENT_MODEL="openrouter/${MODEL:-z-ai/glm-5.3}"

# opencode cli: only the openrouter provider, key comes from OPENROUTER_API_KEY
cat > "${HOME}/.config/opencode/opencode.json" <<JSON
{
  "\$schema": "https://opencode.ai/config.json",
  "enabled_providers": ["openrouter"],
  "model": "${AGENT_MODEL}",
  "autoupdate": false,
  "share": "disabled",
  "permission": { "edit": "allow", "bash": "allow" }
}
JSON
echo "opencode $(opencode --version | head -n1), model ${AGENT_MODEL}"

java ${JAVA_OPTS:-} -jar /app/app.jar &
JAVA_PID=$!
trap 'kill -TERM ${JAVA_PID} 2>/dev/null' TERM INT

# markers for `make start`; /tmp survives container stop/start, so clear old ones first
rm -f /tmp/setup.done /tmp/setup.failed
mkdir -p /shared/framework/workspace
if /app/setup.sh; then touch /tmp/setup.done; else echo "!!! demo setup failed, see log above"; touch /tmp/setup.failed; fi
wait ${JAVA_PID}
