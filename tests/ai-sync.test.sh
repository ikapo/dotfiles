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

# Creates $SANDBOX with a fake repo and fake home, plus (unless called as
# `new_sandbox --no-codex`) a stub codex that appends its arguments to
# $CODEX_LOG and serves `mcp list --json` from $CODEX_STATE.
#
# `--no-codex` skips writing the stub at $SANDBOX/codex, so the path
# AI_SYNC_CODEX_BIN points run_sync at is absolute but does not exist --
# reproducing "codex is not installed on this machine" without touching
# PATH or ever risking a real codex binary being found or run.
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

  if [ "${1:-}" != "--no-codex" ]; then
    cat >"$SANDBOX/codex" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CODEX_LOG"
if [ "${1:-}" = "mcp" ] && [ "${2:-}" = "list" ]; then
  cat "$CODEX_STATE"
fi
exit 0
STUB
    chmod +x "$SANDBOX/codex"
  fi
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

test_link_refusal_partial_apply() {
  printf 'a blocked link does not block unrelated targets\n'

  new_sandbox
  write_mcp <<'JSON'
{"servers": {"a": {"command": "a-cmd", "targets": ["claude"]}}}
JSON
  echo '# instructions' >"$REPO/.config/ai/AGENTS.md"
  echo '{}' >"$REPO/.config/ai/claude/settings.json"

  # A real (non-symlink) directory already occupies ~/.claude/skills,
  # unrelated to anything else ai-sync manages.
  mkdir -p "$FAKEHOME/.claude/skills"
  echo 'do not touch me' >"$FAKEHOME/.claude/skills/mine.txt"

  local out rc
  out="$(run_sync 2>&1)"; rc=$?

  assert_eq "exits 2 for the blocked link" "$rc" "2"
  assert_contains "names the blocked path" "$out" "skills"
  assert_eq "real directory survives untouched" \
    "$([ -d "$FAKEHOME/.claude/skills" ] && [ ! -L "$FAKEHOME/.claude/skills" ] && echo intact)" \
    "intact"
  assert_eq "file inside it survives" \
    "$(cat "$FAKEHOME/.claude/skills/mine.txt")" "do not touch me"

  # Unrelated targets were still applied despite the blocked link.
  assert_link "codex AGENTS.md still linked" \
    "$FAKEHOME/.codex/AGENTS.md" "$REPO/.config/ai/AGENTS.md"
  assert_link "claude CLAUDE.md still linked" \
    "$FAKEHOME/.claude/CLAUDE.md" "$REPO/.config/ai/AGENTS.md"
  assert_contains "claude mcp.json still written" \
    "$(cat "$FAKEHOME/.claude/mcp.json")" '"a-cmd"'
}

test_codex_skills() {
  printf 'codex per-skill links\n'

  new_sandbox
  write_mcp <<'JSON'
{"servers": {}}
JSON
  echo '# i' >"$REPO/.config/ai/AGENTS.md"
  echo '{}' >"$REPO/.config/ai/claude/settings.json"
  mkdir -p "$REPO/.config/ai/skills/alpha" "$REPO/.config/ai/skills/beta"
  echo '# alpha' >"$REPO/.config/ai/skills/alpha/SKILL.md"
  echo '# beta' >"$REPO/.config/ai/skills/beta/SKILL.md"

  run_sync >/dev/null 2>&1
  assert_link "linked alpha" \
    "$FAKEHOME/.codex/skills/alpha" "$REPO/.config/ai/skills/alpha"
  assert_link "linked beta" \
    "$FAKEHOME/.codex/skills/beta" "$REPO/.config/ai/skills/beta"
  assert_eq "left .system alone" \
    "$([ -d "$FAKEHOME/.codex/skills/.system" ] && [ ! -L "$FAKEHOME/.codex/skills/.system" ] && echo intact)" \
    "intact"

  local rc
  run_sync --check >/dev/null 2>&1; rc=$?
  assert_eq "idempotent" "$rc" "0"

  # Deleting a skill removes its stale link.
  rm -rf "$REPO/.config/ai/skills/beta"
  run_sync >/dev/null 2>&1
  assert_eq "removed stale link" \
    "$([ -e "$FAKEHOME/.codex/skills/beta" ] || [ -L "$FAKEHOME/.codex/skills/beta" ] && echo present || echo gone)" \
    "gone"
  assert_link "kept alpha" \
    "$FAKEHOME/.codex/skills/alpha" "$REPO/.config/ai/skills/alpha"

  # A real directory placed by the user is not removed.
  mkdir -p "$FAKEHOME/.codex/skills/handmade"
  run_sync >/dev/null 2>&1
  assert_eq "left real dir alone" \
    "$([ -d "$FAKEHOME/.codex/skills/handmade" ] && echo intact)" "intact"
}

