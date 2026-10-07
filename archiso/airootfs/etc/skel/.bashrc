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

if command -v fastfetch >/dev/null 2>&1; then
  fastfetch
else
  printf 'RobinOS Security Learning Environment\n'
  printf 'Try: robinctl doctor\n'
fi

