#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Teste de Aceitação (TDD): Submissão Determinística de Pareceres de Code Review
# Issue #52
# =============================================================================
# Valida o comportamento do subcomando 'submit-review' em scripts/pr-reviewer.sh:
# - Veredito automático (--status auto):
#     * "🚨 Crítico" / violação de integridade -> request-changes
#     * "⚠️ Importante" / "💡 Sugestão" -> comment
#     * Sem apontamentos impeditivos (limpo) -> approve
# - Vereditos explícitos: --status approve, request-changes, comment
# - Flag --dry-run (não dispara mutações na API do GitHub via gh pr review)
# - Sintaxes: --body-file arquivo / --body-file=arquivo, --status valor / --status=valor
# - Tratamento de falhas:
#     * PR inexistente, CLOSED ou MERGED
#     * Argumento de PR ausente
#     * Body-file ausente, inexistente ou vazio
#     * Status inválido
#     * Erro de rede/API do GitHub CLI
# - Documentação no --help
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

TMP_TEST_DIR="$(mktemp -d "/tmp/test_pr_review_submission_XXXXXX")"
cleanup() {
  rm -rf "$TMP_TEST_DIR"
}
trap cleanup EXIT

MOCK_BIN="$TMP_TEST_DIR/bin"
mkdir -p "$MOCK_BIN"

GH_REVIEW_LOG="$TMP_TEST_DIR/gh_review.log"

# Criação do mock para o GitHub CLI 'gh'
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
{"number":101,"title":"feat: valid pull request","state":"OPEN","headRefName":"feature/test","baseRefName":"main","author":{"login":"developer"},"url":"https://github.com/org/repo/pull/101"}
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
      500)
        # PR para simular falha de mutação na chamada de review
        cat << 'JSON'
{"number":500,"title":"feat: pr with api failure","state":"OPEN","headRefName":"feature/fail","baseRefName":"main","author":{"login":"developer"},"url":"https://github.com/org/repo/pull/500"}
JSON
        exit 0
        ;;
      *)
        echo "Error: Pull request not found" >&2
        exit 1
        ;;
    esac
  elif [[ "$subcmd" == "review" ]]; then
    # Se pr for 500, simula falha de rede/API
    if [[ "$pr" == "500" ]]; then
      echo "GraphQL: Network timeout or connection refused" >&2
      exit 1
    fi

    # Registra a chamada recebida
    echo "$@" >> "$MOCK_LOG_FILE"
    echo "Review submitted for PR #$pr"
    exit 0
  fi
fi

echo "Unexpected gh call: $*" >&2
exit 1
EOF

chmod +x "$MOCK_BIN/gh"

export MOCK_LOG_FILE="$GH_REVIEW_LOG"
export PATH="$MOCK_BIN:$PATH"

echo "========================================================================"
echo " [TEST] Issue #52: Submissão Determinística de Pareceres de Code Review"
echo "========================================================================"

# --- 1. [HAPPY PATH] Documentação e Ajuda ---
echo ""
echo "--- 1. [HAPPY PATH] Documentação e Ajuda ---"

HELP_OUTPUT="$("$SCRIPT_UNDER_TEST" --help 2>&1 || true)"
if echo "$HELP_OUTPUT" | grep -q "submit-review"; then
  pass "--help documenta o subcomando submit-review"
else
  fail "--help NÃO documenta o subcomando submit-review"
fi

if echo "$HELP_OUTPUT" | grep -q -- "--body-file"; then
  pass "--help documenta a opção obrigatória --body-file"
else
  fail "--help NÃO documenta --body-file"
fi

if echo "$HELP_OUTPUT" | grep -q -- "--status"; then
  pass "--help documenta a opção --status"
else
  fail "--help NÃO documenta --status"
fi

if echo "$HELP_OUTPUT" | grep -q -- "--dry-run"; then
  pass "--help documenta a flag --dry-run"
else
  fail "--help NÃO documenta --dry-run"
