# Unified AI Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `.config/ai` the single source of truth for personal skills, MCP server definitions, and shared agent instructions, synced into Claude Code, Codex, and Zed by one idempotent command.

**Architecture:** A single Python executable, `.local/bin/ai-sync`, reads `.config/ai/mcp.json` and emits each tool's native form: a generated JSON file for Claude Code, `codex mcp add/remove` CLI calls for Codex, and a surgical patch of the `context_servers` key for Zed. Skills and instructions are shared by symlink. All target paths and the Codex binary are overridable by environment variable so the whole tool is testable in a sandbox with no real config touched.

**Tech Stack:** Python 3.9+ (stdlib only), GNU Stow, `codex` CLI, Bash for the test harness, `shellcheck`.

**Spec:** `docs/superpowers/specs/2026-09-04-unified-ai-config-design.md`

## Global Constraints

- **Dependencies:** Python 3.9+ stdlib only. No `pip install`, no third-party modules. `jq` is available but must not be required.
- **Shebang:** `#!/usr/bin/env python3`.
- **No secrets in tracked files.** `mcp.json` never contains a credential. Servers needing auth use a `.local/bin` wrapper reading Keychain via `security find-generic-password -s <service> -a "$USER" -w`, following the existing `gh-mcp`.
- **`env` in `mcp.json` is for non-sensitive values only** — feature flags, paths, log levels.
- **Never write `~/.codex/config.toml` directly.** The ChatGPT desktop app owns it. Codex is mutated only through `codex mcp add|remove`.
- **Never remove a Codex MCP server `ai-sync` does not own.** `cua_repl` and `node_repl` are app-managed and must survive every sync.
- **Zed's `settings.json` is JSONC**, not strict JSON. It opens with an 8-line `//` comment header. That header must survive every patch.
- **Zed needs absolute commands.** macOS GUI apps do not inherit the shell `PATH`, so bare command names must be resolved to absolute paths for the `zed` target only.
- **Idempotency is a hard requirement.** A second consecutive `ai-sync` produces zero changes and `ai-sync --check` exits 0.
- **`--check` exits 1 on drift, 0 when clean**, so it can be wired into a hook later.
- **Test harness must be `shellcheck`-clean.**

## Environment Variable Contract

Every task depends on this. `ai-sync` reads:

| Variable | Default | Purpose |
|---|---|---|
| `AI_SYNC_REPO` | derived from `Path(__file__).resolve().parents[2]` | repository root |
| `AI_SYNC_HOME` | `$HOME` | where target configs are written |
| `AI_SYNC_STATE` | `${XDG_STATE_HOME:-$HOME/.local/state}/ai-sync` | ownership state |
| `AI_SYNC_CODEX_BIN` | `codex` | Codex executable; empty string disables Codex sync |

---

### Task 1: Scaffold, stow fixes, and test harness

**Files:**
- Create: `.config/ai/mcp.json`
- Create: `.config/ai/AGENTS.md`
- Create: `.config/ai/skills/.gitkeep`
- Create: `.config/ai/README.md`
- Create: `.local/bin/ai-sync`
- Create: `tests/ai-sync.test.sh`
- Modify: `.stow-local-ignore`

**Interfaces:**
- Consumes: nothing.
- Produces: `ai-sync --version` prints `ai-sync 1.0`. Test harness helpers `new_sandbox`, `run_sync`, `assert_eq`, `assert_link`, `assert_contains`, `report` for all later tasks. Sandbox variables `$REPO`, `$FAKEHOME`, `$SANDBOX`, `$CODEX_LOG`.

- [ ] **Step 1: Write the failing test**

Create `tests/ai-sync.test.sh`:

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
chmod +x tests/ai-sync.test.sh
tests/ai-sync.test.sh
```

Expected: FAIL — `cp: .../.local/bin/ai-sync: No such file or directory`.

- [ ] **Step 3: Write minimal implementation**

Create `.local/bin/ai-sync`:

```python
#!/usr/bin/env python3
"""Sync .config/ai into Claude Code, Codex, and Zed."""

import os
import sys
from pathlib import Path

VERSION = "ai-sync 1.0"


def repo_root() -> Path:
    override = os.environ.get("AI_SYNC_REPO")
    if override:
        return Path(override)
    return Path(__file__).resolve().parents[2]


def target_home() -> Path:
    override = os.environ.get("AI_SYNC_HOME")
    if override:
        return Path(override)
    return Path.home()


def main(argv):
    if "--version" in argv:
        print(VERSION)
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
```

- [ ] **Step 4: Run test to verify it passes**

```bash
chmod +x .local/bin/ai-sync
tests/ai-sync.test.sh
shellcheck tests/ai-sync.test.sh
```

Expected: `ok    prints version`, `All tests passed.`, and shellcheck silent.

- [ ] **Step 5: Create the remaining scaffold files**

`.config/ai/mcp.json` — empty but valid, populated in Task 9:

```json
{
  "servers": {}
}
```

`.config/ai/AGENTS.md`:

```markdown
# Agent Instructions

