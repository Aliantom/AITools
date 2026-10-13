# run-agent-loop.sh (as Markdown)

This is the loop harness from `qta-autonomous-run-kit.md` §8, packaged as Markdown because `.sh` downloads are blocked.
The script inside the four-backtick block below is byte-for-byte the same as the one embedded in the kit.

## Get the script out: pick one way

**A. Let the agent do it (easiest).** In your agent session:

```text
Create scripts/run-agent-loop.sh with exactly the contents of the ````bash block in
docs/proposals/run-agent-loop.md (no edits, LF line endings), then chmod +x it and run bash -n on it.
```

**B. One command (awk).** Run from the repo root, with this file saved as `docs/proposals/run-agent-loop.md`:

```bash
mkdir -p scripts
awk '/^````bash$/{f=1;next} /^````$/{f=0} f' docs/proposals/run-agent-loop.md > scripts/run-agent-loop.sh
sed -i 's/\r$//' scripts/run-agent-loop.sh        # strip Windows line endings, if any crept in
chmod +x scripts/run-agent-loop.sh && bash -n scripts/run-agent-loop.sh && echo "syntax OK"
```

**C. Copy and paste.** Copy everything between the ````bash and ```` lines into `scripts/run-agent-loop.sh`, then run the `sed`, `chmod` and `bash -n` lines from B.

## Check it arrived intact

```bash
sha256sum scripts/run-agent-loop.sh
# expected: 3923c6396ff327877d1ccdf2798bec56c2cde9782dc57e4e99585bc4c57417ec
```

If the hash differs but `bash -n` passes, the usual cause is line endings or a trailing newline from copy and paste. The `sed` line fixes the first. After that, a small difference is harmless, so long as nothing but whitespace changed.

## The script

````bash
#!/usr/bin/env bash
# run-agent-loop.sh — unattended work loop for the QTA MCP repo.
#
# One Claude Code headless run = one iteration = one thin slice of work. State lives in files
# (docs/proposals/*), so every iteration starts with a fresh context and nothing depends on a
# single long conversation. The harness independently re-runs the tests after every iteration;
# if they fail it snapshots the work to an agent-failed/* branch and resets to the last green commit.
#
# Run from the repo root, on a dedicated agent branch, ideally inside tmux on an isolated dev VM.
#   tmux new -s agent
#   MAX_ITERATIONS=12 MAX_HOURS=5 ./scripts/run-agent-loop.sh
# Stop gracefully:  touch STOP_AGENT   (the current iteration finishes first)
# Steer mid-run:     edit .agent-runs/STEERING.md (read by the agent at the start of every iteration)
set -uo pipefail

# Run from a private copy: bash reads scripts lazily, so a checkout or reset that rewrites this
# file mid-run would otherwise change the code that is executing.
if [[ -z "${AGENT_HARNESS_COPY:-}" ]]; then
  _copy="$(mktemp "${TMPDIR:-/tmp}/run-agent-loop.XXXXXX")" && cp "$0" "$_copy" \
    && AGENT_HARNESS_COPY="$_copy" exec bash "$_copy" "$@"
  echo "could not make a private copy of $0" >&2; exit 1
fi
trap 'rm -f "$AGENT_HARNESS_COPY"' EXIT

# ---------- settings (override with environment variables) ----------
MAX_ITERATIONS="${MAX_ITERATIONS:-20}"
MAX_HOURS="${MAX_HOURS:-6}"
MAX_CONSECUTIVE_FAILURES="${MAX_CONSECUTIVE_FAILURES:-3}"
MAX_COST_USD="${MAX_COST_USD:-40}"               # client-side estimate; may read 0 for non-Anthropic models,
                                                  # so iteration and time limits are the real brakes
