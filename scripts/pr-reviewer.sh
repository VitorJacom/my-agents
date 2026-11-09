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

  submit-review <pr_number> --body-file <arquivo> [--status <auto|approve|request-changes|comment>] [--dry-run]
      Submete o parecer formal de code review diretamente na Pull Request via
      GitHub CLI (gh pr review).
      - Mapeamento automático de status (--status auto, padrão):
          * 'request-changes' se contiver severidade "🚨 Crítico" ou violação de integridade.
          * 'comment' se contiver "⚠️ Importante" ou "💡 Sugestão".
          * 'approve' se não houver apontamentos impeditivos.
      - Status explícito: approve, request-changes, comment.
      - Flag --dry-run exibe o comando formatado e o corpo do review sem efetuar mutações.

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

cmd_submit_review() {
  local pr_number=""
  local body_file=""
  local status="auto"
  local dry_run=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --body-file)
        if [[ $# -lt 2 || -z "$2" ]]; then
          echo "Erro: A opção '--body-file' requer um caminho de arquivo válido." >&2
          exit 1
        fi
        body_file="$2"
        shift 2
        ;;
      --body-file=*)
        body_file="${1#*=}"
        if [[ -z "$body_file" ]]; then
          echo "Erro: A opção '--body-file' requer um caminho de arquivo válido." >&2
          exit 1
        fi
        shift
        ;;
      --status)
        if [[ $# -lt 2 || -z "$2" ]]; then
          echo "Erro: A opção '--status' requer um valor (auto, approve, request-changes, comment)." >&2
          exit 1
        fi
        status="$2"
        shift 2
        ;;
      --status=*)
        status="${1#*=}"
        shift
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      -*)
        echo "Erro: Opção desconhecida '$1' para o subcomando 'submit-review'." >&2
        exit 1
        ;;
      *)
        if [[ -z "$pr_number" ]]; then
          pr_number="$1"
        else
          echo "Erro: Argumento posicional inesperado '$1'." >&2
          exit 1
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$pr_number" ]]; then
    echo "Erro: O subcomando 'submit-review' requer o número da PR como argumento." >&2
    echo "Uso: scripts/pr-reviewer.sh submit-review <pr_number> --body-file <arquivo> [--status <auto|approve|request-changes|comment>] [--dry-run]" >&2
    exit 1
  fi

  if [[ -z "$body_file" ]]; then
    echo "Erro: O parâmetro obrigatório '--body-file' não foi informado." >&2
    exit 1
  fi

  if [[ ! -f "$body_file" ]]; then
    echo "Erro: O arquivo de parecer de revisão '$body_file' não existe." >&2
    exit 1
  fi

  if [[ ! -s "$body_file" ]]; then
    echo "Erro: O arquivo de parecer de revisão '$body_file' está vazio." >&2
    exit 1
  fi

  case "$status" in
    auto|approve|request-changes|comment)
      ;;
    *)
      echo "Erro: Status de revisão inválido '$status'. Valores válidos: auto, approve, request-changes, comment." >&2
      exit 1
      ;;
  esac

  check_parsers

  # Validar existência e estado OPEN da PR via GitHub CLI
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
    echo "Erro: PR #$pr_number não está OPEN (estado atual: $pr_state). Apenas PRs abertas podem receber parecer de revisão." >&2
    exit 1
  fi

  # Resolução do status da revisão
  local resolved_flag=""
  local reason=""

  if [[ "$status" == "auto" ]]; then
    local body_content
    body_content="$(cat "$body_file")"

    if echo "$body_content" | grep -qiE '(🚨|crítico|critico|violação.*integridade|violacao.*integridade)'; then
      resolved_flag="request-changes"
      reason="Detectados apontamentos críticos ou violação de integridade no relatório."
    elif echo "$body_content" | grep -qiE '(⚠️|importante|💡|sugestão|sugestao)'; then
      resolved_flag="comment"
      reason="Detectados apontamentos informativos / sugestões no relatório."
    else
      resolved_flag="approve"
      reason="Nenhum apontamento impeditivo identificado no relatório."
    fi
  else
    resolved_flag="$status"
    reason="Status explicitamente definido via linha de comando."
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    cat << EOF
[DRY-RUN] Simulação de submissão de parecer de Code Review para PR #$pr_number
Comando planejado: gh pr review $pr_number --$resolved_flag --body-file $body_file
Status resolvido: $resolved_flag ($reason)
Arquivo de parecer: $body_file
--- Conteúdo do Parecer ---
$(cat "$body_file")
--- Fim do Parecer ---
[DRY-RUN] Nenhuma mutação foi disparada na API do GitHub.
EOF
    return 0
  fi

  local submit_output
  if ! submit_output="$(gh pr review "$pr_number" "--$resolved_flag" --body-file "$body_file" 2>&1)"; then
    echo "Erro ao submeter parecer de code review na PR #$pr_number via GitHub CLI:" >&2
    echo "$submit_output" >&2
    exit 1
  fi

  cat << EOF
Parecer de code review submetido com sucesso na PR #$pr_number!
Status: --$resolved_flag ($reason)
Arquivo: $body_file
Detalhes:
$submit_output
EOF
  return 0
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
  submit-review)
    shift
    cmd_submit_review "$@"
    ;;
  *)
    echo "Erro: Subcomando desconhecido '$1'." >&2
    echo "Uso: scripts/pr-reviewer.sh <subcomando> [argumentos...]" >&2
    echo "Execute 'scripts/pr-reviewer.sh --help' para mais informações." >&2
    exit 1
    ;;
esac
