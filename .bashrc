#!/bin/bash
#
# This file is sourced by all *interactive* bash shells on startup, including
# some apparently interactive shells such as scp and rcp that can't tolerate any
# output.
#
# It attempts to keep all settings completely generic so that any user can
# install this without fear of any unusual aliases or preferences being forced
# upon them.
#
# In order to allow for per-host customization, this file will source sub-files
# ~/.bashrc.d/*.sh.
#
# Because I primarily use zsh, this will also source ~/.zsh/functions/* and
# expose them as bash functions, similar to the zsh autoload mechanism.
#

# shellcheck disable=SC1090 disable=SC1091

###############################################################################
# Test for an interactive shell.  There is no need to set anything past this
# point for scp and rcp, and it's important to refrain from outputting anything
# in those cases.  However, we should add a couple of extra paths in case this
# is rsync (in case rsync itself is stored somewhere like /usr/local/bin).

if [[ "$-" != *i* ]]; then
  for dir in /usr/*/bin/ /opt/*/bin/; do
    export PATH="$PATH:$dir"
  done
  return
fi

###############################################################################
# Source any global definitions that exist
#
for _file in \
    /etc/*bashrc \
    /etc/profile \
    /etc/bash/bashrc \
    /etc/bash_completion \
    ; do
  [[ -f "$_file" ]] && source "$_file"
done
unset _file

###############################################################################
# Collect information about the environment and the current user, which will
# be used throughout this configuration file and then cleared at the end.
#

typeset _is_mac=""
typeset _is_linux=""
typeset _is_admin=""
typeset _user_groups=""

if command -v id &> /dev/null; then
  _user_groups=" $(id -nG) "
fi

case "$OSTYPE" in
  darwin*)
    _is_mac=1
    if [[ "$_user_groups" == *" admin "* || "$_user_groups" == *" root "* ]]; then
      _is_admin=1
    fi
    ;;
  linux*)
    _is_linux=1
    if [[ "$_user_groups" == *" wheel "* || "$_user_groups" == *" root "* ]]; then
      _is_admin=1
    fi
    ;;
esac

###############################################################################
# Nice path functions with slight modifications from:
#   http://stackoverflow.com/questions/370047/what-is-the-most-elegant-way-to-remove-a-path-from-the-path-variable-in-bash
#

append_path()  {
  local _new=${1/%\//}
  [[ -d "$_new" ]] || return
  remove_path "$_new"
  export PATH="$PATH:$_new"
}
prepend_path() {
  local _new=${1/%\//}
  [[ -d "$_new" ]] || return
  remove_path "$_new"
  export PATH="$_new:$PATH"
}
remove_path() {
  local target=${1%/}
  # -v passes the variable safely; printf '%s' avoids echo/backslash quirks
  PATH=$(printf '%s' "$PATH" | awk -v RS=":" -v ORS=":" -v target="$target" '$0 != target')
  # Remove trailing colon if one remains
  export PATH=${PATH%:}
}

###############################################################################
# Adjust shell behavior and key bindings
#

# Set locale settings to UTF-8 for proper handling of non-ASCII characters
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_COLLATE=C

# Like zsh's "setopt interactive_comments": allow # to start a comment on the
# command line. (Requires bash 5.1+; ignore it on older shells.)
shopt -s interactive_comments 2>/dev/null

# Like zsh's "setopt no_banghist": disable ! history expansion
set +H

# Like zsh's "unsetopt ignoreeof": allow Ctrl-D to log out.
set +o ignoreeof

# Enable spellchecking/guessing for cd commands (useful for typo'd pathnames)
shopt -s cdspell

# Like zsh's "setopt correct": guess/correct misspelled commands (not just cd).
# (Requires bash 5.1+; ignore it on older shells.)
shopt -s spellcheck 2>/dev/null

# Store multi-line commands as one line in the history
shopt -s cmdhist

# Turn on checkwinsize so we get $LINES and $COLUMNS
shopt -s checkwinsize

# History configuration
shopt -s histappend
export HISTFILESIZE=100000
export HISTSIZE=200000

# Give the time in the history file
export HISTTIMEFORMAT="%F %T "
# Ignore duplicate history entries and those starting with whitespace
export HISTCONTROL=ignoreboth
# Prevent certain commands from cluttering the history
export HISTIGNORE="&:l:ls:ll:[bf]g:clear:exit:history:history *:history|*:cd:cd -:df"

# Update the bash history after every command rather then the end of the session
if [[ "${PROMPT_COMMAND}" == *\; ]]; then
  export PROMPT_COMMAND="${PROMPT_COMMAND} history -a"
elif [[ -n "${PROMPT_COMMAND}" ]]; then
  export PROMPT_COMMAND="${PROMPT_COMMAND}; history -a"
else
  export PROMPT_COMMAND="history -a"
fi

# Enable color for gnu tools
export CLICOLOR=1

# Instruct less to render nerdfonts directly
export LESSUTFCHARDEF="E000-F8FF:p,F0000-FFFFD:p,100000-10FFFD:p"

# Default less to color rendering, case-insensitive search, and auto-exit for short files
export LESS="-R -i -F"

# Default tools
export EDITOR=vim
if command -v batcat &> /dev/null; then
  export PAGER="batcat"
  export MANPAGER="batcat -l man -p"
elif command -v bat &> /dev/null; then
  export PAGER="bat"
  if command -v batman &> /dev/null; then
    eval "$(batman --export-env)"
  elif [[ $_is_mac ]]; then
    # macOS mandoc needs extra help to avoid random control characters in the output
    # See https://github.com/sharkdp/bat/discussions/3027
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  else
    export MANPAGER="bat -l man -p"
  fi
else
  export PAGER="less"
fi

###############################################################################
# Extend the path
#

if [[ $_is_admin ]]; then
  for dir in \
      /usr/*/sbin/ \
      /opt/*/sbin/ \
      ; do
    prepend_path "$dir"
  done
  prepend_path /usr/sbin
  prepend_path /sbin
fi

for dir in \
    /usr/*/bin/ \
    /opt/*/bin/ \
    /usr/java/*/bin/ \
    ; do
  prepend_path "$dir"
