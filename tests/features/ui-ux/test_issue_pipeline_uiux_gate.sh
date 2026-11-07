#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Conformidade: UI/UX Visual Contract & Audit Gate no /run-issue (Issue #15)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SKILL_MD="$REPO_ROOT/skills/issue-pipeline/SKILL.md"
PLANNER_MD="$REPO_ROOT/agents/planner/agent.md"
CODER_MD="$REPO_ROOT/agents/coder/agent.md"
GATEKEEPER_MD="$REPO_ROOT/agents/gatekeeper/agent.md"

FAILED=0

echo "========================================================================"
echo " [TEST] Validação do Gate UI/UX Visual Contract & Audit no /run-issue"
echo "========================================================================"

check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  [PASS] $desc"
  else
    echo "  [FAIL] $desc"
    FAILED=1
  fi
}

echo ""
echo "--- 1. Orquestrador de Execução (skills/issue-pipeline/SKILL.md) ---"
check "SKILL.md existe" test -f "$SKILL_MD"
check "Contém diagrama Mermaid com nós de decisão (UI_UX_REQUIRED)" bash -c "grep -qiE 'flowchart (TD|LR)' '$SKILL_MD' && grep -q 'UI_UX_REQUIRED' '$SKILL_MD'"
check "ESTADO 1 descreve fallback condicional para uiux-designer (Modo 1)" bash -c "grep -qi 'uiux-designer' '$SKILL_MD' && grep -qi 'Modo 1' '$SKILL_MD'"
check "Contém ESTADO 3.5 dedicado ao UI/UX Visual Audit Gate" grep -qiE "ESTADO 3\.5.*(UI/UX|Visual Audit)" "$SKILL_MD"
check "ESTADO 3.5 invoca uiux-designer (Modo 2)" bash -c "grep -qiE 'ESTADO 3\.5' '$SKILL_MD' && grep -qi 'Modo 2' '$SKILL_MD'"
check "Trata veredito VISUAL_AUDIT: APPROVED" grep -q "VISUAL_AUDIT: APPROVED" "$SKILL_MD"
check "Trata veredito VISUAL_AUDIT: REJECTED" grep -q "VISUAL_AUDIT: REJECTED" "$SKILL_MD"
check "ESTADO 4 exige aprovação visual e prova visual no walkthrough.md" bash -c "grep -qiE '(VISUAL_AUDIT: APPROVED|auditoria visual aprovad)' '$SKILL_MD' && grep -qiE '(prova visual|evidência visual|evidencia visual)' '$SKILL_MD'"

echo ""
echo "--- 2. Subagente Planner (agents/planner/agent.md) ---"
check "planner/agent.md existe" test -f "$PLANNER_MD"
check "Emite flag obrigatória UI_UX_REQUIRED (true/false)" grep -q "UI_UX_REQUIRED" "$PLANNER_MD"
check "Inclui seção '## Visual & UI/UX Contract' no implementation_plan.md" grep -qi "Visual & UI/UX Contract" "$PLANNER_MD"

echo ""
echo "--- 3. Subagente Coder (agents/coder/agent.md) ---"
check "coder/agent.md existe" test -f "$CODER_MD"
check "Instrui consumo obrigatório dos Design Tokens" grep -qi "Design Tokens" "$CODER_MD"
check "Proíbe inventar estilos ou desviar do contrato visual" grep -qiE "(não inventar|proibido inventar|sem inventar).*estilos|estilos fora do contrato" "$CODER_MD"

echo ""
echo "--- 4. Subagente Gatekeeper (agents/gatekeeper/agent.md) ---"
check "gatekeeper/agent.md existe" test -f "$GATEKEEPER_MD"
check "Exige verificação de UI_UX_REQUIRED" grep -q "UI_UX_REQUIRED" "$GATEKEEPER_MD"
check "Valida parecer obrigatório VISUAL_AUDIT: APPROVED para UI_UX_REQUIRED" grep -q "VISUAL_AUDIT: APPROVED" "$GATEKEEPER_MD"
check "Exige comprovação por evidência visual no walkthrough.md" grep -qiE "(prova visual|evidência visual|evidencia visual)" "$GATEKEEPER_MD"

echo ""
echo "========================================================================"
if [ "$FAILED" -ne 0 ]; then
  echo " >>> RESULTADO: RED (Falha esperada: contratos de UI/UX ainda não integrados)"
  echo "========================================================================"
  exit 1
else
  echo " >>> RESULTADO: GREEN (Sucesso: todos os critérios de UI/UX foram atendidos)"
  echo "========================================================================"
  exit 0
fi
