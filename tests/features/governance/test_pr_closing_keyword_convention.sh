#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): Enforce plain-text issue closing keywords in PR bodies
# Issue #69 - Ensure GitHub native auto-close on PR merge
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
AGENTS_RULES="$REPO_ROOT/rules/AGENTS.md"
GATEKEEPER_AGENT="$REPO_ROOT/agents/gatekeeper/agent.md"
GIT_WORKFLOW_SKILL="$REPO_ROOT/skills/git-workflow/SKILL.md"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #69: Enforce Plain-Text Issue Closing Keywords for Auto-Close"
echo "========================================================================"

check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  [PASS] $desc"
    PASSED=$((PASSED + 1))
  else
    echo "  [FAIL] $desc"
    FAILED=$((FAILED + 1))
  fi
}

# =============================================================================
# SEÇÃO 1: HAPPY PATH - DIRETRIZES DE GOVERNANÇA E DOCUMENTAÇÃO
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] rules/AGENTS.md: Exigência de Closing Keywords em Texto Puro ---"
check "rules/AGENTS.md existe" test -f "$AGENTS_RULES"
check "rules/AGENTS.md exige palavras-chave de fechamento (Fixes/Closes/Resolves)" \
  grep -iE '(Fixes|Closes|Resolves) #[0-9<]' "$AGENTS_RULES"
check "rules/AGENTS.md especifica texto puro / plain text para closing keywords" \
  grep -iE '(plain[- ]text|texto puro)' "$AGENTS_RULES"
check "rules/AGENTS.md alerta sobre auto-close nativo do GitHub no merge" \
  grep -iE '(auto[- ]close|fechamento autom[aá]tico)' "$AGENTS_RULES"
check "rules/AGENTS.md proíbe crases / code blocks em closing keywords" \
  grep -iE '(sem crases|proibido.*crases|sem.*inline code|fora de.*c[oó]digo)' "$AGENTS_RULES"

echo ""
echo "--- 2. [HAPPY PATH] agents/gatekeeper/agent.md: Validação e Geração do walkthrough.md ---"
check "agents/gatekeeper/agent.md existe" test -f "$GATEKEEPER_AGENT"
check "gatekeeper/agent.md instrui fechamento com keyword em plain text / texto puro" \
  grep -iE '(plain[- ]text|texto puro)' "$GATEKEEPER_AGENT"
check "gatekeeper/agent.md proíbe crases / backticks na closing keyword do resumo da entrega" \
  grep -iE '(sem crases|sem backticks|fora de.*inline code)' "$GATEKEEPER_AGENT"
check "gatekeeper/agent.md valida closing keyword antes da criação do PR com gh pr create" \
  grep -iE '(closing keyword|palavra-chave de fechamento)' "$GATEKEEPER_AGENT"

echo ""
echo "--- 3. [HAPPY PATH] skills/git-workflow/SKILL.md: Template de PR e Instruções ---"
check "skills/git-workflow/SKILL.md existe" test -f "$GIT_WORKFLOW_SKILL"
check "git-workflow/SKILL.md documenta uso de closing keywords em texto puro" \
  grep -iE '(plain[- ]text|texto puro)' "$GIT_WORKFLOW_SKILL"
check "git-workflow/SKILL.md explica que crases / code blocks desativam o auto-close do GitHub" \
  grep -iE '(crases|code blocks?|inline code).*desatival?|n[aã]o disparam|n[aã]o fecha' "$GIT_WORKFLOW_SKILL"
check "git-workflow/SKILL.md template de PR inclui campo/linha de closing keyword fora de code block" \
  grep -E '^(Fixes|Closes|Resolves) #' "$GIT_WORKFLOW_SKILL"

# =============================================================================
# SEÇÃO 2: EDGE CASES & FAILURE MODES (VALIDAÇÃO DETERMINÍSTICA DO PARSER)
# =============================================================================
echo ""
echo "--- 4. [EDGE CASES & FAILURE MODES] Prevenção de Anti-Padrões em Arquivos de Governança ---"
check "gatekeeper/agent.md NÃO formata o exemplo da closing keyword isolada entre crases (\`Fixes #<numero>\`)" \
  bash -c "! grep -qE '\`Fixes #[<a-zA-Z0-9_>-]+\`' '$GATEKEEPER_AGENT'"

