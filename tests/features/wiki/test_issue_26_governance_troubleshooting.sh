#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): AIDD Governance & Troubleshooting Guides (Issue #26)
# -----------------------------------------------------------------------------
# Valida deterministicamente a existência, integridade estrutural, seções
# mandatórias, diagramas Mermaid e referências consolidadas aos ADRs (0001 a 0009)
# nos novos documentos modulares da Wiki:
#   - docs/AIDD-Manifesto.md
#   - docs/System-Architecture.md
#   - docs/Troubleshooting.md
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
AIDD_MD="$REPO_ROOT/docs/AIDD-Manifesto.md"
ARCH_MD="$REPO_ROOT/docs/System-Architecture.md"
TROUBLE_MD="$REPO_ROOT/docs/Troubleshooting.md"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #26: Modularização de Governança AIDD e Troubleshooting"
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
# SEÇÃO 1: HAPPY PATH - EXISTÊNCIA FÍSICA DOS DOCUMENTOS
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Existência física dos documentos ---"
check "docs/AIDD-Manifesto.md existe" test -f "$AIDD_MD"
check "docs/System-Architecture.md existe" test -f "$ARCH_MD"
check "docs/Troubleshooting.md existe" test -f "$TROUBLE_MD"

# =============================================================================
# SEÇÃO 2: HAPPY PATH - VALIDAÇÃO DE CONTEÚDO DO AIDD-MANIFESTO.MD
# =============================================================================
echo ""
echo "--- 2. [HAPPY PATH] Governança no docs/AIDD-Manifesto.md ---"
check "AIDD-Manifesto: Declara os 4 Valores do Manifesto AIDD" \
  bash -c "grep -qi 'Método sobre o Modelo' '$AIDD_MD' && \
           grep -qi 'Responsabilidade sobre Delegação' '$AIDD_MD' && \
           grep -qi 'Compreensão sobre Aceitação' '$AIDD_MD' && \
           grep -qi 'Resultado sobre Volume' '$AIDD_MD'"

check "AIDD-Manifesto: Documenta o Triângulo de Arquivos Efêmeros" \
  bash -c "grep -q 'task.md' '$AIDD_MD' && \
           grep -q 'implementation_plan.md' '$AIDD_MD' && \
           grep -q 'walkthrough.md' '$AIDD_MD'"

check "AIDD-Manifesto: Regra mandatória de arquivos efêmeros no .gitignore" \
  grep -qi "\.gitignore" "$AIDD_MD"

check "AIDD-Manifesto: Publicação do walkthrough.md no corpo do PR via Gatekeeper" \
  grep -qi "gh pr create --body-file walkthrough\.md" "$AIDD_MD"

check "AIDD-Manifesto: Tolerância Zero a Falsos Positivos e Fail-Fast mandatório" \
  bash -c "grep -qi 'Fail-Fast' '$AIDD_MD' && grep -q 'set -euo pipefail' '$AIDD_MD'"

check "AIDD-Manifesto: Formalização da Trava Dupla Anti-Fraude e pasta tests/core/" \
  bash -c "grep -qi 'Trava Dupla Anti-Fraude' '$AIDD_MD' && grep -q 'tests/core/' '$AIDD_MD'"

check "AIDD-Manifesto: Snippet determinístico da checagem Golden Rule no Git" \
  grep -Fq 'MODIFIED=$(git diff --name-only origin/main...HEAD' "$AIDD_MD"

check "AIDD-Manifesto: Exigência inegociável de Cobertura >= 85%" \
  grep -E -q "85%" "$AIDD_MD"

check "AIDD-Manifesto: Discriminação obrigatória de Happy Path e Edge Cases / Failure Modes" \
  bash -c "grep -qi 'Happy Path' '$AIDD_MD' && grep -qiE '(Edge Cases|Failure Modes)' '$AIDD_MD'"

check "AIDD-Manifesto: Provas Demonstrativas Universais (Screenshots para UI e CLI/Logs para backend)" \
  bash -c "grep -qiE '(screenshot|headless)' '$AIDD_MD' && grep -qiE '(provas demonstrativas|evidências demonstrativas)' '$AIDD_MD'"

check "AIDD-Manifesto: Protocolo de Validação Isolada em Sandbox (Clean Room Testing)" \
  bash -c "grep -qi 'Clean Room' '$AIDD_MD' && grep -q 'agy --dangerously-skip-permissions' '$AIDD_MD'"

check "AIDD-Manifesto: Contém diagramas visuais em Mermaid" \
  grep -q '```mermaid' "$AIDD_MD"

# =============================================================================
# SEÇÃO 3: HAPPY PATH - VALIDAÇÃO DE CONTEÚDO DO SYSTEM-ARCHITECTURE.MD
# =============================================================================
echo ""
echo "--- 3. [HAPPY PATH] Visão Sistêmica no docs/System-Architecture.md ---"
check "System-Architecture: Contém visão estrutural em camadas e taxonomia de componentes" \
  bash -c "grep -qi 'Camadas' '$ARCH_MD' && grep -qi 'Taxonomia de Componentes' '$ARCH_MD'"

check "System-Architecture: Diagramas Mermaid de arquitetura e orquestração do Maestro" \
  bash -c "grep -q 'sequenceDiagram' '$ARCH_MD' && grep -qi 'Maestro' '$ARCH_MD'"

check "System-Architecture: Ciclo de vida ponta a ponta de issues mapeado (/plan-feature -> /run-issue)" \
  bash -c "grep -qi '/plan-feature' '$ARCH_MD' && grep -qi '/run-issue' '$ARCH_MD'"

check "System-Architecture: Consolidação de ADRs contendo Decisões de 0001 a 0009" \
  bash -c "grep -q '0001' '$ARCH_MD' && \
           grep -q '0002' '$ARCH_MD' && \
           grep -q '0003' '$ARCH_MD' && \
           grep -q '0004' '$ARCH_MD' && \
           grep -q '0005' '$ARCH_MD' && \
           grep -q '0006' '$ARCH_MD' && \
           grep -q '0007' '$ARCH_MD' && \
           grep -q '0008' '$ARCH_MD' && \
           grep -q '0009' '$ARCH_MD'"

check "System-Architecture: Referência ao documento canônico interno docs/ARCHITECTURE.md" \
  grep -q "docs/ARCHITECTURE\.md" "$ARCH_MD"

# =============================================================================
# SEÇÃO 4: HAPPY PATH - VALIDAÇÃO DE CONTEÚDO DO TROUBLESHOOTING.MD
# =============================================================================
echo ""
echo "--- 4. [HAPPY PATH] Matriz Diagnóstica no docs/Troubleshooting.md ---"
check "Troubleshooting: Contém Matriz Diagnóstica em formato de tabela" \
  grep -qi "Matriz Diagnóstica" "$TROUBLE_MD"

check "Troubleshooting: Seção de conflitos de lock em worktrees e solução com worktree-manager.sh" \
  bash -c "grep -qi 'lock' '$TROUBLE_MD' && grep -q 'worktree-manager\.sh' '$TROUBLE_MD'"

check "Troubleshooting: Seção de permissões de token no GitHub Actions/CLI e degradação graciosa" \
  bash -c "grep -qi 'gh project' '$TROUBLE_MD' && grep -qi 'degradação graciosa' '$TROUBLE_MD'"

check "Troubleshooting: Seção da Trava Anti-Fraude e violação de tests/core/" \
  bash -c "grep -qi 'ALERTA DE FRAUDE' '$TROUBLE_MD' && grep -q 'tests/core/' '$TROUBLE_MD'"

check "Troubleshooting: Diagnóstico de falha por cobertura inferior a 85%" \
  grep -qi "85" "$TROUBLE_MD"

check "Troubleshooting: Seção de latência sub-50ms e teste de benchmark da statusline" \
  bash -c "grep -qi '50ms' '$TROUBLE_MD' && grep -q 'test-statusline\.sh' '$TROUBLE_MD'"

check "Troubleshooting: Diagnóstico e alinhamento do Interface Contract no Fork/Join" \
  grep -qi "Interface Contract" "$TROUBLE_MD"

check "Troubleshooting: Procedimento de inicialização manual da GitHub Wiki (wiki-sync.yml)" \
  bash -c "grep -qi 'wiki-sync\.yml' '$TROUBLE_MD' && grep -qi 'Create the first page' '$TROUBLE_MD'"

check "Troubleshooting: Diagnóstico de colisão de Target Files nas Execution Waves do Maestro" \
  bash -c "grep -qi 'Target Files' '$TROUBLE_MD' && grep -qi 'Execution Wave' '$TROUBLE_MD'"

# =============================================================================
# SEÇÃO 5: EDGE CASES & FAILURE MODES
# =============================================================================
echo ""
echo "--- 5. [EDGE CASES & FAILURE MODES] Resiliência e Detecção de Falhas ---"

# Edge Case 1: Falha determinística se arquivo de documentação for removido/ausente
check "Detector de ausência: script falha se um arquivo obrigatório não existir" \
  bash -c '! test -f "'"$REPO_ROOT"'/docs/InexistentFile.md"'

# Edge Case 2: Falha determinística se faltar um dos 4 valores do Manifesto AIDD
test_integrity_detects_missing_value() {
  local tmp
  tmp=$(mktemp)
  grep -v -i "Outcome over Output" "$AIDD_MD" > "$tmp"
  if grep -qi "Outcome over Output" "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  rm -f "$tmp"
  return 0
}
check "Detector de integridade: falha quando um valor AIDD essencial é omitido em cópia temporária" \
  test_integrity_detects_missing_value

# Edge Case 3: Falha determinística se algum ADR de 0001 a 0009 for omitido
test_integrity_detects_missing_adr() {
  local tmp
  tmp=$(mktemp)
  grep -v "0009" "$ARCH_MD" > "$tmp"
  if grep -q "0009" "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  rm -f "$tmp"
  return 0
}
check "Detector de integridade: falha se o índice de ADRs tiver lacunas" \
  test_integrity_detects_missing_adr

# Edge Case 4: Verificação de sintaxe de blocos de código Mermaid (pares de abertura e fechamento)
test_mermaid_fences() {
  local file="$1"
  local open_count
  open_count=$(grep -c '^```mermaid' "$file")
  local total_count
  total_count=$(grep -c '^```' "$file")
  [ "$open_count" -gt 0 ] && [ $((total_count % 2)) -eq 0 ]
}

check "Integridade de sintaxe Mermaid em AIDD-Manifesto.md" \
  test_mermaid_fences "$AIDD_MD"

check "Integridade de sintaxe Mermaid em System-Architecture.md" \
  test_mermaid_fences "$ARCH_MD"

# =============================================================================
# RESUMO FINAL
# =============================================================================
echo ""
echo "========================================================================"
echo " Resumo: $PASSED passaram, $FAILED falharam"
echo "========================================================================"

if [ "$FAILED" -eq 0 ]; then
  echo ">>> [STATUS: SUCCESS / GREEN] Todos os critérios de aceite foram atendidos!"
  exit 0
else
  echo ">>> [STATUS: FAILED / RED] Existem falhas a serem corrigidas."
  exit 1
fi