seed_codex_state() { cat >"$CODEX_STATE"; }

test_codex_mcp() {
  printf 'codex mcp sync\n'

  new_sandbox
  write_mcp <<'JSON'
{
  "servers": {
    "github": {"command": "gh-mcp", "targets": ["codex"]},
    "notcodex": {"command": "x", "targets": ["claude"]}
  }
}
JSON
  echo '# i' >"$REPO/.config/ai/AGENTS.md"
  echo '{}' >"$REPO/.config/ai/claude/settings.json"
  # Codex already has an app-managed server ai-sync must never touch.
  seed_codex_state <<'JSON'
[{"name": "node_repl", "enabled": true}]
JSON

  run_sync >/dev/null 2>&1
  local log
  log="$(cat "$CODEX_LOG")"
  assert_contains "added github" "$log" "mcp add github"
  assert_contains "used -- separator" "$log" "-- gh-mcp"
  assert_not_contains "did not add claude-only server" "$log" "notcodex"
  assert_not_contains "never removed app server" "$log" "remove node_repl"

  # Simulate Codex now reporting both servers, then drop github from source.
  seed_codex_state <<'JSON'
[{"name": "node_repl", "enabled": true}, {"name": "github", "enabled": true}]
JSON
  : >"$CODEX_LOG"
  write_mcp <<'JSON'
{"servers": {}}
JSON
  run_sync >/dev/null 2>&1
  log="$(cat "$CODEX_LOG")"
  assert_contains "removed github" "$log" "mcp remove github"
  assert_not_contains "still spared node_repl" "$log" "remove node_repl"

  # A server `codex mcp list` already reports is not re-added.
  new_sandbox
  write_mcp <<'JSON'
{"servers": {"github": {"command": "gh-mcp", "targets": ["codex"]}}}
JSON
  echo '# i' >"$REPO/.config/ai/AGENTS.md"
  echo '{}' >"$REPO/.config/ai/claude/settings.json"
  seed_codex_state <<'JSON'
[{"name": "github", "enabled": true}]
JSON
  run_sync >/dev/null 2>&1
  assert_not_contains "already-installed server is not re-added" \
    "$(cat "$CODEX_LOG")" "mcp add github"

  # With Codex disabled, no CLI calls at all.
  new_sandbox
  write_mcp <<'JSON'
{"servers": {"github": {"command": "gh-mcp", "targets": ["codex"]}}}
JSON
  echo '# i' >"$REPO/.config/ai/AGENTS.md"
  echo '{}' >"$REPO/.config/ai/claude/settings.json"
  AI_SYNC_REPO="$REPO" AI_SYNC_HOME="$FAKEHOME" AI_SYNC_STATE="$SANDBOX/state" \
    AI_SYNC_CODEX_BIN="" "$REPO/.local/bin/ai-sync" >/dev/null 2>&1
  assert_eq "codex disabled means no calls" "$(wc -l <"$CODEX_LOG" | tr -d ' ')" "0"
}

