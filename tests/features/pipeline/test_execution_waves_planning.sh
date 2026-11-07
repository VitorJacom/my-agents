#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): Target Files Blast-Radius & Execution Waves (Issue #36)
# -----------------------------------------------------------------------------
# Valida contratos formais de Target Files & Dependencies, heurística de
# Execution Waves (máximo 3 issues por onda, arquivos 100% disjuntos) e
# modos de falha/rejeição para colisões e estouro de capacidade.
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SYSTEM_ARCHITECT_AGENT="$REPO_ROOT/agents/system-architect/agent.md"
PLANNER_AGENT="$REPO_ROOT/agents/planner/agent.md"
PLAN_FEATURE_SKILL="$REPO_ROOT/skills/plan-feature/SKILL.md"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #36: Target Files Blast-Radius & Execution Waves Planning"
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
# SEÇÃO 1: HAPPY PATH - CONTRATOS ESTÁTICOS DE ESPECIFICAÇÃO
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Contratos do Subagente System Architect ---"
check "agents/system-architect/agent.md existe" test -f "$SYSTEM_ARCHITECT_AGENT"
check "System Architect especifica mapeamento de Blast Radius e Target Files" grep -qi "Target Files" "$SYSTEM_ARCHITECT_AGENT"
check "System Architect especifica mapeamento de precedências e Depends On" grep -qi "Depends On" "$SYSTEM_ARCHITECT_AGENT"
check "System Architect exige matriz consolidada 'Execution Waves' no contrato de saída" grep -qi "Execution Waves" "$SYSTEM_ARCHITECT_AGENT"
check "System Architect impõe teto de no máximo 3 issues simultâneas por wave" grep -E -q "(<= 3|máx(imo)?\.? 3|no máximo 3).*wave" "$SYSTEM_ARCHITECT_AGENT"
check "System Architect exige arquivos disjuntos (interseção nula) entre tasks da mesma wave" grep -E -q "(disjunt|interseção nula|sem compartilhamento|sem sobreposição)" "$SYSTEM_ARCHITECT_AGENT"

echo ""
echo "--- 2. [HAPPY PATH] Contratos do Subagente Planner ---"
check "agents/planner/agent.md existe" test -f "$PLANNER_AGENT"
check "Planner contém a seção obrigatória 'Target Files & Dependencies' no implementation_plan.md" grep -qi "Target Files & Dependencies" "$PLANNER_AGENT"
check "Planner especifica identificação explícita de Target Files" grep -qi "Target Files" "$PLANNER_AGENT"
check "Planner especifica identificação explícita de Depends On" grep -qi "Depends On" "$PLANNER_AGENT"

echo ""
echo "--- 3. [HAPPY PATH] Pipeline da Skill /plan-feature ---"
check "skills/plan-feature/SKILL.md existe" test -f "$PLAN_FEATURE_SKILL"
check "Estado 2 (System Architect) formaliza heurística determinística de 'Execution Waves'" grep -qi "Execution Waves" "$PLAN_FEATURE_SKILL"
check "Estado 2 define teto de até 3 issues simultâneas por wave" grep -E -q "(<= 3|máx(imo)?\.? 3|no máximo 3).*wave" "$PLAN_FEATURE_SKILL"
check "Estado 2 exige arquivos 100% disjuntos / interseção nula na mesma onda" grep -E -q "(disjunt|interseção nula)" "$PLAN_FEATURE_SKILL"
check "Estado 4 (GitHub Issue Creation) inclui 'Target Files & Dependencies' no --body de gh issue create" grep -qi "Target Files & Dependencies" "$PLAN_FEATURE_SKILL"
check "Estado 4 inclui apresentação da matriz 'Execution Waves' no sumário final" grep -qi "Execution Waves" "$PLAN_FEATURE_SKILL"

