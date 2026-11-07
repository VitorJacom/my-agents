#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Teste de Aceitação (TDD): Hardening, Fail-Fast e CLI de tests/run.sh (Issue #601)
# =============================================================================
# Valida o comportamento determinístico do executor de testes (tests/run.sh),
# discriminando cenários de Happy Path e Edge Cases / Failure Modes.
# =============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RUNNER="$REPO_ROOT/tests/run.sh"

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

TMP_PARENT_DIR="$(mktemp -d "/tmp/unique_parent_token_xyz_XXXXXX")"
trap 'rm -rf "$TMP_PARENT_DIR"' EXIT

echo "========================================================================"
echo " [TEST] Issue #601: Hardening, Fail-Fast & CLI Suite for tests/run.sh"
echo "========================================================================"

# =============================================================================
# SEÇÃO 1: HAPPY PATH
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Execução Normal e Flags Suportadas ---"

# 1.1 --help e -h
set +e
HELP_OUT=$("$RUNNER" --help 2>&1)
HELP_CODE=$?
SHORT_HELP_OUT=$("$RUNNER" -h 2>&1)
SHORT_HELP_CODE=$?
set -e

if [[ $HELP_CODE -eq 0 && $SHORT_HELP_CODE -eq 0 ]] && grep -q "Uso:" <<< "$HELP_OUT" && grep -q "Opções Principais:" <<< "$SHORT_HELP_OUT"; then
  pass "--help e -h exibem instruções de uso e retornam exit code 0"
else
  fail "--help (exit=$HELP_CODE) ou -h (exit=$SHORT_HELP_CODE) falhou ao exibir instruções"
fi

# 1.2 --category statusline e --category=statusline
set +e
CAT_OUT=$("$RUNNER" --category statusline 2>&1)
CAT_CODE=$?
CAT_EQ_OUT=$("$RUNNER" --category=statusline 2>&1)
CAT_EQ_CODE=$?
set -e

if [[ $CAT_CODE -eq 0 ]] && grep -q "statusline/test_statusline.sh" <<< "$CAT_OUT"; then
  pass "--category statusline executa apenas os testes da categoria statusline com exit code 0"
else
  fail "--category statusline falhou (exit=$CAT_CODE)"
fi

if [[ $CAT_EQ_CODE -eq 0 ]] && grep -q "statusline/test_statusline.sh" <<< "$CAT_EQ_OUT"; then
  pass "--category=statusline suporta sintaxe com '=' e retorna exit code 0"
else
  fail "--category=statusline falhou (exit=$CAT_EQ_CODE)"
fi

# 1.3 --filter e --filter=
set +e
FILT_OUT=$("$RUNNER" --filter "test_worktree_manager" 2>&1)
FILT_CODE=$?
FILT_EQ_OUT=$("$RUNNER" --filter=test_worktree_manager 2>&1)
FILT_EQ_CODE=$?
set -e

if [[ $FILT_CODE -eq 0 ]] && grep -q "core/test_worktree_manager.sh" <<< "$FILT_OUT" && grep -q "Executando 1 suíte(s) de teste" <<< "$FILT_OUT"; then
  pass "--filter 'test_worktree_manager' encontra e executa o teste correspondente com exit code 0"
else
  fail "--filter 'test_worktree_manager' falhou (exit=$FILT_CODE)"
fi

if [[ $FILT_EQ_CODE -eq 0 ]] && grep -q "core/test_worktree_manager.sh" <<< "$FILT_EQ_OUT" && grep -q "Executando 1 suíte(s) de teste" <<< "$FILT_EQ_OUT"; then
  pass "--filter=test_worktree_manager suporta sintaxe com '=' e retorna exit code 0"
else
  fail "--filter=test_worktree_manager falhou (exit=$FILT_EQ_CODE)"
fi

# =============================================================================
# SEÇÃO 2: EDGE CASES & FAILURE MODES
# =============================================================================
echo ""
echo "--- 2. [EDGE CASES & FAILURE MODES] Validação Fail-Fast e Confinamento ---"

# 2.1 Zero testes encontrados deve falhar com exit code 1 e mensagem em stderr
set +e
EMPTY_STDERR=$("$RUNNER" --filter "padrao_inexistente_xyz_999" 2>&1 >/dev/null)
EMPTY_CODE=$?
set -e

if [[ $EMPTY_CODE -eq 1 && -n "$EMPTY_STDERR" ]]; then
  pass "Zero testes encontrados (--filter inexistente) falha com exit code 1 e emite erro em stderr"
else
  fail "Zero testes encontrados deveria retornar exit code 1 e stderr não vazio (obteve exit=$EMPTY_CODE, stderr='$EMPTY_STDERR')"
fi

