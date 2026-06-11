import { useState } from "react";
import { motion } from "motion/react";
import { useSystem, ACCENTS } from "../system/SystemContext";

// 제어 센터: 메뉴바 우측 아이콘을 누르면 열리는 빠른 설정 패널.
export default function ControlCenter({
  onClose,
  onLock,
}: {
  onClose: () => void;
  onLock: () => void;
}) {
  const { accent, setAccent, brightness, setBrightness, theme, setTheme } = useSystem();
  const [wifi, setWifi] = useState(true);
  const [bt, setBt] = useState(true);

  return (
    <div className="cc-backdrop" onClick={onClose}>
      <motion.div
        className="cc"
        onClick={(e) => e.stopPropagation()}
        initial={{ opacity: 0, y: -8, scale: 0.98 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: -8, scale: 0.98 }}
        transition={{ type: "spring", stiffness: 420, damping: 30 }}
      >
        <div className="cc-row">
          <button className={"cc-toggle" + (wifi ? " on" : "")} onClick={() => setWifi((v) => !v)}>
            <span className="cc-toggle-icon">📶</span>
            <span>Wi-Fi</span>
          </button>
          <button className={"cc-toggle" + (bt ? " on" : "")} onClick={() => setBt((v) => !v)}>
            <span className="cc-toggle-icon">🔵</span>
            <span>Bluetooth</span>
          </button>
        </div>

        <div className="cc-card">
          <p className="cc-label">밝기</p>
          <input
            type="range"
            min={55}
            max={100}
            step={1}
            value={Math.round(brightness * 100)}
            onChange={(e) => setBrightness(Number(e.target.value) / 100)}
            className="cc-slider"
          />
        </div>

        <div className="cc-card">
          <p className="cc-label">강조 색</p>
          <div className="cc-accents">
            {ACCENTS.map((a) => (
              <button
                key={a.id}
                className={"cc-dot" + (a.color === accent ? " sel" : "")}
                style={{ background: a.color }}
                onClick={() => setAccent(a.color)}
                aria-label={a.name}
              />
            ))}
          </div>
        </div>

        <button
          className="cc-lock"
          onClick={() => setTheme(theme === "light" ? "dark" : "light")}
        >
          {theme === "light" ? "☀️ 라이트 모드" : "🌙 다크 모드"}
        </button>
        <button
          className="cc-lock"
          onClick={() => {
            onLock();
            onClose();
          }}
        >
          🔒 화면 잠금
        </button>
      </motion.div>
    </div>
  );
}
