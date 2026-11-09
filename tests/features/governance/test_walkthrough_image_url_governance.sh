#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): Enforce Absolute Raw GitHub URLs for Visual Comparison Mockups in PR Walkthroughs
# Issue #75 - Absolute Raw GitHub URLs in Walkthrough and PR Bodies
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
AGENTS_RULES="$REPO_ROOT/rules/AGENTS.md"
GATEKEEPER_AGENT="$REPO_ROOT/agents/gatekeeper/agent.md"
ISSUE_PIPELINE_SKILL="$REPO_ROOT/skills/issue-pipeline/SKILL.md"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #75: Enforce Absolute Raw GitHub URLs in PR Walkthroughs"
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
echo "--- 1. [HAPPY PATH] rules/AGENTS.md: Exigência de URLs Raw do GitHub e Proibição de Relativos ---"
check "rules/AGENTS.md existe" test -f "$AGENTS_RULES"
check "rules/AGENTS.md proíbe caminhos relativos para mockups e screenshots no walkthrough" \
  grep -iE '(pro[ií]be.*(caminhos? relativos?|docs/assets/mockups)|n[aã]o utilizar caminhos relativos|proibido.*caminhos? relativos?)' "$AGENTS_RULES"
check "rules/AGENTS.md exige URLs canônicas absolutas raw do GitHub (raw.githubusercontent.com)" \
  grep -F 'raw.githubusercontent.com' "$AGENTS_RULES"
check "rules/AGENTS.md especifica formato https://raw.githubusercontent.com/<owner>/<repo>/<branch_or_commit>/<path>" \
  grep -E 'https://raw\.githubusercontent\.com/[^/]+/[^/]+/[^/]+/' "$AGENTS_RULES"
check "rules/AGENTS.md menciona tag <img src=\"https://raw.githubusercontent.com/...\" width=\"560\" />" \
  grep -E '<img.*src="https://raw\.githubusercontent\.com/.*width="560"' "$AGENTS_RULES"
check "rules/AGENTS.md explica que caminhos relativos falham ou quebram na descrição/preview do PR no GitHub" \
  grep -iE '(quebr|falh|n[aã]o renderiz).*descri[çc][aã]o.*(PR|Pull Request)|(PR|Pull Request).*n[aã]o resolve.*relativo' "$AGENTS_RULES"

echo ""
echo "--- 2. [HAPPY PATH] agents/gatekeeper/agent.md: Validação e Auditoria Visual do walkthrough.md ---"
check "agents/gatekeeper/agent.md existe" test -f "$GATEKEEPER_AGENT"
check "gatekeeper/agent.md proíbe caminhos relativos em mockups/screenshots no walkthrough e PR" \
  grep -iE '(pro[ií]be.*(caminhos? relativos?|docs/assets/mockups)|n[aã]o permitir.*relativos?|proibido.*caminhos? relativos?)' "$GATEKEEPER_AGENT"
check "gatekeeper/agent.md exige URLs canônicas absolutas raw do GitHub (raw.githubusercontent.com)" \
  grep -F 'raw.githubusercontent.com' "$GATEKEEPER_AGENT"
check "gatekeeper/agent.md recomenda tag <img com width=\"560\" para renderização responsiva/lado a lado" \
  grep -E '<img.*src="https://raw\.githubusercontent\.com/.*width="560"' "$GATEKEEPER_AGENT"
check "gatekeeper/agent.md circuito de bloqueio rejeita PR se houver caminhos relativos em mockups" \
  grep -iE '(bloqueia|rejeita|circuit[- ]breaker).*caminhos? relativos?|caminhos? relativos?.*(bloqueia|rejeita|aborta)' "$GATEKEEPER_AGENT"

