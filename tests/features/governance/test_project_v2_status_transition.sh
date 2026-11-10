#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tests/features/governance/test_project_v2_status_transition.sh
# Validação da sincronização resiliente de status em GitHub Projects v2 (Issue #71)
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
echo " [TEST] Issue #71: Resilient Status Sync & Auto-Add in GitHub Projects v2"
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
ITEMS_IN_PROJECT="$TMP_DIR/items_in_project.txt"
touch "$ITEMS_IN_PROJECT"

cat <<EOF > "$MOCK_GH_BIN"
#!/usr/bin/env bash
echo "\$@" >> "$MOCK_LOG"

if [ "\${MOCK_GH_SCOPE_ERROR:-0}" = "1" ]; then
  echo "HTTP 403: Resource not accessible by personal access token (missing scope: project)" >&2
  exit 1
fi

if [ "\${MOCK_GH_FAIL:-0}" = "1" ]; then
  echo "graphql error: Resource not found or service unavailable" >&2
  exit 1
fi

if [ "\$1" = "repo" ] && [ "\$2" = "view" ]; then
  echo "https://github.com/VitorJacom/my-agents"
  exit 0
fi

if [ "\$1" = "project" ] && [ "\$2" = "item-add" ]; then
  url=""
  prev=""
  for arg in "\$@"; do
    if [ "\$prev" = "--url" ]; then
      url="\$arg"
    fi
    prev="\$arg"
  done
  if [ -n "\$url" ]; then
    echo "\$url" >> "$ITEMS_IN_PROJECT"
  fi
  exit 0
fi

if [ "\$1" = "project" ] && [ "\$2" = "item-edit" ]; then
  url=""
  prev=""
  for arg in "\$@"; do
    if [ "\$prev" = "--url" ]; then
      url="\$arg"
    fi
    prev="\$arg"
  done
  if [ "\${MOCK_REQUIRE_ITEM_ADD:-0}" = "1" ]; then
    if ! grep -Fxq "\$url" "$ITEMS_IN_PROJECT" 2>/dev/null; then
      echo "Could not resolve to a ProjectV2Item: item not found in project" >&2
      exit 1
    fi
  fi
  exit 0
fi

exit 0
EOF
chmod +x "$MOCK_GH_BIN"

# 2.1 Teste Happy Path: In Progress com número de issue puro
> "$MOCK_LOG"
OUTPUT_HP1=$(PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" 21 "In Progress")
EXIT_HP1=$?
assert_equals "0" "$EXIT_HP1" "project-status-sync.sh conclui com código 0 no Happy Path (In Progress puro)"

if grep -q -E "project item-edit 1 --owner VitorJacom.*--field Status --value In Progress" "$MOCK_LOG" 2>/dev/null; then
  echo "  [PASS] gh project item-edit invocado com Project Number 1, Owner VitorJacom, Status e In Progress"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] gh project item-edit não foi invocado com os argumentos esperados"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# 2.2 Teste Happy Path: Número com tralha (#21)
> "$MOCK_LOG"
OUTPUT_HASH=$(PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" "#21" "In Progress")
EXIT_HASH=$?
assert_equals "0" "$EXIT_HASH" "project-status-sync.sh aceita número com prefixo # (#21)"
if grep -q -E "project item-edit 1 --owner VitorJacom --url https://github.com/VitorJacom/my-agents/issues/21" "$MOCK_LOG" 2>/dev/null; then
  echo "  [PASS] Issue com prefixo '#' (#21) resolvida corretamente para URL canônica"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] Issue com prefixo '#' não foi convertida para URL correta"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# 2.3 Teste Happy Path: In Review com URL completa
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

# 2.4 Teste Happy Path: Normalização de Taxonomia Canônica (Planned, In Progress, In Review, Done)
echo ""
echo "--- 2.4. [HAPPY PATH] Normalização de Taxonomia Canônica ---"

# Normalização Planned ("planned", "todo", "backlog")
> "$MOCK_LOG"
PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" 21 "planned" >/dev/null
if grep -q -E "item-edit.*--value Planned" "$MOCK_LOG" 2>/dev/null; then
  echo "  [PASS] 'planned' normalizado com sucesso para 'Planned'"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] 'planned' não foi normalizado para 'Planned'"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

> "$MOCK_LOG"
PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" 21 "todo" >/dev/null
if grep -q -E "item-edit.*--value Planned" "$MOCK_LOG" 2>/dev/null; then
  echo "  [PASS] 'todo' normalizado com sucesso para 'Planned'"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] 'todo' não foi normalizado para 'Planned'"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Normalização In Progress ("in-progress", "inprogress", "doing")
> "$MOCK_LOG"
PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" 21 "in-progress" >/dev/null
if grep -q -E "item-edit.*--value In Progress" "$MOCK_LOG" 2>/dev/null; then
  echo "  [PASS] 'in-progress' normalizado com sucesso para 'In Progress'"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] 'in-progress' não foi normalizado para 'In Progress'"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Normalização In Review ("in-review", "review")
> "$MOCK_LOG"
PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" 21 "in-review" >/dev/null
if grep -q -E "item-edit.*--value In Review" "$MOCK_LOG" 2>/dev/null; then
  echo "  [PASS] 'in-review' normalizado com sucesso para 'In Review'"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] 'in-review' não foi normalizado para 'In Review'"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Normalização Done ("done", "closed", "completed")
