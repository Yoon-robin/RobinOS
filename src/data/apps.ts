import type { AppDef } from "../system/types";
import Finder from "../apps/Finder";
import Notes from "../apps/Notes";
import Calculator from "../apps/Calculator";
import Paint from "../apps/Paint";
import Terminal from "../apps/Terminal";
import Settings from "../apps/Settings";
import About from "../apps/About";

export type { AppDef };

// 독·런치패드에 들어가는 앱들. 새 앱을 만들면 여기에 한 줄 추가하면 돼요.
export const APPS: AppDef[] = [
  {
    id: "finder",
    name: "Finder",
    icon: "🗂️",
    color: "linear-gradient(135deg,#3b82f6,#60a5fa)",
    component: Finder,
    size: { w: 660, h: 430 },
    robinTool: { action: "finderNewFolder", desc: "새 폴더 만들기", arg: "폴더 이름" },
  },
  {
    id: "notes",
    name: "메모",
    icon: "📝",
    color: "linear-gradient(135deg,#f59e0b,#fde047)",
    component: Notes,
    size: { w: 420, h: 480 },
    robinTool: { action: "notesWrite", desc: "메모에 글 쓰기", arg: "쓸 내용" },
  },
  {
    id: "calc",
    name: "계산기",
    icon: "🧮",
    color: "linear-gradient(135deg,#52525b,#a1a1aa)",
    component: Calculator,
    size: { w: 280, h: 432 },
    robinTool: { action: "calculate", desc: "수식을 계산해 결과를 계산기에 표시", arg: "수식 (예: 12*(3+4))" },
  },
  {
    id: "paint",
    name: "그림판",
    icon: "🎨",
    color: "linear-gradient(135deg,#ec4899,#f59e0b)",
    component: Paint,
    size: { w: 600, h: 480 },
  },
  {
    id: "terminal",
    name: "터미널",
    icon: "⌨️",
    color: "linear-gradient(135deg,#1f2937,#374151)",
    component: Terminal,
    size: { w: 580, h: 380 },
  },
  {
    id: "settings",
    name: "설정",
    icon: "⚙️",
    color: "linear-gradient(135deg,#64748b,#94a3b8)",
    component: Settings,
    size: { w: 560, h: 480 },
  },
  {
    id: "about",
    name: "RobinOS 정보",
    icon: "/brand/logo-mark.svg",
    color: "linear-gradient(135deg,#14b8a6,#5eead4)",
    component: About,
    size: { w: 380, h: 450 },
  },
];
