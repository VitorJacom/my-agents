#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# scripts/migrate-issues-to-project.sh - Full Backlog & Issue Migration
# Migra issues abertas e históricas fechadas para Milestones e GitHub Project v2
# =============================================================================

DRY_RUN=false
REPO="VitorJacom/my-agents"
PROJECT_NUM=1
OWNER="VitorJacom"

usage() {
  cat <<'EOF'
Uso: scripts/migrate-issues-to-project.sh [OPÇÕES]

Opções:
  --dry-run               Simula todas as operações sem alterar GitHub issues ou Project
  --repo, -R <owner/repo> Repositório alvo (padrão: VitorJacom/my-agents)
  --project <number>      Número do GitHub Project v2 (padrão: 1)
  --owner <user/org>      Proprietário do GitHub Project (padrão: VitorJacom)
  -h, --help              Exibe esta ajuda
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --repo|-R)
      REPO="$2"
      shift 2
      ;;
    --project)
      PROJECT_NUM="$2"
      shift 2
      ;;
    --owner)
      OWNER="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Opção desconhecida: $1" >&2
      exit 1
      ;;
  esac
done

echo "====================================================================="
echo " 🚀 Iniciando Migração de Issues -> Milestones & GitHub Project v2"
echo " Repositório: $REPO | Project: #$PROJECT_NUM (@$OWNER) | Dry-Run: $DRY_RUN"
echo "====================================================================="

# 1. Pre-flight Check de autenticação e escopos
echo "[1/4] Verificando autenticação e escopos do GitHub CLI..."
AUTH_STATUS=$(gh auth status 2>&1 || true)
if ! echo "$AUTH_STATUS" | grep -q "Logged in to github.com"; then
  echo "❌ [ERRO] Não autenticado no GitHub CLI. Execute 'gh auth login' primeiro." >&2
  exit 1
fi

if ! echo "$AUTH_STATUS" | grep -E -q "'project'|read:project"; then
  echo "⚠️ [AVISO] O escopo 'project' não foi detectado no token atual."
  echo "Para conceder acesso, execute: gh auth refresh -s project"
fi

# 2. Resolução de Milestones canônicas
echo "[2/4] Validando Milestones existentes no repositório..."
MILESTONES_JSON=$(gh api "repos/$REPO/milestones?state=all" --paginate 2>/dev/null || echo "[]")

has_milestone() {
  local title="$1"
  python3 -c "
import json, sys
data = json.loads('''$MILESTONES_JSON''')
found = any(m.get('title') == sys.argv[1] for m in data)
sys.exit(0 if found else 1)
" "$title" 2>/dev/null
}

MILESTONE_FOUNDATION="v1.0.0 - Foundation & AIDD Core"
MILESTONE_ACTIVE="v1.1.0"
MILESTONE_WIKI="v1.2.0 - Documentation & Wiki Governance"

if ! has_milestone "$MILESTONE_FOUNDATION"; then
  if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY-RUN] Criaria Milestone '$MILESTONE_FOUNDATION'"
  else
    echo "Criando Milestone '$MILESTONE_FOUNDATION'..."
    gh api "repos/$REPO/milestones" -X POST \
      -f title="$MILESTONE_FOUNDATION" \
      -f description="Marcos fundamentais de arquitetura, governança AIDD e automações core." >/dev/null
  fi
fi

# 3. Listagem de todas as issues (abertas e fechadas)
echo "[3/4] Coletando todas as issues de $REPO..."
ISSUES_JSON=$(gh issue list --repo "$REPO" --state all --limit 200 --json number,title,state,milestone,url)
echo "$ISSUES_JSON" > issues_tmp.json

# 4. Migração e reconciliação item a item
echo "[4/4] Executando migração determinística de issues..."

