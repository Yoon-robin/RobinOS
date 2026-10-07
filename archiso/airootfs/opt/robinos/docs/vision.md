# RobinOS 비전

RobinOS는 Kali Linux에 새 옷만 입힌 OS가 아니라, 보안을 배우기 위한 OS여야 해요.

Kali는 전문가용 모의해킹 도구 모음으로는 훌륭해요. RobinOS는 다른 데 집중해서 차별화해야 해요. 안내를 따라 배우는 학습, 안전한 랩 경계, 한국어 우선 사용성, 깔끔한 워크스테이션 경험이에요.

## 브랜드 약속

RobinOS는 Arch를 보안 학습에 집중한 워크스테이션으로 바꿔요.

## 차별점

### 1. 학습 중심 구성

보안 도구는 학습 경로에 따라 묶어야 해요.

- 리눅스와 네트워크 기초
- 웹 보안
- CTF 기본기
- 리버스 엔지니어링
- 디지털 포렌식
- 무선 보안
- 클라우드와 컨테이너 보안

쓸 만한 도구를 전부 설치하지 않아요. 잘 골라 둔 기본 도구만 깔고, 실력이 늘면 사용자가 프로필을 추가할 수 있게 해야 해요.

### 2. 더 안전한 기본값

RobinOS는 윤리적이고 통제된 실습으로 이끌어야 해요.

- 기본 실습 대상은 랩 안에만
- 로컬 취약 앱은 컨테이너에서 실행
- 학습 도구와 일상 앱을 확실히 분리
- 기본 프로필에는 은닉, 지속성 확보, 자격 증명 악용 도구 없음
- 큰 업데이트 전에 스냅샷

### 3. 한국어 사용자에게 편한 환경

RobinOS는 첫 부팅부터 한국어 사용자에게 자연스러워야 해요.

- 한국어 로캘 선택
- 한글 입력기 설정
- 한글에 맞는 글꼴
- 한국어 빠른 시작 문서
- 시간대와 키보드 설정 지원

### 4. 자체 시스템 계층

RobinOS에는 자체 명령과, 시스템을 하나로 엮어 주는 연결 코드가 필요해요.

```bash
robinctl doctor
robinctl update
robinctl snapshot create
robinctl snapshot rollback 12
robinctl profile security
robinctl learn
robinctl lab start web
robinctl lab stop web
```

그래야 RobinOS가 테마 팩이 아니라 진짜 OS처럼 느껴져요.

## 추천하는 기반

Arch Linux를 기반으로 써요.

이유:

- 최신 보안·개발 패키지
- `archiso`로 마음껏 손볼 수 있는 구조
- `pacman`, AUR, 필요하면 BlackArch까지 연동
- RobinOS만의 정체성을 만들기에 잘 맞음

Kali Linux는 기반이 아니라 참고 대상으로 봐야 해요. Kali를 기반으로 삼으면 RobinOS는 Kali 리믹스로 보이기 쉬워요. Arch를 쓰면 RobinOS가 자기만의 OS로 자랄 여지가 더 커요.
