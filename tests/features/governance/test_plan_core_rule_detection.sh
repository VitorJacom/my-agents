#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tests/features/governance/test_plan_core_rule_detection.sh - Issue #63 TDD Suite
# Validação do protocolo de identificação concreta e classificação de regras core no /plan-feature
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
echo " [TEST] Issue #63: Protocolo de Identificação Concreta de Regras Core"
echo "========================================================================"

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PO_AGENT="$WORKSPACE_ROOT/agents/product-owner/agent.md"
PLAN_SKILL="$WORKSPACE_ROOT/skills/plan-feature/SKILL.md"
ARCH_AGENT="$WORKSPACE_ROOT/agents/system-architect/agent.md"
PLANNER_AGENT="$WORKSPACE_ROOT/agents/planner/agent.md"

# --- 1. [HAPPY PATH] Diretrizes no Product Owner (agents/product-owner/agent.md) ---
echo ""
echo "--- 1. [HAPPY PATH] Protocolo de Identificação Concreta em agents/product-owner/agent.md ---"
assert_contains "$PO_AGENT" "tests/core/" "PO referencia proteção/blindagem em tests/core/"
assert_contains "$PO_AGENT" "perguntas genéricas" "PO proíbe perguntas genéricas no vácuo sobre regras core"
assert_contains "$PO_AGENT" "A regra .* é uma Regra Core invariante que deve ser blindada em tests/core/\?" "PO instrui o formato canônico de pergunta concreta"

# --- 2. [HAPPY PATH] Especificação do Estado 1 em skills/plan-feature/SKILL.md ---
echo ""
echo "--- 2. [HAPPY PATH] Diretriz de Descoberta Funcional em skills/plan-feature/SKILL.md ---"
assert_contains "$PLAN_SKILL" "perguntas genéricas" "SKILL.md proíbe perguntas genéricas no vácuo sobre regras core"
assert_contains "$PLAN_SKILL" "A regra .* é uma Regra Core invariante que deve ser blindada em tests/core/\?" "SKILL.md instrui formato canônico de pergunta concreta para regras core"
assert_contains "$PLAN_SKILL" "tests/core/" "SKILL.md referencia blindagem em tests/core/"

# --- 3. [HAPPY PATH] Metadados em System Architect (agents/system-architect/agent.md) ---
echo ""
echo "--- 3. [HAPPY PATH] Propagação de CORE_RULE em agents/system-architect/agent.md ---"
assert_contains "$ARCH_AGENT" "CORE_RULE" "Arquiteto documenta e propaga metadado CORE_RULE"
assert_contains "$ARCH_AGENT" "tests/core/" "Arquiteto lista testes de aceitação candidatos a core em tests/core/"

# --- 4. [HAPPY PATH] Metadados em Planner (agents/planner/agent.md) ---
echo ""
echo "--- 4. [HAPPY PATH] Propagação de CORE_RULE em agents/planner/agent.md ---"
assert_contains "$PLANNER_AGENT" "CORE_RULE" "Planner documenta e propaga metadado CORE_RULE"
assert_contains "$PLANNER_AGENT" "tests/core/" "Planner lista regras e testes candidatos a core para tests/core/"

# --- 5. [FUNCTIONAL & EDGE CASES] Validador de Perguntas de Regras Core ---
echo ""
echo "--- 5. [FUNCTIONAL & EDGE CASES] Validação de Perguntas Válidas vs Genéricas ---"

validate_core_rule_question() {
  local question="$1"
  # Deve coincidir com o padrão canônico:
  # "A regra <descrição> é uma Regra Core invariante que deve ser blindada em tests/core/?"
  if [[ "$question" =~ ^A\ regra\ (.+)\ é\ uma\ Regra\ Core\ invariante\ que\ deve\ ser\ blindada\ em\ tests/core/\?$ ]]; then
    local description="${BASH_REMATCH[1]}"
    # Rejeitar se for placeholder ou vazio ou genérico
    if [ -z "$description" ] || [ "$description" = "[Descrição Concreta da Regra]" ] || [ "$description" = "<descrição>" ]; then
      echo "INVALID_PLACEHOLDER"
      return 1
    fi
    echo "VALID"
    return 0
  else
    echo "INVALID_GENERIC"
    return 1
  fi
}