ITERATION_TIMEOUT_MIN="${ITERATION_TIMEOUT_MIN:-60}"
RETRO_EVERY="${RETRO_EVERY:-5}"                  # every Nth iteration the agent does a retrospective instead of a slice
MAX_IDLE_ITERATIONS="${MAX_IDLE_ITERATIONS:-3}"  # stop after N green iterations in a row with no new commit
ERROR_BACKOFF_SEC="${ERROR_BACKOFF_SEC:-120}"    # pause after a non-zero agent exit (rate limits, API hiccups)
MODEL="${MODEL:-}"                               # e.g. MODEL=laguna-s-2-1-512k-202607 ; empty = your configured default
USE_JSON_SCHEMA="${USE_JSON_SCHEMA:-0}"          # 1 = also request schema-enforced status; the text STATUS line always works
PROMPT_FILE="${PROMPT_FILE:-docs/proposals/AUTONOMOUS_RUN.md}"
SETTINGS_FILE="${SETTINGS_FILE:-.claude/agent-loop-settings.json}"
TEST_CMD="${TEST_CMD:-pytest -q}"
# prints the number of collected tests; the loop fails an iteration whose count drops (empty = skip check)
TEST_COUNT_CMD="${TEST_COUNT_CMD-pytest --collect-only -q 2>/dev/null | grep -Eo '[0-9]+ tests? collected' | grep -Eo '^[0-9]+'}"
# the agent must never change these; an iteration that does is treated as failed (space-separated pathspecs)
PROTECTED_PATHS="${PROTECTED_PATHS:-scripts/run-agent-loop.sh .claude docs/proposals/AUTONOMOUS_RUN.md}"
PERMISSION_MODE="${PERMISSION_MODE:-dontAsk}"    # dontAsk (allowlist only) or auto (if your org enables it)
EXTRA_FLAGS="${EXTRA_FLAGS:---permission-prompts none}"   # needs Claude Code >= 2.1.259; set EXTRA_FLAGS="" on older versions
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
AGENT_CMD="${AGENT_CMD:-}"                       # optional: run a different agent CLI instead of Claude Code.
                                                  # Runs via bash -c with PROMPT_FILE, MODEL, ITERATION in the env and
                                                  # must print the agent's final message (plain text or JSON) to stdout.
STOP_FILE="${STOP_FILE:-STOP_AGENT}"
BRANCH_PREFIX="${BRANCH_PREFIX:-agent/}"
RUNS_ROOT="${RUNS_ROOT:-.agent-runs}"
RUN_DIR="$RUNS_ROOT/$(date +%Y%m%d-%H%M%S)"
LAST_ITER_NOTE="$RUNS_ROOT/last-iteration.md"   # untracked; the prompt tells the agent to read it
STEERING_FILE="$RUNS_ROOT/STEERING.md"          # untracked, survives resets; you may edit it while the loop runs
PYTHON="${PYTHON:-python3}"

STATUS_SCHEMA='{"type":"object","properties":{"status":{"type":"string","enum":["continue","done","blocked","stop"]},"item":{"type":"string"},"summary":{"type":"string"},"tests_passed":{"type":"boolean"}},"required":["status","summary"]}'

log() { printf '%s  %s\n' "$(date '+%F %T')" "$*" | tee -a "$RUN_DIR/loop.log"; }
die() { echo "preflight: $*" >&2; exit 1; }
json_field() {  # json_field <file> <dotted.path> <default>
  "$PYTHON" - "$1" "$2" "$3" <<'PY'
import json, sys
path, key, default = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    obj = json.load(open(path))
    for part in key.split("."):
        obj = obj[part]
    print(obj if obj is not None else default)
except Exception:
    print(default)
PY
}
read_status() {  # read_status <file> -> prints status, item, summary on three lines
  # Prefers schema-enforced structured_output; falls back to the last plain-text line
  #   STATUS: <continue|done|blocked|stop> | ITEM: <id> | SUMMARY: <one line>
  # found in .result, so it works with any model behind Claude Code.
  "$PYTHON" - "$1" <<'PY'
import json, re, sys
status, item, summary = "unknown", "-", "(no summary)"
raw = open(sys.argv[1], errors="replace").read() if sys.argv[1] else ""
try:
    data = json.loads(raw)
    if not isinstance(data, dict):
        data = {"result": raw}
except Exception:
    data = {"result": raw}  # plain-text output from a non-JSON agent CLI
so = data.get("structured_output")
if isinstance(so, dict) and so.get("status"):
    status = str(so["status"]).lower()
    item = str(so.get("item") or "-")
    summary = str(so.get("summary") or summary)
else:
    text = data.get("result") or ""
    if not isinstance(text, str):
        text = json.dumps(text)
    pattern = re.compile(
        r"STATUS:\s*\**\s*(continue|done|blocked|stop)\b"
        r"(?:\s*\|\s*ITEM:\s*([^|\n]*))?"
        r"(?:\s*\|\s*SUMMARY:\s*([^\n]*))?",
        re.IGNORECASE,
    )
    last = None
    for last in pattern.finditer(text):
        pass
    if last:
        status = last.group(1).lower()
        item = (last.group(2) or "-").strip().strip("*`") or "-"
        summary = (last.group(3) or summary).strip().strip("*`") or summary
if status not in {"continue", "done", "blocked", "stop"}:
    status = "unknown"
print(status)
print(item.replace("\n", " ")[:120])
print(summary.replace("\n", " ")[:300])
PY
}

