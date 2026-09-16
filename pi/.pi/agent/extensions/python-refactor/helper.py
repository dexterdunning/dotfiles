#!/usr/bin/env python3
"""LibCST-backed helpers for Pi Python refactor extension.

Protocol: read JSON from stdin with {action, ...}; write JSON to stdout.
"""
from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import libcst as cst
from libcst.metadata import MetadataWrapper, PositionProvider


@dataclass(frozen=True)
class Member:
    index: int
    node: cst.CSTNode
    name: str
    kind: str
    start_line: int
    end_line: int


def _load_payload() -> dict[str, Any]:
    try:
        return json.load(sys.stdin)
    except Exception as exc:
        raise SystemExit(json.dumps({"ok": False, "error": f"Invalid JSON stdin: {exc}"}))


def _read_module(path: Path) -> tuple[str, cst.Module]:
    source = path.read_text()
    return source, cst.parse_module(source)


def _member_name(stmt: cst.CSTNode) -> tuple[str, str] | None:
    if isinstance(stmt, cst.FunctionDef):
        return stmt.name.value, "function"
    if isinstance(stmt, cst.ClassDef):
        return stmt.name.value, "class"
    return None


def _members_from_body(body: tuple[cst.BaseStatement, ...], positions: dict[cst.CSTNode, Any]) -> list[Member]:
    members: list[Member] = []
    for i, stmt in enumerate(body):
        named = _member_name(stmt)
        if not named:
            continue
        name, kind = named
        pos = positions[stmt]
        members.append(Member(i, stmt, name, kind, pos.start.line, pos.end.line))
    return members


def _wrapped_module_and_positions(module: cst.Module) -> tuple[cst.Module, dict[cst.CSTNode, Any]]:
    # MetadataWrapper deep-clones by default; use wrapper.module for nodes that
    # match PositionProvider keys and for subsequent transformations.
    wrapper = MetadataWrapper(module)
    return wrapper.module, wrapper.resolve(PositionProvider)


def _top_level_members(module: cst.Module) -> tuple[cst.Module, list[Member]]:
    wrapped_module, positions = _wrapped_module_and_positions(module)
    return wrapped_module, _members_from_body(tuple(wrapped_module.body), positions)


def _find_top_level_class(module: cst.Module, class_name: str) -> cst.ClassDef | None:
    for stmt in module.body:
        if isinstance(stmt, cst.ClassDef) and stmt.name.value == class_name:
            return stmt
    return None


def _class_members(module: cst.Module, class_name: str) -> tuple[cst.Module, cst.ClassDef, list[Member]]:
    wrapped_module, positions = _wrapped_module_and_positions(module)
    cls = _find_top_level_class(wrapped_module, class_name)
    if cls is None:
        raise ValueError(f"No top-level class named {class_name!r}")
    if not isinstance(cls.body, cst.IndentedBlock):
        raise ValueError(f"Class {class_name!r} does not have a normal indented body")
    return wrapped_module, cls, _members_from_body(tuple(cls.body.body), positions)


def _symbol_json(m: Member) -> dict[str, Any]:
    return {
        "name": m.name,
        "kind": m.kind,
        "startLine": m.start_line,
        "endLine": m.end_line,
    }


def list_symbols(path: Path) -> dict[str, Any]:
    source, module = _read_module(path)
    _module, members = _top_level_members(module)
    return {
        "ok": True,
        "file": str(path),
        "symbols": [_symbol_json(m) for m in members],
        "lineCount": source.count("\n") + 1,
    }


def list_class_symbols(path: Path, class_name: str) -> dict[str, Any]:
    source, module = _read_module(path)
    _module, _cls, members = _class_members(module, class_name)
    return {
        "ok": True,
        "file": str(path),
        "className": class_name,
        "symbols": [_symbol_json(m) for m in members],
        "lineCount": source.count("\n") + 1,
    }


def _ordered_members(members: list[Member], order: list[str], alphabetical: bool = False) -> list[Member]:
    if alphabetical:
        return sorted(members, key=lambda m: (m.kind, m.name.lower(), m.start_line))

    rank = {name: i for i, name in enumerate(order)}
    return sorted(members, key=lambda m: (rank.get(m.name, len(rank)), m.start_line))


def _reordered_body(body: tuple[cst.BaseStatement, ...], members: list[Member], sorted_members: list[Member]) -> list[cst.BaseStatement]:
    replacement_by_slot: dict[int, cst.CSTNode] = {}
    sorted_iter = iter(sorted_members)
    member_slots = {m.index for m in members}
    for i, _stmt in enumerate(body):
        if i in member_slots:
            replacement_by_slot[i] = next(sorted_iter).node
    return [replacement_by_slot.get(i, stmt) for i, stmt in enumerate(body)]  # type: ignore[list-item]


