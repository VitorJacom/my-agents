#!/usr/bin/env bash
# safety-guard.sh: PreToolUse interceptor para comandos potencialmente perigosos

set -euo pipefail

# Lê o input JSON do hook fornecido pelo Antigravity na stdin
INPUT_JSON=$(cat)

# Extrai o comando se a tool chamada for run_command
COMMAND=$(echo "$INPUT_JSON" | grep -o '"CommandLine":\s*"[^"]*"' | sed -E 's/"CommandLine":\s*"(.*)"/\1/' || echo "")

if [ -n "$COMMAND" ]; then
  # 1. Bloqueia comandos destrutivos sistêmicos ou de deleção em massa sem escopo
  if echo "$COMMAND" | grep -E -q '(rm\s+-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*\s+(/|~|\$HOME|\*|\.\.))|(mkfs|dd\s+if=)|(:[()]{2}\s*\{)'; then
    echo "[ERRO DE SEGURANÇA]: Execução bloqueada pelo plugin my-agents." >&2
    echo "Motivo: Comando com potencial destrutivo de sistema detectado: '$COMMAND'." >&2
    echo "Se for necessária deleção, execute manualmente ou utilize caminhos restritos ao projeto." >&2
    exit 1
  fi

  # 2. Bloqueia leitura/impressão deliberada de arquivos de chave privada ou secrets críticos
  if echo "$COMMAND" | grep -E -q '(cat|less|more|tail|head|grep)\s+.*(\.ssh/|id_rsa|id_ed25519|\.aws/credentials)'; then
    echo "[ERRO DE SEGURANÇA]: Acesso bloqueado pelo plugin my-agents." >&2
    echo "Motivo: Tentativa de expor chaves SSH ou credenciais críticas na saída do terminal." >&2
    exit 1
  fi
fi

exit 0
