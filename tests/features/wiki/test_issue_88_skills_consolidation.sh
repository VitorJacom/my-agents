#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): Consolidação de Skills e Deprecação (Issue #88)
#
# Happy Path:
#   - skills/test-runner/ e skills/architecture-decision/ removidos
#   - docs/skills/Skill-test-runner.md e Skill-architecture-decision.md removidos
#   - agents/qa-engineer/agent.md absorve fluxo de test-runner
#   - agents/system-architect/agent.md absorve convenção ADR (Michael Nygard)
#   - skills/docker-dev/SKILL.md e docs/skills/Skill-docker-dev.md marcados DEPRECATED
#   - docs/Skills-Catalog.md e docs/_Sidebar.md refletem 8 skills
#
# Edge Cases / Failure Modes:
#   - Ausência de links quebrados ou referências órfãs a Skill-test-runner,
#     Skill-architecture-decision, /test-runner ou /architecture-decision
#   - Ausência de referências defasadas a "10 skills" ou "10/10"
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOCS_DIR="$REPO_ROOT/docs"
SKILLS_CATALOG="$DOCS_DIR/Skills-Catalog.md"
SIDEBAR="$DOCS_DIR/_Sidebar.md"
QA_AGENT="$REPO_ROOT/agents/qa-engineer/agent.md"
ARCH_AGENT="$REPO_ROOT/agents/system-architect/agent.md"
DOCKER_SKILL="$REPO_ROOT/skills/docker-dev/SKILL.md"
DOCKER_WIKI="$DOCS_DIR/skills/Skill-docker-dev.md"
PROJECT_CONTEXT="$REPO_ROOT/PROJECT_CONTEXT.md"

PASSED=0
FAILED=0

echo "========================================================================"
echo " [TEST] Issue #88: Consolidação de Skills em Agentes e Deprecação"
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

echo ""
echo "--- 1. Happy Path: Remoção Física das Skills Absorvidas e Páginas Wiki ---"
check "Diretório skills/test-runner/ foi removido" \
  bash -c "! test -d '$REPO_ROOT/skills/test-runner'"
check "Diretório skills/architecture-decision/ foi removido" \
  bash -c "! test -d '$REPO_ROOT/skills/architecture-decision'"
check "Página docs/skills/Skill-test-runner.md foi removida" \
  bash -c "! test -f '$DOCS_DIR/skills/Skill-test-runner.md'"
check "Página docs/skills/Skill-architecture-decision.md foi removida" \
  bash -c "! test -f '$DOCS_DIR/skills/Skill-architecture-decision.md'"

echo ""
echo "--- 2. Happy Path: Absorção em agents/qa-engineer/agent.md ---"
check "qa-engineer contém seção Fluxo Cirúrgico de Execução & Diagnóstico" \
  grep -q "Fluxo Cirúrgico de Execução & Diagnóstico" "$QA_AGENT"
check "qa-engineer documenta detecção de ecossistema (vitest/pytest/go test)" \
  bash -c "grep -qi 'vitest' '$QA_AGENT' && grep -qi 'pytest' '$QA_AGENT' && grep -qi 'go test' '$QA_AGENT'"
check "qa-engineer documenta validação em Clean Room (sandbox/)" \
  grep -q "sandbox/" "$QA_AGENT"

echo ""
echo "--- 3. Happy Path: Absorção em agents/system-architect/agent.md ---"
check "system-architect contém seção Padrão de Architecture Decision Records (ADR)" \
  grep -q "Padrão de Architecture Decision Records (ADR)" "$ARCH_AGENT"
check "system-architect documenta convenção docs/adr/" \
  grep -q "docs/adr/" "$ARCH_AGENT"
check "system-architect documenta template Michael Nygard (Alternativas Consideradas, Consequências)" \
  bash -c "grep -q 'Alternativas Consideradas' '$ARCH_AGENT' && grep -q 'Consequências' '$ARCH_AGENT'"

echo ""
echo "--- 4. Happy Path: Deprecação Explícita de docker-dev ---"
check "skills/docker-dev/SKILL.md contém deprecated: true no frontmatter" \
  grep -q "deprecated: true" "$DOCKER_SKILL"
check "skills/docker-dev/SKILL.md contém marcação DEPRECATED" \
  grep -q "DEPRECATED" "$DOCKER_SKILL"
check "docs/skills/Skill-docker-dev.md contém marcação DEPRECATED" \
  grep -q "DEPRECATED" "$DOCKER_WIKI"

echo ""
echo "--- 5. Happy Path: Catálogos Atualizados para 8 Skills ---"
check "docs/Skills-Catalog.md exibe contagem de 8 skills" \
  grep -qE '\b8\b.*skills|8 skills' "$SKILLS_CATALOG"
check "docs/_Sidebar.md exibe contagem de 8 skills" \
  grep -qE '\(8\)|8 skills' "$SIDEBAR"
check "docs/Skills-Catalog.md marca docker-dev como DEPRECATED" \
  bash -c "grep -qi 'docker-dev' '$SKILLS_CATALOG' && grep -q 'DEPRECATED' '$SKILLS_CATALOG'"

echo ""
echo "--- 6. Edge Cases / Failure Modes: Links Quebrados e Referências Órfãs ---"
check "Nenhum arquivo em docs/ referencia Skill-test-runner ou Skill-architecture-decision" \
  bash -c "! grep -rnE 'Skill-(test-runner|architecture-decision)' '$DOCS_DIR'"
check "Nenhum arquivo em docs/ ou PROJECT_CONTEXT.md referencia /test-runner ou /architecture-decision" \
  bash -c "! grep -rnE '/(test-runner|architecture-decision)' '$DOCS_DIR' '$PROJECT_CONTEXT'"
check "docs/Skills-Catalog.md não contém referências defasadas a '10 skills' ou '10/10'" \
  bash -c "! grep -qE '10 skills|10/10' '$SKILLS_CATALOG'"
check "PROJECT_CONTEXT.md não contém referência defasada a '10 skills'" \
  bash -c "! grep -q '10 skills' '$PROJECT_CONTEXT'"

echo ""
echo "========================================================================"
echo " RESUMO DO TESTE: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo "❌ TESTE FALHOU (RED) com $FAILED falha(s)!"
  exit 1
fi

echo "✅ TODOS OS TESTES PASSARAM COM SUCESSO!"
exit 0
