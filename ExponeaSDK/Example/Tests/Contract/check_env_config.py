#!/usr/bin/env python3
"""Checks for the EXPONEA_* keys and the configuration form prefill rules."""

from __future__ import annotations

import sys

REQUIRED_KEYS = frozenset(
    {
        "EXPONEA_PROJECT_TOKEN",
        "EXPONEA_AUTHORIZATION_TOKEN",
        "EXPONEA_BASE_URL",
        "EXPONEA_CUSTOMER_ID",
        "EXPONEA_STREAM_ID",
        "EXPONEA_JWT_KEY_ID",
        "EXPONEA_JWT_SECRET",
        "EXPONEA_INTEGRATION_MODE",
        "EXPONEA_AUTO_CONFIGURE",
    }
)


def pick(saved: str, env: str, default: str = "") -> str:
    if saved.strip():
        return saved.strip()
    if env.strip():
        return env.strip()
    return default


def resolved_mode(
    integration_mode: str,
    stream_id: str,
    project_token: str,
    saved_mode: str = "",
) -> str:
    if saved_mode in ("project", "stream"):
        return saved_mode
    mode = integration_mode.strip().lower()
    if mode == "stream":
        return "stream"
    if not mode and stream_id.strip() and not project_token.strip():
        return "stream"
    return "project"


def should_auto_configure(auto_configure: str, mode: str, base_url: str, stream_id: str, project_token: str, auth_token: str) -> bool:
    if auto_configure.strip().lower() == "false":
        return False
    if not base_url.strip():
        return False
    if mode == "stream":
        return bool(stream_id.strip())
    return bool(project_token.strip() and auth_token.strip())


def main() -> int:
    example_path = sys.argv[1] if len(sys.argv) > 1 else None
    if example_path:
        import json
        from pathlib import Path

        data = json.loads(Path(example_path).read_text(encoding="utf-8"))
        missing = REQUIRED_KEYS - set(data.keys())
        if missing:
            print(f"FAIL credentials.example.json missing keys: {sorted(missing)}")
            return 1

    if pick("saved", "", "default") != "saved":
        print("FAIL pick prefers saved")
        return 1
    if pick("", "env", "default") != "env":
        print("FAIL pick uses env when saved empty")
        return 1
    if resolved_mode("stream", "", "") != "stream":
        print("FAIL resolved_mode from integration mode")
        return 1
    if resolved_mode("", "sid", "") != "stream":
        print("FAIL resolved_mode infers stream")
        return 1
    if not should_auto_configure("false", "stream", "https://x", "sid", "", ""):
        pass
    else:
        print("FAIL auto_configure false")
        return 1
    if not should_auto_configure("", "stream", "https://x", "sid", "", ""):
        print("FAIL auto_configure stream credentials")
        return 1

    print("PASS env config checks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
