import { useEffect, useRef, useState } from "react";

// 간단한 가짜 터미널. 몇 가지 명령어가 실제로 동작해요.
type Line = { text: string; cls?: string };

const BANNER = "RobinOS Terminal — 'help' 를 입력해보세요.";

export default function Terminal() {
  const [lines, setLines] = useState<Line[]>([{ text: BANNER, cls: "muted" }]);
  const [input, setInput] = useState("");
  const endRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    endRef.current?.scrollIntoView();
  }, [lines]);

  const run = (raw: string) => {
    const cmd = raw.trim();
    const out: Line[] = [{ text: `robin@robinos ~ % ${cmd}` }];
    const [name, ...args] = cmd.split(/\s+/);
    switch (name) {
      case "":
        break;
      case "help":
        out.push({
          text: "사용 가능: help, ls, whoami, date, echo, about, neofetch, clear",
          cls: "muted",
        });
        break;
      case "ls":
        out.push({ text: "프로젝트  문서  사진  메모.txt  배경.png" });
        break;
      case "whoami":
        out.push({ text: "robin" });
        break;
      case "date":
        out.push({ text: new Date().toLocaleString("ko-KR") });
        break;
      case "echo":
        out.push({ text: args.join(" ") });
        break;
      case "about":
        out.push({ text: "RobinOS v0.1 — 당신만의 OS. Robin 이 만들었어요." });
        break;
      case "neofetch":
        out.push({ text: "  ██████  robin@robinos", cls: "accent" });
        out.push({ text: "  █ R  █  OS: RobinOS 0.1 Aurora", cls: "accent" });
        out.push({ text: "  ██████  Shell: RobinShell", cls: "accent" });
        break;
      case "clear":
        setLines([]);
        return;
      default:
        out.push({ text: `command not found: ${name}`, cls: "err" });
    }
    setLines((l) => [...l, ...out]);
  };

  const onKey = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      run(input);
      setInput("");
    }
  };

  return (
    <div className="app-term" onClick={(e) => (e.currentTarget.querySelector("input") as HTMLInputElement)?.focus()}>
      {lines.map((l, i) => (
        <div key={i} className={"term-line " + (l.cls ?? "")}>
          {l.text || " "}
        </div>
      ))}
      <div className="term-input-row">
        <span className="term-prompt">robin@robinos ~ %</span>
        <input
          className="term-input"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={onKey}
          autoFocus
          spellCheck={false}
        />
      </div>
      <div ref={endRef} />
    </div>
  );
}
