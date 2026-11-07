#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): Mockup Living Specs Structure & Template (Issue #31)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOCS_DIR="$REPO_ROOT/docs"
MOCKUPS_DIR="$DOCS_DIR/mockups"
TEMPLATE_FILE="$MOCKUPS_DIR/TEMPLATE.md"
README_FILE="$MOCKUPS_DIR/README.md"
ASSETS_MOCKUPS_DIR="$DOCS_DIR/assets/mockups"
GITKEEP_FILE="$ASSETS_MOCKUPS_DIR/.gitkeep"
SIDEBAR_FILE="$DOCS_DIR/_Sidebar.md"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #31: Standardize Mockup Living Specs Structure & Template"
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
# SEÇÃO 1: DIRETÓRIOS E ARQUIVOS BASE
# =============================================================================
echo ""
echo "--- 1. Existência de Diretórios e Arquivos Canônicos ---"
check "Diretório docs/mockups/ existe" test -d "$MOCKUPS_DIR"
check "Diretório docs/assets/mockups/ existe" test -d "$ASSETS_MOCKUPS_DIR"
check "Arquivo docs/assets/mockups/.gitkeep existe" test -f "$GITKEEP_FILE"
check "Arquivo docs/mockups/TEMPLATE.md existe e não está vazio" test -s "$TEMPLATE_FILE"
check "Arquivo docs/mockups/README.md existe e não está vazio" test -s "$README_FILE"

# =============================================================================
# SEÇÃO 2: VALIDAÇÃO DO docs/mockups/TEMPLATE.md
# =============================================================================
echo ""
echo "--- 2. Especificação do Template Canônico (TEMPLATE.md) ---"
# Metadados
check "TEMPLATE.md contém seção ou metadados de Slug" grep -qi "Slug" "$TEMPLATE_FILE"
check "TEMPLATE.md contém metadado de Status" grep -qi "Status" "$TEMPLATE_FILE"
check "TEMPLATE.md contém metadado de Origem" grep -qi "Origem" "$TEMPLATE_FILE"
check "TEMPLATE.md contém metadado de Viewport" grep -qi "Viewport" "$TEMPLATE_FILE"

# Visual Preview
check "TEMPLATE.md contém tag de Visual Preview para imagem de asset" \
  grep -F '![Mockup](../assets/mockups/<slug>.png)' "$TEMPLATE_FILE"

# Camada 1: Spatial Blueprint (ASCII)
check "TEMPLATE.md contém seção Camada 1: Spatial Blueprint (ASCII)" \
  grep -qiE "(Camada 1.*Spatial Blueprint|Spatial Blueprint.*ASCII)" "$TEMPLATE_FILE"

# Camada 2: Design Tokens & Luminance Contract
check "TEMPLATE.md contém seção Camada 2: Design Tokens & Luminance Contract" \
  grep -qi "Camada 2.*Design Tokens & Luminance Contract" "$TEMPLATE_FILE"
check "TEMPLATE.md especifica Value Contrast >= 2:1" \
  grep -qiE "Value Contrast.*2:1|2:1.*Value Contrast" "$TEMPLATE_FILE"
check "TEMPLATE.md especifica WCAG AA >= 4.5:1" \
  grep -qiE "WCAG.*4\\.5:1|4\\.5:1.*WCAG" "$TEMPLATE_FILE"

# Estados Interativos & Acessibilidade
check "TEMPLATE.md contém seção de Estados Interativos & Acessibilidade" \
  grep -qiE "(Estados Interativos.*Acessibilidade|Acessibilidade.*Estados Interativos)" "$TEMPLATE_FILE"

# =============================================================================
# SEÇÃO 3: VALIDAÇÃO DO docs/mockups/README.md
# =============================================================================
echo ""
echo "--- 3. Catálogo e Índice Central (README.md) ---"
check "README.md possui título de Catálogo de Telas ou Mockup Living Specs" \
  grep -qiE "(Catálogo de Telas|Mockup Living Specs)" "$README_FILE"
check "README.md referencia TEMPLATE.md" \
  grep -qi "TEMPLATE" "$README_FILE"
check "README.md possui instrução ou fluxo de criação de telas" \
  grep -qiE "(Como Criar|Como Usar|Novo Mockup|Workflow)" "$README_FILE"

# =============================================================================
# SEÇÃO 4: INTEGRAÇÃO COM _Sidebar.md DA WIKI
# =============================================================================
echo ""
echo "--- 4. Integração na Navegação da Wiki (_Sidebar.md) ---"
check "_Sidebar.md contém link para Catálogo de Telas (Mockups) apontando para mockups/README" \
  grep -qE '\[.*Catálogo de Telas \(Mockups\).*\]\(mockups/README\)' "$SIDEBAR_FILE"

# =============================================================================
# RESUMO FINAL
# =============================================================================
echo ""
echo "========================================================================"
echo " RESUMO DO TESTE: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo "❌ TESTE FALHOU com $FAILED falha(s)!"
  exit 1
fi

echo "✅ TODOS OS TESTES PASSARAM COM SUCESSO!"
exit 0
