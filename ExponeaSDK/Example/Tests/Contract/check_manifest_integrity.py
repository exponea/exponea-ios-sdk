#!/usr/bin/env python3
"""Validate automation_contract.yaml manifest integrity (stdlib only)."""

from __future__ import annotations

import re
import sys
from collections import Counter
from pathlib import Path

SEMANTIC_ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
CAPABILITY_HEADER = re.compile(r"^  ([a-z0-9-]+):\s*$")
STRING_ENTRY = re.compile(r"^\s+-\s+([^\s#]+)\s*$")
DICT_ID_ENTRY = re.compile(r"^\s+-\s+id:\s*(.*)$")


def parse_capability_semantics(path: Path) -> tuple[list[tuple[str, list[str]]], list[str]]:
    """Parse semantic identifiers grouped by capability from the constrained YAML."""
    errors: list[str] = []
    capabilities: list[tuple[str, list[str]]] = []
    current_capability: str | None = None
    current_ids: list[str] = []
    in_semantics = False
    semantics_indent: int | None = None

    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        return capabilities, [f"cannot read manifest: {exc}"]

    if not any(line.strip() == "capabilities:" for line in lines):
        errors.append("missing root key 'capabilities'")
        return capabilities, errors

    def flush_capability() -> None:
        nonlocal current_capability, current_ids
        if current_capability is not None:
            capabilities.append((current_capability, current_ids))
        current_capability = None
        current_ids = []

    for line_number, line in enumerate(lines, start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        capability_match = CAPABILITY_HEADER.match(line)
        if capability_match:
            flush_capability()
            current_capability = capability_match.group(1)
            in_semantics = False
            semantics_indent = None
            continue

        semantics_match = re.match(r"^(\s+)semantics:\s*$", line)
        if semantics_match and current_capability is not None:
            in_semantics = True
            semantics_indent = len(semantics_match.group(1))
            continue

        if not in_semantics or semantics_indent is None or current_capability is None:
            continue

        indent = len(line) - len(line.lstrip(" "))
        if indent <= semantics_indent:
            in_semantics = False
            semantics_indent = None
            continue

        dict_match = DICT_ID_ENTRY.match(line)
        if dict_match:
            raw_id = dict_match.group(1).strip()
            if not raw_id:
                errors.append(
                    f"capability '{current_capability}' line {line_number}: empty semantic id in 'id:' entry"
                )
            else:
                current_ids.append(raw_id)
            continue

        string_match = STRING_ENTRY.match(line)
        if string_match:
            candidate = string_match.group(1)
            if candidate == "id:" or candidate.startswith("id:"):
                continue
            current_ids.append(candidate)

    flush_capability()
    return capabilities, errors


def validate_semantic_id(raw_id: str, context: str) -> list[str]:
    errors: list[str] = []
    if not raw_id or not raw_id.strip():
        errors.append(f"{context}: empty semantic identifier")
        return errors
    if not SEMANTIC_ID_PATTERN.match(raw_id):
        errors.append(f"{context}: malformed semantic identifier '{raw_id}'")
    return errors


def validate_manifest(path: Path) -> list[str]:
    capability_semantics, parse_errors = parse_capability_semantics(path)
    errors = list(parse_errors)

    if not capability_semantics and not parse_errors:
        errors.append("manifest contains no capabilities")

    for capability, ids in capability_semantics:
        context_prefix = f"capability '{capability}'"
        if not ids:
            errors.append(f"{context_prefix}: semantics list is empty")
            continue

        for semantic_id in ids:
            errors.extend(validate_semantic_id(semantic_id, f"identifier '{semantic_id}' in {context_prefix}"))

        counts = Counter(ids)
        for semantic_id, count in sorted(counts.items()):
            if count > 1:
                errors.append(
                    f"duplicate semantic identifier '{semantic_id}' in {context_prefix} ({count} occurrences)"
                )

    return errors


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: check_manifest_integrity.py <automation_contract.yaml>", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    if not path.is_file():
        print(f"FAIL: manifest not found: {path}", file=sys.stderr)
        return 1

    errors = validate_manifest(path)
    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        return 1

    print(f"PASS manifest integrity: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
