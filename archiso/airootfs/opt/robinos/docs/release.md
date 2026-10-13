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

## 배포

- `SHA256SUMS`, `SHA256SUMS.sig`, 공개 열쇠(`keys/robinos-release.asc`)와 함께 GitHub 릴리스에 올려요.
- 릴리스 노트에는 v0.1 범위([design.md](design.md))에서 바뀐 점과 알려진 한계를 적어요.

## 웹사이트

랜딩 페이지는 `site/`에 있어요(빌드 없는 HTML, CSS, JS). GitHub Pages가 `gh-pages` 브랜치를 https://yoon-robin.github.io/RobinOS/ 로 무료로 보여 줘요. GitHub Actions는 쓰지 않아요.

- 고치고 커밋한 뒤 `bash scripts/publish-site.sh`로 올려요. `site/`만 떼어 낸 커밋을 `gh-pages`에 밀어 넣어요(`--dry-run`이면 올릴 파일만 보여 줘요).
- 처음 한 번은 저장소 Settings → Pages에서 "Deploy from a branch", `gh-pages`, `/ (root)`를 골라요(2026-10-13에 브랜치를 올리자 저절로 켜졌어요).
- 미리 보기: `python -m http.server 8642 --directory site` 뒤 http://127.0.0.1:8642
- 디자인 기준은 [taste-skill](https://github.com/Leonxlnx/taste-skill)(MIT)의 `taste-skill`과 `redesign-skill`이에요(2026-10-13 사용자 요청). 첫 화면은 왼쪽 글, 오른쪽 실제 화면이고, 같은 크기 카드 줄, div로 그린 가짜 화면, 섹션마다 붙는 작은 머리글, 장식 점, 긴 대시를 쓰지 않아요. 라이트·다크 둘 다, 움직임 줄이기를 지켜요.
- 문구와 힌트를 바꾸면 `python scripts/build-site.py --fonts build/site-fonts`를 다시 돌려요. `site/hints.json`(페이지의 터미널이 쓰는 표, `desktop/bash/robinos-hints.sh`에서 만들어요)과 페이지에 쓰인 글자만 남긴 Pretendard(`site/assets/fonts/Pretendard-*.woff2`, 굵기마다 약 40KB)를 만들어요. `build/site-fonts`에는 `scripts/fetch-fonts.sh`가 체크섬을 확인해 받아 둔 Pretendard 1.3.9 zip의 `web/static/woff2-subset/Pretendard-*.subset.woff2`를 넣어요(fontTools 필요). Geist와 Geist Mono는 같은 zip의 가변 woff2를 그대로 써요. 글꼴 라이선스(SIL OFL)는 `site/assets/fonts/*-OFL.txt`에 같이 둬요.
- 화면 사진(`site/assets/screens/*.webp`)은 부팅·설치 테스트 스크린샷(`build/boot-test`, `build/install-test`)을 잘라 WebP로 만든 거예요. 링크 미리 보기 그림(`site/assets/og.jpg`, 1200×630)은 첫 화면을 헤드리스 크롬으로 찍었어요.
- 문구는 [design.md](design.md)의 목적과 약속을 따르고, 아직 안 되는 것을 된다고 쓰지 않아요(실제 PC 확인 전에는 "미리 보기").
