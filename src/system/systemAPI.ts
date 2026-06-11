// ===========================================================
// RobinOS 시스템 API — UI/앱이 "시스템 동작"을 부를 때 쓰는 단일 창구.
//
// 지금은 브라우저용(webBackend)으로 구현돼 있어요.
// 나중에 리눅스 위(Tauri 등)에서 돌릴 땐 tauriBackend 를 만들어
//   setBackend(tauriBackend)
// 한 줄로 갈아끼우면 끝 — UI·앱 코드는 한 줄도 안 고쳐요.
//
// 즉 "디자인 → 실제 OS" 전환이 *재작성*이 아니라 *백엔드 교체*가 됩니다.
// ===========================================================

export type NotifyFn = (title: string, body: string, icon?: string) => void;

// 파일/폴더 한 항목
export type FileEntry = { name: string; path: string; type: "dir" | "file" };

export interface SystemBackend {
  // 영속 키-값 저장 (지금: localStorage / 나중: OS 설정 저장소)
  storage: {
    get(key: string): string | null;
    set(key: string, value: string): void;
    remove(key: string): void;
  };
  // 가상 파일 시스템 (지금: localStorage 기반 / 나중: 실제 FS)
  fs: {
    readDir(path: string): FileEntry[];
    readFile(path: string): string | null;
    writeFile(path: string, content: string): void;
    mkdir(path: string): void;
    remove(path: string): void;
    exists(path: string): boolean;
  };
  // 알림 (지금: 인앱 토스트 / 나중: OS 네이티브 알림)
  notify: NotifyFn;
  // 시스템 정보 (지금: 브라우저 / 나중: 실제 OS)
  now(): Date;
  platform(): string;
}

// 알림을 실제로 화면에 띄울 곳(App 의 토스트 시스템)을 여기에 등록해 둠.
let notifySink: NotifyFn | null = null;

// ---------- 가상 파일시스템 (flat map: 경로 -> 노드) ----------
type FileNode = { type: "dir" } | { type: "file"; content: string };
type Tree = Record<string, FileNode>;
const FS_KEY = "robinos.fs.v1";

const parentOf = (p: string): string | null => {
  if (p === "/") return null;
  const i = p.lastIndexOf("/");
  return i === 0 ? "/" : p.slice(0, i);
};
const nameOf = (p: string) => (p === "/" ? "/" : p.slice(p.lastIndexOf("/") + 1));

function loadTree(): Tree {
  try {
    const raw = localStorage.getItem(FS_KEY);
    if (raw) return JSON.parse(raw);
  } catch {
    /* 무시 */
  }
  // 최초 1회 기본 폴더/파일 시드
  const seed: Tree = {
    "/": { type: "dir" },
    "/데스크톱": { type: "dir" },
    "/문서": { type: "dir" },
    "/다운로드": { type: "dir" },
    "/사진": { type: "dir" },
    "/문서/환영.txt": {
      type: "file",
      content:
        "RobinOS 파일 시스템에 오신 걸 환영해요!\n\n메모 앱에서 글을 쓰면 /문서/메모.txt 로 저장되고,\nFinder 에서 바로 보여요.",
    },
  };
  saveTree(seed);
  return seed;
}
function saveTree(t: Tree) {
  try {
    localStorage.setItem(FS_KEY, JSON.stringify(t));
  } catch {
    /* 무시 */
  }
}
// 파일시스템 변경 알림 (Finder 등이 듣고 새로고침). 쓰기 메서드에서만 호출.
function fsChanged() {
  try {
    window.dispatchEvent(new Event("robinos:fs"));
  } catch {
    /* 무시 */
  }
}

const webFs: SystemBackend["fs"] = {
  readDir(path) {
    const t = loadTree();
    return Object.keys(t)
      .filter((p) => p !== "/" && parentOf(p) === path)
      .map((p) => ({ name: nameOf(p), path: p, type: t[p].type }))
      .sort((a, b) =>
        a.type === b.type ? a.name.localeCompare(b.name) : a.type === "dir" ? -1 : 1
      );
  },
  readFile(path) {
    const node = loadTree()[path];
    return node && node.type === "file" ? node.content : null;
  },
  writeFile(path, content) {
    const t = loadTree();
    t[path] = { type: "file", content };
    saveTree(t);
    fsChanged();
  },
  mkdir(path) {
    const t = loadTree();
    if (!t[path]) {
      t[path] = { type: "dir" };
      saveTree(t);
      fsChanged();
    }
  },
  remove(path) {
    const t = loadTree();
    delete t[path];
    // 하위 항목도 함께 제거
    for (const k of Object.keys(t)) if (k.startsWith(path + "/")) delete t[k];
    saveTree(t);
    fsChanged();
  },
  exists(path) {
    return !!loadTree()[path];
  },
};

// ---------- 현재(브라우저) 백엔드 ----------
const webBackend: SystemBackend = {
  storage: {
    get(key) {
      try {
        return localStorage.getItem(key);
      } catch {
        return null;
      }
    },
    set(key, value) {
      try {
        localStorage.setItem(key, value);
      } catch {
        /* 무시 */
      }
    },
    remove(key) {
      try {
        localStorage.removeItem(key);
      } catch {
        /* 무시 */
      }
    },
  },
  fs: webFs,
  notify(title, body, icon) {
    notifySink?.(title, body, icon);
  },
  now() {
    return new Date();
  },
  platform() {
    return "web";
  },
};

// 현재 활성 백엔드 (나중에 setBackend 로 교체)
let backend: SystemBackend = webBackend;

export function setBackend(b: SystemBackend) {
  backend = b;
}

// ---------- 앱/UI 가 실제로 쓰는 단일 진입점 ----------
export const system: SystemBackend = {
  storage: {
    get: (k) => backend.storage.get(k),
    set: (k, v) => backend.storage.set(k, v),
    remove: (k) => backend.storage.remove(k),
  },
  fs: {
    readDir: (p) => backend.fs.readDir(p),
    readFile: (p) => backend.fs.readFile(p),
    writeFile: (p, c) => backend.fs.writeFile(p, c),
    mkdir: (p) => backend.fs.mkdir(p),
    remove: (p) => backend.fs.remove(p),
    exists: (p) => backend.fs.exists(p),
  },
  notify: (t, b, i) => backend.notify(t, b, i),
  now: () => backend.now(),
  platform: () => backend.platform(),
};

// App 이 마운트될 때 토스트 표시 함수를 등록 (cleanup 시 해제)
export function registerNotifySink(fn: NotifyFn) {
  notifySink = fn;
  return () => {
    if (notifySink === fn) notifySink = null;
  };
}
