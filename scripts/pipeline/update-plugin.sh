#!/usr/bin/env bash
# =============================================================================
# scripts/pipeline/update-plugin.sh
# =============================================================================
# Utilitário CLI para verificar e aplicar atualizações do plugin my-agents
# a partir do repositório remoto Git.
#
# Funcionalidades:
# - --check: Consulta tags remotas e armazena metadados em cache JSON (TTL 24h)
#            com lock atômico de concorrência.
# - --status: Exibe versão local, remota, tempo de TTL e status pendente.
# - --apply: Aplica atualização de forma idempotente e segura, abortando
#            se houver working tree suja (fail-safe).
# - Suporte à variável MY_AGENTS_AUTO_UPDATE=1 para atualização opt-in desassistida.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Configurações de Cache e Locking
CACHE_DIR="${MY_AGENTS_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/antigravity}"
CACHE_FILE="${MY_AGENTS_CACHE_FILE:-$CACHE_DIR/my-agents-update.json}"
LOCK_FILE="${CACHE_FILE}.lock"
DEFAULT_TTL="${MY_AGENTS_CACHE_TTL:-86400}" # 24 horas em segundos
LOCK_TIMEOUT="${MY_AGENTS_LOCK_TIMEOUT:-10}" # segundos
AUTO_UPDATE="${MY_AGENTS_AUTO_UPDATE:-0}"
REMOTE_NAME="${MY_AGENTS_GIT_REMOTE:-origin}"

# Cores ANSI
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_BLUE="\033[34m"
C_RED="\033[31m"
C_GRAY="\033[90m"

show_help() {
  cat << EOF
${C_BOLD}scripts/pipeline/update-plugin.sh${C_RESET} - Gerenciador de Atualizações do Plugin my-agents

${C_BOLD}Uso:${C_RESET}
  $0 [OPÇÃO|SUBCOMANDO]

${C_BOLD}Subcomandos & Opções:${C_RESET}
  -c, --check             Verifica atualizações no repositório remoto e atualiza o cache JSON
  -s, --status            Exibe o status da versão local, remota e validade do cache
  -a, --apply             Aplica a versão remota mais recente (com proteção de working tree limpa)
  -f, --force             Força consulta remota ignorando o TTL do cache existente
  --force-check           Atalho para --check --force
  -h, --help              Exibe esta mensagem de ajuda

${C_BOLD}Variáveis de Ambiente:${C_RESET}
  MY_AGENTS_AUTO_UPDATE=1 Executa atualização automática desassistida se houver nova versão
  MY_AGENTS_CACHE_FILE    Caminho customizado para o arquivo de cache JSON
  MY_AGENTS_CACHE_TTL     Tempo de vida útil (TTL) do cache em segundos (padrão: 86400)
  MY_AGENTS_LOCK_TIMEOUT  Tempo limite em segundos para aquisição do lock de cache (padrão: 10)
EOF
}

# Funções de Aquisição e Liberação de Lock
acquire_lock() {
  mkdir -p "$(dirname "$LOCK_FILE")"
  exec 9>"$LOCK_FILE"
  if ! flock -w "$LOCK_TIMEOUT" 9 2>/dev/null; then
    echo "ERRO: Não foi possível obter o lock exclusivo para $LOCK_FILE após ${LOCK_TIMEOUT}s." >&2
    return 1
  fi
  return 0
}

release_lock() {
  flock -u 9 2>/dev/null || true
  exec 9>&- 2>/dev/null || true
}

