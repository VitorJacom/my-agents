#!/usr/bin/env bash
# =============================================================================
# tests/features/pipeline/test_concurrent_qa_coder_fork.sh
# =============================================================================
# Suíte de Testes de Aceitação TDD para a Issue #11:
# Concurrent QA-Coder Fork and Contract Integration Gate (ADR-0005)
#
# Valida a governança, contratos das personas, orquestração e portão determinístico:
# - Orquestrador (skills/issue-pipeline/SKILL.md): Fork Concorrente & Join Point.
# - QA Engineer (agents/qa-engineer/agent.md): Atuação desacoplada sob contrato.
# - Coder (agents/coder/agent.md): Implementação Contract-Driven e Reconciliação.
# - Script Join Point (scripts/pipeline/contract-integration-gate.sh & .py):
#   * Happy Path: Aprovação imediata (GREEN & Cobertura >= 85%).
#   * Edge Cases & Reconciliação: Até 2 iterações de ajuste.
#   * Fail-Safe: Circuit breaker em esgotamento (Exit code 2).
#   * Anti-Fraude: Violação de confinamento de personas (Exit code 3).
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PIPELINE_SKILL="$REPO_ROOT/skills/issue-pipeline/SKILL.md"
QA_AGENT="$REPO_ROOT/agents/qa-engineer/agent.md"
CODER_AGENT="$REPO_ROOT/agents/coder/agent.md"
ARCH_DOC="$REPO_ROOT/docs/ARCHITECTURE.md"
SYSTEM_ARCH_DOC="$REPO_ROOT/docs/System-Architecture.md"
GATE_SCRIPT="$REPO_ROOT/scripts/pipeline/contract-integration-gate.sh"
GATE_PY="$REPO_ROOT/scripts/pipeline/contract-integration-gate.py"

PASSED=0
FAILED=0

echo "========================================================================"
echo " [TEST] Issue #11: Concurrent QA-Coder Fork & Contract Integration Gate"
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

# =============================================================================
# SEÇÃO 1: HAPPY PATH - CONTRATOS, PERSONAS E ORQUESTRAÇÃO DO FORK/JOIN
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Governança e Contratos do Fork Concorrente ---"

check "skills/issue-pipeline/SKILL.md existe" test -f "$PIPELINE_SKILL"
check "SKILL.md documenta o ESTADO 2 como CONCURRENT FORK" \
  grep -qiE "ESTADO 2.*CONCURRENT FORK" "$PIPELINE_SKILL"
check "SKILL.md documenta o ESTADO 3 como CONTRACT INTEGRATION GATE (JOIN POINT)" \
  grep -qiE "ESTADO 3.*CONTRACT INTEGRATION GATE" "$PIPELINE_SKILL"
check "SKILL.md diagrama Mermaid contém nó de Fork Concorrente" \
  grep -q "CONCURRENT FORK" "$PIPELINE_SKILL"
check "SKILL.md diagrama Mermaid contém nó de Join Point" \
  grep -q "CONTRACT INTEGRATION GATE" "$PIPELINE_SKILL"
check "SKILL.md define avanço imediato para Gatekeeper quando suíte GREEN" \
  grep -qiE "(avanço imediato|avance para o ESTADO 4|bypass direto)" "$PIPELINE_SKILL"

check "agents/qa-engineer/agent.md existe" test -f "$QA_AGENT"
check "qa-engineer estabelece atuação desacoplada sob contrato congelado" \
  grep -qiE "(atuação desacoplada|fork concorrente|independência sequencial)" "$QA_AGENT"
check "qa-engineer inicia sem dependência sequencial direta do coder" \
  grep -qiE "(sem qualquer dependência sequencial|sem dependência direta)" "$QA_AGENT"
check "qa-engineer orienta testes pelo Interface Contract congelado" \
  grep -qi "Interface Contract" "$QA_AGENT"

check "agents/coder/agent.md existe" test -f "$CODER_AGENT"
check "coder estabelece atuação desacoplada Contract-Driven em src/" \
  grep -qiE "(contract-driven|atuação desacoplada|fork concorrente)" "$CODER_AGENT"
check "coder inicia sem dependência sequencial direta dos testes de QA" \
  grep -qiE "(sem qualquer dependência sequencial|sem dependência direta)" "$CODER_AGENT"
