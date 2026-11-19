#!/usr/bin/env python3
"""Minimal online leaderboard for Keepy Pro (روپایی پرو)."""

from __future__ import annotations

import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "leaderboard.json"
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8787


def load_board() -> list:
    if not DATA.exists():
        return []
    try:
        return json.loads(DATA.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return []


def save_board(rows: list) -> None:
    rows = sorted(rows, key=lambda r: int(r.get("score", 0)), reverse=True)[:100]
    DATA.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")


class Handler(BaseHTTPRequestHandler):
    def _cors(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self) -> None:  # noqa: N802
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        if path in ("/leaderboard", "/"):
            body = json.dumps(load_board(), ensure_ascii=False).encode("utf-8")
            self.send_response(200)
            self._cors()
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self.send_response(404)
        self._cors()
        self.end_headers()

    def do_POST(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        if path != "/score":
            self.send_response(404)
            self._cors()
            self.end_headers()
            return
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length)
        try:
            data = json.loads(raw.decode("utf-8"))
            name = str(data.get("name", "بازیکن"))[:16]
            score = int(data.get("score", 0))
        except (json.JSONDecodeError, ValueError, TypeError):
            self.send_response(400)
            self._cors()
            self.end_headers()
            return
        rows = load_board()
        rows.append({"name": name, "score": score})
        # keep best per name
        best: dict[str, int] = {}
        for row in rows:
            n = str(row.get("name", ""))
            s = int(row.get("score", 0))
            best[n] = max(best.get(n, 0), s)
        merged = [{"name": n, "score": s} for n, s in best.items()]
        save_board(merged)
        body = b'{"ok":true}'
        self.send_response(200)
        self._cors()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("[keepy] " + (fmt % args) + "\n")


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"Keepy Pro leaderboard on http://127.0.0.1:{PORT}")
    server.serve_forever()
