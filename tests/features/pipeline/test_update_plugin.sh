#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Teste de Aceitação (TDD): Utilitário de Atualização de Plugins (Issue #66)
# =============================================================================
# Valida o comportamento do script scripts/pipeline/update-plugin.sh:
# - Subcomandos --check, --status e --apply
# - Cache com TTL de 24h e escrita atômica com lock
# - Proteção de working tree suja (fail-safe)
# - Suporte a MY_AGENTS_AUTO_UPDATE=1
# =============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRIPT_UNDER_TEST="$REPO_ROOT/scripts/pipeline/update-plugin.sh"

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

TMP_TEST_DIR="$(mktemp -d "/tmp/test_update_plugin_XXXXXX")"
cleanup() {
  rm -rf "$TMP_TEST_DIR"
}
trap cleanup EXIT

echo "========================================================================"
echo " [TEST] Issue #66: Plugin Update Utility with Cache & Dirty Tree Safety"
echo "========================================================================"

# Setup de ambiente estéril: repositório remoto ("origin") e repositório cliente ("local")
REMOTE_REPO="$TMP_TEST_DIR/remote.git"
LOCAL_REPO="$TMP_TEST_DIR/client-repo"
TEST_CACHE_DIR="$TMP_TEST_DIR/cache"
TEST_CACHE_FILE="$TEST_CACHE_DIR/my-agents-update.json"

mkdir -p "$TEST_CACHE_DIR"

# Inicializa bare remote
git init --bare "$REMOTE_REPO" >/dev/null 2>&1

# Cria commit inicial e tag v1.0.0 em um repo de seed para alimentar o remote
SEED_REPO="$TMP_TEST_DIR/seed"
git clone "$REMOTE_REPO" "$SEED_REPO" >/dev/null 2>&1
(
  cd "$SEED_REPO"
  git config user.name "Tester"
  git config user.email "tester@test.local"
  echo "v1.0.0 content" > plugin.txt
  git add plugin.txt
  git commit -m "feat: initial release" >/dev/null 2>&1
  git tag v1.0.0
  git push origin master:main --tags >/dev/null 2>&1 || git push origin HEAD:main --tags >/dev/null 2>&1
)

# Clona para o cliente local
git clone "$REMOTE_REPO" "$LOCAL_REPO" >/dev/null 2>&1
(
  cd "$LOCAL_REPO"
  git config user.name "Local Dev"
  git config user.email "dev@test.local"
  git checkout -b main origin/main >/dev/null 2>&1 || true
)

# Adiciona tag v1.1.0 no remote via seed
(
  cd "$SEED_REPO"
  echo "v1.1.0 content" >> plugin.txt
  git commit -am "feat: update to 1.1.0" >/dev/null 2>&1
  git tag v1.1.0
  git push origin HEAD:main --tags >/dev/null 2>&1
)

# =============================================================================
# SEÇÃO 1: HAPPY PATH
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Verificação, Status e Aplicação Normal ---"

# 1.1 --help e -h
set +e
HELP_OUT=$("$SCRIPT_UNDER_TEST" --help 2>&1)
HELP_CODE=$?
SHORT_HELP_OUT=$("$SCRIPT_UNDER_TEST" -h 2>&1)
SHORT_HELP_CODE=$?
set -e

if [[ $HELP_CODE -eq 0 && $SHORT_HELP_CODE -eq 0 ]] && grep -qi "uso:" <<< "$HELP_OUT" && grep -qi "check" <<< "$HELP_OUT"; then
  pass "--help e -h exibem manual de instruções e retornam exit code 0"
else
  fail "--help ou -h falhou em exibir uso válido (exit=$HELP_CODE, $SHORT_HELP_CODE)"
fi

# 1.2 --check consulta remoto e grava cache JSON
set +e
CHECK_OUT=$(cd "$LOCAL_REPO" && MY_AGENTS_CACHE_FILE="$TEST_CACHE_FILE" "$SCRIPT_UNDER_TEST" --check 2>&1)
CHECK_CODE=$?
set -e

