#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação: Manuais de Onboarding e Catálogos de Recursos (Issue #25)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GETTING_STARTED="$REPO_ROOT/docs/Getting-Started.md"
SUBAGENTS="$REPO_ROOT/docs/Subagents.md"
SKILLS_CATALOG="$REPO_ROOT/docs/Skills-Catalog.md"

FAILED=0

echo "========================================================================"
echo " [TEST] Manuais de Onboarding e Catálogos de Recursos (Issue #25)"
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
echo "--- 1. Existência Física dos Documentos ---"
check "docs/Getting-Started.md existe" test -f "$GETTING_STARTED"
check "docs/Subagents.md existe" test -f "$SUBAGENTS"
check "docs/Skills-Catalog.md existe" test -f "$SKILLS_CATALOG"

echo ""
echo "--- 2. Validação de Conteúdo: docs/Getting-Started.md ---"
check "Contém seção de Pré-requisitos (git, gh, agy)" \
  bash -c "grep -qi 'Pré-requisitos' '$GETTING_STARTED' && grep -q 'gh' '$GETTING_STARTED' && grep -q 'agy' '$GETTING_STARTED'"

check "Documenta configuração de plugins via plugins.json (.agents/plugins.json)" \
  bash -c "grep -q 'plugins.json' '$GETTING_STARTED' && grep -q 'entries' '$GETTING_STARTED' && grep -q '.agents/plugins.json' '$GETTING_STARTED'"

check "Documenta primeiro comando com Antigravity CLI (agy)" \
  bash -c "grep -qi 'primeiro comando' '$GETTING_STARTED' && grep -q 'agy' '$GETTING_STARTED'"

check "Documenta estrutura canônica (PROJECT_CONTEXT.md, tests/core/, tests/features/, .gitignore)" \
  bash -c "grep -q 'PROJECT_CONTEXT.md' '$GETTING_STARTED' && grep -q 'tests/core/' '$GETTING_STARTED' && grep -q 'tests/features/' '$GETTING_STARTED' && grep -q '.gitignore' '$GETTING_STARTED'"

check "Documenta ciclo AIDD com /plan-feature e /run-issue" \
  bash -c "grep -q '/plan-feature' '$GETTING_STARTED' && grep -q '/run-issue' '$GETTING_STARTED'"

echo ""
echo "--- 3. Validação de Conteúdo: docs/Subagents.md (7 Personas) ---"
PERSONAS=(
  "product-owner"
  "system-architect"
  "uiux-designer"
  "planner"
  "qa-engineer"
  "coder"
  "gatekeeper"
)

for persona in "${PERSONAS[@]}"; do
  check "Documenta persona '$persona' com arquivo de agente correspondente" \
    bash -c "grep -qi '$persona' '$SUBAGENTS' && test -f '$REPO_ROOT/agents/$persona/agent.md'"

  check "Persona '$persona' possui link relativo para agents/$persona/agent.md" \
    bash -c "grep -q 'agents/$persona/agent.md' '$SUBAGENTS'"
done

check "Documenta matriz de ferramentas e permissões dos subagentes" \
  bash -c "grep -qi 'Matriz Geral de Personas' '$SUBAGENTS' && grep -q 'read_file' '$SUBAGENTS' && grep -q 'run_command' '$SUBAGENTS'"

check "Documenta contratos de entrada e saída (I/O) das personas" \
  bash -c "grep -qi 'Contrato de Entrada' '$SUBAGENTS' && grep -qi 'Contrato de Saída' '$SUBAGENTS'"

check "Documenta regras de UI/UX (Value Contrast, Monocromático, WCAG)" \
  bash -c "grep -qi 'Value Contrast' '$SUBAGENTS' && grep -qi 'WCAG' '$SUBAGENTS'"

echo ""
echo "--- 4. Validação de Conteúdo: docs/Skills-Catalog.md (9 Skills) ---"
SKILLS=(
  "plan-feature"
  "issue-pipeline"
  "code-review"
  "test-runner"
  "git-workflow"
  "architecture-decision"
  "docker-dev"
  "game-dev-patterns"
  "publish-rule-issue"
)

check "Documenta princípio de Progressive Disclosure e Zero Token Waste" \
  bash -c "grep -qi 'Progressive Disclosure' '$SKILLS_CATALOG' && grep -qi 'Zero Token Waste' '$SKILLS_CATALOG'"

for skill in "${SKILLS[@]}"; do
  check "Documenta skill '$skill' com arquivo SKILL.md correspondente" \
    bash -c "grep -qi '$skill' '$SKILLS_CATALOG' && test -f '$REPO_ROOT/skills/$skill/SKILL.md'"

  check "Skill '$skill' possui link relativo para skills/$skill/SKILL.md" \
    bash -c "grep -q 'skills/$skill/SKILL.md' '$SKILLS_CATALOG'"

  check "Skill '$skill' possui especificação de gatilho de ativação" \
    bash -c "grep -qi 'Gatilho' '$SKILLS_CATALOG'"
done

echo ""
echo "--- 5. Integridade Referencial de Links Locais (Sem Links Quebrados) ---"
# Extrai links markdown da pasta docs/ e valida que arquivos locais existem
for doc in "$GETTING_STARTED" "$SUBAGENTS" "$SKILLS_CATALOG"; do
  doc_dir="$(dirname "$doc")"
  doc_name="$(basename "$doc")"
  
  # Captura links no formato [texto](caminho_relativo) excluindo âncoras # e urls http
  links=$(grep -oE '\]\([^)]+\)' "$doc" | sed 's/\](//;s/)//' | grep -v '^http' | grep -v '^#' || true)
  
  for link in $links; do
    # Remove eventuais âncoras internas no link (ex: ./Subagents.md#secao)
    clean_target="${link%%#*}"
    if [ -n "$clean_target" ]; then
      resolved="$doc_dir/$clean_target"
      check "Link em $doc_name para '$clean_target' resolve arquivo real" test -e "$resolved"
    fi
  done
done

echo ""
if [ "$FAILED" -eq 0 ]; then
  echo "========================================================================"
  echo " [SUCCESS] Todos os critérios de aceite da Issue #25 foram atendidos!"
  echo "========================================================================"
  exit 0
else
  echo "========================================================================"
  echo " [ERROR] Falha na validação de critérios de aceite da Issue #25."
  echo "========================================================================"
  exit 1
fi
