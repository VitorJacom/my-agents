#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Teste de Aceitação (TDD): Utilitário de Revisão e Auditoria de PR (Issue #51)
# =============================================================================
# Valida o comportamento do script scripts/pr-reviewer.sh:
# - Subcomandos fetch-diff e audit-integrity
# - Validação de status da PR (deve estar OPEN)
# - Parsing estruturado resiliente com jq e fallback em Python3
# - Auditoria determinística da Golden Rule anti-fraude (tests/core/) com exit code 3
# - Validações de flags (--help / -h) e tratamento de erros com fail-fast
# =============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_UNDER_TEST="$REPO_ROOT/scripts/pr-reviewer.sh"

FAILED=0
PASSED=0

pass() {
  echo "  [PASS] $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo "  [FAIL] $1"
  FAILED=$((FAILED + 1))
}

TMP_TEST_DIR="$(mktemp -d "/tmp/test_pr_auditor_XXXXXX")"
cleanup() {
  rm -rf "$TMP_TEST_DIR"
}
trap cleanup EXIT

MOCK_BIN="$TMP_TEST_DIR/bin"
mkdir -p "$MOCK_BIN"

# Criação do mock para o comando 'gh'
cat << 'EOF' > "$MOCK_BIN/gh"
#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"
subcmd="${2:-}"
pr="${3:-}"

if [[ "$cmd" == "pr" ]]; then
  if [[ "$subcmd" == "view" ]]; then
    case "$pr" in
      101)
        cat << 'JSON'
{"number":101,"title":"feat: add new feature","state":"OPEN","headRefName":"feature/new-feature","baseRefName":"main","author":{"login":"developer"},"url":"https://github.com/org/repo/pull/101"}
JSON
        exit 0
        ;;
      102)
        cat << 'JSON'
{"number":102,"title":"feat: closed pr","state":"CLOSED","headRefName":"feature/closed","baseRefName":"main","author":{"login":"developer"},"url":"https://github.com/org/repo/pull/102"}
JSON
        exit 0
        ;;
      103)
        cat << 'JSON'
{"number":103,"title":"feat: merged pr","state":"MERGED","headRefName":"feature/merged","baseRefName":"main","author":{"login":"developer"},"url":"https://github.com/org/repo/pull/103"}
JSON
        exit 0
        ;;
      105)
        cat << 'JSON'
{"number":105,"title":"feat: fraud attempt","state":"OPEN","headRefName":"feature/fraud","baseRefName":"main","author":{"login":"sneaky"},"url":"https://github.com/org/repo/pull/105"}
JSON
        exit 0
        ;;
      *)
        echo "Error: Pull request not found" >&2
        exit 1
        ;;
    esac
  elif [[ "$subcmd" == "diff" ]]; then
    case "$pr" in
      101)
        cat << 'DIFF'
diff --git a/src/utils.js b/src/utils.js
index 1234567..89abcdef 100644
--- a/src/utils.js
+++ b/src/utils.js
@@ -1,3 +1,4 @@
+// New helper function
+export function helper() {}
DIFF
        exit 0
        ;;
      105)
        cat << 'DIFF'
diff --git a/tests/core/test_invariants.sh b/tests/core/test_invariants.sh
index 1111111..2222222 100755
--- a/tests/core/test_invariants.sh
+++ b/tests/core/test_invariants.sh
@@ -5,3 +5,4 @@
+# Tampering with invariant core tests
DIFF
        exit 0
        ;;
      *)
        echo "Error: Could not retrieve diff" >&2
        exit 1
        ;;
    esac
  fi
fi

echo "Mock gh: comando não suportado: $*" >&2
exit 1
EOF
chmod +x "$MOCK_BIN/gh"

# Prepara ambiente com mock gh no PATH
ORIGINAL_PATH="$PATH"
export PATH="$MOCK_BIN:$PATH"

echo "========================================================================"
echo " [TEST] Issue #51: PR Reviewer Fetch-Diff & Integrity Auditor"
echo "========================================================================"

# --- 1. [HAPPY PATH] Help e Operação Normal ---
echo ""
echo "--- 1. [HAPPY PATH] Ajuda, Flags e Operação Normal ---"

# Script deve existir e ser executável
if [[ -x "$SCRIPT_UNDER_TEST" ]]; then
  pass "scripts/pr-reviewer.sh existe e possui permissão de execução"
else
  fail "scripts/pr-reviewer.sh não existe ou não é executável"
fi

# Help com --help
set +e
HELP_OUT="$("$SCRIPT_UNDER_TEST" --help 2>&1)"
HELP_STATUS=$?
set -e
if [[ $HELP_STATUS -eq 0 ]] && echo "$HELP_OUT" | grep -qi "fetch-diff" && echo "$HELP_OUT" | grep -qi "audit-integrity"; then
  pass "--help exibe manual com subcomandos fetch-diff e audit-integrity e retorna exit code 0"
else
  fail "--help falhou ou não documentou os subcomandos esperados (status: $HELP_STATUS)"
fi

