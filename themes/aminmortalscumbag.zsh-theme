last_run_time=""
custom_prompt=""
function pipestatus_parse {
  PIPESTATUS="$pipestatus"
  ERROR=0
  for i in "${(z)PIPESTATUS}"; do
      if [[ "$i" -ne 0 ]]; then
          ERROR=1
      fi
  done

  if [[ "$ERROR" -ne 0 ]]; then
      print "[%{$fg[red]%}$PIPESTATUS%{$fg[cyan]%}]"
  fi
}
function duration() {
    local duration
    local now=$(perl -MTime::HiRes=time -e 'printf "%.9f\n", time')
    local last=$1
    local last_split=("${(@s/./)last}")
    local now_split=("${(@s/./)now}")
    local T=$((now_split[1] - last_split[1]))
    local D=$((T/60/60/24))
    local H=$((T/60/60%24))
    local M=$((T/60%60))
    local S=$((T%60))
    local s=$(((now_split[2] - last_split[2]) / 1000000000.))
    local m=$(((now_split[2] - last_split[2]) / 1000000.))

    (( $D > 0 )) && duration+="${D}d"
    (( $H > 0 )) && duration+="${H}h"
    (( $M > 0 )) && duration+="${M}m"

    if [[ $S -le 0 ]]; then
        printf "%ims" "$m"
    else
        if ! [[ -z $duration ]] && printf "%s" "$duration"
        local sec_milli=$((S + s))
        printf "%.3fs" "$sec_milli"
    fi
}
function preexec() {
    last_run_time=$(perl -MTime::HiRes=time -e 'printf "%.9f\n", time')
}
function precmd() {
    RETVAL=$(pipestatus_parse)
    local info=""

    if [ ! -z "$last_run_time" ]; then
        local elapsed=$(duration $last_run_time)
        last_run_time=$(print $last_run_time | tr -d ".")
        if [ $(( $(perl -MTime::HiRes=time -e 'printf "%.9f\n", time' | tr -d ".") - $last_run_time )) -gt $(( 120 * 1000 * 1000 * 1000 )) ]; then
            local elapsed_color="%{$fg[magenta]%}"
        elif [ $(( $(perl -MTime::HiRes=time -e 'printf "%.9f\n", time' | tr -d ".") - $last_run_time )) -gt $(( 60 * 1000 * 1000 * 1000 )) ]; then
            local elapsed_color="%{$fg[red]%}"
        elif [ $(( $(perl -MTime::HiRes=time -e 'printf "%.9f\n", time' | tr -d ".") - $last_run_time )) -gt $(( 10 * 1000 * 1000 * 1000 )) ]; then
            local elapsed_color="%{$fg[yellow]%}"
        else
            local elapsed_color="%{$fg[green]%}"
        fi
        # info=$(printf "%s%s%s%s%s" "%{$fg[cyan]%}[" "$elapsed_color" "$elapsed" "%{$fg[cyan]%}]" "$RETVAL")
        info=$(printf "%s" "$elapsed")
        unset last_run_time
    fi

    custom_prompt="$info"
}

function my_git_prompt() {
  tester=$(git rev-parse --git-dir 2> /dev/null) || return

  INDEX=$(git status --porcelain 2> /dev/null)
  STATUS=""

  # is branch ahead?
  if $(echo "$(git log origin/$(git_current_branch)..HEAD 2> /dev/null)" | grep '^commit' &> /dev/null); then
    STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_AHEAD"
  fi

  # is branch behind?
  if $(echo "$(git log HEAD..origin/$(git_current_branch) 2> /dev/null)" | grep '^commit' &> /dev/null); then
    STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_BEHIND"
  fi

  # is anything staged?
  if $(echo "$INDEX" | command grep -E -e '^(D[ M]|[MARC][ MD]) ' &> /dev/null); then
    STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_STAGED"
  fi

  # is anything unstaged?
  if $(echo "$INDEX" | command grep -E -e '^[ MARC][MD] ' &> /dev/null); then
    STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_UNSTAGED"
  fi

  # is anything untracked?
  if $(echo "$INDEX" | grep '^?? ' &> /dev/null); then
    STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_UNTRACKED"
  fi

  # is anything unmerged?
  if $(echo "$INDEX" | command grep -E -e '^(A[AU]|D[DU]|U[ADU]) ' &> /dev/null); then
    STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_UNMERGED"
  fi

  if [[ -n $STATUS ]]; then
    STATUS=" $STATUS"
  fi

  echo "$ZSH_THEME_GIT_PROMPT_PREFIX$(my_current_branch)$STATUS$ZSH_THEME_GIT_PROMPT_SUFFIX"
}

function my_current_branch() {
  echo $(git_current_branch || echo "(no branch)")
}

function ssh_connection() {
  if [[ -n $SSH_CONNECTION ]]; then
    echo "%{$fg_bold[red]%}(ssh) "
  fi
}

function _toolbox_prompt_info() {
  if typeset -f toolbox_prompt_info > /dev/null; then
    toolbox_prompt_info
  fi
}

local ret_status="%(?:%{$fg_bold[green]%}:%{$fg_bold[red]%})%?%{$reset_color%}"
# PROMPT=%{$fg_bold[green]%}-------$'$(_toolbox_prompt_info)$(ssh_connection)%n %m %D{%I:%M:%S} %/ $(my_git_prompt) --------- %{$reset_color%} ${ret_status}\n%# '
#%n %m 
PROMPT=%{$fg_bold[green]%}-------$' $(pyenv version-name) ${custom_prompt}$(_toolbox_prompt_info)$(ssh_connection) %D{%H:%M:%S} %/ --------- $(my_git_prompt) %{$reset_color%} ${ret_status}\n%# '

ZSH_THEME_PROMPT_RETURNCODE_PREFIX="%{$fg_bold[red]%}"
ZSH_THEME_GIT_PROMPT_PREFIX=" $fg[white] %{$fg_bold[yellow]%}"
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg_bold[magenta]%}↑"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg_bold[green]%}↓"
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg_bold[green]%}●"
ZSH_THEME_GIT_PROMPT_UNSTAGED="%{$fg_bold[red]%}●"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg_bold[white]%}●"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg_bold[red]%}✕"
ZSH_THEME_GIT_PROMPT_SUFFIX=" $fg_bold[white]%{$reset_color%}"
