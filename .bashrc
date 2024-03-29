#!/bin/bash
#
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.
#
# It attempts to keep all settings completely generic so that any
# user can install this without fear of any unusual aliases or
# preferences being forced upon them.
#
# In order to allow for customization (and to allow the authors to
# use this file along with some private aliases), this file will
# source other sub-files if they exist, in the following order:
#
# ~/.bashrc.d/*
#   A place to store extra configuration in order to keep this master .bashrc
#   file as clean and generic as possible.  All files here will be included
#   unless they are "location" files as described below.
#
# ~/.bashrc.d/"$LOCATION".loc
#   This is intended for separating "home" and "work" settings.  $LOCATION is
#   the main domain "word" for this host, i.e. example.loc for example.com.
#   Included when at $LOCATION.
#
# ~/.bashrc.d/"$LOCATION".notloc
#   Like *.loc but only included when not at $LOCATION.
#
# ~/.bashrc_custom
#   This behaves like the files in ~/.bashrc.d, but is intended for custom
#   settings specific to an individual host and as such will never be copied
#   or overwritten by host-setup routines.
#

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
  for file in \
    /etc/*bashrc /etc/profile /etc/bash/bashrc \
    ~/.bash_aliases \
    /etc/bash_completion \
    /sw/bin/init.sh
  do
    [[ -f "$file" ]] && source "$file"
  done

###############################################################################
# Setup some global information about the environment
#

# Figure out what os/distro we are on
  IS_MAC=
  IS_LINUX=
  IS_SUN=
  DISTRO=
  OS=
  VERSION=

  if command -v uname &> /dev/null; then
    OS=`uname`
  fi

  if [[ "$OS" == 'Darwin' ]]; then
    DISTRO='OSX'
    IS_MAC=1
  elif [[ "$OS" == 'SunOS' ]]; then
    DISTRO='SunOS'
    IS_SUN=1
  elif [[ "$OS" == 'Linux' ]]; then
    IS_LINUX=1
    if [[ -f /etc/gentoo-release ]]; then
      DISTRO='Gentoo'
    elif [[ -f /etc/redhat-release ]]; then
      DISTRO=`awk '{ print $1 }' /etc/redhat-release`
    elif [[ -f /etc/debian_version ]]; then
      DISTRO='Debian'
    elif [[ -f /etc/lsb*release ]]; then
      eval `cat /etc/lsb*release`
      DISTRO=$DISTRIB_ID
    fi
  fi

# In a root-capable group?
  ROOTGROUP=
  if [[ $IS_LINUX ]]; then
    groups | grep 'root\|wheel' &> /dev/null
    if [[ "$?" == 0 ]]; then
      ROOTGROUP=1
    fi
  elif [[ $IS_MAC ]]; then
    groups | grep 'root\|admin' &> /dev/null
    if [[ "$?" == 0 ]]; then
      ROOTGROUP=1
    fi
  fi

# Local X server?
  LOCAL_X=
  if [[ $IS_LINUX ]]; then
    if [[ ':' == "${DISPLAY:0:1}" ]]; then
      LOCAL_X=1
    fi
  elif [[ $IS_MAC ]]; then
    if [[ '/tmp/launch' == "${DISPLAY:0:11}" ]]; then
      LOCAL_X=1
    fi
  fi

# Get the primary domain for this host (minus any subdomains)
  if [[ $IS_LINUX ]]; then
    DOMAIN=`echo \`hostname -d\` | sed -e 's/^.\+\.\([^\.]\+\?\.[^\.]\+\)$/\1/'`
  elif [[ $IS_MAC ]]; then
    DOMAIN=`echo \`hostname -f\` | sed -Ee 's/^.+\.([^\.]+\.[^\.]+)$/\1/'`
  else
    DOMAIN=
  fi

###############################################################################
# Define useful functions that things below depend on
#

# Return the absolute/expanded pathname to the requested file or directory
  abspath() {
    dir="$1"
    file=""
    if [[ -f "$dir" ]]; then
      file=/`basename "$dir"`
      dir=`dirname "$dir"`
    fi
    echo `cd "$dir" && pwd -P`"$file"
  }

#
# Nice path functions with slight modifications from:
#
#   http://stackoverflow.com/questions/370047/what-is-the-most-elegant-way-to-remove-a-path-from-the-path-variable-in-bash
#
  append_path()  { NEW=${1/%\//}; [[ -d $NEW ]] || return; remove_path $NEW; export PATH="$PATH:$NEW"; }
  prepend_path() { NEW=${1/%\//}; [[ -d $NEW ]] || return; remove_path $NEW; export PATH="$NEW:$PATH"; }
  remove_path()  {
    # New format not supported by some old versions of awk
    # PATH=`echo -n "$PATH" | awk -v RS=: -v ORS=: '$0 != "'$1'"'`
    PATH=`echo -n "$PATH" | awk  'BEGIN { RS=":"; ORS=":" } $0 != "'$1'" '`
    export PATH=${PATH/%:/}
  }


# Return the first program from the argument list that exists in the execution path
  find_program() {
    for file in $*; do
      if command -v "$file" &>/dev/null; then
        echo "$file"
        return
      fi
    done
  }

###############################################################################
# Basic environmental settings/changes that should go everywhere
#

#
# ANSI colors
#

    ANSI_RESET="\[\033[0m\]"
    ANSI_BRIGHT="\[\033[1m\]"
    ANSI_UNDERSCORE="\[\033[4m\]"

    FG_BLACK="\[\033[0;30m\]"
    FG_BLUE="\[\033[0;34m\]"
    FG_GREEN="\[\033[0;32m\]"
    FG_CYAN="\[\033[0;36m\]"
    FG_RED="\[\033[0;31m\]"
    FG_MAGENTA="\[\033[0;35m\]"
    FG_BROWN="\[\033[0;33m\]"
    FG_LIGHTGRAY="\[\033[0;37m\]"
    FG_DARKGRAY="\[\033[1;30m\]"
    FG_LIGHTBLUE="\[\033[1;34m\]"
    FG_LIGHTGREEN="\[\033[1;32m\]"
    FG_LIGHTCYAN="\[\033[1;36m\]"
    FG_LIGHTRED="\[\033[1;31m\]"
    FG_LIGHTMAGENTA="\[\033[1;35m\]"
    FG_YELLOW="\[\033[1;33m\]"
    FG_WHITE="\[\033[1;37m\]"

    BG_BLACK="\[\033[40m\]"
    BG_RED="\[\033[41m\]"
    BG_GREEN="\[\033[42m\]"
    BG_BROWN="\[\033[43m\]"
    BG_BLUE="\[\033[44m\]"
    BG_PURPLE="\[\033[45m\]"
    BG_CYAN="\[\033[46m\]"
    BG_WHITE="\[\033[47m\]"

#
# Commandline setup
#

# Colorize and customize the sudo prompt
  alias sudo='sudo -p "`echo -e '\''\033[33msudo \033[1;31m%U\033[0;33m password for \033[0;34m%u\033[36m@\033[34m%h\033[0m: \033[0m'\''` "'

# Change PROMPT_COMMAND so that it will update window/tab titles automatically
  if [[ $IS_LINUX || $IS_MAC || $IS_SUN ]]; then
    case "$TERM" in
      xterm*|rxvt|Eterm|eterm|linux)
        PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\007"'
        ;;
      screen)
        PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\033\\"'
        ;;
    esac
  fi

# Redraw the prompt to a better look.  Red for Root (EUID zero)
  if [[ $EUID == 0 ]]; then
    PS1="${FG_RED}\u${FG_LIGHTRED}@\h${ANSI_RESET}: ${FG_GREEN}\w ${FG_LIGHTRED}#${ANSI_RESET} "
  else
    PS1="${FG_BLUE}\u${FG_CYAN}@${FGBLUE}\h${ANSI_RESET}: ${FG_GREEN}\w ${FG_DARKGRAY}>${ANSI_RESET} "
  fi

# Allow control-D to log out
  unset ignoreeof

# Enable hist-append
  shopt -s histappend

# History length
  export HISTFILESIZE=100000
  export HISTSIZE=200000

# Give the time in the history file
  export HISTTIMEFORMAT="%F %T "

# Ignore duplicate history entries and those starting with whitespace
  export HISTCONTROL=ignoreboth

# Prevent certain commands from cluttering the history
  export HISTIGNORE="&:l:ls:ll:[bf]g:clear:exit:history:history *:history|*:cd:cd -:df"

# Update the bash history after every command rather then the end of the session
if [[ "${PROMPT_COMMAND}" == *\; ]]
then
  export PROMPT_COMMAND="${PROMPT_COMMAND} history -a"
elif [[ -n "${PROMPT_COMMAND}" ]]
then
  export PROMPT_COMMAND="${PROMPT_COMMAND}; history -a"
else
  export PROMPT_COMMAND="history -a"
fi

# Enable spellchecking/guessing for cd commands (useful for typo'd pathnames)
  shopt -s cdspell

# Store multi-line commands as one line in the history
  shopt -s cmdhist

# Turn on checkwinsize so we get $LINES and $COLUMNS
  shopt -s checkwinsize

#
# Update the search path with some more directories
#

  if [[ $ROOTGROUP ]]; then
    for dir in \
        /usr/*/sbin/           \
        /opt/*/sbin/           \
        /usr/lib/courier/*sbin \
        ; do
      prepend_path "$dir"
    done
    prepend_path /usr/sbin
    prepend_path /sbin
  fi

  append_path ~/bin
  append_path ~/scripts
  for dir in \
      /usr/*/bin/           \
      /opt/*/bin/           \
      /usr/java/*/bin/      \
      ; do
    prepend_path "$dir"
  done

