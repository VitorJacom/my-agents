#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Conformidade: Integração uiux-designer na Máquina de Estados (Issue #14)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL_MD="$REPO_ROOT/skills/plan-feature/SKILL.md"
ARCHITECT_MD="$REPO_ROOT/agents/system-architect/agent.md"

FAILED=0

echo "========================================================================"
echo " [TEST] Validação da Integração do uiux-designer no /plan-feature"
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
echo "--- 1. Verificação de Arquivos Obrigatórios ---"
check "SKILL.md do /plan-feature existe" test -f "$SKILL_MD"
check "agent.md do system-architect existe" test -f "$ARCHITECT_MD"

echo ""
echo "--- 2. Verificação da Skill /plan-feature (skills/plan-feature/SKILL.md) ---"
check "Estado 1 contém classificação 'UI_UX_REQUIRED: YES'" grep -q "UI_UX_REQUIRED: YES" "$SKILL_MD"
check "Estado 1 contém classificação 'UI_UX_REQUIRED: NO'" grep -q "UI_UX_REQUIRED: NO" "$SKILL_MD"
check "Define etapa condicional 'ESTADO 1.5' ou 'UI/UX & Mockup Design'" grep -qiE "(ESTADO 1\.5|UI/UX & Mockup Design)" "$SKILL_MD"
check "ESTADO 1.5 invoca ou referencia subagente 'uiux-designer'" grep -qiE "uiux-designer.*(Modo 1|Mockup-as-Code)|invoke_subagent.*uiux-designer" "$SKILL_MD"
check "Contém diagrama Mermaid (flowchart/graph) com nó condicional para UI_UX_REQUIRED" grep -qiE "(flowchart|graph).*(UI_UX_REQUIRED|interface visual|impacto visual)" "$SKILL_MD"
check "Estado 3 (Gate de Aprovação) referencia validação visual de '.mockup-preview.png'" grep -q "\.mockup-preview\.png" "$SKILL_MD"
check "Estado 4 (Criação no GitHub) referencia inclusão de 'Visual & UI/UX Contract' no body da issue" grep -qi "Visual & UI/UX Contract" "$SKILL_MD"

echo ""
echo "--- 3. Verificação do Arquiteto (agents/system-architect/agent.md) ---"
check "system-architect explicita acolhimento de 'Visual & UI/UX Contract'" grep -qi "Visual & UI/UX Contract" "$ARCHITECT_MD"
check "system-architect persiste contrato visual no planning_proposal.md ou issues fatiadas" grep -qiE "(planning_proposal\.md|issues fatiadas|issues resultantes).*(Visual & UI/UX Contract)|(Visual & UI/UX Contract).*(planning_proposal\.md|issues fatiadas|issues resultantes)" "$ARCHITECT_MD"

echo ""
echo "========================================================================"
if [ "$FAILED" -ne 0 ]; then
  echo " >>> RESULTADO: RED (Falha esperada: implementação ainda não realizada)"
  echo "========================================================================"
  exit 1
else
  echo " >>> RESULTADO: GREEN (Sucesso: todos os critérios foram atendidos)"
  echo "========================================================================"
  exit 0
fi