Shared across Claude Code and Codex. Edit this file only; `ai-sync` links it
into each tool.
```

`.config/ai/README.md`:

```markdown
# `.config/ai`

Single source of truth for personal AI tool configuration.

| Path | Purpose |
|---|---|
| `AGENTS.md` | Shared instructions. Linked to `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`. |
| `mcp.json` | MCP server definitions. Each server lists the tools that receive it. |
| `skills/` | Personal skills, one directory per skill. Shared by Claude Code and Codex. |
| `claude/settings.json` | Claude Code settings: model, effort, enabled plugins, marketplaces. |

## Usage

    stow -t ~ .     # first time, or after adding a file
    ai-sync         # apply
    ai-sync --check # report drift, exit 1 if any

Never put a credential in `mcp.json`. Use a `.local/bin` wrapper that reads
Keychain at runtime, like `gh-mcp`.

Design: `docs/superpowers/specs/2026-09-04-unified-ai-config-design.md`
```

Create the skills placeholder:

```bash
touch .config/ai/skills/.gitkeep
```

- [ ] **Step 6: Fix the stow ignore list**

`.stow-local-ignore` currently lets stow link this repo's project-local
`.claude/settings.local.json` into the user's global Claude config, and would
link `docs` to `~/docs`. Append two entries so the file reads:

```
.git
.githooks
.gitignore
install_deps.sh
LICENSE
README.md
.claude
docs
tests
```

- [ ] **Step 7: Verify stow no longer leaks**

```bash
stow -n -v -t ~ . 2>&1 | grep -E 'claude|docs|tests'
```

Expected: no output at all. Then confirm the intended links still appear:

```bash
stow -n -v -t ~ . 2>&1 | grep -E '\.config/ai|ai-sync'
```

Expected: LINK lines for `.config/ai` and nothing alarming.

- [ ] **Step 8: Commit**

```bash
git add .config/ai .local/bin/ai-sync tests/ai-sync.test.sh .stow-local-ignore
git commit -m "feat(ai): scaffold .config/ai, ai-sync skeleton, and test harness

Also stop stow from linking project-local .claude/settings.local.json
into the global Claude config directory."
```

---

### Task 2: Load and validate `mcp.json`

**Files:**
- Modify: `.local/bin/ai-sync`
- Modify: `tests/ai-sync.test.sh`

**Interfaces:**
- Consumes: `repo_root()`, `target_home()` from Task 1.
- Produces:
  - `class ConfigError(Exception)`
  - `load_servers(ai_dir: Path) -> dict[str, dict]` — raises `ConfigError` with all problems joined by newline.
  - `servers_for(servers: dict, target: str) -> dict` — insertion-ordered subset.
  - `VALID_TARGETS = {"claude", "zed", "codex"}`
  - `ai_dir()` helper returning `repo_root() / ".config" / "ai"`.

- [ ] **Step 1: Write the failing test**

Add to `tests/ai-sync.test.sh`, before `report`:

```bash
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
}
```

Register it by adding `test_validation` on the line after `test_version`.

- [ ] **Step 2: Run test to verify it fails**

```bash
tests/ai-sync.test.sh
```

Expected: FAIL on `unknown target exits 2` — got `0`, because nothing validates yet.

- [ ] **Step 3: Write minimal implementation**

Add to `.local/bin/ai-sync` after the imports:

```python
import json

VALID_TARGETS = {"claude", "zed", "codex"}


class ConfigError(Exception):
    """Raised when mcp.json is unusable. Message may be multi-line."""


def ai_dir() -> Path:
    return repo_root() / ".config" / "ai"


def load_servers(directory: Path) -> dict:
    path = directory / "mcp.json"
    try:
        raw = path.read_text()
    except OSError as exc:
        raise ConfigError("cannot read %s: %s" % (path, exc)) from exc
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ConfigError("%s is not valid JSON: %s" % (path, exc)) from exc

    if not isinstance(data, dict):
        raise ConfigError("%s: top level must be an object" % path)
    servers = data.get("servers", {})
    if not isinstance(servers, dict):
        raise ConfigError("%s: 'servers' must be an object" % path)

    valid = ", ".join(sorted(VALID_TARGETS))
    errors = []
    for name, cfg in servers.items():
        if not isinstance(cfg, dict):
            errors.append("%s: must be an object" % name)
            continue
        if not cfg.get("command"):
            errors.append("%s: missing 'command'" % name)
        targets = cfg.get("targets")
        if not targets:
            errors.append("%s: missing 'targets' (valid: %s)" % (name, valid))
            continue
        if not isinstance(targets, list):
            errors.append("%s: 'targets' must be a list (valid: %s)" % (name, valid))
            continue
        unknown = sorted(set(targets) - VALID_TARGETS)
        if unknown:
            errors.append(
                "%s: unknown target(s) %s (valid: %s)"
                % (name, ", ".join(unknown), valid)
            )
    if errors:
        raise ConfigError("\n".join(errors))
    return servers


def servers_for(servers: dict, target: str) -> dict:
    return {n: c for n, c in servers.items() if target in c["targets"]}
