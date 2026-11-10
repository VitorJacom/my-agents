#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Teste de Aceitação (TDD): Gerador Automático de Issues Rastreadas com Governança
# Issue #53
# =============================================================================
# Valida o comportamento do subcomando 'create-issues' em scripts/pr-reviewer.sh:
# - Suporte a argumentos: create-issues <pr_number> --findings-file <arquivo> [--dry-run]
# - Parsing estruturado de apontamentos elegíveis (🚨 Crítico e ⚠️ Importante)
# - Criação de issues no GitHub via gh issue create com taxonomia semântica:
#     * Crítico: type:fix, status:planned, source:code-review
#     * Importante: type:refactor, status:planned, source:code-review
# - Injeção de metadados de rastreabilidade no corpo:
#     * Link da PR de origem
#     * Branch head
#     * SHA do commit (headRefOid)
#     * Critérios de remediação
# - Disparo automático do script de reconciliação de governança ao final do lote (exceto em --dry-run)
# - Suporte a --dry-run sem efeitos colaterais
# - Tratamento de falhas e edge cases:
#     * PR inexistente, CLOSED ou MERGED
#     * Argumento de PR ausente
#     * Findings-file ausente, inexistente ou vazio
#     * Arquivo sem apontamentos elegíveis (ex: apenas sugestões ou vazio)
#     * Falha de execução no GitHub CLI
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

TMP_TEST_DIR="$(mktemp -d "/tmp/test_pr_issue_gen_XXXXXX")"
cleanup() {
  rm -rf "$TMP_TEST_DIR"
}
trap cleanup EXIT

MOCK_BIN="$TMP_TEST_DIR/bin"
mkdir -p "$MOCK_BIN"

GH_LOG="$TMP_TEST_DIR/gh.log"
RECONCILE_LOG="$TMP_TEST_DIR/reconcile.log"

# Criação do mock para o GitHub CLI 'gh'
cat << 'EOF' > "$MOCK_BIN/gh"
#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"
subcmd="${2:-}"

if [[ "$cmd" == "pr" ]]; then
  pr="${3:-}"
  if [[ "$subcmd" == "view" ]]; then
    case "$pr" in
      201)
        cat << 'JSON'
{"number":201,"title":"feat: pr under review","state":"OPEN","headRefName":"feature/issue-201","baseRefName":"main","headRefOid":"a1b2c3d4e5f67890abcdef1234567890abcdef12","author":{"login":"coder-agent"},"url":"https://github.com/org/repo/pull/201"}
JSON
        exit 0
        ;;
      202)
        cat << 'JSON'
{"number":202,"title":"feat: closed pr","state":"CLOSED","headRefName":"feature/closed","baseRefName":"main","headRefOid":"b2c3d4e5f67890abcdef1234567890abcdef12a1","author":{"login":"coder-agent"},"url":"https://github.com/org/repo/pull/202"}
JSON
        exit 0
        ;;
      203)
        cat << 'JSON'
{"number":203,"title":"feat: merged pr","state":"MERGED","headRefName":"feature/merged","baseRefName":"main","headRefOid":"c3d4e5f67890abcdef1234567890abcdef12a1b2","author":{"login":"coder-agent"},"url":"https://github.com/org/repo/pull/203"}
JSON
        exit 0
        ;;
      500)
        cat << 'JSON'
{"number":500,"title":"feat: pr failing api","state":"OPEN","headRefName":"feature/fail","baseRefName":"main","headRefOid":"d4e5f67890abcdef1234567890abcdef12a1b2c3","author":{"login":"coder-agent"},"url":"https://github.com/org/repo/pull/500"}
JSON
        exit 0
        ;;
      *)
        echo "Error: Pull request not found" >&2
        exit 1
        ;;
    esac
  fi
elif [[ "$cmd" == "issue" ]]; then
  if [[ "$subcmd" == "create" ]]; then
    # Checar se simula erro de API
    for arg in "$@"; do
      if [[ "$arg" =~ "FAIL_TRIGGER" ]]; then
        echo "GraphQL: Unable to create issue due to server error" >&2
        exit 1
      fi
    done

    # Registrar a chamada em uma única linha no log para facilitar asserções
    echo "gh $*" | tr '\n' ' ' >> "$MOCK_GH_LOG"
    echo "" >> "$MOCK_GH_LOG"
    # Simula emissão do URL da nova issue criada
    echo "https://github.com/org/repo/issues/$((RANDOM % 800 + 100))"
    exit 0
  fi
fi

echo "Unexpected gh call: $*" >&2
exit 1
EOF
chmod +x "$MOCK_BIN/gh"

