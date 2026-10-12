# Read by every zsh, login or not, before anything else. Only what every
# shell needs lives here; the rest of the environment is in $ZDOTDIR/.zprofile,
# which zsh now looks for in ZDOTDIR rather than ~.
export ZDOTDIR="$HOME/.config/zsh"

# One GnuPG home for every shell, login or not. ~/.gnupg is a symlink to it
# for programs that never see this variable (GUI apps, launchd).
export GNUPGHOME="$HOME/.config/gnupg"

# Stop /etc/zshrc_Apple_Terminal writing per-window history into $ZDOTDIR.
export SHELL_SESSIONS_DISABLE=1
