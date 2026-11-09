#!/usr/bin/env bash
# =============================================================================
# test_wiki_update_documentation.sh
# Validação da Documentação do Mecanismo de Atualização e Notificação
# Issue #68: docs(wiki): documentar mecanismo de atualização e notificação
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DOCS_DIR="$REPO_ROOT/docs"
README_FILE="$REPO_ROOT/README.md"
GETTING_STARTED="$DOCS_DIR/Getting-Started.md"
TROUBLESHOOTING="$DOCS_DIR/Troubleshooting.md"
SYS_ARCH="$DOCS_DIR/System-Architecture.md"

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
echo " [TEST] Issue #68: Documentação do Mecanismo de Atualização e Notificação"
echo "========================================================================"

# =============================================================================
# SEÇÃO 1: HAPPY PATH - README.md & docs/Getting-Started.md
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] Instruções de Atualização no README.md ---"
check "README.md documenta comando de checagem manual (--check)" \
  grep -q "update-plugin.sh --check" "$README_FILE"

check "README.md documenta comando de status (--status)" \
  grep -q "update-plugin.sh --status" "$README_FILE"

check "README.md documenta comando de atualização segura (--apply)" \
  grep -q "update-plugin.sh --apply" "$README_FILE"

check "README.md documenta variável de auto-update MY_AGENTS_AUTO_UPDATE=1" \
  grep -q "MY_AGENTS_AUTO_UPDATE=1" "$README_FILE"

check "README.md utiliza caminho portável para update-plugin.sh (~/.gemini/... ou relativo)" \
  grep -qE "(~/\.gemini/config/plugins/my-agents/scripts/pipeline/update-plugin\.sh|\./\.agents/plugins/my-agents/scripts/pipeline/update-plugin\.sh)" "$README_FILE"

echo ""
echo "--- 2. [HAPPY PATH] Instruções de Atualização no docs/Getting-Started.md ---"
check "Getting-Started.md documenta comando de verificação (--check)" \
  grep -q "update-plugin.sh --check" "$GETTING_STARTED"

check "Getting-Started.md documenta comando de status (--status)" \
  grep -q "update-plugin.sh --status" "$GETTING_STARTED"

check "Getting-Started.md documenta aplicação de atualizações (--apply)" \
  grep -q "update-plugin.sh --apply" "$GETTING_STARTED"

check "Getting-Started.md documenta variável MY_AGENTS_AUTO_UPDATE=1" \
  grep -q "MY_AGENTS_AUTO_UPDATE=1" "$GETTING_STARTED"

check "Getting-Started.md contextualiza a notificação visual na statusline" \
  grep -qiE "statusline.*update|widget_update|notifica[çc][ãa]o.*atualiza[çc][ãa]o" "$GETTING_STARTED"

# =============================================================================
# SEÇÃO 2: HAPPY PATH - docs/Troubleshooting.md
# =============================================================================
echo ""
echo "--- 3. [HAPPY PATH] Diagnóstico de Atualização em docs/Troubleshooting.md ---"
check "Troubleshooting.md possui entrada na matriz rápida para atualizações" \
  grep -qiE "update-plugin|atualiza[çc][ãa]o.*plugin" "$TROUBLESHOOTING"

check "Troubleshooting.md documenta dirty tree fail-safe (working tree suja)" \
  grep -qiE "working tree suja|dirty.*working tree|altera[çc][õo]es n[ãa]o comitadas" "$TROUBLESHOOTING"

check "Troubleshooting.md documenta cache my-agents-update.json e recuperação" \
  grep -q "my-agents-update.json" "$TROUBLESHOOTING"

check "Troubleshooting.md menciona XDG_CACHE_HOME ou caminho padrão ~/.cache" \
  grep -qE "(XDG_CACHE_HOME|~/\.cache/antigravity)" "$TROUBLESHOOTING"

check "Troubleshooting.md documenta diagnóstico e liberação de lockfile retido" \
  grep -qiE "lock.*update|lockfile.*retido|my-agents-update.*lock" "$TROUBLESHOOTING"