test_codex_missing_binary() {
  printf 'codex binary not found (not disabled, just absent)\n'

  # No codex stub at all: AI_SYNC_CODEX_BIN in run_sync points at a path
  # that does not exist. This must not crash, must not block the other
  # targets, and must not leave the sync permanently non-idempotent.
  new_sandbox --no-codex
  write_mcp <<'JSON'
{
  "servers": {
    "a": {"command": "a-cmd", "targets": ["claude"]},
    "github": {"command": "gh-mcp", "targets": ["codex"]}
  }
}
JSON
  echo '# instructions' >"$REPO/.config/ai/AGENTS.md"
  echo '{}' >"$REPO/.config/ai/claude/settings.json"

  local out rc
  out="$(run_sync 2>&1)"; rc=$?
  assert_eq "sync succeeds despite missing codex" "$rc" "0"
  assert_not_contains "no traceback" "$out" "Traceback"
  assert_contains "explains codex was skipped" "$out" "codex"

  # Other targets were not blocked by the missing codex binary.
  assert_contains "claude mcp.json still written" \
    "$(cat "$FAKEHOME/.claude/mcp.json")" '"a-cmd"'
  assert_link "claude skills still linked" \
    "$FAKEHOME/.claude/skills" "$REPO/.config/ai/skills"
  assert_link "claude CLAUDE.md still linked" \
    "$FAKEHOME/.claude/CLAUDE.md" "$REPO/.config/ai/AGENTS.md"
  assert_link "codex AGENTS.md still linked" \
    "$FAKEHOME/.codex/AGENTS.md" "$REPO/.config/ai/AGENTS.md"

  # The important half: this must not become a permanent, repeating
  # failure. A second run (and --check) must be clean.
  out="$(run_sync --check 2>&1)"; rc=$?
  assert_eq "second run --check is clean (idempotent)" "$rc" "0"

  out="$(run_sync 2>&1)"; rc=$?
  assert_eq "second apply run also succeeds" "$rc" "0"
  assert_not_contains "second run wrote nothing new" "$out" "write"
}

write_state_file() { mkdir -p "$SANDBOX/state"; cat >"$SANDBOX/state/managed.json"; }

test_codex_state_bad_shapes() {
  printf 'codex state file bad shapes\n'

  local shape
  for shape in 'null' '[]' '{"codex": "github"}' '{"codex": [1, 2]}'; do
    new_sandbox
    write_mcp <<'JSON'
{"servers": {"extra": {"command": "x", "targets": ["codex"]}}}
JSON
    echo '# i' >"$REPO/.config/ai/AGENTS.md"
    echo '{}' >"$REPO/.config/ai/claude/settings.json"
    # Codex already has an app-managed server ai-sync must never touch,
    # regardless of how unusable the on-disk state file is.
    seed_codex_state <<'JSON'
[{"name": "node_repl", "enabled": true}]
JSON
    printf '%s' "$shape" | write_state_file

    local out rc
    out="$(run_sync 2>&1)"; rc=$?
    assert_eq "no crash for shape [$shape]" "$rc" "0"
    assert_not_contains "no traceback for shape [$shape]" "$out" "Traceback"
    assert_not_contains "unusable state never removes app server [$shape]" \
      "$(cat "$CODEX_LOG")" "remove node_repl"
  done
}

test_codex_skills_foreign_symlink_safety() {
  printf 'codex skills foreign symlink safety\n'

  new_sandbox
  write_mcp <<'JSON'
{"servers": {}}
JSON
  echo '# i' >"$REPO/.config/ai/AGENTS.md"
  echo '{}' >"$REPO/.config/ai/claude/settings.json"
  mkdir -p "$REPO/.config/ai/skills/alpha"
  echo '# alpha' >"$REPO/.config/ai/skills/alpha/SKILL.md"

  # A symlink under ~/.codex/skills pointing OUTSIDE the source skills dir
  # (e.g. someone else's tool, or a manual link) must never be pruned.
  mkdir -p "$SANDBOX/outside-target"
  ln -sfn "$SANDBOX/outside-target" "$FAKEHOME/.codex/skills/foreign"

  run_sync >/dev/null 2>&1
  assert_link "foreign symlink untouched" \
    "$FAKEHOME/.codex/skills/foreign" "$SANDBOX/outside-target"
}

