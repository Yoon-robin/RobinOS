# RobinOS 네트워크 스캔 랩

내 컴퓨터 안에 작은 가상 네트워크(172.30.66.0/24)를 만들고, 그 안의 컴퓨터를 nmap으로 찾아보는 랩이에요. 학습 미션 6, 9, 10(IP 주소, 포트, 내 컴퓨터 스캔)의 다음 단계예요.

| 주소 | 컨테이너 | 하는 일 |
|---|---|---|
| 172.30.66.10 | `nginx:1.27-alpine` | 80번 포트의 웹 서버. 페이지에 코드가 있어요 |
| 172.30.66.20 | `redis:7.4-alpine` | 6379번 포트의 캐시 서버. 기본 보호 모드라 밖에서 온 명령은 거절해요 |
| 172.30.66.30 | `alpine:3.20` | nmap 기본 스캔(흔한 1000개)에 안 나오는 31337번 포트에서 배너를 보여 줘요 |
| 172.30.66.40 | `alpine:3.20` | 켜져 있지만 열린 포트가 없어요. 호스트 찾기에만 나와요 |

호스트(내 컴퓨터)의 포트로는 아무것도 열지 않아요. 그래서 같은 와이파이나 회사 네트워크의 다른 컴퓨터에서는 이 랩에 닿지 않아요. 이미지는 버전을 고정해 뒀고, 재부팅하면 저절로 켜지지 않아요.

nmap(network 프로필)과 Docker(web 프로필)가 필요해요.

```bash
sudo robinctl profile network
sudo robinctl profile web
robinctl lab start net
robinctl lab info net      # 해 볼 것 여섯 단계
robinctl lab stop net
```

시작하고 멈출 때 Docker 때문에 비밀번호를 물어봐요(웹 랩과 같은 이유예요, [../web/README.md](../web/README.md)). 스캔은 이 랩처럼 내 것이거나 허락받은 네트워크에서만 해요([docs/ethics.md](../../docs/ethics.md)).
