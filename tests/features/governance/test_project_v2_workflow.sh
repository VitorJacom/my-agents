#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tests/features/governance/test_project_v2_workflow.sh - Issue #72 TDD Suite
# Validação do workflow automatizado de sincronização contínua do GitHub Projects v2
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
  local content="$1"
  local pattern="$2"
  local msg="$3"
  if echo "$content" | grep -q -E -e "$pattern"; then
    echo "  [PASS] $msg"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] $msg: Padrão '$pattern' não encontrado"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_not_contains() {
  local content="$1"
  local pattern="$2"
  local msg="$3"
  if ! echo "$content" | grep -q -E -e "$pattern"; then
    echo "  [PASS] $msg"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] $msg: Padrão '$pattern' encontrado indevidamente"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "========================================================================"
echo " [TEST] Issue #72: Automated GitHub Projects v2 Continuous Sync Workflow"
echo "========================================================================"

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WORKFLOW_FILE="$WORKSPACE_ROOT/.github/workflows/project-v2-automation.yml"

# =============================================================================
# SEÇÃO 1: HAPPY PATH (ESTRUTURA E CONTRATOS DO WORKFLOW)
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Existência do Arquivo e Validação de Sintaxe YAML ---"

if [ -f "$WORKFLOW_FILE" ]; then
  echo "  [PASS] Arquivo .github/workflows/project-v2-automation.yml existe"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] Arquivo .github/workflows/project-v2-automation.yml não encontrado"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  exit 1
fi

YAML_CONTENT=$(cat "$WORKFLOW_FILE")

# Validação sintática via Python PyYAML
PARSED_JSON=$(python3 -c '
import sys, yaml, json
try:
    with open("'"$WORKFLOW_FILE"'", "r") as f:
        data = yaml.safe_load(f)
    print(json.dumps(data))
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
' 2>/dev/null || echo "")

if [ -n "$PARSED_JSON" ]; then
  echo "  [PASS] Sintaxe YAML válida e parseável"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] Sintaxe YAML inválida em project-v2-automation.yml"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""
echo "--- 2. [HAPPY PATH] Configuração de Triggers de Eventos ---"

assert_contains "$YAML_CONTENT" "issues:" "Trigger de evento 'issues' declarado"
assert_contains "$YAML_CONTENT" "opened" "Trigger 'opened' declarado para issues"
assert_contains "$YAML_CONTENT" "reopened" "Trigger 'reopened' declarado para issues"
assert_contains "$YAML_CONTENT" "closed" "Trigger 'closed' declarado para issues"

assert_contains "$YAML_CONTENT" "pull_request:" "Trigger de evento 'pull_request' declarado"
assert_contains "$YAML_CONTENT" "ready_for_review" "Trigger 'ready_for_review' declarado para PRs"

assert_contains "$YAML_CONTENT" "workflow_dispatch:" "Trigger manual 'workflow_dispatch' declarado"

echo ""
echo "--- 3. [HAPPY PATH] Permissões Mínimas e Concorrência ---"

assert_contains "$YAML_CONTENT" "issues:\s*write" "Permissão 'issues: write' declarada"
assert_contains "$YAML_CONTENT" "pull-requests:\s*write" "Permissão 'pull-requests: write' declarada"
assert_contains "$YAML_CONTENT" "(project|repository-projects):\s*write" "Permissão de projetos write declarada"

assert_contains "$YAML_CONTENT" "concurrency:" "Chave de concorrência declarada"
assert_contains "$YAML_CONTENT" "issue\.number|pull_request\.number" "Concorrência isolada por issue ou PR"

echo ""
echo "--- 4. [HAPPY PATH] Lógica de Transição de Status no Kanban ---"

assert_contains "$YAML_CONTENT" "Planned" "Transição de status 'Planned' para issues abertas/reabertas"
assert_contains "$YAML_CONTENT" "In Review" "Transição de status 'In Review' para PRs abertos ou em revisão"
assert_contains "$YAML_CONTENT" "Done" "Transição de status 'Done' para issues ou PRs concluídos"
assert_contains "$YAML_CONTENT" "set -euo pipefail" "Step em bash padronizado com 'set -euo pipefail'"

