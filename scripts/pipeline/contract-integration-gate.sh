#!/usr/bin/env bash
# =============================================================================
# scripts/pipeline/contract-integration-gate.sh
# =============================================================================
# Wrapper executável para scripts/pipeline/contract-integration-gate.py
# Valida a convergência do Join Point entre testes em tests/features/ e código
# em src/, gerenciando o loop de reconciliação de até 2 iterações e fail-safe.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

exec "$PYTHON_BIN" "$SCRIPT_DIR/contract-integration-gate.py" "$@"
