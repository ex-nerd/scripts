# Uncomment to enable profiling
# zmodload zsh/zprof

# Ensure unique entries in path arrays
typeset -U path fpath

local _is_mac=""
local _is_linux=""
local _is_admin=""
local _user_groups=""

local _file
local _dir

###############################################################################
# Collect information about the environment and the current user, which will
# be used throughout this configuration file and then cleared at the end.
#

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
# Adjust shell behavior and key bindings
#

# Set locale settings to UTF-8 for proper handling of non-ASCII characters
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_COLLATE=C

# History configuration (shell-only variables do not need export)
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=200000
setopt share_history        # share history across all sessions
setopt hist_ignore_dups     # ignore duplicate commands
setopt hist_ignore_space    # ignore commands that start with a space
setopt hist_reduce_blanks   # reduce duplicates by removing extra whitespace
setopt extended_history     # save history timestamps+duration

# Not neccessary on MacOS. Might want to uncomment for linux.
# export TZ="America/Los_Angeles"

# Like bash's cdspell to correct mistyped programs (use correctall to also correct arguments)
setopt correct

# respect comment characters in interactive shell
setopt interactive_comments

# disable ! character for history expansion
setopt no_banghist

# should be the default, but just in case make sure ctrl-D logs out
unsetopt ignoreeof

# Remove some unwanted characters from WORDCHARS
export WORDCHARS=${WORDCHARS/\/} # remove /
export WORDCHARS=${WORDCHARS/_}  # remove _

# Switch to emacs key bindings (e.g. ctrl-r for reverse search)
bindkey -e

# to get new bindings, run: cat[enter][press key]
bindkey "^[[1;5C" forward-word      # Ctrl+Right
bindkey "^[[1;5D" backward-word     # Ctrl+Left
bindkey "^[[H"    beginning-of-line # Home
bindkey "^[OH"    beginning-of-line # Home (application mode)
bindkey "^[[F"    end-of-line       # End
bindkey "^[OF"    end-of-line       # End (application mode)
bindkey "^[[3~"   delete-char       # Delete

# Enable color for gnu tools
export CLICOLOR=1

# Instruct less to render nerdfonts directly
export LESSUTFCHARDEF="E000-F8FF:p,F0000-FFFFD:p,100000-10FFFD:p"

# Default less to color rendering, case-insensitive search, and auto-exit for short files
export LESS="-R -i -F"

# Default tools
export EDITOR="vim"
if (( $+commands[batcat] )); then
  export PAGER="batcat"
  export MANPAGER="batcat -l man -p"
elif (( $+commands[bat] )); then
  export PAGER="bat"
  if (( $+commands[batman] )); then
    eval "$(batman --export-env)"
  elif [[ $_is_mac ]]; then
    # macos mandoc needs extra help to avoid random control characters in the output
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
  for _dir in \
      /usr/*/sbin(N/) \
      /opt/*/sbin(N/) \
      ; do
    path=( "$_dir" $path )
  done
  path=( /usr/sbin /sbin $path )
fi

for _dir in \
    /usr/*/bin(N/) \
    /opt/*/bin(N/) \
    ; do
  path=( "$_dir" $path )
done

path=( ~/.local/bin ~/bin ~/scripts $path )

if [[ -d "$HOME/go" ]]; then
    typeset -TUx GOPATH gopath
    gopath+=("$HOME/go")
    [[ -d "$HOME/go/bin" ]] && path+=("$HOME/go/bin")
fi

# Added by LM Studio CLI (lms)
if [[ -d "$HOME/.lmstudio/bin" ]]; then
  path+=("$HOME/.lmstudio/bin")
fi

###############################################################################
# GNU utilities
#

if [[ $_is_mac ]]; then
  () {
    local _app
    # Note: grep is handled separately below.
    for _app in find tar sed xargs; do
      local _gnu_app="g$_app"
      if (( $+commands[$_gnu_app] )); then
        alias -- "$_app=$_gnu_app"
      fi
    done
  }
fi

