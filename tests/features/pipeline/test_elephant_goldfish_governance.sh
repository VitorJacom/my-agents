#!/usr/bin/env bash
# =============================================================================
# tests/features/pipeline/test_elephant_goldfish_governance.sh
# =============================================================================
# Suíte de Testes de Aceitação TDD para a Issue #61:
# Integração do Modelo Elephant-Goldfish no Pipeline AIDD
#
# Valida a governança, contratos estáticos e invariantes comportamentais:
# - The Elephant (Product Owner): Contexto cumulativo, postura socrática e living specs.
# - The Goldfish (Gatekeeper Modo 1): Auditoria fria, stateless, anti-premissas implícitas.
# - Skill plan-feature: Máquina de estados com ciclo Elephant-Goldfish e auto-healing (<= 2 iterações).
# - Registro Arquitetural: Decisão Técnica 0014 em docs/ARCHITECTURE.md e catálogos da Wiki.
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PO_AGENT="$REPO_ROOT/agents/product-owner/agent.md"
GATEKEEPER_AGENT="$REPO_ROOT/agents/gatekeeper/agent.md"
PLAN_FEATURE_SKILL="$REPO_ROOT/skills/plan-feature/SKILL.md"
ARCHITECTURE_DOC="$REPO_ROOT/docs/ARCHITECTURE.md"
SUBAGENTS_DOC="$REPO_ROOT/docs/Subagents.md"
SKILLS_CATALOG_DOC="$REPO_ROOT/docs/Skills-Catalog.md"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #61: Elephant-Goldfish Model & Specification Audit Governance"
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
# SEÇÃO 1: HAPPY PATH - CONTRATOS DO PRODUCT OWNER (THE ELEPHANT)
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Persona e Contrato do Product Owner (The Elephant) ---"
check "agents/product-owner/agent.md existe" test -f "$PO_AGENT"
check "PO define formalmente a persona 'The Elephant' e contexto de longo alcance" \
  grep -E -q -i "elephant" "$PO_AGENT"
check "PO estabelece a postura socrática de engenharia de requisitos" \
  grep -E -q -i "socrátic" "$PO_AGENT"
check "PO formaliza retenção de contexto cumulativo sem escrita prematura de código" \
  grep -E -q -i "(contexto cumulativo|long[- ]horizon|longo alcance)" "$PO_AGENT"
check "PO exige especificações autocontidas que passem no teste do olhar frio" \
  grep -E -q -i "(olhar frio|autocontid|sem assumir conhecimento)" "$PO_AGENT"
check "docs/Subagents.md formaliza o papel do product-owner como 'The Elephant'" \
  grep -E -q -i "elephant" "$SUBAGENTS_DOC"

# =============================================================================
# SEÇÃO 2: HAPPY PATH - AUDITORIA DE ESPECIFICAÇÃO DO GATEKEEPER (THE GOLDFISH)
# =============================================================================
echo ""
echo "--- 2. [HAPPY PATH] Persona e Contrato do Gatekeeper (The Goldfish Reviewer) ---"
check "agents/gatekeeper/agent.md existe" test -f "$GATEKEEPER_AGENT"
check "Gatekeeper define 'Modo 1: Auditoria de Especificação' ou 'Goldfish Reviewer'" \
  grep -E -q -i "(modo 1|goldfish reviewer|auditoria de especificação)" "$GATEKEEPER_AGENT"
check "Gatekeeper formaliza a postura de auditoria fria e stateless ('Cold Audit')" \
  grep -E -q -i "(stateless|cold audit|olhar frio)" "$GATEKEEPER_AGENT"
check "Gatekeeper estabelece auditoria explícita contra premissas ocultas e ambiguidades" \
  grep -E -q -i "premissas? (implícitas?|ocultas?|não testadas?)" "$GATEKEEPER_AGENT"
check "docs/Subagents.md formaliza o papel do gatekeeper como 'The Goldfish'" \
  grep -E -q -i "goldfish" "$SUBAGENTS_DOC"

# =============================================================================
# SEÇÃO 3: HAPPY PATH - PIPELINE /plan-feature E LIVING ARCHITECTURE
# =============================================================================
echo ""
echo "--- 3. [HAPPY PATH] Máquina de Estados e Decisão Técnica 0014 ---"
check "skills/plan-feature/SKILL.md existe" test -f "$PLAN_FEATURE_SKILL"
check "skills/plan-feature/SKILL.md incorpora o ciclo Elephant-Goldfish na máquina de estados" \
  grep -E -q -i "elephant.*goldfish|goldfish.*elephant" "$PLAN_FEATURE_SKILL"
