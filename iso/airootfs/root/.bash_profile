# RobinOS 라이브: tty1 로그인 시 데스크톱 세션 시작.
# exec 하지 않는다 — Hyprland가 죽어도 셸이 살아남아 크래시 루프(깜빡임)를 막는다.
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ "$(tty)" = "/dev/tty1" ]; then
    robinos-session
fi
