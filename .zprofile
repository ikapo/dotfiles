eval "$(/opt/homebrew/bin/brew shellenv)"
#!/bin/sh

# Profile file. Runs on login. Environmental variables are set here.
export EDITOR="nvim"

# Adds `~/.local/bin` to $PATH
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export PATH="$PATH:$HOME/.local/bin"

#Golang
export GOBIN="$HOME/Workspace/Go/bin"
export GOPATH="$HOME/Workspace/Go"
export PATH="$PATH:$GOBIN"

#Rust
export CARGO_HOME="$XDG_CONFIG_HOME"/cargo
export RUSTUP_HOME="$XDG_CONFIG_HOME"/rustup
export PATH="$PATH:$CARGO_HOME/bin"

#JS
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export PATH="/opt/homebrew/opt/node@20/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/node@20/lib"
export CPPFLAGS="-I/opt/homebrew/opt/node@20/include"
export NODE_REPL_HISTORY=""
# Prisma telemetry disable
export CHECKPOINT_DISABLE=1

# ~/ Clean-up:
export XAUTHORITY="$XDG_CONFIG_HOME/Xauthority"
export GTK2_RC_FILES="$HOME/.config/gtk-2.0/gtkrc-2.0"
export LESSHISTFILE="-"
export INPUTRC="$HOME/.config/inputrc"
export ZDOTDIR="$HOME/.config/zsh"
export GNUPGHOME="$HOME/.config/gnupg"
export GPG_TTY=$(tty)
export PASSWORD_STORE_DIR="$HOME/.local/share/password-store"
export PYLINTHOME="$XDG_CACHE_HOME/pylint"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# Other program settings:
export LESS=-R
export LESS_TERMCAP_mb="$(printf '%b' '[1;31m')"
export LESS_TERMCAP_md="$(printf '%b' '[1;36m')"
export LESS_TERMCAP_me="$(printf '%b' '[0m')"
export LESS_TERMCAP_so="$(printf '%b' '[01;44;33m')"
export LESS_TERMCAP_se="$(printf '%b' '[0m')"
export LESS_TERMCAP_us="$(printf '%b' '[1;32m')"
export LESS_TERMCAP_ue="$(printf '%b' '[0m')"
