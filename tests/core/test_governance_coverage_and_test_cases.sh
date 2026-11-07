#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Conformidade: Governança de Cobertura (85%), Testes Happy/Edge
# e Provas Demonstrativas Universais (Issue #12)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RULES_MD="$REPO_ROOT/rules/AGENTS.md"
QA_MD="$REPO_ROOT/agents/qa-engineer/agent.md"
CODER_MD="$REPO_ROOT/agents/coder/agent.md"
GATEKEEPER_MD="$REPO_ROOT/agents/gatekeeper/agent.md"
PIPELINE_MD="$REPO_ROOT/skills/issue-pipeline/SKILL.md"

FAILED=0

echo "========================================================================"
echo " [TEST] Governança de Cobertura (85%), Casos Happy/Edge e Provas"
echo "========================================================================"

check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  [PASS] $desc"
  else
    echo "  [FAIL] $desc"
    FAILED=1
  fi
}

echo ""
echo "--- 1. Governança Global AIDD (rules/AGENTS.md) ---"
check "rules/AGENTS.md existe" test -f "$RULES_MD"

# Happy Path
check "Seção 1.3 exige provas demonstrativas para qualquer domínio" \
  bash -c "sed -n '/### 1\.3/,/### 1\.4/p' '$RULES_MD' | grep -qiE '(prova demonstrativa|evidência demonstrativa|provas demonstrativas|evidências demonstrativas)'"

check "Seção 1.3 exige screenshots para UIs e evidências reais (CLI/snapshots/logs) para backend/CLI/infra" \
  bash -c "sed -n '/### 1\.3/,/### 1\.4/p' '$RULES_MD' | grep -qiE '(screenshot|captura)' && sed -n '/### 1\.3/,/### 1\.4/p' '$RULES_MD' | grep -qiE '(saída cli|snapshots de terminal|logs estruturados|evidência demonstrativa|evidências demonstrativas)'"

check "Seção 2.4 define governança de cobertura mínima de código >= 85%" \
  bash -c "sed -n '/### 2\.4/,/### 2\.5/p' '$RULES_MD' | grep -qiE '(cobertura|coverage)' && sed -n '/### 2\.4/,/### 2\.5/p' '$RULES_MD' | grep -qE '85%'"

check "Seção 2.5 define discriminação mandatória de Happy Path e Edge Cases / Failure Modes" \
  bash -c "sed -n '/### 2\.5/,\$p' '$RULES_MD' | grep -qi 'Happy Path' && sed -n '/### 2\.5/,\$p' '$RULES_MD' | grep -qiE '(Edge Cases|Failure Modes)'"

# Edge Cases & Failure Modes
check "[Edge Case] Seção 1.3 explicita não-isenção de provas para backend/CLI/infra" \
  bash -c "sed -n '/### 1\.3/,/### 1\.4/p' '$RULES_MD' | grep -qiE '(não são isent|não estão isent|não há isenção|não-isenção)'"

check "[Edge Case] Seção 2.4 instrui fail-fast se cobertura for inferior a 85%" \
  bash -c "sed -n '/### 2\.4/,/### 2\.5/p' '$RULES_MD' | grep -qiE '(< 85%|abaixo de 85%|inferior a 85%|menor que 85%)' && sed -n '/### 2\.4/,/### 2\.5/p' '$RULES_MD' | grep -qiE '(falha|bloqueia|rejeita|circuit-breaker|interromp)'"

echo ""
echo "--- 2. Subagente QA Engineer (agents/qa-engineer/agent.md) ---"
check "qa-engineer/agent.md existe" test -f "$QA_MD"

# Happy Path
check "Exige estruturação discriminando explicitamente Happy Path de Edge Cases / Failure Modes" \
  bash -c "grep -qi 'Happy Path' '$QA_MD' && grep -qiE '(Edge Cases|Failure Modes)' '$QA_MD'"

check "Contrato de saída detalha explicitamente cenários Happy Path e Edge Cases" \
  bash -c "sed -n '/## 📄 Contrato de Saída/,\$p' '$QA_MD' | grep -qi 'Happy Path' && sed -n '/## 📄 Contrato de Saída/,\$p' '$QA_MD' | grep -qiE '(Edge Cases|Failure Modes)'"

# Edge Cases & Failure Modes
check "[Edge Case] Exige obrigatoriedade de cobertura de cenários de borda e erro" \
  bash -c "grep -qiE '(obrigatório incluir|obrigatória a inclusão|mandatório incluir|sem cenários de borda|cenários de erro|proibido limitar-se|proibido omitir)' '$QA_MD'"

echo ""
echo "--- 3. Subagente Coder (agents/coder/agent.md) ---"
check "coder/agent.md existe" test -f "$CODER_MD"

# Happy Path
check "Exige aferição e alcance de cobertura de código mínima >= 85%" \
  bash -c "grep -qiE '(cobertura|coverage)' '$CODER_MD' && grep -qE '85%' '$CODER_MD'"

check "Contrato de saída exige relatório/métrica de cobertura alcançada" \
  bash -c "sed -n '/## 📄 Contrato de Saída/,\$p' '$CODER_MD' | grep -qiE '(cobertura|coverage)'"

# Edge Cases & Failure Modes
check "[Edge Case] Proíbe considerar GREEN se cobertura estiver abaixo de 85%" \
  bash -c "grep -qiE '(abaixo de 85|< 85%|inferior a 85%)' '$CODER_MD'"