```

Replace `main` with a version that validates and reports:

```python
def main(argv):
    if "--version" in argv:
        print(VERSION)
        return 0
    try:
        load_servers(ai_dir())
    except ConfigError as exc:
        print("ai-sync: %s" % exc, file=sys.stderr)
        return 2
    return 0
```

- [ ] **Step 4: Run test to verify it passes**

```bash
tests/ai-sync.test.sh
```

Expected: all `validation` assertions `ok`.

- [ ] **Step 5: Commit**

```bash
git add .local/bin/ai-sync tests/ai-sync.test.sh
git commit -m "feat(ai): validate mcp.json, rejecting unknown targets loudly"
```

---

### Task 3: Generate Claude Code's `mcp.json` with drift detection

**Files:**
- Modify: `.local/bin/ai-sync`
- Modify: `tests/ai-sync.test.sh`

**Interfaces:**
- Consumes: `load_servers`, `servers_for`, `ai_dir`, `target_home` from Tasks 1-2.
- Produces:
  - `render_claude(servers: dict) -> str` — full file text, trailing newline included.
  - `class Action` with fields `verb: str`, `detail: str`, and method `apply()`.
  - `write_file(path: Path, text: str) -> Action | None` — returns `None` when content already matches.
  - `Plan` accumulator with `.actions: list[Action]`, `.add(action)`, `.apply()`, `.render() -> str`.

- [ ] **Step 1: Write the failing test**

Add before `report`:

```bash
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
```

Register `test_claude_mcp` after `test_validation`.

- [ ] **Step 2: Run test to verify it fails**

```bash
tests/ai-sync.test.sh
```

Expected: FAIL on `check reports drift` — got `0`, nothing is generated yet.

- [ ] **Step 3: Write minimal implementation**

Add to `.local/bin/ai-sync`:

```python
class Action:
    """One pending change. `apply` performs it."""

    def __init__(self, verb, detail, run):
        self.verb = verb
        self.detail = detail
        self._run = run

    def apply(self):
        self._run()

    def __str__(self):
        return "  %-6s %s" % (self.verb, self.detail)


class Plan:
    def __init__(self):
        self.actions = []

    def add(self, action):
        if action is not None:
            self.actions.append(action)

    def apply(self):
        for action in self.actions:
            action.apply()

    def render(self):
        return "\n".join(str(a) for a in self.actions)

    def __bool__(self):
        return bool(self.actions)


def write_file(path: Path, text: str):
    if path.exists():
        try:
            if path.read_text() == text:
                return None
        except OSError:
            pass

    def run():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)

    return Action("write", str(path), run)


def render_claude(servers: dict) -> str:
    out = {}
    for name in sorted(servers):
        cfg = servers[name]
        entry = {"command": cfg["command"], "args": cfg.get("args", [])}
        if cfg.get("env"):
            entry["env"] = cfg["env"]
        out[name] = entry
    return json.dumps({"mcpServers": out}, indent=2) + "\n"
```

Rewrite `main` to build and either apply or report the plan:

```python
def build_plan(servers) -> Plan:
    plan = Plan()
    home = target_home()
    plan.add(
        write_file(
            home / ".claude" / "mcp.json",
            render_claude(servers_for(servers, "claude")),
        )
    )
    return plan


def main(argv):
    if "--version" in argv:
        print(VERSION)
        return 0
    check = "--check" in argv

    try:
        servers = load_servers(ai_dir())
    except ConfigError as exc:
        print("ai-sync: %s" % exc, file=sys.stderr)
        return 2

    plan = build_plan(servers)
    if not plan:
        if not check:
            print("ai-sync: already in sync")
        return 0

    print(plan.render())
    if check:
        return 1
    plan.apply()
    return 0
```

- [ ] **Step 4: Run test to verify it passes**

```bash
tests/ai-sync.test.sh
```

Expected: every `claude mcp generation` assertion `ok`.

- [ ] **Step 5: Commit**

```bash
git add .local/bin/ai-sync tests/ai-sync.test.sh
git commit -m "feat(ai): generate Claude Code mcp.json with --check drift detection"
```

---

### Task 4: Shared symlinks for skills, instructions, and settings

**Files:**
- Modify: `.local/bin/ai-sync`
- Modify: `tests/ai-sync.test.sh`

**Interfaces:**
- Consumes: `Plan`, `Action`, `build_plan`, `ai_dir`, `target_home`.
- Produces: `link(path: Path, dest: Path) -> Action | None` — returns `None` when the symlink already points at `dest`; replaces a wrong symlink; refuses to clobber a real file by raising `ConfigError`.

- [ ] **Step 1: Write the failing test**

Add before `report`:

```bash
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
```

Register `test_symlinks` after `test_claude_mcp`.

- [ ] **Step 2: Run test to verify it fails**

```bash
tests/ai-sync.test.sh
```

Expected: FAIL on `claude skills dir` — "not a symlink".

- [ ] **Step 3: Write minimal implementation**

Add to `.local/bin/ai-sync`:

```python
def link(path: Path, dest: Path):
    """Symlink `path` -> `dest`. Never destroys a real file."""
    if path.is_symlink():
        if Path(os.readlink(path)) == dest:
            return None
    elif path.exists():
        raise ConfigError(
            "%s exists and is not a symlink; move it aside "
            "(its content belongs in %s)" % (path, dest)
        )

    def run():
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.is_symlink() or path.exists():
            path.unlink()
        path.symlink_to(dest)

    return Action("link", "%s -> %s" % (path, dest), run)