# Carregar lista de itens já presentes no projeto para evitar chamadas redundantes
EXISTING_PROJECT_URLS=$(gh project item-list "$PROJECT_NUM" --owner "$OWNER" --format json 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    urls = [it.get("content", {}).get("url") for it in data.get("items", []) if it.get("content")]
    print("\n".join(filter(None, urls)))
except Exception:
    pass
' || true)

python3 -c '
import json, subprocess, sys

dry_run = sys.argv[1] == "true"
repo = sys.argv[2]
project_num = sys.argv[3]
owner = sys.argv[4]
existing_urls = set(sys.argv[5].splitlines())

with open("issues_tmp.json") as f:
    issues = json.load(f)

print(f"Total de issues para processar: {len(issues)}")

# Categorização de Milestones
# - Issues fechadas legadas sem milestone -> v1.0.0
# - Issues ativas documentais (24, 25, 26, 27) -> v1.2.0
# - Demais issues abertas -> v1.1.0
wiki_issues = {24, 25, 26, 27}
in_review_issues = {24, 25, 26, 27, 46} # Vinculadas ao PR #50 aberto

for issue in sorted(issues, key=lambda x: x["number"]):
    num = issue["number"]
    title = issue["title"]
    state = issue["state"]
    url = issue["url"]
    current_m = issue.get("milestone")
    current_m_title = current_m.get("title") if current_m else None

    # Determinar Milestone Alvo
    target_milestone = None
    if current_m_title:
        target_milestone = current_m_title # Preserva se já atribuída
    else:
        if state == "CLOSED":
            target_milestone = "v1.0.0 - Foundation & AIDD Core"
        elif num in wiki_issues:
            target_milestone = "v1.2.0 - Documentation & Wiki Governance"
        else:
            target_milestone = "v1.1.0"

    # Determinar Status no Project v2
    if state == "CLOSED":
        target_status = "Done"
    elif num in in_review_issues:
        target_status = "In Review"
    else:
        target_status = "Planned"

    print(f"\n👉 Issue #{num} [{state}]: {title[:50]}...")
    
    # 4.1. Atualizar Milestone se necessário
    if current_m_title != target_milestone:
        print(f"  [Milestone] Associando a \"{target_milestone}\" (era: {current_m_title})")
        if not dry_run:
            cmd = ["gh", "issue", "edit", str(num), "--repo", repo, "--milestone", target_milestone]
            res = subprocess.run(cmd, capture_output=True, text=True)
            if res.returncode != 0:
                print(f"  ⚠️ Falha ao editar milestone da issue #{num}: {res.stderr.strip()}")
    else:
        print(f"  [Milestone] Já associada a \"{target_milestone}\" (OK)")

    # 4.2. Adicionar ao Project v2 se ainda não estiver
    if url not in existing_urls:
        print(f"  [Project v2] Adicionando ao Project #{project_num}...")
        if not dry_run:
            cmd = ["gh", "project", "item-add", str(project_num), "--owner", owner, "--url", url]
            res = subprocess.run(cmd, capture_output=True, text=True)
            if res.returncode == 0:
                existing_urls.add(url)
            else:
                print(f"  ⚠️ Falha ao adicionar item ao project #{num}: {res.stderr.strip()}")
    else:
        print(f"  [Project v2] Já presente no Project #{project_num} (OK)")

    # 4.3. Atualizar Status no Project v2
    print(f"  [Project Status] Definindo Status -> \"{target_status}\"")
    if not dry_run:
        cmd = ["gh", "project", "item-edit", str(project_num), "--owner", owner, "--url", url, "--field", "Status", "--value", target_status]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"  ⚠️ Falha ao definir status no Project v2 para #{num}: {res.stderr.strip()}")

print("\n✨ Processamento de issues finalizado.")
' "$DRY_RUN" "$REPO" "$PROJECT_NUM" "$OWNER" "$EXISTING_PROJECT_URLS"

rm -f issues_tmp.json 2>/dev/null || true

echo "====================================================================="
echo " ✅ Migração concluída com sucesso!"
echo " Acesse o projeto em: https://github.com/users/$OWNER/projects/$PROJECT_NUM"
echo "====================================================================="
