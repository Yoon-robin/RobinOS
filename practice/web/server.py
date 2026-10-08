#!/usr/bin/env python3
"""RobinOS 웹 기초 연습 서버 (robinctl learn 21-25).

내 컴퓨터(127.0.0.1)에서만 열려요. 끄려면 이 서버를 띄운 터미널에서 Ctrl+C,
뒤에서 돌고 있으면 kill %1 이나 pkill -f practice/web/server.py.
정답 코드는 0x5a로 XOR 해 둬서 이 파일만 읽어서는 바로 보이지 않아요.
"""
import http.server
import os

HOST = "127.0.0.1"
PORT = int(os.environ.get("ROBIN_WEB_PORT", "8000"))
SESSION = "robin-practice"

CODES = {
    "hello": "0815181314770d1f1877121f161615",
    "header": "0815181314770d1f1877121f1b1e1f08",
    "robots": "0815181314770d1f1877081518150e09",
    "cookie": "0815181314770d1f187719151511131f",
    "redirect": "0815181314770d1f1877081f1e13081f190e",
}


def code(name):
    return bytes(b ^ 0x5a for b in bytes.fromhex(CODES[name])).decode()


def page(title, body):
    return (f'<!doctype html>\n<html lang="ko">\n<head><meta charset="utf-8"><title>{title}</title></head>\n'
            f"<body>\n<h1>{title}</h1>\n{body}\n</body>\n</html>\n")


class Handler(http.server.BaseHTTPRequestHandler):
    server_version = "RobinOS-Practice/1.0"

    def reply(self, status, body="", headers=None, content_type="text/html; charset=utf-8"):
        data = body.encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        for name, value in (headers or {}).items():
            self.send_header(name, value)
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(data)

    def do_HEAD(self):
        self.do_GET()

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/":
            self.reply(200, page("RobinOS 연습 서버", f"<p>접속했어요! 코드: {code('hello')}</p>\n"
                                  "<p>응답 헤더에도 무언가 있어요: curl -I</p>"),
                       {"X-Robin-Code": code("header")})
        elif path == "/robots.txt":
            self.reply(200, "# 검색 로봇에게 보여 주지 말라는 곳이에요. 막는 게 아니라 부탁일 뿐이에요.\n"
                            "User-agent: *\nDisallow: /secret-notes/\n", content_type="text/plain; charset=utf-8")
        elif path in ("/secret-notes", "/secret-notes/"):
            self.reply(200, page("숨겨 둔 메모", f"<p>robots.txt는 숨기는 기능이 아니에요. 코드: {code('robots')}</p>"))
        elif path == "/login":
            self.reply(200, page("로그인", "<p>쿠키를 드렸어요. 이제 /me 에 쿠키를 보내 보세요.</p>"),
                       {"Set-Cookie": f"session={SESSION}; Path=/; HttpOnly"})
        elif path == "/me":
            cookies = self.headers.get("Cookie", "")
            if f"session={SESSION}" in [c.strip() for c in cookies.split(";")]:
                self.reply(200, page("내 정보", f"<p>쿠키로 누군지 알아봤어요. 코드: {code('cookie')}</p>"))
            else:
                self.reply(401, page("로그인이 필요해요", "<p>쿠키가 없어요. 먼저 /login 에서 쿠키를 받아요.</p>"))
        elif path == "/old-page":
            self.reply(301, page("옮겼어요", "<p>새 주소로 옮겼어요.</p>"), {"Location": "/new-page"})
        elif path == "/new-page":
            self.reply(200, page("새 페이지", f"<p>리다이렉트를 따라왔어요. 코드: {code('redirect')}</p>"))
        else:
            self.reply(404, page("없는 페이지예요", "<p>404 Not Found</p>"))


if __name__ == "__main__":
    print(f"연습 서버가 http://{HOST}:{PORT} 에서 돌고 있어요. 끄려면 Ctrl+C", flush=True)
    try:
        http.server.ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
    except KeyboardInterrupt:
        pass
    except OSError as error:
        print(f"서버를 켜지 못했어요: {error} (이미 켜져 있나요? ss -tln 으로 {PORT}번을 확인해요)")