```

Extend `build_plan` to add the links, keeping the Claude `mcp.json` write:

```python
def build_plan(servers) -> Plan:
    plan = Plan()
    home = target_home()
    src = ai_dir()

    plan.add(
        write_file(
            home / ".claude" / "mcp.json",
            render_claude(servers_for(servers, "claude")),
        )
    )

    agents = src / "AGENTS.md"
    plan.add(link(home / ".claude" / "skills", src / "skills"))
    plan.add(link(home / ".claude" / "CLAUDE.md", agents))
    plan.add(link(home / ".codex" / "AGENTS.md", agents))
    plan.add(link(home / ".claude" / "settings.json", src / "claude" / "settings.json"))
    return plan
```

`build_plan` can now raise `ConfigError`, so widen the guard in `main` — move the `build_plan` call inside the existing `try`:

```python
    try:
        servers = load_servers(ai_dir())
        plan = build_plan(servers)
    except ConfigError as exc:
        print("ai-sync: %s" % exc, file=sys.stderr)
        return 2
```

- [ ] **Step 4: Run test to verify it passes**

```bash
tests/ai-sync.test.sh
```

Expected: every `shared symlinks` assertion `ok`.

- [ ] **Step 5: Commit**

```bash
git add .local/bin/ai-sync tests/ai-sync.test.sh
git commit -m "feat(ai): link shared skills, AGENTS.md, and Claude settings"
```

---

### Task 5: Per-skill symlinks for Codex, with stale cleanup

**Files:**
- Modify: `.local/bin/ai-sync`
- Modify: `tests/ai-sync.test.sh`

**Interfaces:**
- Consumes: `link`, `Plan`, `ai_dir`, `target_home`.
- Produces: `plan_codex_skills(plan: Plan, src: Path, home: Path) -> None` — adds one link per skill directory and one `unlink` Action per stale symlink. Never touches `.system` or any non-symlink entry.

Codex owns `~/.codex/skills/.system`, so the directory itself cannot become a
symlink the way `~/.claude/skills` does. Each skill is linked individually.

- [ ] **Step 1: Write the failing test**

Add before `report`:

```bash
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
```

Register `test_codex_skills` after `test_symlinks`.

- [ ] **Step 2: Run test to verify it fails**

```bash
tests/ai-sync.test.sh
```

Expected: FAIL on `linked alpha` — "not a symlink".

- [ ] **Step 3: Write minimal implementation**

Add to `.local/bin/ai-sync`:

```python
def unlink_action(path: Path):
    def run():
        path.unlink()

    return Action("unlink", str(path), run)


def plan_codex_skills(plan: Plan, src: Path, home: Path) -> None:
    skills_src = src / "skills"
    skills_dst = home / ".codex" / "skills"

    wanted = {}
    if skills_src.is_dir():
        for entry in sorted(skills_src.iterdir()):
            if entry.is_dir() and not entry.name.startswith("."):
                wanted[entry.name] = entry

    for name, source in wanted.items():
        plan.add(link(skills_dst / name, source))

    if not skills_dst.is_dir():
        return
    for entry in sorted(skills_dst.iterdir()):
        # Only ever remove symlinks this tool created.
        if not entry.is_symlink() or entry.name in wanted:
            continue
        try:
            points_into_src = Path(os.readlink(entry)).parent == skills_src
        except OSError:
            continue
        if points_into_src:
            plan.add(unlink_action(entry))
```

Call it from `build_plan`, just before `return plan`:

```python
    plan_codex_skills(plan, src, home)
    return plan
```

- [ ] **Step 4: Run test to verify it passes**

```bash
tests/ai-sync.test.sh
```

Expected: every `codex per-skill links` assertion `ok`.

- [ ] **Step 5: Commit**

```bash
git add .local/bin/ai-sync tests/ai-sync.test.sh
git commit -m "feat(ai): link skills into Codex individually, pruning stale links"
```

---

### Task 6: Codex MCP sync through the CLI, with ownership tracking

**Files:**
- Modify: `.local/bin/ai-sync`
- Modify: `tests/ai-sync.test.sh`

**Interfaces:**
- Consumes: `Plan`, `Action`, `servers_for`, `target_home`.
- Produces:
  - `state_dir() -> Path` and `state_path() -> Path` (`managed.json` inside it).
  - `read_state() -> dict` / `write_state(dict) -> None`, shape `{"codex": ["name", ...]}`.
  - `codex_bin() -> str | None` — `None` when `AI_SYNC_CODEX_BIN` is set to empty.
  - `codex_installed(bin) -> set[str]` — names from `codex mcp list --json`.
  - `plan_codex_mcp(plan, servers, state) -> list[str]` — returns the new owned-name list to persist.

`codex mcp list` includes app-managed servers such as `cua_repl` and
`node_repl`. Removal is therefore restricted to names recorded in the state
file as previously installed by `ai-sync`.

- [ ] **Step 1: Write the failing test**

Add before `report`:

```bash
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
```

Register `test_codex_mcp` after `test_codex_skills`.

- [ ] **Step 2: Run test to verify it fails**

```bash
tests/ai-sync.test.sh
```

Expected: FAIL on `added github` — the codex log is empty.

- [ ] **Step 3: Write minimal implementation**

Add to `.local/bin/ai-sync`:

```python
import subprocess