check "coder estabelece atuação no Join Point e loop de reconciliação de até 2 iterações" \
  grep -qiE "(join point|loop de reconciliação|2 iterações)" "$CODER_AGENT"

check "docs/ARCHITECTURE.md registra ADR-0005 como Aprovada" \
  bash -c "grep -A 2 'Decisão 0005' '$ARCH_DOC' | grep -qi 'Aprovada'"
check "docs/System-Architecture.md registra ADR-0005 como Aprovada" \
  bash -c "grep 'Paralelismo Intra-Task' '$SYSTEM_ARCH_DOC' | grep -qi 'Aprovada'"

# =============================================================================
# SEÇÃO 2: HAPPY PATH - EXECUÇÃO DO PORTÃO DE INTEGRAÇÃO (JOIN POINT)
# =============================================================================
echo ""
echo "--- 2. [HAPPY PATH] Execução Funcional do Script do Join Point ---"

check "scripts/pipeline/contract-integration-gate.sh existe e é executável" test -x "$GATE_SCRIPT"
check "scripts/pipeline/contract-integration-gate.py existe e é executável" test -x "$GATE_PY"

# HP-GATE-01: Aprovação imediata (GREEN e Cobertura >= 85%)
HP1_OUT="$("$GATE_SCRIPT" --test-exit-code 0 --coverage 92.5)"
check "Join Point aprova com exit code 0 para suíte GREEN e cobertura >= 85%" \
  "$GATE_SCRIPT" --test-exit-code 0 --coverage 92.5
check "Join Point emite tag [JOIN_POINT: APPROVED] no stdout" \
  bash -c "echo '$HP1_OUT' | grep -q '\[JOIN_POINT: APPROVED\]'"

# HP-GATE-02: Saída JSON estruturada
HP2_JSON="$("$GATE_SCRIPT" --test-exit-code 0 --coverage 88.0 --json)"
check "Modo --json emite status APPROVED" \
  bash -c "echo '$HP2_JSON' | grep -q '\"status\": \"APPROVED\"'"
check "Modo --json inclui campos de iteração e cobertura" \
  bash -c "echo '$HP2_JSON' | grep -q '\"iteration\": 1' && echo '$HP2_JSON' | grep -q '\"coverage\": 88.0'"

# HP-GATE-03: Execução real de comando de teste com sucesso
check "Join Point executa comando real com sucesso via --test-cmd" \
  "$GATE_SCRIPT" --test-cmd "true" --coverage 85.0

# =============================================================================
# SEÇÃO 3: EDGE CASES & FAILURE MODES - LOOP DE RECONCILIAÇÃO (<= 2 ITERAÇÕES)
# =============================================================================
echo ""
echo "--- 3. [EDGE CASES & FAILURE MODES] Loop de Reconciliação e Fail-Safe ---"

# EC-REC-01: Falha na suíte na iteração 1 dispara RECONCILE_REQUIRED (Exit code 1)
REC1_EXIT=0
REC1_OUT="$("$GATE_SCRIPT" --test-exit-code 1 --iteration 1 2>&1)" || REC1_EXIT=$?
check "Iteração 1 com falha de teste retorna exit code 1" test "$REC1_EXIT" -eq 1
check "Iteração 1 emite tag [JOIN_POINT: RECONCILE_REQUIRED]" \
  bash -c "echo '$REC1_OUT' | grep -q '\[JOIN_POINT: RECONCILE_REQUIRED\]'"
check "Iteração 1 informa necessidade de reconciliação com o coder" \
  bash -c "echo '$REC1_OUT' | grep -qi 'Reconciliação requerida com coder'"

# EC-REC-02: Falha na suíte na iteração 2 ainda permite reconciliação (Exit code 1)
REC2_EXIT=0
REC2_OUT="$("$GATE_SCRIPT" --test-exit-code 1 --iteration 2 2>&1)" || REC2_EXIT=$?
check "Iteração 2 com falha de teste retorna exit code 1 (última tentativa de reconciliação)" \
  test "$REC2_EXIT" -eq 1
