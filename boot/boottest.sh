#!/usr/bin/env bash
# RobinOS ISO를 QEMU TCG(가상화 없음)로 부팅테스트 → 시리얼 로그 + 스크린샷.
# isolinux 부트메뉴(키 입력 필요 → TCG에서 QMP sendkey가 안 먹음)를 우회:
# ISO에서 커널/initrd를 추출해 -kernel 로 직접 부팅 → 키 입력 불필요 +
# console=ttyS0 로 부팅 전과정이 boot-serial.log 에 텍스트로 남는다.
# 사용: bash boot/boottest.sh [ISO경로]   (저장소 루트에서 실행)
set -uo pipefail

ISO="${1:-$(ls boot/*.iso 2>/dev/null | head -n1)}"
if [ -z "${ISO:-}" ] || [ ! -f "$ISO" ]; then
  echo "ISO를 찾을 수 없음: '${ISO:-}'"
  exit 0
fi
echo "ISO: $ISO ($(du -h "$ISO" | cut -f1))"

sudo apt-get update -qq || true
sudo apt-get install -y qemu-system-x86 imagemagick >/dev/null

# ISO에서 커널/initrd 추출
mkdir -p /tmp/isomnt
sudo mount -o loop,ro "$ISO" /tmp/isomnt
echo "=== ISO /live 내용 ==="; ls -la /tmp/isomnt/live/ 2>/dev/null || true
cp "$(ls /tmp/isomnt/live/vmlinuz* | head -n1)" /tmp/vmlinuz
cp "$(ls /tmp/isomnt/live/initrd*  | head -n1)" /tmp/initrd
sudo umount /tmp/isomnt

echo "QEMU 직접-커널 부팅 (TCG, KVM 없음, 부트메뉴 없음)…"
qemu-system-x86_64 -machine q35 -accel tcg -m 4096 -smp 2 \
  -kernel /tmp/vmlinuz -initrd /tmp/initrd \
  -append "boot=live components console=ttyS0,115200 systemd.journald.forward_to_console=1" \
  -cdrom "$ISO" -vga virtio -display none \
  -qmp unix:/tmp/qmp.sock,server,nowait \
  -serial file:boot/boot-serial.log &
QPID=$!

python3 boot/qmp_shots.py /tmp || true
for f in /tmp/shot*.ppm; do
  [ -f "$f" ] && convert "$f" "boot/$(basename "${f%.ppm}").png" || true
done
kill "$QPID" 2>/dev/null || true

echo "=== boot-serial.log (마지막 80줄) ==="
tail -80 boot/boot-serial.log 2>/dev/null || echo "(시리얼 로그 비어있음)"
echo "=== 스크린샷 ==="
ls -la boot/*.png 2>/dev/null | head || echo "(스크린샷 없음)"
