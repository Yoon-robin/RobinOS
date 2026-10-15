// A small local server for the video page. Chrome blocks ES modules and fonts
// on file:// (the origin is null), so the page is served on 127.0.0.1 only.
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const HERE = path.dirname(fileURLToPath(import.meta.url));
const TYPES = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8", ".woff2": "font/woff2", ".wav": "audio/wav", ".png": "image/png", ".svg": "image/svg+xml",
};

export function serve(port = 0) {
  return new Promise((resolve, reject) => {
    const srv = http.createServer((req, res) => {
      let p = decodeURIComponent(new URL(req.url, "http://x").pathname);
      if (p === "/") p = "/index.html";
      const file = path.join(HERE, p);
      if (!file.startsWith(HERE + path.sep)) { res.writeHead(403); res.end(); return; }
      fs.readFile(file, (err, buf) => {
        if (err) { res.writeHead(404); res.end("not found"); return; }
        res.writeHead(200, { "Content-Type": TYPES[path.extname(file)] || "application/octet-stream", "Cache-Control": "no-store" });
        res.end(buf);
      });
    });
    srv.on("error", reject);
    srv.listen(port, "127.0.0.1", () => resolve({ srv, port: srv.address().port }));
  });
}
