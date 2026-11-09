#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Teste de Aceitação (TDD): Utilitário promote-core-test.sh & Protocolo Interativo (Issue #64)
# =============================================================================
# Valida a promoção segura e determinística de testes de aceitação para testes core,
# com suporte a --list-candidates, --dry-run, --base, --promote, rollback automático
# e integração interativa ao ESTADO 4 de skills/issue-pipeline/SKILL.md.
# =============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PROMOTE_SCRIPT="$REPO_ROOT/scripts/pipeline/promote-core-test.sh"
SKILL_MD="$REPO_ROOT/skills/issue-pipeline/SKILL.md"

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

TMP_TEST_DIR="$(mktemp -d -t test_promote_core_XXXXXX)"
trap 'rm -rf "$TMP_TEST_DIR"' EXIT

echo "========================================================================"
echo " [TEST] Issue #64: promote-core-test.sh & Protocolo Interativo na Skill"
echo "========================================================================"

# =============================================================================
# SEÇÃO 1: HAPPY PATH
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] CLI e Execução Normal ---"

# 1.1 Existência e permissão de execução
if [[ -f "$PROMOTE_SCRIPT" && -x "$PROMOTE_SCRIPT" ]]; then
  pass "scripts/pipeline/promote-core-test.sh existe e possui permissão de execução"
else
  fail "scripts/pipeline/promote-core-test.sh não existe ou não é executável"
fi

# 1.2 Fail-fast no cabeçalho
if [[ -f "$PROMOTE_SCRIPT" ]] && grep -q "set -euo pipefail" "$PROMOTE_SCRIPT"; then
  pass "scripts/pipeline/promote-core-test.sh inicia com 'set -euo pipefail'"
else
  fail "scripts/pipeline/promote-core-test.sh não inicia com 'set -euo pipefail'"
fi

# 1.3 --help e -h
set +e
HELP_OUT=$("$PROMOTE_SCRIPT" --help 2>&1)
HELP_CODE=$?
SHORT_HELP_OUT=$("$PROMOTE_SCRIPT" -h 2>&1)
SHORT_HELP_CODE=$?
set -e

if [[ $HELP_CODE -eq 0 && $SHORT_HELP_CODE -eq 0 ]] && grep -qiE "(uso|usage):" <<< "$HELP_OUT" && grep -q -- "--promote" <<< "$SHORT_HELP_OUT"; then
  pass "--help e -h exibem manual de uso com exit code 0"
else
  fail "--help (code=$HELP_CODE) ou -h (code=$SHORT_HELP_CODE) falhou"
fi

# Preparação de repositório sandbox estéril para testes funcionais
SANDBOX="$TMP_TEST_DIR/sandbox"
mkdir -p "$SANDBOX/tests/core" "$SANDBOX/tests/features/pipeline" "$SANDBOX/scripts/pipeline"
cp "$PROMOTE_SCRIPT" "$SANDBOX/scripts/pipeline/promote-core-test.sh" 2>/dev/null || true
chmod +x "$SANDBOX/scripts/pipeline/promote-core-test.sh" 2>/dev/null || true