check "Troubleshooting.md documenta desativação manual ou supressão da notificação na statusline" \
  grep -qiE "supress[ãa]o|desativa[çc][ãa]o.*statusline|desativar.*notifica[çc][ãa]o" "$TROUBLESHOOTING"

# =============================================================================
# SEÇÃO 3: HAPPY PATH - docs/System-Architecture.md
# =============================================================================
echo ""
echo "--- 4. [HAPPY PATH] Arquitetura de Atualização em docs/System-Architecture.md ---"
check "System-Architecture.md referencia scripts/pipeline/update-plugin.sh" \
  grep -q "scripts/pipeline/update-plugin.sh" "$SYS_ARCH"

check "System-Architecture.md referencia widget_update na statusline" \
  grep -q "widget_update" "$SYS_ARCH"

check "System-Architecture.md referencia scripts/statusline/statusline-quota.sh" \
  grep -q "scripts/statusline/statusline-quota.sh" "$SYS_ARCH"

check "System-Architecture.md inclui ADR-0016 no Índice de ADRs" \
  grep -qE "(\*\*0016\*\*|ADR-0016)" "$SYS_ARCH"

# =============================================================================
# SEÇÃO 4: EDGE CASES & FAILURE MODES - Portabilidade e Zero Dead Links
# =============================================================================
echo ""
echo "--- 5. [EDGE CASES & FAILURE MODES] Tolerância Zero a Caminhos Hardcoded ---"
HARDCODED_VITOR_README=$(grep -c "/home/vitor/" "$README_FILE" || true)
if [ "$HARDCODED_VITOR_README" -eq 0 ]; then
  pass "README.md possui 0 caminhos hardcoded '/home/vitor/'"
else
  fail "README.md possui $HARDCODED_VITOR_README caminhos '/home/vitor/'"
fi

HARDCODED_USER_README=$(grep -cE "/home/[a-zA-Z0-9_-]+/" "$README_FILE" || true)
if [ "$HARDCODED_USER_README" -eq 0 ]; then
  pass "README.md possui 0 caminhos absolutos de usuário /home/<user>/"
else
  fail "README.md possui $HARDCODED_USER_README caminhos de usuário /home/<user>/"
fi

echo ""
echo "--- 6. [EDGE CASES & FAILURE MODES] Ausência de Links Quebrados (Zero Dead Links) ---"
BROKEN_LINKS=0
DOCS_TO_CHECK=("$README_FILE" "$GETTING_STARTED" "$TROUBLESHOOTING" "$SYS_ARCH")

for doc_path in "${DOCS_TO_CHECK[@]}"; do
  doc_name="$(basename "$doc_path")"
  targets=$(grep -oE '\]\([^)]+\)' "$doc_path" | sed 's/\](//;s/)//' | grep -vE '^(https?|mailto|file):' | grep -v '^#' || true)
  
  for target in $targets; do
    clean_target="${target%%#*}"
    [ -z "$clean_target" ] && continue
    
    resolved=0
    if [ -e "$DOCS_DIR/$clean_target" ] || [ -e "$DOCS_DIR/$clean_target.md" ]; then
      resolved=1
    elif [ -e "$REPO_ROOT/$clean_target" ] || [ -e "$REPO_ROOT/$clean_target.md" ]; then
      resolved=1
    elif [ -e "$DOCS_DIR/$(basename "$clean_target")" ] || [ -e "$DOCS_DIR/$(basename "$clean_target").md" ]; then
      resolved=1
    fi

    if [ "$resolved" -eq 1 ]; then
      pass "Link em $doc_name -> '$clean_target' [OK]"
    else
      fail "Link quebrado em $doc_name -> '$clean_target' (alvo inexistente)"
      BROKEN_LINKS=$((BROKEN_LINKS + 1))
    fi
  done
done

echo ""
echo "========================================================================"
echo " RESUMO DO TESTE: $PASSED passou, $FAILED falhou"
echo "========================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo -e "${C_RED}❌ FALHA: Critérios de documentação não atendidos ($FAILED falhas).${C_RESET}"
  exit 1
else
  echo -e "${C_GREEN}✅ SUCESSO: Documentação do mecanismo de atualização validada.${C_RESET}"
  exit 0
fi
