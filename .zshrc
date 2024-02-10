#!/bin/zsh
ZSH="$HOME/.oh-my-zsh"

builtin_plugin_dir="$ZSH/plugins"
plugin_dir="$ZSH/custom/plugins"

custom_plugins=(
    "$plugin_dir/zsh-syntax-highlighting"
    "$plugin_dir/zsh-autosuggestions"
)
custom_plugins_url=(
    "https://github.com/zsh-users/zsh-syntax-highlighting.git"
    "https://github.com/zsh-users/zsh-autosuggestions.git"
)

if [ ! -d $ZSH ]; then
    echo 'oh-my-zsh not found, will download'
    git clone https://github.com/ohmyzsh/ohmyzsh.git --depth=1 $ZSH
fi

source $ZSH/oh-my-zsh.sh
source $builtin_plugin_dir/git/git.plugin.zsh
source $builtin_plugin_dir/vi-mode/vi-mode.plugin.zsh
source $builtin_plugin_dir/z/z.plugin.zsh
source $builtin_plugin_dir/dirhistory/dirhistory.plugin.zsh

length=${#custom_plugins[@]}

for ((i=1; i<=$length; i++)); do
    dir=${custom_plugins[$i]}
    if [ ! -d $dir ]; then
        echo "$dir not found, will download"
        git clone "${custom_plugins_url[$i]}" --depth=1 $dir &&
            source "$dir/$(basename $dir).plugin.zsh"
    else
        source "$dir/$(basename $dir).plugin.zsh"
    fi
done

# vi-mode no delay
KEYTIMEOUT=1

# theme
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[cyan]%}["
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}*%{$fg_bold[cyan]%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

function prompt_char {
	if [ $UID -eq 0 ]; then echo "%{$fg_bold[blue]%}#%{$reset_color%}"; else echo "%{$fg_bold[blue]%}$%{$reset_color%}"; fi
}
function last_cmd_time_char {
    echo "${zsh_exec_start:+[$zsh_exec_start }${zsh_last_cmd_cost:+${zsh_last_cmd_cost}s] }"
}

# PROMPT='%{$fg[cyan]%}%n%{$reset_color%}@%{$fg[cyan]%}%m%{$reset_color%}: %{$fg[green]%}%~%{$reset_color%}$(git_prompt_info) %(?, ,%{$fg[red]%}%?%{$reset_color%})
# $(prompt_char) '

PROMPT='%{$fg_bold[green]%}%~%{$reset_color%} $(git_prompt_info) %(?,%{$fg[green]%},%{$fg[red]%})$(last_cmd_time_char)%(?, ,%?)%{$reset_color%}
$(prompt_char) '

RPROMPT='%{$fg_bold[green]%}[%D{%H:%M:%S}]%{$reset_color%}'

function my_preexec(){
    # Set the ZSH_EXEC_START_TIMESTAMP variable to the current timestamp
    zsh_exec_start=$(date +%H:%M:%S)
    zsh_exec_start_tm=$(date +%s)
}

function my_precmd(){
    if [[ ! -n ${zsh_exec_start_tm:+"set"} ]]; then
        return
    fi
    # Get the current timestamp
    zsh_exec_end_tm=$(date +%s)

    # Calculate the time difference between now and ZSH_EXEC_START_TIMESTAMP
    zsh_last_cmd_cost=$((zsh_exec_end_tm - zsh_exec_start_tm))
    unset zsh_exec_start_tm
}

preexec_functions+=(my_preexec)
precmd_functions+=(my_precmd)

# update timestamp every second
# TMOUT=1
# TRAPALRM() {
#     if [ "$WIDGET" != "complete-word" ]; then
#         zle reset-prompt
#     fi
# }

alias cls='clear'
alias af='sudo find / -name '
alias hf='history 1 | fzf'
alias cx='curl -x socks5://127.0.0.1:7891 '
alias docker='sudo docker '
alias sys='sudo systemctl '
alias py='python3 '
alias nf='netstat -npl | fzf'

bindkey '\eh'  backward-char
bindkey '\el'  forward-char
bindkey '\ek'  up-line-or-history
bindkey '\ej'  down-line-or-history 

if [ ! -f "$HOME/.zshrc" ]; then
    echo 'add .zshrc to $HOME'
    ln -s $(pwd)/zshrc.zsh $HOME/.zshrc
fi

# improve from https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh
# # The code at the top and the bottom of this file is the same as in completion.zsh.
# # Refer to that file for explanation.
# if 'zmodload' 'zsh/parameter' 2>'/dev/null' && (( ${+options} )); then
#   __fzf_key_bindings_options="options=(${(j: :)${(kv)options[@]}})"
# else
#   () {
#     __fzf_key_bindings_options="setopt"
#     'local' '__fzf_opt'
#     for __fzf_opt in "${(@)${(@f)$(set -o)}%% *}"; do
#       if [[ -o "$__fzf_opt" ]]; then
#         __fzf_key_bindings_options+=" -o $__fzf_opt"
#       else
#         __fzf_key_bindings_options+=" +o $__fzf_opt"
#       fi
#     done
#   }
# fi

# 'emulate' 'zsh' '-o' 'no_aliases'

{

[[ -o interactive ]] || return 0


__fzfcmd() {
  [ -n "${TMUX_PANE-}" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "${FZF_TMUX_OPTS-}" ]; } &&
    echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

# CTRL-F - Paste the selected file path(s) into the command line
fzf-file-widget() {
  local dir=""
  local cmd=""

  read -A array <<< "$LBUFFER"
  local search_path="${array[-1]}"
  local search_text=""
  if [[ -z $search_path ]];then
      dir="./"
  elif [[ $search_path =~ .*/$ ]];then
      dir=$search_path
  else
      dir=$(dirname $search_path)
      search_text=$(basename $search_path)
  fi
  if [[ ! -d $dir ]]; then
      return 1
  fi
  if [ ! -f /usr/bin/fd ]; then
      cmd="${FZF_CTRL_T_COMMAND:-"command find -L $dir -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
        -o -type f -print \
        -o -type d -print \
        -o -type l -print 2> /dev/null | sed \"s|^$dir||\""}"
  else
      cmd="fd . --type f $dir | sed \"s|^$dir||\""
  fi

  setopt localoptions pipefail no_aliases 2> /dev/null
  local item="$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore --query=\"$search_text\" ${FZF_DEFAULT_OPTS-} ${FZF_ALT_C_OPTS-}" $(__fzfcmd) +m)"
  local ret=$?

  args=(${(s: :)LBUFFER})
  length=${#args[@]}
  unset 'args[length]'
  left_command="${args[@]}"

  LBUFFER="$left_command$dir$item"
  zle reset-prompt
  return $ret
}
zle     -N            fzf-file-widget
bindkey -M emacs '^F' fzf-file-widget
bindkey -M vicmd '^F' fzf-file-widget
bindkey -M viins '^F' fzf-file-widget

# CTLR-K kill selected process
fzf-kill-process() {
    local cmd=""
    local default_search_text=""
    local process_info=""

    local comm_width=$((COLUMNS * 35 / 100))
    local cmd_width=$((COLUMNS * 45 / 100))
    cmd="ps -eo comm:$comm_width,cmd:$cmd_width,pid --no-header | sort -k 1"
    process_info="$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore" $(__fzfcmd) +m)"
    if [[ -z "$process_info" ]]; then
        zle redisplay
        return 0
    fi

    read -A array <<< "$process_info"
    pid="${array[-1]}"

    BUFFER="kill -9 $pid # $process_info"
    local ret=$?
    zle reset-prompt
    return $ret
}
zle     -N            fzf-kill-process
bindkey -M emacs '^K' fzf-kill-process
bindkey -M vicmd '^K' fzf-kill-process
bindkey -M viins '^K' fzf-kill-process

