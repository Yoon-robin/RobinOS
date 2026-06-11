import { useEffect, useState } from "react";
import { system, type FileEntry } from "../system/systemAPI";

// Finder — system.fs(가상 파일시스템) 위에서 실제로 탐색·생성·미리보기.
// 메모 앱이 /문서/메모.txt 를 저장하면 여기 실시간으로 보여요.
function iconFor(e: FileEntry) {
  if (e.type === "dir") return "📁";
  if (/\.(png|jpe?g|gif|webp)$/i.test(e.name)) return "🖼️";
  return "📄";
}
const join = (dir: string, name: string) => (dir === "/" ? "" : dir) + "/" + name;

export default function Finder() {
  const [path, setPath] = useState("/");
  const [, setTick] = useState(0); // fs 변경 시 재렌더용
  const [preview, setPreview] = useState<{ name: string; content: string } | null>(null);

  // 파일시스템 변경 이벤트를 듣고 새로고침 (메모 저장 → 즉시 반영)
  useEffect(() => {
    const h = () => setTick((t) => t + 1);
    window.addEventListener("robinos:fs", h);
    return () => window.removeEventListener("robinos:fs", h);
  }, []);

  const entries = system.fs.readDir(path);
  const favorites = system.fs.readDir("/").filter((e) => e.type === "dir");

  const goUp = () => {
    const i = path.lastIndexOf("/");
    setPath(i <= 0 ? "/" : path.slice(0, i));
    setPreview(null);
  };
  const open = (e: FileEntry) => {
    if (e.type === "dir") {
      setPath(e.path);
      setPreview(null);
    } else {
      setPreview({ name: e.name, content: system.fs.readFile(e.path) ?? "" });
    }
  };
  const newFolder = () => {
    let name = "새 폴더";
    let n = 1;
    while (system.fs.exists(join(path, name))) name = `새 폴더 ${++n}`;
    system.fs.mkdir(join(path, name));
  };

  return (
    <div className="app-finder">
      <aside className="finder-side">
        <p className="finder-side-label">즐겨찾기</p>
        {favorites.map((f) => (
          <button
            key={f.path}
            className={"finder-side-item" + (path === f.path ? " sel" : "")}
            onClick={() => {
              setPath(f.path);
              setPreview(null);
            }}
          >
            <span>📁</span>
            {f.name}
          </button>
        ))}
      </aside>
      <main className="finder-main">
        <div className="finder-bar">
          <button className="finder-btn" onClick={goUp} disabled={path === "/"} aria-label="뒤로">
            ‹
          </button>
          <span className="finder-path">{path === "/" ? "RobinOS" : path}</span>
          <button className="finder-btn finder-new" onClick={newFolder}>
            ＋ 새 폴더
          </button>
        </div>

        {preview ? (
          <div className="finder-preview">
            <div className="finder-preview-head">
              <span>📄 {preview.name}</span>
              <button className="finder-btn" onClick={() => setPreview(null)}>
                닫기
              </button>
            </div>
            <pre className="finder-preview-body">{preview.content || "(빈 파일)"}</pre>
          </div>
        ) : (
          <div className="finder-grid">
            {entries.length === 0 && <p className="finder-empty">비어 있음</p>}
            {entries.map((e) => (
              <button className="finder-item" key={e.path} onClick={() => open(e)}>
                <span className="finder-item-icon">{iconFor(e)}</span>
                <span className="finder-item-name">{e.name}</span>
              </button>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
