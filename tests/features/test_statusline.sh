#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD) e Benchmark: Arquitetura Modular de Statusline (Issue #6)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATUSLINE_SCRIPT="$REPO_ROOT/scripts/statusline-quota.sh"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #6: Modular Statusline Widgets & Sub-50ms Benchmark"
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

# =============================================================================
# SEÇÃO 1: ESTRUTURA MODULAR E EXECUTABILIDADE
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Estrutura Modular e Funções Exportadas ---"
check "Script scripts/statusline-quota.sh existe" test -f "$STATUSLINE_SCRIPT"
check "Script scripts/statusline-quota.sh é executável" test -x "$STATUSLINE_SCRIPT"

# Verificar se as funções modulares existem no script
check "Define função modular widget_git" grep -qE '^[[:space:]]*(function[[:space:]]+)?widget_git[[:space:]]*\(\)' "$STATUSLINE_SCRIPT"
check "Define função modular widget_model" grep -qE '^[[:space:]]*(function[[:space:]]+)?widget_model[[:space:]]*\(\)' "$STATUSLINE_SCRIPT"
check "Define função modular widget_quota" grep -qE '^[[:space:]]*(function[[:space:]]+)?widget_quota[[:space:]]*\(\)' "$STATUSLINE_SCRIPT"
check "Define função modular widget_telemetry" grep -qE '^[[:space:]]*(function[[:space:]]+)?widget_telemetry[[:space:]]*\(\)' "$STATUSLINE_SCRIPT"
check "Define função modular render_statusline" grep -qE '^[[:space:]]*(function[[:space:]]+)?render_statusline[[:space:]]*\(\)' "$STATUSLINE_SCRIPT"

# =============================================================================
# SEÇÃO 2: TOLERÂNCIA A PAYLOADS NULOS, VAZIOS E CORROMPIDOS (SEM STDERR)
# =============================================================================
echo ""
echo "--- 2. [FALLBACK & RESILIÊNCIA] Tolerância a Falhas e Silêncio em Stderr ---"

STDERR_OUT="$TMP_DIR/stderr.log"

# Payload vazio ({})
OUT_EMPTY=$(echo "{}" | "$STATUSLINE_SCRIPT" 2>"$STDERR_OUT")
check "Payload vazio ({}) não emite erro para stderr" test ! -s "$STDERR_OUT"
check "Payload vazio exibe indicador de Quota 5h default [ok]" bash -c "echo '$OUT_EMPTY' | grep -qi 'Quota 5h:.*ok'"
check "Payload vazio exibe indicador Semanal default [ok]" bash -c "echo '$OUT_EMPTY' | grep -qi 'Semanal:.*ok'"
check "Payload vazio exibe widget de telemetria default" bash -c "echo '$OUT_EMPTY' | grep -qi '📊'"

# Payload vazio via stdin fechado (/dev/null)
OUT_DEVNULL=$("$STATUSLINE_SCRIPT" </dev/null 2>"$STDERR_OUT" || true)
check "Entrada vazia (/dev/null) não emite erro para stderr" test ! -s "$STDERR_OUT"
check "Entrada vazia exibe fallback de modelo" bash -c "echo '$OUT_DEVNULL' | grep -qi '🤖'"

# Payload corrompido / JSON quebrado
OUT_CORRUPT=$(echo '{ "model": "broken json ...' | "$STATUSLINE_SCRIPT" 2>"$STDERR_OUT" || true)
check "JSON corrompido não emite erro para stderr" test ! -s "$STDERR_OUT"
check "JSON corrompido degrada graciosamente com fallback" bash -c "echo '$OUT_CORRUPT' | grep -qi '🤖'"

# Valores nulos
OUT_NULL=$(echo '{"display_name": null, "used_percentage": null, "total_tokens": null}' | "$STATUSLINE_SCRIPT" 2>"$STDERR_OUT" || true)
check "Valores nulos não geram erro em stderr" test ! -s "$STDERR_OUT"
check "Valores nulos de quota usam fallback [ok]" bash -c "echo '$OUT_NULL' | grep -qi 'Quota 5h:.*ok'"

# =============================================================================
# SEÇÃO 3: PARSING CORRETO DE PAYLOAD DO ANTIGRAVITY CLI COM TELEMETRIA
# =============================================================================
echo ""
echo "--- 3. [PARSING SCHEMA] Compatibilidade com Antigravity CLI Schema ---"

FULL_PAYLOAD='{
  "model": {
    "display_name": "Gemini 3.8 Pro (Experimental)"
  },
  "quota": {
    "buckets": [
      {"name": "5h", "used_percentage": 65.4},
      {"name": "weekly", "used_percentage": 22.0}
    ]
  },
  "telemetry": {
    "total_tokens": 42000
  }
}'