# Cria um mock do tests/run.sh no sandbox
cat << 'EOF' > "$SANDBOX/tests/run.sh"
#!/usr/bin/env bash
set -euo pipefail
# Mock test runner
for arg in "$@"; do
  if [[ "$arg" == "--core" || "$arg" == "tests/core" || "$arg" == "tests/core/" ]]; then
    for t in tests/core/*.sh; do
      if [[ -f "$t" ]]; then
        bash "$t"
      fi
    done
    exit 0
  fi
done
exit 0
EOF
chmod +x "$SANDBOX/tests/run.sh"

# 1.4 --list-candidates identifica marcadores @core e CORE_RULE
cat << 'EOF' > "$SANDBOX/tests/features/pipeline/test_candidate_core.sh"
#!/usr/bin/env bash
# @core - teste candidato a invariante
exit 0
EOF
chmod +x "$SANDBOX/tests/features/pipeline/test_candidate_core.sh"

cat << 'EOF' > "$SANDBOX/tests/features/pipeline/test_candidate_metadata.sh"
#!/usr/bin/env bash
# CORE_RULE: true
exit 0
EOF
chmod +x "$SANDBOX/tests/features/pipeline/test_candidate_metadata.sh"

cat << 'EOF' > "$SANDBOX/tests/features/pipeline/test_non_candidate.sh"
#!/usr/bin/env bash
# Teste regular de feature
exit 0
EOF
chmod +x "$SANDBOX/tests/features/pipeline/test_non_candidate.sh"

set +e
LIST_OUT=$(cd "$SANDBOX" && ./scripts/pipeline/promote-core-test.sh --list-candidates 2>&1)
LIST_CODE=$?
set -e

if [[ $LIST_CODE -eq 0 ]] && \
   grep -q "test_candidate_core.sh" <<< "$LIST_OUT" && \
   grep -q "test_candidate_metadata.sh" <<< "$LIST_OUT" && \
   ! grep -q "test_non_candidate.sh" <<< "$LIST_OUT"; then
  pass "--list-candidates identifica e lista apenas testes com anotações @core ou CORE_RULE"
else
  fail "--list-candidates falhou (code=$LIST_CODE, output='$LIST_OUT')"
fi

# 1.5 --dry-run não altera arquivos em disco
set +e
DRY_OUT=$(cd "$SANDBOX" && ./scripts/pipeline/promote-core-test.sh --dry-run --promote tests/features/pipeline/test_candidate_core.sh 2>&1)
DRY_CODE=$?
set -e

if [[ $DRY_CODE -eq 0 ]] && \
   [[ -f "$SANDBOX/tests/features/pipeline/test_candidate_core.sh" ]] && \
   [[ ! -f "$SANDBOX/tests/core/test_candidate_core.sh" ]] && \
   grep -qi "dry-run" <<< "$DRY_OUT"; then
  pass "--dry-run simula promoção sem movimentar arquivos em disco com exit code 0"
else
  fail "--dry-run alterou arquivos ou falhou (code=$DRY_CODE, output='$DRY_OUT')"
fi

# 1.6 --promote move com sucesso e valida suíte core
set +e
PROMOTE_OUT=$(cd "$SANDBOX" && ./scripts/pipeline/promote-core-test.sh --promote tests/features/pipeline/test_candidate_core.sh 2>&1)
PROMOTE_CODE=$?
set -e

if [[ $PROMOTE_CODE -eq 0 ]] && \
   [[ ! -f "$SANDBOX/tests/features/pipeline/test_candidate_core.sh" ]] && \
   [[ -f "$SANDBOX/tests/core/test_candidate_core.sh" ]]; then
  pass "--promote move teste para tests/core/, valida suíte e retorna exit code 0"
else
  fail "--promote falhou (code=$PROMOTE_CODE, output='$PROMOTE_OUT')"
fi

# 1.7 Integração no ESTADO 4 de skills/issue-pipeline/SKILL.md
if grep -q "promote-core-test.sh" "$SKILL_MD" && \
   grep -qi "CORE_RULE" "$SKILL_MD" && \
   grep -qiE "(perguntar|consultar|discriminar|confirmar).*promover" "$SKILL_MD"; then
  pass "skills/issue-pipeline/SKILL.md documenta protocolo interativo de promoção no ESTADO 4"
else
  fail "skills/issue-pipeline/SKILL.md não documenta protocolo interativo de promoção de testes core"
fi

# =============================================================================
# SEÇÃO 2: EDGE CASES & FAILURE MODES
# =============================================================================
echo ""
echo "--- 2. [EDGE CASES & FAILURE MODES] Resiliência, Argumentos Inválidos e Rollback ---"

# 2.1 Flag desconhecida
set +e
ERR_FLAG_OUT=$(cd "$SANDBOX" && ./scripts/pipeline/promote-core-test.sh --invalid-option 2>&1)
ERR_FLAG_CODE=$?
set -e

if [[ $ERR_FLAG_CODE -ne 0 ]] && grep -qiE "(desconhecida|inválid)" <<< "$ERR_FLAG_OUT"; then
  pass "Opção desconhecida falha com mensagem explicativa e exit code != 0"
else
  fail "Opção desconhecida não falhou como esperado (code=$ERR_FLAG_CODE)"
fi

# 2.2 --promote sem argumento
set +e
ERR_NO_ARG_OUT=$(cd "$SANDBOX" && ./scripts/pipeline/promote-core-test.sh --promote 2>&1)
ERR_NO_ARG_CODE=$?
set -e

if [[ $ERR_NO_ARG_CODE -ne 0 ]]; then
  pass "--promote sem argumento falha determinística com exit code != 0"
else
  fail "--promote sem argumento deveria falhar"
fi

# 2.3 --promote de arquivo inexistente
set +e
ERR_NO_FILE_OUT=$(cd "$SANDBOX" && ./scripts/pipeline/promote-core-test.sh --promote tests/features/inexistente.sh 2>&1)
ERR_NO_FILE_CODE=$?
set -e

if [[ $ERR_NO_FILE_CODE -ne 0 ]] && grep -qiE "(não encontrado|inexistente)" <<< "$ERR_NO_FILE_OUT"; then
  pass "--promote de arquivo inexistente falha com mensagem clara e exit code != 0"
else
  fail "--promote de arquivo inexistente não falhou adequadamente (code=$ERR_NO_FILE_CODE)"
fi

# 2.4 --promote de arquivo fora de tests/features/
echo "arquivo fora" > "$SANDBOX/outside.sh"
set +e
ERR_OUTSIDE_OUT=$(cd "$SANDBOX" && ./scripts/pipeline/promote-core-test.sh --promote outside.sh 2>&1)
ERR_OUTSIDE_CODE=$?
set -e

if [[ $ERR_OUTSIDE_CODE -ne 0 ]] && grep -qiE "(tests/features|inválido|origem)" <<< "$ERR_OUTSIDE_OUT"; then
  pass "--promote de arquivo fora de tests/features/ é rejeitado com exit code != 0"
else
  fail "--promote de arquivo fora de tests/features/ não foi rejeitado (code=$ERR_OUTSIDE_CODE)"
fi

# 2.5 Rollback automático se a validação da suíte core falhar
cat << 'EOF' > "$SANDBOX/tests/features/pipeline/test_failing_core.sh"
#!/usr/bin/env bash
# @core
echo "Erro intencional para forçar falha no core" >&2
exit 1
EOF
chmod +x "$SANDBOX/tests/features/pipeline/test_failing_core.sh"

set +e
FAIL_PROMOTE_OUT=$(cd "$SANDBOX" && ./scripts/pipeline/promote-core-test.sh --promote tests/features/pipeline/test_failing_core.sh 2>&1)
FAIL_PROMOTE_CODE=$?
set -e

if [[ $FAIL_PROMOTE_CODE -ne 0 ]] && \
   [[ -f "$SANDBOX/tests/features/pipeline/test_failing_core.sh" ]] && \
   [[ ! -f "$SANDBOX/tests/core/test_failing_core.sh" ]] && \
   grep -qi "rollback" <<< "$FAIL_PROMOTE_OUT"; then
  pass "Falha na suíte core aciona rollback automático: arquivo restaurado em features e removido de core"
else
  fail "Rollback automático falhou (code=$FAIL_PROMOTE_CODE, output='$FAIL_PROMOTE_OUT')"
fi

echo ""
echo "========================================================================"
echo " RESUMO DA SUÍTE: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [[ $FAILED -gt 0 ]]; then
  echo " >>> RESULTADO: RED (Testes falharam conforme esperado ou defeito detectado)"
  exit 1
fi

echo " >>> RESULTADO: GREEN (Todos os testes passaram com sucesso)"
exit 0