# Help com -h
set +e
SHORT_HELP_OUT="$("$SCRIPT_UNDER_TEST" -h 2>&1)"
SHORT_HELP_STATUS=$?
set -e
if [[ $SHORT_HELP_STATUS -eq 0 ]] && echo "$SHORT_HELP_OUT" | grep -qi "fetch-diff"; then
  pass "-h exibe manual com sucesso e retorna exit code 0"
else
  fail "-h falhou em exibir a documentação (status: $SHORT_HELP_STATUS)"
fi

# fetch-diff em PR aberta válida
set +e
FETCH_OUT="$("$SCRIPT_UNDER_TEST" fetch-diff 101 2>&1)"
FETCH_STATUS=$?
set -e
if [[ $FETCH_STATUS -eq 0 ]] && echo "$FETCH_OUT" | grep -q "101" && echo "$FETCH_OUT" | grep -q "OPEN" && echo "$FETCH_OUT" | grep -q "diff --git"; then
  pass "fetch-diff 101 extrai metadados estruturados e diff unificado com exit code 0"
else
  fail "fetch-diff 101 falhou (status: $FETCH_STATUS, output: $FETCH_OUT)"
fi

# audit-integrity em PR limpa (sem tests/core/)
set +e
AUDIT_CLEAN_OUT="$("$SCRIPT_UNDER_TEST" audit-integrity 101 2>&1)"
AUDIT_CLEAN_STATUS=$?
set -e
if [[ $AUDIT_CLEAN_STATUS -eq 0 ]] && echo "$AUDIT_CLEAN_OUT" | grep -qi "integridade.*ok\|aprovada\|preservada"; then
  pass "audit-integrity 101 valida conformidade e integridade da Golden Rule com exit code 0"
else
  fail "audit-integrity 101 falhou em aprovar PR íntegra (status: $AUDIT_CLEAN_STATUS, output: $AUDIT_CLEAN_OUT)"
fi

# --- 2. [HAPPY PATH] Resiliência de Parsing (jq e Python3) ---
echo ""
echo "--- 2. [HAPPY PATH] Resiliência de Parsing (jq e Python3) ---"

# Fallback Python3 quando jq não está no PATH
NO_JQ_BIN="$TMP_TEST_DIR/no_jq_bin"
mkdir -p "$NO_JQ_BIN"
cp "$MOCK_BIN/gh" "$NO_JQ_BIN/gh"

# Cria wrapper de PATH sem jq
for cmd in python3 bash sh cat grep sed awk cut date head tr uname; do
  p="$(command -v "$cmd" 2>/dev/null || true)"
  if [[ -n "$p" && -x "$p" ]]; then
    ln -sf "$p" "$NO_JQ_BIN/$cmd"
  fi
done

set +e
FETCH_PY_OUT="$(PATH="$NO_JQ_BIN" "$SCRIPT_UNDER_TEST" fetch-diff 101 2>&1)"
FETCH_PY_STATUS=$?
set -e
if [[ $FETCH_PY_STATUS -eq 0 ]] && echo "$FETCH_PY_OUT" | grep -q "101" && echo "$FETCH_PY_OUT" | grep -q "OPEN"; then
  pass "fetch-diff opera com sucesso e extrai metadados via fallback Python3 quando jq está indisponível"
else
  fail "fetch-diff falhou no fallback Python3 (status: $FETCH_PY_STATUS, output: $FETCH_PY_OUT)"
fi

# --- 3. [EDGE CASES & FAILURE MODES] Validações e Erros de PR ---
echo ""
echo "--- 3. [EDGE CASES & FAILURE MODES] Validações e Erros de PR ---"

# Subcomando ausente ou inválido
set +e
INVALID_CMD_OUT="$("$SCRIPT_UNDER_TEST" comando-inexistente 2>&1)"
INVALID_CMD_STATUS=$?
set -e
if [[ $INVALID_CMD_STATUS -ne 0 ]] && echo "$INVALID_CMD_OUT" | grep -qi "desconhecido\|inválido\|uso:"; then
  pass "Falha determinística quando subcomando é inválido (exit code: $INVALID_CMD_STATUS)"
else
  fail "Subcomando inválido não retornou erro adequado (status: $INVALID_CMD_STATUS)"
fi

# PR_NUMBER ausente no fetch-diff
set +e
NO_PR_FETCH_OUT="$("$SCRIPT_UNDER_TEST" fetch-diff 2>&1)"
NO_PR_FETCH_STATUS=$?
set -e
if [[ $NO_PR_FETCH_STATUS -ne 0 ]] && echo "$NO_PR_FETCH_OUT" | grep -qi "requer.*pr\|número.*pr"; then
  pass "fetch-diff sem número de PR aborta com erro descritivo (exit code: $NO_PR_FETCH_STATUS)"
else
  fail "fetch-diff sem número de PR não tratou erro (status: $NO_PR_FETCH_STATUS, output: $NO_PR_FETCH_OUT)"
fi