OUT_FULL=$(echo "$FULL_PAYLOAD" | "$STATUSLINE_SCRIPT" 2>"$STDERR_OUT")
check "Payload completo não emite erro em stderr" test ! -s "$STDERR_OUT"
check "Renderiza modelo customizado 'Gemini 3.8 Pro (Experimental)'" bash -c "echo '$OUT_FULL' | grep -q 'Gemini 3.8 Pro (Experimental)'"
check "Renderiza Quota 5h com valor calculado (65%)" bash -c "echo '$OUT_FULL' | grep -q '65%'"
check "Renderiza Quota Semanal com valor calculado (22%)" bash -c "echo '$OUT_FULL' | grep -q '22%'"
check "Renderiza telemetria de tokens (42k tok ou 42000 tok)" bash -c "echo '$OUT_FULL' | grep -E '42k|42000'"

# =============================================================================
# SEÇÃO 3.1: ROBUSTEZ A LOCALE (LC_NUMERIC) E DESACOPLAMENTO DE ORDEM DOS BUCKETS
# =============================================================================
echo ""
echo "--- 3.1. [ROBUSTEZ] Sensibilidade a Locale (pt_BR) e Ordem de Buckets ---"

# Payload com buckets invertidos (weekly antes de 5h) e números decimais com ponto
INVERTED_PAYLOAD='{
  "buckets": [
    { "name": "weekly", "used_percentage": 22.8 },
    { "name": "5h", "used_percentage": 65.4 }
  ]
}'

OUT_LOCALE=$(echo "$INVERTED_PAYLOAD" | LC_ALL=pt_BR.UTF-8 LC_NUMERIC=pt_BR.UTF-8 "$STATUSLINE_SCRIPT" 2>"$STDERR_OUT")
check "Execução com LC_NUMERIC=pt_BR.UTF-8 não emite erro em stderr" test ! -s "$STDERR_OUT"
check "Arredondamento correto com LC_NUMERIC=pt_BR (5h -> 65%)" bash -c "echo '$OUT_LOCALE' | grep -q '65%'"
check "Arredondamento correto com LC_NUMERIC=pt_BR (Semanal -> 23%)" bash -c "echo '$OUT_LOCALE' | grep -q '23%'"

# Teste das chamadas individuais via --widget
echo ""
echo "--- 3.2. [DISPATCHER] Consistência de Escape ANSI no Modo Individual ---"
OUT_W_GIT=$(echo '{"branch": "feature-issue-6"}' | "$STATUSLINE_SCRIPT" --widget git)
OUT_W_MODEL=$(echo "$FULL_PAYLOAD" | "$STATUSLINE_SCRIPT" --widget model)
OUT_W_QUOTA=$(echo "$FULL_PAYLOAD" | "$STATUSLINE_SCRIPT" --widget quota)
OUT_W_TELEMETRY=$(echo "$FULL_PAYLOAD" | "$STATUSLINE_SCRIPT" --widget telemetry)

check "--widget git não emite sequência literal '\033'" bash -c "! echo \"$OUT_W_GIT\" | grep -F '\\033'"
check "--widget git contém nome da branch informada no JSON" bash -c "echo \"$OUT_W_GIT\" | grep -q 'feature-issue-6'"
check "--widget model contém modelo ativo" bash -c "echo \"$OUT_W_MODEL\" | grep -q 'Gemini 3.8 Pro'"
check "--widget quota contém indicador de 5h e Semanal" bash -c "echo \"$OUT_W_QUOTA\" | grep -q 'Quota 5h:'"
check "--widget telemetry contém contagem de tokens" bash -c "echo \"$OUT_W_TELEMETRY\" | grep -q '42k tok'"

# =============================================================================
# SEÇÃO 4: BENCHMARK AUTOMATIZADO SUB-50MS (10 ITERAÇÕES CONSECUTIVAS)
# =============================================================================
echo ""
echo "--- 4. [BENCHMARK] Performance Sub-50ms em 10 Iterações Consecutivas ---"

ITERATIONS=10
TOTAL_MS=0
BENCH_LOG="$TMP_DIR/bench.log"
rm -f "$BENCH_LOG"

for i in $(seq 1 $ITERATIONS); do
  START_NS=$(date +%s%N)
  echo "$FULL_PAYLOAD" | "$STATUSLINE_SCRIPT" >/dev/null 2>"$STDERR_OUT"
  END_NS=$(date +%s%N)
  
  ELAPSED_NS=$((END_NS - START_NS))
  ELAPSED_MS=$((ELAPSED_NS / 1000000))
  TOTAL_MS=$((TOTAL_MS + ELAPSED_MS))
  echo "  Iteração $i: ${ELAPSED_MS}ms" >> "$BENCH_LOG"
done

AVG_MS=$((TOTAL_MS / ITERATIONS))
cat "$BENCH_LOG"
echo "  ==> Latência Média: ${AVG_MS}ms (Limite Máximo Obrigatório: < 50ms)"

check "Latência média em 10 iterações é estritamente menor que 50ms ($AVG_MS ms < 50 ms)" test "$AVG_MS" -lt 50

# =============================================================================
# SUMÁRIO
# =============================================================================
echo ""
echo "========================================================================"
echo " Resultado dos Testes: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi

exit 0
