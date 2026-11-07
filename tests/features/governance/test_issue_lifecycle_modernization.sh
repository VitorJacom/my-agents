#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tests/features/governance/test_issue_lifecycle_modernization.sh - Issue #58 TDD Suite
# Validação determinística da modernização do ciclo de vida de issues:
# Épicos (Milestones), Releases (Project v2), Sub-issues e Refinamento in-place.
# =============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  [PASS] $msg"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] $msg: Esperado '$expected', obtido '$actual'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_contains() {
  local content="$1"
  local pattern="$2"
  local msg="$3"
  if echo "$content" | grep -q -E -e "$pattern"; then
    echo "  [PASS] $msg"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] $msg: Padrão '$pattern' não encontrado"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_not_contains() {
  local content="$1"
  local pattern="$2"
  local msg="$3"
  if ! echo "$content" | grep -q -E -e "$pattern"; then
    echo "  [PASS] $msg"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] $msg: Padrão '$pattern' encontrado indevidamente"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local msg="$3"
  if [ ! -f "$file" ]; then
    echo "  [FAIL] $msg: Arquivo '$file' não existe"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return
  fi
  if grep -q -E -e "$pattern" "$file"; then
    echo "  [PASS] $msg"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  [FAIL] $msg: Padrão '$pattern' não encontrado em $file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "========================================================================"
echo " [TEST] Issue #58: Modernize Issue Lifecycle (Epics, Releases, Sub-issues)"
echo "========================================================================"

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CONTEXT_FILE="$WORKSPACE_ROOT/PROJECT_CONTEXT.md"
AGENTS_RULE_FILE="$WORKSPACE_ROOT/rules/AGENTS.md"
PLAN_SKILL_FILE="$WORKSPACE_ROOT/skills/plan-feature/SKILL.md"
PUBLISH_SKILL_FILE="$WORKSPACE_ROOT/skills/publish-rule-issue/SKILL.md"
RECONCILE_SCRIPT="$WORKSPACE_ROOT/scripts/pipeline/reconcile-github-governance.sh"

# =============================================================================
# 1. [HAPPY PATH] Governança Canônica em PROJECT_CONTEXT.md e rules/AGENTS.md
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Governança Canônica em PROJECT_CONTEXT.md e rules/AGENTS.md ---"

# PROJECT_CONTEXT.md
assert_file_contains "$CONTEXT_FILE" "Active Epic \(Milestone\)" "PROJECT_CONTEXT.md declara 'Active Epic (Milestone)'"
assert_file_contains "$CONTEXT_FILE" "Release Field" "PROJECT_CONTEXT.md declara 'Release Field'"

# rules/AGENTS.md - Diretrizes do Ciclo de Vida Modernizado
assert_file_contains "$AGENTS_RULE_FILE" "(Épicos|Epics).*Milestone" "rules/AGENTS.md formaliza Milestones como Épicos temáticos"
assert_file_contains "$AGENTS_RULE_FILE" "Release.*(Project v2|GitHub Project)" "rules/AGENTS.md formaliza o campo Release no GitHub Project v2"
assert_file_contains "$AGENTS_RULE_FILE" "--parent" "rules/AGENTS.md formaliza o suporte a Sub-issues hierárquicas (--parent)"
assert_file_contains "$AGENTS_RULE_FILE" "(gh issue edit|refinamento in-place|reorganização de issues)" "rules/AGENTS.md formaliza suporte a refinamento/edição in-place no backlog"

# =============================================================================
# 2. [HAPPY PATH] Suporte a Épicos, Releases e Sub-issues nas Skills
# =============================================================================
echo ""
echo "--- 2. [HAPPY PATH] Especificação nas Skills (plan-feature e publish-rule-issue) ---"

# skills/plan-feature/SKILL.md
assert_file_contains "$PLAN_SKILL_FILE" "Active Epic \(Milestone\)" "plan-feature referencia 'Active Epic (Milestone)'"
assert_file_contains "$PLAN_SKILL_FILE" "--parent" "plan-feature instrui uso da flag '--parent' no gh issue create"
assert_file_contains "$PLAN_SKILL_FILE" "item-edit.*Release|--field.*Release" "plan-feature instrui atribuição do campo 'Release' via gh project item-edit"
assert_file_contains "$PLAN_SKILL_FILE" "gh issue edit" "plan-feature instrui refinamento/atualização in-place de issues existentes"
assert_file_contains "$PLAN_SKILL_FILE" "(--parent.*inexistente|fallback.*parent|checklist.*sub-issues)" "plan-feature define fallback ou validação para --parent inexistente"

# skills/publish-rule-issue/SKILL.md
assert_file_contains "$PUBLISH_SKILL_FILE" "Active Epic \(Milestone\)" "publish-rule-issue suporta 'Active Epic (Milestone)'"
assert_file_contains "$PUBLISH_SKILL_FILE" "item-edit.*Release|--field.*Release" "publish-rule-issue suporta atribuição do campo Release no Project v2"

