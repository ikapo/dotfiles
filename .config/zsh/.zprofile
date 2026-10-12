#!/bin/sh

# Profile file. Runs on login. Environmental variables are set here.

# Homebrew: puts /opt/homebrew/bin on $PATH. Keep it first; later lines need it.
eval "$(/opt/homebrew/bin/brew shellenv)"

export EDITOR="nvim"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"

# Adds `~/.local/bin` to $PATH
export PATH="$PATH:$HOME/.local/bin"

#JS
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export PATH="/opt/homebrew/opt/node@24/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/node@24/lib"
export CPPFLAGS="-I/opt/homebrew/opt/node@24/include"
export NODE_REPL_HISTORY=""
# Prisma telemetry disable
export CHECKPOINT_DISABLE=1

# ~/ Clean-up:
export LESSHISTFILE="-"

# Other program settings:
export LESS=-R
export LESS_TERMCAP_mb="$(printf '%b' '[1;31m')"
export LESS_TERMCAP_md="$(printf '%b' '[1;36m')"
export LESS_TERMCAP_me="$(printf '%b' '[0m')"
export LESS_TERMCAP_so="$(printf '%b' '[01;44;33m')"
export LESS_TERMCAP_se="$(printf '%b' '[0m')"
export LESS_TERMCAP_us="$(printf '%b' '[1;32m')"
export LESS_TERMCAP_ue="$(printf '%b' '[0m')"