# Criação de mock do reconciliador de governança para testar a chamada
MOCK_RECONCILER="$MOCK_BIN/mock-reconcile.sh"
cat << 'EOF' > "$MOCK_RECONCILER"
#!/usr/bin/env bash
set -euo pipefail
echo "reconcile invoked with: $*" >> "$MOCK_RECONCILE_LOG"
echo "Reconciliation completed."
exit 0
EOF
chmod +x "$MOCK_RECONCILER"

export MOCK_GH_LOG="$GH_LOG"
export MOCK_RECONCILE_LOG="$RECONCILE_LOG"
export PATH="$MOCK_BIN:$PATH"

# Arquivo de findings padrão com 1 Crítico, 1 Importante e 1 Sugestão
FINDINGS_VALID="$TMP_TEST_DIR/findings_valid.md"
cat << 'EOF' > "$FINDINGS_VALID"
# Code Review Feedback

### 🚨 Crítico (Bloqueia Merge)
Problemas de segurança, falhas de lógica graves ou quebra de invariantes.
- **[src/auth.py:42]**: Vulnerabilidade de SQL Injection na rota de login.
  - *Sugestão de correção*: Utilizar queries parametrizadas com placeholders para sanitizar a entrada.

### ⚠️ Importante (Refatoração Recomendada)
Violações de boas práticas, ausência de testes em fluxos relevantes.
- **[src/utils.py:15]**: Complexidade ciclomática excessiva e duplicação de validação.
  - *Sugestão de correção*: Extrair sub-rotinas auxiliares e modularizar o validador.

### 💡 Sugestão (Melhoria Opcional)
Ajustes estéticos e clareza.
- **[src/app.py:10]**: Renomear variável 'x' para 'request_payload'.
EOF

# Arquivo com apenas sugestões (nenhum elegível)
FINDINGS_ONLY_SUGGESTIONS="$TMP_TEST_DIR/findings_suggestions.md"
cat << 'EOF' > "$FINDINGS_ONLY_SUGGESTIONS"
# Code Review Feedback

### 💡 Sugestão (Melhoria Opcional)
- **[src/app.py:10]**: Renomear variável 'x' para 'request_payload'.
EOF

# Arquivo de findings vazio
FINDINGS_EMPTY="$TMP_TEST_DIR/findings_empty.md"
touch "$FINDINGS_EMPTY"

# Arquivo que simula erro de API do GitHub
FINDINGS_FAIL_API="$TMP_TEST_DIR/findings_fail.md"
cat << 'EOF' > "$FINDINGS_FAIL_API"
### 🚨 Crítico (Bloqueia Merge)
- **[src/crash.py:1]**: FAIL_TRIGGER detectado no review.
  - *Sugestão de correção*: Ajustar implementação.
EOF

echo "========================================================================"
echo " [TEST] Issue #53: Gerador Automático de Issues Rastreadas com Governança"
echo "========================================================================"

# --- 1. [HAPPY PATH] Documentação e Ajuda ---
echo ""
echo "--- 1. [HAPPY PATH] Documentação e Ajuda ---"

HELP_OUTPUT="$("$SCRIPT_UNDER_TEST" --help 2>&1 || true)"
if echo "$HELP_OUTPUT" | grep -q "create-issues"; then
  pass "--help documenta o subcomando create-issues"
else
  fail "--help NÃO documenta o subcomando create-issues"
fi

if echo "$HELP_OUTPUT" | grep -q -- "--findings-file"; then
  pass "--help documenta a opção obrigatória --findings-file"
else
  fail "--help NÃO documenta --findings-file"
fi

if echo "$HELP_OUTPUT" | grep -q -- "--dry-run"; then
  pass "--help documenta a flag --dry-run em create-issues"
else
  fail "--help NÃO documenta --dry-run"
fi

# --- 2. [HAPPY PATH] Simulação via --dry-run ---
echo ""
echo "--- 2. [HAPPY PATH] Simulação via --dry-run ---"

rm -f "$GH_LOG" "$RECONCILE_LOG"
DRY_RUN_OUTPUT="$("$SCRIPT_UNDER_TEST" create-issues 201 --findings-file "$FINDINGS_VALID" --dry-run 2>&1 || true)"
DRY_RUN_STATUS=$?

if [[ $DRY_RUN_STATUS -eq 0 ]]; then
  pass "--dry-run executa com status de sucesso (exit code 0)"
else
  fail "--dry-run falhou com exit code $DRY_RUN_STATUS"
fi

if echo "$DRY_RUN_OUTPUT" | grep -qi "DRY-RUN"; then
  pass "--dry-run indica modo simulação na saída"
else
  fail "--dry-run NÃO indica modo simulação na saída"
