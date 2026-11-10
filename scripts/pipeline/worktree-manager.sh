#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# scripts/pipeline/worktree-manager.sh - Git Worktree Lifecycle Manager
# ADR-0004: Orquestração Multiagente Concorrente com Isolamento de Worktrees
# =============================================================================

show_usage() {
  cat <<'EOF'
Uso: scripts/pipeline/worktree-manager.sh <subcomando> [opções]

Subcomandos:
  create <issue_id> [--base <base_branch>]
      Cria ou conecta worktree isolada em .worktrees/issue-<id>
      com branch feature/issue-<id> e lockfile com PID ativo.

  list
      Lista todas as worktrees registradas com status de lock.

  rebase-sync <issue_id> [--base <base_branch>]
      Sincroniza worktree com a branch base via rebase com
      auto-abort em conflito e auditoria anti-fraude (tests/core/ e feature tests).

  remove <issue_id>
      Desmonta a worktree, purga lockfile e limpa registros git.

Códigos de Saída (Exit Codes):
  0: Sucesso
  1: Erro geral / argumentos inválidos / branch inexistente
  2: Concorrência ativa (lock retido por outro processo)
  3: Fraude detectada (violação da Golden Rule ou testes de features pré-existentes)
  4: Conflito de rebase (rebase abortado graciosamente)
EOF
}

normalize_id() {
  local raw="$1"
  local cleaned="${raw#\#}"
  if [ -z "$cleaned" ]; then
    echo "Erro: ID de issue inválido ou vazio: '$raw'" >&2
    exit 1
  fi
  echo "$cleaned"
}

resolve_base_branch() {
  local custom_base="$1"
  if [ -n "$custom_base" ]; then
    if ! git rev-parse --verify "$custom_base" >/dev/null 2>&1; then
      echo "Erro: Branch base customizada '$custom_base' não existe." >&2
      exit 1
    fi
    echo "$custom_base"
    return 0
  fi

  if git rev-parse --verify origin/main >/dev/null 2>&1; then
    echo "origin/main"
  elif git rev-parse --verify main >/dev/null 2>&1; then
    echo "main"
  else
    echo "HEAD"
  fi
}

get_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

# -----------------------------------------------------------------------------
# Subcomando: create
# -----------------------------------------------------------------------------
cmd_create() {
  local issue_id=""
  local custom_base=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --base)
        if [ $# -lt 2 ]; then
          echo "Erro: Flag --base requer o nome da branch." >&2
          exit 1
        fi
        custom_base="$2"
        shift 2
        ;;
      *)
        if [ -z "$issue_id" ]; then
          issue_id="$1"
          shift
        else
          echo "Erro: Argumento inesperado '$1'" >&2
          exit 1
        fi
        ;;
    esac
  done

  if [ -z "$issue_id" ]; then
    echo "Erro: issue_id obrigatório para o comando create." >&2
    exit 1
  fi

  local id
  id=$(normalize_id "$issue_id")
  local base_branch
  base_branch=$(resolve_base_branch "$custom_base")

  local repo_root
  repo_root=$(get_repo_root)
  local worktrees_dir="$repo_root/.worktrees"
  local wt_path="$worktrees_dir/issue-$id"
  local lock_file="$worktrees_dir/.lock-$id"
  local branch_name="feature/issue-$id"

  mkdir -p "$worktrees_dir"

  # Gestão atômica de Lockfile
  if [ -f "$lock_file" ]; then
    local existing_pid
    existing_pid=$(cat "$lock_file" 2>/dev/null || echo "")
    if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
      echo "Erro: Lock ativo pelo processo $existing_pid para issue-$id." >&2
      exit 2
    else
      echo "Aviso: Stale lock detectado (PID $existing_pid). Removendo..." >&2
      rm -f "$lock_file"
    fi
  fi

  echo "$$" > "$lock_file"

  # Criação da worktree
  if [ ! -d "$wt_path" ]; then
    if git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
      git worktree add "$wt_path" "$branch_name"
    else
      git worktree add -b "$branch_name" "$wt_path" "$base_branch"
    fi
  fi

  echo "Worktree issue-$id criada com sucesso em $wt_path (branch $branch_name)."
  exit 0
}

