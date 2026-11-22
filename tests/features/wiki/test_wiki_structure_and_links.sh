#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): Wiki Structure, Integrity and Sync Pipeline (Issue #27)
#
# Cenário: Validação de links e estrutura da Wiki
# Dado que a suíte test_wiki_structure_and_links.sh é executada
# Quando avaliar os arquivos de docs/
# Então todos os 9 arquivos obrigatórios devem existir
# E nenhum link relativo interno markdown deve apontar para arquivo inexistente
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOCS_DIR="$REPO_ROOT/docs"
WORKFLOW_FILE="$REPO_ROOT/.github/workflows/wiki-sync.yml"
PROJECT_CONTEXT="$REPO_ROOT/PROJECT_CONTEXT.md"

PASSED=0
FAILED=0

echo "========================================================================"
echo " [TEST] Issue #27: Modernize Wiki Sync Pipeline & Integrity Test Suite"
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
# SEÇÃO 1: PRESENÇA DOS 9 ARQUIVOS OBRIGATÓRIOS EM docs/
# =============================================================================
echo ""
echo "--- 1. Existência e Integridade dos 9 Arquivos Canônicos da Wiki ---"

MANDATORY_DOCS=(
  "Home.md"
  "_Sidebar.md"
  "_Footer.md"
  "Getting-Started.md"
  "Subagents.md"
  "Skills-Catalog.md"
  "Scripts-Catalog.md"
  "Tests-Catalog.md"
  "AIDD-Manifesto.md"
  "System-Architecture.md"
  "Troubleshooting.md"
  "ARCHITECTURE.md"
)

AGENT_DOCS=(
  "agents/Agent-product-owner.md"
  "agents/Agent-system-architect.md"
  "agents/Agent-uiux-designer.md"
  "agents/Agent-planner.md"
  "agents/Agent-qa-engineer.md"
  "agents/Agent-coder.md"
  "agents/Agent-gatekeeper.md"
)

SKILL_DOCS=(
  "skills/Skill-plan-feature.md"
  "skills/Skill-issue-pipeline.md"
  "skills/Skill-review-pr.md"
  "skills/Skill-code-review.md"
  "skills/Skill-test-runner.md"
  "skills/Skill-git-workflow.md"
  "skills/Skill-architecture-decision.md"
  "skills/Skill-docker-dev.md"
  "skills/Skill-game-dev-patterns.md"
  "skills/Skill-publish-rule-issue.md"
  "skills/Skill-ui-ux-design.md"
)

SCRIPT_DOCS=(
  "scripts/Script-hooks.md"
  "scripts/Script-pipeline.md"
  "scripts/Script-pr-reviewer.md"
  "scripts/Script-statusline.md"
  "scripts/Script-migrations.md"
)

TEST_DOCS=(
  "tests/Test-core.md"
  "tests/Test-governance.md"
  "tests/Test-pipeline.md"
  "tests/Test-wiki.md"
  "tests/Test-ui-ux.md"
  "tests/Test-pr-review.md"
  "tests/Test-statusline.md"
)

ALL_WIKI_DOCS=("${MANDATORY_DOCS[@]}" "${AGENT_DOCS[@]}" "${SKILL_DOCS[@]}" "${SCRIPT_DOCS[@]}" "${TEST_DOCS[@]}")

for doc in "${ALL_WIKI_DOCS[@]}"; do
  doc_path="$DOCS_DIR/$doc"
  check "Arquivo obrigatório docs/$doc existe" test -f "$doc_path"
  check "Arquivo obrigatório docs/$doc não está vazio" test -s "$doc_path"
done

# =============================================================================
# SEÇÃO 2: INTEGRIDADE DE LINKS RELATIVOS INTERNOS (ZERO BROKEN LINKS)
# =============================================================================
echo ""
echo "--- 2. Validação de Links Relativos Internos Markdown ---"

# Verifica se há links vazios '[]()'
for doc in "${ALL_WIKI_DOCS[@]}"; do
  doc_path="$DOCS_DIR/$doc"
  check "docs/$doc não possui links vazios '[]()'" bash -c "! grep -q '\[\]()' '$doc_path'"
done

# Varre todos os arquivos markdown em docs/ e valida referências relativas
echo ""
echo "--- 3. Verificação de Alvos dos Links Relativos e Wiki ---"
BROKEN_LINKS=0