#
# Now that we have altered $PATH, make a few other environment-specific tweaks
#

# Use gnu utilities if they're available
  if [[ $IS_SUN || $IS_MAC ]]; then
    for APP in grep find tar sed xargs; do
      if command -v g$APP &> /dev/null; then
        alias $APP=g$APP
      fi
    done
  fi

#
# Setup Grep
#
  export GREP_OPTIONS=

# Ignore certain directory patterns
  export GREP_OPTIONS="--exclude-dir=.svn $GREP_OPTIONS"
  export GREP_OPTIONS="--exclude-dir=.git $GREP_OPTIONS"
  export GREP_OPTIONS="--exclude-dir=CVS $GREP_OPTIONS"

# Turn on grep colorization
  export GREP_OPTIONS="--color=auto $GREP_OPTIONS"
  # export GREP_COLORS='mt=0;32'

  # Apply the options without using the now-deprecated env var
  if command -v ggrep &> /dev/null; then
    alias grep="ggrep $GREP_OPTIONS"
  else
    alias grep="grep $GREP_OPTIONS"
  fi
  export GREP_OPTIONS=

# Prepare the ls color options
  if [[ $IS_MAC ]]; then
    export CLICOLOR=1
  else
    export CLICOLOR=true
  fi
  for file in /etc/DIR_COLORS ~/.dir_colors; do
    if [[ -f "$file" ]]; then
      eval `dircolors -b $file`
    fi
  done
  if [[ $IS_MAC ]]; then
      LS_OPTIONS='-G -v'
  elif [[ $IS_LINUX ]]; then
      LS_OPTIONS='-v --color=auto --show-control-chars'
  else
      LS_OPTIONS=
  fi

