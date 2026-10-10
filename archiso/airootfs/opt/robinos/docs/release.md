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
out/SHA256SUMS.sig            (이 PC에 릴리스 열쇠가 있을 때)
out/packages/robinos-*.pkg.tar.zst(.sig)   (ISO에 넣은 RobinOS 패키지)
build/logs/mkarchiso-*.log
```

## 배포 전에 모두 통과해야 하는 것

- 정적 검증 (`scripts/validate-project.ps1`)
- 데스크톱 설정 검사와 `qmllint` (`scripts/wsl-build.ps1 check`)
- 패키지 검사 (빌드할 때 자동)
- ISO 빌드 성공과 `SHA256SUMS`. 릴리스 ISO는 `wsl-build.ps1 build`(xz 압축)로 만들어요. `verify`가 만드는 테스트 ISO는 zstd라 2GiB를 넘어서 올릴 수 없어요. 2026-10-10의 xz ISO는 2,101,510,144바이트로 한도(2,147,483,648바이트)까지 약 44MiB 남았어요. 라이브 ISO(`archiso/packages.x86_64`)에 패키지를 더하면 공개 전에 크기부터 봐요. 넘으면 무거운 보안 도구를 라이브 ISO에서 빼고 설치본이나 프로필로 옮기는 게 먼저예요
- 자동 부팅 테스트: 스크린샷을 한 장씩 보고 이상이 없는지
- `robinctl` 테스트(`scripts/test-robinctl.sh`)와 설치기 테스트(`scripts/test-robin-install.py`), 둘 다 `check`에 들어 있어요
- 설치 테스트: `archinstall`, `robinos`, `windows` 세 방식 모두, 한 번은 `-Lab`을 붙여 웹 랩까지
- VM에서 직접 써 보기의 "눈으로 확인할 것" 목록
- 실기기 한 대 이상에서 라이브 부팅
- 문서와 `/etc/motd`에 윤리 안내가 보임

## 서명

`scripts/build-iso.sh`는 빌드 PC에 릴리스 열쇠가 있으면 `SHA256SUMS`에 서명해서 `SHA256SUMS.sig`를 만들고, 저장소의 공개 열쇠([keys/robinos-release.asc](../keys/robinos-release.asc))만으로 바로 확인해요. 열쇠가 없으면 서명 없이 "note: no release key"만 남겨요.

- 열쇠: `RobinOS Release Signing <115547263+Yoon-robin@users.noreply.github.com>`, RSA 4096, 서명 전용, 지문 `D8EB 0C49 5CBF 5B2B BB57 EACC FD9B 53B8 B79E 9AAD`, 2026-10-10에 만들고 2029-10-09에 끝나요(그 전에 `gpg --quick-set-expire`로 늘려요)
- 개인 열쇠는 이 PC의 WSL(`archlinux`) 안 `/root/.robinos-signing`(권한 700)에만 있어요. 빌드가 사람 없이 서명하도록 암호를 걸지 않았어요. 저장소에는 절대 넣지 않아요
- 폐기 인증서: 같은 폴더의 `openpgp-revocs.d/D8EB0C495CBF5B2BBB57EACCFD9B53B8B79E9AAD.rev`. 열쇠가 새면 이걸로 폐기를 알려요
- 백업: PC가 망가지면 열쇠도 사라져요. 오프라인 USB 같은 곳에 따로 보관해 두는 걸 권해요: `wsl -d archlinux -u root -e env GNUPGHOME=/root/.robinos-signing gpg --armor --export-secret-keys D8EB0C495CBF5B2BBB57EACCFD9B53B8B79E9AAD > robinos-release-secret.asc` (이 파일은 USB에만 두고 PC에서는 지워요)
- 같은 열쇠로 RobinOS 파일 업데이트(pacman 저장소)에도 서명해요(아래 "RobinOS 패키지 저장소")

## RobinOS 패키지 저장소

설치한 시스템이 RobinOS 파일 업데이트를 받는 pacman 저장소예요([design.md](design.md) "RobinOS 파일 업데이트"). 깃허브 릴리스 `repo`(프리릴리스, "최신" 표시 안 함)의 첨부 파일이 저장소예요: `robinos.db`, `robinos.files`와 그 서명, 패키지 `robinos-<버전>-1-any.pkg.tar.zst`와 서명.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 publish-repo
```

1. WSL에서 HEAD로 패키지를 빌드하고(`scripts/build-package.sh`: 파일 목록, robinctl, 서명 확인), 서명한 데이터베이스를 만들어요(`scripts/build-repo.sh`)
2. 윈도우의 `gh`로 릴리스 `repo`에 올리고(같은 이름은 바꿔 올림), 데이터베이스에 없는 옛 패키지는 지워요
3. 버린 루트에 깃허브에서 받아 설치해 봐요(`scripts/test-repo.sh`, `SigLevel = Required`)

패키지 버전은 `config/robinos.toml`의 버전과 커밋 수예요(예: `0.3.0.r400`). 검증을 통과한 main에서만 올려요.

ISO 빌드(`build-iso.sh`)도 같은 커밋의 패키지를 만들어 라이브 ISO의 `/opt/robinos/pkg`에 넣어요. 설치기는 그 패키지로 설치하고, 업데이트부터 저장소를 봐요. 그래서 ISO를 공개할 때는 같은 커밋(또는 더 새것)으로 저장소도 올려요. 저장소가 더 오래되면 그 사이에는 RobinOS 파일 업데이트가 오지 않아요(pacman이 "local is newer"라고만 해요).

## 배포

- `SHA256SUMS`, `SHA256SUMS.sig`, 공개 열쇠(`keys/robinos-release.asc`)와 함께 GitHub 릴리스에 올려요.
- 릴리스 노트에는 v0.1 범위([design.md](design.md))에서 바뀐 점과 알려진 한계를 적어요.
