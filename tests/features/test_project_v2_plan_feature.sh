#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tests/features/test_project_v2_plan_feature.sh - Issue #20 TDD Suite
# Validação da vinculação de issues a GitHub Projects v2 com degradação graciosa
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

echo "========================================================================"
echo " [TEST] Issue #20: Binding Issues to GitHub Projects v2 in /plan-feature"
echo "========================================================================"

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTEXT_FILE="$WORKSPACE_ROOT/PROJECT_CONTEXT.md"
PLAN_SKILL_FILE="$WORKSPACE_ROOT/skills/plan-feature/SKILL.md"

# --- 1. [HAPPY PATH] Verificação da Seção Canônica de Governança em PROJECT_CONTEXT.md ---
echo ""
echo "--- 1. [HAPPY PATH] Metadados de GitHub Projects v2 em PROJECT_CONTEXT.md ---"
assert_contains "$CONTEXT_FILE" "GitHub Project v2" "PROJECT_CONTEXT.md declara 'GitHub Project v2'"
assert_contains "$CONTEXT_FILE" "Owner" "PROJECT_CONTEXT.md declara chave 'Owner' para projetos"
assert_contains "$CONTEXT_FILE" "Project Number" "PROJECT_CONTEXT.md declara chave 'Project Number'"

# --- 2. [HAPPY PATH] Especificação do Estado 4 em skills/plan-feature/SKILL.md ---
echo ""
echo "--- 2. [HAPPY PATH] Especificação do Estado 4 em skills/plan-feature/SKILL.md ---"
assert_contains "$PLAN_SKILL_FILE" "project item-add" "SKILL.md instrui a chamada 'gh project item-add'"
assert_contains "$PLAN_SKILL_FILE" "⚠️ \[WARN\]" "SKILL.md especifica aviso não-bloqueante '⚠️ [WARN]' sob falha"

# --- 3. [FUNCTIONAL] Simulação da Vinculação e Degradação Graciosa ---
echo ""
echo "--- 3. [FUNCTIONAL & EDGE CASES] Avaliação da Lógica de Adição com Degradação Graciosa ---"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_GH_BIN="$TMP_DIR/bin/gh"
mkdir -p "$TMP_DIR/bin"
MOCK_LOG="$TMP_DIR/gh_project_add.log"

cat <<EOF > "$MOCK_GH_BIN"
#!/usr/bin/env bash
echo "\$@" >> "$MOCK_LOG"
if [ "\${MOCK_PROJECT_FAIL:-0}" = "1" ]; then
  echo "graphql error: Resource not accessible by personal access token" >&2
  exit 1
fi
exit 0
EOF
chmod +x "$MOCK_GH_BIN"

# Função simula a ação do Estado 4 de vinculação ao projeto v2
bind_issue_to_project() {
  local project_num="$1"
  local owner="$2"
  local issue_url="$3"

  if [ -z "$project_num" ] || [ "$project_num" = "None" ] || [ -z "$owner" ] || [ "$owner" = "None" ]; then
    echo "[INFO] GitHub Project v2 não configurado. Pulando adição."
    return 0
  fi

  if ! gh project item-add "$project_num" --owner "$owner" --url "$issue_url" 2>&1; then
    echo "⚠️ [WARN] Falha não-bloqueante ao adicionar issue ao GitHub Project v2 ($project_num). Prosseguindo esteira."
    return 0
  fi
  return 0
}

# Cenário 1: Projeto ativo com credenciais válidas (Happy Path)
> "$MOCK_LOG"
OUT_HP=$(PATH="$TMP_DIR/bin:$PATH" bind_issue_to_project 1 "VitorJacom" "https://github.com/VitorJacom/my-agents/issues/99")
EXIT_HP=$?
assert_equals "0" "$EXIT_HP" "Vinculação conclui com código 0 sob sucesso"

if grep -q -E "project item-add 1 --owner VitorJacom --url https://github.com/VitorJacom/my-agents/issues/99" "$MOCK_LOG"; then
  echo "  [PASS] gh project item-add executado com número do projeto, owner e issue url"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] gh project item-add não foi executado corretamente"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Cenário 2: Falha no comando gh (ex.: erro 403 / falta de permissão)
> "$MOCK_LOG"
OUT_FAIL=$(MOCK_PROJECT_FAIL=1 PATH="$TMP_DIR/bin:$PATH" bind_issue_to_project 1 "VitorJacom" "https://github.com/VitorJacom/my-agents/issues/99")
EXIT_FAIL=$?
assert_equals "0" "$EXIT_FAIL" "Vinculação conclui com código 0 mesmo sob erro de API (non-blocking)"

if echo "$OUT_FAIL" | grep -q "⚠️ \[WARN\]"; then
  echo "  [PASS] Aviso '⚠️ [WARN]' emitido e falha não bloqueou a esteira"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] Aviso '⚠️ [WARN]' não emitido sob falha"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Cenário 3: Projeto inexistente ou 'Project Number: None'
> "$MOCK_LOG"
OUT_NONE=$(PATH="$TMP_DIR/bin:$PATH" bind_issue_to_project "None" "VitorJacom" "https://github.com/VitorJacom/my-agents/issues/99")
EXIT_NONE=$?
assert_equals "0" "$EXIT_NONE" "Vinculação não dispara gh quando Project Number é None"

if [ -s "$MOCK_LOG" ]; then
  echo "  [FAIL] gh project item-add disparado indevidamente para Project Number: None"
  TESTS_FAILED=$((TESTS_FAILED + 1))
else
  echo "  [PASS] gh project item-add omitido com sucesso para Project Number: None"
  TESTS_PASSED=$((TESTS_PASSED + 1))
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
