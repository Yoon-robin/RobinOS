#
# RobinOS default shell profile
#

# Only interactive shells
[[ $- != *i* ]] && return

# Windows command hints (ipconfig -> ip a, dir -> ls -l, ...)
[[ -r /usr/share/robinos/bash/robinos-hints.sh ]] && . /usr/share/robinos/bash/robinos-hints.sh

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias robinctl='robinctl'

export EDITOR=vim

# Terminals opened by the shell for a task (e.g. learning missions) skip the greeting
if [[ -n "${ROBINOS_NO_GREETING:-}" ]]; then
  :
elif command -v fastfetch >/dev/null 2>&1; then
  fastfetch
  printf '리눅스가 처음이라면: robinctl learn\n'
else
  printf 'RobinOS 보안 학습 환경\n'
  printf '리눅스가 처음이라면: robinctl learn\n'
fi