check "skills/plan-feature/SKILL.md documenta o loop de auto-healing de especificação" \
  grep -E -q -i "(auto-healing|loop de revisão)" "$PLAN_FEATURE_SKILL"
check "docs/Skills-Catalog.md cataloga a esteira /plan-feature com ciclo Elephant-Goldfish" \
  grep -E -q -i "(elephant.*goldfish|goldfish)" "$SKILLS_CATALOG_DOC"
check "docs/ARCHITECTURE.md registra a Decisão Técnica 0014 (Elephant-Goldfish Model)" \
  grep -E -q -i "decisão 0014|decisão técnica 0014" "$ARCHITECTURE_DOC"
check "Decisão 0014 em docs/ARCHITECTURE.md explicita motivação contra context collapse / slop" \
  grep -E -q -i "(context collapse|conversational slop|degradação de contexto|viés de confirmação)" "$ARCHITECTURE_DOC"

# =============================================================================
# SEÇÃO 4: EDGE CASES & FAILURE MODES - TRAVAS DE SEGURANÇA E CONFINAMENTO
# =============================================================================
echo ""
echo "--- 4. [EDGE CASES] Confinamento de Permissões e Critérios de Bloqueio ---"

# EC-01: Product Owner com permissões estritamente confinadas (sem write_file, edit_file, run_command)
check_po_permissions() {
  python3 -c "
import sys, yaml
with open('$PO_AGENT', 'r', encoding='utf-8') as f:
    content = f.read()
parts = content.split('---')
if len(parts) < 3:
    sys.exit(1)
meta = yaml.safe_load(parts[1])
tools = meta.get('tools', [])
forbidden = {'write_file', 'edit_file', 'run_command'}
if any(t in forbidden for t in tools):
    sys.exit(1)
if 'read_file' not in tools:
    sys.exit(1)
sys.exit(0)
"
}
check "EC-01: Product Owner tem tools restrito a leitura/pesquisa (sem write_file, edit_file, run_command)" check_po_permissions

# EC-02: Gatekeeper Modo 1 bloqueia formalmente premissas implícitas não testadas
check "EC-02: Gatekeeper Modo 1 bloqueia formalmente premissas implícitas não testadas" \
  grep -E -q -i "(bloqueia|rejeita|circuit[- ]breaker).*(premissas? (implícitas?|não testadas?|ocultas?))|(premissas? (implícitas?|não testadas?|ocultas?)).*(bloqueia|rejeita|circuit[- ]breaker)" "$GATEKEEPER_AGENT"

# EC-03: Gatekeeper Modo 1 bloqueia formalmente quebra de atomicidade (> 3 passos)
check "EC-03: Gatekeeper Modo 1 bloqueia formalmente especificações que excedam 3 passos (> 3 passos)" \
  grep -E -q -i "(bloqueia|rejeita|circuit[- ]breaker).*(> ?3 passos|mais de 3 passos)|(> ?3 passos|mais de 3 passos).*(bloqueia|rejeita|circuit[- ]breaker)" "$GATEKEEPER_AGENT"

# EC-04: Teto máximo determinístico no loop de auto-healing (<= 2 iterações)
check "EC-04: Skill plan-feature define teto determinístico de 2 iterações no loop de auto-healing" \
  grep -E -q -i "(teto|máximo|limite).*(2|duas) iterações|(2|duas) iterações.*(teto|máximo|limite)" "$PLAN_FEATURE_SKILL"

# =============================================================================
# SEÇÃO 5: EDGE CASES & FAILURE MODES - VALIDAÇÃO FUNCIONAL DETERMINÍSTICA
# =============================================================================
echo ""
echo "--- 5. [TESTES FUNCIONAIS] Simulação Determinística de Auditoria e Auto-Healing ---"