echo ""
echo "--- 5. [EDGE CASES & FAILURE MODES] Algoritmo de Validação de Closing Keywords em PR Bodies ---"

# Função utilitária de teste determinístico simulando a regra do Gatekeeper / Parser
validate_pr_body_closing_keywords() {
  local pr_content="$1"
  # 1. Remove blocos de código cercados (fenced code blocks ```...```)
  local stripped
  stripped=$(printf "%b\n" "$pr_content" | sed '/^```/,/^```/d')

  # 2. Encontra linhas com keywords válidas (Fixes, Fixed, Fix, Closes, Closed, Close, Resolves, Resolved, Resolve)
  # seguidas de #<issue_number>
  local matched_lines
  matched_lines=$(printf "%s\n" "$stripped" | grep -iE '\b(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved) #[0-9]+\b' || true)

  if [ -z "$matched_lines" ]; then
    return 1 # Nenhuma keyword encontrada fora de code blocks
  fi

  # 3. Verifica se pelo menos uma dessas ocorrências está em texto puro (NÃO cercada por crases inline `...`)
  local has_plain_text=0
  while IFS= read -r line; do
    # Remove qualquer ocorrência inline code com crases: `...`
    local no_inline_code
    no_inline_code=$(printf "%s\n" "$line" | sed 's/`[^`]*`//g')
    if printf "%s\n" "$no_inline_code" | grep -qiE '\b(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved) #[0-9]+\b'; then
      has_plain_text=1
      break
    fi
  done <<< "$matched_lines"

  if [ "$has_plain_text" -eq 1 ]; then
    return 0
  else
    return 2 # Apenas encontrada dentro de crases inline (inválido para auto-close)
  fi
}

# Cenário EC-01: Happy path com 'Fixes #42' em texto puro
check "EC-01: Aceita corpo de PR com 'Fixes #42' em texto puro" \
  validate_pr_body_closing_keywords $'## Resumo\nFixes #42\nTestes passando com sucesso.'

# Cenário EC-02: Happy path com 'Closes #108' em texto puro
check "EC-02: Aceita corpo de PR com 'Closes #108' em texto puro" \
  validate_pr_body_closing_keywords $'## Entrega\nCloses #108\nDetalhes da PR.'

# Cenário EC-03: Rejeição quando a keyword está entre crases inline (`Fixes #42`)
check "EC-03: Rejeita corpo com keyword apenas entre crases inline (\`Fixes #42\`)" \
  bash -c '! validate_pr_body_closing_keywords $"## Resumo\nResolvido em \`Fixes #42\`\nFim."'

# Cenário EC-04: Rejeição quando a keyword está dentro de fenced code block
check "EC-04: Rejeita corpo com keyword apenas dentro de bloco de código (\`\`\`)" \
  bash -c '! validate_pr_body_closing_keywords $"## Resumo\n\`\`\`\nFixes #42\n\`\`\`\nSem texto puro."'

# Cenário EC-05: Rejeição quando não há nenhuma closing keyword
check "EC-05: Rejeita corpo sem nenhuma closing keyword de issue" \
  bash -c '! validate_pr_body_closing_keywords $"## Resumo\nApenas texto sem referencia de fechamento."'

# Cenário EC-06: Aceita quando há crases em outras partes do texto mas a closing keyword está em texto puro
check "EC-06: Aceita keyword em plain text mesmo com crases em outros termos inline" \
  validate_pr_body_closing_keywords $'## Resumo\nExecutado `npm test` com sucesso.\nFixes #123\nPronto.'

echo ""
echo "--- 6. [INVARIANTE] Golden Rule: tests/core/ Permanece Intocado ---"
MODIFIED_CORE=$(git status --porcelain tests/core/ 2>/dev/null || true)
check "tests/core/ permanece 100% inalterado" test -z "$MODIFIED_CORE"

echo ""
echo "========================================================================"
echo " Resumo: $PASSED passaram | $FAILED falharam"
echo "========================================================================"
if [ "$FAILED" -ne 0 ]; then
  echo " >>> RESULTADO: RED (Falha esperada na fase TDD RED)"
  echo "========================================================================"
  exit 1
else
  echo " >>> RESULTADO: GREEN (Todos os testes passaram)"
  echo "========================================================================"
  exit 0
fi
