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

  create-issues <pr_number> --findings-file <arquivo> [--dry-run]
      Gera issues rastreadas no GitHub para apontamentos elegíveis (🚨 Crítico, ⚠️ Importante)
      identificados no arquivo de findings de code review.
      - Inclui link da PR de origem, branch head, SHA do commit e critérios de remediação.
      - Aplica taxonomia semântica (labels type:fix/refactor, status:planned, source:code-review).
      - Executa automaticamente o script de reconciliação de governança ao término do lote.
      - Suporta flag --dry-run para simulação sem efeitos colaterais.

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

cmd_create_issues() {
  local pr_number=""
  local findings_file=""
  local dry_run=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --findings-file)
        if [[ $# -lt 2 || -z "$2" ]]; then
          echo "Erro: A opção '--findings-file' requer um caminho de arquivo válido." >&2
          exit 1
        fi
        findings_file="$2"
        shift 2
        ;;
      --findings-file=*)
        findings_file="${1#*=}"
        if [[ -z "$findings_file" ]]; then
          echo "Erro: A opção '--findings-file' requer um caminho de arquivo válido." >&2
          exit 1
        fi
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
        echo "Erro: Opção desconhecida '$1' para o subcomando 'create-issues'." >&2
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
    echo "Erro: O subcomando 'create-issues' requer o número da PR como argumento." >&2
    echo "Uso: scripts/pr-reviewer.sh create-issues <pr_number> --findings-file <arquivo> [--dry-run]" >&2
    exit 1
  fi

  if [[ -z "$findings_file" ]]; then
    echo "Erro: O parâmetro obrigatório '--findings-file' não foi informado." >&2
    exit 1
  fi

  if [[ ! -f "$findings_file" ]]; then
    echo "Erro: O arquivo de apontamentos '$findings_file' não existe." >&2
    exit 1
  fi

  if [[ ! -s "$findings_file" ]]; then
    echo "Erro: O arquivo de apontamentos '$findings_file' está vazio." >&2
    exit 1
  fi

  check_parsers

  # Obter metadados da PR via GitHub CLI
  local pr_json
  if ! pr_json="$(gh pr view "$pr_number" --json number,title,state,headRefName,baseRefName,headRefOid,author,url 2>&1)"; then
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
    echo "Erro: PR #$pr_number não está OPEN (estado atual: $pr_state). Apenas PRs abertas podem receber geração de issues." >&2
    exit 1
  fi

  local pr_title pr_head pr_commit pr_url
  pr_title="$(parse_pr_json "$pr_json" ".title")"
  pr_head="$(parse_pr_json "$pr_json" ".headRefName")"
  pr_commit="$(parse_pr_json "$pr_json" ".headRefOid")"
  pr_url="$(parse_pr_json "$pr_json" ".url")"

  # Extrair apontamentos elegíveis usando Python3 (JSONL format: 1 objeto por linha)
  local parsed_jsonl
  if ! parsed_jsonl="$(python3 -c "
import sys, re, json

findings_file = sys.argv[1]
with open(findings_file, 'r', encoding='utf-8') as f:
    text = f.read()

findings = []
current_sec = None
current_item = None

lines = text.splitlines()
for line in lines:
    header_match = re.match(r'^(#{1,6})\s+(.*)', line)
    if header_match:
        raw_header = header_match.group(2)
        title = raw_header.lower()
        if '🚨' in raw_header or 'crítico' in title or 'critico' in title:
            current_sec = 'Crítico'
        elif '⚠️' in raw_header or 'importante' in title:
            current_sec = 'Importante'
        else:
            current_sec = None
        current_item = None
        continue

    if not current_sec:
        continue

    # Checar se é sub-bullet de remediação ou detalhe (recuo >= 2 ou contendo sugestão/remediação)
    sub_bullet_match = re.match(r'^[ ]{2,}[-*]\s+(.*)', line)
    bullet_match = re.match(r'^[ ]{0,1}[-*]\s+(.*)', line)

    is_remed = bool(re.search(r'\*?(?:sugest[aã]o(?: de corre[cç][aã]o)?|remedia[cç][aã]o|crit[eé]rios de remedia[cç][aã]o)\*?:', line, re.IGNORECASE))

    if current_item and (sub_bullet_match or is_remed):
        raw_text = (sub_bullet_match.group(1) if sub_bullet_match else line).strip()
        rem_m = re.match(r'^\*?(?:sugest[aã]o(?: de corre[cç][aã]o)?|remedia[cç][aã]o|crit[eé]rios de remedia[cç][aã]o)\*?:\s*(.*)', raw_text, re.IGNORECASE)
        if rem_m:
            current_item['remediation'] = rem_m.group(1).strip()
        else:
            if current_item['remediation']:
                current_item['remediation'] += ' ' + raw_text
            else:
                current_item['description'] += '\n' + raw_text
    elif bullet_match:
        content = bullet_match.group(1).strip()
        loc = ''
        desc = content
        loc_m = re.match(r'^\*\*\[([^\]]+)\]\*\*:\s*(.*)', content)
        if loc_m:
            loc = loc_m.group(1).strip()
            desc = loc_m.group(2).strip()
        else:
            loc_m2 = re.match(r'^\*\*([^*]+)\*\*:\s*(.*)', content)
            if loc_m2:
                loc = loc_m2.group(1).strip()
                desc = loc_m2.group(2).strip()

        type_label = 'type:fix' if current_sec == 'Crítico' else 'type:refactor'
        prefix = 'fix' if current_sec == 'Crítico' else 'refactor'
        loc_prefix = f'[{loc}] ' if loc else ''
        issue_title = f'{prefix}(review): {loc_prefix}{desc}'.split('\n')[0].strip()

        current_item = {
            'severity': f'🚨 {current_sec}' if current_sec == 'Crítico' else f'⚠️ {current_sec}',
            'type_label': type_label,
            'labels': f'{type_label},status:planned,source:code-review',
            'location': loc,
            'title': issue_title,
            'description': desc,
            'remediation': ''
        }
        findings.append(current_item)

for item in findings:
    print(json.dumps(item, ensure_ascii=False))
" "$findings_file")"; then
    echo "Erro ao processar o arquivo de apontamentos '$findings_file'." >&2
    exit 1
  fi

  local findings_items=()
  while IFS= read -r item_line; do
    [[ -z "$item_line" ]] && continue
    findings_items+=("$item_line")
  done <<< "$parsed_jsonl"

  local count="${#findings_items[@]}"

  if [[ "$count" -eq 0 ]]; then
    echo "Erro: Nenhum apontamento elegível (🚨 Crítico ou ⚠️ Importante) encontrado em '$findings_file'." >&2
    exit 1
  fi

  # Localização do script de reconciliação de governança
  local reconciler_script="${MY_AGENTS_RECONCILER_OVERRIDE:-}"
  if [[ -z "$reconciler_script" ]]; then
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local repo_root
    repo_root="$(cd "$script_dir/.." && pwd)"

    if [[ -f "$repo_root/scripts/pipeline/reconcile-github-governance.sh" ]]; then
      reconciler_script="$repo_root/scripts/pipeline/reconcile-github-governance.sh"
    elif [[ -f "$repo_root/scripts/reconcile-github-governance.sh" ]]; then
      reconciler_script="$repo_root/scripts/reconcile-github-governance.sh"
    fi
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    cat << EOF
[DRY-RUN] Simulação de criação de issues a partir do review da PR #$pr_number
Origem: $pr_url (Head: $pr_head @ $pr_commit)
Total de apontamentos elegíveis encontrados: $count

EOF
    local idx=0
    for item_json in "${findings_items[@]}"; do
      local item_title item_sev item_labels item_loc item_desc item_remed
      item_title="$(parse_pr_json "$item_json" ".title")"
      item_sev="$(parse_pr_json "$item_json" ".severity")"
      item_labels="$(parse_pr_json "$item_json" ".labels")"
      item_loc="$(parse_pr_json "$item_json" ".location")"
      item_desc="$(parse_pr_json "$item_json" ".description")"
      item_remed="$(parse_pr_json "$item_json" ".remediation")"

      local issue_body
      issue_body="$(cat << BODY_EOF
## Contexto de Origem (Code Review)
- **Pull Request de Origem**: [#$pr_number]($pr_url)
- **Branch Head**: \`$pr_head\`
- **Commit SHA**: \`$pr_commit\`
- **Severidade**: \`$item_sev\`
$([[ -n "$item_loc" ]] && echo "- **Localização**: \`$item_loc\`")

## Descrição do Apontamento
$item_desc

## Critérios de Remediação
${item_remed:-Não especificado no parecer.}
BODY_EOF
)"

      cat << EOF
--- Issue $((idx + 1)) de $count ---
Título: $item_title
Labels: $item_labels
Comando planejado: gh issue create --title "$item_title" --body "<corpo>" --label "$item_labels"
Corpo:
$issue_body

EOF
      idx=$((idx + 1))
    done

    cat << EOF
[DRY-RUN] Script de reconciliação que seria executado: ${reconciler_script:-"scripts/pipeline/reconcile-github-governance.sh"}
[DRY-RUN] Nenhuma issue foi criada e nenhuma mutação foi disparada no GitHub.
EOF
    return 0
  fi

  # Criação real das issues
  echo "Iniciando criação de $count issue(s) rastreada(s) para a PR #$pr_number..."
  local idx=0
  local created_issues=()

  for item_json in "${findings_items[@]}"; do
    local item_title item_sev item_labels item_loc item_desc item_remed
    item_title="$(parse_pr_json "$item_json" ".title")"
    item_sev="$(parse_pr_json "$item_json" ".severity")"
    item_labels="$(parse_pr_json "$item_json" ".labels")"
    item_loc="$(parse_pr_json "$item_json" ".location")"
    item_desc="$(parse_pr_json "$item_json" ".description")"
    item_remed="$(parse_pr_json "$item_json" ".remediation")"

    local issue_body
    issue_body="$(cat << BODY_EOF
## Contexto de Origem (Code Review)
- **Pull Request de Origem**: [#$pr_number]($pr_url)
- **Branch Head**: \`$pr_head\`
- **Commit SHA**: \`$pr_commit\`
- **Severidade**: \`$item_sev\`
$([[ -n "$item_loc" ]] && echo "- **Localização**: \`$item_loc\`")

## Descrição do Apontamento
$item_desc

## Critérios de Remediação
${item_remed:-Não especificado no parecer.}
BODY_EOF
)"

    local create_out
    if ! create_out="$(gh issue create --title "$item_title" --body "$issue_body" --label "$item_labels" 2>&1)"; then
      echo "Erro ao criar issue no GitHub via GitHub CLI:" >&2
      echo "$create_out" >&2
      exit 1
    fi

    echo "  [OK] Issue criada: $create_out"
    created_issues+=("$create_out")
    idx=$((idx + 1))
  done

  echo ""
  echo "Total de ${#created_issues[@]} issue(s) criada(s) com sucesso!"

  # Invocação automática do reconciliador de governança
  if [[ -n "$reconciler_script" && -f "$reconciler_script" ]]; then
    echo "Invocando reconciliador de governança: $reconciler_script"
    if ! bash "$reconciler_script"; then
      echo "Erro ao executar reconciliador de governança '$reconciler_script'." >&2
      exit 1
    fi
    echo "Reconciliação de governança concluída com sucesso."
  else
    echo "Aviso: Script de reconciliação de governança não encontrado em '$reconciler_script'." >&2
  fi

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
  create-issues)
    shift
    cmd_create_issues "$@"
    ;;
  *)
    echo "Erro: Subcomando desconhecido '$1'." >&2
    echo "Uso: scripts/pr-reviewer.sh <subcomando> [argumentos...]" >&2
    echo "Execute 'scripts/pr-reviewer.sh --help' para mais informações." >&2
    exit 1
    ;;
esac
