import { useState } from "react";
import { useSystem, WALLPAPERS, ACCENTS } from "../system/SystemContext";
import { system } from "../system/systemAPI";
import { setRobinBrain, localBrain } from "../system/robin";
import { deepseekBrain } from "../system/robin-deepseek";

const SECTIONS = [
  { id: "appearance", name: "화면", icon: "🎨" },
  { id: "robin", name: "Robin", icon: "🐦" },
  { id: "about", name: "정보", icon: "ℹ️" },
];

// 설정 앱 — 화면(배경·강조색·테마·밝기) / Robin(두뇌·API키) / 정보.
export default function Settings() {
  const {
    wallpaperId,
    setWallpaperId,
    accent,
    setAccent,
    brightness,
    setBrightness,
    theme,
    setTheme,
  } = useSystem();
  const [section, setSection] = useState("appearance");
  const [brain, setBrain] = useState(() => system.storage.get("robinos.brain") ?? "local");
  const [apiKey, setApiKey] = useState(() => system.storage.get("robinos.deepseek.key") ?? "");

  const chooseBrain = (b: string) => {
    setBrain(b);
    system.storage.set("robinos.brain", b);
    setRobinBrain(b === "deepseek" ? deepseekBrain : localBrain);
  };
  const saveKey = (k: string) => {
    setApiKey(k);
    system.storage.set("robinos.deepseek.key", k);
  };

  return (
    <div className="app-settings2">
      <aside className="set-side">
        {SECTIONS.map((s) => (
          <button
            key={s.id}
            className={"set-side-item" + (section === s.id ? " sel" : "")}
            onClick={() => setSection(s.id)}
          >
            <span className="set-side-icon">{s.icon}</span>
            {s.name}
          </button>
        ))}
      </aside>

      <main className="set-main">
        {section === "appearance" && (
          <>
            <h2 className="settings-h">배경화면</h2>
            <div className="wp-grid">
              {WALLPAPERS.map((w) => (
                <button
                  key={w.id}
                  className={"wp-cell" + (w.id === wallpaperId ? " sel" : "")}
                  style={{ background: w.css }}
                  onClick={() => {
                    setWallpaperId(w.id);
                    system.notify("배경화면", `${w.name}(으)로 변경했어요`, "🖼️");
                  }}
                  title={w.name}
                >
                  <span className="wp-name">{w.name}</span>
                </button>
              ))}
            </div>

            <h2 className="settings-h">강조 색</h2>
            <div className="accent-row">
              {ACCENTS.map((a) => (
                <button
                  key={a.id}
                  className={"accent-dot" + (a.color === accent ? " sel" : "")}
                  style={{ background: a.color }}
                  onClick={() => setAccent(a.color)}
                  aria-label={a.name}
                />
              ))}
            </div>

            <h2 className="settings-h">테마</h2>
            <div className="set-theme-row">
              <button
                className={"set-theme" + (theme === "dark" ? " sel" : "")}
                onClick={() => setTheme("dark")}
              >
                🌙 다크
              </button>
              <button
                className={"set-theme" + (theme === "light" ? " sel" : "")}
                onClick={() => setTheme("light")}
              >
                ☀️ 라이트
              </button>
            </div>

            <h2 className="settings-h">밝기</h2>
            <input
              type="range"
              min={55}
              max={100}
              step={1}
              value={Math.round(brightness * 100)}
              onChange={(e) => setBrightness(Number(e.target.value) / 100)}
              className="set-slider"
            />
          </>
        )}

        {section === "robin" && (
          <>
            <h2 className="settings-h">Robin 두뇌</h2>
            <div className="brain-opts">
              <button
                className={"brain-opt" + (brain === "local" ? " sel" : "")}
                onClick={() => chooseBrain("local")}
              >
                <b>로컬</b>
                <span>오프라인 · 기본 명령</span>
              </button>
              <button
                className={"brain-opt" + (brain === "deepseek" ? " sel" : "")}
                onClick={() => chooseBrain("deepseek")}
              >
                <b>DeepSeek</b>
                <span>자연어 · 클라우드</span>
              </button>
            </div>

            {brain === "deepseek" && (
              <>
                <h2 className="settings-h">DeepSeek API 키</h2>
                <input
                  type="password"
                  className="set-input"
                  value={apiKey}
                  onChange={(e) => saveKey(e.target.value)}
                  placeholder="sk-..."
                  spellCheck={false}
                />
                <p className="settings-note">
                  ⚠️ 클라우드라 대화·맥락이 DeepSeek 서버로 전송돼요. 브라우저에선 CORS로 막힐 수
                  있고, 네이티브 빌드에선 정상 작동해요. 더 프라이빗하게 하려면 나중에 로컬
                  LLM(Ollama)으로 바꿀 수 있어요.
                </p>
              </>
            )}
          </>
        )}

        {section === "about" && (
          <div className="set-about">
            <img src="/brand/logo-mark.svg" alt="RobinOS" className="about-mark" />
            <img src="/brand/logo-wordmark-light.svg" alt="RobinOS" className="about-wordmark" />
            <p className="about-version">버전 0.1 “Aurora”</p>
            <div className="about-specs">
              <div>
                <span>셸</span>
                <b>RobinOS Shell</b>
              </div>
              <div>
                <span>렌더러</span>
                <b>React 19 (프로토타입)</b>
              </div>
              <div>
                <span>에이전트</span>
                <b>Robin 🐦</b>
              </div>
              <div>
                <span>만든 사람</span>
                <b>Robin</b>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