def state_dir() -> Path:
    override = os.environ.get("AI_SYNC_STATE")
    if override:
        return Path(override)
    base = os.environ.get("XDG_STATE_HOME")
    root = Path(base) if base else Path.home() / ".local" / "state"
    return root / "ai-sync"


def state_path() -> Path:
    return state_dir() / "managed.json"


def read_state() -> dict:
    try:
        return json.loads(state_path().read_text())
    except (OSError, json.JSONDecodeError):
        return {}


def write_state(state: dict) -> None:
    path = state_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n")


def codex_bin():
    value = os.environ.get("AI_SYNC_CODEX_BIN", "codex")
    return value or None


def codex_installed(binary: str) -> set:
    try:
        proc = subprocess.run(
            [binary, "mcp", "list", "--json"],
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError:
        return set()
    if proc.returncode != 0:
        return set()
    try:
        listed = json.loads(proc.stdout or "[]")
    except json.JSONDecodeError:
        return set()
    return {item["name"] for item in listed if isinstance(item, dict) and "name" in item}


def _codex_run(binary: str, args: list) -> None:
    subprocess.run([binary] + args, check=False)


def plan_codex_mcp(plan: Plan, servers: dict, state: dict) -> list:
    binary = codex_bin()
    wanted = servers_for(servers, "codex")
    if binary is None:
        return sorted(state.get("codex", []))

    installed = codex_installed(binary)
    owned = set(state.get("codex", []))

    for name in sorted(wanted):
        cfg = wanted[name]
        if name in installed:
            continue
        args = ["mcp", "add", name]
        for key, value in sorted((cfg.get("env") or {}).items()):
            args += ["--env", "%s=%s" % (key, value)]
        args += ["--", cfg["command"]] + list(cfg.get("args", []))
        plan.add(
            Action(
                "codex",
                "+ %s" % name,
                lambda b=binary, a=args: _codex_run(b, a),
            )
        )

    # Only remove servers this tool installed. Never app-managed ones.
    for name in sorted(owned - set(wanted)):
        if name not in installed:
            continue
        plan.add(
            Action(
                "codex",
                "- %s" % name,
                lambda b=binary, n=name: _codex_run(b, ["mcp", "remove", n]),
            )
        )

    return sorted(wanted)
```

Change `build_plan` to thread state through and return it alongside the plan:

```python
def build_plan(servers):
    plan = Plan()
    home = target_home()
    src = ai_dir()
    state = read_state()

    plan.add(
        write_file(
            home / ".claude" / "mcp.json",
            render_claude(servers_for(servers, "claude")),
        )
    )

    agents = src / "AGENTS.md"
    plan.add(link(home / ".claude" / "skills", src / "skills"))
    plan.add(link(home / ".claude" / "CLAUDE.md", agents))
    plan.add(link(home / ".codex" / "AGENTS.md", agents))
    plan.add(link(home / ".claude" / "settings.json", src / "claude" / "settings.json"))
    plan_codex_skills(plan, src, home)
    new_codex = plan_codex_mcp(plan, servers, state)
    state["codex"] = new_codex
    return plan, state
```

Update `main` to unpack the tuple and persist state after applying:

```python
    try:
        servers = load_servers(ai_dir())
        plan, state = build_plan(servers)
    except ConfigError as exc:
        print("ai-sync: %s" % exc, file=sys.stderr)
        return 2

    plan_is_empty = not plan
    if plan_is_empty:
        write_state(state)
        if not check:
            print("ai-sync: already in sync")
        return 0

    print(plan.render())
    if check:
        return 1
    plan.apply()
    write_state(state)
    return 0
```

- [ ] **Step 4: Run test to verify it passes**

```bash
tests/ai-sync.test.sh
```

Expected: every `codex mcp sync` assertion `ok`.

- [ ] **Step 5: Commit**

```bash
git add .local/bin/ai-sync tests/ai-sync.test.sh
git commit -m "feat(ai): sync Codex MCP servers via CLI, tracking ownership

Only servers ai-sync installed are ever removed, so app-managed
servers like node_repl and cua_repl survive every sync."
```

---

### Task 7: Patch Zed's JSONC settings with absolute commands

**Files:**
- Modify: `.local/bin/ai-sync`
- Modify: `tests/ai-sync.test.sh`

**Interfaces:**
- Consumes: `write_file`, `servers_for`, `target_home`, `repo_root`.
- Produces:
  - `split_jsonc(text: str) -> tuple[str, str]` — leading comment/blank header, then the JSON body.
  - `resolve_command(command: str, home: Path) -> str` — absolute path, preferring `~/.local/bin`.
  - `render_zed(text: str, servers: dict, home: Path) -> str`.

Two constraints drive this task. Zed's `settings.json` opens with an 8-line
`//` header that a plain `json.loads` cannot parse and a plain `json.dumps`
would erase. And macOS GUI applications do not inherit the shell `PATH`, so
`gh-mcp` must be written as an absolute path — which is why the current
hand-written config already says `/Users/ikapo/.local/bin/gh-mcp`.

- [ ] **Step 1: Write the failing test**

Add before `report`:

```bash
test_zed() {
  printf 'zed jsonc patching\n'

  new_sandbox
  write_mcp <<'JSON'
{"servers": {"github": {"command": "gh-mcp", "targets": ["zed"]}}}
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
  assert_contains "kept absolute path verbatim" \
    "$(cat "$REPO/.config/zed/settings.json")" "/opt/custom/bin/x"
}
```

Register `test_zed` after `test_codex_mcp`.

- [ ] **Step 2: Run test to verify it fails**

```bash
tests/ai-sync.test.sh
```

Expected: FAIL on `added context_servers` — the file is unchanged.

- [ ] **Step 3: Write minimal implementation**

Add to `.local/bin/ai-sync`:

```python
import shutil


def split_jsonc(text: str):
    """Split leading // comments and blank lines from the JSON body."""
    lines = text.splitlines(keepends=True)
    index = 0
    while index < len(lines):
        stripped = lines[index].strip()
        if stripped == "" or stripped.startswith("//"):
            index += 1
            continue
        break
    return "".join(lines[:index]), "".join(lines[index:])


def resolve_command(command: str, home: Path) -> str:
    """Absolute path for `command`. GUI apps do not inherit shell PATH."""
    if command.startswith("/"):
        return command
    local = home / ".local" / "bin" / command
    if local.exists():
        return str(local)
    found = shutil.which(command)
    return found or command


def render_zed(text: str, servers: dict, home: Path) -> str:
    header, body = split_jsonc(text)
    try:
        data = json.loads(body)
    except json.JSONDecodeError as exc:
        raise ConfigError("Zed settings.json is not valid JSONC: %s" % exc) from exc

    if servers:
        data["context_servers"] = {
            name: {
                "command": resolve_command(servers[name]["command"], home),
                "args": list(servers[name].get("args", [])),
            }
            for name in sorted(servers)
        }
    else:
        data.pop("context_servers", None)

    return header + json.dumps(data, indent=2) + "\n"
```

Add to `build_plan`, before `plan_codex_skills`:

```python
    zed_settings = repo_root() / ".config" / "zed" / "settings.json"
    if zed_settings.exists():
        plan.add(
            write_file(
                zed_settings,
                render_zed(
                    zed_settings.read_text(), servers_for(servers, "zed"), home
                ),
            )
        )
```

- [ ] **Step 4: Run test to verify it passes**

```bash
tests/ai-sync.test.sh
```

Expected: every `zed jsonc patching` assertion `ok`.

- [ ] **Step 5: Verify against the real file without writing**

```bash
python3 - <<'PY'
import json, pathlib, sys
sys.path.insert(0, ".local/bin")
src = pathlib.Path(".config/zed/settings.json").read_text()
# Round-trip with no servers changed should alter only context_servers.
import importlib.util
spec = importlib.util.spec_from_file_location("ai_sync", ".local/bin/ai-sync")
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
header, body = mod.split_jsonc(src)
print("header lines:", header.count("\n"))
print("body parses:", bool(json.loads(body)))
PY
```

Expected: `header lines: 8` and `body parses: True`. This confirms the real
file's comment header is detected before Task 9 writes to it.

- [ ] **Step 6: Commit**

```bash
git add .local/bin/ai-sync tests/ai-sync.test.sh
git commit -m "feat(ai): patch Zed context_servers, preserving JSONC comments

Resolves bare commands to absolute paths because macOS GUI apps do
not inherit the shell PATH."
```

---

### Task 8: Human-readable output and usage

**Files:**
- Modify: `.local/bin/ai-sync`
- Modify: `tests/ai-sync.test.sh`

**Interfaces:**
- Consumes: `main`, `Plan`.
- Produces: `--help` output; rejection of unknown flags with exit 2.

- [ ] **Step 1: Write the failing test**

Add before `report`:

```bash
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
```

Register `test_cli` after `test_zed`.

- [ ] **Step 2: Run test to verify it fails**

```bash
tests/ai-sync.test.sh
```

Expected: FAIL on `help mentions --check` — `--help` currently prints nothing.

- [ ] **Step 3: Write minimal implementation**

Add to `.local/bin/ai-sync`:

```python
USAGE = """usage: ai-sync [--check] [--version] [--help]

Sync ~/.config/ai into Claude Code, Codex, and Zed.

  (no flags)  apply all changes; idempotent
  --check     report what would change; exit 1 on drift, 0 when clean
  --version   print version
  --help      print this message

Source of truth: ~/.config/ai
  AGENTS.md            shared instructions
  mcp.json             MCP server definitions
  skills/              personal skills
  claude/settings.json Claude Code settings"""
```

Replace the top of `main` with flag parsing:

```python
def main(argv):
    if "--help" in argv or "-h" in argv:
        print(USAGE)
        return 0
    if "--version" in argv:
        print(VERSION)
        return 0

    unknown = [a for a in argv if a != "--check"]
    if unknown:
        print("ai-sync: unknown argument: %s" % " ".join(unknown), file=sys.stderr)
        print(USAGE, file=sys.stderr)
        return 2

    check = "--check" in argv
```

Keep the rest of `main` from Task 6 unchanged.

- [ ] **Step 4: Run test to verify it passes**

```bash
tests/ai-sync.test.sh
shellcheck tests/ai-sync.test.sh
```

Expected: all assertions `ok`, `All tests passed.`, shellcheck silent.

- [ ] **Step 5: Commit**

```bash
git add .local/bin/ai-sync tests/ai-sync.test.sh
git commit -m "feat(ai): add --help and reject unknown flags"
```

---

### Task 9: Migrate real configuration and verify end to end

**Files:**
- Modify: `.config/ai/mcp.json`
- Create: `.config/ai/claude/settings.json`
- Modify: `.config/zed/settings.json` (by `ai-sync`)
- Modify: `docs/superpowers/specs/2026-09-04-unified-ai-config-design.md`

**Interfaces:**
- Consumes: the complete `ai-sync` from Tasks 1-8.
- Produces: working real configuration; the spec's open risk resolved with a recorded answer.

This task touches live configuration. Every step is reversible and backups
come first.

- [ ] **Step 1: Back up everything this task can affect**

```bash
mkdir -p ~/ai-sync-backup
cp ~/.claude/settings.json ~/ai-sync-backup/claude-settings.json
cp ~/.claude/mcp.json ~/ai-sync-backup/claude-mcp.json
cp ~/.codex/config.toml ~/ai-sync-backup/codex-config.toml
codex mcp list --json > ~/ai-sync-backup/codex-mcp-before.json
cp .config/zed/settings.json ~/ai-sync-backup/zed-settings.json
ls -la ~/ai-sync-backup
```

Expected: five files plus the JSON listing, all non-empty.

- [ ] **Step 2: Populate the real `mcp.json`**

Write `.config/ai/mcp.json`:

```json
{
  "servers": {
    "github": {
      "command": "gh-mcp",
      "args": [],
      "targets": ["claude", "zed", "codex"]
    },
    "ios-simulator": {
      "command": "npx",
      "args": ["-y", "ios-simulator-mcp"],
      "targets": ["claude"]
    }
  }
}
```

- [ ] **Step 3: Move Claude settings into the repo**

```bash
cp ~/.claude/settings.json .config/ai/claude/settings.json
python3 -c "import json;json.load(open('.config/ai/claude/settings.json'));print('valid')"
grep -c enabledPlugins .config/ai/claude/settings.json
```

Expected: `valid` and `1`. The file must still contain `enabledPlugins` and
`extraKnownMarketplaces`, which is what makes plugin-bundled MCP servers
reproducible on a new machine.

- [ ] **Step 4: Preview, then apply**

```bash
stow -t ~ .
ai-sync --check
```

Expected: exit 1, with a plan naming the Claude `mcp.json` write, four links,
the Zed patch, and `codex + github`. If `~/.claude/settings.json` is a real
file, `ai-sync` exits 2 and refuses — that is correct. Move it aside and retry:

```bash
mv ~/.claude/settings.json ~/ai-sync-backup/claude-settings-displaced.json
ai-sync
```

- [ ] **Step 5: Verify idempotency and the tool-facing results**

```bash
ai-sync                 # expect: already in sync
ai-sync --check; echo "check exit: $?"
claude mcp list
codex mcp list --json | python3 -c 'import json,sys;print(sorted(s["name"] for s in json.load(sys.stdin)))'
```

Expected: `already in sync`; `check exit: 0`; Claude lists `github` and
`ios-simulator`; Codex lists `github` alongside `node_repl` and `cua_repl`.

- [ ] **Step 6: Confirm the ChatGPT app's Codex config survived**

```bash
diff <(grep -E '^\[(plugins|marketplaces)' ~/ai-sync-backup/codex-config.toml) \
     <(grep -E '^\[(plugins|marketplaces)' ~/.codex/config.toml) \
  && echo "app-managed blocks intact"
grep -c 'node_repl' ~/.codex/config.toml
```

Expected: `app-managed blocks intact` and a nonzero count for `node_repl`.

- [ ] **Step 7: Verify Zed**

```bash
git diff --stat .config/zed/settings.json
head -9 .config/zed/settings.json
```

Expected: the 8-line `//` header is byte-identical, and the only change is
inside `context_servers`. Then restart Zed and confirm `github` initializes in
the log:

```bash
grep -i 'context server\|github' ~/Library/Logs/Zed/Zed.log | tail -20
```

Expected: a successful handshake for `github`, no "missing Authorization
header" error.

- [ ] **Step 8: Resolve the spec's open risk empirically**

The spec records one unverified question: whether Claude Code preserves the
`settings.json` symlink when it writes.

```bash
ls -la ~/.claude/settings.json
```

In Claude Code, run `/config` and change the theme. Then:

```bash
ls -la ~/.claude/settings.json
git -C ~/Workspace/Code/dotfiles diff --stat .config/ai/claude/settings.json
```

If it is still a symlink and the repo file shows the theme change, the design
worked. If it is now a regular file, the symlink was clobbered — record that
and switch `~/.claude/settings.json` to a `write_file` copy with a drift
warning instead of a link, which is the fallback the spec already defines.

Replace the spec's "Known Risk" section heading body with the observed
outcome, stating plainly which behavior occurred.

- [ ] **Step 9: Test the skills path with a throwaway skill**

```bash
mkdir -p .config/ai/skills/hello-ai
cat > .config/ai/skills/hello-ai/SKILL.md <<'EOF'
---
name: hello-ai
description: Smoke test that .config/ai skills resolve in every tool.
---

Say "hello from .config/ai" and stop.
EOF
ai-sync
ls -la ~/.claude/skills ~/.codex/skills/hello-ai
```

Expected: `~/.claude/skills` is a symlink into the repo and
`~/.codex/skills/hello-ai` is a symlink. Confirm `/hello-ai` resolves in a new
Claude Code session and in Codex, then remove it:

```bash
rm -rf .config/ai/skills/hello-ai
ai-sync
[ -e ~/.codex/skills/hello-ai ] && echo "STALE LINK BUG" || echo "pruned"
```

Expected: `pruned`.

- [ ] **Step 10: Confirm the secret hook still guards the new directory**

The fake token is assembled at runtime rather than written literally, so this
plan file itself does not contain a token-shaped string for the hook to catch.

```bash
cp .config/ai/mcp.json /tmp/mcp-real-backup.json
FAKE="ghp_$(printf '0123456789abcdefghijklmnopqrstuvwxyz')"
printf '{"servers":{"x":{"command":"y","targets":["claude"],"env":{"TOKEN":"%s"}}}}' \
  "$FAKE" > .config/ai/mcp.json
git add .config/ai/mcp.json
git commit -m "test: should be blocked" ; echo "exit: $?"
cp /tmp/mcp-real-backup.json .config/ai/mcp.json
git add .config/ai/mcp.json
git status --short .config/ai/mcp.json
```

Expected: a nonzero exit and the hook's rejection message. Restore the real
file before continuing, and confirm `git status` shows no staged secret.

- [ ] **Step 11: Full test suite and stow check**

```bash
tests/ai-sync.test.sh
shellcheck tests/ai-sync.test.sh
stow -n -v -t ~ . 2>&1 | grep -E 'claude/settings.local|docs|tests' && echo "LEAK" || echo "stow clean"
```

Expected: `All tests passed.`, shellcheck silent, `stow clean`.

- [ ] **Step 12: Commit**

```bash
git add .config/ai/mcp.json .config/ai/claude/settings.json \
        .config/zed/settings.json \
        docs/superpowers/specs/2026-09-04-unified-ai-config-design.md
git commit -m "feat(ai): migrate real MCP and Claude settings into .config/ai

github now reaches Claude Code, Codex, and Zed from one definition.
Records the observed settings.json symlink behavior in the spec."
```

---

## Self-Review

**Spec coverage:**

| Spec section | Task |
|---|---|
| Layout | 1 |
| MCP source of truth / schema | 2 |
| Sync: Claude `mcp.json` | 3 |
| Sync: `~/.claude/skills`, `CLAUDE.md`, `AGENTS.md`, `settings.json` | 4 |
| Sync: Codex per-skill links | 5 |
| Sync: Codex MCP via CLI | 6 |
| Sync: Zed `context_servers` | 7 |
| Secrets | Global Constraints; verified in 9 step 10 |
| Known risk: `settings.json` writes | 9 step 8 |
| Interface (`ai-sync`, `--check`) | 3, 8 |
| Bundled fix (`.stow-local-ignore`) | 1 steps 6-7 |
| Testing items 1-9 | 3, 6, 9 steps 5, 9, 11 |
| Migration items 1-6 | 9 steps 1-3 |

Two additions the spec did not anticipate, both discovered by inspecting the
live tools:

- **Codex ownership tracking** (Task 6). `codex mcp list` returns app-managed
  `cua_repl` and `node_repl`. Without a state file recording what `ai-sync`
  installed, the removal pass would delete them.
- **Zed absolute command resolution** (Task 7). macOS GUI apps do not inherit
  the shell `PATH`, so a bare `gh-mcp` would fail to launch under Zed.

**Type consistency:** `Action(verb, detail, run)` is constructed identically in
`write_file`, `link`, `unlink_action`, and `plan_codex_mcp`. `build_plan`
returns `(plan, state)` from Task 6 onward, and `main` unpacks the tuple in the
same task. `servers_for(servers, target)` is called with the same signature in
Tasks 3, 6, and 7.
