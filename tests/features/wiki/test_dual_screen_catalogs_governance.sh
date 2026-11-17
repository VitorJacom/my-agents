#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): GitHub Wiki & Dual Screen Catalogs Governance (Issue #83)
#
# Valida:
# - Happy Path: Diretrizes de GitHub Wiki viva, Dual Screen Catalogs
#   (docs/mockups/README.md -> Mockups-Catalog e docs/screenshots/README.md ->
#   Implemented-Screens-Catalog) e normalização Dual-Context para Gollum.
# - Edge Cases & Failure Modes: Escape obrigatório de pontos literais (\.\.)
#   nos comandos sed de reescrita e ausência de caminhos relativos não escapados
#   ou omissão do catálogo de telas implementadas.
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RULES_AGENTS="$REPO_ROOT/rules/AGENTS.md"
AGENT_UIUX="$REPO_ROOT/agents/uiux-designer/agent.md"
AGENT_GATEKEEPER="$REPO_ROOT/agents/gatekeeper/agent.md"
SKILL_PLAN="$REPO_ROOT/skills/plan-feature/SKILL.md"
SKILL_ISSUE="$REPO_ROOT/skills/issue-pipeline/SKILL.md"

PASSED=0
FAILED=0

echo "========================================================================"
echo " [TEST] Issue #83: GitHub Wiki & Dual Screen Catalogs Governance"
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
# 1. HAPPY PATH: RULES/AGENTS.MD (GOVERNANÇA DE WIKI E DUAL-CATALOG)
# =============================================================================
echo ""
echo "--- 1. Happy Path: rules/AGENTS.md ---"
check "Arquivo rules/AGENTS.md existe" test -f "$RULES_AGENTS"
check "rules/AGENTS.md exige portal Wiki (docs/Home.md, docs/_Sidebar.md, docs/_Footer.md)" \
  grep -qE "docs/Home\.md" "$RULES_AGENTS"
check "rules/AGENTS.md exige docs/_Sidebar.md e docs/_Footer.md" \
  bash -c "grep -q 'docs/_Sidebar\.md' '$RULES_AGENTS' && grep -q 'docs/_Footer\.md' '$RULES_AGENTS'"
check "rules/AGENTS.md exige workflow .github/workflows/wiki-sync.yml" \
  grep -q "\.github/workflows/wiki-sync\.yml" "$RULES_AGENTS"
check "rules/AGENTS.md define Catálogo de Mockups (docs/mockups/README.md -> Mockups-Catalog)" \
  bash -c "grep -q 'docs/mockups/README\.md' '$RULES_AGENTS' && grep -q 'Mockups-Catalog' '$RULES_AGENTS'"
check "rules/AGENTS.md define Catálogo de Telas Implementadas (docs/screenshots/README.md -> Implemented-Screens-Catalog)" \
  bash -c "grep -q 'docs/screenshots/README\.md' '$RULES_AGENTS' && grep -q 'Implemented-Screens-Catalog' '$RULES_AGENTS'"
check "rules/AGENTS.md documenta padrão de captura de produção (docs/screenshots/<slug>.md e <slug>-preview.png)" \
  bash -c "grep -q 'docs/screenshots/<slug>\.md' '$RULES_AGENTS' && grep -q 'docs/screenshots/<slug>-preview\.png' '$RULES_AGENTS'"
check "rules/AGENTS.md documenta normalização Dual-Context para Gollum com pontos literais escapados (\\.\\.) no sed" \
  bash -c "grep -qF '\.\./assets/mockups/' '$RULES_AGENTS' && grep -qF '\.\./screenshots/' '$RULES_AGENTS'"
check "rules/AGENTS.md documenta normalização de links relativos Markdown para slugs sem .md no Gollum" \
  grep -qF '\.\./mockups/README\.md' "$RULES_AGENTS"

# =============================================================================
# 2. HAPPY PATH: UIUX-DESIGNER E GATEKEEPER
# =============================================================================
echo ""
echo "--- 2. Happy Path: agents/uiux-designer/agent.md e agents/gatekeeper/agent.md ---"
check "uiux-designer Modo 1 referencia catálogo Mockups-Catalog (docs/mockups/README.md)" \
  bash -c "grep -q 'docs/mockups/README\.md' '$AGENT_UIUX' && grep -q 'Mockups-Catalog' '$AGENT_UIUX'"
