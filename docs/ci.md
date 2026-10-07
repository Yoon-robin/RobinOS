# RobinOS CI

RobinOS는 GitHub Actions로 자동 검증하지 않아요. 빌드와 테스트는 개발 PC에서 해요([testing.md](testing.md)). 푸시해도 워크플로가 돌지 않게 모든 워크플로를 수동 실행(`workflow_dispatch`)으로만 남겨 뒀어요.

## 남아 있는 워크플로

필요할 때 GitHub의 Actions 탭이나 `gh workflow run`으로 직접 실행할 수 있어요. 로컬 검사와 같은 일을 해요.

| 워크플로 | 파일 | 하는 일 | 로컬에서는 |
|---|---|---|---|
| `Validate` | `.github/workflows/validate.yml` | 정적 검증, Bash 문법, Python 문법, 데스크톱 설정 검사 | `scripts/validate-project.ps1`, `scripts/ci-local.ps1`, `scripts/wsl-build.ps1 check` |
| `Arch Package Check` | `.github/workflows/arch-package-check.yml` | 패키지 이름이 Arch 저장소에 있는지 | `scripts/check-arch-packages.sh` |
| `Build RobinOS ISO` | `.github/workflows/build-iso.yml` | privileged `archlinux:latest` 컨테이너에서 ISO 빌드, `robinos-iso` 아티팩트로 7일 보관 | `scripts/wsl-build.ps1 build` |
| `Boot-test RobinOS ISO` | `.github/workflows/boot-test.yml` | 빌드한 ISO를 QEMU(KVM)로 부팅해 스크린샷을 `boot-test` 프리릴리스에 올려요 | `scripts/wsl-build.ps1 boot-test` |

`Boot-test RobinOS ISO`는 실행 ID를 입력하면 그 빌드를, 비워 두면 가장 최근에 성공한 빌드를 테스트해요.

```bash
gh workflow run build-iso.yml
gh workflow run boot-test.yml -f run_id=<빌드 실행 ID>
```

## 다시 자동으로 돌리려면

워크플로 파일의 `on:`에 `push`나 `workflow_run` 조건을 다시 넣으면 돼요. 공개 저장소라 GitHub 호스트 러너는 무료지만, ISO 빌드와 부팅 테스트가 푸시마다 25분쯤 걸려요.
