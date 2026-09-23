#!/usr/bin/env bash
# prepare the repo for a spec-driven task (cwd = repo root)
# kept out of the flow yaml: the framework runs a command node in the run folder
# instead of the repo when the command text mentions the runtime scratch dir
set -euo pipefail

mkdir -p specs/changes tests
if [ ! -f specs/governance.md ]; then
  cp /app/checks/governance.md specs/governance.md
  echo "seeded specs/governance.md"
fi
# runtime scratch must never be published, even if an agent writes it into the repo
for p in .hgsdlc/ test-results/; do
  grep -qxF "$p" .gitignore 2>/dev/null || { echo "$p" >> .gitignore; echo "gitignore: $p"; }
done
echo "governance principles:"
grep -E '^\| G-' specs/governance.md | cut -d'|' -f2,3