# ALT-C - cd into the selected directory
fzf-cd-widget() {
  local dir=""
  local cmd=""
  local default_search_text=""

  if [[ $BUFFER =~ ^cd[[:space:]]+(.+)$ ]]; then
    # Extract directory from "cd DIR"
    dir=${match[1]}
    if [[ $BUFFER =~ ^cd[[:space:]]+(.+)/$ ]]; then
        dir=${match[1]}
    else
        default_search_text=$(basename $dir)
        dir=$(dirname $dir)
        BUFFER="cd $dir/"
    fi
  else
    # Use pwd as the current directory
    dir=$(pwd)
  fi

  if [ ! -f /usr/bin/fd ]; then
      cmd="${FZF_ALT_C_COMMAND:-"command find -L $dir -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
        -o -type d -print 2> /dev/null | sed \"s|^$dir/||\""}"
  else
      cmd="fd . --type d $dir | sed \"s|^$dir/||\""
  fi

  setopt localoptions pipefail no_aliases 2> /dev/null
  local dir="$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore --query \"$default_search_text\" ${FZF_DEFAULT_OPTS-} ${FZF_ALT_C_OPTS-}" $(__fzfcmd) +m)"
  if [[ -z "$dir" ]]; then
    zle redisplay
    return 0
  fi
  if [[ "$BUFFER" =~ ^cd[[:space:]]+(.+)$ ]]; then
    # Replace directory in "cd DIR" command
    BUFFER="${BUFFER%${BUFFER##*[![:space:]]}}$dir"
  else
    if [[ ! "$BUFFER" =~ ^cd ]]; then
        zle push-line # Clear buffer. Auto-restored on next prompt.
    fi
    BUFFER="builtin cd -- ${(q)dir}"
  fi
  zle accept-line
  local ret=$?
  unset dir # ensure this doesn't end up appearing in prompt expansion
  zle reset-prompt
  return $ret
}
zle     -N             fzf-cd-widget
bindkey -M emacs '\ec' fzf-cd-widget
bindkey -M vicmd '\ec' fzf-cd-widget
bindkey -M viins '\ec' fzf-cd-widget

# CTRL-R - Paste the selected command from history into the command line
fzf-history-widget() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
  selected=( $(fc -rl 1 | awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, "", cmd); if (!seen[cmd]++) print $0 }' |
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse ${FZF_DEFAULT_OPTS-} -n2..,.. --scheme=history --bind=ctrl-r:toggle-sort,ctrl-z:ignore ${FZF_CTRL_R_OPTS-} --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
  local ret=$?
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle reset-prompt
  return $ret
}
zle     -N            fzf-history-widget
bindkey -M emacs '^R' fzf-history-widget
bindkey -M vicmd '^R' fzf-history-widget
bindkey -M viins '^R' fzf-history-widget

} always {
  eval $__fzf_key_bindings_options
  'unset' '__fzf_key_bindings_options'
}

eval "$(starship init zsh)"
