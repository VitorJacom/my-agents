#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação: UI/UX Design Skill com Progressive Disclosure (Issue #17)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills/ui-ux-design"
SKILL_MD="$SKILL_DIR/SKILL.md"
MODULES_DIR="$SKILL_DIR/modules"
REFERENCES_DIR="$SKILL_DIR/references"
SCRIPTS_DIR="$SKILL_DIR/scripts"
ASSISTANT_PY="$SCRIPTS_DIR/skill_assistant.py"

FAILED=0

echo "========================================================================"
echo " [TEST] UI/UX Design Skill com Progressive Disclosure (Issue #17)"
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
echo "--- 1. Existência e Integridade do Hub SKILL.md ---"
check "Diretório skills/ui-ux-design existe" test -d "$SKILL_DIR"
check "Hub skills/ui-ux-design/SKILL.md existe" test -f "$SKILL_MD"
check "Frontmatter name é ui-ux-design" grep -q "^name: ui-ux-design" "$SKILL_MD"
check "Frontmatter possui description" grep -q "^description:" "$SKILL_MD"

echo ""
echo "--- 2. Existência dos 7 Módulos de Domínio ---"
check "Módulo 01 (01-motion-and-physics.md) existe" test -f "$MODULES_DIR/01-motion-and-physics.md"
check "Módulo 02 (02-anti-slop-refactoring.md) existe" test -f "$MODULES_DIR/02-anti-slop-refactoring.md"
check "Módulo 03 (03-mobile-and-navigation.md) existe" test -f "$MODULES_DIR/03-mobile-and-navigation.md"
check "Módulo 04 (04-ecommerce-conversion.md) existe" test -f "$MODULES_DIR/04-ecommerce-conversion.md"
check "Módulo 05 (05-pricing-and-paywalls.md) existe" test -f "$MODULES_DIR/05-pricing-and-paywalls.md"
check "Módulo 06 (06-landing-pages-hero.md) existe" test -f "$MODULES_DIR/06-landing-pages-hero.md"
check "Módulo 07 (07-adaptive-decision-ux.md) existe" test -f "$MODULES_DIR/07-adaptive-decision-ux.md"

echo ""
echo "--- 3. Existência das 13 Referências Técnicas Profundas ---"
check "Referência: ai-slop-purge-and-refinement-cycle.md" test -f "$REFERENCES_DIR/ai-slop-purge-and-refinement-cycle.md"
check "Referência: animation-recipes.md" test -f "$REFERENCES_DIR/animation-recipes.md"
check "Referência: animation-vocabulary.md" test -f "$REFERENCES_DIR/animation-vocabulary.md"
check "Referência: apple-design-fluid-interfaces.md" test -f "$REFERENCES_DIR/apple-design-fluid-interfaces.md"
check "Referência: building-animations-philosophy.md" test -f "$REFERENCES_DIR/building-animations-philosophy.md"
check "Referência: distinct-frontend-anti-templates.md" test -f "$REFERENCES_DIR/distinct-frontend-anti-templates.md"
check "Referência: ecommerce-mobile-conversion-ux.md" test -f "$REFERENCES_DIR/ecommerce-mobile-conversion-ux.md"
check "Referência: full-ruleset-10-categories.md" test -f "$REFERENCES_DIR/full-ruleset-10-categories.md"
check "Referência: landing-page-narrative-and-hero-architecture.md" test -f "$REFERENCES_DIR/landing-page-narrative-and-hero-architecture.md"
check "Referência: mobile-navigation-bottom-bar-ux.md" test -f "$REFERENCES_DIR/mobile-navigation-bottom-bar-ux.md"
check "Referência: pricing-paywalls-booking-ux.md" test -f "$REFERENCES_DIR/pricing-paywalls-booking-ux.md"
check "Referência: professional-ui-and-pre-delivery-checklist.md" test -f "$REFERENCES_DIR/professional-ui-and-pre-delivery-checklist.md"
check "Referência: refactoring-ai-ui-heuristics.md" test -f "$REFERENCES_DIR/refactoring-ai-ui-heuristics.md"

echo ""
echo "--- 4. Utilitário CLI e Execução com python3 ---"
check "Script skill_assistant.py existe" test -f "$ASSISTANT_PY"
check "Execução skill_assistant.py --help" python3 "$ASSISTANT_PY" --help
check "Execução skill_assistant.py list" python3 "$ASSISTANT_PY" list
check "Execução skill_assistant.py formulas" python3 "$ASSISTANT_PY" formulas
check "Execução skill_assistant.py recipe button" python3 "$ASSISTANT_PY" recipe button
check "Execução skill_assistant.py checklist --type pre-delivery" python3 "$ASSISTANT_PY" checklist --type pre-delivery

echo ""
echo "--- 5. Fail-Fast Mandatório em Erros de CLI (AGENTS.md Seção 1.4) ---"
check "Falha controlada (exit code 1) ao solicitar módulo inválido" \
  bash -c "! python3 '$ASSISTANT_PY' module 99 2>/dev/null"
check "Emite erro em stderr ao solicitar módulo inválido" \
  bash -c "python3 '$ASSISTANT_PY' module 99 2>&1 >/dev/null | grep -qi 'Erro:'"
check "Falha controlada (exit code 1) ao auditar arquivo inexistente" \
  bash -c "! python3 '$ASSISTANT_PY' audit /tmp/inexistente_$(date +%s).ts 2>/dev/null"
check "Emite erro em stderr ao auditar arquivo inexistente" \
  bash -c "python3 '$ASSISTANT_PY' audit /tmp/inexistente_$(date +%s).ts 2>&1 >/dev/null | grep -qi 'Erro:'"
check "Falha controlada (exit code 1) ao solicitar receita inexistente" \
  bash -c "! python3 '$ASSISTANT_PY' recipe receita_inexistente 2>/dev/null"

echo ""
echo "--- 6. Higienização e Desacoplamento de Paths e Nomes Externos ---"
check "Nenhuma menção residual a znapzap (case-insensitive) em toda a pasta da skill" \
  bash -c "! grep -ri 'znapzap' '$SKILL_DIR'"

echo ""
echo "========================================================================"
if [ "$FAILED" -eq 0 ]; then
  echo " [SUCCESS] Todos os testes da skill ui-ux-design passaram com sucesso!"
  exit 0
else
  echo " [FAILURE] Um ou mais testes falharam."
  exit 1
fi