fi

if echo "$DRY_RUN_OUTPUT" | grep -q "SQL Injection"; then
  pass "--dry-run exibe apontamento crítico planejado"
else
  fail "--dry-run NÃO exibe apontamento crítico planejado"
fi

if echo "$DRY_RUN_OUTPUT" | grep -q "Complexidade ciclomática"; then
  pass "--dry-run exibe apontamento importante planejado"
else
  fail "--dry-run NÃO exibe apontamento importante planejado"
fi

if [[ ! -f "$GH_LOG" ]]; then
  pass "--dry-run NÃO executa 'gh issue create' no GitHub CLI"
else
  fail "--dry-run EXECUTOU 'gh issue create' indevidamente"
fi

if [[ ! -f "$RECONCILE_LOG" ]]; then
  pass "--dry-run NÃO executa o script de reconciliação de governança"
else
  fail "--dry-run EXECUTOU o reconciliador de governança indevidamente"
fi

# --- 3. [HAPPY PATH] Criação Real de Issues e Invocação do Reconciliador ---
echo ""
echo "--- 3. [HAPPY PATH] Criação Real de Issues e Invocação do Reconciliador ---"

rm -f "$GH_LOG" "$RECONCILE_LOG"
REAL_RUN_OUTPUT="$(MY_AGENTS_RECONCILER_OVERRIDE="$MOCK_RECONCILER" "$SCRIPT_UNDER_TEST" create-issues 201 --findings-file "$FINDINGS_VALID" 2>&1 || true)"
REAL_RUN_STATUS=$?

if [[ $REAL_RUN_STATUS -eq 0 ]]; then
  pass "create-issues executa com sucesso no Happy Path (exit code 0)"
else
  fail "create-issues falhou com exit code $REAL_RUN_STATUS. Saída: $REAL_RUN_OUTPUT"
fi

if [[ -f "$GH_LOG" ]]; then
  ISSUES_CREATED_COUNT="$(grep -c "issue create" "$GH_LOG" || true)"
  if [[ "$ISSUES_CREATED_COUNT" -eq 2 ]]; then
    pass "Exatamente 2 issues foram geradas (1 Crítico + 1 Importante; Sugestão ignorada)"
  else
    fail "Esperado 2 issues criadas, mas foram criadas $ISSUES_CREATED_COUNT"
  fi
else
  fail "'gh issue create' não foi chamado nenhuma vez"
fi

# Validação das labels semânticas AIDD
if [[ -f "$GH_LOG" ]]; then
  CRIT_CALL="$(grep -i "SQL Injection" "$GH_LOG" || true)"
  if echo "$CRIT_CALL" | grep -q "type:fix" && echo "$CRIT_CALL" | grep -q "source:code-review" && echo "$CRIT_CALL" | grep -q "status:planned"; then
    pass "Apontamento Crítico possui taxonomia semântica (type:fix, source:code-review, status:planned)"
  else
    fail "Apontamento Crítico sem labels esperadas: $CRIT_CALL"
  fi

  IMP_CALL="$(grep -i "Complexidade" "$GH_LOG" || true)"
  if echo "$IMP_CALL" | grep -q "type:refactor" && echo "$IMP_CALL" | grep -q "source:code-review" && echo "$IMP_CALL" | grep -q "status:planned"; then
    pass "Apontamento Importante possui taxonomia semântica (type:refactor, source:code-review, status:planned)"
  else
    fail "Apontamento Importante sem labels esperadas: $IMP_CALL"
  fi

  # Validação de metadados no corpo da issue: PR de origem, branch head, commit SHA e remediação
  if echo "$CRIT_CALL" | grep -q "https://github.com/org/repo/pull/201"; then
    pass "Corpo da issue contém link da PR de origem (https://github.com/org/repo/pull/201)"
  else
    fail "Corpo da issue NÃO contém o link da PR de origem"
  fi

  if echo "$CRIT_CALL" | grep -q "feature/issue-201"; then
    pass "Corpo da issue contém a branch head (feature/issue-201)"
  else
    fail "Corpo da issue NÃO contém a branch head"
  fi

  if echo "$CRIT_CALL" | grep -q "a1b2c3d4e5f67890abcdef1234567890abcdef12"; then
    pass "Corpo da issue contém o commit SHA (headRefOid)"
  else
    fail "Corpo da issue NÃO contém o commit SHA da PR"
  fi

  if echo "$CRIT_CALL" | grep -q "parametrizadas"; then
    pass "Corpo da issue contém os critérios de remediação / sugestão de correção"
  else
    fail "Corpo da issue NÃO contém os critérios de remediação"
  fi
fi

