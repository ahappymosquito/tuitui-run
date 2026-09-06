# Tuitui Run 排行榜 API

给 `ts3@qrqto` / `qrqto.club` 用的 FastAPI。客户端写死：

`https://qrqto.club/tuitui-api/v1/scores`

## 接口

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/v1/health` | 探活 |
| POST | `/v1/scores` | 上报一局 `{player_id,name,score,distance,coins,date}` |
| GET | `/v1/scores/top?limit=20` | 每名玩家只取历史最高分，按分数降序 |
| GET | `/v1/scores/player/{id}` | 某玩家最高分 |
| GET | `/v1/scores` | 最近原始记录 |

## 本机

```
python -m venv .venv
.venv\Scripts\pip install -r requirements.txt
.venv\Scripts\uvicorn app:app --host 127.0.0.1 --port 8091
```

## 服务器（111.229.87.40 / ts3）

1. 把本目录拷到 `/home/ts3/tuitui-api`
2. `python3 -m venv .venv && .venv/bin/pip install -r requirements.txt`
3. `sudo cp tuitui-api.service /etc/systemd/system/`
4. nginx 的 `qrqto.club` server 里 include `nginx-tuitui-api.conf`
5. `sudo systemctl enable --now tuitui-api && sudo nginx -t && sudo nginx -s reload`
