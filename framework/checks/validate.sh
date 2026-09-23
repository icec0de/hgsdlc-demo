#!/usr/bin/env bash
# deterministic validation of one task against specs/governance.md
# usage: validate.sh <TASK_ID> <TASK_DIR>   (cwd = run workspace = repo root)
# writes specs/changes/<TASK_DIR>/validation.md and validation.json, exits 1 if any principle fails
set -uo pipefail

TASK_ID="$1"
TASK_DIR="$2"
CHANGE="specs/changes/${TASK_DIR}"
DELTA="${CHANGE}/delta.md"
TEST_FILE="tests/${TASK_ID}.spec.js"
CHECKS=/app/checks
RESULTS=$(mktemp)
mkdir -p "$CHANGE"
rm -rf test-results  # scratch output of older runs, never part of the repo

echo "== running scenario tests (all tasks) and governance tests"
RESULTS_JSON="$RESULTS" playwright test -c "$CHECKS/playwright.config.js" 2>&1 | tail -40

# flat list of tests: title, project, file, ok
TESTS=$(jq '[.. | objects | select(has("specs")) | .specs[]
  | {title: .title, file: (.file | split("/") | last), ok: .ok, project: (.tests[0].projectName // "")}]' \
  "$RESULTS" 2>/dev/null || echo '[]')

results=()   # "id|status|evidence"
add() { results+=("$1|$2|$3"); }

# G-01 page language is Russian
g01=$(jq -r '[.[] | select(.project == "governance" and (.title | startswith("G-01")))] | if length == 0 then "missing" elif all(.ok) then "pass" else "fail" end' <<<"$TESTS")
case "$g01" in
  pass) add G-01 pass 'governance test passed: lang="ru", visible text is Russian' ;;
  missing) add G-01 fail 'governance test did not run (page failed to load?)' ;;
  *) add G-01 fail 'governance test failed: lang attribute or share of Cyrillic text (see node log)' ;;
esac

# G-02 no external scripts / stylesheets
ext=$(grep -EoiH '<(script|link)[^>]+(src|href)="(https?:)?//[^"]+"' ./*.html 2>/dev/null | head -3 || true)
if [ -z "$ext" ]; then add G-02 pass 'no <script>/<link> pointing to another host'
else add G-02 fail "external resources: $(echo "$ext" | tr '\n' ' ')"; fi

# G-03 every scenario of the delta has a passing test "<TASK_ID>: <scenario>"
if [ ! -f "$TEST_FILE" ]; then
  add G-03 fail "no test file ${TEST_FILE}"
else
  total=0; covered=0; missing=()
  while IFS= read -r scenario; do
    [ -z "$scenario" ] && continue
    total=$((total + 1))
    if jq -e --arg t "${TASK_ID}: ${scenario}" \
        '[.[] | select((.title | ascii_downcase | gsub("\\s+"; " ")) == ($t | ascii_downcase | gsub("\\s+"; " ")) and .ok)] | length > 0' \
        <<<"$TESTS" >/dev/null; then
      covered=$((covered + 1))
    else
      missing+=("$scenario")
    fi
  done < <(sed -nE 's/^#### Scenario: *(.*[^ ]) *$/\1/p' "$DELTA" 2>/dev/null)
  if [ "$total" -eq 0 ]; then add G-03 pass 'delta spec has no scenarios (nothing to test)'
  elif [ "$covered" -eq "$total" ]; then add G-03 pass "${covered}/${total} scenarios have a passing test in ${TEST_FILE}"
  else add G-03 fail "${covered}/${total} scenarios covered; failing or missing: $(IFS='; '; echo "${missing[*]}")"; fi
fi

# G-04 regression: tests of earlier tasks
read -r reg_total reg_ok <<<"$(jq -r --arg f "${TASK_ID}.spec.js" \
  '[.[] | select(.project == "scenarios" and .file != $f)] | "\(length) \([.[] | select(.ok)] | length)"' <<<"$TESTS")"
if [ "$reg_total" -eq 0 ]; then add G-04 pass 'no earlier tests yet'
elif [ "$reg_ok" -eq "$reg_total" ]; then add G-04 pass "${reg_ok}/${reg_total} tests of earlier tasks pass"
else add G-04 fail "${reg_ok}/${reg_total} tests of earlier tasks pass: $(jq -r --arg f "${TASK_ID}.spec.js" '[.[] | select(.project == "scenarios" and .file != $f and (.ok | not)) | .title] | join("; ")' <<<"$TESTS")"; fi

# G-05 spec before code (merge into master is checked by record-increment)
if [ -s "$DELTA" ]; then add G-05 pass "delta spec ${DELTA} present before merge"
else add G-05 fail "no delta spec at ${DELTA}"; fi

all_total=$(jq 'length' <<<"$TESTS")
all_ok=$(jq '[.[] | select(.ok)] | length' <<<"$TESTS")
failed=$(printf '%s\n' "${results[@]}" | grep -c '|fail|' || true)
verdict=$([ "$failed" -eq 0 ] && echo passed || echo failed)

# machine-readable record (read by the task board)
printf '%s\n' "${results[@]}" | jq -R 'split("|") | {id: .[0], status: .[1], evidence: .[2]}' | jq -s \
  --arg task "$TASK_ID" --arg verdict "$verdict" --argjson total "$all_total" --argjson ok "$all_ok" \
  --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{task: $task, verdict: $verdict, validated_at: $at, tests: {total: $total, passed: $ok}, principles: .}' \
  > "${CHANGE}/validation.json"

# human-readable record
{
  echo "# ${TASK_ID} validation"
  echo
  echo "verdict: **${verdict}** · tests ${all_ok}/${all_total} passed · validated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo "Principles from specs/governance.md, checked by the framework (not by the AI)."
  echo
  echo "| id | principle | result | evidence |"
  echo "|---|---|---|---|"
  for r in "${results[@]}"; do
    IFS='|' read -r id status evidence <<<"$r"
    principle=$(sed -nE "s/^\| ${id} \| ([^|]*) \|.*/\1/p" specs/governance.md | sed 's/ *$//')
    mark=$([ "$status" = pass ] && echo "✅ pass" || echo "❌ fail")
    echo "| ${id} | ${principle} | ${mark} | ${evidence} |"
  done
  echo
  echo "## Tests"
  echo
  jq -r '.[] | "- \(if .ok then "✅" else "❌" end) \(.title) (\(.file))"' <<<"$TESTS"
} > "${CHANGE}/validation.md"

cat "${CHANGE}/validation.md"
rm -f "$RESULTS"
[ "$verdict" = passed ]