done

# My user directories, at the front of PATH (in this priority order:
# ~/.local/bin, ~/bin, ~/scripts). Prepended in reverse because prepend_path
# puts each entry at the front.
prepend_path ~/scripts
prepend_path ~/bin
prepend_path ~/.local/bin

if [[ -d "$HOME/go" ]]; then
  export GOPATH="${GOPATH:+$GOPATH:}$HOME/go"
  [[ -d "$HOME/go/bin" ]] && append_path "$HOME/go/bin"
fi

# Added by LM Studio CLI (lms)
if [[ -d "$HOME/.lmstudio/bin" ]]; then
  append_path "$HOME/.lmstudio/bin"
fi

###############################################################################
# GNU utilities
#

# Use gnu utilities if they're available
if [[ $_is_mac ]]; then
  _init_gnu_utils() {
    local _app
    # Note: grep is handled separately below.
    for _app in find tar sed xargs; do
      local _gnu_app="g$_app"
      if command -v $_gnu_app &> /dev/null; then
        alias -- "$_app=$_gnu_app"
      fi
    done
  }
  _init_gnu_utils
  unset -f _init_gnu_utils
fi

_init_grep_alias() {
  # Note: this list should be kept in sync with the values in .ripgreprc
  local -a exclude_files=(
    ".DS_Store"
  )
  local -a exclude_dirs=(
    # Version Control & IDEs
    ".git"
    ".idea"
    ".svn"
    "CVS"
    # Python & Environments
    "__pycache__"
    ".venv"
    "node_modules"
    # Caches
    ".cache"
    ".direnv"
    ".*_cache"
  )

  # Convert the array into repeated exclude flags programmatically
  local -a grep_options=("--color=auto")
  local _file _dir
  for _file in "${exclude_files[@]}"; do
    grep_options+=("--exclude='$_file'")
  done
  for _dir in "${exclude_dirs[@]}"; do
    grep_options+=("--exclude-dir='$_dir'")
  done

  # Check for GNU grep, fallback to standard grep
  local grep_cmd="grep"
  if command -v ggrep &>/dev/null; then
    grep_cmd="ggrep"
  fi

  # In bash, use [*] to expand all array elements joined by spaces
  alias grep="$grep_cmd ${grep_options[*]}"
}
_init_grep_alias
unset -f _init_grep_alias

# Ensure the deprecated environment variable is unset
unset GREP_OPTIONS

###############################################################################
# Initialize homebrew
#

typeset _brew=""

# Find the Homebrew binary without spawning subshells for standard paths
if [[ -x /opt/homebrew/bin/brew ]]; then
  _brew="/opt/homebrew/bin/brew"
elif [[ -x /usr/local/bin/brew ]]; then
  _brew="/usr/local/bin/brew"
elif command -v brew &> /dev/null; then
  _brew=$(command -v brew)
fi

if [[ -n "$_brew" ]]; then
  # Set Homebrew's environment variables (HOMEBREW_PREFIX, HOMEBREW_CELLAR,
  # MANPATH) and add its bin/sbin directories to PATH.
  eval "$("$_brew" shellenv)"

  # Suppress homebrew's "Installing/Removing ..." environment hints
  export HOMEBREW_NO_ENV_HINTS=1

  # Installed brew cask programs bypass the "downloaded from the internet" warning
  export HOMEBREW_CASK_OPTS="--no-quarantine"

  # Load bash completions shipped with the bash-completion formula
  if [[ -f "$HOMEBREW_PREFIX/etc/bash_completion" ]]; then
    source "$HOMEBREW_PREFIX/etc/bash_completion"
  fi

  # Homebrew python
  append_path "$HOMEBREW_PREFIX/opt/python/libexec/bin"
