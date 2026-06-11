import { motion, AnimatePresence } from "motion/react";

export type Notif = {
  id: number;
  title: string;
  body: string;
  icon: string;
  time: string;
};

// 우상단에 잠깐 떴다 사라지는 토스트 알림들.
export function Toasts({
  items,
  onDismiss,
}: {
  items: Notif[];
  onDismiss: (id: number) => void;
}) {
  return (
    <div className="toasts">
      <AnimatePresence>
        {items.map((n) => (
          <motion.div
            key={n.id}
            className="toast"
            initial={{ opacity: 0, x: 60, scale: 0.95 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            exit={{ opacity: 0, x: 60, scale: 0.9 }}
            transition={{ type: "spring", stiffness: 380, damping: 30 }}
            onClick={() => onDismiss(n.id)}
          >
            <span className="toast-icon">{n.icon}</span>
            <div className="toast-text">
              <p className="toast-title">{n.title}</p>
              <p className="toast-body">{n.body}</p>
            </div>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}

// 메뉴바 시계를 누르면 오른쪽에서 슬라이드되는 알림 목록 패널.
export function NotifPanel({
  notifs,
  onClose,
  onClear,
}: {
  notifs: Notif[];
  onClose: () => void;
  onClear: () => void;
}) {
  return (
    <div className="notif-backdrop" onClick={onClose}>
      <motion.div
        className="notif-panel"
        onClick={(e) => e.stopPropagation()}
        initial={{ x: "110%" }}
        animate={{ x: 0 }}
        exit={{ x: "110%" }}
        transition={{ type: "spring", stiffness: 300, damping: 32 }}
      >
        <div className="notif-head">
          <span>알림</span>
          {notifs.length > 0 && (
            <button className="notif-clear" onClick={onClear}>
              지우기
            </button>
          )}
        </div>
        {notifs.length === 0 && <p className="notif-empty">새로운 알림이 없어요</p>}
        {notifs.map((n) => (
          <div key={n.id} className="notif-item">
            <span className="notif-item-icon">{n.icon}</span>
            <div className="notif-item-text">
              <div className="notif-item-row">
                <span className="notif-item-title">{n.title}</span>
                <span className="notif-item-time">{n.time}</span>
              </div>
              <p className="notif-item-body">{n.body}</p>
            </div>
          </div>
        ))}
      </motion.div>
    </div>
  );
}
