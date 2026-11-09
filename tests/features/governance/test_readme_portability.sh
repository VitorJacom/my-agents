#!/usr/bin/env bash
# =============================================================================
# test_readme_portability.sh - Validação de Portabilidade Universal e Statusline no README
# Issue #57: Universal Portability, Remote Installation Guides & Statusline Preview
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
README_FILE="$REPO_ROOT/README.md"

C_GREEN="\033[32m"
C_RED="\033[31m"
C_YELLOW="\033[33m"
C_CYAN="\033[36m"
C_RESET="\033[0m"

PASSED=0
FAILED=0

pass() {
  echo -e "  ${C_GREEN}[PASS]${C_RESET} $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo -e "  ${C_RED}[FAIL]${C_RESET} $1"
  FAILED=$((FAILED + 1))
}

check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

echo "========================================================================"
echo " [TEST] Issue #57: Universal Portability, Remote Install & Statusline Preview"
echo "========================================================================"

# =============================================================================
# SEÇÃO 1: HAPPY PATH - Instalação Remota, Portabilidade e Prévia Visual
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Existência e Estrutura Geral do README.md ---"
check "README.md existe na raiz do repositório" test -f "$README_FILE"
check "README.md possui conteúdo não-vazio" test -s "$README_FILE"

echo ""
echo "--- 2. [HAPPY PATH] Instalação Remota Oficial como Opção Primária ---"
check "README.md contém comando oficial 'agy plugin install https://github.com/VitorJacom/my-agents.git'" \
  grep -q "agy plugin install https://github.com/VitorJacom/my-agents.git" "$README_FILE"

# Verifica se o comando remoto do GitHub aparece antes de qualquer comando local de clone
FIRST_REMOTE_LINE=$(grep -n "agy plugin install https://github.com/VitorJacom/my-agents.git" "$README_FILE" | head -n1 | cut -d: -f1 || echo "0")
FIRST_LOCAL_LINE=$(grep -nE "agy plugin install (~|\./)" "$README_FILE" | head -n1 | cut -d: -f1 || echo "999999")
if [ "$FIRST_REMOTE_LINE" -gt 0 ] && [ "$FIRST_REMOTE_LINE" -lt "$FIRST_LOCAL_LINE" ]; then
  pass "Instalação remota via GitHub é apresentada como método primário antes de caminhos locais"
else
  fail "Instalação remota via GitHub NÃO é o primeiro método na Opção 1 (remoto: linha $FIRST_REMOTE_LINE, local: linha $FIRST_LOCAL_LINE)"
fi

echo ""
echo "--- 3. [HAPPY PATH] Configuração Portável dos Scripts Utilitários ---"
check "Comando para sync-project-context.py utiliza '~/.gemini/config/plugins/my-agents/scripts/pipeline/sync-project-context.py'" \
  grep -q "~/.gemini/config/plugins/my-agents/scripts/pipeline/sync-project-context.py" "$README_FILE"

check "Comando para install-statusline.sh utiliza '~/.gemini/config/plugins/my-agents/scripts/statusline/install-statusline.sh'" \
  grep -q "~/.gemini/config/plugins/my-agents/scripts/statusline/install-statusline.sh" "$README_FILE"

check "Comando para statusline-quota.sh utiliza '~/.gemini/config/plugins/my-agents/scripts/statusline/statusline-quota.sh'" \
  grep -q "~/.gemini/config/plugins/my-agents/scripts/statusline/statusline-quota.sh" "$README_FILE"

check "README.md documenta opção de caminho relativo ao workspace para sync-project-context.py" \
  grep -q "\./\.agents/plugins/my-agents/scripts/pipeline/sync-project-context\.py" "$README_FILE"

echo ""
echo "--- 4. [HAPPY PATH] Prévia Visual em ASCII da Statusline e Modos de Operação ---"
check "README.md contém seção visual com moldura ou card estilizado em ASCII" \
  grep -q "┌─" "$README_FILE"

check "Prévia visual ilustra Modo Idle com telemetria de Contexto" \
  grep -qiE "(MODO IDLE|Estado Idle).*Context" "$README_FILE"

check "Prévia visual exibe widget de contexto '🧠 Context:' com percentual" \
  grep -qE "🧠 Context:[[:space:]]*[0-9]+%" "$README_FILE"