fi

unset _brew

###############################################################################
# User functions and additional configuration
#

# Load zsh functions
if [ -d "$HOME"/.zsh/functions ]; then
  for file in "$HOME"/.zsh/functions/*; do
    [ -f "$file" ] && [ -r "$file" ] || continue

    func_name="${file##*/}" # basename

    # Ignore dotfiles (e.g., .DS_Store, .gitkeep) and compiled Zsh files
    [[ "$func_name" == .* || "$func_name" == *.zwc ]] && continue

    # Replace 'bash' with 'zsh' if the files use Zsh-specific syntax
    eval "${func_name}() { bash \"${file}\" \"\$@\"; }"
  done
fi

# Load any custom extensions
if [[ -d ~/.bashrc.d ]]; then
  for file in ~/.bashrc.d/*.sh; do
    if [[ -d "$file" ]]; then
      continue
    fi
    source "$file"
  done
fi

###############################################################################
# Cleanup temporary variables
#

unset _is_mac _is_linux _is_admin _user_groups
unset -f prepend_path
unset -f append_path
unset -f remove_path

###############################################################################
# Additional config for external programs
#

# Use my global ripgrep config (hidden files, exclusions, etc.)
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# Activate iterm2 shell integration
if [[ -e "$HOME/.iterm2_shell_integration.bash" ]]; then
  source "$HOME/.iterm2_shell_integration.bash"
else
  printf "\033[1;91m⚠️  No iTerm2 integration. \033[0;33mPlease install via iTerm2 menu.\033[0m\n"
fi

# Initialize mise before direnv
if [[ $(command -v mise) ]]; then
  eval "$(mise activate bash)"
fi

# init direnv
if [[ $(command -v direnv) ]]; then
  eval "$(direnv hook bash)"
fi

# Init starship
if [[ $(command -v starship) ]]; then
  eval "$(starship init bash)"
else
  # Declare temporary formatting variables to keep them out of the final environment
  typeset c_red c_lred c_green c_blue c_cyan c_dgray c_reset
  typeset esc osc bel st_seq title_fmt

  # Define readable escape code building blocks
  esc="\033"        # ESC character
  osc="${esc}]0;"   # Operating System Command (Window/Tab title start)
  bel="\007"        # Bell character (OSC terminator)
  apc="${esc}_"     # Application Program Command (Screen/tmux internal title start)
  st_seq="${esc}\\" # String Terminator (APC terminator)

  # Format string for user@host:path
  title_fmt="%s@%s:%s"

  # 1. Update window/tab titles automatically based on terminal type
  case "$TERM" in
    xterm*|rxvt|Eterm|eterm|linux)
      # Sets outer terminal window/tab title: OSC 0; title BEL
      PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }printf \"${osc}${title_fmt}${bel}\" \"\${USER}\" \"\${HOSTNAME%%.*}\" \"\${PWD/#\$HOME/~}\""
      ;;
    screen*|tmux*)
      # Sets both multiplexer internal title (APC ... ST) and outer terminal title (OSC 0 ... BEL)
      PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }printf \"${apc}${title_fmt}${st_seq}${osc}${title_fmt}${bel}\" \"\${USER}\" \"\${HOSTNAME%%.*}\" \"\${PWD/#\$HOME/~}\" \"\${USER}\" \"\${HOSTNAME%%.*}\" \"\${PWD/#\$HOME/~}\""
      ;;
  esac

  # 2. Set ANSI colors safely (respecting NO_COLOR standards)
  if [[ -z "${NO_COLOR:-}" ]]; then
    c_red="\[\e[31m\]"
    c_lred="\[\e[91m\]"
    c_green="\[\e[32m\]"
    c_blue="\[\e[34m\]"
    c_cyan="\[\e[36m\]"
    c_dgray="\[\e[90m\]"
    c_reset="\[\e[0m\]"
  else
    c_red="" c_lred="" c_green="" c_blue="" c_cyan="" c_dgray="" c_reset=""
  fi

  # 3. Apply prompt based on privileges (Red for Root, Blue/Cyan for standard users)
  if [[ $EUID == 0 ]]; then
    PS1="${c_red}\u${c_lred}@\h${c_reset}: ${c_green}\w ${c_lred}#${c_reset} "
  else
    PS1="${c_blue}\u${c_cyan}@\h${c_reset}: ${c_green}\w ${c_dgray}>${c_reset} "
  fi

  # 4. Clean up all temporary variables so they leave zero footprint in your shell
  unset c_red c_lred c_green c_blue c_cyan c_dgray c_reset
  unset esc osc bel apc st_seq title_fmt
fi
