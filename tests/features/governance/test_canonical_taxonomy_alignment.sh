#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): Alinhamento da Taxonomia Canônica em PROJECT_CONTEXT.md
# e agents/qa-engineer/agent.md (Issue #603)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PROJECT_CONTEXT="$REPO_ROOT/PROJECT_CONTEXT.md"
QA_AGENT="$REPO_ROOT/agents/qa-engineer/agent.md"
SESSION_HOOK="$REPO_ROOT/scripts/hooks/session-start-context.sh"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #603: Canonical Taxonomy Alignment in PROJECT_CONTEXT & QA"
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
# SEÇÃO 1: HAPPY PATH
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] PROJECT_CONTEXT.md documenta scripts/ e suas 4 categorias ---"
check "PROJECT_CONTEXT.md documenta o diretório 'scripts/'" grep -q '`scripts/`:' "$PROJECT_CONTEXT"
for category in "hooks/" "pipeline/" "statusline/" "migrations/"; do
  check "PROJECT_CONTEXT.md lista a categoria scripts/$category" grep -q "$category" "$PROJECT_CONTEXT"
done

echo ""
echo "--- 2. [HAPPY PATH] PROJECT_CONTEXT.md documenta tests/run.sh e as 5 subcategorias de tests/features/ ---"
check "PROJECT_CONTEXT.md referencia o runner centralizado 'tests/run.sh'" grep -q 'tests/run.sh' "$PROJECT_CONTEXT"
check "PROJECT_CONTEXT.md referencia 'tests/core/'" grep -q 'tests/core/' "$PROJECT_CONTEXT"
for domain in "pipeline/" "governance/" "ui-ux/" "wiki/" "statusline/"; do
  check "PROJECT_CONTEXT.md lista a subcategoria de domínio tests/features/$domain" grep -q "$domain" "$PROJECT_CONTEXT"
done

echo ""
echo "--- 3. [HAPPY PATH] agents/qa-engineer/agent.md instrui alocação em tests/features/<categoria>/ e ./tests/run.sh ---"
check "qa-engineer/agent.md instrui uso de subpastas tests/features/<categoria>/" grep -q 'tests/features/<categoria>/' "$QA_AGENT"
check "qa-engineer/agent.md referencia o runner './tests/run.sh'" grep -q '\./tests/run\.sh' "$QA_AGENT"
for domain in "pipeline/" "governance/" "ui-ux/" "wiki/" "statusline/"; do
  check "qa-engineer/agent.md explicita o domínio $domain" grep -q "$domain" "$QA_AGENT"
done

# =============================================================================
# SEÇÃO 2: EDGE CASES & FAILURE MODES
# =============================================================================
echo ""
echo "--- 4. [EDGE CASE] Limite de 40 linhas em PROJECT_CONTEXT.md para evitar truncamento no SessionStart hook ---"
LINE_COUNT="$(wc -l < "$PROJECT_CONTEXT" | tr -d ' ')"
check "PROJECT_CONTEXT.md possui no máximo 40 linhas (atual: $LINE_COUNT)" test "$LINE_COUNT" -le 40

HOOK_JSON="$(printf '{"workspacePaths": ["%s"]}' "$REPO_ROOT" | "$SESSION_HOOK")"
check "session-start-context.sh injeta até o final da seção Rastreamento & GitHub Governance sem truncar" bash -c "printf '%s' '$HOOK_JSON' | grep -q 'Default Release'"

echo ""
echo "--- 5. [EDGE CASE / FAILURE MODE] Preservação de Invariantes e Ausência de Estado Volátil em PROJECT_CONTEXT.md ---"
check "PROJECT_CONTEXT.md permanece livre de 'Branch Ativa'" bash -c "! grep -q 'Branch Ativa' '$PROJECT_CONTEXT'"
check "PROJECT_CONTEXT.md permanece livre de 'Último Commit'" bash -c "! grep -q 'Último Commit' '$PROJECT_CONTEXT'"
check "PROJECT_CONTEXT.md permanece livre de 'Estado Atual da Arquitetura'" bash -c "! grep -q 'Estado Atual da Arquitetura' '$PROJECT_CONTEXT'"
check "qa-engineer/agent.md mantém proibição estrita de tocar em 'src/' e 'tests/core/'" bash -c "grep -q 'PROIBIDO tocar em \`src/\`' '$QA_AGENT' && grep -q 'PROIBIDO tocar em \`tests/core/\`' '$QA_AGENT'"

echo ""
echo "========================================================================"
echo " Resumo: $PASSED passaram | $FAILED falharam"
echo "========================================================================"
if [ "$FAILED" -ne 0 ]; then
  echo " >>> RESULTADO: RED (Falha esperada na fase TDD RED)"
  echo "========================================================================"
  exit 1
else
  echo " >>> RESULTADO: GREEN (Todos os testes passaram)"
  echo "========================================================================"
  exit 0
fi