SIMULATION_SCRIPT=$(cat << 'EOF'
import sys

def audit_specification(spec: dict) -> tuple[bool, str]:
    """Auditoria estéril e sem estado da especificação (Goldfish Reviewer)."""
    # Verificação de atomicidade (teto de 3 passos)
    steps = spec.get("steps", [])
    if len(steps) > 3:
        return False, f"Rejeitado: Violação de atomicidade ({len(steps)} passos > 3 passos permitidos)"
    
    # Verificação de premissas não testadas / ambiguidades
    description = spec.get("description", "")
    forbidden_terms = ["obviamente", "supõe-se", "presume-se", "assumindo que", "deve funcionar"]
    for term in forbidden_terms:
        if term in description.lower():
            return False, f"Rejeitado: Premissa implícita não verificada ('{term}')"
            
    # Verificação de critérios de aceite verificáveis
    criteria = spec.get("acceptance_criteria", [])
    if not criteria:
        return False, "Rejeitado: Ausência de critérios de aceite verificáveis"
        
    return True, "Aprovado: Especificação autocontida e atômica"

def simulate_auto_healing(spec: dict, max_iterations: int = 2) -> tuple[bool, int]:
    """Simula o loop Elephant-Goldfish com teto determinístico de auto-healing."""
    iteration = 0
    while iteration < max_iterations:
        iteration += 1
        passed, msg = audit_specification(spec)
        if passed:
            return True, iteration
        # Simula tentativa de correção pelo Elephant
        if "healing_patch" in spec:
            spec.update(spec["healing_patch"].pop(0) if spec["healing_patch"] else {})
    
    # Se ainda falhar após o teto, dispara circuit breaker
    passed, _ = audit_specification(spec)
    return passed, iteration

# Test Case 1: Rejeitar premissa implícita
invalid_spec_premise = {
    "title": "Nova Feature",
    "description": "Supõe-se que a API já envie o token sem necessidade de teste.",
    "steps": ["passo 1", "passo 2"],
    "acceptance_criteria": ["Critério 1"]
}
ok, reason = audit_specification(invalid_spec_premise)
assert not ok, "Deveria ter rejeitado premissa implícita"

# Test Case 2: Rejeitar excesso de passos (> 3)
invalid_spec_atomicity = {
    "title": "Refatoração Monolítica",
    "description": "Especificação clara.",
    "steps": ["passo 1", "passo 2", "passo 3", "passo 4"],
    "acceptance_criteria": ["Critério 1"]
}
ok, reason = audit_specification(invalid_spec_atomicity)
assert not ok, "Deveria ter rejeitado quebra de atomicidade (> 3 passos)"

# Test Case 3: Aprovar especificação atômica com critérios explícitos
valid_spec = {
    "title": "Integração Elephant-Goldfish",
    "description": "Especificação formal e autocontida.",
    "steps": ["1. Atualizar personas", "2. Documentar ADR", "3. Testes TDD"],
    "acceptance_criteria": [
        "Dado o fluxo de planejamento, quando invocado /plan-feature, então executa auditoria Goldfish",
        "Dado spec com > 3 passos, quando auditada, então é rejeitada com circuit breaker"
    ]
}
ok, reason = audit_specification(valid_spec)
assert ok, "Deveria ter aprovado especificação válida"

# Test Case 4: Circuit Breaker ativado ao atingir teto de 2 iterações com falhas persistentes
unhealable_spec = {
    "title": "Demanda Inconsistente",
    "description": "Presume-se comportamento sem testes.",
    "steps": ["passo 1", "passo 2", "passo 3", "passo 4"],
    "acceptance_criteria": [],
    "healing_patch": [] # Não consegue curar
}
success, rounds = simulate_auto_healing(unhealable_spec, max_iterations=2)
assert not success, "Circuit breaker deveria ter abortado após falha na auto-reparação"
assert rounds == 2, f"Deveria ter parado exatamente no teto de 2 iterações (executou {rounds})"

sys.exit(0)
EOF
)

check "HP-05 [Funcional]: Auditoria aprova especificação atômica (<= 3 passos) com critérios verificáveis" \
  python3 -c "$SIMULATION_SCRIPT"
check "EC-05 [Funcional]: Auditoria bloqueia especificações com premissas implícitas não testadas" \
  python3 -c "$SIMULATION_SCRIPT"
check "EC-06 [Funcional]: Auditoria bloqueia quebra de atomicidade (> 3 passos de execução)" \
  python3 -c "$SIMULATION_SCRIPT"
check "EC-07 [Funcional]: Loop de auto-healing interrompe com circuit breaker ao atingir teto de 2 iterações" \
  python3 -c "$SIMULATION_SCRIPT"

# =============================================================================
# RESUMO FINAL
# =============================================================================
echo ""
echo "========================================================================"
echo " RESUMO DA SUÍTE DE TESTES (TDD - Issue #61)"
echo "   Passaram : $PASSED"
echo "   Falharam : $FAILED"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo " [STATUS: RED] Falhas esperadas por ausência da implementação da Issue #61."
  exit 1
else
  echo " [STATUS: GREEN] Todos os critérios de aceite foram atendidos."
  exit 0
fi