echo ""
echo "--- 3. [HAPPY PATH] skills/issue-pipeline/SKILL.md: Instruções e Template de Visual Comparison ---"
check "skills/issue-pipeline/SKILL.md existe" test -f "$ISSUE_PIPELINE_SKILL"
check "skills/issue-pipeline/SKILL.md instrui uso de raw.githubusercontent.com para mockups no PR" \
  grep -F 'raw.githubusercontent.com' "$ISSUE_PIPELINE_SKILL"
check "skills/issue-pipeline/SKILL.md proíbe caminhos relativos em mockups/renderizações no corpo do PR" \
  grep -iE '(pro[ií]be.*(caminhos? relativos?|docs/assets/mockups)|n[aã]o utilizar caminhos relativos|proibido.*caminhos? relativos?)' "$ISSUE_PIPELINE_SKILL"
check "skills/issue-pipeline/SKILL.md template visual comparison utiliza tag <img com raw url e width=\"560\"" \
  grep -E '<img.*src="https://raw\.githubusercontent\.com/.*width="560"' "$ISSUE_PIPELINE_SKILL"

# =============================================================================
# SEÇÃO 2: EDGE CASES & FAILURE MODES (VALIDAÇÃO DETERMINÍSTICA DO PARSER)
# =============================================================================
echo ""
echo "--- 4. [EDGE CASES & FAILURE MODES] Prevenção de Anti-Padrões em Templates de Governança ---"
check "gatekeeper/agent.md NÃO utiliza caminho relativo docs/assets/mockups na tabela comparativa recomendada" \
  bash -c "! grep -F '| ![Mockup Original](docs/assets/mockups/' '$GATEKEEPER_AGENT'"
check "skills/issue-pipeline/SKILL.md NÃO utiliza caminho relativo docs/assets/mockups na tabela comparativa recomendada" \
  bash -c "! grep -F '| ![Mockup Original](docs/assets/mockups/' '$ISSUE_PIPELINE_SKILL'"

echo ""
echo "--- 5. [EDGE CASES & FAILURE MODES] Algoritmo de Validação de URLs de Imagens em Walkthrough ---"

