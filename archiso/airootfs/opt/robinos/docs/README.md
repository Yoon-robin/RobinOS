# RobinOS 문서 지도

문서마다 맡은 내용이 정해져 있어요. 같은 내용은 한 곳(원본)에만 쓰고, 다른 문서에서는 링크만 걸어요. 그래야 고칠 때 한 군데만 고치면 돼요.

## 무엇이 어디에 있나요

| 내용 | 원본 |
|---|---|
| 제품 방향, 설계 결정, v0.1 범위와 항목별 상태 | [design.md](design.md) |
| 지금 할 일, 진행 중인 작업, 푸시 대기 커밋, 사용자 확인이 필요한 것 | [tasks.md](tasks.md) (오래된 완료 기록은 [done.md](done.md)) |
| 장기 단계 (0~6단계) | [roadmap.md](roadmap.md) |
| 루프 작업 절차 (Claude가 회차마다 따르는 순서) | [loop.md](loop.md) |
| 검사 방법, 바꾼 것에 따라 돌릴 검사 | [testing.md](testing.md) |
| 빌드 환경 (WSL 2, Hyper-V, Docker) | [build-environment.md](build-environment.md) |
| ISO 빌드 과정 | [build-iso.md](build-iso.md) |
| 설치 방법 | [install.md](install.md) |
| 스냅샷과 복구 | [recovery.md](recovery.md) |
| 데스크톱 구성, 단축키, 셸 기능 | [desktop.md](desktop.md) |
| 릴리스 절차, 서명, RobinOS 패키지 저장소 | [release.md](release.md) |
| CTF 시작하기, 입문 CTF, 다음 연습장 | [ctf.md](ctf.md) |
| 디자인 토큰 | `desktop/shell/Theme.qml` (코드가 원본, [brand.md](brand.md)의 표는 사본) |

## 문서 목록

제품
- [vision.md](vision.md): 왜 RobinOS를 만드나요
- [design.md](design.md): 확정한 설계와 v0.1 범위
- [ethics.md](ethics.md): 윤리 기준
- [brand.md](brand.md): 로고, 팔레트, 글꼴

쓰는 사람을 위한 안내
- [install.md](install.md): 설치하기
- [recovery.md](recovery.md): 스냅샷으로 되돌리기
- [desktop.md](desktop.md): 데스크톱 쓰기와 바꾸기
- [ctf.md](ctf.md): CTF 시작하기
- [../labs/web/README.md](../labs/web/README.md): 웹 보안 랩
- [../labs/net/README.md](../labs/net/README.md): 네트워크 스캔 랩

개발
- [build-environment.md](build-environment.md): 빌드 환경 준비
- [build-iso.md](build-iso.md): ISO 빌드
- [hyperv-vm.md](hyperv-vm.md): Hyper-V로 Arch VM 만들기
- [testing.md](testing.md): 검사와 테스트
- [ci.md](ci.md): GitHub Actions (수동 실행만)
- [boot-branding.md](boot-branding.md): 부팅 메뉴와 로그인 화면 브랜딩
- [release.md](release.md): 릴리스 체크리스트
- [release-notes-v0.1.md](release-notes-v0.1.md): v0.1 프리뷰 릴리스 노트
- [release-notes-v0.2.md](release-notes-v0.2.md): v0.2 프리뷰 릴리스 노트
- [../themes/README.md](../themes/README.md): 테마 파일

작업 관리
- [tasks.md](tasks.md): 작업 목록
- [done.md](done.md): 오래된 완료 기록
- [roadmap.md](roadmap.md): 장기 로드맵
- [loop.md](loop.md): 루프 작업 절차
- [../CLAUDE.md](../CLAUDE.md): Claude가 이 저장소에서 지키는 규칙

## 문서 쓰는 규칙

- 한국어로 써요. 말투는 [design.md](design.md)의 "말투"를 따라요(해요체, 짧고 쉬운 문장, 번역투 없이). 코드, 명령, 경로, 워크플로 이름은 그대로 둬요.
- 코드를 바꾸면 같은 커밋에서 관련 문서도 고쳐요.

| 바꾼 것 | 같이 고칠 문서 |
|---|---|
| `robinctl` 명령 | `README.md`의 주요 명령, 해당 기능 문서(`recovery.md`, `desktop.md` 등) |
| 셸 기능, 단축키 | `desktop.md`, 환영 마법사의 단축키 안내(`Welcome.qml`), `README.md`의 핵심 아이디어 |
| 기본 앱 연결 (`desktop/mime/mimeapps.list`) | `desktop.md`의 "동영상과 음악, 기본 앱" |
| 학습 미션 (`robinctl learn`) | `README.md`의 학습 미션 표, `desktop.md`, 런처의 학습 미션 설명(`Launcher.qml`), `robinctl help`. 학습 센터(`LearnCenter.qml`)는 `robinctl learn tsv`를 읽으니 그 형식을 바꾸면 같이 고쳐요 |
| 패키지 목록 (`packages/*.txt`) | `install.md`(설치본에 들어가는 것), `desktop.md`(라이브 세션에 없는 것) |
| 설치 과정 (`post-install.sh`, `robin-install`) | `install.md`, `testing.md` |
| 테스트 스크립트 | `testing.md` |
| 빌드 스크립트, 빌드 환경 | `build-iso.md`, `build-environment.md`, `release.md` |
| RobinOS 패키지와 저장소 (`packaging/robinos`, `stage-robinos.sh`, `build-package.sh`, `build-repo.sh`, `robinctl repo`, `keys/`) | `release.md` "RobinOS 패키지 저장소", `design.md` "RobinOS 파일 업데이트", `install.md`, `testing.md`, `build-iso.md` |
| v0.1 항목의 상태 | `design.md`의 v0.1 표, `tasks.md` |
| 새 설계 결정 | `design.md` (결정과 이유, 날짜) |

- `archiso/airootfs/opt/robinos/docs/`는 라이브 ISO에 들어가는 사본이에요. 직접 고치지 말고 `scripts/sync-archiso-files.ps1`로 맞춰요.
