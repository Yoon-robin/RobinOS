# RobinOS 로컬 검증

GitHub Actions는 꼭 쓰지 않아도 돼요. RobinOS는 푸시하거나 빌드하기 전에 로컬에서 검증할 수 있어요.

## 처음 한 번만 하는 훅 설정

로컬 pre-push 훅을 설치해요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-git-hooks.ps1
```

설치하고 나면 `git push`를 할 때마다 다음 스크립트가 실행돼요.

```powershell
scripts/ci-local.ps1
```

검증에 실패하면 푸시가 막혀요.

## 직접 로컬 점검하기

다음 명령을 실행해요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-local-checks.ps1
```

로컬 CI를 돌리고 Git 상태를 보여 줘요.

## Arch VM 점검

Arch Linux에서 실행해요.

```bash
scripts/check-arch-packages.sh
scripts/build-iso.sh
```

ISO를 만들 준비가 됐는지는 이 단계에서 제대로 확인돼요.

## 권장 흐름

GitHub Actions 대신 이 순서로 작업하세요.

```text
Edit files
Run scripts/run-local-checks.ps1
Commit
Push
Build in Arch VM
Boot the ISO in a VM
```
