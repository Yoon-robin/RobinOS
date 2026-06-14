#!/usr/bin/env python3
# QEMU QMP로 라이브 부팅을 진행시키고(부트메뉴에서 ENTER) 스크린샷을 여러 장 찍는다.
# 사용: python3 qmp_shots.py <출력디렉터리>  (QEMU는 -qmp unix:/tmp/qmp.sock 로 떠 있어야 함)
import socket
import json
import time
import sys

SOCK = "/tmp/qmp.sock"
out = sys.argv[1] if len(sys.argv) > 1 else "/tmp"

s = None
for _ in range(60):
    try:
        s = socket.socket(socket.AF_UNIX)
        s.connect(SOCK)
        break
    except OSError:
        s = None
        time.sleep(1)

if s is None:
    print("QMP: 연결 실패 (QEMU가 안 떴거나 소켓 없음)")
    sys.exit(0)


def cmd(obj):
    s.sendall((json.dumps(obj) + "\r\n").encode())
    time.sleep(0.5)
    try:
        return s.recv(65536).decode(errors="ignore").strip()
    except OSError as e:
        return f"recv error: {e}"


def enter():
    return cmd({"execute": "sendkey",
                "arguments": {"keys": [{"type": "qcode", "data": "ret"}]}})


def super_t():
    # Super+T → sway가 foot 터미널을 띄움(독·메뉴바 위에 앱 창이 와도 안 가리는지 검증).
    return cmd({"execute": "sendkey",
                "arguments": {"keys": [{"type": "qcode", "data": "meta_l"},
                                       {"type": "qcode", "data": "t"}]}})


try:
    s.recv(65536)  # QMP greeting
    cmd({"execute": "qmp_capabilities"})
    shot = 0
    # 1) 부트 메뉴 통과: 첫 2분간 ENTER를 반복 전송(메뉴가 언제 준비될지 모르므로
    #    계속 두드린다) + 중간중간 캡처. TCG가 느려 단발 ENTER로는 못 넘어감.
    for t in range(24):  # 24 * 5s = 120s
        time.sleep(5)
        enter()
        if t % 3 == 2:  # ~15초마다 한 장
            cmd({"execute": "screendump",
                 "arguments": {"filename": f"{out}/shot{shot}.ppm"}})
            shot += 1
    # 2) 라이브 부팅 + Flutter 렌더를 길게 캡처(~10분). 중간에 잠금 해제 + 앱 실행으로
    #    데스크톱과 '앱 위에 독·메뉴바가 보이는지'(layer-shell)까지 객관적으로 남긴다.
    for i in range(20):  # 20 * 30s = 600s
        time.sleep(30)
        if i in (3, 4, 5):
            enter()        # 잠금화면이 떴을 시점 → ENTER로 해제(타이밍 여유로 3회)
        if i == 9:
            super_t()      # 데스크톱 진입 후 터미널(foot) 열기 → 독 가림 검증
        r = cmd({"execute": "screendump",
                 "arguments": {"filename": f"{out}/shot{shot}.ppm"}})
        print(f"shot{shot}: {r}")
        shot += 1
except Exception as e:  # noqa: BLE001
    print(f"QMP 오류: {e}")
finally:
    try:
        s.close()
    except OSError:
        pass
