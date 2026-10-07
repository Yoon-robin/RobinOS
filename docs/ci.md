# RobinOS CI

RobinOS는 초기 프로젝트 상태 점검에 GitHub Actions를 쓸 수 있지만, 꼭 필요한 건 아니에요. 로컬 검증과 Git 훅으로도 같은 검사를 할 수 있어요.

## Actions 없이 쓰기 (권장)

로컬 검증을 실행해요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-local-checks.ps1
```

pre-push 훅을 설치해요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-git-hooks.ps1
```

이제 `git push`할 때마다 로컬 검증이 먼저 돌아요.

## Validate

워크플로:

```text
.github/workflows/validate.yml
```

실행 조건:

- `main`에 푸시
- 풀 리퀘스트
- 수동 실행

검사 항목:

- 윈도우 정적 검증(`scripts/validate-project.ps1`)
- 스크립트와 설치되는 명령 프로토타입의 Bash 문법 검사

결제 문제, 지출 한도, 계정 설정 때문에 GitHub Actions를 쓸 수 없으면 같은 검사를 로컬에서 돌리세요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ci-local.ps1
```

## Build RobinOS ISO

워크플로:

```text
.github/workflows/build-iso.yml
```

실행 조건:

- ISO, 데스크톱, 패키지, 스크립트, 테마 중 하나라도 바뀐 `main` 푸시
- 수동 실행

privileged 모드로 띄운 `archlinux:latest` 컨테이너 안에서 `scripts/build-iso.sh`로 ISO를 빌드해요. 그래서 Arch VM이 따로 필요 없어요. ISO와 `SHA256SUMS`는 `robinos-iso` 아티팩트로 7일 동안 보관돼요. 빌드가 실패하면 mkarchiso 로그를 `robinos-build-log`로 올려요.

## Boot-test RobinOS ISO

워크플로:

```text
.github/workflows/boot-test.yml
```

실행 조건:

- `Build RobinOS ISO` 실행이 성공할 때마다
- 수동 실행 (테스트할 빌드의 실행 ID를 지정할 수도 있어요)

`scripts/boot-test.sh`가 QEMU에서 ISO를 부팅해요(KVM을 쓸 수 있으면 KVM 사용). Hyper-V처럼 평범한 VGA 디스플레이를 쓰기 때문에 데스크톱이 소프트웨어 렌더링으로 시작해요. 그다음 `scripts/boot-test-qmp.py`가 런처(검색, 윈도우 앱 이름 검색), 빠른 설정, 윈도우 명령과 첫 학습 미션을 띄운 터미널, 잠금 화면을 열면서 단계마다 스크린샷을 찍어요.

결과:

- 스크린샷과 `serial.log`는 `robinos-boot-test` 아티팩트로 올라가요
- 같은 스크린샷이 `boot-test` 프리릴리스에도 올라가고, 작업 요약에 표시돼요
- 시리얼 로그의 주요 줄(`robinos-session`, SDDM, 실패한 유닛)도 작업 요약에 나와요

테스트는 `robinos.debug`를 붙여 부팅해요. 이 옵션이 있으면 `robinos-session`이 Hyprland와 셸 출력을 저널에 복사하기 때문에 `serial.log`에서도 볼 수 있어요.

빌드한 뒤 리눅스에서 직접 돌려 볼 수도 있어요.

```bash
scripts/boot-test.sh out/robinos-*.iso
```

## Arch Package Check

워크플로:

```text
.github/workflows/arch-package-check.yml
```

실행 조건:

- 수동 실행
- 매주 정기 실행

검사 항목:

- `pacman -Si`로 현재 Arch 저장소에 패키지 이름이 있는지 확인

패키지가 다른 저장소로 옮겨 가거나 도구를 AUR이나 수동으로 설치해야 하면 이 워크플로가 실패할 수 있어요. 그럴 때는 그 도구를 `packages/security-optional.txt`로 옮기거나 패키지 이름을 고치세요.

## 현재 한계

GitHub Actions는 계정에 워크플로 실행이 허용돼 있어야 돌아가요. 작업이 시작되기도 전에 결제나 지출 한도 메시지를 내며 실패하면, GitHub 계정의 결제와 설정을 먼저 고친 다음 워크플로를 다시 실행하세요.
