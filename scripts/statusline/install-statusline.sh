#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# install-statusline.sh: Injetor e configurador automatizado da Statusline
# no Antigravity CLI (~/.gemini/antigravity-cli/settings.json)
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SETTINGS_PATH="${ANTIGRAVITY_SETTINGS_PATH:-"$HOME/.gemini/antigravity-cli/settings.json"}"
DEFAULT_SCRIPT_PATH="${STATUSLINE_SCRIPT_PATH:-"$SCRIPT_DIR/statusline-quota.sh"}"

SETTINGS_PATH="$DEFAULT_SETTINGS_PATH"
TARGET_SCRIPT="$DEFAULT_SCRIPT_PATH"
DRY_RUN="false"

show_help() {
  cat << EOF
Uso: $(basename "$0") [OPÇÕES]

Configura e injeta automaticamente a statusline do my-agents no Antigravity CLI.

Opções:
  --settings-path <caminho>  Caminho customizado do arquivo settings.json
                             (ou defina a variável ANTIGRAVITY_SETTINGS_PATH)
  --script-path <caminho>    Caminho customizado do script de statusline
                             (padrão: scripts/statusline/statusline-quota.sh)
  --dry-run                  Simula as alterações sem gravar no disco
  -h, --help                 Exibe esta mensagem de ajuda
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --settings-path=*)
      SETTINGS_PATH="${1#*=}"
      shift
      ;;
    --settings-path)
      if [[ -z "${2:-}" ]]; then
        echo "Erro: --settings-path requer um argumento." >&2
        exit 1
      fi
      SETTINGS_PATH="$2"
      shift 2
      ;;
    --script-path=*)
      TARGET_SCRIPT="${1#*=}"
      shift
      ;;
    --script-path)
      if [[ -z "${2:-}" ]]; then
        echo "Erro: --script-path requer um argumento." >&2
        exit 1
      fi
      TARGET_SCRIPT="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Erro: Parâmetro desconhecido: $1" >&2
      show_help
      exit 1
      ;;
  esac
done

# Normalizar caminhos absolutos se o script existir
if [ -f "$TARGET_SCRIPT" ]; then
  TARGET_SCRIPT="$(cd "$(dirname "$TARGET_SCRIPT")" && pwd)/$(basename "$TARGET_SCRIPT")"
  chmod +x "$TARGET_SCRIPT"
fi

# Injetor JSON via Python (idempotente e seguro)
python3 - "$SETTINGS_PATH" "$TARGET_SCRIPT" "$DRY_RUN" << 'EOF'
import json
import os
import shutil
import sys

settings_path = sys.argv[1]
target_script = sys.argv[2]
dry_run = (sys.argv[3].lower() == "true")

data = {}
existing_content = ""
file_exists = os.path.exists(settings_path)

if file_exists:
    with open(settings_path, "r", encoding="utf-8") as f:
        existing_content = f.read()
        stripped = existing_content.strip()
        if stripped:
            try:
                data = json.loads(stripped)
            except Exception as e:
                print(f"[ERRO] Falha ao interpretar JSON existente em {settings_path}: {e}", file=sys.stderr)
                sys.exit(1)

# Garante que statusLine seja um dict preservando atributos pré-existentes
status_line = data.get("statusLine")
if not isinstance(status_line, dict):
    status_line = {}

status_line["type"] = "command"
status_line["command"] = target_script
status_line["enabled"] = True
data["statusLine"] = status_line

new_content = json.dumps(data, indent=2, ensure_ascii=False) + "\n"

# Idempotência: se o conteúdo não sofreu alteração, nada precisa ser gravado
if file_exists and existing_content.strip() == new_content.strip():
    print(f"[INFO] Statusline já está perfeitamente configurada em {settings_path}. Nenhuma modificação necessária.")
    sys.exit(0)

if dry_run:
    print(f"[DRY-RUN] Modificações previstas para {settings_path}:")
    print(new_content)
    sys.exit(0)

# Garante a existência do diretório pai
parent_dir = os.path.dirname(settings_path)
if parent_dir and not os.path.exists(parent_dir):
    os.makedirs(parent_dir, exist_ok=True)

# Backup de segurança antes de qualquer modificação
if file_exists:
    backup_path = f"{settings_path}.bak"
    shutil.copy2(settings_path, backup_path)
    print(f"[BACKUP] Cópia de segurança criada em: {backup_path}")

# Gravação atômica via arquivo temporário
tmp_path = f"{settings_path}.tmp.{os.getpid()}"
with open(tmp_path, "w", encoding="utf-8") as f:
    f.write(new_content)
os.replace(tmp_path, settings_path)

print(f"[SUCESSO] Statusline injetada com êxito em: {settings_path}")
print(f"          Comando: {target_script}")
EOF

# Garante permissão de execução após a injeção
if [ -f "$TARGET_SCRIPT" ]; then
  chmod +x "$TARGET_SCRIPT"
fi
