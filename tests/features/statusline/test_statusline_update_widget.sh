#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação TDD: Widget Modular de Notificação de Atualização (Issue #67)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
STATUSLINE_SCRIPT="$REPO_ROOT/scripts/statusline/statusline-quota.sh"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #67: Zero-Noise Update Notification Widget & Sub-50ms SLA"
echo "========================================================================"

check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  [PASS] $desc"
    PASSED=$((PASSED + 1))
  else
    echo "  [FAIL] $desc"
    FAILED=$((FAILED + 1))
  fi
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
export ANTIGRAVITY_WORKSPACE="$TMP_DIR"
STDERR_OUT="$TMP_DIR/stderr.log"

# =============================================================================
# SEÇÃO 1: ESTRUTURA MODULAR E DEFINIÇÃO DE FUNÇÃO
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Estrutura Modular e Função widget_update ---"
check "Script statusline-quota.sh existe e é executável" test -x "$STATUSLINE_SCRIPT"
check "Define função modular widget_update" grep -qE '^[[:space:]]*(function[[:space:]]+)?widget_update[[:space:]]*\(\)' "$STATUSLINE_SCRIPT"

# =============================================================================
# SEÇÃO 2: ESTADO A (UP TO DATE OU SEM UPDATE) - ZERO NOISE
# =============================================================================
echo ""
echo "--- 2. [HAPPY PATH] Estado A: Up to date / Sem Atualização (Zero-Noise) ---"

CACHE_A="$TMP_DIR/cache_a.json"
cat << 'EOF' > "$CACHE_A"
{
  "plugin": "my-agents",
  "current_version": "v1.1.0",
  "latest_version": "v1.1.0",
  "update_available": false,
  "last_checked_timestamp": 2000000000,
  "ttl_seconds": 86400
}
EOF

# Teste com widget isolado (--widget update)
OUT_WIDGET_A=$(MY_AGENTS_CACHE_FILE="$CACHE_A" "$STATUSLINE_SCRIPT" --widget update 2>"$STDERR_OUT")
check "Estado A: --widget update retorna string vazia quando update_available=false" test -z "$OUT_WIDGET_A"
check "Estado A: nenhum erro emitido para stderr" test ! -s "$STDERR_OUT"

# Teste na statusline completa
OUT_STATUSLINE_A=$(echo "{}" | MY_AGENTS_CACHE_FILE="$CACHE_A" "$STATUSLINE_SCRIPT" 2>"$STDERR_OUT")
check "Estado A: statusline completa não contém indicador 📦" bash -c "! echo '$OUT_STATUSLINE_A' | grep -q '📦'"
check "Estado A: statusline completa não possui separador '│' órfão no final" bash -c "! echo '$OUT_STATUSLINE_A' | grep -qE '[│][[:space:]]*$'"
check "Estado A: statusline completa não possui separadores duplicados '│ │'" bash -c "! echo '$OUT_STATUSLINE_A' | grep -qE '│[[:space:]]*│'"

# =============================================================================
# SEÇÃO 3: ESTADO B (UPDATE AVAILABLE) - FORMATO ÂMBAR BOLD E POSICIONAMENTO
# =============================================================================
echo ""
echo "--- 3. [HAPPY PATH] Estado B: Update Disponível (Formato Âmbar Bold) ---"

CACHE_B="$TMP_DIR/cache_b.json"
cat << 'EOF' > "$CACHE_B"
{
  "plugin": "my-agents",
  "current_version": "v1.0.0",
  "latest_version": "v1.2.0",
  "update_available": true,
  "last_checked_timestamp": 2000000000,
  "ttl_seconds": 86400
}
EOF