check "uiux-designer Modo 2 referencia catálogo Implemented-Screens-Catalog (docs/screenshots/README.md)" \
  bash -c "grep -q 'docs/screenshots/README\.md' '$AGENT_UIUX' && grep -q 'Implemented-Screens-Catalog' '$AGENT_UIUX'"
check "uiux-designer Modo 2 documenta registro em docs/screenshots/<slug>.md e docs/screenshots/<slug>-preview.png" \
  bash -c "grep -q 'docs/screenshots/<slug>\.md' '$AGENT_UIUX' && grep -q 'docs/screenshots/<slug>-preview\.png' '$AGENT_UIUX'"

check "gatekeeper audita existência/atualização da Wiki e dos dois catálogos (Mockups-Catalog e Implemented-Screens-Catalog)" \
  bash -c "grep -q 'Mockups-Catalog' '$AGENT_GATEKEEPER' && grep -q 'Implemented-Screens-Catalog' '$AGENT_GATEKEEPER'"
check "gatekeeper exige docs/screenshots/README.md e docs/screenshots/<slug>-preview.png em UI_UX_REQUIRED: true" \
  bash -c "grep -q 'docs/screenshots/README\.md' '$AGENT_GATEKEEPER' && grep -q 'docs/screenshots/<slug>-preview\.png' '$AGENT_GATEKEEPER'"

# =============================================================================
# 3. HAPPY PATH: SKILLS /plan-feature E /issue-pipeline
# =============================================================================
echo ""
echo "--- 3. Happy Path: skills/plan-feature/SKILL.md e skills/issue-pipeline/SKILL.md ---"
check "plan-feature exige estrutura de Wiki (docs/Home.md, docs/_Sidebar.md, wiki-sync.yml) e Mockups-Catalog" \
  bash -c "grep -q 'Mockups-Catalog' '$SKILL_PLAN' && grep -q 'docs/Home\.md' '$SKILL_PLAN' && grep -q 'wiki-sync\.yml' '$SKILL_PLAN'"

check "issue-pipeline Estado 3.5/4 exige atualização do catálogo Implemented-Screens-Catalog (docs/screenshots/README.md)" \
  bash -c "grep -q 'docs/screenshots/README\.md' '$SKILL_ISSUE' && grep -q 'Implemented-Screens-Catalog' '$SKILL_ISSUE'"
check "issue-pipeline Estado 3.5/4 referencia docs/screenshots/<slug>.md e docs/screenshots/<slug>-preview.png" \
  bash -c "grep -q 'docs/screenshots/<slug>\.md' '$SKILL_ISSUE' && grep -q 'docs/screenshots/<slug>-preview\.png' '$SKILL_ISSUE'"

# =============================================================================
# 4. EDGE CASES & FAILURE MODES: ANTI-CORRUPÇÃO DE SED E LINKS GOLLUM
# =============================================================================
echo ""
echo "--- 4. Edge Cases & Failure Modes ---"
check_not "rules/AGENTS.md NÃO deve usar sed sem escapar pontos em ../assets/mockups/ (corromperia docs/assets/mockups/)" \
  grep -qE "sed -i 's\|\.\./assets/mockups/" "$RULES_AGENTS"

check_not "rules/AGENTS.md NÃO deve usar sed sem escapar pontos em ../screenshots/ (corromperia docs/screenshots/)" \
  grep -qE "sed -i 's\|\.\./screenshots/" "$RULES_AGENTS"

check "rules/AGENTS.md contém comando sed completo com escape para wiki-temp/Mockups-Catalog.md e wiki-temp/Implemented-Screens-Catalog.md" \
  bash -c "grep -q 'wiki-temp/Mockups-Catalog\.md' '$RULES_AGENTS' && grep -q 'wiki-temp/Implemented-Screens-Catalog\.md' '$RULES_AGENTS'"

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

echo " >>> RESULTADO: GREEN (Todos os contratos da Issue #83 foram atendidos)"
exit 0
