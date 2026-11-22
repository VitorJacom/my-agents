#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Teste de Aceitação (TDD): Orquestrador da Skill /review-pr com Gate Humano
# Issue #54
# =============================================================================
# Valida a especificação, estrutura e rastreabilidade da Skill /review-pr:
# 1. Existência e Frontmatter YAML de skills/review-pr/SKILL.md
# 2. Protocolo de Invocação (/review-pr <#PR | URL>)
# 3. Máquina de Estados Determinística de 5 Fases
# 4. Gate de Validação Humana Mandatório
# 5. Papel dos Subagentes e Subcomandos do scripts/pr-reviewer.sh
# 6. Integração Cruzada em skills/code-review/SKILL.md
# 7. Documentação e Integridade de Links em docs/Skills-Catalog.md
# 8. Casos de Borda e Falhas (Golden Rule Circuit-Breaker, Rejeição no Gate)
# =============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PR_SKILL="$REPO_ROOT/skills/pr/SKILL.md"
SKILLS_CATALOG="$REPO_ROOT/docs/Skills-Catalog.md"

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

check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

echo "========================================================================"
echo " [TEST] Issue #54: Orquestrador da Skill /pr com Gate Humano"
echo "========================================================================"

# =============================================================================
# SEÇÃO 1: [HAPPY PATH] Estrutura Canônica de skills/pr/SKILL.md
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Estrutura e Metadados da Skill pr ---"

check "skills/pr/SKILL.md existe no repositório" test -f "$PR_SKILL"
check "skills/pr/SKILL.md não está vazio" test -s "$PR_SKILL"

# Validação do Frontmatter YAML
check "Frontmatter possui delimitador de abertura '---'" \
  bash -c "head -n 1 '$PR_SKILL' | grep -q '^---'"

check "Frontmatter declara 'name: pr'" \
  bash -c "grep -E '^name:\s*pr\b' '$PR_SKILL'"

check "Frontmatter declara campo 'description:'" \
  bash -c "grep -E '^description:' '$PR_SKILL'"

# =============================================================================
# SEÇÃO 2: [HAPPY PATH] Protocolo de Invocação e Parâmetros
# =============================================================================
echo ""
echo "--- 2. [HAPPY PATH] Protocolo de Invocação (/pr) ---"

check "Documenta sintaxe de invocação '/pr <#PR | URL>'" \
  bash -c "grep -E '/pr <#PR \| URL>' '$PR_SKILL'"

check "Documenta suporte a identificador numérico (#12 ou 12)" \
  bash -c "grep -E '/pr #?[0-9]+' '$PR_SKILL'"

check "Documenta suporte a URL completa de Pull Request" \
  bash -c "grep -E 'https://github\.com/[^ ]+/pull/[0-9]+' '$PR_SKILL'"

check "Documenta modo de auditoria local (/pr local) e 4 dimensões (OWASP, SOLID)" \
  bash -c "grep -q '/pr local' '$PR_SKILL' && grep -qi 'OWASP' '$PR_SKILL' && grep -qi 'SOLID' '$PR_SKILL'"

# =============================================================================
# SEÇÃO 3: [HAPPY PATH] Máquina de Estados de 5 Fases
# =============================================================================
echo ""
echo "--- 3. [HAPPY PATH] Máquina de Estados de 5 Fases e Subcomandos ---"

check "Fase 1: Inspeção & Diff documentada com fetch-diff" \
  bash -c "grep -qi 'Fase 1' '$PR_SKILL' && grep -q 'fetch-diff' '$PR_SKILL'"

check "Fase 2: Auditoria de Integridade & Golden Rule documentada com audit-integrity" \
  bash -c "grep -qi 'Fase 2' '$PR_SKILL' && grep -q 'audit-integrity' '$PR_SKILL'"

check "Fase 3: Revisão Heurística & Severidade documentada em 4 dimensões" \
  bash -c "grep -qi 'Fase 3' '$PR_SKILL' && grep -qi 'Severidade' '$PR_SKILL'"