OUT_WIDGET_B=$(MY_AGENTS_CACHE_FILE="$CACHE_B" "$STATUSLINE_SCRIPT" --widget update 2>"$STDERR_OUT")
check "Estado B: --widget update contém '📦 Update: v1.2.0'" bash -c "echo '$OUT_WIDGET_B' | grep -q '📦 Update: v1.2.0'"
check "Estado B: utiliza cor âmbar bold (\033[1;33m ou \033[38;5;214m)" bash -c "echo -e '$OUT_WIDGET_B' | grep -qE $'\033\\[(1;33|38;5;214)m'"
check "Estado B: possui reset ANSI (\033[0m)" bash -c "echo -e '$OUT_WIDGET_B' | grep -qE $'\033\\[0m'"
check "Estado B: PROIBIDO usar cor vermelha (\033[31m ou \033[1;31m)" bash -c "! echo -e '$OUT_WIDGET_B' | grep -qE $'\033\\[(31|1;31)m'"

# Teste na statusline completa
OUT_STATUSLINE_B=$(echo "{}" | MY_AGENTS_CACHE_FILE="$CACHE_B" "$STATUSLINE_SCRIPT" 2>"$STDERR_OUT")
check "Estado B: statusline completa termina com o widget de update no slot à extrema direita" bash -c "echo '$OUT_STATUSLINE_B' | grep -qE '│[[:space:]]*.*📦 Update: v1\.2\.0.*$'"
check "Estado B: statusline completa não possui separadores duplicados '│ │'" bash -c "! echo '$OUT_STATUSLINE_B' | grep -qE '│[[:space:]]*│'"

# Suporte ao campo alternativo latest_tag e versão sem 'v' prefixado
CACHE_B_TAG="$TMP_DIR/cache_b_tag.json"
cat << 'EOF' > "$CACHE_B_TAG"
{
  "plugin": "my-agents",
  "current_version": "1.0.0",
  "latest_tag": "1.3.0",
  "update_available": true,
  "last_checked_timestamp": 2000000000,
  "ttl_seconds": 86400
}
EOF
OUT_WIDGET_TAG=$(MY_AGENTS_CACHE_FILE="$CACHE_B_TAG" "$STATUSLINE_SCRIPT" --widget update 2>"$STDERR_OUT")
check "Estado B: normaliza tag sem 'v' para 'v1.3.0'" bash -c "echo '$OUT_WIDGET_TAG' | grep -q '📦 Update: v1.3.0'"

# =============================================================================
# SEÇÃO 4: RESILIÊNCIA E COMPORTAMENTO ASSÍNCRONO EM CACHE MISS / EXPIRO
# =============================================================================
echo ""
echo "--- 4. [EDGE CASES] Resiliência, Cache Ausente / Expirado e Trigger Async ---"

# Criar mock do update-plugin.sh para monitorar disparo assíncrono
MOCK_PIPELINE_DIR="$TMP_DIR/scripts/pipeline"
mkdir -p "$MOCK_PIPELINE_DIR"
MOCK_LOG="$TMP_DIR/mock_update.log"
cat << EOF > "$MOCK_PIPELINE_DIR/update-plugin.sh"
#!/usr/bin/env bash
echo "TRIGGERED:\$*" >> "$MOCK_LOG"
EOF
chmod +x "$MOCK_PIPELINE_DIR/update-plugin.sh"

# Caso 4.1: Cache inexistente
CACHE_MISSING="$TMP_DIR/non_existent_cache.json"
rm -f "$MOCK_LOG"
OUT_MISSING=$(MY_AGENTS_CACHE_FILE="$CACHE_MISSING" ANTIGRAVITY_WORKSPACE="$TMP_DIR" "$STATUSLINE_SCRIPT" --widget update 2>"$STDERR_OUT")
check "Cache ausente: retorna string vazia (sem ruído)" test -z "$OUT_MISSING"
check "Cache ausente: não emite erro para stderr" test ! -s "$STDERR_OUT"

# Aguardar brevemente para verificar disparo desanexado do mock
sleep 0.1
check "Cache ausente: disparou trigger assíncrono '--check'" grep -q "TRIGGERED:--check" "$MOCK_LOG"

