#
# RobinOS default shell profile
#

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

