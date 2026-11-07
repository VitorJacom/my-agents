#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# scripts/project-status-sync.sh - GitHub Projects v2 Status Synchronizer
# ADR-0007: Integração Nativa de GitHub Projects v2 com Degradação Graciosa
# =============================================================================

TARGET_ISSUE="${1:-}"
STATUS_VALUE="${2:-}"

if [ -z "$TARGET_ISSUE" ] || [ -z "$STATUS_VALUE" ]; then
  echo "Uso: scripts/project-status-sync.sh <issue_numero_ou_url> <status_value>"
  echo "Exemplo: scripts/project-status-sync.sh 21 \"In Progress\""
  exit 0
fi

# Localiza PROJECT_CONTEXT.md
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTEXT_FILE="${PROJECT_CONTEXT_PATH:-"$SCRIPT_DIR/../../PROJECT_CONTEXT.md"}"

if [ ! -f "$CONTEXT_FILE" ]; then
  echo "[INFO] PROJECT_CONTEXT.md não encontrado ($CONTEXT_FILE). Ignorando sincronização."
  exit 0
fi

# Extração de configurações de GitHub Projects v2
extract_context_val() {
  local key="$1"
  grep -E "^\s*-\s*\*\*$key\*\*:" "$CONTEXT_FILE" 2>/dev/null | head -n 1 | sed -E 's/.*:\s*"?([^"#]*)"?.*/\1/' | tr -d '\r' | xargs || true
}

OWNER=$(extract_context_val "Owner")
PROJECT_NUM=$(extract_context_val "Project Number")
STATUS_FIELD=$(extract_context_val "Status Field")

if [ -z "$STATUS_FIELD" ] || [ "$STATUS_FIELD" = "None" ]; then
  STATUS_FIELD="Status"
fi

if [ -z "$OWNER" ] || [ "$OWNER" = "None" ] || [ -z "$PROJECT_NUM" ] || [ "$PROJECT_NUM" = "None" ]; then
  echo "[INFO] GitHub Project v2 não configurado ou inativo em PROJECT_CONTEXT.md. Ignorando sincronização."
  exit 0
fi

# Resolução da URL da Issue
if [[ "$TARGET_ISSUE" =~ ^https?:// ]]; then
  ISSUE_URL="$TARGET_ISSUE"
else
  CLEAN_NUM="${TARGET_ISSUE#\#}"
  REPO_URL=$(gh repo view --json url -q .url 2>/dev/null || true)
  if [ -z "$REPO_URL" ]; then
    # Fallback via git remote
    REMOTE=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [[ "$REMOTE" =~ github\.com[:/]([^/]+)/([^/\.]+)(\.git)?$ ]]; then
      REPO_OWNER="${BASH_REMATCH[1]}"
      REPO_NAME="${BASH_REMATCH[2]}"
      REPO_URL="https://github.com/$REPO_OWNER/$REPO_NAME"
    fi
  fi

  if [ -n "$REPO_URL" ]; then
    ISSUE_URL="${REPO_URL}/issues/${CLEAN_NUM}"
  else
    ISSUE_URL="$CLEAN_NUM"
  fi
fi

# Execução com Degradação Graciosa (Non-Blocking)
ERR_LOG=$(mktemp)
trap 'rm -f "$ERR_LOG"' EXIT

if gh project item-edit "$PROJECT_NUM" --owner "$OWNER" --url "$ISSUE_URL" --field "$STATUS_FIELD" --value "$STATUS_VALUE" >/dev/null 2>"$ERR_LOG"; then
  echo "[OK] Status da issue $ISSUE_URL atualizado para '$STATUS_VALUE' no GitHub Project $PROJECT_NUM ($OWNER)."
  exit 0
else
  ERR_MSG=$(tr '\n' ' ' < "$ERR_LOG" | xargs || echo "Erro desconhecido")
  echo "⚠️ [WARN] Falha não-bloqueante ao atualizar status no GitHub Projects v2: $ERR_MSG"
  exit 0
fi
