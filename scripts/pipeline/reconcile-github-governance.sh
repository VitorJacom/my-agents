#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# scripts/reconcile-github-governance.sh - GitHub Governance Reconciler
# Reconciliação idempotente de Milestones e Projects v2 para issues abertas
# =============================================================================

DRY_RUN=false
REPO=""
CONTEXT_FILE="${PROJECT_CONTEXT_PATH:-}"

usage() {
  cat <<'EOF'
Uso: scripts/reconcile-github-governance.sh [OPÇÕES]

Opções:
  --dry-run               Simula as alterações sem executá-las via GitHub CLI
  --repo, -R <owner/repo> Especifica o repositório GitHub alvo
  --context-file <path>   Caminho para o arquivo PROJECT_CONTEXT.md
  -h, --help              Exibe esta mensagem de ajuda
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --repo=*)
      REPO="${1#*=}"
      shift
      ;;
    -R)
      REPO="$2"
      shift 2
      ;;
    -R=*)
      REPO="${1#*=}"
      shift
      ;;
    --context-file)
      CONTEXT_FILE="$2"
      shift 2
      ;;
    --context-file=*)
      CONTEXT_FILE="${1#*=}"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Opção inválida ou desconhecida: $1" >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -z "$CONTEXT_FILE" ]; then
  CONTEXT_FILE="$SCRIPT_DIR/../PROJECT_CONTEXT.md"
fi

if [ ! -f "$CONTEXT_FILE" ]; then
  echo "[INFO] PROJECT_CONTEXT.md não encontrado ($CONTEXT_FILE). Ignorando reconciliação."
  exit 0
fi

extract_context_val() {
  local key="$1"
  grep -E "^\s*-\s*\*\*$key\*\*:" "$CONTEXT_FILE" 2>/dev/null | head -n 1 | sed -E 's/^\s*-\s*\*\*[^*]+\*\*:\s*"?([^"#]*)"?.*/\1/' | tr -d '\r' | xargs || true
}

ACTIVE_EPIC=$(extract_context_val "Active Epic \(Milestone\)")
if [ -z "$ACTIVE_EPIC" ]; then
  ACTIVE_EPIC=$(extract_context_val "Active Milestone")
fi
ACTIVE_MILESTONE="$ACTIVE_EPIC"
OWNER=$(extract_context_val "Owner")
PROJECT_NUM=$(extract_context_val "Project Number")
RELEASE_FIELD=$(extract_context_val "Release Field")
DEFAULT_RELEASE=$(extract_context_val "Default Release")

# Normalização de valores None ou vazios
if [ "$ACTIVE_MILESTONE" = "None" ] || [ "$ACTIVE_MILESTONE" = "none" ] || [ "$ACTIVE_MILESTONE" = "null" ]; then
  ACTIVE_MILESTONE=""
fi

if [ "$OWNER" = "None" ] || [ "$OWNER" = "none" ] || [ "$OWNER" = "null" ]; then
  OWNER=""
fi

if [ "$PROJECT_NUM" = "None" ] || [ "$PROJECT_NUM" = "none" ] || [ "$PROJECT_NUM" = "null" ]; then
  PROJECT_NUM=""
fi

if [ "$RELEASE_FIELD" = "None" ] || [ "$RELEASE_FIELD" = "none" ] || [ "$RELEASE_FIELD" = "null" ]; then
  RELEASE_FIELD=""
fi

if [ "$DEFAULT_RELEASE" = "None" ] || [ "$DEFAULT_RELEASE" = "none" ] || [ "$DEFAULT_RELEASE" = "null" ]; then
  DEFAULT_RELEASE=""
fi

GH_REPO_ARGS=()
if [ -n "$REPO" ]; then
  GH_REPO_ARGS=(--repo "$REPO")
fi

parse_issues() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    if not isinstance(data, list):
        data = []
    for item in data:
        num = item.get("number", "")
        m = item.get("milestone")
        m_title = m.get("title", "") if isinstance(m, dict) else (m or "")
        url = item.get("url", "")
        title = item.get("title", "")
        print(f"{num}\x1f{m_title}\x1f{url}\x1f{title}")
except Exception:
    sys.exit(0)