# Validação do disparo do reconciliador de governança
if [[ -f "$RECONCILE_LOG" ]]; then
  pass "Reconciliador de governança foi executado automaticamente ao término do lote"
else
  fail "Reconciliador de governança NÃO foi acionado ao término do lote"
fi

# Suporte à sintaxe inline --findings-file=arquivo
echo ""
echo "--- 4. [HAPPY PATH] Sintaxe Alternativa --findings-file=arquivo ---"

rm -f "$GH_LOG" "$RECONCILE_LOG"
INLINE_OUTPUT="$(MY_AGENTS_RECONCILER_OVERRIDE="$MOCK_RECONCILER" "$SCRIPT_UNDER_TEST" create-issues 201 --findings-file="$FINDINGS_VALID" 2>&1 || true)"
INLINE_STATUS=$?

if [[ $INLINE_STATUS -eq 0 && -f "$GH_LOG" ]]; then
  pass "Sintaxe --findings-file=arquivo aceita com sucesso"
else
  fail "Sintaxe --findings-file=arquivo falhou com exit code $INLINE_STATUS"
fi

# --- 5. [EDGE CASES & FAILURE MODES] Validação de Entradas e Falhas ---
echo ""
echo "--- 5. [EDGE CASES & FAILURE MODES] Validação de Entradas e Falhas ---"

# PR ausente
if ! "$SCRIPT_UNDER_TEST" create-issues --findings-file "$FINDINGS_VALID" >/dev/null 2>&1; then
  pass "create-issues rejeita execução sem número da PR (exit code != 0)"
else
  fail "create-issues deveria falhar sem número da PR"
fi

# PR inexistente
if ! "$SCRIPT_UNDER_TEST" create-issues 999 --findings-file "$FINDINGS_VALID" >/dev/null 2>&1; then
  pass "create-issues falha quando a PR não existe no GitHub"
else
  fail "create-issues deveria falhar para PR inexistente"
fi

# PR CLOSED
if ! "$SCRIPT_UNDER_TEST" create-issues 202 --findings-file "$FINDINGS_VALID" >/dev/null 2>&1; then
  pass "create-issues rejeita PR em estado CLOSED"
else
  fail "create-issues deveria rejeitar PR CLOSED"
fi

# PR MERGED
if ! "$SCRIPT_UNDER_TEST" create-issues 203 --findings-file "$FINDINGS_VALID" >/dev/null 2>&1; then
  pass "create-issues rejeita PR em estado MERGED"
else
  fail "create-issues deveria rejeitar PR MERGED"
fi

# findings-file ausente
if ! "$SCRIPT_UNDER_TEST" create-issues 201 >/dev/null 2>&1; then
  pass "create-issues falha se --findings-file não for informado"
else
  fail "create-issues deveria falhar sem --findings-file"
fi

# findings-file inexistente
if ! "$SCRIPT_UNDER_TEST" create-issues 201 --findings-file "$TMP_TEST_DIR/nonexistent.md" >/dev/null 2>&1; then
  pass "create-issues falha se --findings-file aponta para arquivo inexistente"
else
  fail "create-issues deveria falhar para arquivo inexistente"
fi

# findings-file vazio
if ! "$SCRIPT_UNDER_TEST" create-issues 201 --findings-file "$FINDINGS_EMPTY" >/dev/null 2>&1; then
  pass "create-issues falha se --findings-file estiver vazio"
else
  fail "create-issues deveria falhar para arquivo de findings vazio"
fi

# findings-file sem apontamentos elegíveis (apenas sugestões)
if ! "$SCRIPT_UNDER_TEST" create-issues 201 --findings-file "$FINDINGS_ONLY_SUGGESTIONS" >/dev/null 2>&1; then
  pass "create-issues falha quando não há apontamentos elegíveis (exit code != 0)"
else
  fail "create-issues deveria falhar quando não há apontamentos elegíveis"
fi

# Falha de API no gh issue create
if ! MY_AGENTS_RECONCILER_OVERRIDE="$MOCK_RECONCILER" "$SCRIPT_UNDER_TEST" create-issues 201 --findings-file "$FINDINGS_FAIL_API" >/dev/null 2>&1; then
  pass "create-issues falha determinística se 'gh issue create' retornar erro de API"
else
  fail "create-issues deveria falhar se gh issue create falhar"
fi

echo ""
echo "========================================================================"
echo " RESUMO DO TESTE: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [[ $FAILED -gt 0 ]]; then
  echo "❌ STATUS: RED (Existem falhas a corrigir)"
  exit 1
else
  echo "✅ STATUS: GREEN (Todos os testes passaram)"
  exit 0
fi
EOF