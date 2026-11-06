#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Conformidade: Protocolo Mockup-as-Code & Visual Gate (Issue #13)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GITIGNORE="$REPO_ROOT/.gitignore"
AGENT_MD="$REPO_ROOT/agents/uiux-designer/agent.md"

FAILED=0

echo "========================================================================"
echo " [TEST] Validação do Protocolo Mockup-as-Code (UI/UX Designer Agent)"
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
echo "--- 1. Verificação de Arquivos Efêmeros (.gitignore) ---"
check ".gitignore existe" test -f "$GITIGNORE"
check ".gitignore contém entrada '.mockup-preview.html'" grep -qE '^\.mockup-preview\.html$' "$GITIGNORE"
check ".gitignore contém entrada '.mockup-preview.png'" grep -qE '^\.mockup-preview\.png$' "$GITIGNORE"

echo ""
echo "--- 2. Verificação do Prompt do Agente (agents/uiux-designer/agent.md) ---"
check "agent.md existe" test -f "$AGENT_MD"
check "Contém 'Modo 1: Concepção & Mockup-as-Code (Figma-less'" grep -qi "Modo 1: Concepção & Mockup-as-Code (Figma-less" "$AGENT_MD"
check "Contém 'Camada 1: Spatial Blueprint' ou 'Camada 1: Wireframe Estrutural ASCII'" grep -qiE "Camada 1.*(Spatial Blueprint|Wireframe Estrutural ASCII)" "$AGENT_MD"
check "Contém 'Camada 2: Design Tokens & Luminance Contract'" grep -qi "Camada 2.*Design Tokens & Luminance Contract" "$AGENT_MD"
check "Camada 2 especifica Value Contrast >= 2:1" grep -qiE "Value Contrast.*2:1|2:1.*Value Contrast" "$AGENT_MD"
check "Camada 2 especifica WCAG AA >= 4.5:1" grep -qiE "WCAG.*4\.5:1|4\.5:1.*WCAG" "$AGENT_MD"
check "Contém 'Camada 3: Protótipo Estático Autocontido'" grep -qi "Camada 3.*Protótipo Estático Autocontido" "$AGENT_MD"
check "Camada 3 especifica '.mockup-preview.html'" grep -q "\.mockup-preview\.html" "$AGENT_MD"
check "Camada 3 especifica '.mockup-preview.png'" grep -q "\.mockup-preview\.png" "$AGENT_MD"
check "Contém 'Modo 2: Auditoria Visual Headless Pós-Implementação'" grep -qi "Modo 2: Auditoria Visual Headless Pós-Implementação" "$AGENT_MD"
check "Especifica veredito obrigatório 'VISUAL_AUDIT: APPROVED'" grep -q "VISUAL_AUDIT: APPROVED" "$AGENT_MD"
check "Especifica veredito obrigatório 'VISUAL_AUDIT: REJECTED'" grep -q "VISUAL_AUDIT: REJECTED" "$AGENT_MD"
check "Especifica instrução de headless browser ('chromium --headless')" grep -q "chromium --headless" "$AGENT_MD"

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