'
  elif command -v jq >/dev/null 2>&1; then
    jq -r '.[] | "\(.number)\u001f\(.milestone.title // "")\u001f\(.url // "")\u001f\(.title // "")"' 2>/dev/null || true
  fi
}

ISSUES_JSON=$(gh issue list "${GH_REPO_ARGS[@]}" --state open --json number,title,milestone,url --limit 100 2>/dev/null || echo "[]")
ISSUES_DATA=$(echo "$ISSUES_JSON" | parse_issues)

if [ -z "$ISSUES_DATA" ]; then
  echo "[INFO] Nenhuma issue aberta encontrada para reconciliação."
  exit 0
fi

while IFS=$'\x1f' read -r NUM MILESTONE_TITLE URL TITLE; do
  [ -z "$NUM" ] && continue

  # 1. Reconciliação de Milestone
  if [ -n "$ACTIVE_MILESTONE" ]; then
    if [ -z "$MILESTONE_TITLE" ]; then
      if [ "$DRY_RUN" = "true" ]; then
        echo "[DRY-RUN] Atribuindo milestone '$ACTIVE_MILESTONE' à issue #$NUM"
      else
        gh issue edit "$NUM" --milestone "$ACTIVE_MILESTONE" "${GH_REPO_ARGS[@]}"
        echo "[OK] Issue #$NUM associada à milestone '$ACTIVE_MILESTONE'."
      fi
    elif [ "$MILESTONE_TITLE" = "$ACTIVE_MILESTONE" ]; then
      echo "[OK] Issue #$NUM já associada à milestone '$ACTIVE_MILESTONE' (idempotente)."
    else
      echo "[INFO] Issue #$NUM já possui milestone '$MILESTONE_TITLE' (diferente de '$ACTIVE_MILESTONE'). Mantendo."
    fi
  else
    echo "[INFO] Nenhuma milestone ativa configurada em PROJECT_CONTEXT.md. Pulando reconciliação de milestone."
  fi

  # 2. Reconciliação de GitHub Project v2 (Resiliente com fallback não-bloqueante)
  if [ -n "$OWNER" ] && [ -n "$PROJECT_NUM" ]; then
    TARGET_URL="$URL"
    if [ -z "$TARGET_URL" ]; then
      if [ -n "$REPO" ]; then
        TARGET_URL="https://github.com/$REPO/issues/$NUM"
      else
        TARGET_URL="$NUM"
      fi
    fi

    if [ "$DRY_RUN" = "true" ]; then
      echo "[DRY-RUN] Adicionando issue #$NUM ao Project v2 $PROJECT_NUM ($OWNER) via URL: $TARGET_URL"
      if [ -n "$RELEASE_FIELD" ] && [ -n "$DEFAULT_RELEASE" ]; then
        echo "[DRY-RUN] Atribuindo campo $RELEASE_FIELD '$DEFAULT_RELEASE' à issue #$NUM no Project v2 $PROJECT_NUM"
      fi
    else
      if gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$TARGET_URL" >/dev/null 2>&1; then
        echo "[OK] Issue #$NUM adicionada ao Project v2 ($PROJECT_NUM)."
      else
        echo "⚠️ [WARN] Falha não-bloqueante ao adicionar issue #$NUM ao Project v2 ($PROJECT_NUM)."
      fi

      if [ -n "$RELEASE_FIELD" ] && [ -n "$DEFAULT_RELEASE" ]; then
        if gh project item-edit "$PROJECT_NUM" --owner "$OWNER" --url "$TARGET_URL" --field "$RELEASE_FIELD" --value "$DEFAULT_RELEASE" >/dev/null 2>&1; then
          echo "[OK] Campo $RELEASE_FIELD configurado como '$DEFAULT_RELEASE' para issue #$NUM no Project v2."
        else
          echo "⚠️ [WARN] Falha não-bloqueante ao atualizar campo $RELEASE_FIELD para issue #$NUM no Project v2 ($PROJECT_NUM)."
        fi
      fi
    fi
  else
    echo "[INFO] GitHub Project v2 não configurado ou inativo em PROJECT_CONTEXT.md. Pulando adição ao Project v2."
  fi

done <<< "$ISSUES_DATA"

echo "[OK] Reconciliação de governança concluída com sucesso."
exit 0