fi

# --- 2. [HAPPY PATH] Veredito Automático (--status auto ou omitido) ---
echo ""
echo "--- 2. [HAPPY PATH] Veredito Automático (--status auto ou omitido) ---"

# 2.1 Parecer com severidade crítica -> request-changes
CRITICAL_REPORT="$TMP_TEST_DIR/report_critical.md"
cat << 'EOF' > "$CRITICAL_REPORT"
# Parecer de Code Review
## Apontamentos
- 🚨 Crítico: Risco de segurança detectado em auth.ts.
- 💡 Sugestão: Melhorar nomes de variáveis.
EOF

> "$GH_REVIEW_LOG"
OUT_CRIT="$("$SCRIPT_UNDER_TEST" submit-review 101 --body-file "$CRITICAL_REPORT" 2>&1)" || true
if grep -q "pr review 101 --request-changes" "$GH_REVIEW_LOG"; then
  pass "Auto status com '🚨 Crítico' submete review com --request-changes"
else
  fail "Auto status com '🚨 Crítico' deveria submeter --request-changes (log: $(cat "$GH_REVIEW_LOG" 2>/dev/null || echo 'vazio'))"
fi

# 2.2 Parecer com violação de integridade -> request-changes
INTEGRITY_REPORT="$TMP_TEST_DIR/report_integrity.md"
cat << 'EOF' > "$INTEGRITY_REPORT"
# Parecer de Code Review
Alerta: Violação de integridade da Golden Rule detectada no diff.
EOF

> "$GH_REVIEW_LOG"
OUT_INT="$("$SCRIPT_UNDER_TEST" submit-review 101 --body-file "$INTEGRITY_REPORT" 2>&1)" || true
if grep -q "pr review 101 --request-changes" "$GH_REVIEW_LOG"; then
  pass "Auto status com violação de integridade submete review com --request-changes"
else
  fail "Auto status com violação de integridade deveria submeter --request-changes"
fi

# 2.3 Parecer apenas com '⚠️ Importante' -> comment
WARN_REPORT="$TMP_TEST_DIR/report_warning.md"
cat << 'EOF' > "$WARN_REPORT"
# Parecer de Code Review
## Apontamentos
- ⚠️ Importante: Tratamento de exceção genérico demais.
EOF

> "$GH_REVIEW_LOG"
OUT_WARN="$("$SCRIPT_UNDER_TEST" submit-review 101 --body-file "$WARN_REPORT" --status auto 2>&1)" || true
if grep -q "pr review 101 --comment" "$GH_REVIEW_LOG"; then
  pass "Auto status com '⚠️ Importante' submete review com --comment"
else
  fail "Auto status com '⚠️ Importante' deveria submeter --comment"
fi

# 2.4 Parecer apenas com '💡 Sugestão' -> comment
SUGG_REPORT="$TMP_TEST_DIR/report_suggestion.md"
cat << 'EOF' > "$SUGG_REPORT"
# Parecer de Code Review
## Sugestões de Melhoria
- 💡 Sugestão: Considerar simplificar a função auxiliar.
EOF

> "$GH_REVIEW_LOG"
OUT_SUGG="$("$SCRIPT_UNDER_TEST" submit-review 101 --body-file "$SUGG_REPORT" 2>&1)" || true
if grep -q "pr review 101 --comment" "$GH_REVIEW_LOG"; then
  pass "Auto status com '💡 Sugestão' submete review com --comment"
else
  fail "Auto status com '💡 Sugestão' deveria submeter --comment"
fi

# 2.5 Parecer limpo sem apontamentos -> approve
CLEAN_REPORT="$TMP_TEST_DIR/report_clean.md"
cat << 'EOF' > "$CLEAN_REPORT"
# Parecer de Code Review
## Resumo
Arquitetura impecável, testes 100% aderentes, nenhuma vulnerabilidade identificada.
EOF

