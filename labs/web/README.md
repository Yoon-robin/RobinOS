# RobinOS 웹 랩

이 랩은 로컬에서 웹 보안을 배울 때만 써요.

서비스:

- OWASP Juice Shop: http://localhost:3000
- DVWA: http://localhost:8080

시작:

```bash
robinctl lab start web
```

중지:

```bash
robinctl lab stop web
```

랩은 Docker로 돌아가서 시작하고 멈출 때 비밀번호를 물어봐요. RobinOS는 사용자를 `docker` 그룹에 넣지 않아요. 그 그룹에 들어가면 내 계정으로 도는 모든 프로그램이 비밀번호 없이 관리자 권한을 쓸 수 있게 되기 때문이에요.

두 앱은 일부러 취약하게 만든 프로그램이에요. 내 컴퓨터(`127.0.0.1`)에서만 열리지만, 브라우저로 다른 사이트를 보는 동안 켜 두면 그 사이트가 이 앱을 노릴 수도 있어요. 다 쓰면 `robinctl lab stop web`으로 꺼 두세요. 재부팅하면 저절로 다시 켜지지는 않아요.
