#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Conformidade: Mandato de Delegação de Subagentes no Modo Maestro
# (Issue #42 - Phase RED)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RULES_MD="$REPO_ROOT/rules/AGENTS.md"
PIPELINE_MD="$REPO_ROOT/skills/issue-pipeline/SKILL.md"

FAILED=0
TOTAL=0
PASSED=0

echo "========================================================================"
echo " [TEST] Mandato de Delegação de Subagentes no Modo Maestro (Issue #42)"
echo "========================================================================"

check() {
  local desc="$1"
  shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then
    echo "  [PASS] $desc"
    PASSED=$((PASSED + 1))
  else
    echo "  [FAIL] $desc"
    FAILED=$((FAILED + 1))
  fi
}

echo ""
echo "--- Happy Path 1: Existência e Definição da Seção 7.4 em rules/AGENTS.md ---"
check "HP1.1: rules/AGENTS.md existe" test -f "$RULES_MD"
check "HP1.2: rules/AGENTS.md possui subseção '7.4' dedicada ao Modo Maestro" \
  grep -qE "^### 7\.4\..*Modo Maestro" "$RULES_MD"
check "HP1.3: Seção 7.4 define expressamente a segregação de planos (Control Plane vs Execution Plane)" \
  bash -c "sed -n '/^### 7\.4/,/^---/p' '$RULES_MD' | grep -qiE '(Control Plane|Execution Plane)'"
check "HP1.4: Seção 7.4 delimita que a sessão principal opera exclusivamente como Maestro / Control Plane" \
  bash -c "sed -n '/^### 7\.4/,/^---/p' '$RULES_MD' | grep -qiE '(exclusivamente|estritamente).*Control Plane'"

echo ""
echo "--- Happy Path 2: Exigência Mandatória de invoke_subagent em rules/AGENTS.md ---"
check "HP2.1: Seção 7.4 exige formalmente a delegação para workers via 'invoke_subagent'" \
  bash -c "sed -n '/^### 7\.4/,/^---/p' '$RULES_MD' | grep -qE 'invoke_subagent'"
check "HP2.2: Seção 7.4 estipula que cada issue da onda ativa deve ser despachada para subagente desacoplado" \
  bash -c "sed -n '/^### 7\.4/,/^---/p' '$RULES_MD' | grep -qiE '(onda|wave|batch)' && sed -n '/^### 7\.4/,/^---/p' '$RULES_MD' | grep -qiE '(subagente|worker)'"

echo ""
echo "--- Happy Path 3: Amarração Normativa em skills/issue-pipeline/SKILL.md ---"
check "HP3.1: skills/issue-pipeline/SKILL.md existe" test -f "$PIPELINE_MD"
check "HP3.2: Fluxo do Modo Maestro amarra o despacho ao mandato normativo do Manifesto AIDD (Seção 7 / 7.4)" \
  bash -c "sed -n '/## 🚀 Fluxo 2: Modo Maestro/,/^## /p' '$PIPELINE_MD' | grep -qiE '(Manifesto AIDD|Seção 7\.4|7\.4)'"
check "HP3.3: M3 explicita a obrigatoriedade de delegação via invoke_subagent" \
  bash -c "sed -n '/### 📍 M3/,/### 📍 M4/p' '$PIPELINE_MD' | grep -qiE 'invoke_subagent.*(mandat|obrigat)'"

echo ""
echo "--- Edge Cases & Failure Modes (EC1, EC2, EC3) ---"
check "EC1.1: rules/AGENTS.md proíbe expressamente a sessão principal/Maestro de codificar ou executar TDD diretamente" \
  bash -c "sed -n '/^### 7\.4/,/^---/p' '$RULES_MD' | grep -qiE '(proibido|vedado|nunca).*(executar|codificar|tdd|testes|inspecionar código|editar)'"
check "EC1.2: skills/issue-pipeline/SKILL.md proíbe explicitamente o Maestro de rodar ciclos TDD ou editar arquivos na raiz" \
  bash -c "sed -n '/## 🚀 Fluxo 2: Modo Maestro/,/^## /p' '$PIPELINE_MD' | grep -qiE '(proibido|vedado|não deve).*(executar ciclos tdd|codificar na raiz|editar arquivos na raiz)'"
check "EC2.1: rules/AGENTS.md 7.4 impõe confinamento estrito de cada worker em .worktrees/issue-<id>" \
  bash -c "sed -n '/^### 7\.4/,/^---/p' '$RULES_MD' | grep -qE '\.worktrees/issue-'"
check "EC2.2: skills/issue-pipeline/SKILL.md estabelece isolamento físico estrito impedindo interferência na raiz ou em worktrees simultâneas" \
  bash -c "sed -n '/### 📍 M3/,/### 📍 M4/p' '$PIPELINE_MD' | grep -qiE '(sem interferir|isolamento estrito|estéril|confinado)'"
check "EC3.1: Trava Anti-Fraude (Golden Rule) - Nenhuma modificação em tests/core/" \
  bash -c "! git status --porcelain | grep -qE 'tests/core/'"
check "EC3.2: rules/AGENTS.md mantém formato markdown válido sem marcadores órfãos ou conflitos" \
  bash -c "! grep -qE '(<<<<<<<|=======|>>>>>>>)' '$RULES_MD'"

echo ""
echo "========================================================================"
echo " Resumo: $PASSED passados, $FAILED falhados de $TOTAL testes"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo " [RED] Suíte falhou como esperado na fase RED do ciclo TDD."
  exit 1
else
  echo " [GREEN] Todos os testes passaram."
  exit 0
fi
