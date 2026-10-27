#!/usr/bin/env python3
"""Compare automation manifest identifiers with the example app Swift accessibility IDs."""

from __future__ import annotations

import importlib.util
import re
import sys
from pathlib import Path

ACCESSIBILITY_LITERAL = re.compile(r"accessibilityIdentifier\s*\(\s*\"([^\"]+)\"")
A11Y_STATIC_LITERAL = re.compile(r"static let \w+\s*=\s*\"([^\"]+)\"")
GAP_ENTRY = re.compile(r"^  ([a-z][a-z0-9_]*):\s*$")
GAP_OWNER = re.compile(r"^    owner:\s*([a-z0-9-]+)\s*$")


def load_checker_module(checker_path: Path):
    spec = importlib.util.spec_from_file_location("manifest_integrity", checker_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def collect_manifest_ids(manifest_path: Path, checker_path: Path) -> tuple[set[str], list[str]]:
    module = load_checker_module(checker_path)
    capabilities, errors = module.parse_capability_semantics(manifest_path)
    ids: set[str] = set()
    for _, semantic_ids in capabilities:
        ids.update(semantic_ids)
    return ids, errors


def collect_swift_accessibility_ids(source_root: Path) -> set[str]:
    ids: set[str] = set()
    for swift_file in source_root.rglob("*.swift"):
        posix = swift_file.as_posix()
        if "/Example/Tests/" in posix and "/fixtures/swift_source_fixture/" not in posix:
            continue
        text = swift_file.read_text(encoding="utf-8")
        for pattern in (ACCESSIBILITY_LITERAL, A11Y_STATIC_LITERAL):
            ids.update(match.group(1) for match in pattern.finditer(text))
    return ids


def parse_known_gaps(gaps_path: Path) -> tuple[dict[str, str], list[str]]:
    errors: list[str] = []
    gaps: dict[str, str] = {}
    if not gaps_path.is_file():
        return gaps, [f"known gaps file not found: {gaps_path}"]

    current_id: str | None = None
    for line_number, line in enumerate(gaps_path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        entry_match = GAP_ENTRY.match(line)
        if entry_match:
            current_id = entry_match.group(1)
            if current_id in gaps:
                errors.append(f"line {line_number}: duplicate known gap '{current_id}'")
            gaps[current_id] = ""
            continue

        owner_match = GAP_OWNER.match(line)
        if owner_match and current_id is not None:
            gaps[current_id] = owner_match.group(1)
            current_id = None
            continue

        if stripped == "gaps:":
            continue

        errors.append(f"line {line_number}: unrecognized known-gap entry")

    for gap_id, owner in gaps.items():
        if not owner:
            errors.append(f"known gap '{gap_id}' is missing owner tag")

    return gaps, errors


def check_coverage(
    manifest_path: Path,
    gaps_path: Path,
    source_root: Path,
    checker_path: Path,
) -> tuple[list[str], list[str], list[str]]:
    errors: list[str] = []
    pending: list[str] = []

    manifest_ids, manifest_errors = collect_manifest_ids(manifest_path, checker_path)
    errors.extend(manifest_errors)

    known_gaps, gap_errors = parse_known_gaps(gaps_path)
    errors.extend(gap_errors)

    swift_ids = collect_swift_accessibility_ids(source_root)

    for gap_id in sorted(known_gaps):
        if gap_id in swift_ids:
            errors.append(
                f"stale known gap '{gap_id}' (implemented in Swift; remove from allowlist)"
            )

    for semantic_id in sorted(manifest_ids):
        if semantic_id in swift_ids:
            continue
        owner = known_gaps.get(semantic_id)
        if owner:
            pending.append(f"PENDING {semantic_id} (owner: {owner})")
        else:
            errors.append(f"unknown missing identifier '{semantic_id}' (not in Swift and not allowlisted)")

    return errors, pending, sorted(swift_ids)


def main() -> int:
    script_dir = Path(__file__).resolve().parent
    example_root = script_dir.parent.parent
    default_manifest = script_dir / "automation_contract.yaml"
    default_gaps = script_dir / "known_identifier_gaps.yaml"
    default_checker = script_dir / "check_manifest_integrity.py"

    manifest_path = Path(sys.argv[1]) if len(sys.argv) > 1 else default_manifest
    gaps_path = Path(sys.argv[2]) if len(sys.argv) > 2 else default_gaps
    source_root = Path(sys.argv[3]) if len(sys.argv) > 3 else example_root

    errors, pending, _ = check_coverage(
        manifest_path=manifest_path,
        gaps_path=gaps_path,
        source_root=source_root,
        checker_path=default_checker,
    )

    for item in pending:
        print(item)

    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        return 1

    print(f"PASS identifier coverage: {manifest_path}")
    if pending:
        print(f"  {len(pending)} known gap(s) pending implementation")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
