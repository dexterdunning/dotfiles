"""Shared helpers for local review comment scripts."""

from __future__ import annotations

import json
import subprocess
from pathlib import Path


def git_root() -> Path:
    out = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        check=False,
        capture_output=True,
        text=True,
    )
    if out.returncode != 0:
        raise SystemExit("not inside a git repository")
    return Path(out.stdout.strip())


def comments_path(root: Path | None = None) -> Path:
    root = root or git_root()
    return root / ".review.local.jsonl"


def load_comments(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    comments: list[dict] = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            item = json.loads(line)
        except json.JSONDecodeError:
            continue
        if item.get("path") and item.get("line"):
            comments.append(item)
    return comments


def write_comments(path: Path, comments: list[dict]) -> None:
    if not comments:
        if path.is_file():
            path.unlink()
        return
    path.write_text("".join(json.dumps(item) + "\n" for item in comments))
