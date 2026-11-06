#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): Persist Living Mockups & Embed Visual Previews (Issue #32)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AGENT_UIUX="$REPO_ROOT/agents/uiux-designer/agent.md"
SKILL_PLAN="$REPO_ROOT/skills/plan-feature/SKILL.md"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #32: Persist Living Mockups in docs/ and Embed in Issues"
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
# SEÇÃO 1: VERIFICAÇÃO DO SUBAGENTE UI/UX (agents/uiux-designer/agent.md)
# =============================================================================
echo ""
echo "--- 1. Verificação do Subagente uiux-designer ---"
check "Arquivo agents/uiux-designer/agent.md existe" test -f "$AGENT_UIUX"

check "Modo 1 referencia persistência da living spec em docs/mockups/<slug>.md" \
  grep -q "docs/mockups/<slug>\.md" "$AGENT_UIUX"

check "Modo 1 referencia template canônico docs/mockups/TEMPLATE.md" \
  grep -q "docs/mockups/TEMPLATE\.md" "$AGENT_UIUX"

check "Modo 1 referencia salvamento persistente do asset em docs/assets/mockups/<slug>.png" \
  grep -q "docs/assets/mockups/<slug>\.png" "$AGENT_UIUX"

check "Modo 1 instrui captura headless direcionada para docs/assets/mockups/<slug>.png" \
  grep -qE "chromium --headless.*screenshot=docs/assets/mockups/<slug>\.png" "$AGENT_UIUX"

check "Contrato de Entrega (Output) no Modo 1 inclui docs/mockups/<slug>.md e docs/assets/mockups/<slug>.png" \
  grep -qE "docs/mockups/<slug>\.md.*docs/assets/mockups/<slug>\.png|docs/assets/mockups/<slug>\.png.*docs/mockups/<slug>\.md" "$AGENT_UIUX"

# =============================================================================
# SEÇÃO 2: VERIFICAÇÃO DA SKILL /plan-feature (skills/plan-feature/SKILL.md)
# =============================================================================
echo ""
echo "--- 2. Verificação do Fluxo /plan-feature (skills/plan-feature/SKILL.md) ---"
check "Arquivo skills/plan-feature/SKILL.md existe" test -f "$SKILL_PLAN"

check "Estado 1.5 orquestra criação da living spec em docs/mockups/<slug>.md" \
  grep -q "docs/mockups/<slug>\.md" "$SKILL_PLAN"

check "Estado 1.5 orquestra template base docs/mockups/TEMPLATE.md" \
  grep -q "docs/mockups/TEMPLATE\.md" "$SKILL_PLAN"

check "Estado 1.5 orquestra salvamento de screenshot em docs/assets/mockups/<slug>.png" \
  grep -q "docs/assets/mockups/<slug>\.png" "$SKILL_PLAN"

check "Estado 3 referencia validação do mockup vivo ou preview em docs/assets/mockups/" \
  grep -qiE "(docs/mockups/<slug>\.md|docs/assets/mockups/<slug>\.png)" "$SKILL_PLAN"

check "Estado 4 inclui explicitamente a seção '## 🎨 Mockup & Living Visual Spec'" \
  grep -q "## 🎨 Mockup & Living Visual Spec" "$SKILL_PLAN"

check "Estado 4 instrui inserção da seção no body de 'gh issue create'" \
  grep -qiE "(## 🎨 Mockup & Living Visual Spec).*gh issue create|gh issue create.*(## 🎨 Mockup & Living Visual Spec)" "$SKILL_PLAN"

check "Estado 4 inclui preview visual embedado de docs/assets/mockups/<slug>.png no template do gh issue create" \
  grep -qE "!\[.*\]\(.*docs/assets/mockups/<slug>\.png\)" "$SKILL_PLAN"

check "Estado 4 inclui link da especificação viva docs/mockups/<slug>.md no template do gh issue create" \
  grep -qE "\[.*\]\(.*docs/mockups/<slug>\.md\)" "$SKILL_PLAN"

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

echo " >>> RESULTADO: GREEN (Todos os contratos de living mockup foram atendidos)"
exit 0
