import { useEffect, useState } from "react";
import { system } from "../system/systemAPI";

// 메모 앱: 입력 내용을 localStorage 에 자동 저장해요.
export default function Notes() {
  const [text, setText] = useState(
    () =>
      system.fs.readFile("/문서/메모.txt") ??
      "여기에 메모를 적어보세요…\n\n입력하는 대로 자동 저장됩니다."
  );

  useEffect(() => {
    const t = setTimeout(() => system.fs.writeFile("/문서/메모.txt", text), 300);
    return () => clearTimeout(t);
  }, [text]);

  // Robin이 메모에 글을 쓰면 즉시 반영
  useEffect(() => {
    const h = (e: Event) => {
      const d = (e as CustomEvent).detail;
      if (typeof d?.text === "string") setText(d.text);
    };
    window.addEventListener("robin:notes", h);
    return () => window.removeEventListener("robin:notes", h);
  }, []);

  return (
    <textarea
      className="app-notes"
      value={text}
      onChange={(e) => setText(e.target.value)}
      spellCheck={false}
    />
  );
}
