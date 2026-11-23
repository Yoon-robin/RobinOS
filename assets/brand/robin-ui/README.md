# robin-ui — 다른 프로젝트에서 쓰는 UI 키트 (V5)

yoonrobin.xyz의 화면 규칙([docs/brand.md](../docs/brand.md) "V5: Recurrence")을 파일 몇 개로 묶은 거예요. 이 폴더만 복사하면 다른 프로젝트에서 같은 모습을 쓸 수 있어요. 빌드도 스크립트도 필요 없어요.

견본은 [index.html](index.html)을 브라우저로 열면 돼요. 부품이 전부 한 번씩 나오고, 오른쪽 위 단추로 밝게·어둡게 바꿔 볼 수 있어요.

## 파일

| 파일 | 무엇 |
| --- | --- |
| `robin-ui.css` | **본체.** 토큰(`--rk-*`)과 부품(`.rk-*`), 어둡게(기본)·밝게. 값은 여기에만 적어요 |
| `icons.svg` | 선 아이콘 31개(24 칸, 선 1.8, 둥근 끝) |
| `tokens.json` | 같은 값을 JSON으로(CSS가 아닌 곳: 앱, 메일 서식, 그림 만드는 스크립트) |
| `tailwind.css` | Tailwind v4용 `@theme`(`bg-rk-card`, `text-rk-soft`, `rounded-rk-control` …) |
| `tokens.py` | `robin-ui.css`에서 `tokens.json`·`tailwind.css`를 다시 뽑고 견본에 아이콘을 넣어요 |
| `index.html` | 견본 쪽 |
| `AGENTS.md` | 이 키트를 쓰는 프로젝트에서 Claude 같은 에이전트가 지킬 규칙. 그 프로젝트의 `CLAUDE.md`·`AGENTS.md`에 붙여 넣어요 |

## 가져다 쓰기

**1. 그냥 CSS로** — 폴더를 복사하고 두 줄을 넣어요.

```html
<link rel="stylesheet" href="brand-kit/robin-ui.css">
<body class="rk">
```

`class="rk"`가 바탕·글자·스크롤바·초점 테를 잡아요. 밝은 테마는 `<html data-theme="light">`(또는 아무 감싸는 요소)예요. 시스템 설정을 따르게 하려면 한 줄이면 돼요.

```html
<script>document.documentElement.dataset.theme = matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';</script>
```

**2. Tailwind v4에서**

```css
@import "tailwindcss";
@import "./brand-kit/robin-ui.css";
@import "./brand-kit/tailwind.css";
```

부품 클래스(`rk-btn`)도 쓰고, 유틸리티(`bg-rk-card border-rk-line rounded-rk-card`)도 쓸 수 있어요.

**3. 값만** — `tokens.json`을 읽거나, 이미 있는 프로젝트의 색 변수를 이 값으로 바꿔요(itcsconnect는 이렇게 옮겼어요).

글꼴은 **Pretendard**예요. 프로젝트가 직접 싣거나 CDN에서 받아요(견본은 CDN). 없으면 시스템 글꼴로 떨어져요.

## 두 가지 문법

화면의 모든 것은 둘 중 하나예요.

| | 메뉴 | 표시기 |
| --- | --- | --- |
| 무엇 | 면 위에 놓인 것: 창, 옆 기둥, 카드, 줄, 컨트롤 | 떠 있는 것: 상태 칩, 토스트, 알림, 머리줄 알약 |
| 면 | 푸른 검정 셋: 기둥 `#0a0e11` < 판 `#0e1012` < 카드 `#0f1115`, 1px 선으로 나눔 | 짙은 면 `#08090b` + 1px 선 + 둘레 그림자 |
| 모서리 | 컨트롤 7, 칩 6, 카드 12, 창 14 | 알약(칩·사람·워터마크), 토스트 10, 알림 14 |
| 색 | 파랑 하나(`#4b7dfe`): 켜짐·고름·링크 | 왼쪽의 짧은 막대가 뜻: 보통·파랑·살구색·빨강 |

