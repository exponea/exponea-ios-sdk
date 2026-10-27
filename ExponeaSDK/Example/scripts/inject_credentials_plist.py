#!/usr/bin/env python3
"""Merge credentials.json keys into a built app Info.plist (install-time injection)."""

from __future__ import annotations

import json
import plistlib
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: inject_credentials_plist.py <Info.plist> <credentials.json>", file=sys.stderr)
        return 2

    plist_path = Path(sys.argv[1])
    credentials_path = Path(sys.argv[2])

    if not plist_path.is_file():
        print(f"error: plist not found: {plist_path}", file=sys.stderr)
        return 1
    if not credentials_path.is_file():
        print(f"skip: no credentials file at {credentials_path}")
        return 0

    with credentials_path.open(encoding="utf-8") as handle:
        payload = json.load(handle)

    if not isinstance(payload, dict):
        print("error: credentials.json must be a JSON object", file=sys.stderr)
        return 1

    with plist_path.open("rb") as handle:
        plist = plistlib.load(handle)

    injected = 0
    for key, value in payload.items():
        if not isinstance(key, str) or not key.startswith("EXPONEA_"):
            continue
        if not isinstance(value, str):
            continue
        plist[key] = value
        injected += 1

    with plist_path.open("wb") as handle:
        plistlib.dump(plist, handle)

    print(f"injected {injected} EXPONEA_* key(s) into {plist_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