# =============================================================================
# 3. [FUNCTIONAL & EDGE CASES] Extração Canônica e Compatibilidade Retroativa
# =============================================================================
echo ""
echo "--- 3. [FUNCTIONAL & EDGE CASES] Lógica de Extração de Épicos e Releases ---"

extract_epic_or_milestone() {
  local context_content="$1"
  local raw_val
  raw_val=$(echo "$context_content" | grep -E "^\s*-\s*\*\*(Active Epic \(Milestone\)|Active Milestone)\*\*:" | head -n 1 | sed -E 's/^\s*-\s*\*\*[^*]+\*\*:\s*"?([^"#]*)"?.*/\1/' | tr -d '\r' | xargs || true)
  if [ -z "$raw_val" ] || [ "$raw_val" = "None" ] || [ "$raw_val" = "none" ] || [ "$raw_val" = "null" ]; then
    echo ""
  else
    echo "$raw_val"
  fi
}

extract_release_field() {
  local context_content="$1"
  local raw_val
  raw_val=$(echo "$context_content" | grep -E "^\s*-\s*\*\*Release Field\*\*:" | head -n 1 | sed -E 's/^\s*-\s*\*\*[^*]+\*\*:\s*"?([^"#]*)"?.*/\1/' | tr -d '\r' | xargs || true)
  if [ -z "$raw_val" ] || [ "$raw_val" = "None" ] || [ "$raw_val" = "none" ] || [ "$raw_val" = "null" ]; then
    echo ""
  else
    echo "$raw_val"
  fi
}

# Cenário 1: Active Epic (Milestone) configurado com prefixo Epic:
SAMPLE_EPIC=$(cat <<'EOF'
## 🎯 Rastreamento & GitHub Governance
- **Active Epic (Milestone)**: "Epic: AIDD Core & Engineering Governance"
- **GitHub Project v2**:
  - **Release Field**: "Release"
EOF
)
E1=$(extract_epic_or_milestone "$SAMPLE_EPIC")
R1=$(extract_release_field "$SAMPLE_EPIC")
assert_equals "Epic: AIDD Core & Engineering Governance" "$E1" "Extrai corretamente Active Epic (Milestone)"
assert_equals "Release" "$R1" "Extrai corretamente Release Field"

# Cenário 2 (Backward Compatibility): Repositório legado com Active Milestone sem prefixo Epic:
SAMPLE_LEGACY=$(cat <<'EOF'
## 🎯 Rastreamento & GitHub Governance
- **Active Milestone**: "v1.2.0"
- **GitHub Project v2**:
  - **Owner**: "VitorJacom"
EOF
)
E2=$(extract_epic_or_milestone "$SAMPLE_LEGACY")
assert_equals "v1.2.0" "$E2" "Compatibilidade retroativa: aceita 'Active Milestone' legado ('v1.2.0')"

# Cenário 3 (Edge Case): Épico e Release Field indefinidos / None
SAMPLE_NONE=$(cat <<'EOF'
## 🎯 Rastreamento & GitHub Governance
- **Active Epic (Milestone)**: None
- **GitHub Project v2**:
  - **Release Field**: None
EOF
)
E3=$(extract_epic_or_milestone "$SAMPLE_NONE")
R3=$(extract_release_field "$SAMPLE_NONE")
assert_equals "" "$E3" "Fallback gracioso: retorna vazio quando Active Epic é 'None'"
assert_equals "" "$R3" "Fallback gracioso: retorna vazio quando Release Field é 'None'"

# =============================================================================
# 4. [FUNCTIONAL & EDGE CASES] Scripts de Reconciliação com Mocks
# =============================================================================
echo ""
echo "--- 4. [FUNCTIONAL & EDGE CASES] Reconciliação (scripts/pipeline/reconcile-github-governance.sh) ---"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_BIN_DIR="$TMP_DIR/bin"
mkdir -p "$MOCK_BIN_DIR"
MOCK_LOG="$TMP_DIR/gh_invocations.log"
MOCK_ISSUES_JSON="$TMP_DIR/mock_issues.json"

cat <<'EOF' > "$MOCK_BIN_DIR/gh"
#!/usr/bin/env bash
echo "gh $@" >> "$MOCK_LOG"

if [ "${1:-}" = "issue" ] && [ "${2:-}" = "list" ]; then
  if [ -f "$MOCK_ISSUES_JSON" ]; then
    cat "$MOCK_ISSUES_JSON"
  else
    echo "[]"
  fi
  exit 0
fi

if [ "${1:-}" = "project" ] && [ "${2:-}" = "item-add" ]; then
  if [ "${FAIL_PROJECT_ITEM_ADD:-false}" = "true" ]; then
    echo "Error: GraphQL error - permission denied" >&2
    exit 1
  fi
  echo "{\"id\": \"item_test_123\"}"
  exit 0
fi

