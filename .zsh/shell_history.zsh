#
# Integration for ShellHistory.app (https://loshadki.app/shellhistory/)
#
# The following code is pasted verbatim from the instructions in ShellHistory settings.
#

if [[ -x "/Applications/ShellHistory.app/Contents/Helpers/shhist" ]]; then

    # ShellHistory records every command you run. Keep these lines at the end of the file.
    if [[ -o interactive && -z "${__shhist_loaded:-}" ]]; then
        __shhist_loaded=1
        zmodload zsh/datetime 2>/dev/null
        path+=("/Applications/ShellHistory.app/Contents/Helpers")
        # One session per shell, also for tmux panes and nested shells that share TERM_SESSION_ID.
        export SHHIST_SESSION="${TERM_SESSION_ID:+${TERM_SESSION_ID}-}$$-${EPOCHSECONDS:-$RANDOM}"
        __shhist_number=0
        __shhist_command=""

        __shhist_preexec() {
            # With hist_ignore_space, a command that starts with a space stays out of ShellHistory too.
            if [[ -o hist_ignore_space && "$1" == [[:space:]]* ]]; then
                __shhist_command=""
                return
            fi
            __shhist_command="$1"
            __shhist_start="${EPOCHREALTIME:-}"
            __shhist_pwd="$PWD"
            __shhist_number=$(( __shhist_number + 1 ))
        }

        __shhist_precmd() {
            local __shhist_exit=$?
            if [[ -n "$__shhist_command" ]]; then
                local -a __shhist_args=(record --shell zsh --session "$SHHIST_SESSION" --number "$__shhist_number"
                    --exit-code "$__shhist_exit" --pwd "$__shhist_pwd" --to-pwd "$PWD"
                    --username "${LOGNAME:-$USER}" --hostname "$HOST")
                if [[ -n "$__shhist_start" && -n "${EPOCHREALTIME:-}" ]]; then
                    local __shhist_ms=$(( (EPOCHREALTIME - __shhist_start) * 1000 ))
                    __shhist_args+=(--start "$__shhist_start" --duration-ms "${__shhist_ms%.*}")
                fi
                if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" ]]; then
                    # A root shell started with sudo records into the history of the user who ran sudo.
                    print -rn -- "$__shhist_command" | sudo --preserve-env --user "$SUDO_USER" "/Applications/ShellHistory.app/Contents/Helpers/shhist" "${__shhist_args[@]}" >/dev/null 2>&1 &!
                else
                    print -rn -- "$__shhist_command" | "/Applications/ShellHistory.app/Contents/Helpers/shhist" "${__shhist_args[@]}" >/dev/null 2>&1 &!
                fi
                __shhist_command=""
            fi
            return $__shhist_exit
        }

        autoload -Uz add-zsh-hook
        add-zsh-hook preexec __shhist_preexec
        precmd_functions=(__shhist_precmd $precmd_functions)
    fi

fi