def sort_members(path: Path, order: list[str] | None, alphabetical: bool, dry_run: bool) -> dict[str, Any]:
    _source, module = _read_module(path)
    module, members = _top_level_members(module)
    if not members:
        return {"ok": True, "changed": False, "message": "No top-level functions/classes found."}

    sorted_members = _ordered_members(members, order or [], alphabetical)
    if [m.name for m in members] == [m.name for m in sorted_members]:
        return {
            "ok": True,
            "changed": False,
            "file": str(path),
            "order": [m.name for m in members],
            "message": "Top-level member order already matches requested order.",
        }

    new_body = _reordered_body(tuple(module.body), members, sorted_members)
    new_module = module.with_changes(body=new_body)
    if not dry_run:
        path.write_text(new_module.code)

    return {
        "ok": True,
        "changed": True,
        "dryRun": dry_run,
        "file": str(path),
        "oldOrder": [m.name for m in members],
        "newOrder": [m.name for m in sorted_members],
    }


def _move_order(names: list[str], name: str, before: str | None, after: str | None, label: str) -> list[str] | dict[str, Any]:
    if name not in names:
        return {"ok": False, "error": f"No {label} member named {name!r}. Available: {names}"}
    if bool(before) == bool(after):
        return {"ok": False, "error": "Specify exactly one of before or after."}
    order = [n for n in names if n != name]
    target = before or after
    if target not in order:
        return {"ok": False, "error": f"Target member {target!r} not found. Available: {names}"}
    idx = order.index(target)
    if after:
        idx += 1
    order.insert(idx, name)
    return order


def move_member(path: Path, name: str, before: str | None, after: str | None, dry_run: bool) -> dict[str, Any]:
    _source, module = _read_module(path)
    _module, members = _top_level_members(module)
    order = _move_order([m.name for m in members], name, before, after, "top-level")
    if isinstance(order, dict):
        return order
    return sort_members(path, order, alphabetical=False, dry_run=dry_run)


class _ReplaceClass(cst.CSTTransformer):
    def __init__(self, class_name: str, replacement: cst.ClassDef):
        self.class_name = class_name
        self.replacement = replacement

    def leave_ClassDef(self, original_node: cst.ClassDef, updated_node: cst.ClassDef) -> cst.ClassDef:
        if original_node.name.value == self.class_name:
            return self.replacement
        return updated_node


def sort_class_members(path: Path, class_name: str, order: list[str] | None, alphabetical: bool, dry_run: bool) -> dict[str, Any]:
    _source, module = _read_module(path)
    module, cls, members = _class_members(module, class_name)
    if not members:
        return {"ok": True, "changed": False, "message": f"No methods/nested classes found in {class_name}."}

    sorted_members = _ordered_members(members, order or [], alphabetical)
    if [m.name for m in members] == [m.name for m in sorted_members]:
        return {
            "ok": True,
            "changed": False,
            "file": str(path),
            "className": class_name,
            "order": [m.name for m in members],
            "message": "Class member order already matches requested order.",
        }

    assert isinstance(cls.body, cst.IndentedBlock)
    new_class_body = cls.body.with_changes(body=_reordered_body(tuple(cls.body.body), members, sorted_members))
    replacement = cls.with_changes(body=new_class_body)
    new_module = module.visit(_ReplaceClass(class_name, replacement))
    if not dry_run:
        path.write_text(new_module.code)

    return {
        "ok": True,
        "changed": True,
        "dryRun": dry_run,
        "file": str(path),
        "className": class_name,
        "oldOrder": [m.name for m in members],
        "newOrder": [m.name for m in sorted_members],
    }


def move_class_member(path: Path, class_name: str, name: str, before: str | None, after: str | None, dry_run: bool) -> dict[str, Any]:
    _source, module = _read_module(path)
    _module, _cls, members = _class_members(module, class_name)
    order = _move_order([m.name for m in members], name, before, after, f"{class_name}")
    if isinstance(order, dict):
        return order
    return sort_class_members(path, class_name, order, alphabetical=False, dry_run=dry_run)


def main() -> None:
    payload = _load_payload()
    try:
        action = payload["action"]
        path = Path(payload["file"]).expanduser().resolve()
        if not path.exists():
            raise FileNotFoundError(str(path))
        if action == "list_symbols":
            result = list_symbols(path)
        elif action == "list_class_symbols":
            result = list_class_symbols(path, payload["className"])
        elif action == "sort_members":
            result = sort_members(
                path,
                payload.get("order"),
                bool(payload.get("alphabetical", False)),
                bool(payload.get("dryRun", False)),
            )
        elif action == "move_member":
            result = move_member(
                path,
                payload["name"],
                payload.get("before"),
                payload.get("after"),
                bool(payload.get("dryRun", False)),
            )
        elif action == "sort_class_members":
            result = sort_class_members(
                path,
                payload["className"],
                payload.get("order"),
                bool(payload.get("alphabetical", False)),
                bool(payload.get("dryRun", False)),
            )
        elif action == "move_class_member":
            result = move_class_member(
                path,
                payload["className"],
                payload["name"],
                payload.get("before"),
                payload.get("after"),
                bool(payload.get("dryRun", False)),
            )
        else:
            result = {"ok": False, "error": f"Unknown action: {action}"}
    except Exception as exc:
        result = {"ok": False, "error": f"{type(exc).__name__}: {exc}"}
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