check "Iteração 2 emite tag [JOIN_POINT: RECONCILE_REQUIRED]" \
  bash -c "echo '$REC2_OUT' | grep -q '\[JOIN_POINT: RECONCILE_REQUIRED\]'"

# EC-REC-03: Suíte verde mas com cobertura inferior a 85% exige reconciliação
COV_EXIT=0
COV_OUT="$("$GATE_SCRIPT" --test-exit-code 0 --coverage 78.5 --iteration 1 2>&1)" || COV_EXIT=$?
check "Cobertura < 85% retorna exit code 1 (RECONCILE_REQUIRED)" test "$COV_EXIT" -eq 1
check "Mensagem detalha cobertura insuficiente" \
  bash -c "echo '$COV_OUT' | grep -qi 'cobertura de código insuficiente'"

# EC-REC-04: Fail-Safe Circuit Breaker após esgotamento de 2 iterações (Iteração 3 -> Exit code 2)
FAILSAFE_EXIT=0
FAILSAFE_OUT="$("$GATE_SCRIPT" --test-exit-code 1 --iteration 3 2>&1)" || FAILSAFE_EXIT=$?
check "Iteração 3 (esgotou 2 tentativas) aciona fail-safe com exit code 2" test "$FAILSAFE_EXIT" -eq 2
check "Iteração 3 emite tag [JOIN_POINT: FAILED_CONTRACT_INTEGRATION]" \
  bash -c "echo '$FAILSAFE_OUT' | grep -q '\[JOIN_POINT: FAILED_CONTRACT_INTEGRATION\]'"
check "Mensagem explicita limite de 2 iterações esgotado" \
  bash -c "echo '$FAILSAFE_OUT' | grep -qi 'limite de 2 iterações esgotado'"

# =============================================================================
# SEÇÃO 4: EDGE CASES & FAILURE MODES - TRAVAS ANTI-FRAUDE E CONFINAMENTO
# =============================================================================
echo ""
echo "--- 4. [EDGE CASES & FAILURE MODES] Travas Anti-Fraude e Confinamento ---"

# AF-01: QA tentando modificar src/
QA_SRC_EXIT=0
QA_SRC_OUT="$("$GATE_SCRIPT" --test-cmd "true" --qa-files "src/core/auth.py" 2>&1)" || QA_SRC_EXIT=$?
check "QA tocando em src/ bloqueia com exit code 3 (ANTI_FRAUD_VIOLATION)" test "$QA_SRC_EXIT" -eq 3
check "Alerta de violação de QA em src/" \
  bash -c "echo '$QA_SRC_OUT' | grep -qi 'qa-engineer modificou arquivo de produção proibido'"

# AF-02: QA tentando modificar tests/core/ (Golden Rule)
QA_CORE_EXIT=0
QA_CORE_OUT="$("$GATE_SCRIPT" --test-cmd "true" --qa-files "tests/core/test_base.sh" 2>&1)" || QA_CORE_EXIT=$?
check "QA tocando em tests/core/ bloqueia com exit code 3" test "$QA_CORE_EXIT" -eq 3
check "Alerta de violação da Golden Rule em tests/core/" \
  bash -c "echo '$QA_CORE_OUT' | grep -qi 'violou a Golden Rule em tests/core/'"

# AF-03: Coder tentando modificar tests/
CODER_TEST_EXIT=0
CODER_TEST_OUT="$("$GATE_SCRIPT" --test-cmd "true" --coder-files "tests/features/test_feature.sh" 2>&1)" || CODER_TEST_EXIT=$?
check "Coder tocando em tests/ bloqueia com exit code 3" test "$CODER_TEST_EXIT" -eq 3
check "Alerta de fraude de Coder modificando tests/" \
  bash -c "echo '$CODER_TEST_OUT' | grep -qi 'coder violou a Trava Anti-Fraude ao modificar arquivo em tests/'"

# AF-04: Normalização de caminhos absolutos para confinamento de escopo
QA_ABS_EXIT=0
QA_ABS_OUT="$("$GATE_SCRIPT" --test-exit-code 0 --qa-files "/workspace/my-agents/src/core/auth.py" 2>&1)" || QA_ABS_EXIT=$?
check "QA tocando em caminho absoluto /workspace/my-agents/src/... bloqueia com exit code 3" test "$QA_ABS_EXIT" -eq 3
check "Alerta de violação de QA com caminho absoluto" \
  bash -c "echo '$QA_ABS_OUT' | grep -qi 'qa-engineer modificou arquivo de produção proibido'"

