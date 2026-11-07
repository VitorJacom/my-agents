#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Test Suite: Maestro Multi-Issue Pipeline & Merge Queue (Issue #9)
# TDD Phase: RED
# =============================================================================
# Valida contratos formais e comportamento determinístico do Modo Maestro:
# 1. Happy Path:
#    - Detecção de Modo Unitário vs Modo Maestro (/run-issue #1 #2 #3 ou --epic)
#    - Pre-flight de Target Files e partição em Ondas (Concurrency Cap = 3)
#    - Derivação de branch intermediária (integration/... ou epic/...) e worktrees isoladas
#    - Merge Queue Sequencial com rebase-sync, suíte acumulada e PR final
#    - Gatekeeper com flag --base <branch> e suporte a worktrees
# 2. Edge Cases & Guardrails:
#    - Algoritmo de partição com colisões de Target Files
#    - Protocolo de Auto-Reconciliação (até 2 iterações com coder)
#    - Trava Anti-Fraude na Auto-Reconciliação (Exit Code 3)
#    - Fail-safe em esgotamento de tentativas (preservação da branch intermediária)
#    - Integridade e sintaxe de diagrama Mermaid do Modo Maestro
# =============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ISSUE_PIPELINE_SKILL="$REPO_ROOT/skills/issue-pipeline/SKILL.md"
GATEKEEPER_AGENT="$REPO_ROOT/agents/gatekeeper/agent.md"
WORKTREE_SCRIPT="$REPO_ROOT/scripts/pipeline/worktree-manager.sh"

PASSED=0
FAILED=0

echo "========================================================================"
echo " [TEST] Issue #9: Maestro Multi-Issue Pipeline & Merge Queue"
echo "========================================================================"