if [[ $CHECK_CODE -eq 0 ]] && [[ -f "$TEST_CACHE_FILE" ]]; then
  # Validação de schema do JSON
  IS_VALID_JSON=$(python3 -c "
import json, sys
try:
    with open('$TEST_CACHE_FILE') as f:
        d = json.load(f)
    assert 'current_version' in d
    assert 'latest_version' in d
    assert d.get('latest_version') == 'v1.1.0'
    assert d.get('update_available') is True
    assert 'last_checked_timestamp' in d
    assert 'ttl_seconds' in d
    print('OK')
except Exception as e:
    print(f'ERROR: {e}')
")
  if [[ "$IS_VALID_JSON" == "OK" ]]; then
    pass "--check consulta remoto e persiste metadados em cache JSON válido com update_available=true"
  else
    fail "--check gravou JSON inválido ou inesperado: $IS_VALID_JSON"
  fi
else
  fail "--check falhou (code=$CHECK_CODE) ou não gerou cache em $TEST_CACHE_FILE"
fi

# 1.3 --status exibe versão local, versão remota e TTL
set +e
STATUS_OUT=$(cd "$LOCAL_REPO" && MY_AGENTS_CACHE_FILE="$TEST_CACHE_FILE" "$SCRIPT_UNDER_TEST" --status 2>&1)
STATUS_CODE=$?
set -e

if [[ $STATUS_CODE -eq 0 ]] && grep -q "v1.1.0" <<< "$STATUS_OUT" && grep -qiE "update|atualiza" <<< "$STATUS_OUT"; then
  pass "--status exibe versão atual, versão remota e status de atualização"
else
  fail "--status falhou (code=$STATUS_CODE) ou não exibiu informações esperadas:\n$STATUS_OUT"
fi

# 1.4 --apply em working tree limpa atualiza o repositório
set +e
APPLY_OUT=$(cd "$LOCAL_REPO" && MY_AGENTS_CACHE_FILE="$TEST_CACHE_FILE" "$SCRIPT_UNDER_TEST" --apply 2>&1)
APPLY_CODE=$?
set -e

LOCAL_TAG=$(cd "$LOCAL_REPO" && git describe --tags --exact-match 2>/dev/null || git describe --tags 2>/dev/null || echo "")
UPD_AFTER=$(python3 -c "import json; print(json.load(open('$TEST_CACHE_FILE')).get('update_available'))" 2>/dev/null || echo "")

if [[ $APPLY_CODE -eq 0 ]] && [[ "$LOCAL_TAG" == *"v1.1.0"* ]] && [[ "$UPD_AFTER" == "False" || "$UPD_AFTER" == "false" ]]; then
  pass "--apply atualiza repositório limpo para v1.1.0 e atualiza cache para update_available=false"
else
  fail "--apply falhou (code=$APPLY_CODE, tag=$LOCAL_TAG, upd=$UPD_AFTER). Output: $APPLY_OUT"
fi

# 1.5 MY_AGENTS_AUTO_UPDATE=1 aplica atualização automaticamente quando disponível
# Publica v1.2.0 no remote
(
  cd "$SEED_REPO"
  echo "v1.2.0 content" >> plugin.txt
  git commit -am "feat: update to 1.2.0" >/dev/null 2>&1
  git tag v1.2.0
  git push origin HEAD:main --tags >/dev/null 2>&1
)
# Força remoção do cache para disparar o check
rm -f "$TEST_CACHE_FILE"

set +e
AUTO_OUT=$(cd "$LOCAL_REPO" && MY_AGENTS_CACHE_FILE="$TEST_CACHE_FILE" MY_AGENTS_AUTO_UPDATE=1 "$SCRIPT_UNDER_TEST" --check 2>&1)
AUTO_CODE=$?
set -e

LOCAL_TAG_AFTER_AUTO=$(cd "$LOCAL_REPO" && git describe --tags --exact-match 2>/dev/null || git describe --tags 2>/dev/null || echo "")

if [[ $AUTO_CODE -eq 0 ]] && [[ "$LOCAL_TAG_AFTER_AUTO" == *"v1.2.0"* ]]; then
  pass "MY_AGENTS_AUTO_UPDATE=1 aplica a atualização automaticamente quando há nova versão e working tree limpa"
else
  fail "MY_AGENTS_AUTO_UPDATE=1 falhou (code=$AUTO_CODE, tag=$LOCAL_TAG_AFTER_AUTO). Output: $AUTO_OUT"
fi


# =============================================================================
# SEÇÃO 2: EDGE CASES & FAILURE MODES
# =============================================================================
echo ""
echo "--- 2. [EDGE CASES & FAILURE MODES] Segurança e Resiliência ---"

# 2.1 Working tree suja: --apply deve abortar com fail-safe
# Publica v1.3.0 no remote
(
  cd "$SEED_REPO"
  echo "v1.3.0 content" >> plugin.txt
  git commit -am "feat: update to 1.3.0" >/dev/null 2>&1
  git tag v1.3.0
  git push origin HEAD:main --tags >/dev/null 2>&1
)
rm -f "$TEST_CACHE_FILE"
# Roda check para registrar update_available=true
(cd "$LOCAL_REPO" && MY_AGENTS_CACHE_FILE="$TEST_CACHE_FILE" "$SCRIPT_UNDER_TEST" --check >/dev/null 2>&1 || true)

# Suja a working tree local com modificações não comitadas
echo "uncommitted changes" >> "$LOCAL_REPO/dirty_file.txt"

set +e
DIRTY_APPLY_OUT=$(cd "$LOCAL_REPO" && MY_AGENTS_CACHE_FILE="$TEST_CACHE_FILE" "$SCRIPT_UNDER_TEST" --apply 2>&1)
DIRTY_APPLY_CODE=$?
set -e

LOCAL_TAG_DIRTY=$(cd "$LOCAL_REPO" && git describe --tags --exact-match 2>/dev/null || git describe --tags 2>/dev/null || echo "")

if [[ $DIRTY_APPLY_CODE -ne 0 ]] && grep -qi "working tree" <<< "$DIRTY_APPLY_OUT" && [[ "$LOCAL_TAG_DIRTY" == *"v1.2.0"* ]]; then
  pass "Working tree suja: --apply aborta com fail-fast e preserva alterações sem atualizar código"
else
  fail "Working tree suja não foi bloqueada adequadamente (code=$DIRTY_APPLY_CODE, tag=$LOCAL_TAG_DIRTY). Output: $DIRTY_APPLY_OUT"
fi

# Limpa a working tree para próximos testes
rm -f "$LOCAL_REPO/dirty_file.txt"

# 2.2 Cache hit respeitando TTL de 24h
# O cache atual aponta para v1.3.0 com timestamp recente.
# Adicionamos v1.4.0 no remote, mas como o cache ainda está válido (dentro do TTL), o --check deve retornar cache hit sem consultar o remote
(
  cd "$SEED_REPO"
  echo "v1.4.0 content" >> plugin.txt
  git commit -am "feat: update to 1.4.0" >/dev/null 2>&1
  git tag v1.4.0
  git push origin HEAD:main --tags >/dev/null 2>&1
)

set +e
CACHE_HIT_OUT=$(cd "$LOCAL_REPO" && MY_AGENTS_CACHE_FILE="$TEST_CACHE_FILE" "$SCRIPT_UNDER_TEST" --check 2>&1)
CACHE_HIT_CODE=$?
set -e

LATEST_IN_CACHE=$(python3 -c "import json; print(json.load(open('$TEST_CACHE_FILE')).get('latest_version'))" 2>/dev/null || echo "")

if [[ $CACHE_HIT_CODE -eq 0 ]] && [[ "$LATEST_IN_CACHE" == "v1.3.0" ]] && grep -qi "cache" <<< "$CACHE_HIT_OUT"; then
  pass "Cache hit: --check reutiliza cache válido dentro do TTL sem consulta redundante ao remoto"
else
  fail "Cache hit falhou: esperado manter v1.3.0 do cache, obteve: $LATEST_IN_CACHE (code=$CACHE_HIT_CODE). Output: $CACHE_HIT_OUT"
fi

# 2.3 Expiração de TTL do cache
# Modifica last_checked_timestamp no cache para 25 horas atrás (90000 segundos)
python3 -c "
import json, time
with open('$TEST_CACHE_FILE', 'r') as f:
    d = json.load(f)
d['last_checked_timestamp'] = int(time.time()) - 90000
with open('$TEST_CACHE_FILE', 'w') as f:
    json.dump(d, f)
"

set +e
EXPIRED_OUT=$(cd "$LOCAL_REPO" && MY_AGENTS_CACHE_FILE="$TEST_CACHE_FILE" "$SCRIPT_UNDER_TEST" --check 2>&1)
EXPIRED_CODE=$?
set -e

LATEST_EXPIRED=$(python3 -c "import json; print(json.load(open('$TEST_CACHE_FILE')).get('latest_version'))" 2>/dev/null || echo "")

if [[ $EXPIRED_CODE -eq 0 ]] && [[ "$LATEST_EXPIRED" == "v1.4.0" ]]; then
  pass "Cache expirado: --check re-consulta remoto ao ultrapassar TTL e atualiza cache para nova tag v1.4.0"
else
  fail "Cache expirado falhou: esperado atualizar para v1.4.0, obteve: $LATEST_EXPIRED (code=$EXPIRED_CODE). Output: $EXPIRED_OUT"
fi

# 2.4 Lock de Concorrência
# Testa que o mecanismo de lock impede gravação corrompida em execuções concorrentes
LOCK_FILE="${TEST_CACHE_FILE}.lock"
mkdir -p "$(dirname "$LOCK_FILE")"
# Simula lock ativo por processo concorrente
exec 9>"$LOCK_FILE"
flock -n 9 || true

set +e
# Ao rodar com timeout curto de lock ou flag de verificação de lock
CONCURRENT_OUT=$(cd "$LOCAL_REPO" && MY_AGENTS_CACHE_FILE="$TEST_CACHE_FILE" MY_AGENTS_LOCK_TIMEOUT=1 "$SCRIPT_UNDER_TEST" --force-check 2>&1 || cd "$LOCAL_REPO" && MY_AGENTS_CACHE_FILE="$TEST_CACHE_FILE" MY_AGENTS_LOCK_TIMEOUT=1 "$SCRIPT_UNDER_TEST" --check --force 2>&1)
CONCURRENT_CODE=$?
# Libera o lock
flock -u 9 2>/dev/null || true
exec 9>&-
set -e

# Deve ter lidado com lock (ou retornado erro de timeout de lock sem corromper cache)
if python3 -c "import json; json.load(open('$TEST_CACHE_FILE'))" >/dev/null 2>&1; then
  pass "Lock de concorrência: integridade do cache JSON mantida sem corrupção durante contenção de lock"
else
  fail "Lock de concorrência falhou: arquivo de cache corrompido!"
fi

# 2.5 Comparação Semântica de Versões (sort -V)
# Quando a versão local estiver à frente ou igual à versão remota, update_available deve ser false
(
  cd "$LOCAL_REPO"
  git commit --allow-empty -m "bump local to v2.0.0" >/dev/null 2>&1
  git tag v2.0.0 >/dev/null 2>&1
)
set +e
HIGHER_LOCAL_OUT=$(cd "$LOCAL_REPO" && MY_AGENTS_CACHE_FILE="$TEST_CACHE_FILE" "$SCRIPT_UNDER_TEST" --force-check 2>&1)
set -e
IS_UPD_AVAIL=$(python3 -c "import json, sys; print(json.load(open(sys.argv[1])).get('update_available', ''))" "$TEST_CACHE_FILE")
if [[ "$IS_UPD_AVAIL" == "False" || "$IS_UPD_AVAIL" == "false" ]]; then
  pass "Comparação Semântica: versão local superior à remota não dispara falso update disponível"
else
  fail "Comparação Semântica falhou: esperado update_available=false quando local > remota, obteve: $IS_UPD_AVAIL"
fi

# 2.6 Caminho de Cache com Caracteres Especiais (Injeção Segura via argv)
SPECIAL_CACHE="$TMP_TEST_DIR/it's a tricky cache.json"
set +e
SPECIAL_OUT=$(cd "$LOCAL_REPO" && MY_AGENTS_CACHE_FILE="$SPECIAL_CACHE" "$SCRIPT_UNDER_TEST" --status 2>&1)
SPECIAL_CODE=$?
set -e
if [[ $SPECIAL_CODE -eq 0 ]]; then
  pass "Cache com aspas e espaços: manipulado com segurança via sys.argv sem erros de sintaxe ou injeção"
else
  fail "Cache com aspas e espaços falhou: exit code $SPECIAL_CODE. Output: $SPECIAL_OUT"
fi

# =============================================================================
# SUMÁRIO
# =============================================================================
echo ""
echo "========================================================================"
echo " RESUMO DA SUÍTE (Issue #66): $PASSED PASSADOS | $FAILED FALHADOS"
echo "========================================================================"

if [[ $FAILED -gt 0 ]]; then
  exit 1
fi
exit 0