# ---------- preflight ----------
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git repository"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[[ "$BRANCH" == "$BRANCH_PREFIX"* ]] || die "current branch '$BRANCH' must start with '$BRANCH_PREFIX' (never run on main)"
[[ -f "$PROMPT_FILE" ]] || die "prompt file $PROMPT_FILE not found"
if [[ -z "$AGENT_CMD" ]]; then
  [[ -f "$SETTINGS_FILE" ]] || die "settings file $SETTINGS_FILE not found"
  command -v "$CLAUDE_BIN" >/dev/null 2>&1 || die "'$CLAUDE_BIN' not on PATH"
fi
command -v "$PYTHON" >/dev/null 2>&1 || die "'$PYTHON' not on PATH"
command -v timeout >/dev/null 2>&1 || die "'timeout' (coreutils) not on PATH"
mkdir -p "$RUN_DIR"
# keep harness logs out of commits without touching the repo's .gitignore
grep -qxF "$RUNS_ROOT/" .git/info/exclude 2>/dev/null || echo "$RUNS_ROOT/" >> .git/info/exclude
grep -qxF "$STOP_FILE" .git/info/exclude 2>/dev/null || echo "$STOP_FILE" >> .git/info/exclude
[[ -z "$(git status --porcelain)" ]] || die "working tree not clean; commit or stash first"
rm -f "$STOP_FILE"
# freeze the prompt and settings for this run so a mid-run edit cannot change the rules
cp "$PROMPT_FILE" "$RUN_DIR/prompt.md"; PROMPT_FILE="$RUN_DIR/prompt.md"
if [[ -z "$AGENT_CMD" ]]; then cp "$SETTINGS_FILE" "$RUN_DIR/settings.json"; SETTINGS_FILE="$RUN_DIR/settings.json"; fi
[[ -f "$STEERING_FILE" ]] || printf '# Steering notes from the human

(Empty. Anything written here overrides BACKLOG order; it never overrides the hard limits.)
' > "$STEERING_FILE"
test_count() { [[ -n "$TEST_COUNT_CMD" ]] && bash -c "$TEST_COUNT_CMD" 2>/dev/null | head -n 1; }

log "run dir: $RUN_DIR  branch: $BRANCH  agent: ${AGENT_CMD:-$CLAUDE_BIN} ${MODEL:+model $MODEL}  mode: $PERMISSION_MODE"
log "limits: ${MAX_ITERATIONS} iters / ${MAX_HOURS} h / \$${MAX_COST_USD} / ${ITERATION_TIMEOUT_MIN} min per iteration"
log "baseline tests: $TEST_CMD"
if ! bash -c "$TEST_CMD" > "$RUN_DIR/baseline.tests.txt" 2>&1; then
  die "baseline tests fail (see $RUN_DIR/baseline.tests.txt); the loop only starts from green"
fi
green_count="$(test_count)"
START_SHA="$(git rev-parse HEAD)"
last_green_sha="$START_SHA"   # the harness trusts this variable, not the tag (the tag is for humans)
git tag -f agent-last-green "$START_SHA" >/dev/null
git tag -f agent-run-start "$START_SHA" >/dev/null
{
  printf '# Last iteration (harness)\n\n'
  printf -- '- next iteration: 1  (retro due: no)\n'
  printf -- '- run started %s from %s; baseline tests green%s\n' "$(date '+%F %T')" "${START_SHA:0:10}" "${green_count:+ ($green_count tests collected)}"
} > "$LAST_ITER_NOTE"

