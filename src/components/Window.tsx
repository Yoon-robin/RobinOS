import { useState } from "react";
import { motion } from "motion/react";
import type { AppDef } from "../data/apps";

const MENUBAR = 28;

type Props = {
  app: AppDef;
  x: number;
  y: number;
  w: number;
  h: number;
  z: number;
  active: boolean;
  minimized: boolean;
  maximized: boolean;
  onFocus: () => void;
  onClose: () => void;
  onMinimize: () => void;
  onToggleMax: () => void;
  onMove: (x: number, y: number) => void;
  onResize: (w: number, h: number) => void;
  onSnap?: (zone: "left" | "right" | "max") => void;
};

export default function Window(props: Props) {
  const { app, x, y, w, h, z, active, minimized, maximized } = props;
  const [interacting, setInteracting] = useState(false);
  const Body = app.component;

  // 타이틀바를 잡고 창 이동 (직접 포인터 추적 → 정확하고 부드러움).
  const startDrag = (e: React.PointerEvent) => {
    if (maximized) return;
    if ((e.target as HTMLElement).closest(".light")) return; // 신호등 클릭은 제외
    props.onFocus();
    setInteracting(true);
    const sx = e.clientX, sy = e.clientY, ox = x, oy = y;
    let lastX = e.clientX, lastY = e.clientY;
    const move = (ev: PointerEvent) => {
      lastX = ev.clientX;
      lastY = ev.clientY;
      props.onMove(ox + ev.clientX - sx, Math.max(MENUBAR, oy + ev.clientY - sy));
    };
    const up = () => {
      setInteracting(false);
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
      // 가장자리 스냅: 상단→최대화, 좌/우 끝→반쪽
      if (props.onSnap) {
        if (lastY <= MENUBAR + 4) props.onSnap("max");
        else if (lastX <= 6) props.onSnap("left");
        else if (lastX >= window.innerWidth - 6) props.onSnap("right");
      }
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
  };

  // 오른쪽 아래 모서리를 잡고 크기 조절.
  const startResize = (e: React.PointerEvent) => {
    e.stopPropagation();
    props.onFocus();
    setInteracting(true);
    const sx = e.clientX, sy = e.clientY, ow = w, oh = h;
    const move = (ev: PointerEvent) => {
      props.onResize(
        Math.max(260, ow + ev.clientX - sx),
        Math.max(180, oh + ev.clientY - sy)
      );
    };
    const up = () => {
      setInteracting(false);
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
  };

  return (
    <motion.div
      className={
        "window" +
        (active ? " active" : "") +
        (maximized ? " maximized" : "") +
        (interacting ? "" : " win-anim")
      }
      style={{ left: x, top: y, width: w, height: h, zIndex: z }}
      initial={{ opacity: 0, scale: 0.92 }}
      animate={{
        opacity: minimized ? 0 : 1,
        scale: minimized ? 0.3 : 1,
        y: minimized ? 280 : 0,
        pointerEvents: minimized ? "none" : "auto",
      }}
      exit={{ opacity: 0, scale: 0.92 }}
      transition={{ type: "spring", stiffness: 320, damping: 28 }}
      onPointerDown={props.onFocus}
    >
      <div className="titlebar" onPointerDown={startDrag} onDoubleClick={props.onToggleMax}>
        <div className="traffic">
          <button className="light red" onClick={props.onClose} aria-label="닫기" />
          <button className="light yellow" onClick={props.onMinimize} aria-label="최소화" />
          <button className="light green" onClick={props.onToggleMax} aria-label="최대화" />
        </div>
        <span className="titlebar-title">{app.name}</span>
      </div>
      <div className="window-content">
        <Body />
      </div>
      {!maximized && <div className="resize-handle" onPointerDown={startResize} />}
    </motion.div>
  );
}