# =============================================================================
# SEÇÃO 2: EXECUÇÃO FUNCIONAL COM MOCKS (HAPPY PATH)
# =============================================================================
echo ""
echo "--- 5. [HAPPY PATH] Execução Funcional dos Steps do Workflow com Mocks ---"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Extrai o script do step do workflow para execução isolada
WORKFLOW_SCRIPT="$TMP_DIR/sync_step.sh"
python3 -c '
import yaml
with open("'"$WORKFLOW_FILE"'") as f:
    data = yaml.safe_load(f)
steps = data["jobs"]["sync-project-v2"]["steps"]
run_step = [s for s in steps if "run" in s][0]["run"]
with open("'"$WORKFLOW_SCRIPT"'", "w") as out:
    out.write(run_step)
'
chmod +x "$WORKFLOW_SCRIPT"

MOCK_BIN="$TMP_DIR/bin"
mkdir -p "$MOCK_BIN"
MOCK_LOG="$TMP_DIR/gh_invocations.log"
touch "$MOCK_LOG"

# Criar mock do gh CLI
cat <<EOF > "$MOCK_BIN/gh"
#!/usr/bin/env bash
echo "gh \$*" >> "$MOCK_LOG"
if [ "\$1" = "project" ] && [ "\$2" = "item-add" ]; then
  echo '{"id":"item_mock_123"}'
  exit 0
elif [ "\$1" = "project" ] && [ "\$2" = "item-edit" ]; then
  echo '{"id":"item_mock_123"}'
  exit 0
elif [ "\$1" = "repo" ]; then
  echo 'https://github.com/VitorJacom/my-agents'
  exit 0
fi
exit 0
EOF
chmod +x "$MOCK_BIN/gh"

# Mock de PROJECT_CONTEXT.md
CONTEXT_MOCK="$TMP_DIR/PROJECT_CONTEXT.md"
cat <<'EOF' > "$CONTEXT_MOCK"
## 🎯 Rastreamento & GitHub Governance
- **Active Epic (Milestone)**: "Epic: AIDD Core & Engineering Governance"
- **GitHub Project v2**:
  - **Owner**: "VitorJacom"
  - **Project Number**: 1
  - **Status Field**: "Status"
  - **Release Field**: "Release"
  - **Default Release**: "v1.1.0"
EOF

# Cenário A: Issue Aberta (opened) -> Status "Planned"
> "$MOCK_LOG"
OUTPUT_SCENARIO_A=$(
  PATH="$MOCK_BIN:$PATH" \
  GH_TOKEN="mock_token_123" \
  EVENT_NAME="issues" \
  EVENT_ACTION="opened" \
  ISSUE_URL="https://github.com/VitorJacom/my-agents/issues/99" \
  PROJECT_CONTEXT_PATH="$CONTEXT_MOCK" \
  bash "$WORKFLOW_SCRIPT" 2>&1
)
assert_contains "$OUTPUT_SCENARIO_A" "Sincronizando item.*Planned" "Cenário Issue Opened sincroniza com status 'Planned'"
assert_contains "$(cat "$MOCK_LOG")" "project item-add 1 --owner VitorJacom" "gh project item-add executado com número e owner corretos"
assert_contains "$(cat "$MOCK_LOG")" "project item-edit 1 --owner VitorJacom.*--field Status --value Planned" "gh project item-edit chamado para 'Planned'"

# Cenário B: PR Aberto (opened) -> Status "In Review"
> "$MOCK_LOG"
OUTPUT_SCENARIO_B=$(
  PATH="$MOCK_BIN:$PATH" \
  GH_TOKEN="mock_token_123" \
  EVENT_NAME="pull_request" \
  EVENT_ACTION="opened" \
  IS_DRAFT="false" \
  PR_URL="https://github.com/VitorJacom/my-agents/pull/101" \
  PROJECT_CONTEXT_PATH="$CONTEXT_MOCK" \
  bash "$WORKFLOW_SCRIPT" 2>&1
)
assert_contains "$OUTPUT_SCENARIO_B" "Sincronizando item.*In Review" "Cenário PR Opened sincroniza com status 'In Review'"
assert_contains "$(cat "$MOCK_LOG")" "project item-edit 1 --owner VitorJacom.*--field Status --value In Review" "gh project item-edit chamado para 'In Review'"

