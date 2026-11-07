#!/usr/bin/env bash
# statusline-quota.sh: Renderizador modular de statusline para o Antigravity CLI
set -euo pipefail

# ANSI Colors (usando ANSI-C quoting para emissão segura tanto individual quanto agregada)
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
MAGENTA=$'\033[35m'
BLUE=$'\033[34m'
RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'

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

  # Extração nominal de bucket 5h
  if [[ "$INPUT_JSON" =~ \"5h\"[^{}]*\"used_percentage\"[[:space:]]*:[[:space:]]*([0-9.]+) ]]; then
    q_5h="${BASH_REMATCH[1]}"
  elif [[ "$INPUT_JSON" =~ \"used_percentage\"[[:space:]]*:[[:space:]]*([0-9.]+)[^{}]*\"5h\" ]]; then
    q_5h="${BASH_REMATCH[1]}"
  fi

  # Extração nominal de bucket weekly/week
  if [[ "$INPUT_JSON" =~ \"week(ly)?\"[^{}]*\"used_percentage\"[[:space:]]*:[[:space:]]*([0-9.]+) ]]; then
    q_week="${BASH_REMATCH[2]}"
  elif [[ "$INPUT_JSON" =~ \"used_percentage\"[[:space:]]*:[[:space:]]*([0-9.]+)[^{}]*\"week(ly)?\" ]]; then
    q_week="${BASH_REMATCH[1]}"
  fi

  # Fallback sequencial caso não haja identificação explícita de nomes de buckets
  if [ -z "$q_5h" ] && [[ "$INPUT_JSON" =~ \"used_percentage\"[[:space:]]*:[[:space:]]*([0-9.]+) ]]; then
    q_5h="${BASH_REMATCH[1]}"
    local rest="${INPUT_JSON#*${BASH_REMATCH[0]}}"
    if [ -z "$q_week" ] && [[ "$rest" =~ \"used_percentage\"[[:space:]]*:[[:space:]]*([0-9.]+) ]]; then
      q_week="${BASH_REMATCH[1]}"
    fi
  fi

  # Formatação da quota de 5 horas com isolamento de locale (LC_ALL=C LC_NUMERIC=C)
  local text_5h
  if [ -n "$q_5h" ]; then
    local val_5h
    val_5h=$(LC_ALL=C LC_NUMERIC=C printf "%.0f" "$q_5h" 2>/dev/null || echo "")
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

  # Formatação da quota semanal com isolamento de locale (LC_ALL=C LC_NUMERIC=C)
  local text_week
  if [ -n "$q_week" ]; then
    local val_week
    val_week=$(LC_ALL=C LC_NUMERIC=C printf "%.0f" "$q_week" 2>/dev/null || echo "")
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
# Widget 4: Informação Volátil de Atividade & Contexto (Idle vs Tarefa)
# Em "idle": exibe porcentagem de /context utilizado (🧠 Context: X%)
# Em "tarefa": exibe porcentagem aproximada restante (⏳ Falta: Y%)
# -----------------------------------------------------------------------------
widget_telemetry() {
  local is_running=false
  local falta=""
  local context_pct=""

  # 1. Detecção de tarefa via task.md local no workspace ativo
  local task_file=""
  if [ -n "${ANTIGRAVITY_WORKSPACE:-}" ]; then
    if [ -f "${ANTIGRAVITY_WORKSPACE}/task.md" ]; then
      task_file="${ANTIGRAVITY_WORKSPACE}/task.md"
    fi
  elif [ -f "./task.md" ]; then
    task_file="./task.md"
  fi

  if [ -n "$task_file" ]; then
    local done_count
    local in_prog_count
    local pending_count
    done_count=$(grep -c '\[x\]' "$task_file" 2>/dev/null || true)
    [ -z "$done_count" ] && done_count=0
    in_prog_count=$(grep -c '\[/\]' "$task_file" 2>/dev/null || true)
    [ -z "$in_prog_count" ] && in_prog_count=0
    pending_count=$(grep -c '\[ \]' "$task_file" 2>/dev/null || true)
    [ -z "$pending_count" ] && pending_count=0
    local total_tasks=$(( done_count + in_prog_count + pending_count ))

    if [ "$in_prog_count" -gt 0 ]; then
      is_running=true
      if [ "$total_tasks" -gt 0 ]; then
        local calc_falta=$(( 100 - (done_count * 100 / total_tasks) ))
        [ "$calc_falta" -le 0 ] && calc_falta=5
        falta="$calc_falta"
      fi
    fi
  fi

  # 2. Verificação de status via payload JSON do Antigravity CLI
  if ! $is_running; then
    if [[ "$INPUT_JSON" =~ \"(status|state)\"[[:space:]]*:[[:space:]]*\"(running|busy|in_progress|executing)\" ]]; then
      is_running=true
      if [[ "$INPUT_JSON" =~ \"(remaining_percentage|remaining|falta)\"[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
        falta="${BASH_REMATCH[2]}"
      elif [[ "$INPUT_JSON" =~ \"(progress_percentage|progress)\"[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
        falta=$(( 100 - BASH_REMATCH[2] ))
      fi
    fi
  fi

  # 3. Renderização condicionada pelo estado
  if $is_running; then
    [ -z "$falta" ] && falta="50"
    printf "${YELLOW}⏳ Falta: %d%%${RESET}" "$falta"
  else
    # Estado Idle: calcula porcentagem de /context utilizado
    if [[ "$INPUT_JSON" =~ \"(context_percentage|context_used_percentage)\"[[:space:]]*:[[:space:]]*([0-9.]+) ]]; then
      context_pct="${BASH_REMATCH[2]}"
    elif [[ "$INPUT_JSON" =~ \"context\"[^{}]*\"(percentage|used_percentage)\"[[:space:]]*:[[:space:]]*([0-9.]+) ]]; then
      context_pct="${BASH_REMATCH[2]}"
    fi

    if [ -z "$context_pct" ]; then
      local tokens=""
      if [[ "$INPUT_JSON" =~ \"total_tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
        tokens="${BASH_REMATCH[1]}"
      elif [[ "$INPUT_JSON" =~ \"tokens\"[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
        tokens="${BASH_REMATCH[1]}"
      fi

      if [ -n "$tokens" ] && [ "$tokens" -gt 0 ] 2>/dev/null; then
        # Janela de contexto padrão de 1.000.000 de tokens do Gemini
        local limit=1000000
        if [[ "$INPUT_JSON" =~ \"context_window\"[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
          limit="${BASH_REMATCH[1]}"
        fi
        context_pct=$(( (tokens * 100) / limit ))
      else
        context_pct="0"
      fi
    fi

    # Formatação do percentual de contexto com cores semânticas
    local round_pct
    round_pct=$(LC_ALL=C LC_NUMERIC=C printf "%.0f" "$context_pct" 2>/dev/null || echo "0")
    local col_ctx=$GREEN
    [ "$round_pct" -ge 50 ] 2>/dev/null && col_ctx=$YELLOW
    [ "$round_pct" -ge 80 ] 2>/dev/null && col_ctx=$RED

    printf "${CYAN}🧠 Context: %s%d%%%s${RESET}" "$col_ctx" "$round_pct" "$RESET"
  fi
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
  parts+=("$(widget_telemetry 2>/dev/null || printf "${CYAN}🧠 Context: 0%%${RESET}")")

  local result=""
  for i in "${!parts[@]}"; do
    if [ "$i" -eq 0 ]; then
      result="${parts[$i]}"
    else
      result="${result} │ ${parts[$i]}"
    fi
  done
  printf "%s\n" "$result"
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
      telemetry|activity|context) widget_telemetry ;;
      *) render_statusline ;;
    esac
  else
    render_statusline
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
