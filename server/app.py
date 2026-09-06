"""Tuitui Run leaderboard API for qrqto.club / tuitui-api."""
from __future__ import annotations

import os
import sqlite3
import time
from contextlib import contextmanager
from pathlib import Path
from typing import Any

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

DB_PATH = Path(os.environ.get("TUITUI_DB", str(Path(__file__).parent / "data" / "scores.db")))

app = FastAPI(title="Tuitui Run Scores", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class ScoreIn(BaseModel):
    player_id: str = Field(min_length=1, max_length=64)
    name: str = Field(default="推推", max_length=32)
    score: int = Field(ge=0, le=10_000_000)
    distance: int = Field(default=0, ge=0)
    coins: int = Field(default=0, ge=0)
    date: str | None = None


def _connect() -> sqlite3.Connection:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(DB_PATH)
    con.row_factory = sqlite3.Row
    return con


@contextmanager
def db() -> Any:
    con = _connect()
    try:
        yield con
        con.commit()
    finally:
        con.close()


def init_db() -> None:
    with db() as con:
        con.execute(
            """
            CREATE TABLE IF NOT EXISTS scores (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                player_id TEXT NOT NULL,
                name TEXT NOT NULL,
                score INTEGER NOT NULL,
                distance INTEGER NOT NULL,
                coins INTEGER NOT NULL,
                created_at TEXT NOT NULL
            )
            """
        )
        con.execute("CREATE INDEX IF NOT EXISTS idx_scores_player ON scores(player_id, score DESC)")
        con.execute("CREATE INDEX IF NOT EXISTS idx_scores_score ON scores(score DESC)")


@app.on_event("startup")
def _startup() -> None:
    init_db()


@app.get("/health")
@app.get("/v1/health")
def health() -> dict[str, str]:
    return {"ok": "tuitui", "ts": str(int(time.time()))}


@app.post("/v1/scores")
def post_score(body: ScoreIn) -> dict[str, Any]:
    created = body.date or time.strftime("%Y-%m-%d %H:%M:%S")
    with db() as con:
        con.execute(
            "INSERT INTO scores(player_id, name, score, distance, coins, created_at) VALUES (?,?,?,?,?,?)",
            (body.player_id.strip(), body.name.strip()[:32], body.score, body.distance, body.coins, created),
        )
        best = con.execute(
            "SELECT MAX(score) AS best FROM scores WHERE player_id = ?",
            (body.player_id.strip(),),
        ).fetchone()
    return {"ok": True, "best": int(best["best"] or 0)}


@app.get("/v1/scores/top")
def top_scores(limit: int = Query(default=20, ge=1, le=50)) -> list[dict[str, Any]]:
    with db() as con:
        rows = con.execute(
            """
            SELECT player_id, name, score, distance, coins, date FROM (
                SELECT player_id, name, score, distance, coins, created_at AS date,
                       ROW_NUMBER() OVER (
                           PARTITION BY player_id ORDER BY score DESC, id ASC
                       ) AS rn
                FROM scores
            )
            WHERE rn = 1
            ORDER BY score DESC
            LIMIT ?
            """,
            (limit,),
        ).fetchall()
    return [dict(r) for r in rows]


@app.get("/v1/scores/player/{player_id}")
def player_best(player_id: str) -> dict[str, Any]:
    with db() as con:
        row = con.execute(
            """
            SELECT player_id, name, score, distance, coins, created_at AS date
            FROM scores WHERE player_id = ?
            ORDER BY score DESC, id ASC LIMIT 1
            """,
            (player_id,),
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="no scores")
    return dict(row)


@app.post("/v1/scores/reset")
def reset_scores() -> dict[str, Any]:
    with db() as con:
        con.execute("DELETE FROM scores")
        n = con.execute("SELECT COUNT(*) AS n FROM scores").fetchone()
    return {"ok": True, "left": int(n["n"] or 0)}


@app.get("/v1/scores")
def recent(limit: int = Query(default=20, ge=1, le=100)) -> list[dict[str, Any]]:
    with db() as con:
        rows = con.execute(
            """
            SELECT player_id, name, score, distance, coins, created_at AS date
            FROM scores ORDER BY id DESC LIMIT ?
            """,
            (limit,),
        ).fetchall()
    return [dict(r) for r in rows]