test_zed() {
  printf 'zed jsonc patching\n'

  new_sandbox
  write_mcp <<'JSON'
{"servers": {"github": {"command": "gh-mcp", "targets": ["zed"], "env": {"GH_TOKEN_SOURCE": "keychain"}}}}
JSON
  echo '# i' >"$REPO/.config/ai/AGENTS.md"
  echo '{}' >"$REPO/.config/ai/claude/settings.json"
  printf '#!/bin/sh\n' >"$FAKEHOME/.local/bin/gh-mcp"
  chmod +x "$FAKEHOME/.local/bin/gh-mcp"

  cat >"$REPO/.config/zed/settings.json" <<'JSON'
// Zed settings
// keep this comment
{
  "cli_default_open_behavior": "existing_window",
  "vim_mode": true
}
JSON

  run_sync >/dev/null 2>&1
  local patched
  patched="$(cat "$REPO/.config/zed/settings.json")"
  assert_contains "preserved comment header" "$patched" "keep this comment"
  assert_contains "added context_servers" "$patched" '"context_servers"'
  assert_contains "resolved absolute command" "$patched" "$FAKEHOME/.local/bin/gh-mcp"
  assert_contains "kept unrelated key" "$patched" '"vim_mode"'
  assert_contains "propagated env to zed" "$patched" '"GH_TOKEN_SOURCE": "keychain"'

  local rc
  run_sync --check >/dev/null 2>&1; rc=$?
  assert_eq "idempotent" "$rc" "0"

  # Removing the last zed server drops the key entirely.
  write_mcp <<'JSON'
{"servers": {}}
JSON
  run_sync >/dev/null 2>&1
  patched="$(cat "$REPO/.config/zed/settings.json")"
  assert_not_contains "dropped empty context_servers" "$patched" "context_servers"
  assert_contains "header still there" "$patched" "keep this comment"

  # An already-absolute command is left as written.
  new_sandbox
  write_mcp <<'JSON'
{"servers": {"x": {"command": "/opt/custom/bin/x", "targets": ["zed"]}}}
JSON
  echo '# i' >"$REPO/.config/ai/AGENTS.md"
  echo '{}' >"$REPO/.config/ai/claude/settings.json"
  printf '{\n  "vim_mode": true\n}\n' >"$REPO/.config/zed/settings.json"
  run_sync >/dev/null 2>&1
  patched="$(cat "$REPO/.config/zed/settings.json")"
  assert_contains "kept absolute path verbatim" "$patched" "/opt/custom/bin/x"
  assert_not_contains "no spurious env key when absent" "$patched" '"env"'
}

test_zed_comment_after_brace() {
  printf 'zed jsonc rejects comments after the opening brace\n'

  new_sandbox
  write_mcp <<'JSON'
{"servers": {}}
JSON
  echo '# i' >"$REPO/.config/ai/AGENTS.md"
  echo '{}' >"$REPO/.config/ai/claude/settings.json"

  cat >"$REPO/.config/zed/settings.json" <<'JSON'
{
  // comment after the opening brace, valid Zed JSONC, unsupported here
  "vim_mode": true
}
JSON

  local before after out rc
  before="$(cat "$REPO/.config/zed/settings.json")"
  out="$(run_sync 2>&1)"; rc=$?
  after="$(cat "$REPO/.config/zed/settings.json")"

  assert_eq "exits 2 on comment after brace" "$rc" "2"
  assert_contains "names the leading header rule" "$out" "leading header"
  assert_eq "file left untouched" "$after" "$before"
}

