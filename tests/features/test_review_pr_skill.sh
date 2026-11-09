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
REVIEW_PR_SKILL="$REPO_ROOT/skills/review-pr/SKILL.md"
CODE_REVIEW_SKILL="$REPO_ROOT/skills/code-review/SKILL.md"
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
echo " [TEST] Issue #54: Orquestrador da Skill /review-pr com Gate Humano"
echo "========================================================================"

# =============================================================================
# SEÇÃO 1: [HAPPY PATH] Estrutura Canônica de skills/review-pr/SKILL.md
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Estrutura e Metadados da Skill review-pr ---"

check "skills/review-pr/SKILL.md existe no repositório" test -f "$REVIEW_PR_SKILL"
check "skills/review-pr/SKILL.md não está vazio" test -s "$REVIEW_PR_SKILL"

# Validação do Frontmatter YAML
check "Frontmatter possui delimitador de abertura '---'" \
  bash -c "head -n 1 '$REVIEW_PR_SKILL' | grep -q '^---'"

check "Frontmatter declara 'name: review-pr'" \
  bash -c "grep -E '^name:\s*review-pr\b' '$REVIEW_PR_SKILL'"

check "Frontmatter declara campo 'description:'" \
  bash -c "grep -E '^description:' '$REVIEW_PR_SKILL'"

# =============================================================================
# SEÇÃO 2: [HAPPY PATH] Protocolo de Invocação e Parâmetros
# =============================================================================
echo ""
echo "--- 2. [HAPPY PATH] Protocolo de Invocação (/review-pr) ---"

check "Documenta sintaxe de invocação '/review-pr <#PR | URL>'" \
  bash -c "grep -E '/review-pr <#PR \| URL>' '$REVIEW_PR_SKILL'"

check "Documenta suporte a identificador numérico (#12 ou 12)" \
  bash -c "grep -E '/review-pr #?[0-9]+' '$REVIEW_PR_SKILL'"

check "Documenta suporte a URL completa de Pull Request" \
  bash -c "grep -E 'https://github\.com/[^ ]+/pull/[0-9]+' '$REVIEW_PR_SKILL'"

# =============================================================================
# SEÇÃO 3: [HAPPY PATH] Máquina de Estados de 5 Fases
# =============================================================================
echo ""
echo "--- 3. [HAPPY PATH] Máquina de Estados de 5 Fases e Subcomandos ---"

check "Fase 1: Inspeção & Diff documentada com fetch-diff" \
  bash -c "grep -qi 'Fase 1' '$REVIEW_PR_SKILL' && grep -q 'fetch-diff' '$REVIEW_PR_SKILL'"

check "Fase 2: Auditoria de Integridade & Golden Rule documentada com audit-integrity" \
  bash -c "grep -qi 'Fase 2' '$REVIEW_PR_SKILL' && grep -q 'audit-integrity' '$REVIEW_PR_SKILL'"

check "Fase 3: Revisão Heurística & Severidade documentada em 4 dimensões" \
  bash -c "grep -qi 'Fase 3' '$REVIEW_PR_SKILL' && grep -qi 'Severidade' '$REVIEW_PR_SKILL'"

check "Fase 3 categoriza severidades: Crítico, Importante e Sugestão" \
  bash -c "grep -q 'Crítico' '$REVIEW_PR_SKILL' && grep -q 'Importante' '$REVIEW_PR_SKILL' && grep -q 'Sugestão' '$REVIEW_PR_SKILL'"

check "Fase 4: Gate de Validação Humana Mandatório claramente definido" \
  bash -c "grep -qi 'Fase 4' '$REVIEW_PR_SKILL' && grep -qi 'Gate de Validação Humana' '$REVIEW_PR_SKILL'"

check "Fase 5: Despacho & Rastreabilidade documentada com submit-review e create-issues" \
  bash -c "grep -qi 'Fase 5' '$REVIEW_PR_SKILL' && grep -q 'submit-review' '$REVIEW_PR_SKILL' && grep -q 'create-issues' '$REVIEW_PR_SKILL'"

# =============================================================================
# SEÇÃO 4: [HAPPY PATH] Gate Humano e Rastreabilidade de Subagentes
# =============================================================================
echo ""
echo "--- 4. [HAPPY PATH] Gate de Validação Humana e Papéis de Subagentes ---"

check "Gate Humano exige confirmação explícita antes de mutações remotas" \
  bash -c "grep -qi 'confirmação' '$REVIEW_PR_SKILL' && grep -qi 'desenvolvedor' '$REVIEW_PR_SKILL'"

check "Documenta bloqueio de submissão quando confirmação não for concedida" \
  bash -c "grep -E -i '(sem aprovação|sem confirmação|proibido publicar|não submete)' '$REVIEW_PR_SKILL'"

check "Documenta o papel do subagente gatekeeper na auditoria e fechamento" \
  bash -c "grep -qi 'gatekeeper' '$REVIEW_PR_SKILL'"

check "Documenta o papel do subagente planner ou orchestrator na triagem inicial" \
  bash -c "grep -E -i '(planner|orquestrador|orchestrator)' '$REVIEW_PR_SKILL'"

# =============================================================================
# SEÇÃO 5: [HAPPY PATH] Links Cruzados e Catálogo na GitHub Wiki
# =============================================================================
echo ""
echo "--- 5. [HAPPY PATH] Links Cruzados e Atualização na Wiki ---"

check "skills/code-review/SKILL.md referencia a esteira /review-pr" \
  bash -c "grep -q '/review-pr' '$CODE_REVIEW_SKILL'"

check "skills/code-review/SKILL.md contém link cruzado para review-pr" \
  bash -c "grep -E '(skills/review-pr|review-pr)' '$CODE_REVIEW_SKILL'"

check "docs/Skills-Catalog.md cataloga a skill review-pr na tabela resumo" \
  bash -c "grep -q 'review-pr' '$SKILLS_CATALOG' && grep -q '/review-pr' '$SKILLS_CATALOG'"

check "docs/Skills-Catalog.md possui seção detalhada para a skill review-pr" \
  bash -c "grep -E -i '### [0-9]+\.[0-9]+\..*review-pr' '$SKILLS_CATALOG'"

check "docs/Skills-Catalog.md referencia o arquivo skills/review-pr/SKILL.md" \
  bash -c "grep -q 'skills/review-pr/SKILL.md' '$SKILLS_CATALOG'"

# =============================================================================
# SEÇÃO 6: [EDGE CASES & FAILURE MODES] Tolerância a Falhas e Circuit-Breakers
# =============================================================================
echo ""
echo "--- 6. [EDGE CASES & FAILURE MODES] Resiliência e Fail-Fast ---"

check "Fase 2 documenta interrupção imediata por Golden Rule (exit code 3 / circuit-breaker)" \
  bash -c "grep -E '(exit.*3|circuit-breaker|Golden Rule)' '$REVIEW_PR_SKILL' && grep -qi 'abort' '$REVIEW_PR_SKILL'"

check "Fase 4 documenta comportamento em caso de recusa humana ou cancelamento" \
  bash -c "grep -E -i '(rejei|cancela|ajust)' '$REVIEW_PR_SKILL'"

check "Fase 5 documenta que dry-run e simulação preservam estado sem mutações" \
  bash -c "grep -q '\-\-dry-run' '$REVIEW_PR_SKILL'"

check "Wiki Docs possui zero links quebrados após adição de review-pr" \
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
