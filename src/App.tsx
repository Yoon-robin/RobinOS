import { useCallback, useEffect, useRef, useState, type CSSProperties } from "react";
import { AnimatePresence } from "motion/react";
import { SystemProvider, useSystem, WALLPAPERS } from "./system/SystemContext";
import { registerNotifySink, system } from "./system/systemAPI";
import BootScreen from "./components/BootScreen";
import MenuBar from "./components/MenuBar";
import Dock from "./components/Dock";
import Window from "./components/Window";
import Launchpad from "./components/Launchpad";
import ContextMenu, { type CtxItem } from "./components/ContextMenu";
import LockScreen from "./components/LockScreen";
import Spotlight from "./components/Spotlight";
import ControlCenter from "./components/ControlCenter";
import { Toasts, NotifPanel, type Notif } from "./components/Notifications";
import MissionControl from "./components/MissionControl";
import DesktopWidget from "./components/DesktopWidget";
import Robin from "./components/Robin";
import { runRobin } from "./system/robin";
import { APPS, type AppDef } from "./data/apps";

// 열린 창 하나의 상태.
type Win = {
  key: number;
  app: AppDef;
  x: number;
  y: number;
  w: number;
  h: number;
  z: number;
  minimized: boolean;
  maximized: boolean;
  prev?: { x: number; y: number; w: number; h: number };
};

export default function App() {
  // 시스템 설정(배경화면·강조색)을 앱 전체에 공급.
  return (
    <SystemProvider>
      <Shell />
    </SystemProvider>
  );
}