# Função determinística simulando a validação executada pelo Gatekeeper
validate_walkthrough_image_urls() {
  local content="$1"
  local has_violation=0

  # 1. Procura imagens Markdown: ![alt](url)
  while IFS= read -r img_url; do
    [ -z "$img_url" ] && continue
    # Se for relativo (docs/..., ./..., ../... ou qualquer coisa que não comece com http)
    if [[ ! "$img_url" =~ ^https?:// ]]; then
      has_violation=1
      break
    fi
    # Se for URL HTTP/HTTPS mas não for raw.githubusercontent.com
    if [[ ! "$img_url" =~ ^https://raw\.githubusercontent\.com/ ]]; then
      has_violation=1
      break
    fi
  done < <(printf "%s\n" "$content" | grep -oE '!\[[^]]*\]\([^)]+\)' | sed -E 's/!\[[^]]*\]\(([^)]+)\)/\1/' || true)

  if [ "$has_violation" -eq 1 ]; then
    return 1
  fi

  # 2. Procura tags HTML: <img ... src="..." ... />
  while IFS= read -r img_src; do
    [ -z "$img_src" ] && continue
    if [[ ! "$img_src" =~ ^https?:// ]]; then
      has_violation=1
      break
    fi
    if [[ ! "$img_src" =~ ^https://raw\.githubusercontent\.com/ ]]; then
      has_violation=1
      break
    fi
  done < <(printf "%s\n" "$content" | grep -oE '<img[^>]+src="[^"]+"' | sed -E 's/.*src="([^"]+)".*/\1/' || true)

  if [ "$has_violation" -eq 1 ]; then
    return 1
  fi

  return 0
}

# Cenário EC-01: Rejeitar caminho relativo padrão docs/assets/mockups/... em Markdown
EC01_CONTENT="## 👁️ Visual Comparison Audit
| Mockup Original Aprovado | Implementação Renderizada |
| :---: | :---: |
| ![Mockup Original](docs/assets/mockups/feature-a.png) | ![Render](docs/assets/mockups/feature-a-render.png) |"

check "EC-01: Rejeita caminho relativo padrão docs/assets/mockups em Markdown" \
  bash -c "! validate_walkthrough_image_urls '$EC01_CONTENT'"

# Cenário EC-02: Rejeitar caminho relativo com ./ ou ../
EC02_CONTENT="| ![Mockup](./docs/assets/mockups/screen.png) | ![Impl](../assets/screen.png) |"
check "EC-02: Rejeita caminho relativo com ./ ou ../" \
  bash -c "! validate_walkthrough_image_urls '$EC02_CONTENT'"

# Cenário EC-03: Rejeitar caminho relativo em tag HTML <img src=\"docs/...\" />
EC03_CONTENT="| <img src=\"docs/assets/mockups/screen.png\" width=\"560\" /> | <img src=\"docs/assets/mockups/screen-render.png\" width=\"560\" /> |"
check "EC-03: Rejeita caminho relativo em tag HTML <img>" \
  bash -c "! validate_walkthrough_image_urls '$EC03_CONTENT'"

# Cenário EC-04: Rejeitar URL do GitHub com /blob/ (não-raw)
EC04_CONTENT="| <img src=\"https://github.com/org/repo/blob/main/docs/assets/mockups/screen.png\" width=\"560\" /> |"
check "EC-04: Rejeita URL GitHub /blob/ (deve ser raw.githubusercontent.com)" \
  bash -c "! validate_walkthrough_image_urls '$EC04_CONTENT'"

# Cenário EC-05: Rejeitar tabela com imagem válida misturada com imagem relativa inválida
EC05_CONTENT="| <img src=\"https://raw.githubusercontent.com/org/repo/main/docs/assets/mockups/screen.png\" width=\"560\" /> | ![Render](docs/assets/mockups/screen.png) |"
check "EC-05: Rejeita tabela mista (válida + relativa)" \
  bash -c "! validate_walkthrough_image_urls '$EC05_CONTENT'"

# Cenário HP-01: Aceitar tag <img src=\"https://raw.githubusercontent.com/...\" width=\"560\" />
HP01_CONTENT="## 👁️ Visual Comparison Audit
| Mockup Original Aprovado | Implementação Renderizada |
| :---: | :---: |
| <img src=\"https://raw.githubusercontent.com/owner/repo/commit123/docs/assets/mockups/login.png\" width=\"560\" /> | <img src=\"https://raw.githubusercontent.com/owner/repo/commit123/docs/assets/mockups/login-render.png\" width=\"560\" /> |"

check "HP-01: Aprova tabela comparativa com tags <img raw.githubusercontent.com e width=560" \
  validate_walkthrough_image_urls "$HP01_CONTENT"

# Cenário HP-02: Aceitar Markdown com raw.githubusercontent.com
HP02_CONTENT="| ![Mockup](https://raw.githubusercontent.com/owner/repo/main/docs/assets/mockups/login.png) | ![Render](https://raw.githubusercontent.com/owner/repo/main/docs/assets/mockups/login-render.png) |"
check "HP-02: Aprova Markdown com URL absoluta raw.githubusercontent.com" \
  validate_walkthrough_image_urls "$HP02_CONTENT"

# Cenário HP-03: Aprovar conteúdo sem imagens (ex.: backend/CLI)
HP03_CONTENT="## Walkthrough
Backend service implemented with 100% tests green.
Fixes #42"
check "HP-03: Aprova conteúdo sem imagens quando nenhuma imagem estiver presente" \
  validate_walkthrough_image_urls "$HP03_CONTENT"

# =============================================================================
# RESUMO FINAL
# =============================================================================
echo ""
echo "========================================================================"
echo " RESUMO DO TESTE: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo " >>> RESULTADO: RED (Falha esperada antes da implementação)"
  exit 1
fi

echo " >>> RESULTADO: GREEN (Todos os critérios de URLs raw de imagem atendidos)"
exit 0
