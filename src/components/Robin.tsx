import { useEffect, useRef, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import type { RobinResult } from "../system/robin";

type Msg = {
  from: "robin" | "user";
  text: string;
  confirm?: { text: string; run: () => void } | null;
};

// Robin — RobinOS의 개인 에이전트 UI.
// 위험 동작은 ask()가 confirm 을 돌려주고, 여기서 허용/취소 버튼을 띄워요 (가드레일).
export default function Robin({ ask }: { ask: (msg: string) => Promise<RobinResult> }) {
  const [open, setOpen] = useState(false);
  const [msgs, setMsgs] = useState<Msg[]>([
    { from: "robin", text: "안녕하세요, 저는 Robin이에요 🐦 무엇을 도와드릴까요?" },
  ]);
  const [input, setInput] = useState("");
  const [thinking, setThinking] = useState(false);
  const endRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [msgs, open, thinking]);

  const send = async () => {
    const t = input.trim();
    if (!t || thinking) return;
    setInput("");
    setMsgs((m) => [...m, { from: "user", text: t }]);
    setThinking(true);
    try {
      const res = await ask(t);
      setMsgs((m) => [...m, { from: "robin", text: res.reply, confirm: res.confirm ?? null }]);
    } catch {
      setMsgs((m) => [...m, { from: "robin", text: "앗, 문제가 생겼어요. 다시 시도해주세요." }]);
    } finally {
      setThinking(false);
    }
  };

  // 확인 버튼 처리 — 승인 시에만 위험 동작 실행 (run 은 updater 밖에서 호출)
  const resolve = (idx: number, approve: boolean) => {
    const msg = msgs[idx];
    if (approve && msg?.confirm) msg.confirm.run();
    setMsgs((m) => {
      const cleared = m.map((x, i) => (i === idx ? { ...x, confirm: null } : x));
      return [...cleared, { from: "robin", text: approve ? "✅ 실행했어요." : "취소했어요." }];
    });
  };

  return (
    <>
      <motion.button
        className="robin-orb"
        onClick={() => setOpen((o) => !o)}
        whileTap={{ scale: 0.9 }}
        animate={{
          boxShadow: [
            "0 0 18px 3px rgba(168,85,247,0.45)",
            "0 0 30px 8px rgba(168,85,247,0.65)",
            "0 0 18px 3px rgba(168,85,247,0.45)",
          ],
        }}
        transition={{ duration: 2.6, repeat: Infinity, ease: "easeInOut" }}
        aria-label="Robin 에이전트"
      >
        <span className="robin-orb-core" />
      </motion.button>

      <AnimatePresence>
        {open && (
          <motion.div
            className="robin-panel"
            initial={{ opacity: 0, y: 20, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.96 }}
            transition={{ type: "spring", stiffness: 400, damping: 30 }}
          >
            <div className="robin-head">
              <span className="robin-dot" />
              Robin
              <button className="robin-close" onClick={() => setOpen(false)} aria-label="닫기">
                ✕
              </button>
            </div>
            <div className="robin-msgs">
              {msgs.map((m, i) => (
                <div key={i} className={"robin-msg " + m.from}>
                  {m.text.split("\n").map((l, j) => (
                    <div key={j}>{l || " "}</div>
                  ))}
                  {m.confirm && (
                    <div className="robin-confirm">
                      <button className="robin-confirm-yes" onClick={() => resolve(i, true)}>
                        {m.confirm.text}
                      </button>
                      <button className="robin-confirm-no" onClick={() => resolve(i, false)}>
                        취소
                      </button>
                    </div>
                  )}
                </div>
              ))}
              {thinking && (
                <div className="robin-msg robin robin-thinking">
                  <span />
                  <span />
                  <span />
                </div>
              )}
              <div ref={endRef} />
            </div>
            <div className="robin-input-row">
              <input
                className="robin-input"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") send();
                }}
                placeholder="Robin에게 말하기…"
                autoFocus
              />
              <button className="robin-send" onClick={send} aria-label="보내기">
                ↑
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