# 2.2 Escopo do --filter restrito ao caminho relativo a tests/ (não contamina com pastas pai)
mkdir -p "$TMP_PARENT_DIR/tests/core"
cp "$RUNNER" "$TMP_PARENT_DIR/tests/run.sh"
chmod +x "$TMP_PARENT_DIR/tests/run.sh"
cat << 'EOF' > "$TMP_PARENT_DIR/tests/core/test_dummy.sh"
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TMP_PARENT_DIR/tests/core/test_dummy.sh"

PARENT_TOKEN="$(basename "$TMP_PARENT_DIR")"
set +e
SCOPE_OUT=$("$TMP_PARENT_DIR/tests/run.sh" --filter "$PARENT_TOKEN" 2>&1)
SCOPE_CODE=$?
set -e

if [[ $SCOPE_CODE -eq 1 ]]; then
  pass "Escopo de --filter é restrito ao caminho relativo a tests/ (ignora diretório pai '$PARENT_TOKEN' e retorna exit 1)"
else
  fail "Escopo de --filter vazou para o caminho absoluto pai '$PARENT_TOKEN' (obteve exit=$SCOPE_CODE)"
fi

# 2.3 Flags --category e --filter sem valor antes de outra flag (ou vazias)
set +e
CAT_ADJ_ERR=$("$RUNNER" --category --core 2>&1 >/dev/null)
CAT_ADJ_CODE=$?
FILT_ADJ_ERR=$("$RUNNER" --filter --all 2>&1 >/dev/null)
FILT_ADJ_CODE=$?
CAT_EMPTY_EQ_ERR=$("$RUNNER" --category= 2>&1 >/dev/null)
CAT_EMPTY_EQ_CODE=$?
FILT_EMPTY_EQ_ERR=$("$RUNNER" --filter= 2>&1 >/dev/null)
FILT_EMPTY_EQ_CODE=$?
set -e

if [[ $CAT_ADJ_CODE -eq 1 ]] && grep -qi "requer um nome de categoria" <<< "$CAT_ADJ_ERR"; then
  pass "--category seguido de flag (--category --core) falha imediatamente no parser com exit code 1"
else
  fail "--category --core deveria falhar no parser com exit code 1 (obteve exit=$CAT_ADJ_CODE, stderr='$CAT_ADJ_ERR')"
fi

if [[ $FILT_ADJ_CODE -eq 1 && -n "$FILT_ADJ_ERR" ]]; then
  pass "--filter seguido de flag (--filter --all) falha imediatamente com exit code 1"
else
  fail "--filter --all deveria falhar com exit code 1 (obteve exit=$FILT_ADJ_CODE)"
fi

if [[ $CAT_EMPTY_EQ_CODE -eq 1 && $FILT_EMPTY_EQ_CODE -eq 1 ]]; then
  pass "--category= e --filter= vazios falham imediatamente com exit code 1"
else
  fail "--category= (exit=$CAT_EMPTY_EQ_CODE) ou --filter= (exit=$FILT_EMPTY_EQ_CODE) não falhou com exit code 1"
fi

# 2.4 Regex inválida em --filter
set +e
REGEX_ERR=$("$RUNNER" --filter "[unclosed_regex" 2>&1 >/dev/null)
REGEX_CODE=$?
set -e

if [[ $REGEX_CODE -eq 1 ]] && grep -qi "inválida" <<< "$REGEX_ERR"; then
  pass "Regex inválida em --filter ('[unclosed_regex') falha com exit code 1 e mensagem clara em stderr"
else
  fail "Regex inválida em --filter deveria retornar exit code 1 e mensagem em stderr (obteve exit=$REGEX_CODE, stderr='$REGEX_ERR')"
fi

# 2.5 Categoria inexistente
set +e
BAD_CAT_ERR=$("$RUNNER" --category inexistente 2>&1 >/dev/null)
BAD_CAT_CODE=$?
set -e

if [[ $BAD_CAT_CODE -eq 1 && -n "$BAD_CAT_ERR" ]]; then
  pass "Categoria inexistente (--category inexistente) falha com exit code 1"
else
  fail "Categoria inexistente deveria falhar com exit code 1 (obteve exit=$BAD_CAT_CODE)"
fi

# 2.6 Flag desconhecida
set +e
BAD_FLAG_ERR=$("$RUNNER" --flag-invalida 2>&1 >/dev/null)
BAD_FLAG_CODE=$?
set -e

if [[ $BAD_FLAG_CODE -eq 1 && -n "$BAD_FLAG_ERR" ]]; then
  pass "Flag desconhecida (--flag-invalida) falha com exit code 1"
else
  fail "Flag desconhecida deveria falhar com exit code 1 (obteve exit=$BAD_FLAG_CODE)"
fi

echo ""
echo "========================================================================"
echo " [RESULTADO] Passaram: $PASSED | Falharam: $FAILED"
echo "========================================================================"

if [[ $FAILED -gt 0 ]]; then
  exit 1
fi
exit 0
