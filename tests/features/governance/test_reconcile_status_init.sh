#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tests/features/governance/test_reconcile_status_init.sh - Issue #70 TDD Suite
# Validação do status inicial 'Planned', ciclo 'Done' e idempotência no reconciler
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
    echo "  [FAIL] $msg: Padrão '$pattern' não encontrado no output"
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
    echo "  [FAIL] $msg: Padrão '$pattern' encontrado indevidamente no output"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "========================================================================"
echo " [TEST] Issue #70: Status Inicial 'Planned' e Ciclo 'Done' no Reconciler"
echo "========================================================================"

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RECONCILE_SCRIPT="$WORKSPACE_ROOT/scripts/pipeline/reconcile-github-governance.sh"

# Ambiente temporário para stubs e mocks
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_BIN_DIR="$TMP_DIR/bin"
mkdir -p "$MOCK_BIN_DIR"
MOCK_LOG="$TMP_DIR/gh_invocations.log"
MOCK_ISSUES_JSON="$TMP_DIR/mock_issues.json"
MOCK_PROJECT_ITEMS_JSON="$TMP_DIR/mock_project_items.json"

cat <<'EOF' > "$MOCK_BIN_DIR/gh"
#!/usr/bin/env bash
echo "gh $@" >> "$MOCK_LOG"

if [ "${1:-}" = "issue" ] && [ "${2:-}" = "list" ]; then
  if [ -f "$MOCK_ISSUES_JSON" ]; then
    cat "$MOCK_ISSUES_JSON"
  else
    echo "[]"
  fi
  exit 0
fi

if [ "${1:-}" = "issue" ] && [ "${2:-}" = "edit" ]; then
  exit 0
fi

if [ "${1:-}" = "project" ] && [ "${2:-}" = "item-list" ]; then
  if [ "${MOCK_PROJECT_LIST_FAIL:-0}" = "1" ]; then
    echo "GraphQL: Project item list query failed" >&2
    exit 1
  fi
  if [ -f "$MOCK_PROJECT_ITEMS_JSON" ]; then
    cat "$MOCK_PROJECT_ITEMS_JSON"
  else
    echo '{"items":[]}'
  fi
  exit 0
fi

if [ "${1:-}" = "project" ] && [ "${2:-}" = "item-add" ]; then
  if [ "${MOCK_PROJECT_FAIL:-0}" = "1" ]; then
    echo "GraphQL: Project item addition failed" >&2
    exit 1
  fi
  echo "Item added"
  exit 0
fi

if [ "${1:-}" = "project" ] && [ "${2:-}" = "item-edit" ]; then
  if [ "${MOCK_PROJECT_EDIT_FAIL:-0}" = "1" ]; then
    echo "GraphQL: Project item edit failed" >&2
    exit 1
  fi
  echo "Item edited"
  exit 0
fi

if [ "${1:-}" = "repo" ] && [ "${2:-}" = "view" ]; then
  echo "https://github.com/VitorJacom/my-agents"
  exit 0
fi

exit 0
EOF
chmod +x "$MOCK_BIN_DIR/gh"

export PATH="$MOCK_BIN_DIR:$PATH"
export MOCK_LOG
export MOCK_ISSUES_JSON
export MOCK_PROJECT_ITEMS_JSON

# --- 1. [ESTRUTURA & INTERFACE] Suporte a --include-closed no Help ---
echo ""
echo "--- 1. [ESTRUTURA & INTERFACE] Verificação de Flags e Ajuda ---"
HELP_OUTPUT=$("$RECONCILE_SCRIPT" --help 2>&1 || true)
assert_contains "$HELP_OUTPUT" "--include-closed" "Ajuda (--help) documenta a flag --include-closed"

# --- 2. [HAPPY PATH] Status Inicial 'Planned' para Issue Aberta sem Status ---
echo ""
echo "--- 2. [HAPPY PATH] Inicialização com Status Padrão (Fallback 'Planned') ---"
cat <<'EOF' > "$TMP_DIR/context_default_status.md"
# Contexto Canônico do Projeto
## 🎯 Rastreamento & GitHub Governance
- **Active Milestone**: "v1.1.0"
- **GitHub Project v2**:
  - **Owner**: "VitorJacom"
  - **Project Number**: 1
  - **Status Field**: "Status"
EOF

cat <<'EOF' > "$MOCK_ISSUES_JSON"
[
  {"number": 70, "title": "Nova issue sem status", "milestone": "v1.1.0", "url": "https://github.com/VitorJacom/my-agents/issues/70", "state": "OPEN"}
]
EOF

cat <<'EOF' > "$MOCK_PROJECT_ITEMS_JSON"
{
  "items": []
}
EOF