# -----------------------------------------------------------------------------
# Subcomando: list
# -----------------------------------------------------------------------------
cmd_list() {
  local repo_root
  repo_root=$(get_repo_root)
  local worktrees_dir="$repo_root/.worktrees"

  if [ ! -d "$worktrees_dir" ]; then
    echo "Nenhuma worktree registrada em .worktrees/"
    exit 0
  fi

  local found=0
  for wt in "$worktrees_dir"/issue-*; do
    if [ -d "$wt" ]; then
      found=1
      local wt_name
      wt_name=$(basename "$wt")
      local issue_num="${wt_name#issue-}"
      local lockfile="$worktrees_dir/.lock-${issue_num}"
      local lock_status="sem lock"

      if [ -f "$lockfile" ]; then
        local pid
        pid=$(cat "$lockfile" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
          lock_status="lock ativo (PID $pid)"
        else
          lock_status="stale lock (PID $pid)"
        fi
      fi

      local branch
      branch=$(git -C "$wt" branch --show-current 2>/dev/null || echo "detached")
      echo "$wt_name: branch '$branch' [$lock_status]"
    fi
  done

  if [ "$found" -eq 0 ]; then
    echo "Nenhuma worktree ativa em $worktrees_dir."
  fi
  exit 0
}

# -----------------------------------------------------------------------------
# Subcomando: rebase-sync
# -----------------------------------------------------------------------------
cmd_rebase_sync() {
  local issue_id=""
  local custom_base=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --base)
        if [ $# -lt 2 ]; then
          echo "Erro: Flag --base requer o nome da branch." >&2
          exit 1
        fi
        custom_base="$2"
        shift 2
        ;;
      *)
        if [ -z "$issue_id" ]; then
          issue_id="$1"
          shift
        else
          echo "Erro: Argumento inesperado '$1'" >&2
          exit 1
        fi
        ;;
    esac
  done

  if [ -z "$issue_id" ]; then
    echo "Erro: issue_id obrigatório para o comando rebase-sync." >&2
    exit 1
  fi

  local id
  id=$(normalize_id "$issue_id")
  local repo_root
  repo_root=$(get_repo_root)
  local worktrees_dir="$repo_root/.worktrees"
  local wt_path="$worktrees_dir/issue-$id"

  if [ ! -d "$wt_path" ]; then
    echo "Erro: Worktree para issue-$id não encontrada em $wt_path." >&2
    exit 1
  fi

  local base_branch
  base_branch=$(resolve_base_branch "$custom_base")

  # Executa rebase dentro da worktree
  local rebase_output=""
  local rebase_status=0
  rebase_output=$(git -C "$wt_path" rebase "$base_branch" 2>&1) || rebase_status=$?

  if [ "$rebase_status" -ne 0 ]; then
    echo "Erro: Conflito de rebase detectado na issue-$id contra $base_branch:" >&2
    echo "$rebase_output" >&2
    git -C "$wt_path" rebase --abort 2>/dev/null || true
    exit 4
  fi

  # Auditoria Anti-Fraude
  local modified_files
  modified_files=$(git -C "$wt_path" diff --diff-filter=MD --name-only "$base_branch...HEAD" 2>/dev/null || echo "")

  if [ -n "$modified_files" ]; then
    # Verificação A: tests/core/ (Golden Rule)
    if echo "$modified_files" | grep -q '^tests/core/'; then
      echo "ALERTA DE FRAUDE: Violação da Golden Rule! Modificação ilegal detectada em 'tests/core/'." >&2
      exit 3
    fi

    # Verificação B: tests/features/ pré-existente na base branch
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      case "$file" in
        tests/features/*)
          if git -C "$wt_path" cat-file -e "${base_branch}:${file}" 2>/dev/null; then
            echo "ALERTA DE FRAUDE: Violação de integridade! Teste pré-existente '$file' em tests/features/ foi modificado." >&2
            exit 3
          fi
          ;;
      esac
    done <<< "$modified_files"
  fi

  echo "Rebase-sync concluído com sucesso para issue-$id sobre $base_branch."
  exit 0
}

# -----------------------------------------------------------------------------
# Subcomando: remove
# -----------------------------------------------------------------------------
cmd_remove() {
  if [ $# -lt 1 ]; then
    echo "Erro: issue_id obrigatório para o comando remove." >&2
    exit 1
  fi

  local id
  id=$(normalize_id "$1")
  local repo_root
  repo_root=$(get_repo_root)
  local worktrees_dir="$repo_root/.worktrees"
  local wt_path="$worktrees_dir/issue-$id"
  local lock_file="$worktrees_dir/.lock-$id"

  if [ -d "$wt_path" ] || git worktree list 2>/dev/null | grep -q "$wt_path"; then
    git worktree remove "$wt_path" 2>/dev/null || \
    git worktree remove --force "$wt_path" 2>/dev/null || \
    rm -rf "$wt_path"
    git worktree prune 2>/dev/null || true
  fi

  if [ -d "$wt_path" ]; then
    rm -rf "$wt_path"
  fi

  rm -f "$lock_file"
  echo "Worktree issue-$id e lockfile removidos com sucesso."
  exit 0
}

# -----------------------------------------------------------------------------
# Dispatcher Principal
# -----------------------------------------------------------------------------
main() {
  if [ $# -lt 1 ]; then
    show_usage >&2
    exit 1
  fi

  local subcommand="$1"
  shift

  case "$subcommand" in
    create)
      cmd_create "$@"
      ;;
    list)
      cmd_list "$@"
      ;;
    rebase-sync)
      cmd_rebase_sync "$@"
      ;;
    remove)
      cmd_remove "$@"
      ;;
    *)
      echo "Erro: Subcomando desconhecido '$subcommand'." >&2
      show_usage >&2
      exit 1
      ;;
  esac
}

main "$@"
