#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tests/features/test_issue_46_governance_reconciliation_docs.sh
# Validação determinística das documentações de reconciliação de governança
# e indexação da Decisão 0009 (Issue #46)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TESTS_PASSED=0
TESTS_FAILED=0

assert_contains() {
  local file="$1"
  local pattern="$2"
  local msg="$3"
  if grep -q -E -e "$pattern" "$file"; then
    echo "  [PASS] $msg"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] $msg: Padrão '$pattern' não encontrado em $file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_file_executable() {
  local file="$1"
  local msg="$2"
  if [ -f "$file" ] && [ -x "$file" ]; then
    echo "  [PASS] $msg"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] $msg: Arquivo $file não existe ou não tem permissão de execução"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "=== Iniciando Testes de Aceite da Issue #46 ==="

PLAN_FEATURE_FILE="$WORKSPACE_ROOT/skills/plan-feature/SKILL.md"
ARCHITECTURE_FILE="$WORKSPACE_ROOT/docs/ARCHITECTURE.md"
RECONCILE_SCRIPT="$WORKSPACE_ROOT/scripts/reconcile-github-governance.sh"
PROJECT_CONTEXT_FILE="$WORKSPACE_ROOT/PROJECT_CONTEXT.md"

echo "1. Validando integridade física dos artefatos alvo e scripts referenciados..."
assert_file_executable "$RECONCILE_SCRIPT" "scripts/reconcile-github-governance.sh existe e é executável"
assert_contains "$PLAN_FEATURE_FILE" "name: plan-feature" "skills/plan-feature/SKILL.md está presente e válido"
assert_contains "$ARCHITECTURE_FILE" "# Arquitetura e Decisões Técnicas" "docs/ARCHITECTURE.md está presente e válido"
assert_contains "$PROJECT_CONTEXT_FILE" "Contexto Canônico do Projeto" "PROJECT_CONTEXT.md está presente e válido"

echo "2. Validando documentação operacional em skills/plan-feature/SKILL.md..."
assert_contains "$PLAN_FEATURE_FILE" "## 🛠️ Procedimento Operacional: Reconciliação de Backlog e Governança" "Seção operacional de reconciliação presente"
assert_contains "$PLAN_FEATURE_FILE" "scripts/reconcile-github-governance\.sh" "Referência formal a scripts/reconcile-github-governance.sh"
assert_contains "$PLAN_FEATURE_FILE" "--dry-run" "Documentação do modo simulação (--dry-run) presente"
assert_contains "$PLAN_FEATURE_FILE" "Kanban Board" "Menção à View de Kanban Board"
assert_contains "$PLAN_FEATURE_FILE" "Milestone Roadmap" "Menção à View de Milestone Roadmap"
assert_contains "$PLAN_FEATURE_FILE" "Backlog Table" "Menção à View de Backlog Table"
assert_contains "$PLAN_FEATURE_FILE" "Idempotência Estrita" "Princípio de idempotência estrita documentado"
assert_contains "$PLAN_FEATURE_FILE" "Degradação Graciosa" "Princípio de degradação graciosa documentado"
assert_contains "$PLAN_FEATURE_FILE" "Reconciliação de Governança" "Passo ou transição de reconciliação de governança presente"

echo "3. Validando indexação e integridade em docs/ARCHITECTURE.md..."
assert_contains "$ARCHITECTURE_FILE" "reconcile-github-governance\.sh" "reconcile-github-governance.sh indexado na taxonomia de scripts"
assert_contains "$ARCHITECTURE_FILE" "### Decisão 0009" "Decisão 0009 formalmente declarada"
assert_contains "$ARCHITECTURE_FILE" "Reconciliação Idempotente de Governança" "Título da Decisão 0009 presente"
assert_contains "$ARCHITECTURE_FILE" "\* \*\*Status\*\*: Implementada" "Decisão 0009 com status Implementada"
assert_contains "$ARCHITECTURE_FILE" "scripts/reconcile-github-governance\.sh" "Script citado no corpo da Decisão 0009"

echo "=== Resumo dos Testes da Issue #46 ==="
echo "Passaram: $TESTS_PASSED"
echo "Falharam: $TESTS_FAILED"

if [ "$TESTS_FAILED" -gt 0 ]; then
  echo "❌ Suíte da Issue #46 FALHOU com $TESTS_FAILED erros."
  exit 1
fi

echo "✅ Suíte da Issue #46 passou com 100% de sucesso!"
exit 0