if [ "${1:-}" = "project" ] && [ "${2:-}" = "item-edit" ]; then
  if [ "${FAIL_PROJECT_ITEM_EDIT:-false}" = "true" ]; then
    echo "Error: Field not found or insufficient permissions" >&2
    exit 1
  fi
  echo "{\"id\": \"item_test_123\"}"
  exit 0
fi

if [ "${1:-}" = "issue" ] && [ "${2:-}" = "edit" ]; then
  exit 0
fi

exit 0
EOF
chmod +x "$MOCK_BIN_DIR/gh"
export MOCK_LOG
export MOCK_ISSUES_JSON

# Cenário 4.1: Reconciliação de Active Epic (Milestone) e campo Release em Dry-Run
cat <<'EOF' > "$TMP_DIR/mock_issues.json"
[
  {
    "number": 58,
    "title": "feat(pipeline): modernize issue lifecycle",
    "milestone": null,
    "url": "https://github.com/VitorJacom/my-agents/issues/58"
  }
]
EOF

MOCK_CONTEXT="$TMP_DIR/PROJECT_CONTEXT.md"
cat <<'EOF' > "$MOCK_CONTEXT"
## 🎯 Rastreamento & GitHub Governance
- **Active Epic (Milestone)**: "Epic: AIDD Core & Engineering Governance"
- **GitHub Project v2**:
  - **Owner**: "VitorJacom"
  - **Project Number**: 1
  - **Status Field**: "Status"
  - **Release Field**: "Release"
  - **Default Release**: "v1.1.0"
EOF

> "$MOCK_LOG"
DRY_OUTPUT=$(PATH="$MOCK_BIN_DIR:$PATH" bash "$RECONCILE_SCRIPT" --dry-run --context-file "$MOCK_CONTEXT")
assert_contains "$DRY_OUTPUT" "Epic: AIDD Core & Engineering Governance" "Dry-run detecta e reporta Active Epic (Milestone)"
assert_contains "$DRY_OUTPUT" "(Release|v1.1.0)" "Dry-run detecta e reporta atribuição do campo Release (v1.1.0)"

# Cenário 4.2: Execução Real com Mocks (Happy Path)
> "$MOCK_LOG"
RUN_OUTPUT=$(PATH="$MOCK_BIN_DIR:$PATH" bash "$RECONCILE_SCRIPT" --context-file "$MOCK_CONTEXT")
assert_contains "$RUN_OUTPUT" "associada à milestone 'Epic: AIDD Core & Engineering Governance'|associada ao épico" "Issue associada ao Épico com sucesso"
assert_file_contains "$MOCK_LOG" "gh issue edit 58 --milestone Epic: AIDD Core & Engineering Governance" "Comando gh issue edit executado com Épico correto"
assert_file_contains "$MOCK_LOG" "gh project item-edit.*--field Release.*--value v1.1.0" "Comando gh project item-edit executado com campo Release"

# Cenário 4.3: Edge Case - Falha no item-edit do Project v2 degrada graciosamente (não bloqueante)
> "$MOCK_LOG"
FAIL_OUTPUT=$(PATH="$MOCK_BIN_DIR:$PATH" FAIL_PROJECT_ITEM_EDIT=true bash "$RECONCILE_SCRIPT" --context-file "$MOCK_CONTEXT" || true)
assert_contains "$FAIL_OUTPUT" "⚠️ \[WARN\]" "Degradação graciosa: emite aviso [WARN] ao falhar item-edit"
assert_not_contains "$FAIL_OUTPUT" "ALERTA DE FRAUDE" "Não dispara alerta indevido"

# Cenário 4.4: Edge Case - Ausência de Release Field não quebra execução
cat <<'EOF' > "$TMP_DIR/PROJECT_CONTEXT_NO_RELEASE.md"
## 🎯 Rastreamento & GitHub Governance
- **Active Epic (Milestone)**: "Epic: AIDD Core & Engineering Governance"
- **GitHub Project v2**:
  - **Owner**: "VitorJacom"
  - **Project Number**: 1
EOF

NO_RELEASE_OUTPUT=$(PATH="$MOCK_BIN_DIR:$PATH" bash "$RECONCILE_SCRIPT" --dry-run --context-file "$TMP_DIR/PROJECT_CONTEXT_NO_RELEASE.md")
assert_contains "$NO_RELEASE_OUTPUT" "concluída com sucesso|Reconciliação" "Script conclui com sucesso mesmo sem Release Field configurado"

# =============================================================================
# Sumário de Execução
# =============================================================================
echo ""
echo "========================================================================"
echo " Resumo da Suíte TDD - Issue #58"
echo " Passaram: $TESTS_PASSED | Falharam: $TESTS_FAILED"
echo "========================================================================"

if [ "$TESTS_FAILED" -gt 0 ]; then
  echo " [RED] Suíte em estado RED ($TESTS_FAILED falhas esperadas antes da implementação)."
  exit 1
else
  echo " [GREEN] Todos os testes passaram com sucesso!"
  exit 0
fi
