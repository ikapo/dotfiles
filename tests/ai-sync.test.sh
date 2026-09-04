#!/usr/bin/env bash
# Test harness for ai-sync. Run: tests/ai-sync.test.sh
set -uo pipefail

SRC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_AI_SYNC="$SRC_ROOT/.local/bin/ai-sync"
FAILED=0
SANDBOXES=()

pass() { printf '  ok    %s\n' "$1"; }
fail() {
  printf '  FAIL  %s\n        %s\n' "$1" "$2"
  FAILED=1
}

assert_eq() {
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "expected [$3] got [$2]"; fi
}

assert_link() {
  local desc="$1" link="$2" want="$3" got
  if [ ! -L "$link" ]; then
    fail "$desc" "not a symlink: $link"
    return
  fi
  got="$(readlink "$link")"
  if [ "$got" = "$want" ]; then pass "$desc"; else fail "$desc" "link -> [$got] want [$want]"; fi
}

# shellcheck disable=SC2329  # part of the harness API; called starting in a later task
assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  case "$haystack" in
    *"$needle"*) pass "$desc" ;;
    *) fail "$desc" "missing [$needle] in: $haystack" ;;
  esac
}

# shellcheck disable=SC2329  # part of the harness API; called starting in a later task
assert_not_contains() {
  local desc="$1" haystack="$2" needle="$3"
  case "$haystack" in
    *"$needle"*) fail "$desc" "unexpected [$needle] in: $haystack" ;;
    *) pass "$desc" ;;
  esac
}

# Creates $SANDBOX with a fake repo and fake home, plus a stub codex
# that appends its arguments to $CODEX_LOG and serves `mcp list --json`
# from $CODEX_STATE.
new_sandbox() {
  SANDBOX="$(mktemp -d)"
  SANDBOXES+=("$SANDBOX")
  REPO="$SANDBOX/repo"
  FAKEHOME="$SANDBOX/home"
  CODEX_LOG="$SANDBOX/codex.log"
  CODEX_STATE="$SANDBOX/codex-servers.json"

  mkdir -p "$REPO/.config/ai/skills" "$REPO/.config/ai/claude" \
           "$REPO/.config/zed" "$REPO/.local/bin" \
           "$FAKEHOME/.claude" "$FAKEHOME/.codex/skills/.system" \
           "$FAKEHOME/.local/bin"
  cp "$SRC_AI_SYNC" "$REPO/.local/bin/ai-sync"
  chmod +x "$REPO/.local/bin/ai-sync"
  : >"$CODEX_LOG"
  echo '[]' >"$CODEX_STATE"

  cat >"$SANDBOX/codex" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CODEX_LOG"
if [ "${1:-}" = "mcp" ] && [ "${2:-}" = "list" ]; then
  cat "$CODEX_STATE"
fi
exit 0
STUB
  chmod +x "$SANDBOX/codex"
}

run_sync() {
  AI_SYNC_REPO="$REPO" \
  AI_SYNC_HOME="$FAKEHOME" \
  AI_SYNC_STATE="$SANDBOX/state" \
  AI_SYNC_CODEX_BIN="$SANDBOX/codex" \
  CODEX_LOG="$CODEX_LOG" \
  CODEX_STATE="$CODEX_STATE" \
    "$REPO/.local/bin/ai-sync" "$@"
}

# shellcheck disable=SC2329  # invoked indirectly via `trap cleanup EXIT`
cleanup() {
  local d
  for d in "${SANDBOXES[@]+"${SANDBOXES[@]}"}"; do
    [ -n "$d" ] && rm -rf "$d"
  done
}
trap cleanup EXIT

report() {
  if [ "$FAILED" -eq 0 ]; then
    printf '\nAll tests passed.\n'
  else
    printf '\nFAILURES.\n'
  fi
  exit "$FAILED"
}

# ---------------------------------------------------------------- tests

test_version() {
  printf 'version\n'
  new_sandbox
  local out
  out="$(run_sync --version)"
  assert_eq "prints version" "$out" "ai-sync 1.0"
}

write_mcp() { cat >"$REPO/.config/ai/mcp.json"; }

