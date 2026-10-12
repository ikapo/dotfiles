# A zsh that starts with ZDOTDIR already set (inherited from a parent, or set
# by a terminal or tool) reads this file instead of ~/.zshenv. Hand off to
# ~/.zshenv so it still gets GNUPGHOME and the rest. A shell without ZDOTDIR
# reads only ~/.zshenv: zsh picks .zshenv from the ZDOTDIR in effect at
# startup, so setting ZDOTDIR there does not bring this file in too.
[[ -r "$HOME/.zshenv" ]] && source "$HOME/.zshenv"