test_cli() {
  printf 'cli surface\n'

  new_sandbox
  write_mcp <<'JSON'
{"servers": {}}
JSON
  local out rc

  out="$(run_sync --help 2>&1)"; rc=$?
  assert_eq "help exits 0" "$rc" "0"
  assert_contains "help mentions --check" "$out" "--check"
  assert_contains "help mentions usage" "$out" "usage"

  out="$(run_sync --bogus 2>&1)"; rc=$?
  assert_eq "unknown flag exits 2" "$rc" "2"
  assert_contains "names the bad flag" "$out" "--bogus"
}

test_write_file_non_utf8() {
  printf 'write_file tolerates a non-UTF-8 existing target\n'

  new_sandbox
  write_mcp <<'JSON'
{"servers": {"a": {"command": "a-cmd", "targets": ["claude"]}}}
JSON
  echo '# i' >"$REPO/.config/ai/AGENTS.md"
  echo '{}' >"$REPO/.config/ai/claude/settings.json"
  # A pre-existing target file with invalid UTF-8 bytes must not crash
  # write_file's existing-content comparison.
  printf '\xff\xfe garbage not utf8' >"$FAKEHOME/.claude/mcp.json"

  local out rc
  out="$(run_sync 2>&1)"; rc=$?
  assert_eq "no crash on non-utf8 existing file" "$rc" "0"
  assert_not_contains "no traceback" "$out" "Traceback"
  assert_contains "wrote fresh content" \
    "$(cat "$FAKEHOME/.claude/mcp.json")" '"a-cmd"'
}

test_link_apply_time_toctou() {
  printf 'link() apply-time re-check (TOCTOU guard)\n'

  # Reproduces the race directly: link() plans a normal symlink because
  # the target is absent at plan-build time, then a real file appears in
  # the window before apply. Calling the returned Action's apply()
  # directly exercises the new re-check branch inside the closure without
  # needing to win a real filesystem timing race.
  new_sandbox

  local out rc
  out="$(AI_SYNC_REPO="$REPO" AI_SYNC_HOME="$FAKEHOME" python3 - <<'PY'
import importlib.machinery, importlib.util, os
from pathlib import Path

loader = importlib.machinery.SourceFileLoader(
    "ai_sync", os.path.join(os.environ["AI_SYNC_REPO"], ".local/bin/ai-sync")
)
spec = importlib.util.spec_from_loader("ai_sync", loader)
mod = importlib.util.module_from_spec(spec)
loader.exec_module(mod)

target = Path(os.environ["AI_SYNC_HOME"]) / ".claude" / "CLAUDE.md"
dest = Path(os.environ["AI_SYNC_REPO"]) / ".config" / "ai" / "AGENTS.md"
dest.parent.mkdir(parents=True, exist_ok=True)
dest.write_text("# instructions\n")

action = mod.link(target, dest)
assert action is not None, "expected link() to return an Action when target absent"

# A real file appears in the window between plan-build and apply.
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text("precious hand-written notes")

try:
    action.apply()
    print("NO_RAISE")
except mod.ConfigError as exc:
    print("RAISED:" + str(exc))
PY
)"; rc=$?

  assert_eq "python snippet ran cleanly" "$rc" "0"
  assert_eq "apply-time guard raised ConfigError" "${out%%:*}" "RAISED"
  assert_contains "same wording as plan-time refusal" "$out" "exists and is not a symlink"
  assert_eq "file survived the attempted apply" \
    "$(cat "$FAKEHOME/.claude/CLAUDE.md")" "precious hand-written notes"
}

test_version
test_validation
test_claude_mcp
test_symlinks
test_link_refusal_partial_apply
test_codex_skills
test_codex_mcp
test_codex_missing_binary
test_zed
test_zed_comment_after_brace
test_cli
test_write_file_non_utf8
test_codex_state_bad_shapes
test_codex_skills_foreign_symlink_safety
test_link_apply_time_toctou
report
