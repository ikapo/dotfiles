# Read by every zsh, login or not, before anything else. Only ZDOTDIR lives
# here; the rest of the environment is in $ZDOTDIR/.zprofile, which zsh now
# looks for in ZDOTDIR rather than ~.
export ZDOTDIR="$HOME/.config/zsh"

# Stop /etc/zshrc_Apple_Terminal writing per-window history into $ZDOTDIR.
export SHELL_SESSIONS_DISABLE=1