# Cenário 1: Pergunta concreta válida (Happy Path)
Q_VALID="A regra O saldo nunca pode ser negativo é uma Regra Core invariante que deve ser blindada em tests/core/?"
RES_VALID=$(validate_core_rule_question "$Q_VALID" || true)
assert_equals "VALID" "$RES_VALID" "Validador aceita pergunta formulada concretamente"

# Cenário 2: Pergunta genérica no vácuo (Edge Case / Failure Mode)
Q_GENERIC="Existe alguma regra core invariante para este módulo?"
RES_GENERIC=$(validate_core_rule_question "$Q_GENERIC" || true)
assert_equals "INVALID_GENERIC" "$RES_GENERIC" "Validador rejeita pergunta genérica no vácuo"

# Cenário 3: Pergunta contendo placeholder não preenchido (Edge Case / Failure Mode)
Q_PLACEHOLDER="A regra [Descrição Concreta da Regra] é uma Regra Core invariante que deve ser blindada em tests/core/?"
RES_PLACEHOLDER=$(validate_core_rule_question "$Q_PLACEHOLDER" || true)
assert_equals "INVALID_PLACEHOLDER" "$RES_PLACEHOLDER" "Validador rejeita placeholder não preenchido"

# Cenário 4: Outra variação vaga sem template canônico (Edge Case / Failure Mode)
Q_VAGUE="Há alguma regra core que devemos blindar em tests/core/?"
RES_VAGUE=$(validate_core_rule_question "$Q_VAGUE" || true)
assert_equals "INVALID_GENERIC" "$RES_VAGUE" "Validador rejeita pergunta vaga informal"

# --- 6. [FUNCTIONAL & EDGE CASES] Parsing de Metadado CORE_RULE em Planos ---
echo ""
echo "--- 6. [FUNCTIONAL & EDGE CASES] Parsing de Metadado CORE_RULE em Planos ---"

extract_core_rule_metadata() {
  local content="$1"
  local raw_val
  raw_val=$(echo "$content" | grep -E "^\s*-\s*\*\*CORE_RULE\*\*:" | head -n 1 | sed -E 's/.*:\s*"?([^"]*)"?/\1/' | tr -d '\r' | xargs || true)
  if [ -z "$raw_val" ]; then
    raw_val=$(echo "$content" | grep -E "^CORE_RULE:" | head -n 1 | sed -E 's/CORE_RULE:\s*"?([^"]*)"?/\1/' | tr -d '\r' | xargs || true)
  fi
  if [ -z "$raw_val" ]; then
    echo "NOT_FOUND"
  else
    echo "$raw_val"
  fi
}

SAMPLE_WITH_CORE_TRUE=$(cat <<'EOF'
## Interface Contract & Governança
- **CORE_RULE**: true
- **Core Candidates**: A regra de unicidade de chave primária em tests/core/test_db_unique.sh
EOF
)
RES_CORE_TRUE=$(extract_core_rule_metadata "$SAMPLE_WITH_CORE_TRUE")
assert_equals "true" "$RES_CORE_TRUE" "Extrai CORE_RULE: true de proposta/plano"

SAMPLE_WITH_CORE_FALSE=$(cat <<'EOF'
## Interface Contract & Governança
- **CORE_RULE**: false
EOF
)
RES_CORE_FALSE=$(extract_core_rule_metadata "$SAMPLE_WITH_CORE_FALSE")
assert_equals "false" "$RES_CORE_FALSE" "Extrai CORE_RULE: false de proposta/plano"

SAMPLE_WITHOUT_CORE=$(cat <<'EOF'
## Interface Contract & Governança
- **UI_UX_REQUIRED**: false
EOF
)
RES_NO_CORE=$(extract_core_rule_metadata "$SAMPLE_WITHOUT_CORE")
assert_equals "NOT_FOUND" "$RES_NO_CORE" "Retorna NOT_FOUND quando metadado CORE_RULE está ausente"

# =============================================================================
# Resumo Final
# =============================================================================
echo ""
echo "========================================================================"
echo " RESUMO DO TESTE: $TESTS_PASSED passou, $TESTS_FAILED falhou"
echo "========================================================================"

if [ "$TESTS_FAILED" -gt 0 ]; then
  echo "❌ FALHA: $TESTS_FAILED asserção(ões) falharam."
  exit 1
else
  echo "✅ SUCESSO: Todas as asserções passaram."
  exit 0
fi