for doc in "${ALL_WIKI_DOCS[@]}"; do
  doc_path="$DOCS_DIR/$doc"
  doc_name="$doc"
  
  # Extrai alvos de links [label](target), filtrando protocolos web, âncoras puras e URIs file:
  targets=$(grep -oE '\]\([^)]+\)' "$doc_path" | sed 's/\](//;s/)//' | grep -vE '^(https?|mailto|file):' | grep -v '^#' || true)
  
  for target in $targets; do
    # Remove eventuais âncoras internas no link (ex: ./Subagents.md#secao ou Page#secao)
    clean_target="${target%%#*}"
    [ -z "$clean_target" ] && continue
    
    # Resoluções possíveis:
    # 1. Relativo ao docs/ (ex: ./Subagents.md, Getting-Started.md)
    # 2. Convenção GitHub Wiki sem extensão (ex: Getting-Started -> Getting-Started.md, Skill-plan-feature -> skills/Skill-plan-feature.md)
    # 3. Relativo à raiz do repositório (ex: ../skills/... ou .github/...)
    # 4. Subpastas canônicas da Wiki (docs/skills/, docs/mockups/)
    resolved=0
    base_name="$(basename "$clean_target")"
    if [ -e "$DOCS_DIR/$clean_target" ] || [ -e "$DOCS_DIR/$clean_target.md" ]; then
      resolved=1
    elif [ -e "$REPO_ROOT/$clean_target" ] || [ -e "$REPO_ROOT/$clean_target.md" ]; then
      resolved=1
    elif [ -e "$DOCS_DIR/$base_name" ] || [ -e "$DOCS_DIR/$base_name.md" ]; then
      resolved=1
    elif [ -e "$DOCS_DIR/agents/$base_name" ] || [ -e "$DOCS_DIR/agents/$base_name.md" ]; then
      resolved=1
    elif [ -e "$DOCS_DIR/skills/$base_name" ] || [ -e "$DOCS_DIR/skills/$base_name.md" ]; then
      resolved=1
    elif [ -e "$DOCS_DIR/scripts/$base_name" ] || [ -e "$DOCS_DIR/scripts/$base_name.md" ]; then
      resolved=1
    elif [ -e "$DOCS_DIR/tests/$base_name" ] || [ -e "$DOCS_DIR/tests/$base_name.md" ]; then
      resolved=1
    elif [ -e "$DOCS_DIR/mockups/$base_name" ] || [ -e "$DOCS_DIR/mockups/$base_name.md" ]; then
      resolved=1
    fi

    if [ "$resolved" -eq 1 ]; then
      echo "  [PASS] Link em $doc_name -> '$clean_target' [OK]"
      PASSED=$((PASSED + 1))
    else
      echo "  [FAIL] Link quebrado em $doc_name -> '$clean_target' (alvo inexistente)"
      FAILED=$((FAILED + 1))
      BROKEN_LINKS=$((BROKEN_LINKS + 1))
    fi
  done
done

# =============================================================================
# SEÇÃO 4: WORKFLOW DE SINCRONIZAÇÃO (.github/workflows/wiki-sync.yml)
# =============================================================================
echo ""
echo "--- 4. Validação do Workflow .github/workflows/wiki-sync.yml ---"
check "Workflow wiki-sync.yml existe" test -f "$WORKFLOW_FILE"

# Validação estrita: eliminação da sobrescrita legada de ARCHITECTURE.md para Home.md
check "NÃO contém sobrescrita legada 'cp.*ARCHITECTURE\.md.*Home\.md'" \
  bash -c "! grep -E -q 'cp.*ARCHITECTURE\.md.*Home\.md' '$WORKFLOW_FILE'"

check "NÃO contém atribuição de ARCHITECTURE.md para wiki-temp/Home.md" \
  bash -c "! grep -q 'wiki-temp/ARCHITECTURE.md wiki-temp/Home.md' '$WORKFLOW_FILE'"

# Validação do espelhamento fiel de docs/
check "Contém comando de sincronização/espelhamento de docs/ para wiki-temp" \
  bash -c "grep -E -q '(rsync.*docs/|cp -r docs/\*)' '$WORKFLOW_FILE'"

check "Workflow executa com fail-fast 'set -euo pipefail'" \
  grep -q "set -euo pipefail" "$WORKFLOW_FILE"

check "Workflow reporta erros com anotações '::error::'" \
  grep -q "::error::" "$WORKFLOW_FILE"

# =============================================================================
# SEÇÃO 5: CONFORMIDADE DO PROJECT_CONTEXT.md
# =============================================================================
echo ""
echo "--- 5. Validação da Seção Canônica em PROJECT_CONTEXT.md ---"
check "PROJECT_CONTEXT.md existe" test -f "$PROJECT_CONTEXT"
check "PROJECT_CONTEXT.md referencia wiki-sync.yml" grep -q "wiki-sync.yml" "$PROJECT_CONTEXT"
check "PROJECT_CONTEXT.md referencia suíte test_wiki_structure_and_links.sh" \
  grep -q "test_wiki_structure_and_links.sh" "$PROJECT_CONTEXT"
check "PROJECT_CONTEXT.md referencia Home.md da Wiki" grep -q "Home.md" "$PROJECT_CONTEXT"
check "PROJECT_CONTEXT.md referencia _Sidebar.md da Wiki" grep -q "_Sidebar.md" "$PROJECT_CONTEXT"
check "PROJECT_CONTEXT.md referencia _Footer.md da Wiki" grep -q "_Footer.md" "$PROJECT_CONTEXT"

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