> "$GH_REVIEW_LOG"
OUT_CLEAN="$("$SCRIPT_UNDER_TEST" submit-review 101 --body-file "$CLEAN_REPORT" 2>&1)" || true
if grep -q "pr review 101 --approve" "$GH_REVIEW_LOG"; then
  pass "Auto status em parecer limpo submete review com --approve"
else
  fail "Auto status em parecer limpo deveria submeter --approve"
fi

# --- 3. [HAPPY PATH] Status Explícitos e Sintaxe Alternativa ---
echo ""
echo "--- 3. [HAPPY PATH] Status Explícitos e Sintaxe Alternativa ---"

# 3.1 Forçar approve mesmo com apontamento
> "$GH_REVIEW_LOG"
"$SCRIPT_UNDER_TEST" submit-review 101 --body-file "$CRITICAL_REPORT" --status approve >/dev/null 2>&1 || true
if grep -q "pr review 101 --approve" "$GH_REVIEW_LOG"; then
  pass "--status approve explícito força --approve"
else
  fail "--status approve explícito falhou em enviar --approve"
fi

# 3.2 Forçar request-changes mesmo em parecer limpo
> "$GH_REVIEW_LOG"
"$SCRIPT_UNDER_TEST" submit-review 101 --body-file "$CLEAN_REPORT" --status request-changes >/dev/null 2>&1 || true
if grep -q "pr review 101 --request-changes" "$GH_REVIEW_LOG"; then
  pass "--status request-changes explícito força --request-changes"
else
  fail "--status request-changes explícito falhou em enviar --request-changes"
fi

# 3.3 Forçar comment
> "$GH_REVIEW_LOG"
"$SCRIPT_UNDER_TEST" submit-review 101 --body-file "$CLEAN_REPORT" --status comment >/dev/null 2>&1 || true
if grep -q "pr review 101 --comment" "$GH_REVIEW_LOG"; then
  pass "--status comment explícito força --comment"
else
  fail "--status comment explícito falhou em enviar --comment"
fi

# 3.4 Sintaxe com '=' (--body-file=... --status=...)
> "$GH_REVIEW_LOG"
"$SCRIPT_UNDER_TEST" submit-review 101 "--body-file=$WARN_REPORT" "--status=comment" >/dev/null 2>&1 || true
if grep -q "pr review 101 --comment" "$GH_REVIEW_LOG"; then
  pass "Suporte à sintaxe com '=' (--body-file=... --status=...)"
else
  fail "Falha ao processar sintaxe com '='"
fi

# 3.5 Ordem de argumentos flexível (flags antes do número da PR)
> "$GH_REVIEW_LOG"
"$SCRIPT_UNDER_TEST" submit-review --body-file "$CLEAN_REPORT" --status approve 101 >/dev/null 2>&1 || true
if grep -q "pr review 101 --approve" "$GH_REVIEW_LOG"; then
  pass "Permite flags antes do número da PR"
else
  fail "Falha ao permitir flags antes do número da PR"
fi

# --- 4. [HAPPY PATH] Flag --dry-run ---
echo ""
echo "--- 4. [HAPPY PATH] Flag --dry-run ---"

> "$GH_REVIEW_LOG"
DRY_RUN_OUT="$("$SCRIPT_UNDER_TEST" submit-review 101 --body-file "$CRITICAL_REPORT" --dry-run 2>&1 || true)"

if [[ ! -s "$GH_REVIEW_LOG" ]]; then
  pass "--dry-run não realiza chamadas de mutação na API do GitHub (log de review vazio)"
else
  fail "--dry-run DISPAROU chamada gh pr review indevidamente: $(cat "$GH_REVIEW_LOG")"
fi

if echo "$DRY_RUN_OUT" | grep -qi "dry-run"; then
  pass "--dry-run emite mensagem explícita indicando simulação"
else
  fail "--dry-run não emitiu indicação de dry-run na saída"
fi