check "Fase 3 categoriza severidades: Crítico, Importante e Sugestão" \
  bash -c "grep -q 'Crítico' '$PR_SKILL' && grep -q 'Importante' '$PR_SKILL' && grep -q 'Sugestão' '$PR_SKILL'"

check "Fase 4: Gate de Validação Humana Mandatório claramente definido" \
  bash -c "grep -qi 'Fase 4' '$PR_SKILL' && grep -qi 'Gate de Validação Humana' '$PR_SKILL'"

check "Fase 5: Despacho & Rastreabilidade documentada com submit-review e create-issues" \
  bash -c "grep -qi 'Fase 5' '$PR_SKILL' && grep -q 'submit-review' '$PR_SKILL' && grep -q 'create-issues' '$PR_SKILL'"

# =============================================================================
# SEÇÃO 4: [HAPPY PATH] Gate Humano e Rastreabilidade de Subagentes
# =============================================================================
echo ""
echo "--- 4. [HAPPY PATH] Gate de Validação Humana e Papéis de Subagentes ---"

check "Gate Humano exige confirmação explícita antes de mutações remotas" \
  bash -c "grep -qi 'confirmação' '$PR_SKILL' && grep -qi 'desenvolvedor' '$PR_SKILL'"

check "Documenta bloqueio de submissão quando confirmação não for concedida" \
  bash -c "grep -E -i '(sem aprovação|sem confirmação|proibido publicar|não submete)' '$PR_SKILL'"

check "Documenta o papel do subagente gatekeeper na auditoria e fechamento" \
  bash -c "grep -qi 'gatekeeper' '$PR_SKILL'"

check "Documenta o papel do subagente planner ou orchestrator na triagem inicial" \
  bash -c "grep -E -i '(planner|orquestrador|orchestrator)' '$PR_SKILL'"

# =============================================================================
# SEÇÃO 5: [HAPPY PATH] Catálogo na GitHub Wiki
# =============================================================================
echo ""
echo "--- 5. [HAPPY PATH] Atualização na Wiki ---"

check "docs/Skills-Catalog.md cataloga a skill pr na tabela resumo" \
  bash -c "grep -q 'Skill-pr' '$SKILLS_CATALOG' && grep -q '/pr' '$SKILLS_CATALOG'"

check "docs/Skills-Catalog.md referencia o arquivo skills/pr/SKILL.md" \
  bash -c "grep -q 'skills/pr/SKILL.md' '$SKILLS_CATALOG'"

# =============================================================================
# SEÇÃO 6: [EDGE CASES & FAILURE MODES] Tolerância a Falhas e Circuit-Breakers
# =============================================================================
echo ""
echo "--- 6. [EDGE CASES & FAILURE MODES] Resiliência e Fail-Fast ---"

check "Fase 2 documenta interrupção imediata por Golden Rule (exit code 3 / circuit-breaker)" \
  bash -c "grep -E '(exit.*3|circuit-breaker|Golden Rule)' '$PR_SKILL' && grep -qi 'abort' '$PR_SKILL'"

check "Fase 4 documenta comportamento em caso de recusa humana ou cancelamento" \
  bash -c "grep -E -i '(rejei|cancela|ajust)' '$PR_SKILL'"

check "Fase 5 documenta que dry-run e simulação preservam estado sem mutações" \
  bash -c "grep -q '\-\-dry-run' '$PR_SKILL'"

check "Wiki Docs possui zero links quebrados após unificação para pr" \
  bash "$REPO_ROOT/tests/features/wiki/test_wiki_structure_and_links.sh"

# =============================================================================
# RESUMO FINAL DOS TESTES
# =============================================================================
echo ""
echo "========================================================================"
echo " RESUMO DO TESTE: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo "❌ TESTE FALHOU com $FAILED falha(s)!"
  exit 1
fi

echo "✅ TODOS OS TESTES PASSARAM COM SUCESSO!"
exit 0
