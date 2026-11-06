#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tests/features/test_labels_views_conventions.sh - Issue #22 TDD Suite
# Validação da padronização de Views no GitHub Projects v2 e taxonomia de Labels AIDD
# =============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  [PASS] $msg"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] $msg: Esperado '$expected', obtido '$actual'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

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

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  local msg="$3"
  if ! grep -q -E -e "$pattern" "$file"; then
    echo "  [PASS] $msg"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] $msg: Padrão proibido '$pattern' encontrado em $file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "========================================================================"
echo " [TEST] Issue #22: Standardization of Views and Labels in AIDD Ecosystem"
echo "========================================================================"

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARCH_FILE="$WORKSPACE_ROOT/docs/ARCHITECTURE.md"
PLAN_SKILL_FILE="$WORKSPACE_ROOT/skills/plan-feature/SKILL.md"

# --- 1. [HAPPY PATH] Verificação das Views Essenciais no GitHub Projects v2 ---
echo ""
echo "--- 1. [HAPPY PATH] Views Essenciais no GitHub Projects v2 em docs/ARCHITECTURE.md ---"
assert_contains "$ARCH_FILE" "Kanban" "docs/ARCHITECTURE.md documenta View Kanban"
assert_contains "$ARCH_FILE" "Milestone Roadmap|Roadmap" "docs/ARCHITECTURE.md documenta View Milestone Roadmap"
assert_contains "$ARCH_FILE" "Backlog" "docs/ARCHITECTURE.md documenta View Backlog"

# --- 2. [HAPPY PATH] Taxonomia Oficial de Labels AIDD em docs/ARCHITECTURE.md ---
echo ""
echo "--- 2. [HAPPY PATH] Taxonomia Oficial de Labels AIDD em docs/ARCHITECTURE.md ---"
# Categorias principais
assert_contains "$ARCH_FILE" "type:\*" "docs/ARCHITECTURE.md documenta categoria type:*"
assert_contains "$ARCH_FILE" "status:\*" "docs/ARCHITECTURE.md documenta categoria status:*"
assert_contains "$ARCH_FILE" "aidd:\*" "docs/ARCHITECTURE.md documenta categoria aidd:*"

# Tipos (Conventional Commits)
assert_contains "$ARCH_FILE" "type:feat" "docs/ARCHITECTURE.md documenta label type:feat"
assert_contains "$ARCH_FILE" "type:fix" "docs/ARCHITECTURE.md documenta label type:fix"
assert_contains "$ARCH_FILE" "type:docs" "docs/ARCHITECTURE.md documenta label type:docs"
assert_contains "$ARCH_FILE" "type:refactor" "docs/ARCHITECTURE.md documenta label type:refactor"
assert_contains "$ARCH_FILE" "type:chore" "docs/ARCHITECTURE.md documenta label type:chore"
assert_contains "$ARCH_FILE" "type:test" "docs/ARCHITECTURE.md documenta label type:test"

# Status de Ciclo de Vida
assert_contains "$ARCH_FILE" "status:planned" "docs/ARCHITECTURE.md documenta label status:planned"
assert_contains "$ARCH_FILE" "status:in-progress" "docs/ARCHITECTURE.md documenta label status:in-progress"
assert_contains "$ARCH_FILE" "status:blocked" "docs/ARCHITECTURE.md documenta label status:blocked"
assert_contains "$ARCH_FILE" "status:ready-for-review" "docs/ARCHITECTURE.md documenta label status:ready-for-review"

# Escopos de Automação/Governança AIDD
assert_contains "$ARCH_FILE" "aidd:wave-" "docs/ARCHITECTURE.md documenta label aidd:wave-*"
assert_contains "$ARCH_FILE" "aidd:clean-room" "docs/ARCHITECTURE.md documenta label aidd:clean-room"
assert_contains "$ARCH_FILE" "aidd:reconciled" "docs/ARCHITECTURE.md documenta label aidd:reconciled"

# --- 3. [HAPPY PATH] Conformidade na Skill plan-feature ---
echo ""
echo "--- 3. [HAPPY PATH] Conformidade de Labels em skills/plan-feature/SKILL.md ---"
assert_contains "$PLAN_SKILL_FILE" "type:feat" "skills/plan-feature/SKILL.md utiliza label padronizada type:feat"
assert_contains "$PLAN_SKILL_FILE" "status:planned" "skills/plan-feature/SKILL.md utiliza label padronizada status:planned"

# --- 4. [EDGE CASES & NEGATIVE CHECKS] Prevenção de Regressão e Antipatters ---
echo ""
echo "--- 4. [EDGE CASES] Prevenção de Regressões e Labels Legadas ---"
assert_not_contains "$PLAN_SKILL_FILE" "enhancement,planned" "skills/plan-feature/SKILL.md não contém label legada 'enhancement,planned'"
assert_contains "$ARCH_FILE" "Status" "docs/ARCHITECTURE.md detalha agrupamento/campo Status para o Board Kanban"

# --- Resumo Final ---
echo ""
echo "========================================================================"
echo " Resumo dos Testes: $TESTS_PASSED passaram, $TESTS_FAILED falharam."
echo "========================================================================"

if [ "$TESTS_FAILED" -gt 0 ]; then
  exit 1
fi