# PR_NUMBER ausente no audit-integrity
set +e
NO_PR_AUDIT_OUT="$("$SCRIPT_UNDER_TEST" audit-integrity 2>&1)"
NO_PR_AUDIT_STATUS=$?
set -e
if [[ $NO_PR_AUDIT_STATUS -ne 0 ]] && echo "$NO_PR_AUDIT_OUT" | grep -qi "requer.*pr\|número.*pr"; then
  pass "audit-integrity sem número de PR aborta com erro descritivo (exit code: $NO_PR_AUDIT_STATUS)"
else
  fail "audit-integrity sem número de PR não tratou erro (status: $NO_PR_AUDIT_STATUS, output: $NO_PR_AUDIT_OUT)"
fi

# PR inexistente
set +e
NOT_FOUND_OUT="$("$SCRIPT_UNDER_TEST" fetch-diff 999 2>&1)"
NOT_FOUND_STATUS=$?
set -e
if [[ $NOT_FOUND_STATUS -ne 0 ]] && echo "$NOT_FOUND_OUT" | grep -qi "erro\|falha\|not found"; then
  pass "fetch-diff em PR inexistente falha graciosamente (exit code: $NOT_FOUND_STATUS)"
else
  fail "fetch-diff em PR inexistente não falhou como esperado (status: $NOT_FOUND_STATUS)"
fi

# PR com estado CLOSED
set +e
CLOSED_OUT="$("$SCRIPT_UNDER_TEST" fetch-diff 102 2>&1)"
CLOSED_STATUS=$?
set -e
if [[ $CLOSED_STATUS -ne 0 ]] && echo "$CLOSED_OUT" | grep -qi "closed\|não está open\|fechada"; then
  pass "fetch-diff rejeita PR fechada (CLOSED) com erro descritivo (exit code: $CLOSED_STATUS)"
else
  fail "fetch-diff permitiu PR fechada (status: $CLOSED_STATUS, output: $CLOSED_OUT)"
fi

# PR com estado MERGED
set +e
MERGED_OUT="$("$SCRIPT_UNDER_TEST" fetch-diff 103 2>&1)"
MERGED_STATUS=$?
set -e
if [[ $MERGED_STATUS -ne 0 ]] && echo "$MERGED_OUT" | grep -qi "merged\|não está open\|mesclada"; then
  pass "fetch-diff rejeita PR mesclada (MERGED) com erro descritivo (exit code: $MERGED_STATUS)"
else
  fail "fetch-diff permitiu PR mesclada (status: $MERGED_STATUS, output: $MERGED_OUT)"
fi

# --- 4. [EDGE CASES & FAILURE MODES] Golden Rule Anti-Fraude (tests/core/) ---
echo ""
echo "--- 4. [EDGE CASES & FAILURE MODES] Golden Rule Anti-Fraude (tests/core/) ---"

# audit-integrity em PR que altera tests/core/ DEVE retornar exit code 3
set +e
FRAUD_OUT="$("$SCRIPT_UNDER_TEST" audit-integrity 105 2>&1)"
FRAUD_STATUS=$?
set -e
if [[ $FRAUD_STATUS -eq 3 ]] && echo "$FRAUD_OUT" | grep -qi "tests/core/\|alerta de fraude\|fraude"; then
  pass "audit-integrity detecta adulteração de tests/core/ e aborta com exit code 3 (Circuit-Breaker)"
else
  fail "audit-integrity não abortou com código 3 diante de fraude em tests/core/ (status: $FRAUD_STATUS, output: $FRAUD_OUT)"
fi

# --- 5. [EDGE CASES & FAILURE MODES] Degradação Graciosa de Dependências ---
echo ""
echo "--- 5. [EDGE CASES & FAILURE MODES] Falta de Parsers JSON ---"

# Ambiente sem jq e sem python3
MINIMAL_BIN="$TMP_TEST_DIR/minimal_bin"
mkdir -p "$MINIMAL_BIN"
cp "$MOCK_BIN/gh" "$MINIMAL_BIN/gh"
for cmd in bash sh cat grep sed awk cut date head tr uname; do
  p="$(command -v "$cmd" 2>/dev/null || true)"
  if [[ -n "$p" && -x "$p" ]]; then
    ln -sf "$p" "$MINIMAL_BIN/$cmd"
  fi
done

set +e
NO_PARSER_OUT="$(PATH="$MINIMAL_BIN" "$SCRIPT_UNDER_TEST" fetch-diff 101 2>&1)"
NO_PARSER_STATUS=$?
set -e
if [[ $NO_PARSER_STATUS -ne 0 ]] && echo "$NO_PARSER_OUT" | grep -qi "jq.*python3\|parser"; then
  pass "Falha explicita e determinística quando nem jq nem python3 estão disponíveis"
else
  fail "Script não tratou a ausência de parsers JSON (status: $NO_PARSER_STATUS, output: $NO_PARSER_OUT)"
fi

echo ""
echo "========================================================================"
echo " RESUMO DA EXECUÇÃO: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [[ $FAILED -eq 0 ]]; then
  echo "✅ STATUS: GREEN (Todos os testes passaram)"
  exit 0
else
  echo "❌ STATUS: RED ($FAILED falha(s) detectada(s))"
  exit 1
fi
