import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import { system } from "./systemAPI";

// 배경화면 목록 (CSS background 문자열). 설정 앱에서 실시간으로 바꿀 수 있어요.
export type Wallpaper = { id: string; name: string; css: string };

export const WALLPAPERS: Wallpaper[] = [
  {
    id: "aurora",
    name: "오로라",
    css: "radial-gradient(circle at 18% 22%, rgba(129,140,248,0.55), transparent 42%), radial-gradient(circle at 82% 18%, rgba(244,114,182,0.45), transparent 42%), radial-gradient(circle at 50% 92%, rgba(45,212,191,0.4), transparent 48%), linear-gradient(135deg,#0b1026 0%,#2b1055 55%,#7e2a6e 100%)",
  },
  {
    id: "midnight",
    name: "미드나잇",
    css: "radial-gradient(circle at 80% 85%, rgba(99,102,241,0.4), transparent 45%), linear-gradient(160deg,#020617,#0b1026,#1e1b4b)",
  },
  {
    id: "sunset",
    name: "선셋",
    css: "radial-gradient(circle at 72% 22%, rgba(255,205,120,0.45), transparent 45%), linear-gradient(160deg,#2b1055,#7e2a6e,#ff7e5f)",
  },
  {
    id: "ocean",
    name: "오션",
    css: "linear-gradient(160deg,#1a2980,#26d0ce)",
  },
  {
    id: "sakura",
    name: "사쿠라",
    css: "radial-gradient(circle at 30% 20%, rgba(255,182,193,0.5), transparent 42%), linear-gradient(160deg,#42275a,#734b6d,#bc4e9c)",
  },
  {
    id: "graphite",
    name: "그래파이트",
    css: "linear-gradient(160deg,#1c1c1e,#2c2c2e,#3a3a3c)",
  },
];

// 강조 색 (선택 표시, 포커스 등에 쓰임)
export const ACCENTS: { id: string; name: string; color: string }[] = [
  { id: "purple", name: "퍼플", color: "#a855f7" },
  { id: "blue", name: "블루", color: "#3b82f6" },
  { id: "pink", name: "핑크", color: "#ec4899" },
  { id: "teal", name: "틸", color: "#14b8a6" },
  { id: "orange", name: "오렌지", color: "#f59e0b" },
  { id: "red", name: "레드", color: "#ef4444" },
];

type SystemState = {
  wallpaper: Wallpaper;
  wallpaperId: string;
  setWallpaperId: (id: string) => void;
  accent: string;
  setAccent: (c: string) => void;
  brightness: number;
  setBrightness: (n: number) => void;
  theme: "dark" | "light";
  setTheme: (t: "dark" | "light") => void;
};

const SystemCtx = createContext<SystemState | null>(null);
const LS_KEY = "robinos.settings.v1";

export function SystemProvider({ children }: { children: ReactNode }) {
  const [wallpaperId, setWallpaperId] = useState("aurora");
  const [accent, setAccent] = useState("#a855f7");
  const [brightness, setBrightness] = useState(1);
  const [theme, setTheme] = useState<"dark" | "light">("dark");

  // 최초 1회 저장된 설정 복원
  useEffect(() => {
    try {
      const raw = system.storage.get(LS_KEY);
      if (raw) {
        const s = JSON.parse(raw);
        if (s.wallpaperId) setWallpaperId(s.wallpaperId);
        if (s.accent) setAccent(s.accent);
        if (typeof s.brightness === "number") setBrightness(s.brightness);
        if (s.theme === "light" || s.theme === "dark") setTheme(s.theme);
      }
    } catch {
      /* 무시 */
    }
  }, []);

  // 변경 시 저장
  useEffect(() => {
    try {
      system.storage.set(LS_KEY, JSON.stringify({ wallpaperId, accent, brightness, theme }));
    } catch {
      /* 무시 */
    }
  }, [wallpaperId, accent, brightness, theme]);

  const wallpaper = WALLPAPERS.find((w) => w.id === wallpaperId) ?? WALLPAPERS[0];

  return (
    <SystemCtx.Provider
      value={{ wallpaper, wallpaperId, setWallpaperId, accent, setAccent, brightness, setBrightness, theme, setTheme }}
    >
      {children}
    </SystemCtx.Provider>
  );
}

export function useSystem() {
  const ctx = useContext(SystemCtx);
  if (!ctx) throw new Error("useSystem must be used within SystemProvider");
  return ctx;
}
