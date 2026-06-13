# layer-shell 독·메뉴바 (설계 노트)

> RobinOS 독·메뉴바를 앱 창에 **가리지 않게** 만드는 작업(ROADMAP #10). 이 브랜치(`feat/layer-shell`)에서 실험 → ISO 실부팅 검증 → 좋으면 main 병합.

## 문제

RobinOS 셸(Flutter, `os.robinos.shell`)은 **창 하나**다. 그 안에 배경(오로라) + 독 + 메뉴바 + 오버레이를 전부 그린다.
**창 하나는 "풀스크린 백드롭"인 동시에 "항상 맨 위 패널"이 될 수 없다.** (맨 위로 올리면 앱을 다 가리고, 배경으로 내리면 독이 앱 밑으로 깔린다.)

지금까지의 우회책: 셸=풀스크린 백드롭(maximize), 실제 앱=70% 중앙 floating → 독·메뉴바가 가장자리에 "엿보임". 단점: 앱을 옮기거나 키우면 독·메뉴바를 덮음.

## 가능한 두 방향

**A. 셸 = `background` layer-shell 표면 + sway gap 예약 (이 브랜치에서 채택)**
- 셸을 wlr-layer-shell **background** 표면(전체 화면)으로. 데스크톱 배경처럼 모든 창 **아래**에 깔린다.
- sway가 실제 앱을 **타일링**하되 `gaps top 34 / bottom 96`으로 상단(메뉴바)·하단(독) 영역을 **비운다**.
- 그 비운 영역엔 아무 앱도 안 와서, background 레이어에 그려진 **메뉴바·독이 항상 보인다**. (맨 위가 아니라, 아무도 안 가리는 영역에 있는 것.)
- 장점: 단일 창 유지, 구현 단순, 독·메뉴바 항상 보임. 단점: 앱이 **타일링**됨(맥OS식 자유 floating이 기본이 아님 — 단 `Super+Space`로 개별 floating 토글 가능). 오버레이(런치패드/Spotlight)는 background라 열린 앱 뒤로 감(※ 현재도 동일한 한계라 회귀 아님).

**B. 셸 = `top`/`overlay` 표면 + 중앙 투명 + 입력 영역 = 패널만 (미채택, 향후)**
- 셸을 맨 위 레이어로, 중앙은 투명 + 입력 통과(독·메뉴바 사각형만 입력 캡처). 앱은 그대로 floating, 독은 진짜 항상 위.
- 단점: 중앙 투명 → Flutter 오로라 배경 사라짐(swaybg 등 별도 배경 필요, 패럴랙스 상실), 입력 영역/키보드 동적 관리 복잡, 깨지기 쉬움.

→ **A를 먼저** 실험(단순·견고). 부팅에서 느낌 확인 후 B로 갈지, A를 다듬을지 결정.

## 이 브랜치의 변경

- `linux/runner/my_application.cc` — gtk-layer-shell 있으면(Wayland) 창을 background 레이어로(anchor 4변, exclusive 0, keyboard on-demand). 없거나 미지원이면 기존 `maximize` 폴백.
- `linux/CMakeLists.txt` / `linux/runner/CMakeLists.txt` — `gtk-layer-shell-0` **선택적** 링크(`HAVE_GTK_LAYER_SHELL` 정의). 라이브러리 없으면 그냥 폴백(빌드는 성공).
- `.github/workflows/build-iso.yml` — 빌드 deps에 `libgtk-layer-shell-dev`.
- `boot/config/package-lists/robinos.list.chroot` — 런타임 `libgtk-layer-shell0`.
- `boot/config/includes.chroot/etc/sway/config` — 앱 타일링 + `gaps top 34 / bottom 96`(메뉴바·독 예약). 이전 70% floating 규칙 제거.

## 검증 방법 (네가 해줄 것)

1. GitHub → Actions → **Build RobinOS ISO** → Run workflow → **Branch: `feat/layer-shell`** 선택.
2. 나온 ISO를 QEMU/USB로 부팅:
   - 독·메뉴바가 **항상 보이는지**(앱을 열고 키워도 안 가려지는지).
   - 앱이 상단 34px·하단 96px을 침범하지 않는지.
   - Spotlight/Robin 입력(키보드) 동작 여부.
3. 좋으면 main 병합. 어색하면(타일링 싫음 등) B 방향 또는 gap 값 조정.

## 되돌리기

문제 시 `feat/layer-shell`를 버리면 끝(main은 무관). 부분 폴백: gtk-layer-shell 미설치면 셸은 자동으로 기존 maximize 백드롭으로 동작.
