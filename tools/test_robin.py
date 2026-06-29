#!/usr/bin/env python3
"""Robin 명령 파서 회귀 테스트.  실행: python tools/test_robin.py"""
import os
import sys
from importlib.machinery import SourceFileLoader

HERE = os.path.dirname(os.path.abspath(__file__))
ROBIN = os.path.join(HERE, "..", "iso", "airootfs", "usr", "local", "bin", "robin")

robin = SourceFileLoader("robin", ROBIN).load_module()

CASES = {
    "안녕": "say",
    "너 누구야": "say",
    "몇시야": "say",
    "상태 알려줘": "status",
    "시스템 정보": "status",
    "볼륨 올려줘": "run",
    "소리 줄여": "run",
    "음소거": "run",
    "밝기 올려": "run",
    "밝기 낮춰": "run",
    "와이파이 상태": "network",
    "네트워크 상태": "network",
    "브라우저 열어줘": "run",
    "터미널 띄워": "run",
    "파일 열어": "run",
    "고양이 검색해줘": "run",
    "화면 잠가": "run",
    "도움말": "help",
    "종료": "exit",
    "ㅁㄴㅇㄹ": "unknown",
}


def main() -> int:
    fails = 0
    for text, want in CASES.items():
        got = robin.parse(text).kind
        if got != want:
            fails += 1
            print(f"FAIL  {text!r} -> {got} (want {want})")
    if fails:
        print(f"\n{fails}/{len(CASES)} 실패")
        return 1
    print(f"OK  {len(CASES)}개 통과")
    return 0


if __name__ == "__main__":
    sys.exit(main())