# ---------- loop ----------
start_epoch=$(date +%s); iter=0; fails=0; idle=0; cost_total=0; end_reason="max iterations reached"
while :; do
  if [[ -f "$STOP_FILE" ]]; then end_reason="STOP file found"; break; fi
  if (( iter >= MAX_ITERATIONS )); then end_reason="max iterations reached"; break; fi
  if (( ( $(date +%s) - start_epoch ) >= MAX_HOURS * 3600 )); then end_reason="time budget reached"; break; fi
  if awk -v a="$cost_total" -v b="$MAX_COST_USD" 'BEGIN{exit !(a>=b)}'; then end_reason="cost budget reached"; break; fi

  iter=$((iter + 1))
  out="$RUN_DIR/iter-$iter.json"; err="$RUN_DIR/iter-$iter.stderr"
  pre_sha="$(git rev-parse HEAD)"
  log "iteration $iter: starting (HEAD ${pre_sha:0:10})"

  if [[ -n "$AGENT_CMD" ]]; then
    PROMPT_FILE="$PROMPT_FILE" MODEL="$MODEL" ITERATION="$iter" \
      timeout -k 30s "${ITERATION_TIMEOUT_MIN}m" bash -c "$AGENT_CMD" > "$out" 2> "$err" < /dev/null
    rc=$?
  else
    schema_args=(); [[ "$USE_JSON_SCHEMA" == 1 ]] && schema_args=(--json-schema "$STATUS_SCHEMA")
    model_args=();  [[ -n "$MODEL" ]] && model_args=(--model "$MODEL")
    # shellcheck disable=SC2086  # EXTRA_FLAGS is intentionally word-split
    timeout -k 30s "${ITERATION_TIMEOUT_MIN}m" "$CLAUDE_BIN" -p "$(cat "$PROMPT_FILE")" \
        ${model_args[@]+"${model_args[@]}"} \
        --settings "$SETTINGS_FILE" \
        --permission-mode "$PERMISSION_MODE" $EXTRA_FLAGS \
        --output-format json ${schema_args[@]+"${schema_args[@]}"} \
        > "$out" 2> "$err" < /dev/null
    rc=$?
  fi
  (( rc == 137 )) && rc=124   # killed after the grace period still counts as a timeout

  mapfile -t st < <(read_status "$out")
  status="${st[0]:-unknown}"; item="${st[1]:--}"; summary="${st[2]:-(no summary)}"
  cost="$(json_field "$out" total_cost_usd 0)"
  [[ "$cost" =~ ^[0-9]+([.][0-9]+)?$ ]] || cost=0
  cost_total="$(awk -v a="$cost_total" -v b="$cost" 'BEGIN{printf "%.2f", a+b}')"
  (( rc == 124 )) && summary="TIMEOUT after ${ITERATION_TIMEOUT_MIN} min. $summary"
  log "iteration $iter: rc=$rc status=$status item=$item cost=\$$cost (total \$$cost_total)"
  log "  summary: $summary"

  # Independent verification: never trust "tests passed" from the agent alone.
  problem=""; now_count=""
  bash -c "$TEST_CMD" > "$RUN_DIR/iter-$iter.tests.txt" 2>&1; test_rc=$?
  cur_branch="$(git rev-parse --abbrev-ref HEAD)"
  if (( rc == 124 )); then
    problem="timed out"
  elif [[ "$cur_branch" != "$BRANCH" ]]; then
    problem="agent left branch $BRANCH (now on '$cur_branch')"
  elif ! git merge-base --is-ancestor "$last_green_sha" HEAD; then
    problem="history rewritten (last green commit is no longer an ancestor of HEAD)"
  elif (( test_rc != 0 )); then
    problem="tests failed"
  else
    # shellcheck disable=SC2086  # PROTECTED_PATHS is a list of pathspecs
    touched="$( { git diff --name-only "$last_green_sha" -- $PROTECTED_PATHS; \
                  git ls-files --others --exclude-standard -- $PROTECTED_PATHS; } | sort -u | tr '\n' ' ')"
    if [[ -n "${touched// /}" ]]; then
      problem="changed protected paths: $touched"
    else
      now_count="$(test_count)"
      if [[ "$now_count" =~ ^[0-9]+$ && "$green_count" =~ ^[0-9]+$ ]] && (( now_count < green_count )); then
        problem="test count dropped from $green_count to $now_count"
      fi
    fi
  fi

  if [[ -z "$problem" ]]; then
    if [[ -n "$(git status --porcelain)" ]]; then
      git stash push -u -q -m "agent iter $iter uncommitted leftovers" \
        && log "  note: uncommitted leftovers stashed (git stash list)"
    fi
    last_green_sha="$(git rev-parse HEAD)"
    git tag -f agent-last-green "$last_green_sha" >/dev/null
    [[ "${now_count:-}" =~ ^[0-9]+$ ]] && green_count="$now_count"
    fails=0
    if [[ "$(git rev-parse HEAD)" == "$pre_sha" ]]; then
      idle=$((idle + 1)); verdict="tests green; no new commit (idle $idle/$MAX_IDLE_ITERATIONS)"
    else
      idle=0; verdict="tests green; kept $(git rev-list --count "$pre_sha..HEAD") commit(s)"
    fi
  else
    fails=$((fails + 1))
    snap="agent-failed/iter-$iter-$(date +%H%M%S)"
    git switch -q -c "$snap"
    git add -A && git commit -q --no-verify --allow-empty -m "WIP snapshot: iteration $iter failed verification ($problem)"
    git switch -q -f "$BRANCH"
    git reset -q --hard "$last_green_sha"
    git tag -f agent-last-green "$last_green_sha" >/dev/null   # restore the tag in case it was moved
    verdict="FAILED ($problem); work saved to $snap and branch reset to agent-last-green"
  fi
  log "  verdict: $verdict"

  {
    printf '# Last iteration (harness)\n\n'
    next=$((iter + 1)); retro="no"; (( RETRO_EVERY > 0 && next % RETRO_EVERY == 0 )) && retro="yes"
    printf -- '- next iteration: %s  (retro due: %s)\n' "$next" "$retro"
    printf -- '- previous iteration: %s  (finished %s)\n' "$iter" "$(date '+%F %T')"
    printf -- '- item: %s\n- agent status: %s\n- agent summary: %s\n' "$item" "$status" "$summary"
    printf -- '- harness verdict: %s\n' "$verdict"
    printf -- '- consecutive failures: %s/%s   idle iterations: %s/%s\n' "$fails" "$MAX_CONSECUTIVE_FAILURES" "$idle" "$MAX_IDLE_ITERATIONS"
    printf -- '- test output (tail):\n\n```\n'
    tail -n 30 "$RUN_DIR/iter-$iter.tests.txt"
    printf '```\n\nIf the verdict says FAILED, treat the item as needs-rethink (see AUTONOMOUS_RUN.md).\n'
  } > "$LAST_ITER_NOTE"

  if (( fails >= MAX_CONSECUTIVE_FAILURES )); then end_reason="$fails consecutive failed iterations"; break; fi
  if (( idle >= MAX_IDLE_ITERATIONS )); then end_reason="$idle iterations in a row produced no commit (check $err)"; break; fi
  case "$status" in
    done)  end_reason="agent reports backlog done"; break ;;
    stop)  end_reason="agent requested stop: $summary"; break ;;
    *)     : ;;   # continue | blocked | unknown -> next iteration
  esac
  if (( rc != 0 && rc != 124 )); then
    log "  agent exited rc=$rc; backing off ${ERROR_BACKOFF_SEC}s (stderr tail below)"
    tail -n 5 "$err" | sed 's/^/    /' | tee -a "$RUN_DIR/loop.log"
    sleep "$ERROR_BACKOFF_SEC"
  else
    sleep 5
  fi
