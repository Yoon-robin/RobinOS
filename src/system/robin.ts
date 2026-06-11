// ===========================================================
// Robin — RobinOS의 개인 에이전트 (자비스 컨셉)
//
// 보안(가드레일):
//  1) 능력 allowlist — Robin은 RobinActions 에 정의된 동작만 가능 (임의 코드 X)
//  2) 위험도 등급 — 안전한 동작은 자동 실행, 위험·되돌릴 수 없는 동작은
//     RobinResult.confirm 으로 "허용?" 확인을 받은 뒤에만 실행
//
// 두뇌(brain)는 교체 가능: 지금은 localBrain(파서), 나중엔 deepseekBrain.
// UI 는 runRobin(msg, actions) → Promise<RobinResult> 하나만 호출.
// ===========================================================

export type RobinActions = {
  // --- 안전 (자동 실행) ---
  openApp: (id: string) => boolean;
  setTheme: (t: "dark" | "light") => void;
  currentTheme: () => "dark" | "light";
  setWallpaper: (id: string) => boolean;
  lock: () => void;
  appList: () => { id: string; name: string }[];
  wallpaperList: () => { id: string; name: string }[];
  // --- 앱 활용 (각 앱의 robinTool 과 연결) ---
  calculate: (expr: string) => { ok: boolean; result?: string; error?: string };
  notesWrite: (text: string) => void;
  finderNewFolder: (name: string) => void;
  // --- 위험 (확인 필요) ---
  resetSettings: () => void; // 모든 설정 초기화 — 되돌릴 수 없음
};

// 위험 동작은 즉시 실행하지 않고 confirm 을 돌려줌 → UI 가 사용자 승인 받음
export type RobinResult = {
  reply: string;
  confirm?: { text: string; run: () => void };
};

export type RobinBrain = (msg: string, actions: RobinActions) => Promise<RobinResult>;

// 메시지에서 수식만 추출 (예: "계산기에서 12*(3+4) 계산해줘" → "12*(3+4)")
function extractExpr(s: string): string | null {
  const norm = s.replace(/×/g, "*").replace(/÷/g, "/").replace(/＋/g, "+").replace(/－/g, "-");
  const m = norm.match(/[0-9.(][0-9.+\-*/()\s]*[0-9.)]/);
  return m ? m[0].trim() : null;
}

