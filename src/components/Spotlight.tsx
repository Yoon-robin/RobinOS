import { useEffect, useMemo, useRef, useState } from "react";
import { motion } from "motion/react";
import { APPS, type AppDef } from "../data/apps";

// Spotlight 검색: ⌘/Ctrl+Space 또는 메뉴바 검색 아이콘으로 열려요.
// 입력하면 앱이 필터링되고, ↑↓ 로 이동 · Enter/클릭으로 실행.
export default function Spotlight({
  onOpen,
  onClose,
}: {
  onOpen: (a: AppDef) => void;
  onClose: () => void;
}) {
  const [q, setQ] = useState("");
  const [sel, setSel] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  const results = useMemo(() => {
    const s = q.trim().toLowerCase();
    if (!s) return APPS;
    return APPS.filter(
      (a) => a.name.toLowerCase().includes(s) || a.id.includes(s)
    );
  }, [q]);

  useEffect(() => setSel(0), [q]);

  const launch = (a?: AppDef) => {
    const app = a ?? results[sel];
    if (app) {
      onOpen(app);
      onClose();
    }
  };

  const onKey = (e: React.KeyboardEvent) => {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setSel((s) => Math.min(s + 1, results.length - 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setSel((s) => Math.max(s - 1, 0));
    } else if (e.key === "Enter") {
      e.preventDefault();
      launch();
    }
  };

  return (
    <motion.div
      className="spotlight-backdrop"
      onClick={onClose}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.15 }}
    >
      <motion.div
        className="spotlight"
        onClick={(e) => e.stopPropagation()}
        initial={{ opacity: 0, y: -12, scale: 0.98 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: -12, scale: 0.98 }}
        transition={{ type: "spring", stiffness: 420, damping: 30 }}
      >
        <div className="sp-input-row">
          <span className="sp-search-icon">🔍</span>
          <input
            ref={inputRef}
            className="sp-input"
            placeholder="앱 검색…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            onKeyDown={onKey}
            spellCheck={false}
          />
        </div>
        {results.length > 0 && (
          <div className="sp-results">
            {results.map((a, i) => {
              const isImg = a.icon.startsWith("/");
              return (
                <button
                  key={a.id}
                  className={"sp-item" + (i === sel ? " sel" : "")}
                  onMouseEnter={() => setSel(i)}
                  onClick={() => launch(a)}
                >
                  <span
                    className="sp-item-icon"
                    style={{ background: isImg ? "transparent" : a.color }}
                  >
                    {isImg ? (
                      <img src={a.icon} alt="" className="sp-item-img" />
                    ) : (
                      a.icon
                    )}
                  </span>
                  <span className="sp-item-name">{a.name}</span>
                </button>
              );
            })}
          </div>
        )}
      </motion.div>
    </motion.div>
  );
}
