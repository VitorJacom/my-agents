#!/usr/bin/env bash
# statusline-quota.sh: Renderizador modular de statusline para o Antigravity CLI
set -euo pipefail

# ANSI Colors
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
MAGENTA="\033[35m"
BLUE="\033[34m"
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Variável global para armazenar o payload recebido do stdin
INPUT_JSON="{}"

# -----------------------------------------------------------------------------
# Widget 1: Git Branch / VCS
# -----------------------------------------------------------------------------
widget_git() {
  local branch=""
  # Tenta primeiro extrair do payload JSON (campo vcs/branch)
  if [[ "$INPUT_JSON" =~ \"branch\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
    branch="${BASH_REMATCH[1]}"
  fi

  # Fallback: inspeciona o repositório Git local de forma ultrarrápida
  if [ -z "$branch" ]; then
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  fi

  # Trata detached HEAD
  if [ "$branch" = "HEAD" ]; then
    branch=$(git rev-parse --short HEAD 2>/dev/null || true)
  fi

  if [ -n "$branch" ]; then
    printf "${BLUE}🌿 ${BOLD}%s${RESET}" "$branch"
  fi
}

# -----------------------------------------------------------------------------
# Widget 2: Modelo Ativo e Reasoning Effort
# -----------------------------------------------------------------------------
widget_model() {
  local model=""
  # Tenta extrair display_name ou model do payload JSON
  if [[ "$INPUT_JSON" =~ \"display_name\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
    model="${BASH_REMATCH[1]}"
  fi
  if [ -z "$model" ] && [[ "$INPUT_JSON" =~ \"model\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
    model="${BASH_REMATCH[1]}"
  fi

  # Fallback para ~/.gemini/antigravity-cli/settings.json
  if [ -z "$model" ]; then
    local settings_file="$HOME/.gemini/antigravity-cli/settings.json"
    if [ -f "$settings_file" ]; then
      local settings_content
      settings_content=$(< "$settings_file" 2>/dev/null || true)
      if [[ "$settings_content" =~ \"model\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
        model="${BASH_REMATCH[1]}"
      fi
    fi
  fi

  # Default seguro e elegante
  if [ -z "$model" ] || [ "$model" = "null" ]; then
    model="Gemini 3.8 Flash (Low)"
  fi

  printf "${MAGENTA}🤖 %s${RESET}" "$model"
}

# -----------------------------------------------------------------------------
# Widget 3: Quota (5 Horas e Semanal) com Alerta Visual
# -----------------------------------------------------------------------------
widget_quota() {
  local q_5h=""
  local q_week=""

  # Extrai até duas ocorrências de used_percentage (5h e Semanal)
  if [[ "$INPUT_JSON" =~ \"used_percentage\"[[:space:]]*:[[:space:]]*([0-9.]+) ]]; then
    q_5h="${BASH_REMATCH[1]}"
    local rest="${INPUT_JSON#*${BASH_REMATCH[0]}}"
    if [[ "$rest" =~ \"used_percentage\"[[:space:]]*:[[:space:]]*([0-9.]+) ]]; then
      q_week="${BASH_REMATCH[1]}"
    fi
  fi

  # Formatação da quota de 5 horas
  local text_5h
  if [ -n "$q_5h" ]; then
    local val_5h
    val_5h=$(printf "%.0f" "$q_5h" 2>/dev/null || echo "")
    if [ -n "$val_5h" ]; then
      local col_5h=$GREEN
      [ "$val_5h" -ge 50 ] 2>/dev/null && col_5h=$YELLOW
      [ "$val_5h" -ge 80 ] 2>/dev/null && col_5h=$RED
      text_5h="${col_5h}${val_5h}%${RESET}"
    else
      text_5h="${CYAN}ok${RESET}"
    fi
  else
    text_5h="${CYAN}ok${RESET}"
  fi

  # Formatação da quota semanal
  local text_week
  if [ -n "$q_week" ]; then
    local val_week
    val_week=$(printf "%.0f" "$q_week" 2>/dev/null || echo "")
    if [ -n "$val_week" ]; then
      local col_week=$GREEN
      [ "$val_week" -ge 50 ] 2>/dev/null && col_week=$YELLOW
      [ "$val_week" -ge 80 ] 2>/dev/null && col_week=$RED
      text_week="${col_week}${val_week}%${RESET}"
    else
      text_week="${CYAN}ok${RESET}"
    fi
  else
    text_week="${CYAN}ok${RESET}"
  fi

  printf "⚡ Quota 5h: [%s] │ 📅 Semanal: [%s]" "$text_5h" "$text_week"
}

# -----------------------------------------------------------------------------
# Widget 4: Telemetria (Tokens da Sessão e Custo)
# -----------------------------------------------------------------------------
widget_telemetry() {
  local tokens=""
  if [[ "$INPUT_JSON" =~ \"total_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
    tokens="${BASH_REMATCH[1]}"
  elif [[ "$INPUT_JSON" =~ \"tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
    tokens="${BASH_REMATCH[1]}"
  fi

  local usd=""
  if [[ "$INPUT_JSON" =~ \"total_usd\"[[:space:]]*:[[:space:]]*([0-9.]+) ]]; then
    usd="${BASH_REMATCH[1]}"
  fi

  local display="0 tok"
  if [ -n "$tokens" ] && [ "$tokens" -gt 0 ] 2>/dev/null; then
    if [ "$tokens" -ge 1000 ]; then
      display="$(( tokens / 1000 ))k tok"
    else
      display="${tokens} tok"
    fi
  fi

  if [ -n "$usd" ]; then
    display="${display} (\$${usd})"
  fi

  printf "${CYAN}📊 %s${RESET}" "$display"
}

# -----------------------------------------------------------------------------
# Renderizador Principal de Statusline
# -----------------------------------------------------------------------------
render_statusline() {
  local parts=()
  local w_git
  w_git=$(widget_git 2>/dev/null || true)
  [ -n "$w_git" ] && parts+=("$w_git")

  parts+=("$(widget_model 2>/dev/null || printf "${MAGENTA}🤖 Gemini 3.8 Flash (Low)${RESET}")")
  parts+=("$(widget_quota 2>/dev/null || printf "⚡ Quota 5h: [${CYAN}ok${RESET}] │ 📅 Semanal: [${CYAN}ok${RESET}]")")
  parts+=("$(widget_telemetry 2>/dev/null || printf "${CYAN}📊 0 tok${RESET}")")

  local result=""
  for i in "${!parts[@]}"; do
    if [ "$i" -eq 0 ]; then
      result="${parts[$i]}"
    else
      result="${result} │ ${parts[$i]}"
    fi
  done
  echo -e "$result"
}

# -----------------------------------------------------------------------------
# Ponto de Entrada (CLI Dispatcher)
# -----------------------------------------------------------------------------
main() {
  # Leitura resiliente do STDIN sem bloqueio interativo
  if [ -t 0 ]; then
    INPUT_JSON="{}"
  else
    INPUT_JSON=$(cat 2>/dev/null || echo "{}")
  fi
  [ -z "$INPUT_JSON" ] && INPUT_JSON="{}"

  # Dispatcher para widget isolado ou statusline completa
  if [ "${1:-}" = "--widget" ] && [ -n "${2:-}" ]; then
    case "$2" in
      git) widget_git ;;
      model) widget_model ;;
      quota) widget_quota ;;
      telemetry) widget_telemetry ;;
      *) render_statusline ;;
    esac
  else
    render_statusline
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
