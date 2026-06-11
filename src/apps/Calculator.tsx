import { useEffect, useState } from "react";

// 실제로 계산되는 계산기 (macOS 스타일 2-피연산자 방식).
export default function Calculator() {
  const [display, setDisplay] = useState("0");
  const [prev, setPrev] = useState<number | null>(null);
  const [op, setOp] = useState<string | null>(null);
  const [fresh, setFresh] = useState(true); // 다음 숫자가 새 입력의 시작인지

  // Robin이 계산하면 결과를 디스플레이에 표시
  useEffect(() => {
    const onRobin = (e: Event) => {
      const d = (e as CustomEvent).detail;
      if (d?.result != null) {
        setDisplay(String(d.result));
        setPrev(null);
        setOp(null);
        setFresh(true);
      }
    };
    window.addEventListener("robin:calc", onRobin);
    return () => window.removeEventListener("robin:calc", onRobin);
  }, []);

  const fmt = (n: number) =>
    Number.isFinite(n) ? String(Math.round(n * 1e10) / 1e10) : "오류";
  const apply = (a: number, b: number, o: string) =>
    o === "+" ? a + b : o === "−" ? a - b : o === "×" ? a * b : a / b;

  const inputDigit = (d: string) => {
    if (fresh) {
      setDisplay(d === "." ? "0." : d);
      setFresh(false);
    } else {
      if (d === "." && display.includes(".")) return;
      setDisplay(display.length < 12 ? display + d : display);
    }
  };
  const clearAll = () => {
    setDisplay("0");
    setPrev(null);
    setOp(null);
    setFresh(true);
  };
  const chooseOp = (o: string) => {
    const cur = parseFloat(display);
    if (prev !== null && op && !fresh) {
      const r = apply(prev, cur, op);
      setPrev(r);
      setDisplay(fmt(r));
    } else {
      setPrev(cur);
    }
    setOp(o);
    setFresh(true);
  };
  const equals = () => {
    if (op === null || prev === null) return;
    const r = apply(prev, parseFloat(display), op);
    setDisplay(fmt(r));
    setPrev(null);
    setOp(null);
    setFresh(true);
  };

  const keys: { label: string; fn: () => void; cls: string }[] = [
    { label: "AC", fn: clearAll, cls: "fn" },
    { label: "±", fn: () => setDisplay(fmt(parseFloat(display) * -1)), cls: "fn" },
    { label: "%", fn: () => setDisplay(fmt(parseFloat(display) / 100)), cls: "fn" },
    { label: "÷", fn: () => chooseOp("÷"), cls: "op" },
    { label: "7", fn: () => inputDigit("7"), cls: "" },
    { label: "8", fn: () => inputDigit("8"), cls: "" },
    { label: "9", fn: () => inputDigit("9"), cls: "" },
    { label: "×", fn: () => chooseOp("×"), cls: "op" },
    { label: "4", fn: () => inputDigit("4"), cls: "" },
    { label: "5", fn: () => inputDigit("5"), cls: "" },
    { label: "6", fn: () => inputDigit("6"), cls: "" },
    { label: "−", fn: () => chooseOp("−"), cls: "op" },
    { label: "1", fn: () => inputDigit("1"), cls: "" },
    { label: "2", fn: () => inputDigit("2"), cls: "" },
    { label: "3", fn: () => inputDigit("3"), cls: "" },
    { label: "+", fn: () => chooseOp("+"), cls: "op" },
    { label: "0", fn: () => inputDigit("0"), cls: "zero" },
    { label: ".", fn: () => inputDigit("."), cls: "" },
    { label: "=", fn: equals, cls: "op" },
  ];

  return (
    <div className="app-calc">
      <div className="calc-display">{display}</div>
      <div className="calc-grid">
        {keys.map((k) => (
          <button
            key={k.label}
            className={"calc-key " + k.cls}
            onClick={k.fn}
          >
            {k.label}
          </button>
        ))}
      </div>
    </div>
  );
}
