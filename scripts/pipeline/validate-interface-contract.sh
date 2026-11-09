#!/usr/bin/env bash
# =============================================================================
# scripts/pipeline/validate-interface-contract.sh
# =============================================================================
# Wrapper executável para scripts/pipeline/validate-interface-contract.py
# Valida a conformidade do Interface Contract (Signatures, Types/Interfaces,
# Inputs, Outputs, Errors) em implementation_plan.md ou propostas de issue.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

exec "$PYTHON_BIN" "$SCRIPT_DIR/validate-interface-contract.py" "$@"