assert_true() {
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

assert_equal() {
  local desc="$1"
  local expected="$2"
  local actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  [PASS] $desc"
    PASSED=$((PASSED + 1))
  else
    echo "  [FAIL] $desc (Esperado: '$expected', Obtido: '$actual')"
    FAILED=$((FAILED + 1))
  fi
}

# =============================================================================
# SEÇÃO 1: HAPPY PATH - ESPECIFICAÇÃO DO MODO MAESTRO NA SKILL (issue-pipeline)
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Especificações do Modo Maestro em skills/issue-pipeline/SKILL.md ---"

assert_true "Arquivo skills/issue-pipeline/SKILL.md existe" test -f "$ISSUE_PIPELINE_SKILL"

assert_true "HP-01: Define distinção formal entre Modo Unitário (1 issue) e Modo Maestro (multi-issue)" \
  grep -qi "Modo Maestro" "$ISSUE_PIPELINE_SKILL"

assert_true "HP-01: Documenta sintaxe multi-issue (/run-issue #A #B ou múltiplos números)" \
  grep -E -q "(/run-issue #[0-9]+ #[0-9]+|/run-issue [0-9]+ [0-9]+)" "$ISSUE_PIPELINE_SKILL"

assert_true "HP-01: Documenta invocação por épico (/run-issue --epic)" \
  grep -qi -- "--epic" "$ISSUE_PIPELINE_SKILL"

assert_true "HP-02: Define Pre-flight de Target Files e dependências antes do despacho" \
  grep -qi "Pre-flight" "$ISSUE_PIPELINE_SKILL"

assert_true "HP-02: Formaliza partição em Ondas (Execution Waves) com teto <= 3 workers simultâneos" \
  grep -E -qi "(cap.*3|<= 3|máx(imo)? 3|teto de 3).*worker" "$ISSUE_PIPELINE_SKILL"

assert_true "HP-02: Exige arquivos disjuntos (Target Files) entre issues da mesma onda" \
  grep -E -qi "(disjunt|interseção nula|sem sobreposição)" "$ISSUE_PIPELINE_SKILL"

assert_true "HP-03: Define criação de branch intermediária (integration/... ou epic/...)" \
  grep -E -q "(integration/|epic/)" "$ISSUE_PIPELINE_SKILL"

assert_true "HP-03: Define despacho de Workers isolados em worktrees via invoke_subagent" \
  grep -E -qi "invoke_subagent.*(self|worker)" "$ISSUE_PIPELINE_SKILL"

assert_true "HP-04: Define estado formal de Merge Queue Sequencial" \
  grep -qi "Merge Queue" "$ISSUE_PIPELINE_SKILL"

assert_true "HP-04: Integração com worktree-manager.sh rebase-sync contra branch intermediária" \
  grep -E -q "worktree-manager\.sh rebase-sync.*--base" "$ISSUE_PIPELINE_SKILL"

assert_true "HP-04: Exige validação da suíte acumulada (tests/core/ e tests/features/) na Merge Queue" \
  grep -qi "acumulad" "$ISSUE_PIPELINE_SKILL"

assert_true "HP-04: Especifica auto-merge na branch intermediária após aprovação na Merge Queue" \
  grep -qi "auto-merge" "$ISSUE_PIPELINE_SKILL"

assert_true "HP-04: Define criação de PR consolidado da branch intermediária para main" \
  grep -E -qi "(pr consolidado|pull request consolidado|pr único)" "$ISSUE_PIPELINE_SKILL"

# =============================================================================
# SEÇÃO 2: HAPPY PATH - ESPECIFICAÇÃO DO AGENTE GATEKEEPER
# =============================================================================
echo ""
echo "--- 2. [HAPPY PATH] Especificações de Parâmetros do Gatekeeper em agents/gatekeeper/agent.md ---"

assert_true "Arquivo agents/gatekeeper/agent.md existe" test -f "$GATEKEEPER_AGENT"

assert_true "HP-05: Gatekeeper suporta parâmetro/flag --base para auditoria contextual" \
  grep -qi -- "--base" "$GATEKEEPER_AGENT"

assert_true "HP-05: Golden Rule suporta variável BASE_BRANCH ou diff parametrizado em vez de apenas origin/main" \
  grep -E -q "(\\\$BASE_BRANCH|BASE_BRANCH=|--base)" "$GATEKEEPER_AGENT"

assert_true "HP-06: Gatekeeper documenta integração com worktree-manager.sh rebase-sync e cleanup" \
  grep -qi "worktree-manager\.sh" "$GATEKEEPER_AGENT"

# =============================================================================
# SEÇÃO 3: EDGE CASES & GUARDRAILS - PROTOCOLO DE AUTO-RECONCILIAÇÃO & FRAUDE
# =============================================================================
echo ""
echo "--- 3. [EDGE CASES] Protocolo de Auto-Reconciliação e Travas Anti-Fraude ---"

assert_true "EC-01: Documenta protocolo de Auto-Reconciliação na Merge Queue" \
  grep -qi "Auto-Reconcilia" "$ISSUE_PIPELINE_SKILL"

assert_true "EC-01: Limita Auto-Reconciliação a no máximo 2 tentativas com subagente coder" \
  grep -E -qi "(2 tentativas|duas tentativas|até 2)" "$ISSUE_PIPELINE_SKILL"

assert_true "EC-02: Trava Anti-Fraude na Auto-Reconciliação proíbe alterar tests/core/ e testes já integrados em tests/features/" \
  grep -E -qi "(testes já integrados|testes pré-existentes na base|testes integrados.*tests/features)" "$ISSUE_PIPELINE_SKILL"

assert_true "EC-03: Fail-safe em esgotamento: issue marcada com falha sem quebrar branch intermediária" \
  grep -E -qi "(FAILED_RECONCILIATION|falha.*sem quebrar|isolar.*falha)" "$ISSUE_PIPELINE_SKILL"

assert_true "EC-04: Contém diagrama Mermaid atualizado refletindo o fluxo do Modo Maestro" \
  grep -E -qi "flowchart.*(Maestro|Merge Queue|Onda|Wave)" "$ISSUE_PIPELINE_SKILL"

# =============================================================================
# SEÇÃO 4: TESTES FUNCIONAIS EM SANDBOX GIT TEMPORÁRIO
# =============================================================================
echo ""
echo "--- 4. [TESTES FUNCIONAIS] Simulação Determinística da Merge Queue & Auto-Reconciliação ---"

TEMP_SANDBOX=$(mktemp -d -t maestro_sandbox_XXXXXX)
SANDBOX_RESULTS="$TEMP_SANDBOX/.results"
touch "$SANDBOX_RESULTS"

sandbox_cleanup() {
  rm -rf "$TEMP_SANDBOX"
}
trap sandbox_cleanup EXIT

# Setup do repositório estéril simulando repo central
(
  cd "$TEMP_SANDBOX"
  git init -b main >/dev/null 2>&1
  git config user.name "Maestro Test"
  git config user.email "maestro@pipeline.local"

  mkdir -p tests/core tests/features src
  echo "echo 'core v1'" > tests/core/test_core.sh
  chmod +x tests/core/test_core.sh
  echo "echo 'feature 0 v1'" > tests/features/test_feature_0.sh
  chmod +x tests/features/test_feature_0.sh
  echo "echo 'app baseline'" > src/app.sh
  chmod +x src/app.sh

  git add .
  git commit -m "chore: baseline commit" >/dev/null 2>&1
)

# Teste 4.1: Algoritmo de Pre-Flight Wave Partitioning
python3 - << 'EOF' >/dev/null 2>&1 && TEST_ALGO_STATUS=0 || TEST_ALGO_STATUS=$?
import sys

def partition_waves(issues, max_workers=3):
    waves = []
    for issue in issues:
        placed = False
        for wave in waves:
            if len(wave) >= max_workers:
                continue
            # Verifica colisão de target files
            collision = False
            wave_files = set()
            for w_iss in wave:
                wave_files.update(w_iss["target_files"])
            if wave_files.intersection(set(issue["target_files"])):
                collision = True
            if not collision:
                wave.append(issue)
                placed = True
                break
        if not placed:
            waves.append([issue])
    return waves

# 3 issues onde 1 e 3 colidem no arquivo "src/shared.sh"
issues_sample = [
    {"id": 101, "target_files": ["src/shared.sh", "tests/features/test_101.sh"]},
    {"id": 102, "target_files": ["src/module_b.sh", "tests/features/test_102.sh"]},
    {"id": 103, "target_files": ["src/shared.sh", "tests/features/test_103.sh"]},
]
waves = partition_waves(issues_sample, max_workers=3)
assert len(waves) == 2, f"Esperado 2 waves devido a colisão, obtido {len(waves)}"
assert any(i["id"] == 101 for i in waves[0])
assert any(i["id"] == 102 for i in waves[0])
assert any(i["id"] == 103 for i in waves[1]), "Issue 103 deve estar na Wave 2 por colisão de target_files"
EOF
assert_equal "EC-05 [Funcional]: Algoritmo de partição separa colisões de Target Files em waves distintas" "0" "$TEST_ALGO_STATUS"

# Teste 4.2: Simulação de Merge Queue Happy Path com Branch Intermediária
(
  cd "$TEMP_SANDBOX"
  
  # Cria branch intermediária
  INTERMEDIATE_BRANCH="integration/batch-20261106"
  git checkout -b "$INTERMEDIATE_BRANCH" >/dev/null 2>&1
  
  # Cria Worktree para Issue 201 com base na branch intermediária
  "$WORKTREE_SCRIPT" create 201 --base "$INTERMEDIATE_BRANCH" >/dev/null 2>&1
  
  # Issue 201 implementa sua feature
  echo "echo 'feature 201 test'" > .worktrees/issue-201/tests/features/test_feature_201.sh
  chmod +x .worktrees/issue-201/tests/features/test_feature_201.sh
  echo "echo 'feature 201 code'" > .worktrees/issue-201/src/feature_201.sh
  chmod +x .worktrees/issue-201/src/feature_201.sh
  (
    cd .worktrees/issue-201
    git add .
    git commit -m "feat(201): implement feature 201" >/dev/null 2>&1
  )

  # Merge Queue sincroniza Issue 201 via rebase-sync e auto-merge
  "$WORKTREE_SCRIPT" rebase-sync 201 --base "$INTERMEDIATE_BRANCH" >/dev/null 2>&1
  git checkout "$INTERMEDIATE_BRANCH" >/dev/null 2>&1
  git merge --ff-only feature/issue-201 >/dev/null 2>&1
  "$WORKTREE_SCRIPT" remove 201 >/dev/null 2>&1
)
MQ_HP_STATUS=$?
assert_equal "HP-07 [Funcional]: Merge Queue integra Issue 201 na branch intermediária com rebase-sync e cleanup" "0" "$MQ_HP_STATUS"

# Teste 4.3: Simulação de Trava Anti-Fraude na Auto-Reconciliação (Exit Code 3)
(
  cd "$TEMP_SANDBOX"
  INTERMEDIATE_BRANCH="integration/batch-20261106"

  # Cria Worktree para Issue 202
  "$WORKTREE_SCRIPT" create 202 --base "$INTERMEDIATE_BRANCH" >/dev/null 2>&1

  # Coder fraudulento tenta alterar teste pré-existente integrado da Issue 201
  echo "echo 'tampered test'" > .worktrees/issue-202/tests/features/test_feature_201.sh
  (
    cd .worktrees/issue-202
    git add .
    git commit -m "fraud: modify integrated feature test" >/dev/null 2>&1
  )

  # rebase-sync DEVE retornar exit code 3 (Fraude detectada!)
  set +e
  "$WORKTREE_SCRIPT" rebase-sync 202 --base "$INTERMEDIATE_BRANCH" >/dev/null 2>&1
  FRAUD_EXIT=$?
  set -e
  "$WORKTREE_SCRIPT" remove 202 >/dev/null 2>&1
  exit "$FRAUD_EXIT"
) || FRAUD_CODE=$?
assert_equal "EC-06 [Funcional]: rebase-sync barra tentativa de adulterar teste integrado com Exit Code 3" "3" "${FRAUD_CODE:-0}"

# Teste 4.4: Simulação de Conflito de Rebase (Exit Code 4) e Fail-Safe de Isolamento
(
  cd "$TEMP_SANDBOX"
  INTERMEDIATE_BRANCH="integration/batch-20261106"

  # Cria Worktree para Issue 203
  "$WORKTREE_SCRIPT" create 203 --base "$INTERMEDIATE_BRANCH" >/dev/null 2>&1
  echo "conflict line from 203" > .worktrees/issue-203/src/app.sh
  (
    cd .worktrees/issue-203
    git add .
    git commit -m "feat(203): conflict branch" >/dev/null 2>&1
  )

  # Na branch intermediária, avança o mesmo arquivo gerando conflito de rebase
  echo "conflicting change on intermediate" > src/app.sh
  git add src/app.sh
  git commit -m "chore: change on intermediate" >/dev/null 2>&1

  # rebase-sync detecta conflito e retorna 4
  set +e
  "$WORKTREE_SCRIPT" rebase-sync 203 --base "$INTERMEDIATE_BRANCH" >/dev/null 2>&1
  CONFLICT_EXIT=$?
  set -e

  # Fail-safe: a branch intermediária não foi corrompida
  git rev-parse --verify "$INTERMEDIATE_BRANCH" >/dev/null 2>&1
  BRANCH_SAFE=$?

  "$WORKTREE_SCRIPT" remove 203 >/dev/null 2>&1

  if [ "$CONFLICT_EXIT" -eq 4 ] && [ "$BRANCH_SAFE" -eq 0 ]; then
    exit 0
  else
    exit 1
  fi
)
FAILSAFE_STATUS=$?
assert_equal "EC-07 [Funcional]: Conflito de rebase gera Exit Code 4 e fail-safe preserva branch intermediária" "0" "$FAILSAFE_STATUS"

# =============================================================================
# SUMÁRIO E VEREDITO FINAL
# =============================================================================
echo ""
echo "========================================================================"
echo " RESUMO DA EXECUÇÃO: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo "❌ STATUS: RED (Falhas esperadas por ausência da implementação da Issue #9)"
  exit 1
else
  echo "✅ STATUS: GREEN (Todos os testes passaram)"
  exit 0
fi