# Obter versão local atual do repositório
get_local_version() {
  local version
  version=$(git describe --tags --exact-match 2>/dev/null || git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  echo "$version"
}

# Obter tag mais recente do repositório remoto
get_remote_latest_tag() {
  local remote="$1"
  local raw_tags
  raw_tags=$(git ls-remote --tags "$remote" 2>/dev/null || true)
  if [[ -z "$raw_tags" ]]; then
    echo ""
    return 0
  fi

  # Extrai tags, remove ^{} e ordena por version sort
  local latest_tag
  latest_tag=$(echo "$raw_tags" | awk -F'refs/tags/' '{print $2}' | grep -v '\^{}' | grep -v '^$' | sort -V | tail -n 1 || echo "")
  echo "$latest_tag"
}

# Escrever cache atômico com python3
write_cache_atomic() {
  local current_ver="$1"
  local latest_ver="$2"
  local upd_avail="$3"
  local timestamp="$4"
  local ttl="$5"

  local target_dir
  target_dir="$(dirname "$CACHE_FILE")"
  mkdir -p "$target_dir"

  local tmp_file="${CACHE_FILE}.tmp.$$"
  python3 -c "
import json, sys
data = {
    'plugin': 'my-agents',
    'current_version': sys.argv[1],
    'latest_version': sys.argv[2],
    'update_available': sys.argv[3].lower() == 'true',
    'last_checked_timestamp': int(sys.argv[4]),
    'ttl_seconds': int(sys.argv[5])
}
with open(sys.argv[6], 'w') as f:
    json.dump(data, f, indent=2)
" "$current_ver" "$latest_ver" "$upd_avail" "$timestamp" "$ttl" "$tmp_file"

  mv "$tmp_file" "$CACHE_FILE"
}

# Formatar segundos em formato legível (Xh Ym Zs)
format_seconds() {
  local s=$1
  if (( s <= 0 )); then
    echo "0s"
    return
  fi
  local hours=$(( s / 3600 ))
  local mins=$(( (s % 3600) / 60 ))
  local secs=$(( s % 60 ))
  local res=""
  if (( hours > 0 )); then
    res="${hours}h "
  fi
  if (( mins > 0 || hours > 0 )); then
    res="${res}${mins}m "
  fi
  res="${res}${secs}s"
  echo "$res"
}

# Subcomando: check
do_check() {
  local force="${1:-0}"
  local now
  now=$(date +%s)
  local local_ver
  local_ver=$(get_local_version)

  local is_cache_valid=0
  local cached_latest=""
  local cached_upd_avail=""
  local cached_timestamp=0
  local cached_ttl="$DEFAULT_TTL"

  if [[ -f "$CACHE_FILE" && "$force" -eq 0 ]]; then
    # Avalia validade do cache
    local cache_eval
    cache_eval=$(python3 -c "
import json, sys, time
try:
    with open('$CACHE_FILE') as f:
        d = json.load(f)
    now = int(sys.argv[1])
    ts = int(d.get('last_checked_timestamp', 0))
    ttl = int(d.get('ttl_seconds', 86400))
    valid = 1 if (now - ts) < ttl else 0
    upd = 'true' if d.get('update_available') else 'false'
    print(f'{valid}|{d.get(\"latest_version\", \"\")}|{upd}|{ts}|{ttl}')
except Exception:
    print('0||false|0|86400')
" "$now")
    IFS='|' read -r is_cache_valid cached_latest cached_upd_avail cached_timestamp cached_ttl <<< "$cache_eval"
  fi

  if [[ "$is_cache_valid" -eq 1 ]]; then
    local remaining=$(( cached_ttl - (now - cached_timestamp) ))
    local fmt_rem
    fmt_rem=$(format_seconds "$remaining")
    echo -e "${C_GREEN}[CACHE HIT]${C_RESET} Verificação em cache é válida (TTL restante: $fmt_rem)."
    echo "  Versão local:  $local_ver"
    echo "  Versão remota: $cached_latest"
    if [[ "$cached_upd_avail" == "true" ]]; then
      echo -e "  Status:        ${C_YELLOW}Atualização disponível!${C_RESET}"
    else
      echo -e "  Status:        ${C_GREEN}Plugin atualizado.${C_RESET}"
    fi

    # Se auto-update ativo e atualização disponível
    if [[ "$AUTO_UPDATE" == "1" && "$cached_upd_avail" == "true" ]]; then
      echo -e "${C_BLUE}[AUTO-UPDATE]${C_RESET} MY_AGENTS_AUTO_UPDATE=1 detectado. Disparando atualização automática..."
      do_apply
    fi
    return 0
  fi

  # Cache miss ou expirado ou force
  echo -e "${C_BLUE}[CHECK]${C_RESET} Consultando versões no repositório remoto '${REMOTE_NAME}'..."
  acquire_lock
  trap release_lock EXIT

  local remote_latest
  remote_latest=$(get_remote_latest_tag "$REMOTE_NAME")

  if [[ -z "$remote_latest" ]]; then
    echo "Aviso: Nenhuma tag encontrada no repositório remoto '${REMOTE_NAME}'." >&2
    remote_latest="$local_ver"
  fi

  local update_available="false"
  if [[ "$remote_latest" != "$local_ver" ]]; then
    # Compara se a remota é diferente da local
    update_available="true"
  fi

  write_cache_atomic "$local_ver" "$remote_latest" "$update_available" "$now" "$DEFAULT_TTL"
  release_lock
  trap - EXIT

  echo "  Versão local:  $local_ver"
  echo "  Versão remota: $remote_latest"
  if [[ "$update_available" == "true" ]]; then
    echo -e "  Status:        ${C_YELLOW}Atualização disponível! (Execute: $0 --apply)${C_RESET}"
  else
    echo -e "  Status:        ${C_GREEN}Plugin já está na versão mais recente.${C_RESET}"
  fi

  if [[ "$AUTO_UPDATE" == "1" && "$update_available" == "true" ]]; then
    echo -e "${C_BLUE}[AUTO-UPDATE]${C_RESET} MY_AGENTS_AUTO_UPDATE=1 detectado. Disparando atualização automática..."
    do_apply
  fi
}

# Subcomando: status
do_status() {
  local local_ver
  local_ver=$(get_local_version)
  local now
  now=$(date +%s)

  echo -e "${C_BOLD}Status do Plugin my-agents:${C_RESET}"
  echo "  Versão local atual: $local_ver"

  if [[ ! -f "$CACHE_FILE" ]]; then
    echo -e "  Status do cache:    ${C_YELLOW}Nenhum cache encontrado (nunca verificado).${C_RESET}"
    echo "  Recomendação:       Execute '$0 --check' para consultar atualizações."
    return 0
  fi

  local parsed
  parsed=$(python3 -c "
import json, sys
try:
    with open('$CACHE_FILE') as f:
        d = json.load(f)
    print(f\"{d.get('latest_version', 'desconhecida')}|{d.get('update_available', False)}|{d.get('last_checked_timestamp', 0)}|{d.get('ttl_seconds', 86400)}\")
except Exception as e:
    print('desconhecida|False|0|86400')
")
  local remote_ver upd_avail ts ttl
  IFS='|' read -r remote_ver upd_avail ts ttl <<< "$parsed"

  echo "  Versão mais recente remota: $remote_ver"

  local elapsed=$(( now - ts ))
  if (( elapsed >= ttl )); then
    echo -e "  Validade do cache:  ${C_RED}Cache expirado há $(format_seconds $(( elapsed - ttl ))).${C_RESET}"
  else
    local remaining=$(( ttl - elapsed ))
    echo -e "  Validade do cache:  ${C_GREEN}Válido (TTL restante: $(format_seconds "$remaining")).${C_RESET}"
  fi

  if [[ "$upd_avail" == "True" || "$upd_avail" == "true" ]]; then
    echo -e "  Status de atualização: ${C_YELLOW}Atualização pendente disponível!${C_RESET}"
  else
    echo -e "  Status de atualização: ${C_GREEN}Atualizado.${C_RESET}"
  fi
}

# Subcomando: apply
do_apply() {
  local local_ver
  local_ver=$(get_local_version)

  echo -e "${C_BLUE}[APPLY]${C_RESET} Verificando integridade da working tree..."

  # Fail-safe: checagem de working tree suja
  local dirty
  dirty=$(git status --porcelain 2>/dev/null || true)
  if [[ -n "$dirty" ]]; then
    echo -e "${C_RED}ERRO FAIL-SAFE: Working tree com alterações locais não comitadas!${C_RESET}" >&2
    echo "Para garantir a segurança do seu código e evitar perda de alterações," >&2
    echo "por favor faça commit ou stash dos arquivos modificados antes de atualizar." >&2
    echo "" >&2
    echo "Arquivos modificados:" >&2
    echo "$dirty" | sed 's/^/  /' >&2
    exit 1
  fi

  # Adquire lock para o processo de aplicação
  acquire_lock
  trap release_lock EXIT

  echo -e "${C_BLUE}[APPLY]${C_RESET} Buscando atualizações remotas (${REMOTE_NAME})..."
  git fetch "$REMOTE_NAME" --tags >/dev/null 2>&1

  local target_tag=""
  if [[ -f "$CACHE_FILE" ]]; then
    target_tag=$(python3 -c "import json; print(json.load(open('$CACHE_FILE')).get('latest_version', ''))" 2>/dev/null || echo "")
  fi

  if [[ -z "$target_tag" || "$target_tag" == "unknown" ]]; then
    target_tag=$(get_remote_latest_tag "$REMOTE_NAME")
  fi

  if [[ -z "$target_tag" ]]; then
    echo -e "${C_RED}ERRO: Não foi possível determinar a versão de destino.${C_RESET}" >&2
    exit 1
  fi

  echo -e "${C_BLUE}[APPLY]${C_RESET} Aplicando atualização para a versão ${target_tag}..."

  # Se houver branch ativa que rastreia remote, atualiza; caso contrário realiza checkout da tag
  local current_branch
  current_branch=$(git branch --show-current 2>/dev/null || echo "")

  if [[ -n "$current_branch" ]] && git merge-base --is-ancestor "$target_tag" "$current_branch" 2>/dev/null; then
    # Já está na tag ou à frente
    true
  elif [[ -n "$current_branch" ]] && git rev-parse --verify "refs/remotes/$REMOTE_NAME/$current_branch" >/dev/null 2>&1; then
    # Tenta fast-forward na branch
    git pull --ff-only "$REMOTE_NAME" "$current_branch" >/dev/null 2>&1 || git checkout "$target_tag" >/dev/null 2>&1
  else
    # Checkout direto da tag mais recente
    git checkout "$target_tag" >/dev/null 2>&1
  fi

  local new_ver
  new_ver=$(get_local_version)
  local now
  now=$(date +%s)

  # Atualiza o cache local marcando update_available: false
  write_cache_atomic "$new_ver" "$target_tag" "false" "$now" "$DEFAULT_TTL"

  release_lock
  trap - EXIT

  echo -e "${C_GREEN}[SUCESSO]${C_RESET} Plugin atualizado com sucesso para ${new_ver}."
}

# =============================================================================
# CLI Dispatcher
# =============================================================================
COMMAND=""
FORCE_FLAG=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help|help)
      show_help
      exit 0
      ;;
    -c|--check|check)
      COMMAND="check"
      shift
      ;;
    --force-check)
      COMMAND="check"
      FORCE_FLAG=1
      shift
      ;;
    -s|--status|status)
      COMMAND="status"
      shift
      ;;
    -a|--apply|apply)
      COMMAND="apply"
      shift
      ;;
    -f|--force)
      FORCE_FLAG=1
      shift
      ;;
    *)
      echo "Opção inválida: $1" >&2
      show_help
      exit 1
      ;;
  esac
done

if [[ -z "$COMMAND" ]]; then
  if [[ "$AUTO_UPDATE" == "1" ]]; then
    COMMAND="check"
  else
    COMMAND="status"
  fi
fi

case "$COMMAND" in
  check)
    do_check "$FORCE_FLAG"
    ;;
  status)
    do_status
    ;;
  apply)
    do_apply
    ;;
esac