: > "$MOCK_LOG"
OUT_INIT=$(PROJECT_CONTEXT_PATH="$TMP_DIR/context_default_status.md" "$RECONCILE_SCRIPT" 2>&1 || true)
assert_contains "$(cat "$MOCK_LOG")" "gh project item-edit 1 --owner VitorJacom --url https://github.com/VitorJacom/my-agents/issues/70 --field Status --value Planned" "Atribui status 'Planned' por padrão quando não especificado"
assert_contains "$OUT_INIT" "Planned" "Emite log de sucesso para atribuição de status 'Planned'"

# --- 3. [HAPPY PATH] Custom Default Status em PROJECT_CONTEXT.md ---
echo ""
echo "--- 3. [HAPPY PATH] Suporte a 'Default Status' Customizado ---"
cat <<'EOF' > "$TMP_DIR/context_custom_status.md"
# Contexto Canônico do Projeto
## 🎯 Rastreamento & GitHub Governance
- **Active Milestone**: "v1.1.0"
- **GitHub Project v2**:
  - **Owner**: "VitorJacom"
  - **Project Number**: 1
  - **Status Field**: "Status"
  - **Default Status**: "Backlog"
EOF

: > "$MOCK_LOG"
OUT_CUSTOM=$(PROJECT_CONTEXT_PATH="$TMP_DIR/context_custom_status.md" "$RECONCILE_SCRIPT" 2>&1 || true)
assert_contains "$(cat "$MOCK_LOG")" "gh project item-edit 1 --owner VitorJacom --url https://github.com/VitorJacom/my-agents/issues/70 --field Status --value Backlog" "Atribui status customizado 'Backlog' respeitando PROJECT_CONTEXT.md"

# --- 4. [HAPPY PATH] Idempotência: Não Sobrescrever Status Existente ---
echo ""
echo "--- 4. [HAPPY PATH] Idempotência: Preservar Status Existente em Issues Abertas ---"
cat <<'EOF' > "$MOCK_PROJECT_ITEMS_JSON"
{
  "items": [
    {
      "id": "item-70",
      "content": {
        "number": 70,
        "url": "https://github.com/VitorJacom/my-agents/issues/70"
      },
      "status": "In Progress"
    }
  ]
}
EOF

: > "$MOCK_LOG"
OUT_IDEMPOTENT=$(PROJECT_CONTEXT_PATH="$TMP_DIR/context_default_status.md" "$RECONCILE_SCRIPT" 2>&1 || true)
assert_not_contains "$(cat "$MOCK_LOG")" "--field Status" "Não chama item-edit de Status se issue já possui 'In Progress'"
assert_contains "$OUT_IDEMPOTENT" "In Progress.*Mantendo|já possui status" "Loga que a issue já possui status e mantém o existente"

# --- 5. [HAPPY PATH] Suporte a --include-closed e Ciclo 'Done' ---
echo ""
echo "--- 5. [HAPPY PATH] Suporte a --include-closed e Transição para 'Done' ---"
cat <<'EOF' > "$MOCK_ISSUES_JSON"
[
  {"number": 71, "title": "Issue aberta em andamento", "milestone": "v1.1.0", "url": "https://github.com/VitorJacom/my-agents/issues/71", "state": "OPEN"},
  {"number": 72, "title": "Issue fechada precisando de Done", "milestone": "v1.1.0", "url": "https://github.com/VitorJacom/my-agents/issues/72", "state": "CLOSED"},
  {"number": 73, "title": "Issue fechada já Done", "milestone": "v1.1.0", "url": "https://github.com/VitorJacom/my-agents/issues/73", "state": "CLOSED"}
]
EOF

cat <<'EOF' > "$MOCK_PROJECT_ITEMS_JSON"
{
  "items": [
    {
      "id": "item-71",
      "content": {
        "number": 71,
        "url": "https://github.com/VitorJacom/my-agents/issues/71"
      },
      "status": "In Progress"
    },
    {
      "id": "item-72",
      "content": {
        "number": 72,
        "url": "https://github.com/VitorJacom/my-agents/issues/72"
      },
      "status": "In Review"
    },
    {
      "id": "item-73",
      "content": {
        "number": 73,
        "url": "https://github.com/VitorJacom/my-agents/issues/73"
      },
      "status": "Done"
    }
  ]
}
EOF