check "Prévia visual ilustra Modo Ativo / Em Andamento com Progresso Feito %" \
  grep -qiE "(MODO ATIVO|Em Andamento|Execu[çc][ãa]o).*Feito" "$README_FILE"

check "Prévia visual exibe widget de progresso '🚀 Feito:' com percentual" \
  grep -qE "🚀 Feito:[[:space:]]*[0-9]+%" "$README_FILE"

check "Prévia visual ilustra Seletores Polimórficos por Modelo (Gemini, Argon e 3P)" \
  grep -qiE "Argon" "$README_FILE"

check "Prévia visual documenta seletor de modelo Argon com cota específica '⚡ Argon:'" \
  grep -qE "⚡ Argon:[[:space:]]*\[[0-9]+%\]" "$README_FILE"

check "Prévia visual documenta seletor de modelos 3P (Claude/GPT) com cota '⚡ 3P'" \
  grep -qE "⚡ 3P( 5h)?:[[:space:]]*\[[0-9]+%\]" "$README_FILE"

check "Prévia visual documenta modelos Gemini regulares com cota '⚡ Quota 5h:'" \
  grep -qE "⚡ Quota 5h:[[:space:]]*\[[0-9]+%\]" "$README_FILE"

# =============================================================================
# SEÇÃO 2: EDGE CASES & FAILURE MODES - Ausência de Hardcoding e Integridade
# =============================================================================
echo ""
echo "--- 5. [EDGE CASES & FAILURE MODES] Tolerância Zero a Referências Hardcoded ---"
HARDCODED_VITOR_COUNT=$(grep -c "/home/vitor/" "$README_FILE" || true)
if [ "$HARDCODED_VITOR_COUNT" -eq 0 ]; then
  pass "Tolerância Zero: README.md contém 0 ocorrências de '/home/vitor/'"
else
  fail "ALERTA DE PORTABILIDADE: README.md contém $HARDCODED_VITOR_COUNT ocorrência(s) de '/home/vitor/'"
fi

HARDCODED_HOME_USER_COUNT=$(grep -cE "/home/[a-zA-Z0-9_-]+/" "$README_FILE" || true)
if [ "$HARDCODED_HOME_USER_COUNT" -eq 0 ]; then
  pass "README.md não contém caminhos absolutos /home/<usuario>/"
else
  fail "README.md contém $HARDCODED_HOME_USER_COUNT caminhos /home/<usuario>/"
fi

check "README.md não contém esquemas locais 'file://'" \
  bash -c "! grep -q 'file://' '$README_FILE'"

echo ""
echo "--- 6. [EDGE CASES & FAILURE MODES] Integridade dos Scripts Referenciados ---"
# Verifica se todos os scripts mencionados existem no repositório
SCRIPTS_FOUND=$(grep -oE "scripts/[a-zA-Z0-9_/-]+\.(sh|py)" "$README_FILE" | sort -u || true)
while IFS= read -r script_path; do
  if [ -n "$script_path" ]; then
    if [ -f "$REPO_ROOT/$script_path" ]; then
      pass "Script referenciado existe fisicamente: $script_path"
    else
      fail "Script referenciado no README.md não existe: $script_path"
    fi
  fi
done <<< "$SCRIPTS_FOUND"

echo ""
echo "--- 7. [EDGE CASES & FAILURE MODES] Sintaxe Válida dos Blocos de Configuração JSON ---"
# Extrai os blocos JSON do README.md e valida a sintaxe
JSON_BLOCK=$(sed -n '/```json/,/```/p' "$README_FILE" | sed '/^```/d' || true)
if [ -n "$JSON_BLOCK" ]; then
  if python3 -c "import json, sys; json.loads('''$JSON_BLOCK''')" 2>/dev/null; then
    pass "Bloco JSON de configuração do plugins.json é sintaticamente válido"
  else
    fail "Bloco JSON de configuração do plugins.json possui sintaxe inválida"
  fi
else
  fail "Nenhum bloco JSON encontrado para validação"
fi

echo ""
echo "========================================================================"
echo " RESUMO DO TESTE: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo -e "${C_RED}❌ FALHA: A suíte de portabilidade do README detectou violações.${C_RESET}"
  exit 1
else
  echo -e "${C_GREEN}✅ SUCESSO: O README atende a todos os critérios de portabilidade e telemetria.${C_RESET}"
  exit 0
fi
