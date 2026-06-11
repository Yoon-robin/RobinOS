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


try:
    s.recv(65536)  # QMP greeting
    cmd({"execute": "qmp_capabilities"})
    # 부트 메뉴가 뜰 시간을 준 뒤 ENTER → 라이브 시스템 부팅 시작
    time.sleep(25)
    print("ENTER (부트메뉴):", enter())
    time.sleep(5)
    enter()  # 혹시 한 번 더 필요할 때 대비
    # TCG(소프트 에뮬)는 매우 느리니 라이브 부팅이 끝날 때까지 길게 캡처.
    for i in range(12):
        time.sleep(45)
        r = cmd({"execute": "screendump", "arguments": {"filename": f"{out}/shot{i}.ppm"}})
        print(f"shot{i}: {r}")
except Exception as e:  # noqa: BLE001
    print(f"QMP 오류: {e}")
finally:
    try:
        s.close()
    except OSError:
        pass
