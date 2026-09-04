#!/usr/bin/env bash
# Test harness for ai-sync. Run: tests/ai-sync.test.sh
# shellcheck disable=SC2329  # helpers are the harness API for later tasks; not all are called yet
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

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  case "$haystack" in
    *"$needle"*) pass "$desc" ;;
    *) fail "$desc" "missing [$needle] in: $haystack" ;;
  esac
}

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

test_version
report
