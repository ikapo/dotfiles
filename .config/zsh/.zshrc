# Enable colors and change prompt:
autoload -U colors && colors
PS1="%B%{$fg[blue]%}%1~%{$reset_color%} -> %b"


# History in XDG state dir (zsh won't create the dir and silently saves nothing):
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${HISTFILE:h}"
setopt INC_APPEND_HISTORY	# Write each command as it runs, not only on exit.

# Basic auto/tab complete (dump and cache in XDG cache, out of the repo):
zsh_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$zsh_cache"
autoload -U compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' cache-path "$zsh_cache/zcompcache"
zmodload zsh/complist
compinit -d "$zsh_cache/zcompdump"
unset zsh_cache
_comp_options+=(globdots)		# Include hidden files.

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char
# Option+Backspace (Ghostty sends ESC DEL) and ctrl-w delete the previous word,
# past where insert mode started too (the vi-* versions stop there).
bindkey -M viins '^[^?' backward-kill-word
bindkey -M viins '^w' backward-kill-word

# Change cursor shape for different vi modes. Ghostty's own cursor handling is
# off (shell-integration-features = no-cursor), so this is the only owner.
_vi_cursor_insert='\e[5 q'  # blinking bar
_vi_cursor_normal='\e[2 q'  # steady block
_vi_cursor_replace='\e[3 q' # blinking underline
_vi_cursor() {
  case $KEYMAP in
    vicmd|visual|viopp) echo -ne $_vi_cursor_normal ;;
    *) [[ $ZLE_STATE == *overwrite* ]] && echo -ne $_vi_cursor_replace ||
         echo -ne $_vi_cursor_insert ;;
  esac
}
zle-keymap-select() { _vi_cursor }
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # every prompt starts in insert mode
    _vi_cursor
}
zle -N zle-line-init
# Hand programs the terminal's default shape; nvim sets its own anyway.
preexec() { echo -ne '\e[0 q' ;}
# Programs run from inside a widget (nvim via ctrl-e) leave their shape behind.
_vi_cursor_edit_command_line() { edit-command-line; _vi_cursor }

# Use ranger to switch directories and bind it to ctrl-o
rangercd () {
    tmp="$(mktemp)"
    ranger --choosedir="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        rm -f "$tmp"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}

bindkey -s '^o' 'rangercd\n'

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line _vi_cursor_edit_command_line
bindkey '^e' edit-command-line

# Search backward with ctrl-r:
bindkey '^R' history-incremental-search-backward

# gpg-agent needs the tty to put its passphrase prompt on.
export GPG_TTY=$(tty)

# Load aliases if existent.
[ -f "$HOME/.config/aliasrc" ] && source "$HOME/.config/aliasrc"

#Private Aliases
[ -f "$HOME/.config/paliasrc" ] && source "$HOME/.config/paliasrc"

eval "$(zoxide init --cmd cd zsh)"
source <(fzf --zsh)

# Load zsh-syntax-highlighting; should be last.
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh




