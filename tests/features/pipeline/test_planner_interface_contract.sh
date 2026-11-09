#!/usr/bin/env bash
# =============================================================================
# tests/features/pipeline/test_planner_interface_contract.sh
# =============================================================================
# Suíte de Testes de Aceitação TDD para a Issue #10:
# Interface Contract Standard and Strict Validation Gate
#
# Valida a governança, contratos estáticos, templates e portão determinístico:
# - Planner (agents/planner/agent.md): Interface Contract obrigatório e tipado.
# - Feature Planning Pipeline (skills/plan-feature/SKILL.md): Padrão estruturado e issue template.
# - Issue Pipeline (skills/issue-pipeline/SKILL.md): Portão de validação no Planning.
# - Gatekeeper (agents/gatekeeper/agent.md): Cold Audit com Interface Contract Gate.
# - Script Validador (scripts/pipeline/validate-interface-contract.sh): Validação determinística.
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PLANNER_AGENT="$REPO_ROOT/agents/planner/agent.md"
PLAN_FEATURE_SKILL="$REPO_ROOT/skills/plan-feature/SKILL.md"
ISSUE_PIPELINE_SKILL="$REPO_ROOT/skills/issue-pipeline/SKILL.md"
GATEKEEPER_AGENT="$REPO_ROOT/agents/gatekeeper/agent.md"
RULES_AGENTS="$REPO_ROOT/rules/AGENTS.md"
VALIDATE_SCRIPT="$REPO_ROOT/scripts/pipeline/validate-interface-contract.sh"
VALIDATE_PY="$REPO_ROOT/scripts/pipeline/validate-interface-contract.py"

PASSED=0
FAILED=0

echo "========================================================================"
echo " [TEST] Issue #10: Planner Interface Contract Standard & Validation Gate"
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
# SEÇÃO 1: HAPPY PATH - CONTRATOS ESTÁTICOS E TEMPLATES DE PLANEJAMENTO
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Governança e Templates do Interface Contract ---"

check "agents/planner/agent.md existe" test -f "$PLANNER_AGENT"
check "Planner define formalmente a seção '## Interface Contract' como mandatória" \
  grep -E -q -i "interface contract" "$PLANNER_AGENT"
check "Planner estabelece o 'Interface Contract Gate' como regra inviolável" \
  grep -E -q -i "interface contract gate" "$PLANNER_AGENT"
check "Planner padroniza a estrutura com os 5 pilares (Signatures, Types/Interfaces, Inputs, Outputs, Errors)" \
  grep -E -q -i "signatures" "$PLANNER_AGENT"
check "Planner explicita desacoplamento simultâneo para QA e Coder operarem em paralelo" \
  grep -E -q -i "(qa.*coder|coder.*qa).*simultaneamente" "$PLANNER_AGENT"

check "skills/plan-feature/SKILL.md existe" test -f "$PLAN_FEATURE_SKILL"
check "skills/plan-feature/SKILL.md inclui Interface Contract no ciclo Elephant-Goldfish" \
  grep -E -q -i "interface contract" "$PLAN_FEATURE_SKILL"
check "skills/plan-feature/SKILL.md inclui Interface Contract Gate no ESTADO 2.5 (Goldfish Cold Audit)" \
  grep -E -q -i "interface contract gate" "$PLAN_FEATURE_SKILL"
check "skills/plan-feature/SKILL.md inclui template do Interface Contract no ESTADO 4 (gh issue create)" \
  grep -E -q -i "## Interface Contract" "$PLAN_FEATURE_SKILL"

check "skills/issue-pipeline/SKILL.md existe" test -f "$ISSUE_PIPELINE_SKILL"
check "skills/issue-pipeline/SKILL.md aciona validação do Interface Contract Gate no ESTADO 1" \
  grep -E -q -i "validate-interface-contract" "$ISSUE_PIPELINE_SKILL"

check "agents/gatekeeper/agent.md formaliza o Interface Contract Gate no Modo 1" \
  grep -E -q -i "interface contract gate" "$GATEKEEPER_AGENT"
check "rules/AGENTS.md seção 1.2 exige a seção ## Interface Contract congelada" \
  grep -E -q -i "interface contract" "$RULES_AGENTS"

# =============================================================================
# SEÇÃO 2: HAPPY PATH - VALIDAÇÃO DETERMINÍSTICA DO UTILITÁRIO CLI
# =============================================================================
echo ""
echo "--- 2. [HAPPY PATH] Execução Funcional do Validador de Interface Contract ---"

check "scripts/pipeline/validate-interface-contract.sh existe e é executável" test -x "$VALIDATE_SCRIPT"
check "scripts/pipeline/validate-interface-contract.py existe e é executável" test -x "$VALIDATE_PY"

TMP_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# HP-VALID-01: Plano com Interface Contract Completo e Tipado
cat << 'EOF' > "$TMP_DIR/valid_plan.md"
# Implementation Plan - Issue #100

## Target Files & Dependencies
- Target Files: src/service/auth.ts, tests/features/test_auth.ts
- Depends On: None

## Interface Contract
- **Signatures**:
  `authenticate(credentials: UserCredentials): Promise<AuthToken>`
  `validateSession(token: AuthToken): SessionPayload`
- **Types & Interfaces**:
  ```typescript
  interface UserCredentials { username: string; passwordHash: string; }
  type AuthToken = string;
  interface SessionPayload { userId: string; roles: string[]; expiresAt: number; }
  ```
- **Inputs**:
  - `credentials`: objeto válido com username (min 3 chars) e hash sha256
  - `token`: string JWT não vazia
- **Outputs**:
  - `authenticate`: retorna `AuthToken` JWT assinado
  - `validateSession`: retorna payload decodificado
- **Errors**:
  - `InvalidCredentialsError`: lançado quando credenciais não conferem
  - `ExpiredSessionError`: lançado quando token ultrapassa expiresAt

## Passo a Passo de Implementação
1. Passo 1
2. Passo 2
EOF

check "HP-VALID-01: Validador aprova implementation_plan.md com 5 pilares tipados" \
  "$VALIDATE_SCRIPT" "$TMP_DIR/valid_plan.md"

check "HP-VALID-02: Validador opera via pipeline stdin (cat plan | validate)" \
  bash -c "cat '$TMP_DIR/valid_plan.md' | '$VALIDATE_SCRIPT'"

# =============================================================================
# SEÇÃO 3: EDGE CASES & FAILURE MODES - PORTÃO DE REJEIÇÃO
# =============================================================================
echo ""
echo "--- 3. [EDGE CASES & FAILURE MODES] Rejeição Determinística de Planos Inválidos ---"

# EC-01: Plano sem seção Interface Contract
cat << 'EOF' > "$TMP_DIR/missing_contract.md"
# Implementation Plan

## Target Files & Dependencies
- Target Files: src/service/auth.ts

## Passo a Passo de Implementação
1. Passo 1
EOF

check_missing_contract() {
  local output
  output=$("$VALIDATE_SCRIPT" "$TMP_DIR/missing_contract.md" 2>&1 || true)
  echo "$output" | grep -qi "Interface Contract.*ausente"
}
check "EC-01: Rejeita plano sem a seção '## Interface Contract'" check_missing_contract

# EC-02: Plano com seção Interface Contract vazia
cat << 'EOF' > "$TMP_DIR/empty_contract.md"
# Implementation Plan

## Interface Contract

## Passo a Passo de Implementação
1. Passo 1
EOF

check_empty_contract() {
  local output
  output=$("$VALIDATE_SCRIPT" "$TMP_DIR/empty_contract.md" 2>&1 || true)
  echo "$output" | grep -qi "vazia"
}
check "EC-02: Rejeita plano com seção '## Interface Contract' totalmente vazia" check_empty_contract

# EC-03: Plano faltando pilar obrigatório (Signatures)
cat << 'EOF' > "$TMP_DIR/missing_signatures.md"
# Implementation Plan

## Interface Contract
- **Types & Interfaces**: interface Token { id: string }
- **Inputs**: token string
- **Outputs**: boolean
- **Errors**: TokenExpiredError
EOF

check_missing_signatures() {
  local output
  output=$("$VALIDATE_SCRIPT" "$TMP_DIR/missing_signatures.md" 2>&1 || true)
  echo "$output" | grep -E -q -i "(Signatures.*ausente|ausente.*Signatures)"
}
check "EC-03: Rejeita plano com pilar obrigatório ausente ('Signatures')" check_missing_signatures

# EC-04: Plano faltando pilar de tratamento de erros (Errors)
cat << 'EOF' > "$TMP_DIR/missing_errors.md"
# Implementation Plan

## Interface Contract
- **Signatures**: `verifyToken(token: string): boolean`
- **Types & Interfaces**: `type Token = string`
- **Inputs**: `token` não nulo
- **Outputs**: `true` ou `false`
EOF

check_missing_errors() {
  local output
  output=$("$VALIDATE_SCRIPT" "$TMP_DIR/missing_errors.md" 2>&1 || true)
  echo "$output" | grep -E -q -i "(Errors.*ausente|ausente.*Errors)"
}
check "EC-04: Rejeita plano sem tratamento de erros mapeado ('Errors')" check_missing_errors

# EC-05: Plano com termos vagos / placeholders (TODO / TBD / a definir)
cat << 'EOF' > "$TMP_DIR/placeholder_contract.md"
# Implementation Plan

## Interface Contract
- **Signatures**: TODO
- **Types & Interfaces**: TBD
- **Inputs**: a definir
- **Outputs**: any
- **Errors**: none
EOF

check_placeholder_contract() {
  local output
  output=$("$VALIDATE_SCRIPT" "$TMP_DIR/placeholder_contract.md" 2>&1 || true)
  echo "$output" | grep -qi "placeholder ou especulação"
}
check "EC-05: Rejeita plano com placeholders ou indefinições ('TODO', 'TBD', 'a definir')" check_placeholder_contract

# EC-06: Plano com premissas implícitas não testadas ("supõe-se", "obviamente")
cat << 'EOF' > "$TMP_DIR/speculative_contract.md"
# Implementation Plan

## Interface Contract
- **Signatures**: `fetchData(id: string)`
- **Types & Interfaces**: `interface Data { val: string }`
- **Inputs**: supõe-se que a API sempre responda
- **Outputs**: `Data`
- **Errors**: nenhum erro esperado obviamente
EOF

check_speculative_contract() {
  local output
  output=$("$VALIDATE_SCRIPT" "$TMP_DIR/speculative_contract.md" 2>&1 || true)
  echo "$output" | grep -qi "placeholder ou especulação"
}
check "EC-06: Rejeita plano com premissas especulativas ('supõe-se', 'obviamente')" check_speculative_contract

# EC-07: Arquivo inexistente
check_nonexistent_file() {
  ! "$VALIDATE_SCRIPT" "$TMP_DIR/nonexistent_file_xyz.md" >/dev/null 2>&1
}
check "EC-07: Falha determinística quando o arquivo alvo não existe" check_nonexistent_file

# EC-08: Arquivo vazio
touch "$TMP_DIR/empty_file.md"
check_empty_file() {
  ! "$VALIDATE_SCRIPT" "$TMP_DIR/empty_file.md" >/dev/null 2>&1
}
check "EC-08: Falha determinística quando o arquivo alvo está vazio" check_empty_file

# EC-09: Stdin vazio
check_empty_stdin() {
  ! printf "" | "$VALIDATE_SCRIPT" >/dev/null 2>&1
}
check "EC-09: Falha determinística quando o fluxo stdin está vazio" check_empty_stdin

# =============================================================================
# RESUMO FINAL
# =============================================================================
echo ""
echo "========================================================================"
echo " RESUMO DA EXECUÇÃO: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo "❌ STATUS: RED ($FAILED falha(s) detectada(s))"
  exit 1
else
  echo "✅ STATUS: GREEN (Todos os testes passaram)"
  exit 0
fi