echo ""
echo "--- 4. Subagente Gatekeeper (agents/gatekeeper/agent.md) ---"
check "gatekeeper/agent.md existe" test -f "$GATEKEEPER_MD"

# Happy Path
check "Gate 2 audita cobertura mínima >= 85%" \
  bash -c "sed -n '/## 🔍 Auditoria de Conformidade Canônica (Gate 2)/,/## 📄 Geração do/p' '$GATEKEEPER_MD' | grep -qiE '(cobertura|coverage)' && sed -n '/## 🔍 Auditoria de Conformidade Canônica (Gate 2)/,/## 📄 Geração do/p' '$GATEKEEPER_MD' | grep -qE '85%'"

check "Gate 2 audita separação de cenários Happy Path e Edge Cases" \
  bash -c "sed -n '/## 🔍 Auditoria de Conformidade Canônica (Gate 2)/,/## 📄 Geração do/p' '$GATEKEEPER_MD' | grep -qi 'Happy Path' && sed -n '/## 🔍 Auditoria de Conformidade Canônica (Gate 2)/,/## 📄 Geração do/p' '$GATEKEEPER_MD' | grep -qiE '(Edge Cases|cenários de borda)'"

check "Audita provas demonstrativas no walkthrough.md para UIs (screenshots) e backend/CLI (logs/snapshots)" \
  bash -c "sed -n '/## 📄 Geração do/,\$p' '$GATEKEEPER_MD' | grep -qiE '(screenshot|captura)' && sed -n '/## 📄 Geração do/,\$p' '$GATEKEEPER_MD' | grep -qiE '(terminal|cli|logs)'"

# Edge Cases & Failure Modes
check "[Edge Case] Gate 2 rejeita entrega se cobertura < 85%" \
  bash -c "sed -n '/## 🔍 Auditoria de Conformidade Canônica (Gate 2)/,/## 📄 Geração do/p' '$GATEKEEPER_MD' | grep -qiE '(< 85%|abaixo de 85%|inferior a 85%)' && sed -n '/## 🔍 Auditoria de Conformidade Canônica (Gate 2)/,/## 📄 Geração do/p' '$GATEKEEPER_MD' | grep -qiE '(rejeita|aborta|bloqueia)'"

check "[Edge Case] Gate 2 rejeita entrega se faltar discriminação de Edge Cases / Failure Modes" \
  bash -c "sed -n '/## 🔍 Auditoria de Conformidade Canônica (Gate 2)/,/## 📄 Geração do/p' '$GATEKEEPER_MD' | grep -qiE '(sem (cenários de borda|edge cases)|ausência de (cenários de borda|edge cases)|faltar (cenários de borda|edge cases))' && sed -n '/## 🔍 Auditoria de Conformidade Canônica (Gate 2)/,/## 📄 Geração do/p' '$GATEKEEPER_MD' | grep -qiE '(rejeita|bloqueia|aborta)'"

echo ""
echo "--- 5. Orquestrador de Execução (skills/issue-pipeline/SKILL.md) ---"
check "issue-pipeline/SKILL.md existe" test -f "$PIPELINE_MD"

# Happy Path
check "ESTADO 2 orienta QA a cobrir e categorizar Happy Path e Edge Cases" \
  bash -c "sed -n '/### 📍 ESTADO 2/,/### 📍 ESTADO 3/p' '$PIPELINE_MD' | grep -qi 'Happy Path' && sed -n '/### 📍 ESTADO 2/,/### 📍 ESTADO 3/p' '$PIPELINE_MD' | grep -qiE '(Edge Cases|borda)'"

check "ESTADO 3 orienta Coder a garantir cobertura mínima >= 85%" \
  bash -c "sed -n '/### 📍 ESTADO 3/,/### 📍 ESTADO 3\.5/p' '$PIPELINE_MD' | grep -qE '85%'"

check "ESTADO 4 instrui Gatekeeper a auditar cobertura >= 85% e discriminação Happy/Edge" \
  bash -c "sed -n '/### 📍 ESTADO 4/,/2\. \*\*Conclusão/p' '$PIPELINE_MD' | grep -qE '85%' && sed -n '/### 📍 ESTADO 4/,/2\. \*\*Conclusão/p' '$PIPELINE_MD' | grep -qiE '(Happy Path|Edge Cases|borda)'"

check "ESTADO 4 exige provas demonstrativas no walkthrough.md para todos os domínios" \
  bash -c "sed -n '/### 📍 ESTADO 4/,/2\. \*\*Conclusão/p' '$PIPELINE_MD' | grep -qiE '(prova demonstrativa|evidência demonstrativa|provas demonstrativas|evidências demonstrativas|terminal|cli|logs)'"

# Edge Cases & Failure Modes
check "[Edge Case] Interrupção da esteira se cobertura for inferior a 85%" \
  bash -c "grep -qiE '(< 85%|abaixo de 85%|inferior a 85%)' '$PIPELINE_MD' && grep -qiE '(interrompa|aborte|bloqueie)' '$PIPELINE_MD'"

echo ""
echo "========================================================================"
if [ "$FAILED" -ne 0 ]; then
  echo " >>> RESULTADO: RED (Falha esperada: regras de cobertura 85%, Happy/Edge e provas ainda não implementadas)"
  echo "========================================================================"
  exit 1
else
  echo " >>> RESULTADO: GREEN (Sucesso: todos os critérios de governança foram atendidos)"
  echo "========================================================================"
  exit 0
fi
