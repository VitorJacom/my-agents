#!/usr/bin/env bash
# statusline-quota.sh: Renderizador de statusline customizado para o Antigravity CLI

INPUT_JSON=$(cat 2>/dev/null || echo "{}")

# 1. Detectar o modelo ativo e reasoning effort:
# Tenta primeiro via payload JSON do agy, caso contrário lê do settings.json
MODEL_NAME=$(echo "$INPUT_JSON" | grep -o '"display_name":\s*"[^"]*"' | head -n 1 | sed -E 's/"display_name":\s*"(.*)"/\1/' || echo "")

if [ -z "$MODEL_NAME" ]; then
  MODEL_NAME=$(echo "$INPUT_JSON" | grep -o '"model":\s*"[^"]*"' | head -n 1 | sed -E 's/"model":\s*"(.*)"/\1/' || echo "")
fi

# Fallback para ~/.gemini/antigravity-cli/settings.json
if [ -z "$MODEL_NAME" ]; then
  SETTINGS_FILE="$HOME/.gemini/antigravity-cli/settings.json"
  if [ -f "$SETTINGS_FILE" ]; then
    MODEL_NAME=$(grep -o '"model":\s*"[^"]*"' "$SETTINGS_FILE" | head -n 1 | sed -E 's/"model":\s*"(.*)"/\1/' || echo "")
  fi
fi

[ -z "$MODEL_NAME" ] && MODEL_NAME="Gemini 3.8 Flash (Low)"

# 2. Cores ANSI
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
MAGENTA="\033[35m"
BLUE="\033[34m"
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# 3. Contexto Git
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
BRANCH_INFO=""
if [ -n "$BRANCH" ]; then
  BRANCH_INFO="${BLUE}🌿 ${BOLD}${BRANCH}${RESET} │ "
fi

# 4. Dados de Quota
QUOTA_5H=$(echo "$INPUT_JSON" | grep -o '"used_percentage":\s*[0-9.]*' | head -n 1 | awk '{print $2}' || echo "")
QUOTA_WEEK=$(echo "$INPUT_JSON" | grep -o '"used_percentage":\s*[0-9.]*' | tail -n 1 | awk '{print $2}' || echo "")

COLOR_5H=$GREEN
COLOR_WEEK=$GREEN

if [ -n "$QUOTA_5H" ]; then
  VAL_5H=$(printf "%.0f" "$QUOTA_5H" 2>/dev/null || echo 0)
  [ "$VAL_5H" -ge 50 ] && COLOR_5H=$YELLOW
  [ "$VAL_5H" -ge 80 ] && COLOR_5H=$RED
  TEXT_5H="${COLOR_5H}${VAL_5H}%${RESET}"
else
  TEXT_5H="${CYAN}ok${RESET}"
fi

if [ -n "$QUOTA_WEEK" ]; then
  VAL_WEEK=$(printf "%.0f" "$QUOTA_WEEK" 2>/dev/null || echo 0)
  [ "$VAL_WEEK" -ge 50 ] && COLOR_WEEK=$YELLOW
  [ "$VAL_WEEK" -ge 80 ] && COLOR_WEEK=$RED
  TEXT_WEEK="${COLOR_WEEK}${VAL_WEEK}%${RESET}"
else
  TEXT_WEEK="${CYAN}ok${RESET}"
fi

# 5. Saída estilizada preservando o Modelo
echo -e "${BRANCH_INFO}${MAGENTA}🤖 ${MODEL_NAME}${RESET} │ ⚡ Quota 5h: [${TEXT_5H}] │ 📅 Semanal: [${TEXT_WEEK}]"
