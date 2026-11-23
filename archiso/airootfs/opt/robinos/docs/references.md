# 참고할 비슷한 사례

2026-10-13 사용자 요청("나처럼 OS 만든 사례 찾아서 참고할 부분 찾아봐")으로 웹에서 찾아 정리했어요. 혼자 또는 아주 작은 팀이 만든 배포판, RobinOS와 같은 목적(윈도우에서 넘어온 사람)을 가진 배포판, 같은 부품(Arch, Hyprland, Quickshell)을 쓴 프로젝트를 봤어요. 어디까지 확인했는지를 같이 적어 두었어요. 아래 숫자는 대부분 프로젝트 쪽 발표나 기사라서 그대로 믿기보다 방향을 잡는 데만 써요.

## 한눈에

| 사례 | RobinOS와 닮은 점 | 가져올 것 | 작업 |
|---|---|---|---|
| [Omarchy](https://learn.omacom.io/2/the-omarchy-manual) (DHH) | Arch + Hyprland, ISO 설치기, 스냅샷 부팅, 방화벽 기본 켬 | 보안 부팅·스냅샷·암호화를 한 설계로, 업데이트 "마이그레이션" | T-148, T-163 |
| [Zorin OS](https://zorin.com/os/) | 윈도우에서 온 사람이 목표, `.exe` 안내 | 앱 인식 목록(240개 넘게), 휴대폰 연결 | T-159, T-165 |
| [Pop!_OS](https://system76.com/support/pop-recovery) | - | "새로 설치하되 내 파일은 그대로" | T-171 |
| [EndeavourOS](https://discovery.endeavouros.com/installation/installation-intro/2021/03/) | Arch 기반 설치기 | 오프라인 설치를 대비책으로 | T-171 |
| [Linux Mint](https://www.ghacks.net/?p=145626) | 업데이트 전 스냅샷, 시작 화면 | 첫 로그인 점검표 | T-149 |
| [linux-hardware.org](https://en.opensuse.org/Hardware_probe) (`hw-probe`) | - | 실기기 호환성 표를 직접 만들지 않고 받기 | T-167 |
| [하모니카(HamoniKR)](https://docs.hamonikr.org/) | 한국어 우선, 윈도우 사용자 | 한국 사용자 문제의 선례 | T-175(후보) |
| [Antergos](https://www.phoronix.com/news/Antergos-EOL)의 마지막 | Arch 기반 작은 프로젝트 | 멈춰도 사용자가 순수 Arch로 가는 길 | 문서 후보 |

## 1. 같은 부품으로 만든 것

### Omarchy (Arch + Hyprland, [매뉴얼](https://learn.omacom.io/2/the-omarchy-manual))

DHH가 만든 Arch 기반 배포판이에요. 매뉴얼에서 확인한 구성이에요.

- **설치:** ISO 설치기. 디스크 전체 암호화(LUKS)가 기본이에요. 윈도우와 같이 쓰려면 윈도우 디스크 관리에서 볼륨을 먼저 줄이라고 안내해요(설치기가 줄여 주지 않아요). 레거시 BIOS는 안 되고 60GB가 필요해요.
- **스냅샷:** 부트로더 Limine에 Snapper 스냅샷이 나오고 `omarchy-snapshot` 명령이 있어요. RobinOS는 GRUB + grub-btrfs라 부품은 달라도 목적은 같아요.
- **업데이트:** 메뉴에서 "Update"를 누르면 Omarchy 코드 갱신, **마이그레이션**, 패키지 업데이트를 한꺼번에 해요. 방화벽은 기본으로 켜져 있어요. 상단 바는 Waybar예요.
- 한 서드파티 글이 Omarchy가 Quickshell을 쓴다고 했는데, 매뉴얼에서는 Waybar만 확인돼서 그 말은 믿지 않았어요.

**RobinOS에 쓸 것**

1. **보안 부팅 + 스냅샷 + 암호화는 한 번에 설계해요.** Omarchy 사용자들이 부딪친 문제가 그대로 RobinOS의 T-148(보안 부팅)과 T-163(디스크 암호화) 앞에 있어요([Omarchy 토론](https://github.com/basecamp/omarchy/discussions/2296), [CachyOS 포럼](https://discuss.cachyos.org/t/is-there-a-solution-for-making-secure-boot-work-with-limine-snapshots/8148)).
   - 서명한 UKI는 자기 커널 명령줄을 품고 있어서, 스냅샷으로 켜려고 넘기는 인자를 무시해요.
   - 보안 부팅을 켜기 전에 만든 스냅샷은 서명이 없어서 막혀요.
   - sbctl의 mkinitcpio 훅이 Limine와 안 맞아 엉뚱한 이미지에 서명해요.
   - 펌웨어 업데이트가 등록한 열쇠를 지우기도 해요.
   RobinOS의 "스냅샷으로 켜기"는 `rootflags=subvol=@snapshots/...`로 동작하니 같은 문제가 생길 수 있어요. 둘을 따로 만들면 하나가 다른 하나를 깨요.
2. **윈도우 옆 설치에서 설치기가 볼륨을 줄여 주지 않아도 흠은 아니에요.** Omarchy도 윈도우 디스크 관리에서 하라고 해요. 그래서 "설치기 안에서 C: 줄이기"는 P1에서 P2로 낮춰도 돼요. 대신 안내 화면에서 단계를 그림으로 보여 주는 쪽이 더 값져요.
3. **업데이트 마이그레이션:** `robinos` 패키지가 `/usr`은 갈아 끼워도 사용자 설정(`~/.config`, 저장된 테마)은 버전이 바뀔 때 손봐야 할 때가 생겨요. Omarchy처럼 버전마다 한 번만 도는 이전 스크립트가 필요해요(지금 없어요).

### Quickshell로 만든 셸들

Quickshell과 Hyprland 위에 셸을 만든 프로젝트가 여럿 있어요. 라이선스를 확인하지 않았으니 코드를 가져오지 말고 **기능 목록과 화면 구성만** 참고해요.

- [Caelestia](https://github.com/caelestia-dots/shell), [DankMaterialShell](https://github.com/bbedward/DankMaterialShell), [Noctalia](https://github.com/noctalia-dev/noctalia-shell)(MIT로 표시), [end-4의 dots-hyprland](https://github.com/end-4/dots-hyprland)
- DankMaterialShell의 설명이 RobinOS와 가장 비슷해요. Waybar, swaylock, swayidle, mako, fuzzel 같은 도구를 한 패키지로 바꾸고, Caelestia와 end-4를 영감으로 밝혀요.
- 이들은 개인 설정(dotfiles)이지 설치할 수 있는 OS가 아니에요. 설치기, 스냅샷 복구, 학습, 한국어를 갖춘 것이 RobinOS의 자리예요.

## 2. 윈도우에서 온 사람을 겨냥한 것

### Zorin OS

- 가장 큰 사례예요. Zorin이 발표한 숫자로는 Zorin OS 18이 두 달여 만에 100만 다운로드, 석 달 안에 200만을 넘겼고, 그중 78%쯤이 윈도우에서 받은 거라고 해요([TechRepublic](https://www.techrepublic.com/article/news-zorin-os-2m-downloads-windows-10-support-ends/), [Windows Central](https://www.windowscentral.com/microsoft/windows-10/windows-10-retirement-pushes-780-000-users-to-linux-as-zorin-os-hits-1m-downloads)). 다운로드이지 설치가 아니고, 직접 낸 숫자라 확인은 못 했어요. 그래도 "윈도우에서 넘어오려는 사람이 있다"는 건 보여 줘요.
- **`.exe` 안내:** `.exe`·`.msi`를 두 번 누르면 알아보고, 리눅스나 웹 대체 앱을 먼저 권하고, 원하면 Wine으로 실행해요. 알아보는 앱이 18에서 170개, 18.1에서 240개 넘게예요([Tecnoblog](https://tecnoblog.net/noticias/zorin-os-18-1-chega-com-mais-recursos-para-quem-foge-do-windows/)). RobinOS의 `.exe` 안내는 17개예요. **같은 방식인데 목록이 한 자리 작아요.**
- **Zorin Connect:** 안드로이드 폰과 같은 네트워크에서 알림, 파일, 사진을 주고받아요. RobinOS의 T-165(휴대폰 연결)가 보류인 이유가 이거예요.
- **돈:** 코어는 무료, Pro는 유료(가격은 확인 못 했어요).
- **철학이 달라요:** Zorin은 "배울 게 없다"를 약속하고 리눅스를 숨겨요. RobinOS는 윈도우 이름으로 시작해서 리눅스를 알려 줘요. 제가 찾은 범위에서는 터미널 힌트와 학습 미션을 이어 주는 배포판을 못 찾았어요(모든 배포판을 본 건 아니에요).

**RobinOS에 쓸 것:** `desktop/shell/windowsapps.js`의 알려진 앱을 늘려요(카카오톡, 네이버 웹하드, 알집, V3 같은 한국 앱을 더 넣는 쪽이 Zorin보다 유리해요).

### AnduinOS

마이크로소프트 엔지니어 한 명이 만든 윈도우 11 닮은 배포판이에요. Ubuntu 위에 GNOME 확장 18개로 꾸몄고, 기사에서 GNOME 확장은 데스크톱 버전이 바뀔 때 깨지기 쉽다고 경고해요([The Register](https://www.theregister.com/2025/05/23/anduinos/)). RobinOS는 확장이 아니라 셸을 직접 만들었으니 같은 약점은 없어요. 대신 Hyprland와 Quickshell이 빨리 바뀌어요(정기 점검의 "업스트림 변화" 줄이 이걸 봐요).

### 하모니카(HamoniKR), 구름 OS

한국에서 가장 가까운 선례예요.

- 하모니카는 리눅스 민트 MATE로 시작해(2014) 이후 우분투 계열과 Cinnamon으로 옮겼어요. 처음부터 한글 설정 없이 쓸 수 있게 했고, 한글 입력기(fcitx)를 넣고 HWP 뷰어를 같이 깔았어요([etnews 2014](https://m.etnews.com/20141201001461)). 2020년 사용자 가이드는 공공·민간 33곳에서 40만 명 넘게 쓴다고 해요. 무료이고 윈도우 앱은 Wine 안내 문서로 다뤄요([공식 문서](https://docs.hamonikr.org/)).
- 2020년에 행정안전부가 공공기관 PC를 국산 개방형 OS(하모니카, 구름, 티맥스)로 옮기겠다는 계획을 냈어요([기사](https://v.daum.net/v/20200204150508999)). 2026년 현재 얼마나 됐는지는 못 찾았어요.
- 한국의 윈도우 10 점유율이 2025년 9월에 52.41%였다는 보도가 있어요([파이낸셜뉴스](https://www.fnnews.com/news/202510171856566539)). 지원 종료(2025-10-14)가 이미 지났다는 뜻이에요.

**RobinOS에 쓸 것:** 하모니카가 이미 보여 주듯 한국어 입력, HWP 열기, 윈도우 앱 안내는 처음부터 있어야 해요. RobinOS는 이 셋이 있고(HWP는 LibreOffice의 제한적인 열기와 한컴독스 안내), 더 새로운 건 "리눅스를 배우게 한다"는 점이에요.

### 한국 사용자 문제는 아직 아무도 풀지 못했어요

- **HWP:** LibreOffice로 열면 서식이 깨지는 일이 많다고 해요. 한컴독스는 브라우저에서 열고 편집하지만 파일이 서버로 올라가요. 오픈소스 HWP 뷰어 `rhwp`가 눈에 띄지만 리눅스에서 되는지는 확인 못 했어요. 리눅스용 한컴오피스를 개인이 쓸 수 있는지는 못 찾았어요.
- **은행, 공동·금융인증서:** 2026년 현재 리눅스 지원 상황을 확인하지 못했어요. 은행마다 달라서 한 번에 "된다/안 된다"를 쓸 수 없어요.
- **제안:** "내 은행이 리눅스에서 되나요"를 한 장의 표로 모으는 일은 사용자가 직접 확인한 결과를 받는 쪽이 정확해요(T-167의 실기기 표와 같이).

## 3. 설치, 복구, 점검에서 가져올 것

### Pop!_OS의 "새로 설치"(Refresh Install)

[복구 파티션에서 시스템만 새로 설치하고 사용자 파일은 그대로 두는 기능](https://system76.com/support/pop-recovery)이에요. 홈 밖에 깐 앱은 사라진다고 분명히 적어 두었어요.

**RobinOS에 쓸 것:** 지금 재설치는 `mkfs.btrfs -f`로 파티션 전체를 지워요(개인 파일도). 그런데 RobinOS는 `@`, `@home`, `@log`, `@pkg`, `@snapshots` 하위 볼륨이라, **재설치할 때 `@home`만 남기고 나머지를 다시 만드는 게 자연스러워요.** 이 안이 [unfinished.md](unfinished.md)의 "재설치할 때 `/home` 지키기"를 푸는 가장 작은 길이에요. 오래된 `@snapshots`는 새 `@`와 맞지 않으니 지우고요.

### EndeavourOS: 온라인 설치를 기본, 오프라인을 대비책으로

EndeavourOS는 인터넷에서 패키지를 받는 설치(기본)와, 라이브 이미지를 그대로 복사하는 오프라인 설치를 둘 다 줘요. 오프라인은 인터넷 문제 때를 위한 대비책이라고 해요([포럼](https://forum.endeavouros.com/t/which-packages-does-endeavouros-install-by-default/33217)). 온라인이 실패했는데 오프라인은 됐다는 후기도 있어요.

**RobinOS에 쓸 것:** 인터넷이 안 되는 PC에서 지금은 설치를 못 해요. 라이브 이미지(`airootfs.sfs`)를 복사하는 대비책을 만들 수 있지만, RobinOS의 ISO는 2GiB 때문에 오피스와 앱 스토어가 빠져 있어요. 그래서 오프라인 설치로는 "기본 시스템만" 깔리고, 인터넷이 되면 나머지를 받게 안내하는 식이 돼요.

### Linux Mint: 업데이트 전 스냅샷과 시작 화면

- Mint 19부터 업데이트 관리자가 Timeshift 설정을 먼저 권하고, 그 안전망 덕분에 업데이트를 모두 선택한 채로 둬요([ghacks](https://www.ghacks.net/?p=145626)). RobinOS의 "업데이트 전 자동 스냅샷"과 같은 생각이에요.
- 시작 화면(First Steps)이 데스크톱 색, 시스템 스냅샷, **드라이버 관리자**, 업데이트 관리자를 한 줄로 이어 줘요([Going Linux](https://www.goinglinux.com/linux-mints-welcome-screen/)).

**RobinOS에 쓸 것:** 환영 마법사의 마지막에 "업데이트 확인, 스냅샷 확인, 그래픽 드라이버(NVIDIA면 `nvidia-open`이 깔렸는지)" 점검표를 넣어요. 설정 앱 "정보"에 그래픽 드라이버를 보여 주는 건 Mint의 드라이버 관리자에 해당해요.

### hw-probe와 linux-hardware.org

`hw-probe`는 한 명령으로 하드웨어와 로그를 모아 [공개 하드웨어 데이터베이스](https://en.opensuse.org/Hardware_probe)에 올리고 보고서 링크를 줘요. Ubuntu, Fedora, openSUSE 위키가 모두 안내해요. 이름, 호스트명, IP, MAC, 일련번호는 올리지 않고 해시를 올린다고 해요(해시는 완전한 익명이 아니고, 올린 보고서는 공개 통계에 쓰여요. 사용 전 내용을 볼 수 있어요).

**RobinOS에 쓸 것:** T-167의 "실기기 호환성 표"를 직접 만들 필요 없이 `robinctl doctor`가 **동의를 받고** `hw-probe`를 돌려 링크를 주게 하면 돼요. 사용자가 올린 링크를 모으면 RobinOS 이용자의 기기 표가 돼요(올리지 않는 쪽이 기본이에요).

### Vanilla OS: 쉬우려고 바꿀 수 없게 만들면 생기는 일

초보자를 위해 A/B 파티션 불변 시스템을 만든 사례예요. 첫 설정 앱과 자동 백그라운드 업데이트는 좋은 평을 받았지만, 시스템 패키지를 깔려면 `abroot pkg add` 후 재부팅해야 하고 문서가 모호하다는 비판이 컸어요([Linuxiac](https://linuxiac.com/vanilla-os-promising-idea-disappointing-implementation/)). RobinOS가 일반 Arch에 스냅샷을 얹은 방식을 고른 이유(막지 않고 되돌린다)를 뒷받침해요.

## 4. 작은 프로젝트가 오래 가려면

### Antergos의 마지막

Arch 기반 Antergos는 2019년 5월 "시간이 없다"며 스스로 끝냈어요([Phoronix](https://www.phoronix.com/news/Antergos-EOL)). 눈여겨볼 점은 이렇게 끝냈다는 거예요.

- 코드를 열어 두어 누구나 포크할 수 있게 했고, 사용자는 저장소와 Antergos 전용 패키지를 빼면 순수 Arch로 계속 업데이트할 수 있었어요.
- 포럼 관리자들이 며칠 만에 이어 가서 2019년 7월에 EndeavourOS가 나왔어요.
- 작은 배포판이 닫는 이유는 대부분 번아웃과 수익 부족이라고 해요([Linuxiac](https://linuxiac.com/when-passion-is-not-enough-small-linux-projects-big-problems/)). 한두 명이 하는 프로젝트는 대체할 사람이 없어요.

**RobinOS에 쓸 것(문서 후보):** "RobinOS가 멈추면 내 컴퓨터는 어떻게 되나요"를 한 장으로 적어요. RobinOS는 Arch에 `robinos` 패키지와 `[robinos]` 저장소를 얹은 거라, **저장소를 빼고 `robinos` 패키지를 지우면 순수 Arch**예요. 이 약속을 문서에 쓰고 테스트로 지키면(설치 테스트에서 저장소를 뺀 뒤 `pacman -Syu`가 되는지) 사용자의 위험이 크게 줄어요.

### 돈은 어디서 오나

- [elementary OS](https://blog.elementary.io/building-the-future-of-elementary-os/): 앱 스토어를 "내고 싶은 만큼 내기"로 해서 개발자에게 돈이 가게 했어요. 인디고고로 모은 돈이 1만 달러쯤이라 성과는 크지 않았고, 후원(GitHub Sponsors, Patreon, Liberapay)을 같이 써요.
- [Nobara](https://en.wikipedia.org/wiki/Nobara_(operating_system)): 개발자 한 명이 이끌고 Patreon 후원으로 굴러가요(한 기사에서 후원자 1,577명이라고 했는데 다른 곳에서는 확인 못 했어요).
- Zorin: 코어는 무료, Pro는 유료예요.
- 돈은 사용자가 정할 일이라 [tasks.md](tasks.md)의 "사용자 확인 필요"에 올려 두고 지금은 아무것도 열지 않아요.

### 홍보와 모임

"End of 10" 캠페인은 윈도우 10 지원 종료를 계기로 도서관과 수리 카페에서 설치 모임을 열었어요. 배포판 중립이라 RobinOS 같은 신생 배포판이 직접 들어가기는 어려워요([Linuxiac](https://linuxiac.com/end-of-10-campaign-highlights-benefits-of-linux-transition/)). 지원 종료일이 이미 지나서 같은 바람은 없어요. 한국어 커뮤니티에서 설치 모임을 여는 쪽이 더 현실적일 거예요.

## 5. 정리: 할 만한 일 일곱 가지

| # | 할 일 | 근거 | 연결 |
|---|---|---|---|
| 1 | 보안 부팅, 스냅샷 부팅, 디스크 암호화를 한 설계로 정하기 | Omarchy 사용자들이 겪은 서명, UKI, 스냅샷 충돌 | T-148, T-163 |
| 2 | 재설치할 때 `@home`을 남기기 | Pop!_OS Refresh Install, RobinOS의 하위 볼륨 구조 | T-171 |
| 3 | `.exe` 안내 목록을 17개에서 늘리기 | Zorin 240개 넘게 | T-159 |
| 4 | `robinctl doctor`에 `hw-probe`(동의 받고) | 실기기 표를 직접 만들지 않기 | T-167 |
| 5 | 오프라인 설치를 대비책으로(기본 시스템만) | EndeavourOS | T-171 |
| 6 | 업데이트 마이그레이션 스크립트 틀 | Omarchy 업데이트 | 새 작업 후보 |
| 7 | "RobinOS가 멈추면" 문서와 저장소를 뺀 `pacman -Syu` 테스트 | Antergos의 끝맺음 | 문서 후보 |

## 확인하지 못한 것

- Zorin의 다운로드 숫자와 윈도우 비율은 Zorin이 직접 낸 거예요.
- 하모니카의 최신 버전과 현재 사용 규모는 확인하지 못했어요(2020년 사용자 가이드 숫자만).
- 국내 은행이 지금 리눅스를 지원하는지, 한컴오피스 리눅스 개인판이 있는지는 못 찾았어요.
- Quickshell 셸들의 라이선스는 Noctalia(MIT)만 봤어요.
- Nobara의 후원자 수는 한 기사의 숫자예요.
