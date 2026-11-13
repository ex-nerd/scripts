#!/bin/bash
# shellcheck disable=SC2139  # alias values intentionally expand $VAR (LS_OPTIONS/EDITOR) at source time
#
# Handy aliases
#

_init_aliases() {
  # MacOS
  alias macsleep='osascript -e '\''tell application "System Events" to sleep'\'''

  # Colorize and customize the sudo prompt
  alias sudo=$'command sudo -p "\e[33msudo \e[1;31m%U\e[0;33m password for \e[0;34m%u\e[36m@\e[34m%h\e[0m: "'

  # Add some aliases to prevent accidental overwriting/deleting
  alias rm='/bin/rm -i'
  alias cp='/bin/cp -i'
  alias mv='/bin/mv -i'

  # Add some ls-related aliases

  if command -v lsd &>/dev/null; then

    alias ls="lsd -F"
    alias ll="lsd -laF"
    alias llg="lsd -laF --git"
    alias llt="lsd -laF --tree --depth=2"

  else

    local _ls_options=""
    case "$OSTYPE" in
      darwin*)
        _ls_options=' -G -v'
        ;;
      linux*)
        _ls_options=' -v --color=auto --show-control-chars'
        ;;
    esac

    alias ls="ls -F$_ls_options"
    alias ll="ls -laFh$_ls_options"

  fi

  # And some program-related shortcuts
  alias vi='vim'
  alias v='vim -N'
  alias vim='vim -N'

  # Ubuntu naming annoyance
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    alias bat=batcat
  fi

  # Helpful shortcuts

  local _grep_cmd="grep"
  if command -v rg &>/dev/null; then
    _grep_cmd="rg"
  fi

  alias ff="find . -type f | $_grep_cmd "
  alias fd="find . -type d | $_grep_cmd "

  # Git
  alias gitlog='git logn'
  alias gg='git grep'

  # Dropbox
  alias clean_dropbox="find ~/Dropbox -name '* conflicted copy *' -exec rm {} \+"
}
_init_aliases
unset -f _init_aliases