CODER_ABS_EXIT=0
CODER_ABS_OUT="$("$GATE_SCRIPT" --test-exit-code 0 --coder-files "/workspace/my-agents/tests/features/test_feature.sh" 2>&1)" || CODER_ABS_EXIT=$?
check "Coder tocando em caminho absoluto /workspace/my-agents/tests/... bloqueia com exit code 3" test "$CODER_ABS_EXIT" -eq 3
check "Alerta de fraude de Coder com caminho absoluto" \
  bash -c "echo '$CODER_ABS_OUT' | grep -qi 'coder violou a Trava Anti-Fraude'"

# =============================================================================
# SEÇÃO 5: EDGE CASES - VALIDAÇÃO DE ENTRADAS ANÔMALAS E LIMITES
# =============================================================================
echo ""
echo "--- 5. [EDGE CASES] Validação de Limites e Parâmetros Inválidos ---"

# Limite: iteração menor que 1
INVALID_ITER_EXIT=0
INVALID_ITER_OUT="$("$GATE_SCRIPT" --iteration 0 --test-exit-code 0 2>&1)" || INVALID_ITER_EXIT=$?
check "Iteração < 1 é rejeitada com exit code != 0" test "$INVALID_ITER_EXIT" -ne 0
check "Mensagem de erro para iteração < 1" \
  bash -c "echo '$INVALID_ITER_OUT' | grep -qi 'iteração deve ser.*maior ou igual a 1'"

# Limite: cobertura negativa ou > 100%
INVALID_COV_EXIT=0
INVALID_COV_OUT="$("$GATE_SCRIPT" --coverage 115.0 --test-exit-code 0 2>&1)" || INVALID_COV_EXIT=$?
check "Cobertura > 100% é rejeitada com exit code != 0" test "$INVALID_COV_EXIT" -ne 0
check "Mensagem de erro para cobertura > 100%" \
  bash -c "echo '$INVALID_COV_OUT' | grep -qi 'cobertura deve ser um valor percentual entre 0.0 e 100.0'"

# =============================================================================
# SEÇÃO 6: TIMEOUT RÍGIDO E ANTI-HANG (--test-timeout)
# =============================================================================
echo ""
echo "--- 6. [TIMEOUT RÍGIDO & ANTI-HANG] Configuração de Timeout e Fail-Fast ---"

# HP-TO-01: Documentação e suporte da flag --test-timeout
check "--help documenta --test-timeout com default de 60s" \
  bash -c "'$GATE_SCRIPT' --help | grep -q -- '--test-timeout' && '$GATE_SCRIPT' --help | grep -q '60'"

# HP-TO-02: Execução com timeout explícito que conclui antes do limite
check "Comando rápido com --test-timeout 10 conclui com sucesso (exit code 0)" \
  "$GATE_SCRIPT" --test-cmd "true" --test-timeout 10 --coverage 90.0

# EC-TO-01: Comando que excede timeout é interrompido com fail-fast sem travar a esteira
TO_START=$(date +%s)
TO_EXIT=0
TO_OUT="$("$GATE_SCRIPT" --test-cmd "sleep 5" --test-timeout 1 --iteration 1 2>&1)" || TO_EXIT=$?
TO_END=$(date +%s)
TO_DURATION=$((TO_END - TO_START))

check "Comando excedendo timeout sofre fail-fast (exit code != 0)" test "$TO_EXIT" -ne 0
check "Execução abortada em tempo hábil (duração < 4s para timeout de 1s)" test "$TO_DURATION" -lt 4
check "Diagnóstico emite aviso claro de TIMEOUT" \
  bash -c "echo '$TO_OUT' | grep -qi 'TIMEOUT'"

# EC-TO-02: Modo JSON emite diagnóstico estruturado de falha por timeout
TO_JSON_EXIT=0
TO_JSON_OUT="$("$GATE_SCRIPT" --test-cmd "sleep 5" --test-timeout 1 --iteration 1 --json 2>&1)" || TO_JSON_EXIT=$?
check "Modo --json registra falha ou erro em timeout com exit code != 0" test "$TO_JSON_EXIT" -ne 0
check "Modo --json contém menção a timeout ou exit code 124 na saída" \
  bash -c "echo '$TO_JSON_OUT' | grep -qiE '(timeout|124)'"

