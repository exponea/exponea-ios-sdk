#!/usr/bin/env python3
"""Checks for ConfigureRequest validation rules: trimming, URL scheme and host, required fields."""
from __future__ import annotations

import sys
from urllib.parse import urlparse


def is_base_url_valid(base_url: str) -> bool:
    trimmed = base_url.strip()
    if not trimmed:
        return False
    parsed = urlparse(trimmed)
    return (
        parsed.scheme in ("http", "https")
        and parsed.netloc
        and parsed.hostname
    )


def is_jwt_pair_valid(key: str, secret: str) -> bool:
    return key.strip() == "" == secret.strip() or (
        key.strip() != "" and secret.strip() != ""
    )


def is_stream_valid(base_url: str, stream_id: str, key: str, secret: str) -> bool:
    return (
        is_jwt_pair_valid(key, secret)
        and is_base_url_valid(base_url)
        and stream_id.strip() != ""
    )


def main() -> int:
    cases = [
        (
            "stream_ok_with_jwt",
            True,
            is_stream_valid(
                "https://api.exponea.com",
                "235e574e-4f6f-47fb-861b-186b2a1f0c9d",
                "key-id",
                "secret",
            ),
        ),
        (
            "stream_ok_without_jwt",
            True,
            is_stream_valid(
                "https://api.exponea.com",
                "stream-id",
                "",
                "",
            ),
        ),
        (
            "stream_trailing_space_url_trimmed",
            True,
            is_stream_valid(
                "https://api.exponea.com ",
                "stream-id",
                "key",
                "secret",
            ),
        ),
        (
            "stream_invalid_url",
            False,
            is_stream_valid(
                "not-a-url",
                "stream-id",
                "key",
                "secret",
            ),
        ),
        (
            "stream_jwt_mismatch",
            False,
            is_stream_valid(
                "https://api.exponea.com",
                "stream-id",
                "key",
                "",
            ),
        ),
        (
            "stream_missing_id",
            False,
            is_stream_valid(
                "https://api.exponea.com",
                "",
                "key",
                "secret",
            ),
        ),
    ]

    failed = []
    for name, expected, actual in cases:
        if actual != expected:
            failed.append(f"{name}: expected {expected}, got {actual}")

    if failed:
        print("FAIL configure request validation")
        for line in failed:
            print(line)
        return 1

    print("PASS configure request validation")
    return 0


if __name__ == "__main__":
    sys.exit(main())
