#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): Visual Comparison & Living Mockup Validation in PRs (Issue #33)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SKILL_MD="$REPO_ROOT/skills/issue-pipeline/SKILL.md"
GATEKEEPER_MD="$REPO_ROOT/agents/gatekeeper/agent.md"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #33: Visual Comparison Audit & Living Mockup in Pull Requests"
echo "========================================================================"

check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  [PASS] $desc"
    PASSED=$((PASSED + 1))
  else
    echo "  [FAIL] $desc"
    FAILED=$((FAILED + 1))
  fi
}

# =============================================================================
# SEÇÃO 1: SKILL ISSUE-PIPELINE (skills/issue-pipeline/SKILL.md)
# =============================================================================
echo ""
echo "--- 1. Verificação de skills/issue-pipeline/SKILL.md ---"
check "Arquivo skills/issue-pipeline/SKILL.md existe" test -f "$SKILL_MD"

check "Estado 1 instrui carregar living spec em docs/mockups/<slug>.md caso exista" \
  bash -c "grep -qi 'docs/mockups/<slug>\.md' '$SKILL_MD'"

check "Estado 3.5 instrui confrontar a implementação contra o mockup aprovado em docs/assets/mockups/<slug>.png" \
  bash -c "grep -qi 'docs/assets/mockups/<slug>\.png' '$SKILL_MD'"

check "Estado 4 inclui a seção obrigatória '## 👁️ Visual Comparison Audit'" \
  grep -q "## 👁️ Visual Comparison Audit" "$SKILL_MD"

check "Estado 4 inclui tabela comparativa side-by-side '| Mockup Original Aprovado | Implementação Renderizada |'" \
  grep -q "| Mockup Original Aprovado | Implementação Renderizada |" "$SKILL_MD"

# =============================================================================
# SEÇÃO 2: AGENTE GATEKEEPER (agents/gatekeeper/agent.md)
# =============================================================================
echo ""
echo "--- 2. Verificação de agents/gatekeeper/agent.md ---"
check "Arquivo agents/gatekeeper/agent.md existe" test -f "$GATEKEEPER_MD"

check "Gatekeeper exige a seção '## 👁️ Visual Comparison Audit' no walkthrough.md para UI_UX_REQUIRED: true" \
  grep -q "## 👁️ Visual Comparison Audit" "$GATEKEEPER_MD"

check "Gatekeeper valida tabela comparativa '| Mockup Original Aprovado | Implementação Renderizada |'" \
  grep -q "| Mockup Original Aprovado | Implementação Renderizada |" "$GATEKEEPER_MD"

check "Gatekeeper bloqueia gh pr create se auditoria visual comparativa estiver ausente em UI_UX_REQUIRED: true" \
  bash -c "grep -qiE '(Visual Comparison Audit|tabela comparativa).*gh pr create|gh pr create.*(Visual Comparison Audit|tabela comparativa)|antes de.*gh pr create' '$GATEKEEPER_MD'"

# =============================================================================
# RESUMO FINAL
# =============================================================================
echo ""
echo "========================================================================"
echo " RESUMO DO TESTE: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo " >>> RESULTADO: RED (Falha esperada antes da implementação)"
  exit 1
fi

echo " >>> RESULTADO: GREEN (Todos os critérios de auditoria visual comparativa atendidos)"
exit 0
