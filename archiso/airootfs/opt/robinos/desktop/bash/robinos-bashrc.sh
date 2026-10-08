# RobinOS: interactive bash setup, sourced from ~/.bashrc (the one in /etc/skel,
# and post-install.sh adds the line to the installing user's own ~/.bashrc).
# It lives here, not in ~/.bashrc, so RobinOS updates reach existing users too.

[[ $- != *i* ]] && return

# Windows command hints (ipconfig -> ip a, dir -> ls -l, ...)
[[ -r /usr/share/robinos/bash/robinos-hints.sh ]] && . /usr/share/robinos/bash/robinos-hints.sh

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

export EDITOR=vim

# Prompt: "robin@robinos ~/practice >" with the RobinOS red ">" ("#" as root, like
# every Linux), the last command's exit code in red when it failed, and the window
# title saying where the terminal is
PROMPT_DIRTRIM=3
__robinos_prompt() {
  local status=$? code=""
  local red='\[\e[38;2;229;72;77m\]' dim='\[\e[2m\]' bold='\[\e[1m\]' reset='\[\e[0m\]'
  local mark='>'
  ((EUID == 0)) && mark='#'
  ((status != 0)) && code="${red}${status}${reset} "
  PS1="\[\e]0;\u@\h: \w\a\]${dim}\u@\h${reset} ${bold}\w${reset} ${code}${red}${mark}${reset} "
}
case ";${PROMPT_COMMAND:-};" in
  *";__robinos_prompt;"*) ;;
  *) PROMPT_COMMAND="__robinos_prompt${PROMPT_COMMAND:+;${PROMPT_COMMAND}}" ;;
esac

# Terminals opened by the shell for a task (e.g. learning missions) skip the greeting
if [[ -z "${ROBINOS_NO_GREETING:-}" && -z "${__robinos_greeted:-}" ]]; then
  __robinos_greeted=1
  if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
  else
    printf 'RobinOS 보안 학습 환경\n'
  fi
  printf '리눅스가 처음이라면: robinctl learn\n'
fi