유리·흐림은 없어요(대화창 뒤를 어둡게 하는 한 곳만). **초록과 노랑은 쓰지 않아요.**

## 뼈대

```html
<div class="rk-window rk-window--page">
  <aside class="rk-side">
    <div class="rk-brand"><span class="rk-mark">R</span><span><b>앱 이름</b><small>아랫줄</small></span></div>
    <p class="rk-label">묶음</p>
    <a class="rk-nav" href="/" aria-current="page"><svg class="rk-ico"><use href="#rk-i-home"/></svg>지금 쪽</a>
    <a class="rk-nav" href="/other"><svg class="rk-ico"><use href="#rk-i-sliders"/></svg>다른 쪽</a>
    <a class="rk-account" href="/me"><span class="rk-avatar">R</span><span><b>이름</b><small>아랫줄</small></span></a>
  </aside>
  <main class="rk-main">
    <div class="rk-bar"><h1>쪽 이름</h1><span class="rk-gap"></span><button class="rk-btn rk-btn--primary">주 동작</button></div>
    <div class="rk-body">
      <p class="rk-label">묶음</p>
      <div class="rk-card">
        <div class="rk-row"><span>줄</span><button class="rk-switch" role="switch" aria-checked="true" aria-label="줄"></button></div>
        <a class="rk-row" href="/in"><span>안으로 들어가는 줄</span><svg class="rk-ico"><use href="#rk-i-right"/></svg></a>
      </div>
    </div>
  </main>
</div>
```

옆 기둥이 없는 쪽은 `rk-header`(로고 알약, `rk-pilltabs`, 오른쪽 알약들) 아래에 카드를 놓아요.

## 부품

### 메뉴

| 클래스 | 무엇 |
| --- | --- |
| `rk-window` (`--page`: 화면 전체) · `rk-side` · `rk-main` | 창, 붙은 옆 기둥(폭은 `--rk-side-w`, 기본 178), 판 |
| `rk-brand` + `rk-mark` | 표 30(흰 글자 + 파란 번짐), 이름 16, 아랫줄 9.5 |
| `rk-label` | 묶음 이름표: 작고 흐리게, 카드 **밖** |
| `rk-nav` | 옆 줄 33. 지금 것은 `aria-current="page"` → 회색 면 + 파란 아이콘 |
| `rk-account` + `rk-avatar` | 기둥 맨 아래의 계정 |
| `rk-bar` · `rk-pick` · `rk-gap` | 위 막대 60, 고르기(30, 선만), 남는 폭 |
| `rk-body` (`--2`: 두 열) | 카드가 놓이는 곳 |
| `rk-card` (`--pad`) · `rk-row` · `rk-more` | 카드, 줄 41(줄 사이 선은 9 들여서), 줄 끝의 `···` |
| `rk-tile` | 숫자 타일: 이름표 → 값 28 → 아랫글 |
| `rk-btn` (`--primary` `--danger` `--danger-fill` `--small` `--icon` `--bare`) | 단추. **파란 채움은 한 화면에 하나**, 지우기는 빨간 테 + 빨간 글자, 채운 빨강은 확인 대화창의 한 단추뿐 |
| `rk-field` · `rk-input` · `rk-select` (`--row`) · `rk-textarea` | 입력. 자리표시가 할 일을 말해요 |
| `rk-switch` | `<button role="switch" aria-checked>` 34×19. 꺼지면 어두운 홈 + 1px 선 |
| `rk-check` | 체크 16 |
| `rk-slider` · `rk-value` · `rk-meter` | 막대(두께 3, 흰 손잡이 11; `--rk-at`에 값의 비율), 값 칸, 눈금 |
| `rk-tabs` + `rk-tab` | 고르는 묶음. 고른 것은 회색 면 + 흰 글자(`aria-selected="true"`) |
| `rk-tag` · `rk-kbd` · `rk-code` | 종류·개수 칩(상태가 아님), 키, 글 속 코드 |
| `rk-table` · `rk-empty` | 표, 빈 곳(아이콘 + 한 줄) |
| `rk-menu` + `rk-menu__item` (`--danger`) | 열리는 메뉴 |
| `rk-dialog` + `rk-dialog__foot` | `<dialog>` 대화창 |
| `rk-loading` · `rk-in` | 기다림 3px 줄, 들어올 때 4px |

