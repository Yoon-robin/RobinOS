import { motion } from "motion/react";

// 부팅 화면: 로고가 통통 튀며 나타나고, 진행 바가 채워진 뒤
// App.tsx 에서 일정 시간 후 사라지면서 데스크톱으로 전환돼요.
export default function BootScreen() {
  return (
    <motion.div
      className="boot"
      initial={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.6 }}
    >
      <motion.img
        src="/brand/logo-wordmark-light.svg"
        alt="RobinOS"
        className="boot-wordmark"
        initial={{ scale: 0.85, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ type: "spring", stiffness: 200, damping: 16 }}
      />
      <div className="boot-bar">
        <motion.div
          className="boot-bar-fill"
          initial={{ width: "0%" }}
          animate={{ width: "100%" }}
          transition={{ duration: 1.8, ease: "easeInOut" }}
        />
      </div>
    </motion.div>
  );
}
