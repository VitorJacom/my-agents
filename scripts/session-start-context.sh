#!/usr/bin/env bash
# session-start-context.sh: Injeta resumo do PROJECT_CONTEXT.md e metadados voláteis do Git em tempo real (SessionStart Hook)

set -euo pipefail

# Lê o input JSON fornecido pelo Antigravity na stdin
INPUT_JSON=$(cat 2>/dev/null || echo "{}")

# Extrai o caminho do workspace primário
WORKSPACE_PATH=$(printf '%s' "$INPUT_JSON" | grep -o '"workspacePaths":\s*\[[^]]*\]' | grep -o '"[^"]*"' | head -n 2 | tail -n 1 | tr -d '"' || echo "")

if [ -z "$WORKSPACE_PATH" ] || [ ! -d "$WORKSPACE_PATH" ]; then
  WORKSPACE_PATH=$(pwd)
fi

# Coleta dinâmica de metadados voláteis do Git (In-Memory / Read-Only)
LIVE_BRANCH=$(git -C "$WORKSPACE_PATH" branch --show-current 2>/dev/null || true)
if [ -z "$LIVE_BRANCH" ]; then
  LIVE_BRANCH="detached/none"
fi

LIVE_COMMIT=$(git -C "$WORKSPACE_PATH" log -1 --pretty=format:'%h - %s (%an)' 2>/dev/null || true)
if [ -z "$LIVE_COMMIT" ]; then
  LIVE_COMMIT="Sem commits registrados"
fi

LIVE_STATUS=$(git -C "$WORKSPACE_PATH" status --short 2>/dev/null || true)
if [ -z "$LIVE_STATUS" ]; then
  LIVE_STATUS="Working tree limpa"
fi

CONTEXT_FILE="${WORKSPACE_PATH}/PROJECT_CONTEXT.md"

python3 - "$CONTEXT_FILE" "$WORKSPACE_PATH" "$LIVE_BRANCH" "$LIVE_COMMIT" "$LIVE_STATUS" <<'PYEOF'
import json
import os
import sys

context_file, workspace_path, live_branch, live_commit, live_status = sys.argv[1:6]

live_git_block = (
    "## 📍 Estado Volátil do Git (Live SessionStart)\n"
    f"- **Branch Ativa**: `{live_branch}`\n"
    f"- **Último Commit**: `{live_commit}`\n"
    f"- **Status da Working Tree**:\n"
    f"```text\n{live_status}\n```"
)

if os.path.isfile(context_file):
    with open(context_file, "r", encoding="utf-8") as f:
        lines = [line.rstrip("\r\n") for line in f.readlines()[:40]]
    snippet = "\n".join(lines).strip()
    message = (
        "📌 [PROJECT CONTEXT CARREGADO AUTOMATICAMENTE - ZERO TOKEN WASTE]\n\n"
        f"{snippet}\n\n"
        f"{live_git_block}\n\n"
        "---\n"
        "*Orientações*: Proibido varrer o repositório cegamente. Respeite as estruturas canônicas e as regras do Duplo Gate."
    )
else:
    message = (
        f"📌 [SESSION START]: Nenhum PROJECT_CONTEXT.md detectado na raiz do workspace ({workspace_path}). "
        "Recomenda-se inicializar o arquivo canônico de contexto para economizar tokens.\n\n"
        f"{live_git_block}"
    )

payload = {
    "injectSteps": [
        {
            "systemMessage": {
                "systemMessage": message
            }
        }
    ]
}
print(json.dumps(payload, ensure_ascii=False, indent=2))
PYEOF