# EC-TO-03: Timeout inválido (<= 0 ou inválido) é rejeitado com erro
INV_TO_EXIT=0
INV_TO_OUT="$("$GATE_SCRIPT" --test-cmd "true" --test-timeout 0 2>&1)" || INV_TO_EXIT=$?
check "Timeout <= 0 é rejeitado com exit code != 0" test "$INV_TO_EXIT" -ne 0
check "Mensagem de erro para timeout inválido" \
  bash -c "echo '$INV_TO_OUT' | grep -qiE 'timeout.*maior que zero'"

# =============================================================================
# SEÇÃO 7: BLINDAGEM CONTRA FALLBACK PESADO SILENCIOSO
# =============================================================================
echo ""
echo "--- 7. [BLINDAGEM CONTRA FALLBACK] Eliminação de Execução Pesada Implícita ---"

# EC-FB-01: Invocação sem --test-cmd e sem --test-exit-code falha imediatamente
NO_CMD_EXIT=0
NO_CMD_OUT="$("$GATE_SCRIPT" --iteration 1 2>&1)" || NO_CMD_EXIT=$?
check "Execução sem --test-cmd e sem --test-exit-code falha imediatamente (exit code != 0)" \
  test "$NO_CMD_EXIT" -ne 0
check "Mensagem alerta sobre desativação de fallback implícito ou obrigatoriedade de comando" \
  bash -c "echo '$NO_CMD_OUT' | grep -qiE '(--test-cmd|--test-exit-code|fallback)'"

# EC-FB-02: Invocação com arquivos válidos mas sem comando de teste não dispara suíte pesada
VALID_FILES_EXIT=0
VALID_FILES_OUT="$("$GATE_SCRIPT" --qa-files "tests/features/pipeline/test_foo.sh" --coder-files "src/pipeline/foo.py" 2>&1)" || VALID_FILES_EXIT=$?
check "Arquivos válidos sem --test-cmd / --test-exit-code não executam suíte pesada e falham com exit code != 0" \
  test "$VALID_FILES_EXIT" -ne 0

# =============================================================================
# SEÇÃO 8: GOVERNANÇA AIDD (AGENTS.md & PERSONA QA-ENGINEER)
# =============================================================================
echo ""
echo "--- 8. [GOVERNANÇA AIDD] Regras de Timeouts, Anti-Hang e Mocks ---"

AGENTS_RULE="$REPO_ROOT/rules/AGENTS.md"
check "rules/AGENTS.md formaliza regra de Timeouts Rígidos Mandatórios em testes" \
  grep -qiE "(timeouts? rígidos? mandatórios?|anti-hang|timeout em subprocessos)" "$AGENTS_RULE"
check "rules/AGENTS.md proíbe fallback pesado silencioso" \
  grep -qiE "(fallback pesado silencioso|fallback implícito)" "$AGENTS_RULE"
check "rules/AGENTS.md exige mocks determinísticos em testes de esteira/CLI" \
  grep -qiE "(mocks? determinísticos?|obrigatoriedade de mocks|--test-cmd)" "$AGENTS_RULE"

check "agents/qa-engineer/agent.md define diretrizes de timeout e anti-hang" \
  grep -qiE "(timeouts?|anti-hang|tempo limite)" "$QA_AGENT"
check "agents/qa-engineer/agent.md define obrigatoriedade de mocks rápidos em testes de infra/pipeline" \
  grep -qiE "(mocks?|fallback pesado|isolamento determinístico)" "$QA_AGENT"

# =============================================================================
# RELATÓRIO CONSOLIDADO
# =============================================================================
echo ""
echo "========================================================================"
echo " RESUMO DO TESTE: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ "$FAILED" -eq 0 ]; then
  echo "✅ TODOS OS TESTES PASSARAM COM SUCESSO!"
  exit 0
else
  echo "❌ HOUVE FALHAS NA SUÍTE DE TESTES."
  exit 1
fi