#
# Other settings specific to the OS
#

# Linux and Solaris settings
  if [[ $IS_LINUX || $IS_SUN ]]; then

  # Update JAVA_HOME, too
    JAVA_HOME="`dirname \`dirname \\\`command -v java2 2>/dev/null\\\` 2>/dev/null\` 2>/dev/null`"

    export LC_ALL=$LANG

  #Export proper case-sensitive language sorting
    export LC_COLLATE=C


  # Preferred editor settings
    export EDITOR=`find_program vim vi nano`

  # Preferred pager
    export PAGER=`find_program less more cat`

  # Python-preferred browser
    export BROWSER=`find_program firefox mozilla iceweasel elinks lynx`

# Mac settings
  elif [[ $IS_MAC ]]; then

  # Preferred editor settings
    export EDITOR=vim

  # Preferred pager
    export PAGER=less

  fi

###############################################################################
# Things very specific to MacOS
#

if [[ $IS_MAC ]]; then

# Turn on bash-completion for macs
  if command -v brew > /dev/null; then
    for file in \
      $(brew --prefix)/etc/bash_completion \
      $(brew --prefix)/etc/bash_completion.d/brew
    do
      [[ -f "$file" ]] && source "$file"
    done
  fi

fi

###############################################################################
# Execute any environment-specific bashrc files
#

# Get the location (useful for home vs. work separation)
  LOCATION=`echo "$DOMAIN" | awk -F. '{ print $1 }'`

# Load any custom extensions
  if [[ -d ~/.bashrc.d ]]; then
    for file in ~/.bashrc.d/*; do
      if [[ -d "$file" ]]; then
        continue
      elif [[ ${file:$((${#file}-9)):9} == '.disabled' ]]; then
        continue
      elif [[ ${file:$((${#file}-4)):4} == '.loc' ]]; then
        if [[ $file == ~/.bashrc.d/"$LOCATION".loc ]]; then
          source "$file"
        fi
      elif [[ ${file:$((${#file}-7)):7} == '.notloc' ]]; then
        if [[ $file != ~/.bashrc.d/"$LOCATION".notloc ]]; then
          source "$file"
        fi
      else
        source "$file"
      fi
    done
  fi

# And finally even more, just in case
  [[ -f ~/.bashrc_custom ]] && source ~/.bashrc_custom

# Init some NVM stuff
  # export NVM_DIR="$HOME/.nvm"
  # [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  # [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# init direnv
  if [[ $(command -v direnv) ]]; then
    eval "$(direnv hook bash)"
  fi

# Lastly, init iterm2 shell integration
  if [[ -e "${HOME}/.iterm2_shell_integration.bash" ]]; then
      source "${HOME}/.iterm2_shell_integration.bash"
  else
      echo "No iterm integration.  Please install via iTerm2 menu"
  fi