: > "$MOCK_LOG"
OUT_CLOSED=$(PROJECT_CONTEXT_PATH="$TMP_DIR/context_default_status.md" "$RECONCILE_SCRIPT" --include-closed 2>&1 || true)
# Deve consultar com --state all quando --include-closed estiver ativo
assert_contains "$(cat "$MOCK_LOG")" "issue list.*--state all" "Consulta issues abertas e fechadas com --state all"
# Issue 72 deve ir para Done
assert_contains "$(cat "$MOCK_LOG")" "gh project item-edit 1 --owner VitorJacom --url https://github.com/VitorJacom/my-agents/issues/72 --field Status --value Done" "Atualiza status da issue fechada #72 para 'Done'"
# Issue 73 já é Done -> idempotente
assert_not_contains "$(cat "$MOCK_LOG")" "issues/73 --field Status" "Não re-edita issue #73 que já possui status 'Done'"
# Issue 71 já está In Progress -> mantém
assert_not_contains "$(cat "$MOCK_LOG")" "issues/71 --field Status" "Não sobrescreve status 'In Progress' da issue aberta #71"

# --- 6. [HAPPY PATH] Modo --dry-run com Status Inicial e Done ---
echo ""
echo "--- 6. [HAPPY PATH] Simulação com --dry-run ---"
: > "$MOCK_LOG"
OUT_DRY=$(PROJECT_CONTEXT_PATH="$TMP_DIR/context_default_status.md" "$RECONCILE_SCRIPT" --include-closed --dry-run 2>&1 || true)
assert_contains "$OUT_DRY" "\[DRY-RUN\]" "Exibe logs [DRY-RUN] no modo de simulação"
assert_contains "$OUT_DRY" "Done" "Indica em dry-run a transição para Done da issue #72"
assert_not_contains "$(cat "$MOCK_LOG")" "gh project item-edit" "Não executa gh project item-edit no modo --dry-run"

# --- 7. [EDGE CASES & FAILURE MODES] Degradação Graciosa e Resiliência ---
echo ""
echo "--- 7. [EDGE CASES & FAILURE MODES] Degradação Graciosa sob Erros ou Ausência ---"

# 7.1 Status Field configurado como 'None'
cat <<'EOF' > "$TMP_DIR/context_status_none.md"
# Contexto Canônico do Projeto
## 🎯 Rastreamento & GitHub Governance
- **Active Milestone**: "v1.1.0"
- **GitHub Project v2**:
  - **Owner**: "VitorJacom"
  - **Project Number**: 1
  - **Status Field**: None
EOF

: > "$MOCK_LOG"
OUT_STATUS_NONE=$(PROJECT_CONTEXT_PATH="$TMP_DIR/context_status_none.md" "$RECONCILE_SCRIPT" 2>&1 || true)
assert_not_contains "$(cat "$MOCK_LOG")" "gh project item-edit.*--field" "Não chama item-edit de Status se Status Field for None"
assert_contains "$OUT_STATUS_NONE" "⚠️ \[WARN\].*Status Field" "Emite warning ao pular status quando Status Field é None"

# 7.2 Falha na API gh project item-list
cat <<'EOF' > "$MOCK_ISSUES_JSON"
[
  {"number": 70, "title": "Issue aberta", "milestone": "v1.1.0", "url": "https://github.com/VitorJacom/my-agents/issues/70", "state": "OPEN"}
]
EOF

: > "$MOCK_LOG"
export MOCK_PROJECT_LIST_FAIL=1
OUT_LIST_FAIL=$(PROJECT_CONTEXT_PATH="$TMP_DIR/context_default_status.md" "$RECONCILE_SCRIPT" 2>&1 || true)
LIST_FAIL_CODE=$?
export MOCK_PROJECT_LIST_FAIL=0

assert_equals "0" "$LIST_FAIL_CODE" "Script retorna 0 com falha de consulta do item-list"
assert_contains "$OUT_LIST_FAIL" "⚠️ \[WARN\]" "Emite aviso '⚠️ [WARN]' quando consulta de item-list falha"

# 7.3 Falha na API gh project item-edit
: > "$MOCK_LOG"
cat <<'EOF' > "$MOCK_PROJECT_ITEMS_JSON"
{
  "items": []
}
EOF
export MOCK_PROJECT_EDIT_FAIL=1
OUT_EDIT_FAIL=$(PROJECT_CONTEXT_PATH="$TMP_DIR/context_default_status.md" "$RECONCILE_SCRIPT" 2>&1 || true)
EDIT_FAIL_CODE=$?
export MOCK_PROJECT_EDIT_FAIL=0

assert_equals "0" "$EDIT_FAIL_CODE" "Script retorna 0 mesmo se item-edit falhar (non-blocking)"
assert_contains "$OUT_EDIT_FAIL" "⚠️ \[WARN\]" "Emite aviso '⚠️ [WARN]' sob falha em item-edit"

echo ""
echo "========================================================================"
echo " Resumo dos Testes: $TESTS_PASSED passaram, $TESTS_FAILED falharam."
echo "========================================================================"

if [ "$TESTS_FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