() {
  # Note: this list should be kept in sync with the values in .ripgreprc
  local -a exclude_files=(
    .DS_Store
  )
  local -a exclude_dirs=(
    # Version Control & IDEs
    .git
    .idea
    .svn
    CVS
    # Python & Environments
    __pycache__
    .venv
    node_modules
    # Caches
    .cache
    .direnv
    ".*_cache"
  )

  # Convert the array into repeated --exclude-dir flags programmatically
  local -a grep_options=(--color=auto)
  for _file in $exclude_files; do
    grep_options+=(--exclude="'$_file'")
  done
  for _dir in $exclude_dirs; do
    grep_options+=(--exclude-dir="'$_dir'")
  done

  # Check for GNU grep, fallback to standard grep
  local grep_cmd="grep"
  (( $+commands[ggrep] )) && grep_cmd="ggrep"

  # In zsh, expanding an array inside double quotes automatically joins elements with spaces
  alias grep="$grep_cmd $grep_options"

}

# Ensure the deprecated environment variable is unset
unset GREP_OPTIONS


###############################################################################
# Initialize homebrew
#

local _brew

# Find Homebrew binary without spawning subshells for standard paths
if [[ -x /opt/homebrew/bin/brew ]]; then
  _brew="/opt/homebrew/bin/brew"
elif [[ -x /usr/local/bin/brew ]]; then
  _brew="/usr/local/bin/brew"
# elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
#   _brew="/home/linuxbrew/.linuxbrew/bin/brew"
elif (( $+commands[brew] )); then
  _brew="$commands[brew]"
fi
if [[ -n "$_brew" ]]; then
  # Set homebrew env vars
  # Note: calls will be blank if env vars are already set
  eval "$("$_brew" shellenv)"

  # Disable homebrew's automatic environment hints
  export HOMEBREW_NO_ENV_HINTS=1

  # Installed brew cask programs bypass "downloaded from the internet" warning
  export HOMEBREW_CASK_OPTS="--no-quarantine"

  fpath=("$HOMEBREW_PREFIX/share/zsh-completions" $fpath)

  path+=("$HOMEBREW_PREFIX/opt/python/libexec/bin")
fi

unset _brew

###############################################################################
# User functions and additional zsh configuration
#

# Load all regular, non-hidden files (excluding .zwc and dotfiles) in a single command
fpath=("$HOME/.zsh/functions" $fpath)

local -a _user_funcs=()

for _file in "$HOME/.zsh/functions/"*(N); do
  _file="${_file:t}"
  [[ $_file != *.zwc ]] && _user_funcs+="$_file"
done
(( ${#_user_funcs} )) && autoload -Uz "${_user_funcs[@]}"
unset _user_funcs

# Process my zsh include-files
for _file in "$HOME/.zsh/"*.zsh(N); do
  source "$_file"
done

# Initialize zsh completion system (full scan every hour; cached otherwise)
autoload -Uz compinit
if [[ -n "$HOME/.zcompdump"(#qNmh-1) ]]; then
  compinit -C
else
  compinit
fi

# Compile .zcompdump to bytecode in the background if missing or stale
# {
#   if [[ -s "$HOME/.zcompdump" && (! -s "$HOME/.zcompdump.zwc" || "$HOME/.zcompdump" -nt "$HOME/.zcompdump.zwc") ]]; then
#     zcompile "$HOME/.zcompdump"
#   fi
# } &!

###############################################################################
# Cleanup temporary variables
#

unset _user_groups _is_mac _is_linux _is_admin
unset _file _dir

###############################################################################
# Additional config for external programs
#

export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# Activate iterm2 shell integration
local _iterm2_script="${HOME}/.iterm2_shell_integration.zsh"
if [[ -r "$_iterm2_script" ]]; then
	# if [[ ! -f "${_iterm2_script}.zwc" || "$_iterm2_script" -nt "${_iterm2_script}.zwc" ]]; then
	# 	zcompile "$_iterm2_script"
	# fi
	source "$_iterm2_script"
else
  printf "\033[1;91m⚠️  No iTerm2 integration. \033[0;33mPlease install via iTerm2 menu.\033[0m\n"
fi
unset _iterm2_script

# Initialize mise before direnv
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi

# Initialize direnv
if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

# Initialize starship
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# Uncomment to enable profiling
# zprof
