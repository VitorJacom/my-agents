#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tests/features/governance/test_golden_rule_diff_filter.sh - Issue #65 TDD Suite
# Validação da modernização da Golden Rule Anti-Fraude com --diff-filter=MD (ADR-0015)
# =============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RULES_MD="$REPO_ROOT/rules/AGENTS.md"
GATEKEEPER_MD="$REPO_ROOT/agents/gatekeeper/agent.md"
AIDD_MANIFESTO="$REPO_ROOT/docs/AIDD-Manifesto.md"
SUBAGENTS_MD="$REPO_ROOT/docs/Subagents.md"
SYSTEM_ARCH_MD="$REPO_ROOT/docs/System-Architecture.md"
ARCH_MD="$REPO_ROOT/docs/ARCHITECTURE.md"

TESTS_PASSED=0
TESTS_FAILED=0

assert_true() {
  local msg="$1"
  shift
  if "$@"; then
    echo "  [PASS] $msg"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] $msg"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_false() {
  local msg="$1"
  shift
  if ! "$@"; then
    echo "  [PASS] $msg"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] $msg (Esperado falso/falha)"
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

# Função auxiliar que executa a checagem canônica da Golden Rule
run_golden_rule_check() {
  local target_dir="$1"
  local base_branch="${2:-main}"

  (
    cd "$target_dir"
    BASE_BRANCH="$base_branch"
    MODIFIED=$(git diff --diff-filter=MD --name-only "$BASE_BRANCH...HEAD" 2>/dev/null | grep -E '^tests/core/' || true)
    if [ -n "$MODIFIED" ]; then
      echo "ALERTA DE FRAUDE: O agente modificou ou removeu arquivos protegidos em tests/core/: $MODIFIED"
      return 1
    fi
    return 0
  )
}

echo "========================================================================"
echo " [TEST] Issue #65: Modernização da Golden Rule Anti-Fraude (--diff-filter=MD)"
echo "========================================================================"
echo ""

# Configuração de repositório Git sandbox para testes determinísticos
TEMP_SANDBOX=$(mktemp -d "/tmp/golden_rule_sandbox_XXXXXX")
cleanup() {
  rm -rf "$TEMP_SANDBOX"
}
trap cleanup EXIT

# Inicialização do repositório Git estéril
git -C "$TEMP_SANDBOX" init -q -b main
git -C "$TEMP_SANDBOX" config user.email "aidd-test@example.com"
git -C "$TEMP_SANDBOX" config user.name "AIDD Test Runner"

mkdir -p "$TEMP_SANDBOX/tests/core" "$TEMP_SANDBOX/tests/features" "$TEMP_SANDBOX/src"
echo 'echo "core test 1"' > "$TEMP_SANDBOX/tests/core/test_baseline.sh"
echo 'console.log("src");' > "$TEMP_SANDBOX/src/index.js"
git -C "$TEMP_SANDBOX" add .
git -C "$TEMP_SANDBOX" commit -q -m "chore: initial commit with baseline tests/core"

# Criar branch de trabalho
git -C "$TEMP_SANDBOX" checkout -q -b feature/issue-promotion

echo "--- 1. [HAPPY PATH] Comportamento Dinâmico da Golden Rule Modernizada ---"

# HP-01: Adição de novo teste legítimo em tests/core/ (Promoção pós-GREEN) não deve ser bloqueada
echo 'echo "new promoted core test"' > "$TEMP_SANDBOX/tests/core/test_promoted_rule.sh"
git -C "$TEMP_SANDBOX" add "tests/core/test_promoted_rule.sh"
git -C "$TEMP_SANDBOX" commit -q -m "feat(core): promover teste de regra core"

assert_true "HP-01: Adição legítima de novo teste em tests/core/ não dispara falso positivo de fraude" \
  run_golden_rule_check "$TEMP_SANDBOX" "main"

# HP-02: Alterações em tests/features/ e src/ não são bloqueadas pela Golden Rule de tests/core/
echo 'echo "feature test"' > "$TEMP_SANDBOX/tests/features/test_new_feature.sh"
echo 'console.log("updated");' >> "$TEMP_SANDBOX/src/index.js"
git -C "$TEMP_SANDBOX" add tests/features/ src/
git -C "$TEMP_SANDBOX" commit -q -m "feat: adicionar feature e atualizar src"

assert_true "HP-02: Modificações fora de tests/core/ não acionam a Golden Rule" \
  run_golden_rule_check "$TEMP_SANDBOX" "main"

# HP-03: Suporte a BASE_BRANCH parametrizada
assert_true "HP-03: Golden Rule funciona com parâmetro explícito de BASE_BRANCH" \
  run_golden_rule_check "$TEMP_SANDBOX" "feature/issue-promotion~1"

