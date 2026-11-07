#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tests/features/governance/test_publish_rule_issue_governance.sh - Issue #44 TDD Suite
# Validação da modernização do publish-rule-issue com governança e contratos atômicos
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
echo " [TEST] Issue #44: Governance & Atomic Contracts in publish-rule-issue"
echo "========================================================================"

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SKILL_FILE="$WORKSPACE_ROOT/skills/publish-rule-issue/SKILL.md"

# --- 1. [HAPPY PATH] Verificação dos Contratos Atômicos no Template da Issue ---
echo ""
echo "--- 1. [HAPPY PATH] Verificação dos Contratos Atômicos no Template da Issue ---"
assert_contains "$SKILL_FILE" "## Target Files & Dependencies" "Template possui a seção '## Target Files & Dependencies'"
assert_contains "$SKILL_FILE" "Target Files:" "Template inclui o campo 'Target Files:'"
assert_contains "$SKILL_FILE" "Depends On:" "Template inclui o campo 'Depends On:'"
assert_contains "$SKILL_FILE" "## Passos de Implementação \(<= 3 passos\)" "Template inclui '## Passos de Implementação (<= 3 passos)'"

# --- 2. [HAPPY PATH] Flags e Governança no gh issue create ---
echo ""
echo "--- 2. [HAPPY PATH] Flags e Governança no gh issue create ---"
assert_contains "$SKILL_FILE" '--label\s+"enhancement,planned"' "Comando gh issue create utiliza '--label \"enhancement,planned\"'"
assert_contains "$SKILL_FILE" "Active Milestone" "Procedimento instrui a leitura de Active Milestone em PROJECT_CONTEXT.md"
assert_contains "$SKILL_FILE" "--milestone" "Procedimento instrui anexar '--milestone' dinamicamente"

# --- 3. [HAPPY PATH] Vinculação a GitHub Project v2 com Fallback Resiliente ---
echo ""
echo "--- 3. [HAPPY PATH] Vinculação a GitHub Project v2 com Fallback Resiliente ---"
assert_contains "$SKILL_FILE" "gh project item-add" "Procedimento inclui 'gh project item-add'"
assert_contains "$SKILL_FILE" '\|\|\s*echo\s+"⚠️\s*\[WARN\]' "gh project item-add utiliza fallback não-bloqueante '|| echo \"⚠️ [WARN]...\"'"

# --- 4. [FUNCTIONAL & EDGE CASES] Teste Funcional da Extração de Milestone e Fallback ---
echo ""
echo "--- 4. [FUNCTIONAL & EDGE CASES] Avaliação da Lógica de Extração de Milestone ---"

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

# Caso 1: Milestone configurada
M1=$(extract_milestone "- **Active Milestone**: \"v1.1.0\"")
assert_equals "v1.1.0" "$M1" "Extrai milestone válida com aspas ('v1.1.0')"

# Caso 2: Milestone configurada sem aspas
M2=$(extract_milestone "- **Active Milestone**: v2.0.0")
assert_equals "v2.0.0" "$M2" "Extrai milestone válida sem aspas ('v2.0.0')"

# Caso 3: Milestone definida como None
M3=$(extract_milestone "- **Active Milestone**: None")
assert_equals "" "$M3" "Retorna vazio quando Active Milestone é 'None'"

# Caso 4: Milestone ausente
M4=$(extract_milestone "# Contexto sem milestone")
assert_equals "" "$M4" "Retorna vazio quando Active Milestone está ausente"

# --- 5. [FUNCTIONAL & EDGE CASES] Resiliência da Vinculação a Projeto v2 ---
echo ""
echo "--- 5. [FUNCTIONAL & EDGE CASES] Resiliência da Vinculação a Projeto v2 ---"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_GH_BIN="$TMP_DIR/bin/gh"
mkdir -p "$TMP_DIR/bin"
export MOCK_LOG="$TMP_DIR/gh_call.log"

cat <<'EOF' > "$MOCK_GH_BIN"
#!/usr/bin/env bash
echo "$@" >> "$MOCK_LOG"
if [ "${MOCK_PROJECT_FAIL:-0}" = "1" ]; then
  echo "graphql error: Resource not accessible by personal access token" >&2
  exit 1
fi
exit 0
EOF
chmod +x "$MOCK_GH_BIN"

PATH="$TMP_DIR/bin:$PATH"

bind_project_test() {
  local project_num="$1"
  local owner="$2"
  local issue_url="$3"

  if [ -z "$project_num" ] || [ "$project_num" = "None" ] || [ -z "$owner" ] || [ "$owner" = "None" ]; then
    echo "[INFO] GitHub Project v2 não configurado. Pulando."
    return 0
  fi

  gh project item-add "$project_num" --owner "$owner" --url "$issue_url" || echo "⚠️ [WARN] Falha não-bloqueante ao adicionar issue ao GitHub Project v2 ($project_num). Prosseguindo esteira."
}

# Cenário de Sucesso (Happy Path)
> "$MOCK_LOG"
export MOCK_PROJECT_FAIL=0
OUT=$(bind_project_test "1" "VitorJacom" "https://github.com/VitorJacom/my-agents/issues/44")
assert_equals "" "$OUT" "Execução com sucesso não emite warning"
assert_contains "$MOCK_LOG" "project item-add 1 --owner VitorJacom --url https://github.com/VitorJacom/my-agents/issues/44" "Chamou gh project item-add com parâmetros esperados"

# Cenário de Falha (Fallback Resiliente / Degradação Graciosa)
> "$MOCK_LOG"
export MOCK_PROJECT_FAIL=1
OUT_WARN=$(bind_project_test "1" "VitorJacom" "https://github.com/VitorJacom/my-agents/issues/44" 2>&1)
if echo "$OUT_WARN" | grep -q "⚠️ \[WARN\]"; then
  echo "  [PASS] Degradação graciosa acionada com fallback em caso de falha de permissão"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] Degradação graciosa não emitiu warning esperado"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""
echo "========================================================================"
echo " RESUMO: $TESTS_PASSED passou, $TESTS_FAILED falhou"
echo "========================================================================"

if [ "$TESTS_FAILED" -gt 0 ]; then
  exit 1
fi
