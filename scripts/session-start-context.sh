#!/usr/bin/env bash
# session-start-context.sh: Injeta resumo do PROJECT_CONTEXT.md no início da sessão do chat (SessionStart Hook)

set -euo pipefail

# Lê o input JSON fornecido pelo Antigravity na stdin
INPUT_JSON=$(cat 2>/dev/null || echo "{}")

# Extrai o caminho do workspace primário via python/sed
WORKSPACE_PATH=$(echo "$INPUT_JSON" | grep -o '"workspacePaths":\s*\[[^]]*\]' | grep -o '"[^"]*"' | head -n 2 | tail -n 1 | tr -d '"' || echo "")

if [ -z "$WORKSPACE_PATH" ] || [ ! -d "$WORKSPACE_PATH" ]; then
  WORKSPACE_PATH=$(pwd)
fi

CONTEXT_FILE="${WORKSPACE_PATH}/PROJECT_CONTEXT.md"
MESSAGE=""

if [ -f "$CONTEXT_FILE" ]; then
  # Lê até as primeiras 40 linhas do PROJECT_CONTEXT.md para manter o consumo abaixo de 300 tokens
  SNIPPET=$(head -n 40 "$CONTEXT_FILE" | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
  MESSAGE="📌 [PROJECT CONTEXT CARREGADO AUTOMATICAMENTE - ZERO TOKEN WASTE]\n\n${SNIPPET}\n---\n*Orientações*: Proibido varrer o repositório cegamente. Respeite as estruturas canônicas e as regras do Duplo Gate."
else
  MESSAGE="📌 [SESSION START]: Nenhum PROJECT_CONTEXT.md detectado na raiz do workspace (${WORKSPACE_PATH}). Recomenda-se inicializar o arquivo canônico de contexto para economizar tokens."
fi

# Emite o payload JSON esperado pelo contrato SessionStart do Antigravity
cat <<EOF
{
  "injectSteps": [
    {
      "systemMessage": {
        "systemMessage": "${MESSAGE}"
      }
    }
  ]
}
EOF
exit 0