# Cenário C: Issue Fechada (closed) -> Status "Done"
> "$MOCK_LOG"
OUTPUT_SCENARIO_C=$(
  PATH="$MOCK_BIN:$PATH" \
  GH_TOKEN="mock_token_123" \
  EVENT_NAME="issues" \
  EVENT_ACTION="closed" \
  ISSUE_URL="https://github.com/VitorJacom/my-agents/issues/99" \
  PROJECT_CONTEXT_PATH="$CONTEXT_MOCK" \
  bash "$WORKFLOW_SCRIPT" 2>&1
)
assert_contains "$OUTPUT_SCENARIO_C" "Sincronizando item.*Done" "Cenário Issue Closed sincroniza com status 'Done'"
assert_contains "$(cat "$MOCK_LOG")" "project item-edit 1 --owner VitorJacom.*--field Status --value Done" "gh project item-edit chamado para 'Done'"

# =============================================================================
# SEÇÃO 3: EDGE CASES & FAILURE MODES
# =============================================================================
echo ""
echo "--- 6. [EDGE CASES & FAILURE MODES] Resiliência de Tokens e Ausência de Falsos Positivos ---"

# Edge Case 1: Token ausente (GH_TOKEN="") -> Fail-Fast com exit 1 e mensagem explicativa
set +e
MISSING_TOKEN_OUTPUT=$(
  PATH="$MOCK_BIN:$PATH" \
  GH_TOKEN="" \
  bash "$WORKFLOW_SCRIPT" 2>&1
)
TOKEN_EXIT_CODE=$?
set -e
assert_equals 1 "$TOKEN_EXIT_CODE" "Falha imediata (exit 1) quando nenhum token é configurado"
assert_contains "$MISSING_TOKEN_OUTPUT" "Nenhum token de autenticação" "Mensagem explicativa clara sob ausência de token"

# Edge Case 2: PR em rascunho (draft = true) -> Ignora transição para 'In Review'
DRAFT_PR_OUTPUT=$(
  PATH="$MOCK_BIN:$PATH" \
  GH_TOKEN="mock_token_123" \
  EVENT_NAME="pull_request" \
  EVENT_ACTION="opened" \
  IS_DRAFT="true" \
  PR_URL="https://github.com/VitorJacom/my-agents/pull/102" \
  PROJECT_CONTEXT_PATH="$CONTEXT_MOCK" \
  bash "$WORKFLOW_SCRIPT" 2>&1
)
assert_contains "$DRAFT_PR_OUTPUT" "rascunho \(draft\)" "PR em draft não transita para 'In Review'"

# Edge Case 3: PROJECT_CONTEXT.md ausente -> Fallback gracioso com aviso sem quebrar
NO_CONTEXT_OUTPUT=$(
  PATH="$MOCK_BIN:$PATH" \
  GH_TOKEN="mock_token_123" \
  PROJECT_CONTEXT_PATH="$TMP_DIR/inexistente.md" \
  bash "$WORKFLOW_SCRIPT" 2>&1
)
assert_contains "$NO_CONTEXT_OUTPUT" "PROJECT_CONTEXT\.md não encontrado" "Aviso claro quando PROJECT_CONTEXT.md ausente"

# Edge Case 4: Projeto v2 inativo ou "None" -> Fallback gracioso
CONTEXT_DISABLED="$TMP_DIR/context_disabled.md"
cat <<'EOF' > "$CONTEXT_DISABLED"
## 🎯 Rastreamento & GitHub Governance
- **GitHub Project v2**:
  - **Owner**: "None"
  - **Project Number**: None
EOF
DISABLED_OUTPUT=$(
  PATH="$MOCK_BIN:$PATH" \
  GH_TOKEN="mock_token_123" \
  PROJECT_CONTEXT_PATH="$CONTEXT_DISABLED" \
  bash "$WORKFLOW_SCRIPT" 2>&1
)
assert_contains "$DISABLED_OUTPUT" "não configurado ou inativo" "Aviso claro quando Projects v2 está inativo"

# Edge Case 5: Golden Rule: Diretório tests/core/ intocado
CORE_DIFF=$(git -C "$WORKSPACE_ROOT" diff --name-only origin/main...HEAD 2>/dev/null | grep -E '^tests/core/' || true)
assert_equals "" "$CORE_DIFF" "Golden Rule: Diretório tests/core/ intocado"

echo ""
echo "========================================================================"
echo " Resumo: $TESTS_PASSED passaram | $TESTS_FAILED falharam"
echo "========================================================================"

if [ "$TESTS_FAILED" -gt 0 ]; then
  echo " >>> RESULTADO: RED (Falhas detectadas na suíte)"
  exit 1
else
  echo " >>> RESULTADO: GREEN (Todos os testes passaram)"
  exit 0
fi