> "$MOCK_LOG"
PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" 21 "closed" >/dev/null
if grep -q -E "item-edit.*--value Done" "$MOCK_LOG" 2>/dev/null; then
  echo "  [PASS] 'closed' normalizado com sucesso para 'Done'"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] 'closed' não foi normalizado para 'Done'"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# 2.5 Teste Happy Path: Auto-Inclusão Resiliente (Auto-Add quando item não está no Project)
echo ""
echo "--- 2.5. [HAPPY PATH] Auto-Inclusão Resiliente (item-add antes de nova tentativa) ---"

> "$MOCK_LOG"
> "$ITEMS_IN_PROJECT"
OUTPUT_AUTOADD=$(MOCK_REQUIRE_ITEM_ADD=1 PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" 71 "In Progress")
EXIT_AUTOADD=$?
assert_equals "0" "$EXIT_AUTOADD" "project-status-sync.sh conclui com código 0 com auto-add ativado"

if grep -q -E "project item-add 1 --owner VitorJacom --url https://github.com/VitorJacom/my-agents/issues/71" "$MOCK_LOG" 2>/dev/null; then
  echo "  [PASS] gh project item-add executado para auto-incluir issue #71 no Project v2"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] gh project item-add não foi executado para auto-inclusão"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

if grep -q -E "project item-edit 1 --owner VitorJacom.*--value In Progress" "$MOCK_LOG" 2>/dev/null; then
  echo "  [PASS] gh project item-edit executado com sucesso após auto-inclusão"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] gh project item-edit não foi executado após auto-inclusão"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# --- 3. [EDGE CASES & FAILURE MODES] Degradação Graciosa e Validação ---
echo ""
echo "--- 3. [EDGE CASES & FAILURE MODES] Degradação Graciosa (Non-Blocking) ---"

# 3.1 Status Inválido fora da taxonomia canônica
OUTPUT_INVALID_STATUS=$(PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" 21 "InvalidStatusNonExistent" 2>&1)
EXIT_INVALID_STATUS=$?
assert_equals "0" "$EXIT_INVALID_STATUS" "project-status-sync.sh não aborta a esteira em caso de status inválido"
if echo "$OUTPUT_INVALID_STATUS" | grep -q "⚠️ \[WARN\]"; then
  echo "  [PASS] Alerta informativo '⚠️ [WARN]' emitido para status inválido"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] Alerta '⚠️ [WARN]' não emitido para status inválido"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# 3.2 Token sem escopo ou permissão insuficiente (403 missing scope: project)
> "$MOCK_LOG"
OUTPUT_SCOPE_ERR=$(MOCK_GH_SCOPE_ERROR=1 PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" 21 "In Progress" 2>&1)
EXIT_SCOPE_ERR=$?
assert_equals "0" "$EXIT_SCOPE_ERR" "project-status-sync.sh degrada graciosamente (exit 0) em token sem escopo de projeto"

if echo "$OUTPUT_SCOPE_ERR" | grep -q "⚠️ \[WARN\]"; then
  echo "  [PASS] Alerta informativo '⚠️ [WARN]' emitido sob falta de escopo/permissão de token"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] Alerta '⚠️ [WARN]' não emitido para erro de escopo de token"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# 3.3 Indisponibilidade geral / Erro 500 do GitHub CLI
> "$MOCK_LOG"
OUTPUT_FAIL=$(MOCK_GH_FAIL=1 PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" 21 "In Progress" 2>&1)
EXIT_FAIL=$?
assert_equals "0" "$EXIT_FAIL" "project-status-sync.sh conclui com código 0 sob falha de rede/servidor (non-blocking)"

if echo "$OUTPUT_FAIL" | grep -q "⚠️ \[WARN\]"; then
  echo "  [PASS] Mensagem de alerta informativo '⚠️ [WARN]' emitida sob erro geral"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] Alerta '⚠️ [WARN]' não emitido sob falha geral"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# 3.4 Projeto não configurado (Project Number: None)
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

# 3.5 PROJECT_CONTEXT.md não encontrado
OUTPUT_NO_CTX=$(PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/nonexistent.md" bash "$SYNC_SCRIPT" 21 "In Progress" 2>&1)
EXIT_NO_CTX=$?
assert_equals "0" "$EXIT_NO_CTX" "project-status-sync.sh conclui com código 0 quando PROJECT_CONTEXT.md inexiste"
if echo "$OUTPUT_NO_CTX" | grep -q "não encontrado"; then
  echo "  [PASS] Mensagem informativa emitida quando PROJECT_CONTEXT.md inexiste"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] Mensagem não encontrada para ausência de PROJECT_CONTEXT.md"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# 3.6 Argumentos ausentes (Uso correto do script)
OUTPUT_NO_ARGS=$(PATH="$TMP_DIR/bin:$PATH" PROJECT_CONTEXT_PATH="$TMP_DIR/PROJECT_CONTEXT.md" bash "$SYNC_SCRIPT" 2>&1)
EXIT_NO_ARGS=$?
assert_equals "0" "$EXIT_NO_ARGS" "project-status-sync.sh conclui com código 0 quando argumentos estão ausentes"
if echo "$OUTPUT_NO_ARGS" | grep -q "Uso:"; then
  echo "  [PASS] Mensagem de uso exibida quando argumentos estão ausentes"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] Mensagem de uso não foi exibida"
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
