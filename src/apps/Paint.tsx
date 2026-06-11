import { useRef, useState } from "react";

const COLORS = ["#a855f7", "#3b82f6", "#ec4899", "#14b8a6", "#f59e0b", "#ef4444", "#111827", "#ffffff"];
const SIZES = [3, 6, 12];

// 그림판: 캔버스에 마우스로 그려요. 색·브러시 크기·지우기 지원.
export default function Paint() {
  const ref = useRef<HTMLCanvasElement>(null);
  const [color, setColor] = useState("#a855f7");
  const [size, setSize] = useState(6);
  const drawing = useRef(false);
  const last = useRef<{ x: number; y: number } | null>(null);

  // 화면 좌표 → 캔버스 내부 좌표 (캔버스는 1000x680 고정, CSS로 늘려서 표시)
  const pos = (e: React.PointerEvent) => {
    const c = ref.current!;
    const r = c.getBoundingClientRect();
    return {
      x: ((e.clientX - r.left) / r.width) * c.width,
      y: ((e.clientY - r.top) / r.height) * c.height,
    };
  };

  const down = (e: React.PointerEvent) => {
    drawing.current = true;
    last.current = pos(e);
    try {
      (e.currentTarget as Element).setPointerCapture(e.pointerId);
    } catch {
      /* 무시 */
    }
  };
  const move = (e: React.PointerEvent) => {
    if (!drawing.current) return;
    const ctx = ref.current!.getContext("2d")!;
    const p = pos(e);
    const l = last.current!;
    ctx.strokeStyle = color;
    ctx.lineWidth = size;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.beginPath();
    ctx.moveTo(l.x, l.y);
    ctx.lineTo(p.x, p.y);
    ctx.stroke();
    last.current = p;
  };
  const up = () => {
    drawing.current = false;
    last.current = null;
  };
  const clear = () => {
    const c = ref.current!;
    c.getContext("2d")!.clearRect(0, 0, c.width, c.height);
  };

  return (
    <div className="app-paint">
      <div className="paint-toolbar">
        <div className="paint-colors">
          {COLORS.map((col) => (
            <button
              key={col}
              className={"paint-swatch" + (col === color ? " sel" : "")}
              style={{ background: col }}
              onClick={() => setColor(col)}
              aria-label={col}
            />
          ))}
        </div>
        <div className="paint-sizes">
          {SIZES.map((s) => (
            <button
              key={s}
              className={"paint-size" + (s === size ? " sel" : "")}
              onClick={() => setSize(s)}
              aria-label={`브러시 ${s}`}
            >
              <span style={{ width: s + 3, height: s + 3 }} />
            </button>
          ))}
        </div>
        <button className="paint-clear" onClick={clear}>
          지우기
        </button>
      </div>
      <canvas
        ref={ref}
        width={1000}
        height={680}
        className="paint-canvas"
        onPointerDown={down}
        onPointerMove={move}
        onPointerUp={up}
      />
    </div>
  );
}