# Caso 4.2: Cache expirado
rm -f "$MOCK_LOG"
CACHE_EXPIRED="$TMP_DIR/cache_expired.json"
NOW=$(date +%s)
OLD_TS=$(( NOW - 100000 )) # 100k segundos atrás (> 86400s)
cat << EOF > "$CACHE_EXPIRED"
{
  "plugin": "my-agents",
  "current_version": "v1.0.0",
  "latest_version": "v1.0.0",
  "update_available": false,
  "last_checked_timestamp": $OLD_TS,
  "ttl_seconds": 86400
}
EOF
OUT_EXPIRED=$(MY_AGENTS_CACHE_FILE="$CACHE_EXPIRED" ANTIGRAVITY_WORKSPACE="$TMP_DIR" "$STATUSLINE_SCRIPT" --widget update 2>"$STDERR_OUT")
check "Cache expirado: retorna string vazia" test -z "$OUT_EXPIRED"
sleep 0.1
check "Cache expirado: disparou trigger assíncrono '--check'" grep -q "TRIGGERED:--check" "$MOCK_LOG"

# Caso 4.3: Cache corrompido / JSON inválido
CACHE_CORRUPT="$TMP_DIR/cache_corrupt.json"
echo "{ corrupted json invalid ... " > "$CACHE_CORRUPT"
OUT_CORRUPT=$(MY_AGENTS_CACHE_FILE="$CACHE_CORRUPT" "$STATUSLINE_SCRIPT" --widget update 2>"$STDERR_OUT")
check "JSON corrompido: não explode e retorna vazio" test -z "$OUT_CORRUPT"
check "JSON corrompido: não suja stderr" test ! -s "$STDERR_OUT"

# =============================================================================
# SEÇÃO 5: BENCHMARK DE PERFORMANCE SUB-50MS (SLA ESTRITO)
# =============================================================================
echo ""
echo "--- 5. [BENCHMARK] Latência e Tempo de Resposta (< 50ms) ---"

# Medição do tempo de execução com cache hit (10 iterações)
START_TIME=$(python3 -c "import time; print(time.time())")
for i in {1..10}; do
  MY_AGENTS_CACHE_FILE="$CACHE_B" "$STATUSLINE_SCRIPT" --widget update >/dev/null 2>&1
done
END_TIME=$(python3 -c "import time; print(time.time())")
ELAPSED_MS=$(python3 -c "print(int(($END_TIME - $START_TIME) / 10 * 1000))")
echo "  [INFO] Tempo médio por invocação (--widget update): ${ELAPSED_MS}ms"
check "Latência média de --widget update é inferior a 50ms (Zero-Noise SLA)" test "$ELAPSED_MS" -lt 50

# Medição do tempo de execução na renderização completa da statusline (5 iterações)
START_FULL=$(python3 -c "import time; print(time.time())")
for i in {1..5}; do
  echo "{}" | MY_AGENTS_CACHE_FILE="$CACHE_B" "$STATUSLINE_SCRIPT" >/dev/null 2>&1
done
END_FULL=$(python3 -c "import time; print(time.time())")
ELAPSED_FULL_MS=$(python3 -c "print(int(($END_FULL - $START_FULL) / 5 * 1000))")
echo "  [INFO] Tempo médio por renderização completa: ${ELAPSED_FULL_MS}ms"
check "Latência média de render_statusline com update é inferior a 50ms" test "$ELAPSED_FULL_MS" -lt 50

# =============================================================================
# SUMÁRIO FINAL
# =============================================================================
echo ""
echo "========================================================================"
echo " RESUMO DA EXECUÇÃO: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ "$FAILED" -eq 0 ]; then
  echo "✅ STATUS: GREEN (Todos os testes de widget_update passaram)"
  exit 0
else
  echo "❌ STATUS: RED ($FAILED teste(s) falharam)"
  exit 1
fi
