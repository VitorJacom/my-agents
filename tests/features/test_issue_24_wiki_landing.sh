#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): Wiki Navigation Hub and Landing Pages (Issue #24)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS_DIR="$REPO_ROOT/docs"
HOME_MD="$DOCS_DIR/Home.md"
SIDEBAR_MD="$DOCS_DIR/_Sidebar.md"
FOOTER_MD="$DOCS_DIR/_Footer.md"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #24: Build Wiki Navigation Hub and Landing Pages"
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
# SEÇÃO 1: EXISTÊNCIA E NÃO-VACUIDADE DOS ARQUIVOS DA WIKI
# =============================================================================
echo ""
echo "--- 1. Existência e Estrutura Básica dos Arquivos ---"
check "docs/Home.md existe e não está vazio" test -s "$HOME_MD"
check "docs/_Sidebar.md existe e não está vazio" test -s "$SIDEBAR_MD"
check "docs/_Footer.md existe e não está vazio" test -s "$FOOTER_MD"

# =============================================================================
# SEÇÃO 2: VALIDAÇÃO DO HUB docs/Home.md
# =============================================================================
echo ""
echo "--- 2. Validação de Conteúdo do docs/Home.md ---"
check "Home.md possui título de boas-vindas" grep -q "# Bem-vindo à Wiki do \`my-agents\`" "$HOME_MD"
check "Home.md possui badges informativos" grep -q "img.shields.io" "$HOME_MD"
check "Home.md declara valor 1 do AIDD: Method over Model" grep -qi "Method over Model" "$HOME_MD"
check "Home.md declara valor 2 do AIDD: Ownership over Delegation" grep -qi "Ownership over Delegation" "$HOME_MD"
check "Home.md declara valor 3 do AIDD: Understanding over Acceptance" grep -qi "Understanding over Acceptance" "$HOME_MD"
check "Home.md declara valor 4 do AIDD: Outcome over Output" grep -qi "Outcome over Output" "$HOME_MD"

echo ""
echo "--- Taxonomia dos Subagentes no docs/Home.md ---"
check "Subagente product-owner listado" grep -q "product-owner" "$HOME_MD"
check "Subagente system-architect listado" grep -q "system-architect" "$HOME_MD"
check "Subagente uiux-designer listado" grep -q "uiux-designer" "$HOME_MD"
check "Subagente planner listado" grep -q "planner" "$HOME_MD"
check "Subagente qa-engineer listado" grep -q "qa-engineer" "$HOME_MD"
check "Subagente coder listado" grep -q "coder" "$HOME_MD"
check "Subagente gatekeeper listado" grep -q "gatekeeper" "$HOME_MD"

echo ""
echo "--- Links Rápidos no docs/Home.md ---"
check "Link rápido para Getting-Started" grep -q "Getting-Started" "$HOME_MD"
check "Link rápido para AIDD-Manifesto" grep -q "AIDD-Manifesto" "$HOME_MD"
check "Link rápido para Architecture" grep -q "Architecture" "$HOME_MD"
check "Link rápido para Subagents" grep -q "Subagents" "$HOME_MD"
check "Link rápido para Skills-Catalog" grep -q "Skills-Catalog" "$HOME_MD"
check "Link rápido para Troubleshooting" grep -q "Troubleshooting" "$HOME_MD"

# =============================================================================
# SEÇÃO 3: VALIDAÇÃO DA BARRA LATERAL docs/_Sidebar.md
# =============================================================================
echo ""
echo "--- 3. Validação do Índice Hierárquico do docs/_Sidebar.md ---"
check "Sidebar possui cabeçalho de navegação da Wiki" grep -q "my-agents Wiki" "$SIDEBAR_MD"
check "Sidebar possui seção 'Início'" grep -q "Início" "$SIDEBAR_MD"
check "Sidebar possui seção 'Primeiros Passos'" grep -q "Primeiros Passos" "$SIDEBAR_MD"
check "Sidebar possui seção 'Arquitetura & Governança'" grep -q "Arquitetura & Governança" "$SIDEBAR_MD"
check "Sidebar possui seção 'Catálogo de Recursos'" grep -q "Catálogo de Recursos" "$SIDEBAR_MD"
check "Sidebar possui seção 'Troubleshooting'" grep -q "Troubleshooting" "$SIDEBAR_MD"

echo ""
echo "--- Links Canônicos no docs/_Sidebar.md ---"
check "Sidebar aponta para Home" grep -E -q '\(Home\)' "$SIDEBAR_MD"
check "Sidebar aponta para Getting-Started" grep -E -q '\(Getting-Started\)' "$SIDEBAR_MD"
check "Sidebar aponta para AIDD-Manifesto" grep -E -q '\(AIDD-Manifesto\)' "$SIDEBAR_MD"
check "Sidebar aponta para Architecture" grep -E -q '\(Architecture\)' "$SIDEBAR_MD"
check "Sidebar aponta para Subagents" grep -E -q '\(Subagents\)' "$SIDEBAR_MD"
check "Sidebar aponta para Skills-Catalog" grep -E -q '\(Skills-Catalog\)' "$SIDEBAR_MD"
check "Sidebar aponta para Troubleshooting" grep -E -q '\(Troubleshooting\)' "$SIDEBAR_MD"

# =============================================================================
# SEÇÃO 4: VALIDAÇÃO DO RODAPÉ INSTITUCIONAL docs/_Footer.md
# =============================================================================
echo ""
echo "--- 4. Validação do docs/_Footer.md ---"
check "Footer possui divisor horizontal markdown" grep -q -- "---" "$FOOTER_MD"
check "Footer possui link para repositório oficial" grep -q "https://github.com/VitorJacom/my-agents" "$FOOTER_MD"
check "Footer faz referência à Licença" grep -qi "Licença" "$FOOTER_MD"
check "Footer contém aviso de sincronização automatizada via wiki-sync.yml" grep -q "wiki-sync.yml" "$FOOTER_MD"

# =============================================================================
# SEÇÃO 5: INTEGRIDADE DE LINKS SINTÁTICOS (SEM LINKS VAZIOS OU QUEBRADOS)
# =============================================================================
echo ""
echo "--- 5. Integridade Sintática dos Arquivos Markdown ---"
check "Home.md não contém links markdown vazios '[]()'" bash -c "! grep -q '\[\]()' '$HOME_MD'"
check "Sidebar.md não contém links markdown vazios '[]()'" bash -c "! grep -q '\[\]()' '$SIDEBAR_MD'"
check "Footer.md não contém links markdown vazios '[]()'" bash -c "! grep -q '\[\]()' '$FOOTER_MD'"

# =============================================================================
# RELATÓRIO FINAL
# =============================================================================
echo ""
echo "========================================================================"
echo " RESUMO DO TESTE: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo "❌ TESTE FALHOU com $FAILED falhas!"
  exit 1
fi

echo "✅ TODOS OS TESTES PASSARAM COM SUCESSO!"
exit 0
