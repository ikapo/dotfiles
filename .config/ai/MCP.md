# MCP servers

Instructions for setting up MCP servers on a new machine. Written to be handed
to an AI agent: each server below has the exact command to install it.

Nothing here is automated and nothing is generated. Run the commands for the
servers you want, skip the rest.

**No secret belongs in this repository.** Prefer a remote server, whose token
lives in the tool's own credential store after a browser login. A local server
that needs a credential must read it from the Keychain at runtime.

## Read this before installing anything

**Headless environments.** Servers marked **GUI-only** below drive an
application with a window — a simulator, a browser, a desktop app. On a server,
a container, a CI runner, or any SSH session with no display, they cannot work.
Skip them. Nothing else in this file depends on them, and skipping one is not a
partial setup: it is the correct setup for that machine.

**Check before adding.** A server may already be registered, or may come from a
plugin under a different name. Look first:

```sh
claude mcp list      # Claude Code
codex mcp list       # Codex
```

A name already present is not a reason to remove it. Ask before replacing one.

## github

Remote, over OAuth. No binary, no token stored here.

**Skip in a headless environment?** No — it is a plain HTTPS API and works
anywhere with a network.

GitHub's authorization server supports neither dynamic client registration nor
CIMD, so every tool has to be handed a client ID you registered by hand. Do
this once per person, not per machine:

1. Go to <https://github.com/settings/developers> → **New OAuth App**.
2. Callback URL: `http://localhost:33418/callback`.
3. Copy the Client ID. **Do not generate a client secret** — GitHub advertises
   PKCE (`code_challenge_methods_supported: ["S256"]`), so a public client
   needs none, and a secret could not be stored here anyway.

Then, substituting the client ID:

```sh
# Claude Code
claude mcp add --scope user --transport http \
  --client-id <CLIENT_ID> --callback-port 33418 \
  github https://api.githubcopilot.com/mcp/

# Codex
codex mcp add github --url https://api.githubcopilot.com/mcp/ \
  --oauth-client-id <CLIENT_ID>
codex mcp login github
```

Claude Code authenticates on first use — run `/mcp` and pick `github`.

If the browser shows a redirect-URI mismatch, the `redirect_uri=` parameter in
the URL is the one the tool actually sent. Put that exact string in the OAuth
App's callback field.

**Zed cannot use this server.** Zed 1.18 supports only CIMD and dynamic
registration (`crates/context_server/src/oauth.rs`,
`determine_registration_strategy`) and has no setting for a hand-registered
client ID. Its only alternative is a literal `Authorization` header in
`settings.json`, which is tracked in this repo — so do not add it there.

## ios-simulator

Local, launched with `npx`. Drives the iOS Simulator for UI automation and
screenshots.

**Skip in a headless environment? Yes — GUI-only.** It needs the iOS Simulator,
which needs macOS with a display and Xcode installed. On a Linux server, a
container, or a remote session with no display, do not install it. There is no
headless substitute; omit it and carry on.

```sh
claude mcp add --scope user ios-simulator -- npx -y ios-simulator-mcp
```

Claude Code only. Codex and Zed do not need it.

## Adding a server that needs a secret

Only when no remote equivalent exists. Never write the token into any file in
this repository.

1. Store the credential in the Keychain. The same command rotates it later:

   ```sh
   security add-generic-password -a "$USER" -s <service-name> -w '<token>' -U
   ```

2. Add a wrapper at `~/.local/bin/<name>-mcp`, `chmod +x` it. Use an absolute
   path for the binary — Zed and the desktop apps do not inherit `$PATH`:

   ```sh
   #!/bin/sh
   TOKEN_ENV_VAR=$(security find-generic-password -s <service-name> -w) || {
   	echo "<name>-mcp: no '<service-name>' entry in Keychain" >&2
   	exit 1
   }
   export TOKEN_ENV_VAR

   exec /opt/homebrew/bin/<server> stdio "$@"
   ```

3. Register the wrapper, by absolute path:

   ```sh
   claude mcp add --scope user <name> -- /Users/<you>/.local/bin/<name>-mcp
   ```

4. Verify the handshake before trusting it. A `serverInfo` reply means both the
   Keychain read and the binary work:

   ```sh
   { printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"probe","version":"0"}}}'
     sleep 2
   } | ~/.local/bin/<name>-mcp
   ```

`.githooks/pre-commit` blocks any commit containing a credential-shaped string,
but it is a backstop, not permission to be careless.

## Where each tool keeps this

Useful when something does not show up. All three read their config once at
startup — **restart the tool after changing it.**

| Tool | File | Notes |
|---|---|---|
| Claude Code | `~/.claude.json`, key `mcpServers` | Not `~/.claude/mcp.json`, which Claude Code never reads. Claude Code rewrites this file as it runs; edit it with the tool closed, or use `claude mcp add`. |
| Codex | `~/.codex/config.toml`, `[mcp_servers.*]` | Also written by the ChatGPT desktop app; prefer `codex mcp add`. |
| Zed | `.config/zed/settings.json`, `context_servers` | Tracked in this repo, so no token may appear in it. Do not add `"source": "custom"` — Zed 1.18 rejects it. |