if echo "$DRY_RUN_OUT" | grep -q "Risco de segurança detectado em auth.ts"; then
  pass "--dry-run exibe o conteúdo do parecer submetido"
else
  fail "--dry-run deveria exibir o conteúdo do parecer"
fi

# --- 5. [EDGE CASES & FAILURE MODES] Validações e Resiliência ---
echo ""
echo "--- 5. [EDGE CASES & FAILURE MODES] Validações e Resiliência ---"

# 5.1 Sem número de PR
if ! "$SCRIPT_UNDER_TEST" submit-review --body-file "$CLEAN_REPORT" >/dev/null 2>&1; then
  pass "submit-review sem número de PR aborta com erro (exit != 0)"
else
  fail "submit-review sem número de PR deveria falhar"
fi

# 5.2 Sem --body-file
if ! "$SCRIPT_UNDER_TEST" submit-review 101 >/dev/null 2>&1; then
  pass "submit-review sem --body-file aborta com erro (exit != 0)"
else
  fail "submit-review sem --body-file deveria falhar"
fi

# 5.3 Arquivo de parecer inexistente
if ! "$SCRIPT_UNDER_TEST" submit-review 101 --body-file "$TMP_TEST_DIR/nonexistent.md" >/dev/null 2>&1; then
  pass "submit-review com arquivo inexistente aborta com erro (exit != 0)"
else
  fail "submit-review com arquivo inexistente deveria falhar"
fi

# 5.4 Arquivo de parecer vazio
EMPTY_REPORT="$TMP_TEST_DIR/empty.md"
touch "$EMPTY_REPORT"
if ! "$SCRIPT_UNDER_TEST" submit-review 101 --body-file "$EMPTY_REPORT" >/dev/null 2>&1; then
  pass "submit-review com arquivo vazio aborta com erro (exit != 0)"
else
  fail "submit-review com arquivo vazio deveria falhar"
fi

# 5.5 Status inválido
if ! "$SCRIPT_UNDER_TEST" submit-review 101 --body-file "$CLEAN_REPORT" --status invalid_status >/dev/null 2>&1; then
  pass "submit-review com --status inválido aborta com erro (exit != 0)"
else
  fail "submit-review com status inválido deveria falhar"
fi

# 5.6 PR fechada (CLOSED)
if ! "$SCRIPT_UNDER_TEST" submit-review 102 --body-file "$CLEAN_REPORT" >/dev/null 2>&1; then
  pass "submit-review rejeita PR CLOSED com exit code != 0"
else
  fail "submit-review deveria rejeitar PR CLOSED"
fi

# 5.7 PR mesclada (MERGED)
if ! "$SCRIPT_UNDER_TEST" submit-review 103 --body-file "$CLEAN_REPORT" >/dev/null 2>&1; then
  pass "submit-review rejeita PR MERGED com exit code != 0"
else
  fail "submit-review deveria rejeitar PR MERGED"
fi

# 5.8 PR inexistente
if ! "$SCRIPT_UNDER_TEST" submit-review 999 --body-file "$CLEAN_REPORT" >/dev/null 2>&1; then
  pass "submit-review rejeita PR inexistente com exit code != 0"
else
  fail "submit-review deveria falhar em PR inexistente"
fi

# 5.9 Falha de rede / API no comando gh
if ! "$SCRIPT_UNDER_TEST" submit-review 500 --body-file "$CLEAN_REPORT" >/dev/null 2>&1; then
  pass "submit-review falha com fail-fast quando chamada gh pr review retorna erro de rede/API"
else
  fail "submit-review deveria falhar quando a API do GitHub falhar"
fi

# --- Relatório Final ---
echo ""
echo "========================================================================"
echo " RESUMO DA EXECUÇÃO: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [[ $FAILED -eq 0 ]]; then
  echo "✅ STATUS: GREEN (Todos os testes passaram)"
  exit 0
else
  echo "❌ STATUS: RED ($FAILED teste(s) falharam)"
  exit 1
fi