test_validation() {
  printf 'validation\n'

  new_sandbox
  write_mcp <<'JSON'
{"servers": {"a": {"command": "x", "targets": ["claude", "bogus"]}}}
JSON
  local out rc
  out="$(run_sync --check 2>&1)"; rc=$?
  assert_eq "unknown target exits 2" "$rc" "2"
  assert_contains "names the bad target" "$out" "bogus"
  assert_contains "lists valid targets" "$out" "claude"

  new_sandbox
  write_mcp <<'JSON'
{"servers": {"a": {"targets": ["claude"]}}}
JSON
  out="$(run_sync --check 2>&1)"; rc=$?
  assert_eq "missing command exits 2" "$rc" "2"
  assert_contains "names missing command" "$out" "command"

  new_sandbox
  write_mcp <<'JSON'
{"servers": {"a": {"command": "x"}}}
JSON
  out="$(run_sync --check 2>&1)"; rc=$?
  assert_eq "missing targets exits 2" "$rc" "2"
  assert_contains "names missing targets" "$out" "targets"

  new_sandbox
  write_mcp <<'JSON'
{ not json
JSON
  out="$(run_sync --check 2>&1)"; rc=$?
  assert_eq "malformed json exits 2" "$rc" "2"
  assert_contains "names the file" "$out" "mcp.json"

  new_sandbox
  write_mcp <<'JSON'
{"servers": {"a": {"command": 5, "targets": ["claude"]}}}
JSON
  out="$(run_sync --check 2>&1)"; rc=$?
  assert_eq "non-string command exits 2" "$rc" "2"
  assert_contains "names the server" "$out" "a"
  assert_contains "names command" "$out" "command"
}

test_claude_mcp() {
  printf 'claude mcp generation\n'

  new_sandbox
  write_mcp <<'JSON'
{
  "servers": {
    "zeta":  {"command": "z-cmd", "args": ["--a"], "targets": ["claude"]},
    "alpha": {"command": "a-cmd", "targets": ["claude"], "env": {"LOG": "debug"}},
    "zedonly": {"command": "q", "targets": ["zed"]}
  }
}
JSON

  local out rc
  out="$(run_sync --check 2>&1)"; rc=$?
  assert_eq "check reports drift" "$rc" "1"
  assert_contains "check names the file" "$out" "mcp.json"

  run_sync >/dev/null 2>&1
  local generated
  generated="$(cat "$FAKEHOME/.claude/mcp.json")"
  assert_contains "wrote alpha" "$generated" '"alpha"'
  assert_contains "wrote zeta" "$generated" '"zeta"'
  assert_not_contains "excluded zed-only server" "$generated" "zedonly"
  assert_contains "wrapped in mcpServers" "$generated" '"mcpServers"'
  assert_contains "kept env" "$generated" '"LOG": "debug"'
  assert_contains "kept args" "$generated" '"--a"'

  # Deterministic ordering: alpha sorts before zeta regardless of input order.
  local first
  first="$(python3 -c 'import json,sys;print(next(iter(json.load(sys.stdin)["mcpServers"])))' <"$FAKEHOME/.claude/mcp.json")"
  assert_eq "sorted deterministically" "$first" "alpha"

  out="$(run_sync --check 2>&1)"; rc=$?
  assert_eq "check clean after sync" "$rc" "0"

  out="$(run_sync 2>&1)"
  assert_not_contains "second run is a no-op" "$out" "mcp.json"
}

test_symlinks() {
  printf 'shared symlinks\n'

  new_sandbox
  write_mcp <<'JSON'
{"servers": {}}
JSON
  echo '# instructions' >"$REPO/.config/ai/AGENTS.md"
  echo '{"model": "opus"}' >"$REPO/.config/ai/claude/settings.json"

  run_sync >/dev/null 2>&1
  assert_link "claude skills dir" \
    "$FAKEHOME/.claude/skills" "$REPO/.config/ai/skills"
  assert_link "claude CLAUDE.md" \
    "$FAKEHOME/.claude/CLAUDE.md" "$REPO/.config/ai/AGENTS.md"
  assert_link "codex AGENTS.md" \
    "$FAKEHOME/.codex/AGENTS.md" "$REPO/.config/ai/AGENTS.md"
  assert_link "claude settings.json" \
    "$FAKEHOME/.claude/settings.json" "$REPO/.config/ai/claude/settings.json"

  local rc
  run_sync --check >/dev/null 2>&1; rc=$?
  assert_eq "idempotent after linking" "$rc" "0"

  # A wrong existing symlink is corrected.
  ln -sfn /nowhere "$FAKEHOME/.claude/CLAUDE.md"
  run_sync >/dev/null 2>&1
  assert_link "repaired wrong symlink" \
    "$FAKEHOME/.claude/CLAUDE.md" "$REPO/.config/ai/AGENTS.md"

  # A real file is never silently destroyed.
  rm -f "$FAKEHOME/.claude/CLAUDE.md"
  echo 'precious hand-written notes' >"$FAKEHOME/.claude/CLAUDE.md"
  local out
  out="$(run_sync 2>&1)"; rc=$?
  assert_eq "refuses to clobber real file" "$rc" "2"
  assert_contains "explains the refusal" "$out" "CLAUDE.md"
  assert_eq "file survived" \
    "$(cat "$FAKEHOME/.claude/CLAUDE.md")" "precious hand-written notes"
}

test_version
test_validation
test_claude_mcp
test_symlinks
report
