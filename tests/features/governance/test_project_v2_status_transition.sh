#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tests/features/governance/test_project_v2_status_transition.sh - Issue #21 TDD Suite
# Validação da sincronização de status em GitHub Projects v2 no /run-issue
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
echo " [TEST] Issue #21: Automated Status Sync in GitHub Projects v2"
echo "========================================================================"

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SYNC_SCRIPT="$WORKSPACE_ROOT/scripts/pipeline/project-status-sync.sh"
PIPELINE_SKILL="$WORKSPACE_ROOT/skills/issue-pipeline/SKILL.md"
GATEKEEPER_AGENT="$WORKSPACE_ROOT/agents/gatekeeper/agent.md"

# --- 1. [HAPPY PATH] Verificação dos Contratos em SKILL e AGENT ---
echo ""
echo "--- 1. [HAPPY PATH] Contratos de Integração no Pipeline e Gatekeeper ---"

if [ -f "$SYNC_SCRIPT" ] && [ -x "$SYNC_SCRIPT" ]; then
  echo "  [PASS] scripts/pipeline/project-status-sync.sh existe e é executável"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] scripts/pipeline/project-status-sync.sh não existe ou não é executável"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

assert_contains "$PIPELINE_SKILL" "project-status-sync\.sh" "skills/issue-pipeline/SKILL.md referencia project-status-sync.sh"
assert_contains "$PIPELINE_SKILL" "In Progress" "skills/issue-pipeline/SKILL.md referencia transição para 'In Progress'"

assert_contains "$GATEKEEPER_AGENT" "project-status-sync\.sh" "agents/gatekeeper/agent.md referencia project-status-sync.sh"
assert_contains "$GATEKEEPER_AGENT" "In Review" "agents/gatekeeper/agent.md referencia transição para 'In Review'"

# --- 2. [HAPPY PATH] Execução Funcional do Script project-status-sync.sh ---
echo ""
echo "--- 2. [HAPPY PATH] Execução Funcional do Script com Mock do gh CLI ---"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Mock de PROJECT_CONTEXT.md
cat <<'EOF' > "$TMP_DIR/PROJECT_CONTEXT.md"
# Contexto Canônico
## 🎯 Rastreamento & GitHub Governance
- **Active Milestone**: "v1.1.0"
- **GitHub Project v2**:
  - **Owner**: "VitorJacom"
  - **Project Number**: 1
  - **Status Field**: "Status"
EOF

# Mock do binário 'gh'
MOCK_GH_BIN="$TMP_DIR/bin/gh"
mkdir -p "$TMP_DIR/bin"
MOCK_LOG="$TMP_DIR/gh_invocations.log"

cat <<EOF > "$MOCK_GH_BIN"
#!/usr/bin/env bash
echo "\$@" >> "$MOCK_LOG"
if [ "\${MOCK_GH_FAIL:-0}" = "1" ]; then
  echo "graphql error: Resource not found" >&2
  exit 1
fi
if [ "\$1" = "repo" ] && [ "\$2" = "view" ]; then
  echo "https://github.com/VitorJacom/my-agents"
  exit 0
fi
exit 0
EOF
chmod +x "$MOCK_GH_BIN"

if [ -f "$SYNC_SCRIPT" ]; then
  # Teste Happy Path: In Progress com número de issue
  OUTPUT_HP1=$(PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" 21 "In Progress")
  EXIT_HP1=$?
  assert_equals "0" "$EXIT_HP1" "project-status-sync.sh conclui com código 0 no Happy Path (In Progress)"

  if grep -q -E "project item-edit 1 --owner VitorJacom.*--field Status --value In Progress" "$MOCK_LOG" 2>/dev/null; then
    echo "  [PASS] gh project item-edit invocado com Project Number 1, Owner VitorJacom, Status e In Progress"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] gh project item-edit não foi invocado com os argumentos esperados"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Teste Happy Path: In Review com URL completa
  > "$MOCK_LOG"
  OUTPUT_HP2=$(PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" "https://github.com/VitorJacom/my-agents/issues/21" "In Review")
  EXIT_HP2=$?
  assert_equals "0" "$EXIT_HP2" "project-status-sync.sh conclui com código 0 com URL completa"

  if grep -q -E "project item-edit 1 --owner VitorJacom --url https://github.com/VitorJacom/my-agents/issues/21 --field Status --value In Review" "$MOCK_LOG" 2>/dev/null; then
    echo "  [PASS] gh project item-edit invocado com URL direta e Status In Review"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] gh project item-edit não foi invocado com URL direta"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # --- 3. [EDGE CASES] Degradação Graciosa (Non-Blocking) ---
  echo ""
  echo "--- 3. [EDGE CASES] Degradação Graciosa (Non-Blocking) sob Falha ou Falta de Configuração ---"

  # Falha do comando gh (ex.: 403, 404, erro de rede)
  > "$MOCK_LOG"
  OUTPUT_FAIL=$(MOCK_GH_FAIL=1 PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" 21 "In Progress" 2>&1)
  EXIT_FAIL=$?
  assert_equals "0" "$EXIT_FAIL" "project-status-sync.sh conclui com código 0 mesmo quando gh falha (non-blocking)"

  if echo "$OUTPUT_FAIL" | grep -q "⚠️ \[WARN\]"; then
    echo "  [PASS] Mensagem de alerta informativo '⚠️ [WARN]' emitida sob erro"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] Alerta '⚠️ [WARN]' não emitido sob falha"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Projeto não configurado (Project Number: None)
  cat <<'EOF' > "$TMP_DIR/PROJECT_CONTEXT_NONE.md"
# Contexto Canônico
## 🎯 Rastreamento & GitHub Governance
- **GitHub Project v2**:
  - **Owner**: "VitorJacom"
  - **Project Number**: None
EOF
  OUTPUT_NONE=$(PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT_NONE.md" bash "$SYNC_SCRIPT" 21 "In Progress" 2>&1)
  EXIT_NONE=$?
  assert_equals "0" "$EXIT_NONE" "project-status-sync.sh conclui com código 0 quando Project Number é None"

  if echo "$OUTPUT_NONE" | grep -q -E "\[INFO\]"; then
    echo "  [PASS] Mensagem informativa emitida quando projeto não está ativo"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] Mensagem informativa não emitida para Project Number: None"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
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