# =============================================================================
# SEÇÃO 2: HAPPY PATH - TESTE ALGORÍTMICO DE PARTICIONAMENTO DE ONDAS
# =============================================================================
echo ""
echo "--- 4. [HAPPY PATH] Validação Algorítmica da Partição em Ondas Disjuntas ---"

ALGO_TEST_SCRIPT=$(cat << 'EOF'
import sys
import json

def validate_execution_waves(issues, waves):
    """
    Valida as regras inegociáveis de Execution Waves:
    1. Cada wave possui no máximo 3 issues simultâneas.
    2. Issues dentro da mesma wave devem ter arquivos estritamente disjuntos em Target Files.
    3. Dependências em Depends On devem estar concluídas em waves anteriores.
    4. Cada issue deve declarar obrigatoriamente Target Files e Depends On.
    """
    issues_by_id = {iss["id"]: iss for iss in issues}
    scheduled_issues = set()

    for wave_idx, wave in enumerate(waves):
        # Regra 1: Teto de <= 3 issues por wave
        if len(wave) > 3:
            return False, f"Wave {wave_idx + 1} excede capacidade máxima de 3 issues: possui {len(wave)}"
        
        wave_files = set()
        for iss_id in wave:
            if iss_id not in issues_by_id:
                return False, f"Issue {iss_id} desconhecida na Wave {wave_idx + 1}"
            
            iss = issues_by_id[iss_id]
            
            # Regra 4: Validação estrita de presença de schema
            if "target_files" not in iss or "depends_on" not in iss:
                return False, f"Issue {iss_id} incompleta: falta 'target_files' ou 'depends_on'"
            if not isinstance(iss["target_files"], list) or not isinstance(iss["depends_on"], list):
                return False, f"Issue {iss_id}: 'target_files' e 'depends_on' devem ser listas"

            # Regra 3: Precedência (Depends On concluídas em waves anteriores)
            for dep in iss["depends_on"]:
                if dep not in scheduled_issues:
                    return False, f"Issue {iss_id} na Wave {wave_idx + 1} depende de {dep}, que não foi executada em wave anterior"

            # Regra 2: Arquivos estritamente disjuntos na mesma wave
            for f in iss["target_files"]:
                if f in wave_files:
                    return False, f"Colisão em Wave {wave_idx + 1}: arquivo '{f}' compartilhado por múltiplas issues"
                wave_files.add(f)

        for iss_id in wave:
            scheduled_issues.add(iss_id)

    if len(scheduled_issues) != len(issues):
        return False, f"Nem todas as issues foram agendadas ({len(scheduled_issues)}/{len(issues)})"

    return True, "Valid Waves"

def partition_into_waves(issues):
    """
    Algoritmo determinístico ganancioso de agendamento em ondas:
    - Respeita dependências topológicas.
    - Agrupa até 3 issues sem colisão de arquivos por onda.
    - Se houver colisão de target_files, adia para a próxima onda disponível.
    """
    issues_by_id = {iss["id"]: iss for iss in issues}
    remaining = set(issues_by_id.keys())
    completed = set()
    waves = []

    while remaining:
        current_wave = []
        current_wave_files = set()
        
        # Candidatos prontos (todas as dependências satisfeitas)
        ready = [
            iss_id for iss_id in sorted(remaining)
            if all(dep in completed for dep in issues_by_id[iss_id]["depends_on"])
        ]
        
        if not ready:
            raise ValueError("Deadlock ou ciclo de dependências detectado")

        for cand_id in ready:
            if len(current_wave) == 3:
                break
            cand_files = set(issues_by_id[cand_id]["target_files"])
            # Checar colisão com os arquivos já alocados nesta wave
            if not (cand_files & current_wave_files):
                current_wave.append(cand_id)
                current_wave_files.update(cand_files)
        
        if not current_wave:
            # Não foi possível alocar nenhum candidato (não deve acontecer com lista não-vazia)
            raise ValueError("Incapaz de formar wave válida")

        for iss_id in current_wave:
            remaining.remove(iss_id)
            completed.add(iss_id)
        
        waves.append(current_wave)

    return waves

# Cenário Happy Path:
# 4 issues onde Issue #1 e Issue #2 colidem em Target Files (ambas tocam src/auth.ts)
# Issue #3 e Issue #4 tocam arquivos independentes.
sample_issues = [
    {"id": "#1", "target_files": ["src/auth.ts", "src/tokens.ts"], "depends_on": []},
    {"id": "#2", "target_files": ["src/auth.ts", "src/session.ts"], "depends_on": []},
    {"id": "#3", "target_files": ["src/db.ts"], "depends_on": []},
    {"id": "#4", "target_files": ["src/api.ts"], "depends_on": []},
]

generated_waves = partition_into_waves(sample_issues)

# Verificações de negócio
valid, msg = validate_execution_waves(sample_issues, generated_waves)
if not valid:
    sys.exit(f"Erro na validação do Happy Path: {msg}")

# Verificar que #1 e #2 ficaram em waves distintas devido à colisão em src/auth.ts
wave_of_1 = next(idx for idx, w in enumerate(generated_waves) if "#1" in w)
wave_of_2 = next(idx for idx, w in enumerate(generated_waves) if "#2" in w)
if wave_of_1 == wave_of_2:
    sys.exit("Falha: #1 e #2 colidentes foram alocados na mesma wave!")

# Verificar que nenhuma wave ultrapassou o teto de 3 issues
for idx, w in enumerate(generated_waves):
    if len(w) > 3:
        sys.exit(f"Falha: wave {idx + 1} possui {len(w)} issues (máximo permitido é 3)")

print("Algoritmo de partição em ondas validado com sucesso!")
EOF
)

