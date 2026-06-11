import { motion } from "motion/react";
import type { AppDef } from "../data/apps";

type WinCard = { key: number; app: AppDef; minimized: boolean };

// 미션 컨트롤: 열린 창들을 카드로 펼쳐 한눈에 보고, 누르면 그 창으로.
export default function MissionControl({
  wins,
  onPick,
  onClose,
}: {
  wins: WinCard[];
  onPick: (key: number) => void;
  onClose: () => void;
}) {
  return (
    <motion.div
      className="mc"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      onClick={onClose}
    >
      {wins.length === 0 && <p className="mc-empty">열린 창이 없어요</p>}
      <div className="mc-grid" onClick={(e) => e.stopPropagation()}>
        {wins.map((w, i) => {
          const isImg = w.app.icon.startsWith("/");
          return (
            <motion.button
              key={w.key}
              className="mc-card"
              onClick={() => onPick(w.key)}
              initial={{ opacity: 0, scale: 0.85, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.85 }}
              transition={{ delay: i * 0.04, type: "spring", stiffness: 300, damping: 24 }}
            >
              <div
                className="mc-card-icon"
                style={{ background: isImg ? "transparent" : w.app.color }}
              >
                {isImg ? (
                  <img src={w.app.icon} alt="" className="mc-card-img" />
                ) : (
                  w.app.icon
                )}
              </div>
              <span className="mc-card-title">
                {w.app.name}
                {w.minimized ? " (최소화됨)" : ""}
              </span>
            </motion.button>
          );
        })}
      </div>
    </motion.div>
  );
}
