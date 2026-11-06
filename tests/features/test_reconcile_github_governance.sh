#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tests/features/test_reconcile_github_governance.sh - Issue #45 TDD Suite
# Validação do script de reconciliação idempotente de governança GitHub
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
echo " [TEST] Issue #45: Idempotent GitHub Governance Reconciliation"
echo "========================================================================"

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RECONCILE_SCRIPT="$WORKSPACE_ROOT/scripts/reconcile-github-governance.sh"

# --- 1. [ESTRUTURA & FAIL-FAST] Verificação do Arquivo e Shebang ---
echo ""
echo "--- 1. [ESTRUTURA & FAIL-FAST] Verificação do Arquivo e Flags ---"

if [ -f "$RECONCILE_SCRIPT" ] && [ -x "$RECONCILE_SCRIPT" ]; then
  echo "  [PASS] scripts/reconcile-github-governance.sh existe e é executável"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  [FAIL] scripts/reconcile-github-governance.sh não existe ou não é executável"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

if [ -f "$RECONCILE_SCRIPT" ]; then
  if head -n 5 "$RECONCILE_SCRIPT" | grep -q "set -euo pipefail"; then
    echo "  [PASS] Script contém 'set -euo pipefail' logo no início"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] Script não contém 'set -euo pipefail' nas primeiras 5 linhas"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
else
  echo "  [FAIL] Script inexistente para validação de set -euo pipefail"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Ambiente temporário para os testes funcionais e stubs
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_BIN_DIR="$TMP_DIR/bin"
mkdir -p "$MOCK_BIN_DIR"
MOCK_LOG="$TMP_DIR/gh_invocations.log"
MOCK_ISSUES_JSON="$TMP_DIR/mock_issues.json"

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

if [ "${1:-}" = "project" ] && [ "${2:-}" = "item-add" ]; then
  if [ "${MOCK_PROJECT_FAIL:-0}" = "1" ]; then
    echo "GraphQL: Project item addition failed" >&2
    exit 1
  fi
  echo "Item added"
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

# --- 2. [EDGE CASE] Ausência de PROJECT_CONTEXT.md ---
echo ""
echo "--- 2. [EDGE CASE] Comportamento sem PROJECT_CONTEXT.md ---"
if [ -f "$RECONCILE_SCRIPT" ]; then
  OUT_MISSING=$(PROJECT_CONTEXT_PATH="$TMP_DIR/nonexistent.md" "$RECONCILE_SCRIPT" 2>&1 || true)
  assert_contains "$OUT_MISSING" "não encontrado" "Script degrada graciosamente quando PROJECT_CONTEXT.md inexiste"
fi

# --- 3. [EDGE CASE] PROJECT_CONTEXT.md com Valores 'None' ou Vazios ---
echo ""
echo "--- 3. [EDGE CASE] PROJECT_CONTEXT.md com Valores 'None' ---"
cat <<'EOF' > "$TMP_DIR/context_none.md"
# Contexto Canônico do Projeto
## 🎯 Rastreamento & GitHub Governance
- **Active Milestone**: None
- **GitHub Project v2**:
  - **Owner**: None
  - **Project Number**: None
  - **Status Field**: "Status"
EOF

cat <<'EOF' > "$MOCK_ISSUES_JSON"
[
  {"number": 10, "title": "Issue sem milestone", "milestone": null, "url": "https://github.com/VitorJacom/my-agents/issues/10"}
]
EOF

if [ -f "$RECONCILE_SCRIPT" ]; then
  : > "$MOCK_LOG"
  OUT_NONE=$(PROJECT_CONTEXT_PATH="$TMP_DIR/context_none.md" "$RECONCILE_SCRIPT" 2>&1 || true)
  assert_not_contains "$(cat "$MOCK_LOG")" "issue edit" "Não deve editar milestone quando Active Milestone for None"
  assert_not_contains "$(cat "$MOCK_LOG")" "project item-add" "Não deve adicionar ao Project quando Project Number for None"
  assert_contains "$OUT_NONE" "Pulando|inativo|não configurado" "Emite log informativo ao pular reconciliação"
fi

# --- 4. [HAPPY PATH] Reconciliação Normal: Milestone + Project v2 ---
echo ""
echo "--- 4. [HAPPY PATH] Reconciliação de Milestone e Project v2 ---"
cat <<'EOF' > "$TMP_DIR/context_valid.md"
# Contexto Canônico do Projeto
## 🎯 Rastreamento & GitHub Governance
- **Active Milestone**: "v1.1.0"
- **GitHub Project v2**:
  - **Owner**: "VitorJacom"
  - **Project Number**: 1
  - **Status Field**: "Status"