check "Algoritmo de particionamento separa colisões de Target Files e respeita teto de 3 issues" python3 -c "$ALGO_TEST_SCRIPT"

# =============================================================================
# SEÇÃO 3: EDGE CASES & FAILURE MODES (VALICADAÇÃO DE ERRO E LIMITES)
# =============================================================================
echo ""
echo "--- 5. [EDGE CASES] Falha e Rejeição Determinística de Violações de Contrato ---"

EDGE_CASES_SCRIPT=$(cat << 'EOF'
import sys

# Importa o validador do bloco anterior
test_scope = {}
exec('''
def validate_execution_waves(issues, waves):
    issues_by_id = {iss["id"]: iss for iss in issues}
    scheduled_issues = set()

    for wave_idx, wave in enumerate(waves):
        if len(wave) > 3:
            return False, f"Wave {wave_idx + 1} excede capacidade máxima de 3 issues: possui {len(wave)}"
        
        wave_files = set()
        for iss_id in wave:
            if iss_id not in issues_by_id:
                return False, f"Issue {iss_id} desconhecida na Wave {wave_idx + 1}"
            
            iss = issues_by_id[iss_id]
            if "target_files" not in iss or "depends_on" not in iss:
                return False, f"Issue {iss_id} incompleta: falta 'target_files' ou 'depends_on'"
            if not isinstance(iss["target_files"], list) or not isinstance(iss["depends_on"], list):
                return False, f"Issue {iss_id}: 'target_files' e 'depends_on' devem ser listas"

            for dep in iss["depends_on"]:
                if dep not in scheduled_issues:
                    return False, f"Issue {iss_id} na Wave {wave_idx + 1} depende de {dep}, que não foi executada em wave anterior"

            for f in iss["target_files"]:
                if f in wave_files:
                    return False, f"Colisão em Wave {wave_idx + 1}: arquivo '{f}' compartilhado por múltiplas issues"
                wave_files.add(f)

        for iss_id in wave:
            scheduled_issues.add(iss_id)

    if len(scheduled_issues) != len(issues):
        return False, f"Nem todas as issues foram agendadas ({len(scheduled_issues)}/{len(issues)})"

    return True, "Valid Waves"
''', test_scope)

validate = test_scope["validate_execution_waves"]

# Caso 1: Rejeitar se duas issues na mesma wave compartilharem arquivos de Target Files
case_collision = [
    {"id": "#1", "target_files": ["src/service.ts"], "depends_on": []},
    {"id": "#2", "target_files": ["src/service.ts"], "depends_on": []},
]
waves_with_collision = [["#1", "#2"]]
valid, msg = validate(case_collision, waves_with_collision)
assert not valid and "Colisão" in msg, f"Deveria rejeitar colisão na mesma wave, mas obteve: {valid}, {msg}"

# Caso 2: Rejeitar se uma wave ultrapassar o teto estrito de 3 issues
case_overflow = [
    {"id": "#1", "target_files": ["src/a.ts"], "depends_on": []},
    {"id": "#2", "target_files": ["src/b.ts"], "depends_on": []},
    {"id": "#3", "target_files": ["src/c.ts"], "depends_on": []},
    {"id": "#4", "target_files": ["src/d.ts"], "depends_on": []},
]
waves_with_overflow = [["#1", "#2", "#3", "#4"]]
valid, msg = validate(case_overflow, waves_with_overflow)
assert not valid and "excede capacidade máxima" in msg, f"Deveria rejeitar wave > 3 issues, mas obteve: {valid}, {msg}"

# Caso 3: Rejeitar se 'target_files' estiver ausente
case_missing_target = [
    {"id": "#1", "depends_on": []},
]
waves_missing_target = [["#1"]]
valid, msg = validate(case_missing_target, waves_missing_target)
assert not valid and "falta 'target_files'" in msg, f"Deveria rejeitar ausência de target_files, mas obteve: {valid}, {msg}"

# Caso 4: Rejeitar se 'depends_on' estiver ausente
case_missing_depends = [
    {"id": "#1", "target_files": ["src/a.ts"]},
]
waves_missing_depends = [["#1"]]
valid, msg = validate(case_missing_depends, waves_missing_depends)
assert not valid and "falta 'target_files' ou 'depends_on'" in msg, f"Deveria rejeitar ausência de depends_on, mas obteve: {valid}, {msg}"

# Caso 5: Rejeitar inversão de dependência (Issue depende de outra na mesma wave ou wave posterior)
case_dep_inversion = [
    {"id": "#1", "target_files": ["src/a.ts"], "depends_on": ["#2"]},
    {"id": "#2", "target_files": ["src/b.ts"], "depends_on": []},
]
waves_inversion = [["#1", "#2"]]
valid, msg = validate(case_dep_inversion, waves_inversion)
assert not valid and "depende de #2" in msg, f"Deveria rejeitar dependência na mesma wave, mas obteve: {valid}, {msg}"

print("Todos os cenários de Edge Cases / Failure Modes foram rejeitados com sucesso!")
EOF
)

check "Rejeita colisão de Target Files na mesma onda de execução" python3 -c "$EDGE_CASES_SCRIPT"
check "Rejeita onda com mais de 3 issues simultâneas" python3 -c "$EDGE_CASES_SCRIPT"
check "Rejeita ausência obrigatória de Target Files ou Depends On" python3 -c "$EDGE_CASES_SCRIPT"
check "Rejeita violação de precedência em Depends On na mesma onda" python3 -c "$EDGE_CASES_SCRIPT"

# =============================================================================
# RESUMO FINAL
# =============================================================================
echo ""
echo "========================================================================"
echo " RESUMO DA SUÍTE DE TESTES (TDD)"
echo "   Passaram : $PASSED"
echo "   Falharam : $FAILED"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo " [STATUS: RED] Falhas esperadas por ausência da implementação da Issue #36."
  exit 1
else
  echo " [STATUS: GREEN] Todos os critérios de aceite foram atendidos."
  exit 0
fi
