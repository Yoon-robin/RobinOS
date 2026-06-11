import { motion } from "motion/react";
import { APPS, type AppDef } from "../data/apps";

// 런치패드: 모든 앱을 한눈에 보여주는 전체화면 오버레이.
export default function Launchpad({
  onOpen,
  onClose,
}: {
  onOpen: (app: AppDef) => void;
  onClose: () => void;
}) {
  return (
    <motion.div
      className="launchpad"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      onClick={onClose}
    >
      <div className="lp-grid" onClick={(e) => e.stopPropagation()}>
        {APPS.map((a, i) => {
          const isImg = a.icon.startsWith("/");
          return (
            <motion.button
              key={a.id}
              className="lp-item"
              onClick={() => {
                onOpen(a);
                onClose();
              }}
              initial={{ opacity: 0, scale: 0.7 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.03 * i, type: "spring", stiffness: 300, damping: 22 }}
            >
              <span
                className="lp-icon"
                style={{ background: isImg ? "transparent" : a.color }}
              >
                {isImg ? (
                  <img src={a.icon} alt="" className="lp-icon-img" />
                ) : (
                  a.icon
                )}
              </span>
              <span className="lp-name">{a.name}</span>
            </motion.button>
          );
        })}
      </div>
    </motion.div>
  );
}