// ---------- 기본 두뇌: 오프라인 의도 파서 ----------
function parse(raw: string, a: RobinActions): RobinResult {
  const low = raw.trim().toLowerCase();
  const r = (reply: string): RobinResult => ({ reply });

  if (/^(안녕|하이|hi|hello|ㅎㅇ)/.test(low))
    return r("안녕하세요! 저는 Robin이에요 🐦 RobinOS를 도와드릴게요. \"뭐 할 수 있어?\"라고 물어보세요.");
  if (/누구|정체|넌 ?뭐|who are you|너는/.test(low))
    return r("저는 Robin — RobinOS의 개인 에이전트예요. 앱 열기, 테마·배경 바꾸기, 화면 잠그기를 해드려요.\n위험한 동작(초기화 등)은 항상 먼저 여쭤봐요. 🔒");
  if (/뭐.*할|할 수|도와|도움|help|기능|명령|할수/.test(low))
    return r("이런 걸 할 수 있어요:\n• \"다크/라이트 모드\" 전환\n• \"배경 오션으로\" 바꾸기\n• \"메모 열어\" 앱 실행\n• \"화면 잠가\"\n• \"설정 초기화\" (확인 후)\n편하게 말해보세요 🙂");
  if (/고마워|고맙|thanks|thank/.test(low)) return r("천만에요! 언제든 불러주세요 🐦");
  if (/몇 ?시|지금.*시간|what time|시간 알려/.test(low))
    return r(`지금 ${new Date().toLocaleTimeString("ko-KR", { hour: "2-digit", minute: "2-digit" })}이에요 ⏰`);

  // 계산 — 계산기 앱으로 실제 계산 (Robin은 "못 한다"고 하지 않아요)
  if (/계산|수식|얼마|몇이|equals|=/.test(low) || /\d\s*[-+*/×÷]\s*\d/.test(raw)) {
    const expr = extractExpr(raw);
    if (expr) {
      const res = a.calculate(expr);
      if (res.ok) return r(`${expr} = ${res.result} 예요. 계산기에도 띄웠어요 🧮`);
      return r("그 식은 계산을 못 했어요 😅 숫자와 + − × ÷ ( ) 로 다시 알려줄래요?");
    }
    if (/계산/.test(low)) return r("어떤 식을 계산할까요? 예: 1234 × 567 + 89");
  }

  // 메모에 쓰기
  if (/메모.*(써|적어|작성|기록)|메모해/.test(low)) {
    const text = raw
      .replace(/^.*?메모(?:장|에다|에)?\s*/, "")
      .replace(/\s*(을|를)?\s*(써줘|써|적어줘|적어|작성해줘|작성|기록해줘|기록|메모해줘|메모해).*$/, "")
      .trim();
    if (text) {
      a.notesWrite(text);
      return r(`메모에 "${text}" 적었어요 📝`);
    }
    return r("메모에 뭐라고 쓸까요?");
  }

  // 새 폴더 만들기
  if (/폴더.*(만들|생성|추가)|새 ?폴더/.test(low)) {
    const name =
      raw
        .replace(/^.*?(?:새 ?폴더|폴더)\s*/, "")
        .replace(/\s*(을|를)?\s*(만들어줘|만들어|만들|생성해줘|생성|추가해줘|추가).*$/, "")
        .trim() || "새 폴더";
    a.finderNewFolder(name);
    return r(`'${name}' 폴더를 만들었어요 📁`);
  }

  // 위험 동작 — 즉시 실행 X, 확인 요청
  if (/초기화|리셋|reset|공장|날려|다 지워/.test(low)) {
    return {
      reply: "⚠️ 모든 설정(배경·테마·밝기)을 초기화할까요? 되돌릴 수 없어요.",
      confirm: { text: "설정 초기화", run: () => a.resetSettings() },
    };
  }

  // 안전 동작 — 자동 실행
  if (/다크|어둡게|어둡|dark/.test(low)) {
    a.setTheme("dark");
    return r("다크 모드로 바꿨어요 🌙");
  }
  if (/라이트|밝게|밝은|light/.test(low)) {
    a.setTheme("light");
    return r("라이트 모드로 바꿨어요 ☀️");
  }
  if (/테마|모드/.test(low) && /바꿔|토글|전환|바꾸/.test(low)) {
    const t = a.currentTheme() === "dark" ? "light" : "dark";
    a.setTheme(t);
    return r(`${t === "dark" ? "다크 🌙" : "라이트 ☀️"} 모드로 전환했어요.`);
  }

  const wp = a.wallpaperList().find((w) => low.includes(w.name.toLowerCase()) || low.includes(w.id));
  if (/배경|월페이퍼|바탕화면|wallpaper/.test(low)) {
    if (wp) {
      a.setWallpaper(wp.id);
      return r(`배경을 '${wp.name}'(으)로 바꿨어요 🖼️`);
    }
    return r(`어떤 배경으로 바꿀까요? — ${a.wallpaperList().map((w) => w.name).join(", ")} 중에 골라주세요.`);
  }
  if (wp && /바꿔|바꾸|으로|로 ?해|적용/.test(low)) {
    a.setWallpaper(wp.id);
    return r(`배경을 '${wp.name}'(으)로 바꿨어요 🖼️`);
  }

  if (/잠가|잠궈|잠금|잠그|lock/.test(low)) {
    a.lock();
    return r("화면을 잠갔어요 🔒");
  }

  const app = a.appList().find((ap) => low.includes(ap.name.toLowerCase()) || low.includes(ap.id));
  if (app) {
    a.openApp(app.id);
    return r(`'${app.name}' 열었어요.`);
  }

  return r('음, 아직 그건 못 배웠어요 😅 "뭐 할 수 있어?"로 확인해보세요.\n(나중에 DeepSeek 두뇌가 연결되면 다 알아들을 거예요!)');
}

export const localBrain: RobinBrain = async (msg, actions) => parse(msg, actions);

// ---------- 교체 가능한 두뇌 ----------
let brain: RobinBrain = localBrain;
export function setRobinBrain(b: RobinBrain) {
  brain = b;
}
export function runRobin(msg: string, actions: RobinActions): Promise<RobinResult> {
  return brain(msg, actions);
}
