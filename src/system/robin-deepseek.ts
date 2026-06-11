// ===========================================================
// Robin 두뇌 — DeepSeek API (OpenAI 호환). 지금은 "대기" 상태.
//
// 연결법:
//   1) localStorage.setItem("robinos.deepseek.key", "sk-...")
//   2) main.tsx 등에서:
//        import { setRobinBrain } from "./system/robin";
//        import { deepseekBrain } from "./system/robin-deepseek";
//        setRobinBrain(deepseekBrain);
//
// 보안: 위험 동작(resetSettings 등)은 여기서도 즉시 실행하지 않고
//       RobinResult.confirm 으로 돌려줘 사용자 확인을 받아요 (가드레일 동일).
// ⚠️ 브라우저 직접 호출은 CORS로 막힐 수 있음 — 네이티브 빌드/프록시에선 OK.
// ===========================================================

import { system } from "./systemAPI";
import { APPS } from "../data/apps";
import type { RobinBrain, RobinActions, RobinResult } from "./robin";

// 시스템 프롬프트를 앱 목록(APPS)에서 자동 생성 →
// 새 앱이나 robinTool 을 추가하면 Robin(DeepSeek)이 즉시 인지해요. (하드코딩 X)
function buildSystemPrompt(): string {
  const appIds = APPS.map((a) => a.id).join("|");
  const appTools = APPS.filter((a) => a.robinTool)
    .map((a) => `- ${a.robinTool!.action} : arg = ${a.robinTool!.arg} — ${a.robinTool!.desc} (${a.name})`)
    .join("\n");
  return `너는 Robin, RobinOS를 직접 제어하는 개인 에이전트야. 친근하고 유능하게, 한국어로 짧게 답해.
너는 아래 모든 앱을 열고 조작할 수 있어. "저는 ~할 수 없습니다", "그 앱이 어디 있나요" 같은 말은 절대 하지 마 — 도구(action)로 직접 해내.
OS 동작이 필요하면 반드시 JSON "한 줄"로만 답해:
{"action":"calculate","arg":"1234*567+89","reply":"1234×567+89 = 699767 이에요 🧮"}
동작이 필요 없으면: {"action":null,"reply":"<답변>"}

설치된 앱 (openApp 으로 열기): ${appIds}

앱별 도구:
${appTools}

시스템 도구:
- setTheme : arg = "dark" | "light"
- setWallpaper : arg = aurora|midnight|sunset|ocean|sakura|graphite
- openApp : arg = 위 앱 id 중 하나
- lock
- resetSettings  (위험! 시스템이 사용자에게 확인을 받음)`;
}

// 지연 계산: 모듈 로드 시점이 아니라 첫 호출 때 생성 (순환 import로 인한 크래시 방지)
let _systemPrompt: string | null = null;
const getSystemPrompt = () => (_systemPrompt ??= buildSystemPrompt());

// 위험 동작은 확인 필요
const DANGEROUS = new Set(["resetSettings"]);

function applyAction(action: string, arg: string | undefined, a: RobinActions) {
  if (action === "setTheme" && (arg === "dark" || arg === "light")) a.setTheme(arg);
  else if (action === "setWallpaper" && arg) a.setWallpaper(arg);
  else if (action === "openApp" && arg) a.openApp(arg);
  else if (action === "lock") a.lock();
  else if (action === "calculate" && arg) a.calculate(arg);
  else if (action === "notesWrite" && arg) a.notesWrite(arg);
  else if (action === "finderNewFolder" && arg) a.finderNewFolder(arg);
  else if (action === "resetSettings") a.resetSettings();
}

export const deepseekBrain: RobinBrain = async (msg, actions): Promise<RobinResult> => {
  const key = system.storage.get("robinos.deepseek.key");
  if (!key) return { reply: "DeepSeek API 키가 아직 없어요. 키를 설정하면 제가 훨씬 똑똑해져요!" };

  try {
    const res = await fetch("https://api.deepseek.com/chat/completions", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
      body: JSON.stringify({
        model: "deepseek-chat",
        temperature: 0.6,
        messages: [
          { role: "system", content: getSystemPrompt() },
          { role: "user", content: msg },
        ],
      }),
    });
    const data = await res.json();
    const content: string = data?.choices?.[0]?.message?.content ?? "";

    const match = content.match(/\{[\s\S]*\}/);
    if (match) {
      try {
        const obj = JSON.parse(match[0]);
        const reply: string = obj.reply ?? "네!";
        if (obj.action && DANGEROUS.has(obj.action)) {
          // 위험 동작 → 즉시 실행하지 않고 확인 요청
          return {
            reply,
            confirm: { text: "실행", run: () => applyAction(obj.action, obj.arg, actions) },
          };
        }
        if (obj.action) applyAction(obj.action, obj.arg, actions);
        return { reply };
      } catch {
        /* JSON 깨지면 본문 반환 */
      }
    }
    return { reply: content || "음, 잘 모르겠어요." };
  } catch {
    return { reply: "DeepSeek 연결에 문제가 생겼어요. 키·네트워크(또는 CORS)를 확인해주세요." };
  }
};