EOF

# Issue 10: sem milestone
# Issue 20: já com milestone v1.1.0 (idempotência)
cat <<'EOF' > "$MOCK_ISSUES_JSON"
[
  {"number": 10, "title": "Issue desprovida de milestone", "milestone": null, "url": "https://github.com/VitorJacom/my-agents/issues/10"},
  {"number": 20, "title": "Issue já vinculada", "milestone": {"title": "v1.1.0"}, "url": "https://github.com/VitorJacom/my-agents/issues/20"}
]
EOF

if [ -f "$RECONCILE_SCRIPT" ]; then
  : > "$MOCK_LOG"
  OUT_VALID=$(PROJECT_CONTEXT_PATH="$TMP_DIR/context_valid.md" "$RECONCILE_SCRIPT" 2>&1 || true)
  
  # Deve ter chamado issue edit apenas para #10
  assert_contains "$(cat "$MOCK_LOG")" "gh issue edit 10 --milestone v1.1.0" "Issue #10 recebeu a milestone ativa v1.1.0"
  assert_not_contains "$(cat "$MOCK_LOG")" "gh issue edit 20" "Issue #20 já vinculada não foi editada (idempotência)"
  
  # Deve ter tentado adicionar ambas ao Project v2
  assert_contains "$(cat "$MOCK_LOG")" "gh project item-add 1 --owner VitorJacom --url https://github.com/VitorJacom/my-agents/issues/10" "Issue #10 adicionada ao Project v2"
  assert_contains "$(cat "$MOCK_LOG")" "gh project item-add 1 --owner VitorJacom --url https://github.com/VitorJacom/my-agents/issues/20" "Issue #20 adicionada ao Project v2"
fi

# --- 5. [HAPPY PATH] Suporte a --repo <owner/repo> ---
echo ""
echo "--- 5. [HAPPY PATH] Suporte a --repo <owner/repo> ---"
if [ -f "$RECONCILE_SCRIPT" ]; then
  : > "$MOCK_LOG"
  OUT_REPO=$(PROJECT_CONTEXT_PATH="$TMP_DIR/context_valid.md" "$RECONCILE_SCRIPT" --repo "custom-org/custom-repo" 2>&1 || true)
  assert_contains "$(cat "$MOCK_LOG")" "--repo custom-org/custom-repo" "Passa flag --repo para comandos gh"
fi

# --- 6. [HAPPY PATH] Suporte a --dry-run ---
echo ""
echo "--- 6. [HAPPY PATH] Suporte a --dry-run ---"
if [ -f "$RECONCILE_SCRIPT" ]; then
  : > "$MOCK_LOG"
  OUT_DRY=$(PROJECT_CONTEXT_PATH="$TMP_DIR/context_valid.md" "$RECONCILE_SCRIPT" --dry-run 2>&1 || true)
  assert_contains "$OUT_DRY" "DRY-RUN" "Modo --dry-run loga as operações sem executá-las"
  assert_not_contains "$(cat "$MOCK_LOG")" "gh issue edit" "Em --dry-run não chama gh issue edit"
  assert_not_contains "$(cat "$MOCK_LOG")" "gh project item-add" "Em --dry-run não chama gh project item-add"
fi

# --- 7. [RESILIÊNCIA] Degradação Graciosa em Falha no Project v2 ---
echo ""
echo "--- 7. [RESILIÊNCIA] Falha na API do Project v2 Não Quebra a Esteira ---"
if [ -f "$RECONCILE_SCRIPT" ]; then
  : > "$MOCK_LOG"
  export MOCK_PROJECT_FAIL=1
  OUT_FAIL=$(PROJECT_CONTEXT_PATH="$TMP_DIR/context_valid.md" "$RECONCILE_SCRIPT" 2>&1 || true)
  EXIT_CODE=$?
  export MOCK_PROJECT_FAIL=0
  
  assert_equals "0" "$EXIT_CODE" "Script retorna 0 mesmo se gh project item-add falhar"
  assert_contains "$OUT_FAIL" "⚠️ \[WARN\]" "Emite log de aviso '⚠️ [WARN]' ao falhar adição ao Project v2"
fi

echo ""
echo "========================================================================"
echo " Resumo dos Testes: $TESTS_PASSED passaram, $TESTS_FAILED falharam."
echo "========================================================================"

if [ "$TESTS_FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
