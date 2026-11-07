#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Test Suite: Canonical Header Comments & Usage Strings in Categorized Scripts
# Issue #604: Padronização de Cabeçalhos e Strings de usage/--help
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

PASS_COUNT=0
FAIL_COUNT=0

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if grep -Fq -- "$needle" <<<"$haystack"; then
    echo "  [PASS] $message"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  [FAIL] $message (esperado conter: '$needle')"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_file_contains() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if grep -Fq -- "$needle" "$file"; then
    echo "  [PASS] $message"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  [FAIL] $message (esperado conter '$needle' em $(basename "$file"))"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_file_not_contains() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if ! grep -Fq -- "$needle" "$file"; then
    echo "  [PASS] $message"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  [FAIL] $message (não deveria conter '$needle' em $(basename "$file"))"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

echo "=== [Happy Path] Verificando cabeçalhos e saídas de usage/--help canônicos ==="

# 1. scripts/pipeline/worktree-manager.sh
WT_SCRIPT="$REPO_ROOT/scripts/pipeline/worktree-manager.sh"
WT_OUT="$("$WT_SCRIPT" --help 2>&1 || true)"
assert_file_contains "$WT_SCRIPT" "# scripts/pipeline/worktree-manager.sh" "Cabeçalho canônico em worktree-manager.sh"
assert_contains "$WT_OUT" "Uso: scripts/pipeline/worktree-manager.sh" "String de Uso canônica em worktree-manager.sh"

# 2. scripts/pipeline/project-status-sync.sh
PSS_SCRIPT="$REPO_ROOT/scripts/pipeline/project-status-sync.sh"
PSS_OUT="$("$PSS_SCRIPT" 2>&1 || true)"
assert_file_contains "$PSS_SCRIPT" "# scripts/pipeline/project-status-sync.sh" "Cabeçalho canônico em project-status-sync.sh"
assert_contains "$PSS_OUT" "Uso: scripts/pipeline/project-status-sync.sh" "String de Uso canônica em project-status-sync.sh"
assert_contains "$PSS_OUT" "Exemplo: scripts/pipeline/project-status-sync.sh" "String de Exemplo canônica em project-status-sync.sh"

# 3. scripts/pipeline/reconcile-github-governance.sh
RGG_SCRIPT="$REPO_ROOT/scripts/pipeline/reconcile-github-governance.sh"
RGG_OUT="$("$RGG_SCRIPT" --help 2>&1 || true)"
assert_file_contains "$RGG_SCRIPT" "# scripts/pipeline/reconcile-github-governance.sh" "Cabeçalho canônico em reconcile-github-governance.sh"
assert_contains "$RGG_OUT" "Uso: scripts/pipeline/reconcile-github-governance.sh" "String de Uso canônica em reconcile-github-governance.sh --help"

# 4. scripts/statusline/install-statusline.sh
ISL_SCRIPT="$REPO_ROOT/scripts/statusline/install-statusline.sh"
ISL_OUT="$("$ISL_SCRIPT" --help 2>&1 || true)"
assert_contains "$ISL_OUT" "(padrão: scripts/statusline/statusline-quota.sh)" "Caminho padrão canônico em install-statusline.sh --help"

# 5. scripts/migrations/migrate-issues-to-project.sh
MIP_SCRIPT="$REPO_ROOT/scripts/migrations/migrate-issues-to-project.sh"
MIP_OUT="$("$MIP_SCRIPT" --help 2>&1 || true)"
assert_file_contains "$MIP_SCRIPT" "# scripts/migrations/migrate-issues-to-project.sh" "Cabeçalho canônico em migrate-issues-to-project.sh"
assert_contains "$MIP_OUT" "Uso: scripts/migrations/migrate-issues-to-project.sh" "String de Uso canônica em migrate-issues-to-project.sh --help"

# 6. scripts/migrations/reclassify-epics-and-releases.py
RER_SCRIPT="$REPO_ROOT/scripts/migrations/reclassify-epics-and-releases.py"
assert_file_contains "$RER_SCRIPT" "scripts/migrations/reclassify-epics-and-releases.py" "Docstring canônica em reclassify-epics-and-releases.py"

echo ""
echo "=== [Edge Cases / Failure Modes] Ausência de caminhos legados e integridade de execução ==="

TARGET_SCRIPTS=(
  "$WT_SCRIPT"
  "$PSS_SCRIPT"
  "$RGG_SCRIPT"
  "$ISL_SCRIPT"
  "$MIP_SCRIPT"
  "$RER_SCRIPT"
)

LEGACY_PATHS=(
  "scripts/worktree-manager.sh"
  "scripts/project-status-sync.sh"
  "scripts/reconcile-github-governance.sh"
  "scripts/statusline-quota.sh"
  "scripts/migrate-issues-to-project.sh"
  "scripts/reclassify-epics-and-releases.py"
)

for script in "${TARGET_SCRIPTS[@]}"; do
  for legacy in "${LEGACY_PATHS[@]}"; do
    assert_file_not_contains "$script" "$legacy" "Sem referência legada '$legacy' em $(basename "$script")"
  done

  if [ -x "$script" ]; then
    echo "  [PASS] Permissão executável preservada em $(basename "$script")"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  [FAIL] Permissão executável ausente em $(basename "$script")"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi

  first_line="$(head -n 1 "$script")"
  if [[ "$first_line" =~ ^#!/usr/bin/env\ (bash|python3)$ ]]; then
    echo "  [PASS] Shebang válido em $(basename "$script"): $first_line"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  [FAIL] Shebang inválido em $(basename "$script"): $first_line"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done

echo ""
echo "Resumo: $PASS_COUNT passaram, $FAIL_COUNT falharam."

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
