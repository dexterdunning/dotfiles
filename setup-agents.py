#!/usr/bin/env python3
"""Compose portable agent sources and optional private overrides into a home directory."""
from __future__ import annotations

import argparse
import json
import os
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


_REPO = Path(__file__).resolve().parent


def _json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    value = json.loads(path.read_text())
    if not isinstance(value, dict):
        raise TypeError(f"Expected a JSON object: {path}")
    return value


def _merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    """Merge objects recursively; private scalars and arrays replace public values."""
    result = base.copy()
    for key, value in override.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = _merge(result[key], value)
        else:
            result[key] = value
    return result


def _text(*paths: Path) -> str:
    return "\n\n".join(path.read_text().strip() for path in paths if path.exists()) + "\n"


class _Installer:
    def __init__(self, home: Path) -> None:
        self.home = home
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
        self.backups = home / ".local/state/dotfiles/backups" / stamp
        self.changed = 0
        self._backup_count = 0

    def _backup(self, path: Path) -> None:
        if path.exists() or path.is_symlink():
            self._backup_count += 1
            backup = self.backups / f"{self._backup_count:04d}" / path.relative_to(self.home)
            backup.parent.mkdir(parents=True, exist_ok=True)
            path.rename(backup)

    def directory(self, path: Path) -> None:
        if path.is_dir() and not path.is_symlink():
            return
        self.directory(path.parent)
        if path.is_symlink():
            source = path.resolve()
            children = list(source.iterdir()) if source.is_dir() else []
            self._backup(path)
            path.mkdir()
            for child in children:
                (path / child.name).symlink_to(child)
            self.changed += 1
        elif path.exists():
            raise ValueError(f"Expected a directory, found a file: {path}")
        else:
            path.mkdir()

    def file(self, path: Path, content: str) -> None:
        if not path.is_symlink() and path.is_file() and path.read_text() == content:
            return
        self.directory(path.parent)
        self._backup(path)
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as temporary:
            temporary.write(content)
            temporary_path = Path(temporary.name)
        os.replace(temporary_path, path)
        self.changed += 1

    def link(self, path: Path, source: Path) -> None:
        if path.is_symlink() and Path(os.readlink(path)) == source:
            return
        self.directory(path.parent)
        self._backup(path)
        path.symlink_to(source, target_is_directory=source.is_dir())
        self.changed += 1


