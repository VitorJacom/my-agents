#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Suite de Testes: Links Relativos em scripts/README.md e Contratos CLI (Issue #602)
# Valida a ausencia de links locais file:// e o alinhamento da documentacao com
# os contratos reais de metrics-collector.py e worktree-manager.sh.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SCRIPTS_README="$REPO_ROOT/scripts/README.md"
TROUBLESHOOTING_DOC="$REPO_ROOT/docs/Troubleshooting.md"

FAILURES=0

pass() {
  echo "  [PASS] $1"
}

fail() {
  echo "  [FAIL] $1" >&2
  FAILURES=$((FAILURES + 1))
}

echo "=================================================================="
echo " Running Scripts README & Troubleshooting Links Test Suite"
echo "=================================================================="

# ------------------------------------------------------------------------------
# 1. HAPPY PATH: Links relativos validos e contratos CLI documentados
# ------------------------------------------------------------------------------
echo ""
echo "[Happy Path] 1. Validando links relativos e existencia fisica em scripts/README.md..."

EXPECTED_RELATIVE_LINKS=(
  "hooks/safety-guard.sh"
  "hooks/session-start-context.sh"
  "statusline/install-statusline.sh"
  "statusline/statusline-quota.sh"
  "statusline/test-statusline.sh"
)

for rel_link in "${EXPECTED_RELATIVE_LINKS[@]}"; do
  if grep -Fq "($rel_link)" "$SCRIPTS_README"; then
    pass "Link relativo documentado em scripts/README.md: ($rel_link)"
  else
    fail "Link relativo ausente em scripts/README.md: ($rel_link)"
  fi

  if [[ -f "$REPO_ROOT/scripts/$rel_link" ]]; then
    pass "Arquivo fisico referenciado existe: scripts/$rel_link"
  else
    fail "Arquivo fisico referenciado nao existe: scripts/$rel_link"
  fi
done

echo ""
echo "[Happy Path] 2. Validando documentacao do argumento obrigatorio --agents em metrics-collector.py..."

if grep -E "metrics-collector\.py.*--agents" "$SCRIPTS_README" >/dev/null 2>&1; then
  pass "scripts/README.md documenta uso de metrics-collector.py com a flag obrigatoria --agents"
else
  fail "scripts/README.md nao documenta a flag obrigatoria --agents nos exemplos de metrics-collector.py"
fi

echo ""
echo "[Happy Path] 3. Validando subcomandos reais de worktree-manager.sh em docs/Troubleshooting.md..."

for subcmd in "create" "list" "remove"; do
  if grep -E "worktree-manager\.sh ${subcmd}\b" "$TROUBLESHOOTING_DOC" >/dev/null 2>&1; then
    pass "docs/Troubleshooting.md documenta subcomando real: worktree-manager.sh $subcmd"
  else
    fail "docs/Troubleshooting.md nao documenta subcomando real: worktree-manager.sh $subcmd"
  fi
done

# ------------------------------------------------------------------------------
# 2. EDGE CASES & FAILURE MODES: Proibicao de links file:// e subcomandos/flags invalidos
# ------------------------------------------------------------------------------
echo ""
echo "[Edge Cases / Failure Modes] 1. Verificando ausencia de links locais file:// ou /home/ em scripts/README.md..."

if grep -E "file://|/home/" "$SCRIPTS_README" >/dev/null 2>&1; then
  fail "scripts/README.md contem links locais file:// ou caminhos absolutos /home/ proibidos"
else
  pass "scripts/README.md livre de esquemas file:// e caminhos absolutos /home/"
fi

echo ""
echo "[Edge Cases / Failure Modes] 2. Verificando ausencia de subcomandos/flags inexistentes em docs/Troubleshooting.md..."

if grep -E "worktree-manager\.sh add\b" "$TROUBLESHOOTING_DOC" >/dev/null 2>&1; then
  fail "docs/Troubleshooting.md instrui subcomando inexistente: worktree-manager.sh add"
else
  pass "docs/Troubleshooting.md nao contem subcomando inexistente: worktree-manager.sh add"
fi

if grep -E "worktree-manager\.sh remove .*--force" "$TROUBLESHOOTING_DOC" >/dev/null 2>&1; then
  fail "docs/Troubleshooting.md instrui flag nao suportada: worktree-manager.sh remove <id> --force"
else
  pass "docs/Troubleshooting.md nao contem flag nao suportada: worktree-manager.sh remove <id> --force"
fi

echo ""
echo "=================================================================="
if [[ "$FAILURES" -gt 0 ]]; then
  echo " RESULT: FAILED ($FAILURES assertion(s) failed)"
  echo "=================================================================="
  exit 1
else
  echo " RESULT: PASSED (All assertions green)"
  echo "=================================================================="
  exit 0
fi
