#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_ROOT="$(cd "${ROOT}/../../" && pwd)"
python3 "${ROOT}/check_env_config.py" "${EXAMPLE_ROOT}/Resources/credentials.example.json"
