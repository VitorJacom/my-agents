#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tests/features/test_milestone_plan_feature.sh - Issue #19 TDD Suite
# Validação do suporte nativo à vinculação de Milestones no /plan-feature
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
    echo "  [FAIL] $msg: Padrão '$pattern' foi encontrado indevidamente em $file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "========================================================================"
echo " [TEST] Issue #19: Native Milestone Binding in /plan-feature"
echo "========================================================================"

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTEXT_FILE="$WORKSPACE_ROOT/PROJECT_CONTEXT.md"
PLAN_SKILL_FILE="$WORKSPACE_ROOT/skills/plan-feature/SKILL.md"

# --- 1. [HAPPY PATH] Verificação da Seção Canônica em PROJECT_CONTEXT.md ---
echo ""
echo "--- 1. [HAPPY PATH] Seção Canônica de Governança e Milestone em PROJECT_CONTEXT.md ---"
assert_contains "$CONTEXT_FILE" "^## 🎯 Rastreamento & GitHub Governance" "PROJECT_CONTEXT.md possui a seção '## 🎯 Rastreamento & GitHub Governance'"
assert_contains "$CONTEXT_FILE" "Active Milestone" "PROJECT_CONTEXT.md declara a chave 'Active Milestone'"

# --- 2. [HAPPY PATH] Instrução e Suporte a Milestone em skills/plan-feature/SKILL.md ---
echo ""
echo "--- 2. [HAPPY PATH] Especificação do Estado 4 em skills/plan-feature/SKILL.md ---"
assert_contains "$PLAN_SKILL_FILE" "Active Milestone" "SKILL.md referencia detecção de 'Active Milestone'"
assert_contains "$PLAN_SKILL_FILE" "--milestone" "SKILL.md instrui a flag '--milestone' no gh issue create"

# --- 3. [HAPPY PATH & EDGE CASES] Teste Funcional da Lógica de Extração de Milestone ---
echo ""
echo "--- 3. [FUNCTIONAL] Avaliação da Lógica de Extração e Injeção de Milestone ---"

# Função canônica de extração a ser validada
extract_milestone() {
  local context_content="$1"
  local raw_val
  raw_val=$(echo "$context_content" | grep -E "^\s*-\s*\*\*Active Milestone\*\*:" | head -n 1 | sed -E 's/.*:\s*"?([^"]*)"?/\1/' | tr -d '\r' | xargs || true)
  if [ -z "$raw_val" ] || [ "$raw_val" = "None" ] || [ "$raw_val" = "none" ] || [ "$raw_val" = '""' ]; then
    echo ""
  else
    echo "$raw_val"
  fi
}

# Cenário 1: Milestone ativa presente com aspas
SAMPLE_WITH_MILESTONE=$(cat <<'EOF'
## 🎯 Rastreamento & GitHub Governance
- **Active Milestone**: "v1.1.0"
EOF
)
M1=$(extract_milestone "$SAMPLE_WITH_MILESTONE")
assert_equals "v1.1.0" "$M1" "Extrai corretamente Milestone com aspas ('v1.1.0')"

# Cenário 2: Milestone ativa presente sem aspas
SAMPLE_NO_QUOTES=$(cat <<'EOF'
## 🎯 Rastreamento & GitHub Governance
- **Active Milestone**: v2.0.0
EOF
)
M2=$(extract_milestone "$SAMPLE_NO_QUOTES")
assert_equals "v2.0.0" "$M2" "Extrai corretamente Milestone sem aspas ('v2.0.0')"

# Cenário 3: Milestone definida explicitamente como None
SAMPLE_NONE=$(cat <<'EOF'
## 🎯 Rastreamento & GitHub Governance
- **Active Milestone**: None
EOF
)
M3=$(extract_milestone "$SAMPLE_NONE")
assert_equals "" "$M3" "Trata 'Active Milestone: None' como vazio (sem flag --milestone)"

# Cenário 4: Chave ausente
SAMPLE_EMPTY=$(cat <<'EOF'
## 🎯 Rastreamento & GitHub Governance
EOF
)
M4=$(extract_milestone "$SAMPLE_EMPTY")
assert_equals "" "$M4" "Trata ausência de Active Milestone como vazio"

# Cenário 5: Flag builder logic
build_gh_issue_cmd() {
  local title="$1"
  local milestone="$2"
  local cmd="gh issue create --title \"$title\" --label \"enhancement,planned\""
  if [ -n "$milestone" ]; then
    cmd="$cmd --milestone \"$milestone\""
  fi
  echo "$cmd"
}

CMD_WITH_M=$(build_gh_issue_cmd "feat(test): task" "v1.1.0")
CMD_WITHOUT_M=$(build_gh_issue_cmd "feat(test): task" "")

if [[ "$CMD_WITH_M" == *'--milestone "v1.1.0"'* ]]; then
  echo "  [PASS] Flag --milestone injetada quando milestone está presente"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] Flag --milestone não foi injetada quando esperada"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

if [[ "$CMD_WITHOUT_M" != *'--milestone'* ]]; then
  echo "  [PASS] Flag --milestone omitida quando milestone é vazia/None"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] Flag --milestone foi injetada indevidamente quando vazia"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo "========================================================================"
echo " Resumo: $TESTS_PASSED passaram | $TESTS_FAILED falharam"
echo "========================================================================"

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo " >>> RESULTADO: GREEN (Sucesso: todos os critérios foram atendidos)"
  exit 0
else
  echo " >>> RESULTADO: RED (Falhas detectadas)"
  exit 1
fi
