#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): Persist Living Mockups & Embed Visual Previews (Issue #32 & #81)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
AGENT_UIUX="$REPO_ROOT/agents/uiux-designer/agent.md"
SKILL_PLAN="$REPO_ROOT/skills/plan-feature/SKILL.md"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #81: Publish Mockup Assets to Dedicated aidd-assets Branch"
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

check_not() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  [FAIL] $desc"
    FAILED=$((FAILED + 1))
  else
    echo "  [PASS] $desc"
    PASSED=$((PASSED + 1))
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

# -----------------------------------------------------------------------------
# HAPPY PATH (Issue #81)
# -----------------------------------------------------------------------------
echo ""
echo "--- 2.1 Happy Path: URLs Absolutas e Publicação Isolada na Branch aidd-assets ---"

check "Template gh issue create inclui URL absoluta com ?raw=true na branch aidd-assets para imagem de preview" \
  grep -F "https://github.com/<owner>/<repo>/blob/aidd-assets/docs/assets/mockups/<slug>.png?raw=true" "$SKILL_PLAN"

check "Template gh issue create inclui URL absoluta na branch aidd-assets para a living spec" \
  grep -F "https://github.com/<owner>/<repo>/blob/aidd-assets/docs/mockups/<slug>.md" "$SKILL_PLAN"

check "Estado 4 (Item 4) exige publicação isolada de mockups e living specs na branch dedicada aidd-assets" \
  grep -qiE "branch dedicada.*aidd-assets" "$SKILL_PLAN"

check "Estado 4 (Item 4) instrui explicitamente a NÃO commitar assets de mockups na branch main" \
  grep -qiE "sem commitar na .*main" "$SKILL_PLAN"

check "Estado 4 (Item 4) inclui publicação de docs/assets/mockups/<slug>.png, docs/mockups/<slug>.md e docs/mockups/README.md" \
  grep -qiE "docs/assets/mockups/<slug>\.png.*docs/mockups/<slug>\.md.*docs/mockups/README\.md" "$SKILL_PLAN"

check "Estado 4 (Item 4) exige uso de git worktree temporário a partir de origin/aidd-assets ou HEAD" \
  grep -qiE "git worktree.*(origin/aidd-assets|HEAD)" "$SKILL_PLAN"

check "Estado 4 (Item 4) exige push dos assets para origin/aidd-assets" \
  grep -qiE "push para.*origin/aidd-assets" "$SKILL_PLAN"

# -----------------------------------------------------------------------------
# EDGE CASES & FAILURE MODES (Issue #81)
# -----------------------------------------------------------------------------
echo ""
echo "--- 2.2 Edge Cases & Failure Modes: Prevenção de Falhas em Repos Privados e Links Quebrados ---"

check_not "Template gh issue create NÃO deve conter caminhos relativos residuais para imagem de mockup" \
  grep -qE "!\[Mockup Preview\]\((\.\/)?docs/assets/mockups/" "$SKILL_PLAN"

check_not "Template gh issue create NÃO deve conter caminhos relativos residuais para a living spec" \
  grep -qE "\[docs/mockups/<slug>\.md\]\((\.\/)?docs/mockups/<slug>\.md\)" "$SKILL_PLAN"

check_not "Template gh issue create NÃO deve utilizar raw.githubusercontent.com (falha em repositórios privados)" \
  grep -q "raw.githubusercontent.com" "$SKILL_PLAN"

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

echo " >>> RESULTADO: GREEN (Todos os contratos de living mockup e branch aidd-assets foram atendidos)"
exit 0