def _plan(home: Path, private: Path | None, profile: str) -> tuple[dict[Path, str], dict[Path, Path]]:
    public_agents = _REPO / "agents/.agents"
    public_pi = _REPO / "pi/.pi/agent"
    public_omp = _REPO / "omp"
    private_agents = private / "agents" if private else None
    private_pi = private / "pi" if private else None
    private_omp = private / "omp" if private else None
    agent_home = home / ".agents"
    pi_home = home / ".pi/agent"
    omp_home = home / ".omp" / "profiles" / profile / "agent" if profile else home / ".omp/agent"
    files: dict[Path, str] = {}
    links: dict[Path, Path] = {}

    instructions = [public_agents / "AGENTS.md"]
    if private_agents:
        instructions.append(private_agents / "AGENTS.md")
    files[agent_home / "AGENTS.md"] = _text(*instructions)
    pi_instructions = files[agent_home / "AGENTS.md"]
    if private_pi and (private_pi / "AGENTS.md").exists():
        pi_instructions += "\n" + _text(private_pi / "AGENTS.md")
    files[pi_home / "AGENTS.md"] = pi_instructions
    links[omp_home / "AGENTS.md"] = agent_home / "AGENTS.md"

    for name in ["settings.json", "title-renamer.json", "context-prune/settings.json"]:
        override = _json(private_pi / name) if private_pi else {}
        files[pi_home / name] = json.dumps(_merge(_json(public_pi / name), override), indent=2) + "\n"
    override = _json(private_omp / "config.json") if private_omp else {}
    files[omp_home / "config.yml"] = json.dumps(_merge(_json(public_omp / "config.json"), override), indent=2) + "\n"
    append = [public_omp / "APPEND_SYSTEM.md"]
    if private_omp:
        append.append(private_omp / "APPEND_SYSTEM.md")
    files[omp_home / "APPEND_SYSTEM.md"] = _text(*append)
    links[pi_home / "pi-vimmode.config.js"] = public_pi / "pi-vimmode.config.js"

    sources = [public_agents / "skills"]
    if private_agents:
        sources.append(private_agents / "skills")
    skill_names: set[str] = set()
    for source_root in sources:
        if not source_root.is_dir():
            continue
        for source in sorted(source_root.iterdir()):
            if not (source / "SKILL.md").is_file():
                continue
            if source.name in skill_names:
                raise ValueError(f"Duplicate public/private skill: {source.name}")
            skill_names.add(source.name)
            links[agent_home / "skills" / source.name] = source

    if private_agents and (private_agents / "skill-overrides").is_dir():
        for source in sorted((private_agents / "skill-overrides").iterdir()):
            if source.is_dir() and (source / "instructions.md").is_file():
                links[agent_home / "skill-overrides" / source.name] = source

    for public, personal, destination in [(public_pi, private_pi, pi_home), (public_omp, private_omp, omp_home)]:
        for root in [public / "extensions", personal / "extensions" if personal else None]:
            if root and root.is_dir():
                for source in sorted(root.iterdir()):
                    if not source.name.startswith("."):
                        links[destination / "extensions" / source.name] = source
    if private_pi and (private_pi / "files").is_dir():
        for source in sorted((private_pi / "files").rglob("*")):
            if source.is_file():
                links[pi_home / source.relative_to(private_pi / "files")] = source
    if private and (private / "zsh/work.zsh").is_file():
        links[home / ".config/dotfiles/work.zsh"] = private / "zsh/work.zsh"

    # Only migrate existing harness links; leave local copies and unrelated resources alone.
    roots = [home / ".pi/agent/skills", home / ".claude/skills", home / ".cursor/skills", home / ".codex/skills"]
    source_roots = sources + [home / ".agents/skills"]
    for root in roots + [home / ".claude/commands"]:
        if not root.is_dir():
            continue
        for entry in root.iterdir():
            if not entry.is_symlink():
                continue
            target = entry.resolve()
            if not any(target.is_relative_to(source.resolve()) for source in source_roots):
                continue
            name = entry.stem if root.name == "commands" else entry.name
            if name in skill_names:
                links[entry] = agent_home / "skills" / name / "SKILL.md" if root.name == "commands" else agent_home / "skills" / name
    return files, links


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--home", type=Path, default=Path.home(), help="Destination home; use a temporary directory for a smoke install")
    parser.add_argument("--private", type=Path, help="Optional private sources outside this repository (never inferred)")
    parser.add_argument("--omp-profile", default="", help="Named OMP profile; omit to configure ~/.omp/agent")
    parser.add_argument("--apply", action="store_true", help="Apply the plan; otherwise only report what would be managed")
    args = parser.parse_args()
    home = args.home.expanduser().resolve()
    private = args.private.expanduser().resolve() if args.private else None
    if private and (not private.is_dir() or private.is_relative_to(_REPO)):
        parser.error("--private must be an existing directory outside the public repository")
    if args.omp_profile and (args.omp_profile in {".", ".."} or "/" in args.omp_profile or "\\" in args.omp_profile):
        parser.error("--omp-profile must be a profile name, not a path")
    files, links = _plan(home, private, args.omp_profile)
    print(f"{'Applying' if args.apply else 'Previewing'} {'public + private' if private else 'public-only'} setup: {len(files)} generated files, {len(links)} links")
    print(f"Destination: {home}; OMP profile: {args.omp_profile or '(default)'}")
    if not args.apply:
        print("No files changed. Add --apply to install; existing managed paths are backed up locally.")
        return
    home.mkdir(parents=True, exist_ok=True)
    installer = _Installer(home)
    for path, content in files.items():
        installer.file(path, content)
    for path, source in links.items():
        installer.link(path, source)
    print(f"Changed {installer.changed} paths. Backups, when needed: {installer.backups}")
    print("Auth, MCP configuration, sessions, caches, and package installations were not modified.")


if __name__ == "__main__":
    main()
