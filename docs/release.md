# RobinOS 릴리스 체크리스트

프리뷰 ISO를 낼 때 쓰는 체크리스트예요. 각 검사의 방법은 [testing.md](testing.md)에 있어요.

## 빌드

```powershell
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 build
```

나와야 하는 파일 (WSL의 `/root/RobinOS/` 아래):

```text
out/robinos-*.iso
out/SHA256SUMS
build/logs/mkarchiso-*.log
```

## 배포 전에 모두 통과해야 하는 것

- 정적 검증 (`scripts/validate-project.ps1`)
- 데스크톱 설정 검사와 `qmllint` (`scripts/wsl-build.ps1 check`)
- 패키지 검사 (빌드할 때 자동)
- ISO 빌드 성공과 `SHA256SUMS`
- 자동 부팅 테스트: 스크린샷을 한 장씩 보고 이상이 없는지
- 설치 테스트: `archinstall`과 `robinos` 두 방식 모두
- VM에서 직접 써 보기의 "눈으로 확인할 것" 목록
- 실기기 한 대 이상에서 라이브 부팅
- 문서와 `/etc/motd`에 윤리 안내가 보임

## 배포

- `SHA256SUMS`와 함께 GitHub 릴리스에 올려요.
- 릴리스 노트에는 v0.1 범위([design.md](design.md))에서 바뀐 점과 알려진 한계를 적어요.