### 표시기

`data-tone`으로 뜻을 정해요: 없음(보통) · `on`(켜짐·하는 중·끝남) · `note`(알림·주의) · `alarm`(실패·멈춤).

| 클래스 | 무엇 |
| --- | --- |
| `rk-chip` | 상태 칩 22. 낱말이 상태를 말하고 막대와 글자색이 되풀이해요 |
| `rk-toast` (+ `rk-toasts`: 화면 구석에 쌓는 자리) | 토스트 = 기록 줄 |
| `rk-alert` | 알림 = 경보 카드: `<b>`윗줄 + `<em>`아랫줄(색) |
| `rk-hud` (`--pill` `--bare` `--block`) | 떠 있는 면 아무 크기: 머리줄 알약, 쪽 안 안내 상자(`--block`) |
| `rk-watermark` + `rk-watermark__mark` + `rk-round` | 표 · 아이콘과 값 묶음 · 둥근 단추가 든 48 알약 |
| `rk-keys` | 단축키: 머리 + 값·이름 두 열 |
| `rk-person` | 사람 알약 25 |
| `rk-header` + `rk-pilltabs` | 옆 기둥 없는 쪽의 머리줄 |

## 아이콘

```html
<svg class="rk-ico"><use href="#rk-i-mail"/></svg>
```

`icons.svg`의 내용을 쪽에 한 번 넣거나(파일로 여는 쪽은 이렇게), http로 서비스하면 `href="brand-kit/icons.svg#rk-i-mail"`로 써요. 이름: home mail cloud lock chat spark download globe image film music pulse bars sliders terminal keys search user clock target alarm plus minus check close right down copy trash refresh out.

새 아이콘도 같은 식으로 그려요: 24 칸, 선 1.8, 둥근 끝, 채우지 않음.

## 지키는 것

1. **설명 문장을 쓰지 않아요.** 제목은 이름, 아랫줄은 사실(날짜·시각·숫자). 문장은 무언가 잘못됐거나, 켜고 끌 때 따라오는 결과이거나, 한 번 눌러야 보이는 곳에만.
2. **알약은 표시기에만.** 단추·입력 칸은 모서리 7.
3. **파란 채움은 한 화면에 하나**(그 화면의 주 동작).
4. **상태는 낱말로 말하고** 색은 되풀이만 해요. 초록·노랑 없음.
5. **묶음 이름표는 카드 밖**에, 작고 흐리게.
6. 굵기는 Pretendard 450 / 550 / 650. 가늘게 바꾸지 않아요.
7. 움직임은 짧게(150~240ms), `prefers-reduced-motion`에서 멈춰요.

## 값을 고칠 때

`robin-ui.css`만 고치고 `python brand-kit/tokens.py`를 돌려요. `tokens.json`·`tailwind.css`·견본의 아이콘이 따라와요. 규칙이 바뀌면 [docs/brand.md](../docs/brand.md)도 같이 고쳐요.

고친 화면이 키트에서 벗어났는지는 눈이 아니라 계산값으로 봐요. 이 저장소의 [ops/snap/v5scan.mjs](../ops/snap/v5scan.mjs)가 화면마다 흐림·초록·노랑·옛 파랑·큰 모서리를 세요. 견본은 `cd ops/snap && node snap.mjs kit.mjs`로 찍어요.

## 출처와 이름

- 모양과 값은 Figma Community의 **Neverlose CS2: Recurrence Design**(Jellyx Design, [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/))에서 쟀어요. 잰 기록은 [recurrence_6.md](../docs/design/neverlose-reference/research_notes/Neverlose%20UI%20디자인%20심층%20조사/recurrence_6.md)예요. 이 키트를 다른 곳에 공개하면 이 출처를 같이 적어요.
- 그 제품의 이름·로고·그림은 여기 없고, 쓰지도 않아요. 화면에 그 이름을 적지 않아요.
- 아이콘과 견본은 이 저장소에서 그린 거예요.
