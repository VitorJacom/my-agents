#!/usr/bin/env bash
# =============================================================================
# tests/features/test_audit_token_efficiency.sh
# Acceptance Tests for Token Efficiency & Pipeline Telemetry Auditor (Issue #49)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AUDIT_SCRIPT="$WORKSPACE_ROOT/scripts/audit-token-efficiency.py"

# Cores
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_GREEN="\033[32m"
C_RED="\033[31m"
C_CYAN="\033[36m"

PASSED=0
FAILED=0

pass() {
  echo -e "  ${C_GREEN}[PASS]${C_RESET} $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo -e "  ${C_RED}[FAIL]${C_RESET} $1: $2"
  FAILED=$((FAILED + 1))
}

TMP_DIR=$(mktemp -d "/tmp/audit_token_eff_test_XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

echo "========================================================================"
echo " [TEST] Token Efficiency & Pipeline Telemetry Auditor (Issue #49)"
echo "========================================================================"

# Fixture: Amostra normal com boa taxa de cache
SAMPLE_HEALTHY="$TMP_DIR/healthy_transcript.jsonl"
cat << 'EOF' > "$SAMPLE_HEALTHY"
{"step_index":0,"source":"USER_EXPLICIT","type":"USER_INPUT","status":"DONE","created_at":"2026-11-09T10:00:00Z","content":"Inicie a tarefa"}
{"step_index":1,"source":"MODEL","type":"PLANNER_RESPONSE","status":"DONE","created_at":"2026-11-09T10:00:05Z","input_tokens":12000,"cache_read_tokens":9000,"output_tokens":450,"tool_calls":[{"name":"read_file","args":{"Path":"src/app.py","StartLine":1,"EndLine":50}}]}
{"step_index":2,"source":"MODEL","type":"PLANNER_RESPONSE","status":"DONE","created_at":"2026-11-09T10:00:15Z","input_tokens":13000,"cache_read_tokens":11000,"output_tokens":320,"tool_calls":[{"name":"run_command","args":{"CommandLine":"pytest"}}]}
EOF

# Fixture: Amostra com cache miss severo e hotspots de tokens
SAMPLE_HOTSPOTS="$TMP_DIR/hotspots_transcript.jsonl"
cat << 'EOF' > "$SAMPLE_HOTSPOTS"
{"step_index":0,"source":"USER_EXPLICIT","type":"USER_INPUT","status":"DONE","created_at":"2026-11-09T10:00:00Z","content":"Tarefa pesada"}
{"step_index":1,"source":"MODEL","type":"PLANNER_RESPONSE","status":"DONE","created_at":"2026-11-09T10:00:10Z","input_tokens":75000,"cache_read_tokens":100,"output_tokens":3500,"tool_calls":[{"name":"read_file","args":{"Path":"large_dump.log"}}]}
{"step_index":2,"source":"MODEL","type":"PLANNER_RESPONSE","status":"DONE","created_at":"2026-11-09T10:00:20Z","input_tokens":82000,"cache_read_tokens":200,"output_tokens":4200,"tool_calls":[{"name":"read_file","args":{"Path":"large_dump.log"}}]}
EOF

# Fixture: Multi-agentes em brain mock
MOCK_BRAIN="$TMP_DIR/brain"
mkdir -p "$MOCK_BRAIN/planner-cid/.system_generated/logs"
mkdir -p "$MOCK_BRAIN/qa-cid/.system_generated/logs"
mkdir -p "$MOCK_BRAIN/coder-cid/.system_generated/logs"
mkdir -p "$MOCK_BRAIN/gatekeeper-cid/.system_generated/logs"

cat << 'EOF' > "$MOCK_BRAIN/planner-cid/.system_generated/logs/transcript.jsonl"
{"step_index":0,"created_at":"2026-11-09T11:00:00Z","input_tokens":15000,"cache_read_tokens":12000,"output_tokens":500,"tool_calls":[{"name":"read_file","args":{"Path":"spec.md"}}]}
EOF

cat << 'EOF' > "$MOCK_BRAIN/qa-cid/.system_generated/logs/transcript.jsonl"
{"step_index":0,"created_at":"2026-11-09T11:05:00Z","input_tokens":16000,"cache_read_tokens":13000,"output_tokens":600,"tool_calls":[{"name":"write_file","args":{"Path":"tests/test_feat.py"}}]}
EOF

cat << 'EOF' > "$MOCK_BRAIN/coder-cid/.system_generated/logs/transcript.jsonl"
{"step_index":0,"created_at":"2026-11-09T11:10:00Z","input_tokens":18000,"cache_read_tokens":14000,"output_tokens":800,"tool_calls":[{"name":"write_file","args":{"Path":"src/feat.py"}}]}
EOF

cat << 'EOF' > "$MOCK_BRAIN/gatekeeper-cid/.system_generated/logs/transcript.jsonl"
{"step_index":0,"created_at":"2026-11-09T11:15:00Z","input_tokens":14000,"cache_read_tokens":11000,"output_tokens":300,"tool_calls":[{"name":"run_command","args":{"CommandLine":"git status"}}]}
EOF

# =============================================================================
# SEÇÃO 1: HAPPY PATH
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Execução e Argumentos de Linha de Comando ---"

# 1.1 Existência e Permissão de Execução
if [ -f "$AUDIT_SCRIPT" ] && [ -x "$AUDIT_SCRIPT" ]; then
  pass "O script scripts/audit-token-efficiency.py existe e é executável"
else
  fail "O script scripts/audit-token-efficiency.py existe e é executável" "arquivo ausente ou sem permissão +x"
fi

# 1.2 Ajuda via --help e -h
set +e
HELP_OUT=$("$AUDIT_SCRIPT" --help 2>&1)
HELP_CODE=$?
set -e
if [ $HELP_CODE -eq 0 ] && grep -qi "token" <<< "$HELP_OUT" && grep -qi "usage" <<< "$HELP_OUT"; then
  pass "--help exibe sintaxe e opções com exit code 0"
else
  fail "--help exibe sintaxe e opções com exit code 0" "exit code $HELP_CODE"
fi

# 1.3 Análise de transcript único em formato padrão (Terminal)
set +e
TERM_OUT=$("$AUDIT_SCRIPT" --transcript "$SAMPLE_HEALTHY" 2>&1)
TERM_CODE=$?
set -e
if [ $TERM_CODE -eq 0 ] && grep -qi "score" <<< "$TERM_OUT" && grep -qi "read_file" <<< "$TERM_OUT"; then
  pass "Análise de transcript único exibe score e operações de tool calls"
else
  fail "Análise de transcript único exibe score e operações de tool calls" "saída inesperada: $TERM_OUT"
fi

# 1.4 Saída estruturada em JSON (--json)
set +e
JSON_OUT=$("$AUDIT_SCRIPT" --transcript "$SAMPLE_HEALTHY" --json 2>&1)
JSON_CODE=$?
set -e
if [ $JSON_CODE -eq 0 ] && python3 -c "import json, sys; d=json.loads(sys.argv[1]); assert 'score' in d and 'tools' in d" "$JSON_OUT" 2>/dev/null; then
  pass "Modo --json emite JSON válido com score e ferramentas"
else
  fail "Modo --json emite JSON válido com score e ferramentas" "falha no parsing JSON: $JSON_OUT"
fi

# 1.5 Saída estruturada em Markdown (--markdown)
set +e
MD_OUT=$("$AUDIT_SCRIPT" --transcript "$SAMPLE_HEALTHY" --markdown 2>&1)
MD_CODE=$?
set -e
if [ $MD_CODE -eq 0 ] && grep -q "|.*Tool.*|" <<< "$MD_OUT" && grep -qi "eficiência" <<< "$MD_OUT"; then
  pass "Modo --markdown emite tabelas GFM e diagnóstico estruturado"
else
  fail "Modo --markdown emite tabelas GFM e diagnóstico estruturado" "falha em Markdown: $MD_OUT"
fi

# 1.6 Análise via STDIN (--stdin)
set +e
STDIN_OUT=$(cat "$SAMPLE_HEALTHY" | "$AUDIT_SCRIPT" --stdin --json 2>&1)
STDIN_CODE=$?
set -e
if [ $STDIN_CODE -eq 0 ] && python3 -c "import json, sys; d=json.loads(sys.argv[1]); assert d['score'] >= 80" "$STDIN_OUT" 2>/dev/null; then
  pass "Suporte a pipeline via STDIN (--stdin) calcula score corretamente"
else
  fail "Suporte a pipeline via STDIN (--stdin) calcula score corretamente" "erro stdin: $STDIN_OUT"
fi

# 1.7 Mapeamento de múltiplos agentes e fases (--agents e --brain-dir)
AGENTS_MAP='{"Planner": "planner-cid", "QA": "qa-cid", "Coder": "coder-cid", "Gatekeeper": "gatekeeper-cid"}'
set +e
MULTI_OUT=$("$AUDIT_SCRIPT" --agents "$AGENTS_MAP" --brain-dir "$MOCK_BRAIN" --json 2>&1)
MULTI_CODE=$?
set -e
if [ $MULTI_CODE -eq 0 ] && python3 -c "
import json, sys
d = json.loads(sys.argv[1])
assert 'phases' in d or 'agents' in d
assert d['score'] >= 85
" "$MULTI_OUT" 2>/dev/null; then
  pass "Mapeamento multi-agente por fase (Planning, QA, Coding, Gatekeeper) calcula métricas e score alto para execução saudável"
else
  fail "Mapeamento multi-agente por fase" "erro multi-agente: $MULTI_OUT"
fi

# 1.8 Quality gate com --min-score
set +e
GATE_PASS_OUT=$("$AUDIT_SCRIPT" --transcript "$SAMPLE_HEALTHY" --min-score 70 2>&1)
GATE_PASS_CODE=$?
set -e
if [ $GATE_PASS_CODE -eq 0 ]; then
  pass "Flag --min-score 70 passa com exit code 0 para transcript saudável"
else
  fail "Flag --min-score 70 passa com exit code 0 para transcript saudável" "exit code $GATE_PASS_CODE"
fi

# =============================================================================
# SEÇÃO 2: EDGE CASES & FAILURE MODES
# =============================================================================
echo ""
echo "--- 2. [EDGE CASES & FAILURE MODES] Diagnóstico de Anomalias e Fail-Fast ---"

# 2.1 Detecção de Hotspots e Anomalias de Cache
set +e
HOTSPOT_JSON=$("$AUDIT_SCRIPT" --transcript "$SAMPLE_HOTSPOTS" --json 2>&1)
HOTSPOT_CODE=$?
set -e
if [ $HOTSPOT_CODE -eq 0 ] && python3 -c "
import json, sys
d = json.loads(sys.argv[1])
assert d['score'] < 70, f'Score esperado < 70, obtido {d[\"score\"]}'
assert len(d.get('hotspots', [])) > 0, 'Hotspots esperados não encontrados'
assert len(d.get('cache_anomalies', [])) > 0 or len(d.get('recommendations', [])) > 0
" "$HOTSPOT_JSON" 2>/dev/null; then
  pass "Identifica hotspots de consumo, anomalia de cache miss e reduz score proporcionalmente"
else
  fail "Identifica hotspots de consumo, anomalia de cache miss e reduz score proporcionalmente" "resultado: $HOTSPOT_JSON"
fi

# 2.2 Quality gate --min-score falha quando score < threshold
set +e
GATE_FAIL_OUT=$("$AUDIT_SCRIPT" --transcript "$SAMPLE_HOTSPOTS" --min-score 85 2>&1)
GATE_FAIL_CODE=$?
set -e
if [ $GATE_FAIL_CODE -ne 0 ]; then
  pass "Flag --min-score 85 falha com exit code != 0 quando score é inferior ao limiar"
else
  fail "Flag --min-score 85 falha com exit code != 0 quando score é inferior ao limiar" "esperava falha mas saiu com code 0"
fi

# 2.3 Arquivo de transcript inexistente (Fail-Fast)
set +e
NOFILE_OUT=$("$AUDIT_SCRIPT" --transcript "$TMP_DIR/nao_existe.jsonl" 2>&1)
NOFILE_CODE=$?
set -e
if [ $NOFILE_CODE -ne 0 ] && grep -qi "erro\|not found\|não existe" <<< "$NOFILE_OUT"; then
  pass "Fail-fast determinístico emite erro e sai com exit code != 0 para arquivo inexistente"
else
  fail "Fail-fast determinístico emite erro e sai com exit code != 0 para arquivo inexistente" "code $NOFILE_CODE: $NOFILE_OUT"
fi

# 2.4 Arquivo corrompido / vazio
EMPTY_FILE="$TMP_DIR/empty.jsonl"
touch "$EMPTY_FILE"
set +e
EMPTY_OUT=$("$AUDIT_SCRIPT" --transcript "$EMPTY_FILE" 2>&1)
EMPTY_CODE=$?
set -e
if [ $EMPTY_CODE -ne 0 ] && grep -qi "erro\|vazio\|empty\|nenhum" <<< "$EMPTY_OUT"; then
  pass "Fail-fast determinístico emite erro para transcript vazio ou sem eventos"
else
  fail "Fail-fast determinístico emite erro para transcript vazio ou sem eventos" "code $EMPTY_CODE: $EMPTY_OUT"
fi

# 2.5 JSON de --agents inválido
set +e
BAD_JSON_OUT=$("$AUDIT_SCRIPT" --agents "{invalido" 2>&1)
BAD_JSON_CODE=$?
set -e
if [ $BAD_JSON_CODE -ne 0 ] && grep -qi "json" <<< "$BAD_JSON_OUT"; then
  pass "Falha com erro amigável ao receber JSON malformado em --agents"
else
  fail "Falha com erro amigável ao receber JSON malformado em --agents" "code $BAD_JSON_CODE: $BAD_JSON_OUT"
fi

echo ""
echo "========================================================================"
echo " RESUMO DO TESTE: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ $FAILED -gt 0 ]; then
  echo -e "${C_RED}❌ STATUS: RED ($FAILED falha(s))${C_RESET}"
  exit 1
else
  echo -e "${C_GREEN}✅ STATUS: GREEN (Todos os testes passaram)${C_RESET}"
  exit 0
fi