done

# ---------- run summary ----------
{
  printf '# Agent run summary\n\n'
  printf -- '- started: %s  ended: %s\n' "$(date -d "@$start_epoch" '+%F %T' 2>/dev/null || echo "$start_epoch")" "$(date '+%F %T')"
  printf -- '- branch: %s  start: %s  end: %s\n' "$BRANCH" "${START_SHA:0:10}" "$(git rev-parse --short HEAD)"
  printf -- '- iterations: %s  estimated cost: $%s  end reason: %s\n\n' "$iter" "$cost_total" "$end_reason"
  printf '## Commits kept (review these)\n\n```\n'
  git log --oneline "$START_SHA..HEAD"
  printf '```\n\n## Failed-iteration snapshots\n\n```\n'
  git branch --list 'agent-failed/*'
  printf '```\n\nReview with: git log -p %s..HEAD   (or git diff --stat %s HEAD)\n' "${START_SHA:0:10}" "${START_SHA:0:10}"
  printf 'Then read docs/proposals/MORNING_REPORT.md and QUESTIONS.md. Loop log: %s/loop.log\n' "$RUN_DIR"
} > "$RUN_DIR/RUN_SUMMARY.md"
git tag -f agent-run-start "$START_SHA" >/dev/null
cp "$RUN_DIR/RUN_SUMMARY.md" "$RUNS_ROOT/LATEST_RUN_SUMMARY.md"
log "done: $end_reason. Summary: $RUN_DIR/RUN_SUMMARY.md"
````