echo ""
echo "--- 2. [EDGE CASES & FAILURE MODES] Circuit-Breaker contra Fraudes ---"

# EC-01: Modificação de teste pré-existente em tests/core/ deve falhar com exit code 1
echo 'echo "tampered test"' > "$TEMP_SANDBOX/tests/core/test_baseline.sh"
git -C "$TEMP_SANDBOX" add "$TEMP_SANDBOX/tests/core/test_baseline.sh"
git -C "$TEMP_SANDBOX" commit -q -m "fraud: adulterar teste pré-existente"

assert_false "EC-01: Modificação ilegal em tests/core/ é bloqueada com exit code 1" \
  run_golden_rule_check "$TEMP_SANDBOX" "main"

# Restaurar baseline para testar deleção
git -C "$TEMP_SANDBOX" revert --no-edit HEAD >/dev/null 2>&1

# EC-02: Deleção de teste pré-existente em tests/core/ deve falhar com exit code 1
git -C "$TEMP_SANDBOX" rm -q "$TEMP_SANDBOX/tests/core/test_baseline.sh"
git -C "$TEMP_SANDBOX" commit -q -m "fraud: remover teste pré-existente"

assert_false "EC-02: Deleção ilegal em tests/core/ é bloqueada com exit code 1" \
  run_golden_rule_check "$TEMP_SANDBOX" "main"

# Restaurar repositório para estado limpo
git -C "$TEMP_SANDBOX" revert --no-edit HEAD >/dev/null 2>&1

# EC-03: Cenário cumulativo (Adição legítima + Modificação ilícita) deve falhar com exit code 1
echo 'echo "another promoted test"' > "$TEMP_SANDBOX/tests/core/test_promoted_2.sh"
echo 'echo "tampered baseline again"' >> "$TEMP_SANDBOX/tests/core/test_baseline.sh"
git -C "$TEMP_SANDBOX" add tests/core/
git -C "$TEMP_SANDBOX" commit -q -m "fraud: tentar camuflar modificação ilícita junto com adição"

assert_false "EC-03: Tentativa cumulativa de camuflar modificação junto com adição é bloqueada" \
  run_golden_rule_check "$TEMP_SANDBOX" "main"

echo ""
echo "--- 3. [CONFORMIDADE ESTÁTICA] Regras, Personas e Documentação Canônica ---"

# HP-04: rules/AGENTS.md deve conter --diff-filter=MD
assert_contains "$RULES_MD" 'git diff --diff-filter=MD --name-only' \
  "HP-04: rules/AGENTS.md especifica --diff-filter=MD na Golden Rule"

# HP-05: agents/gatekeeper/agent.md deve conter --diff-filter=MD
assert_contains "$GATEKEEPER_MD" 'git diff --diff-filter=MD --name-only' \
  "HP-05: agents/gatekeeper/agent.md especifica --diff-filter=MD na checagem"

# HP-06: docs/AIDD-Manifesto.md deve conter --diff-filter=MD
assert_contains "$AIDD_MANIFESTO" 'git diff --diff-filter=MD --name-only' \
  "HP-06: docs/AIDD-Manifesto.md documenta o snippet atualizado com --diff-filter=MD"

# HP-07: docs/Subagents.md deve conter --diff-filter=MD
assert_contains "$SUBAGENTS_MD" 'git diff --diff-filter=MD --name-only' \
  "HP-07: docs/Subagents.md documenta a checagem do Gatekeeper com --diff-filter=MD"

# HP-08: docs/System-Architecture.md e docs/ARCHITECTURE.md registram ADR-0015 com --diff-filter=MD
assert_contains "$SYSTEM_ARCH_MD" '0015' \
  "HP-08a: docs/System-Architecture.md contém ADR-0015 no Índice de ADRs"
assert_contains "$SYSTEM_ARCH_MD" '--diff-filter=MD' \
  "HP-08b: docs/System-Architecture.md menciona --diff-filter=MD na descrição da ADR-0015"
assert_contains "$ARCH_MD" 'Decisão 0015' \
  "HP-08c: docs/ARCHITECTURE.md contém a Decisão 0015 consolidada"
assert_contains "$ARCH_MD" '--diff-filter=MD' \
  "HP-08d: docs/ARCHITECTURE.md especifica a modernização com --diff-filter=MD"

echo ""
echo "========================================================================"
echo " RESUMO DA SUÍTE: $TESTS_PASSED passou, $TESTS_FAILED falhou"
echo "========================================================================"

if [ "$TESTS_FAILED" -gt 0 ]; then
  echo " >>> RESULTADO: RED (Falhas detectadas conforme esperado no ciclo TDD)"
  exit 1
else
  echo " >>> RESULTADO: GREEN (Todos os testes passaram com sucesso)"
  exit 0
fi
