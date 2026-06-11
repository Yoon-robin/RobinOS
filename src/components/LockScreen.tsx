import { useEffect, useState } from "react";
import { motion } from "motion/react";
import { useSystem } from "../system/SystemContext";

// 잠금 화면: 부팅 직후 보이고, 클릭하거나 Enter/Space 를 누르면 데스크톱으로.
export default function LockScreen({ onUnlock }: { onUnlock: () => void }) {
  const { wallpaper } = useSystem();
  const [now, setNow] = useState(new Date());

  useEffect(() => {
    const t = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(t);
  }, []);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Enter" || e.key === " ") onUnlock();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onUnlock]);

  const time = now.toLocaleTimeString("ko-KR", { hour: "2-digit", minute: "2-digit" });
  const date = now.toLocaleDateString("ko-KR", {
    month: "long",
    day: "numeric",
    weekday: "long",
  });

  return (
    <motion.div
      className="lock"
      style={{ background: wallpaper.css }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.5 }}
      onClick={onUnlock}
    >
      <div className="lock-overlay" />
      <motion.div
        className="lock-content"
        initial={{ y: -10, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.1 }}
      >
        <div className="lock-time">{time}</div>
        <div className="lock-date">{date}</div>
      </motion.div>
      <motion.div
        className="lock-foot"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.4 }}
      >
        <img src="/brand/logo-mark.svg" className="lock-mark" alt="RobinOS" />
        <span>클릭하거나 Enter 를 눌러 잠금 해제</span>
      </motion.div>
    </motion.div>
  );
}