function Shell() {
  const { wallpaper, accent, brightness, theme, setTheme, setWallpaperId, setAccent, setBrightness } =
    useSystem();
  const [booted, setBooted] = useState(false);
  const [wins, setWins] = useState<Win[]>([]);
  const [focusKey, setFocusKey] = useState<number | null>(null);
  const [launchpad, setLaunchpad] = useState(false);
  const [spotlight, setSpotlight] = useState(false);
  const [cc, setCc] = useState(false);
  const [notifs, setNotifs] = useState<Notif[]>([]);
  const [toastIds, setToastIds] = useState<number[]>([]);
  const [notifPanel, setNotifPanel] = useState(false);
  const [mc, setMc] = useState(false);
  const notifIdRef = useRef(0);
  const [locked, setLocked] = useState(true); // 부팅 후 잠금 화면부터 시작
  const [ctx, setCtx] = useState<{ x: number; y: number; items: CtxItem[] } | null>(null);
  const keyRef = useRef(0);
  const zRef = useRef(10); // 다음 창에 줄 z-index (ref라 렌더와 무관하게 증가)

  useEffect(() => {
    const t = setTimeout(() => setBooted(true), 2600);
    return () => clearTimeout(t);
  }, []);

  // 키보드: Esc(닫기), ⌘/Ctrl+Space(Spotlight)
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setLaunchpad(false);
        setCtx(null);
        setSpotlight(false);
        setMc(false);
        return;
      }
      if (locked) return;
      if ((e.metaKey || e.ctrlKey) && e.code === "Space") {
        e.preventDefault();
        setSpotlight((s) => !s);
      }
      if (e.key === "F3") {
        e.preventDefault();
        setMc((v) => !v);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [locked]);

  // 알림 띄우기: 토스트로 잠깐 보여주고, 패널 목록엔 계속 쌓아둠.
  const notify = useCallback((title: string, body: string, icon = "🔔") => {
    const id = ++notifIdRef.current;
    const time = new Date().toLocaleTimeString("ko-KR", { hour: "2-digit", minute: "2-digit" });
    setNotifs((n) => [{ id, title, body, icon, time }, ...n].slice(0, 30));
    setToastIds((t) => [...t, id]);
    setTimeout(() => setToastIds((t) => t.filter((x) => x !== id)), 4500);
  }, []);

  // 알림 표시 함수를 systemAPI 에 등록 → 어떤 앱이든 system.notify() 로 알림 가능
  useEffect(() => registerNotifySink(notify), [notify]);

  // 데모 알림 (프리뷰에서 알림 센터를 바로 볼 수 있게)
  useEffect(() => {
    const t1 = setTimeout(
      () => notify("RobinOS 업데이트", "알림 센터가 추가됐어요. 메뉴바 시계를 눌러 확인하세요.", "🎉"),
      1500
    );
    const t2 = setTimeout(
      () => notify("팁", "창을 화면 왼쪽·오른쪽 끝으로 끌면 반쪽으로 정렬돼요.", "💡"),
      3800
    );
    return () => {
      clearTimeout(t1);
      clearTimeout(t2);
    };
  }, [notify]);

  const focusWin = (key: number) => {
    const nz = ++zRef.current;
    setWins((ws) => ws.map((w) => (w.key === key ? { ...w, z: nz, minimized: false } : w)));
    setFocusKey(key);
  };

  // 독/런치패드에서 앱 실행: 이미 열려 있으면 맨 앞으로, 아니면 새 창.
  const openApp = (app: AppDef) => {
    const existing = wins.filter((w) => w.app.id === app.id);
    if (existing.length) {
      const top = existing.reduce((a, b) => (a.z > b.z ? a : b));
      focusWin(top.key);
      return;
    }
    const key = ++keyRef.current;
    const nz = ++zRef.current;
    const size = app.size ?? { w: 480, h: 340 };
    const count = wins.length;
    const x = Math.max(20, Math.min(140 + count * 28, window.innerWidth - size.w - 40));
    const y = Math.max(40, Math.min(70 + count * 28, window.innerHeight - size.h - 120));
    setWins((ws) => [
      ...ws,
      { key, app, x, y, w: size.w, h: size.h, z: nz, minimized: false, maximized: false },
    ]);
    setFocusKey(key);
  };

  const closeWin = (key: number) => setWins((ws) => ws.filter((w) => w.key !== key));
  const closeApp = (id: string) => setWins((ws) => ws.filter((w) => w.app.id !== id));
  const minimizeWin = (key: number) => {
    setWins((ws) => ws.map((w) => (w.key === key ? { ...w, minimized: true } : w)));
    setFocusKey((fk) => (fk === key ? null : fk));
  };
  const moveWin = (key: number, x: number, y: number) =>
    setWins((ws) => ws.map((w) => (w.key === key ? { ...w, x, y } : w)));
  const resizeWin = (key: number, w: number, h: number) =>
    setWins((ws) => ws.map((win) => (win.key === key ? { ...win, w, h } : win)));
  const toggleMax = (key: number) =>
    setWins((ws) =>
      ws.map((w) => {
        if (w.key !== key) return w;
        if (w.maximized) {
          const p = w.prev ?? { x: w.x, y: w.y, w: w.w, h: w.h };
          return { ...w, ...p, maximized: false, prev: undefined };
        }
        return {
          ...w,
          prev: { x: w.x, y: w.y, w: w.w, h: w.h },
          x: 6,
          y: 34,
          w: window.innerWidth - 12,
          h: window.innerHeight - 34 - 96,
          maximized: true,
        };
      })
    );

  // 창을 화면 가장자리로 끌면 반쪽/최대화로 스냅.
  const snapWin = (key: number, zone: "left" | "right" | "max") =>
    setWins((ws) =>
      ws.map((w) => {
        if (w.key !== key) return w;
        const y = 34;
        const h = window.innerHeight - 34 - 96;
        if (zone === "max") {
          return {
            ...w,
            prev: w.prev ?? { x: w.x, y: w.y, w: w.w, h: w.h },
            x: 6,
            y,
            w: window.innerWidth - 12,
            h,
            maximized: true,
          };
        }
        const halfW = Math.floor(window.innerWidth / 2) - 9;
        const x = zone === "left" ? 6 : Math.ceil(window.innerWidth / 2) + 3;
        return { ...w, x, y, w: halfW, h, maximized: false };
      })
    );

  const activeApp = wins.find((w) => w.key === focusKey && !w.minimized)?.app.name ?? "RobinOS";
  const openAppIds = [...new Set(wins.map((w) => w.app.id))];
  const toastItems = toastIds
    .map((id) => notifs.find((n) => n.id === id))
    .filter((n): n is Notif => Boolean(n));

  const desktopMenu: CtxItem[] = [
    { label: "배경화면 바꾸기", onClick: () => openApp(APPS.find((a) => a.id === "settings")!) },
    { label: "런치패드 열기", onClick: () => setLaunchpad(true) },
    { label: "미션 컨트롤", onClick: () => setMc(true) },
    { label: "RobinOS 정보", onClick: () => openApp(APPS.find((a) => a.id === "about")!) },
  ];

  // 메뉴바 로고(🐦→R) 클릭 시 나오는 RobinOS 메뉴
  const robinMenu: CtxItem[] = [
    { label: "이 RobinOS에 관하여", onClick: () => openApp(APPS.find((a) => a.id === "about")!) },
    { label: "배경화면 바꾸기", onClick: () => openApp(APPS.find((a) => a.id === "settings")!) },
    { label: "화면 잠금", onClick: () => setLocked(true) },
  ];

  // 독 아이콘 우클릭 메뉴
  const appMenu = (app: AppDef): CtxItem[] => [
    { label: "열기", onClick: () => openApp(app) },
    ...(openAppIds.includes(app.id)
      ? [{ label: "모두 닫기", onClick: () => closeApp(app.id) }]
      : []),
  ];

  // Robin의 계산 능력 — 계산기 앱을 실제로 활용. 수학 문자만 남겨 안전하게 평가.
  const calculate = (expr: string) => {
    const clean = expr
      .replace(/×/g, "*")
      .replace(/÷/g, "/")
      .replace(/[^0-9+\-*/().\s]/g, "")
      .trim();
    if (!/[0-9]/.test(clean)) return { ok: false, error: "식 없음" };
    try {
      const result = Function('"use strict"; return (' + clean + ")")();
      if (typeof result !== "number" || !Number.isFinite(result))
        return { ok: false, error: "계산 불가" };
      const rounded = String(Math.round(result * 1e10) / 1e10);
      const calcApp = APPS.find((x) => x.id === "calc");
      if (calcApp) openApp(calcApp);
      // 계산기가 마운트된 뒤 결과를 표시 (이미 열려 있으면 바로 반영)
      setTimeout(
        () => window.dispatchEvent(new CustomEvent("robin:calc", { detail: { result: rounded } })),
        90
      );
      return { ok: true, result: rounded };
    } catch {
      return { ok: false, error: "계산 오류" };
    }
  };

  // Robin 에이전트의 "손" — 메시지를 받아 실제 OS 동작을 실행하고 답을 돌려줌
  const askRobin = (msg: string) =>
    runRobin(msg, {
      openApp: (id) => {
        const app = APPS.find((x) => x.id === id);
        if (app) {
          openApp(app);
          return true;
        }
        return false;
      },
      setTheme,
      currentTheme: () => theme,
      setWallpaper: (id) => {
        if (WALLPAPERS.some((w) => w.id === id)) {
          setWallpaperId(id);
          return true;
        }
        return false;
      },
      lock: () => setLocked(true),
      appList: () => APPS.map((x) => ({ id: x.id, name: x.name })),
      wallpaperList: () => WALLPAPERS.map((w) => ({ id: w.id, name: w.name })),
      resetSettings: () => {
        setTheme("dark");
        setWallpaperId("aurora");
        setAccent("#a855f7");
        setBrightness(1);
      },
      calculate,
      notesWrite: (text: string) => {
        system.fs.writeFile("/문서/메모.txt", text);
        window.dispatchEvent(new CustomEvent("robin:notes", { detail: { text } }));
        const a = APPS.find((x) => x.id === "notes");
        if (a) openApp(a);
      },
      finderNewFolder: (name: string) => {
        system.fs.mkdir("/" + name);
        const a = APPS.find((x) => x.id === "finder");
        if (a) openApp(a);
      },
    });

  const style: CSSProperties = { background: wallpaper.css };
  (style as Record<string, string>)["--accent"] = accent;

  return (
    <div
      className={"desktop" + (theme === "light" ? " light" : "")}
      style={style}
      onContextMenu={(e) => {
        if (e.target === e.currentTarget) {
          e.preventDefault();
          setCtx({ x: e.clientX, y: e.clientY, items: desktopMenu });
        }
      }}
    >
      <MenuBar
        activeApp={activeApp}
        onSearch={() => setSpotlight(true)}
        onControlCenter={() => setCc(true)}
        onClock={() => setNotifPanel((v) => !v)}
        onLogo={() => setCtx({ x: 6, y: 28, items: robinMenu })}
      />

      <DesktopWidget />

      <AnimatePresence>
        {wins.map((w) => (
          <Window
            key={w.key}
            app={w.app}
            x={w.x}
            y={w.y}
            w={w.w}
            h={w.h}
            z={w.z}
            active={w.key === focusKey && !w.minimized}
            minimized={w.minimized}
            maximized={w.maximized}
            onFocus={() => focusWin(w.key)}
            onClose={() => closeWin(w.key)}
            onMinimize={() => minimizeWin(w.key)}
            onToggleMax={() => toggleMax(w.key)}
            onMove={(x, y) => moveWin(w.key, x, y)}
            onResize={(ww, hh) => resizeWin(w.key, ww, hh)}
            onSnap={(zone) => snapWin(w.key, zone)}
          />
        ))}
      </AnimatePresence>

      <Dock
        openApps={openAppIds}
        onOpen={openApp}
        onLaunchpad={() => setLaunchpad(true)}
        onAppContext={(app, x, y) => setCtx({ x, y, items: appMenu(app) })}
      />

      <Robin ask={askRobin} />

      <AnimatePresence>
        {launchpad && <Launchpad onOpen={openApp} onClose={() => setLaunchpad(false)} />}
      </AnimatePresence>

      {ctx && (
        <ContextMenu x={ctx.x} y={ctx.y} items={ctx.items} onClose={() => setCtx(null)} />
      )}

      <AnimatePresence>
        {spotlight && <Spotlight onOpen={openApp} onClose={() => setSpotlight(false)} />}
      </AnimatePresence>

      <AnimatePresence>
        {cc && <ControlCenter onClose={() => setCc(false)} onLock={() => setLocked(true)} />}
      </AnimatePresence>

      <Toasts items={toastItems} onDismiss={(id) => setToastIds((t) => t.filter((x) => x !== id))} />

      <AnimatePresence>
        {notifPanel && (
          <NotifPanel
            notifs={notifs}
            onClose={() => setNotifPanel(false)}
            onClear={() => setNotifs([])}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {mc && (
          <MissionControl
            wins={wins.map((w) => ({ key: w.key, app: w.app, minimized: w.minimized }))}
            onPick={(k) => {
              focusWin(k);
              setMc(false);
            }}
            onClose={() => setMc(false)}
          />
        )}
      </AnimatePresence>

      {brightness < 1 && (
        <div className="brightness-overlay" style={{ opacity: 1 - brightness }} />
      )}

      <AnimatePresence>
        {booted && locked && <LockScreen onUnlock={() => setLocked(false)} />}
      </AnimatePresence>

      <AnimatePresence>{!booted && <BootScreen />}</AnimatePresence>
    </div>
  );
}
