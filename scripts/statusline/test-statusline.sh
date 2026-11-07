#!/usr/bin/env bash
set -euo pipefail

# scripts/statusline/test-statusline.sh: Executa a validação e benchmark automatizado sub-50ms da statusline
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/../../tests/features/statusline/test_statusline.sh" "$@"
