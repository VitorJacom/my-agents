#!/usr/bin/env bash
# =============================================================================
# scripts/pr-reviewer.sh - Utilitário de Inspeção e Auditoria de PRs
# =============================================================================
# Fornece recursos de inspeção de metadados, extração de diffs e checagem
# determinística de integridade da Golden Rule (tests/core/) no fluxo AIDD.
# =============================================================================

set -euo pipefail

show_help() {
  cat << 'EOF'
scripts/pr-reviewer.sh - Motor Determinístico de Inspeção e Auditoria de PR

Uso:
  scripts/pr-reviewer.sh <subcomando> [argumentos...]

Subcomandos:
  fetch-diff <pr_number>
      Valida se a PR está OPEN, extrai metadados estruturados e
      o diff unificado via GitHub CLI (gh pr view, gh pr diff).
      Parsing resiliente com jq e fallback em Python3.

  audit-integrity <pr_number>
      Valida se a PR está OPEN e audita se qualquer arquivo sob
      tests/core/ foi modificado, adicionado ou removido no diff.
      Se houver violação da Golden Rule, aborta com exit code 3 (circuit-breaker).

Opções Globais:
  -h, --help
      Exibe este manual de instruções.

Códigos de Saída (Exit Codes):
  0: Sucesso / PR íntegra
  1: Erro geral / parâmetros inválidos / PR fechada / PR inexistente / dependência ausente
  3: ALERTA DE FRAUDE: Violação da Golden Rule (alteração detectada em tests/core/)
EOF
}

check_parsers() {
  if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    echo "Erro: Nem 'jq' nem 'python3' estão disponíveis no ambiente para processamento de JSON." >&2
    return 1
  fi
  return 0
}

parse_pr_json() {
  local json="$1"
  local expr="$2"

  if command -v jq >/dev/null 2>&1; then
    echo "$json" | jq -r "$expr // empty"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "
import sys, json

try:
    data = json.loads(sys.argv[1])
    target = sys.argv[2].lstrip('.')
    parts = target.split('.')
    val = data
    for p in parts:
        if isinstance(val, dict):
            val = val.get(p)
        else:
            val = None
            break
    if val is not None:
        print(val)
except Exception:
    sys.exit(1)
" "$json" "$expr"
  else
    echo "Erro: Nem 'jq' nem 'python3' estão disponíveis para parsing de JSON." >&2
    return 1
  fi
}

cmd_fetch_diff() {
  local pr_number="${1:-}"

  if [[ -z "$pr_number" ]]; then
    echo "Erro: O subcomando 'fetch-diff' requer o número da PR como argumento." >&2
    echo "Uso: scripts/pr-reviewer.sh fetch-diff <pr_number>" >&2
    exit 1
  fi

  check_parsers

  # Obter metadados da PR via GitHub CLI
  local pr_json
  if ! pr_json="$(gh pr view "$pr_number" --json number,title,state,headRefName,baseRefName,author,url 2>&1)"; then
    echo "Erro ao consultar PR #$pr_number via GitHub CLI:" >&2
    echo "$pr_json" >&2
    exit 1
  fi

  local pr_state
  pr_state="$(parse_pr_json "$pr_json" ".state")"

  if [[ -z "$pr_state" ]]; then
    echo "Erro: Não foi possível obter o estado da PR #$pr_number." >&2
    exit 1
  fi

  if [[ "$pr_state" != "OPEN" ]]; then
    echo "Erro: PR #$pr_number não está OPEN (estado atual: $pr_state). Apenas PRs abertas podem ser inspecionadas." >&2
    exit 1
  fi

  local pr_title pr_head pr_base pr_author pr_url
  pr_title="$(parse_pr_json "$pr_json" ".title")"
  pr_head="$(parse_pr_json "$pr_json" ".headRefName")"
  pr_base="$(parse_pr_json "$pr_json" ".baseRefName")"
  pr_author="$(parse_pr_json "$pr_json" ".author.login")"
  pr_url="$(parse_pr_json "$pr_json" ".url")"

  # Obter diff unificado
  local pr_diff
  if ! pr_diff="$(gh pr diff "$pr_number" 2>&1)"; then
    echo "Erro ao obter diff unificado da PR #$pr_number via GitHub CLI:" >&2
    echo "$pr_diff" >&2
    exit 1
  fi

  # Exibir metadados estruturados e diff unificado
  cat << EOF
=== PR #$pr_number METADATA ===
Number: $pr_number
Title: $pr_title
State: $pr_state
Author: $pr_author
Head: $pr_head -> Base: $pr_base
URL: $pr_url
=== UNIFIED DIFF ===
$pr_diff
EOF
}

cmd_audit_integrity() {
  local pr_number="${1:-}"

  if [[ -z "$pr_number" ]]; then
    echo "Erro: O subcomando 'audit-integrity' requer o número da PR como argumento." >&2
    echo "Uso: scripts/pr-reviewer.sh audit-integrity <pr_number>" >&2
    exit 1
  fi

  check_parsers

  # Obter metadados da PR via GitHub CLI
  local pr_json
  if ! pr_json="$(gh pr view "$pr_number" --json number,title,state,headRefName,baseRefName,author,url 2>&1)"; then
    echo "Erro ao consultar PR #$pr_number via GitHub CLI:" >&2
    echo "$pr_json" >&2
    exit 1
  fi

  local pr_state
  pr_state="$(parse_pr_json "$pr_json" ".state")"

  if [[ -z "$pr_state" ]]; then
    echo "Erro: Não foi possível obter o estado da PR #$pr_number." >&2
    exit 1
  fi

  if [[ "$pr_state" != "OPEN" ]]; then
    echo "Erro: PR #$pr_number não está OPEN (estado atual: $pr_state)." >&2
    exit 1
  fi

  # Obter diff unificado
  local pr_diff
  if ! pr_diff="$(gh pr diff "$pr_number" 2>&1)"; then
    echo "Erro ao obter diff unificado da PR #$pr_number via GitHub CLI:" >&2
    echo "$pr_diff" >&2
    exit 1
  fi

  # Auditar alterações no diff para verificar se tests/core/ foi tocado
  local core_tampered
  core_tampered="$(echo "$pr_diff" | grep -E '(^diff --git .* tests/core/|^--- [ab]/tests/core/|^\+\+\+ [ab]/tests/core/)' || true)"

  if [[ -n "$core_tampered" ]]; then
    echo "ALERTA DE FRAUDE: A PR modifica arquivos protegidos em tests/core/!" >&2
    echo "Arquivos violados detectados:" >&2
    echo "$core_tampered" >&2
    exit 3
  fi

  echo "Integridade da PR #$pr_number aprovada. Nenhuma violação em tests/core/ detectada (Golden Rule preservada)."
  exit 0
}

# --- Parsing de Comandos ---
if [[ $# -eq 0 ]]; then
  show_help
  exit 1
fi

case "$1" in
  -h|--help)
    show_help
    exit 0
    ;;
  fetch-diff)
    shift
    cmd_fetch_diff "$@"
    ;;
  audit-integrity)
    shift
    cmd_audit_integrity "$@"
    ;;
  *)
    echo "Erro: Subcomando desconhecido '$1'." >&2
    echo "Uso: scripts/pr-reviewer.sh <subcomando> [argumentos...]" >&2
    echo "Execute 'scripts/pr-reviewer.sh --help' para mais informações." >&2
    exit 1
    ;;
esac
