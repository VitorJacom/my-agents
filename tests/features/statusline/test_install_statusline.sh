#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): Instalador Automatizado de Statusline (Issue #7)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INSTALL_SCRIPT="$REPO_ROOT/scripts/statusline/install-statusline.sh"
STATUSLINE_SCRIPT="$REPO_ROOT/scripts/statusline/statusline-quota.sh"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #7: Automated Plug-and-Play Statusline Setup"
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

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# =============================================================================
# SEÇÃO 1: SCRIPT DE INSTALAÇÃO E EXECUTABILIDADE
# =============================================================================
echo ""
echo "--- 1. [ESTRUTURA] Existência e Permissão de Execução ---"
check "Script scripts/statusline/install-statusline.sh existe" test -f "$INSTALL_SCRIPT"
check "Script scripts/statusline/install-statusline.sh é executável" test -x "$INSTALL_SCRIPT"

if [ ! -f "$INSTALL_SCRIPT" ]; then
  echo ""
  echo "========================================================================"
  echo " [RED] Falha esperada no ciclo TDD: scripts/statusline/install-statusline.sh ausente."
  echo " Passaram: $PASSED | Falharam: $FAILED"
  echo "========================================================================"
  exit 1
fi

# =============================================================================
# SEÇÃO 2: INSTALAÇÃO EM ARQUIVO INEXISTENTE (FRESH INSTALL)
# =============================================================================
echo ""
echo "--- 2. [FRESH INSTALL] Arquivo Inexistente Criado Corretamente ---"
FRESH_SETTINGS="$TMP_DIR/new_dir/settings.json"
"$INSTALL_SCRIPT" --settings-path "$FRESH_SETTINGS"

check "Arquivo settings.json criado no destino" test -f "$FRESH_SETTINGS"
check "Conteúdo é JSON válido" python3 -c "import json; json.load(open('$FRESH_SETTINGS'))"
check "Chave statusLine configurada" python3 -c "
import json
data = json.load(open('$FRESH_SETTINGS'))
assert 'statusLine' in data, 'statusLine ausente'
sl = data['statusLine']
assert sl.get('type') == 'command', f'type incorreto: {sl.get(\"type\")}'
assert sl.get('command') == '$STATUSLINE_SCRIPT', f'command incorreto: {sl.get(\"command\")}'
assert sl.get('enabled') is True, f'enabled incorreto: {sl.get(\"enabled\")}'
"

# =============================================================================
# SEÇÃO 3: PRESERVAÇÃO DE CHAVES PRÉ-EXISTENTES E BACKUP DE SEGURANÇA
# =============================================================================
echo ""
echo "--- 3. [PRESERVAÇÃO & BACKUP] Preserva Chaves e Cria .bak ---"
EXISTING_SETTINGS="$TMP_DIR/existing_settings.json"
cat << 'EOF' > "$EXISTING_SETTINGS"
{
  "artifactReviewPolicy": "always-proceed",
  "colorScheme": "dark",
  "model": "Gemini 3.8 Flash (Medium)",
  "notifications": true,
  "permissions": {
    "allow": [
      "command(git)",
      "command(ls)"
    ]
  },
  "trustedWorkspaces": [
    "/home/vitor/Projetos"
  ]
}
EOF

ORIGINAL_CHECKSUM=$(sha256sum "$EXISTING_SETTINGS" | awk '{print $1}')

"$INSTALL_SCRIPT" --settings-path "$EXISTING_SETTINGS"

check "Arquivo de backup .bak gerado" test -f "${EXISTING_SETTINGS}.bak"
BACKUP_CHECKSUM=$(sha256sum "${EXISTING_SETTINGS}.bak" | awk '{print $1}')
check "Conteúdo do .bak idêntico ao original prévio" test "$ORIGINAL_CHECKSUM" = "$BACKUP_CHECKSUM"

check "Preserva chaves pré-existentes intactas" python3 -c "
import json
data = json.load(open('$EXISTING_SETTINGS'))
assert data.get('artifactReviewPolicy') == 'always-proceed'
assert data.get('colorScheme') == 'dark'
assert data.get('model') == 'Gemini 3.8 Flash (Medium)'
assert data.get('notifications') is True
assert data.get('permissions', {}).get('allow') == ['command(git)', 'command(ls)']
assert data.get('trustedWorkspaces') == ['/home/vitor/Projetos']
assert data.get('statusLine', {}).get('command') == '$STATUSLINE_SCRIPT'
assert data.get('statusLine', {}).get('type') == 'command'
assert data.get('statusLine', {}).get('enabled') is True
"

# =============================================================================
# SEÇÃO 4: PRESERVAÇÃO DE ATRIBUTOS CUSTOMIZADOS DE STATUSLINE
# =============================================================================
echo ""
echo "--- 4. [STATUSLINE MERGE] Preserva Atributos Adicionais em statusLine ---"
CUSTOM_SL_SETTINGS="$TMP_DIR/custom_sl_settings.json"
cat << 'EOF' > "$CUSTOM_SL_SETTINGS"
{
  "statusLine": {
    "type": "custom",
    "command": "/tmp/old-command.sh",
    "enabled": false,
    "stack_with_default": true,
    "refreshInterval": 5
  }
}
EOF

"$INSTALL_SCRIPT" --settings-path "$CUSTOM_SL_SETTINGS"

check "Atualiza command, type e enabled preservando campos adicionais" python3 -c "
import json
data = json.load(open('$CUSTOM_SL_SETTINGS'))
sl = data.get('statusLine', {})
assert sl.get('command') == '$STATUSLINE_SCRIPT', f'command incorreto: {sl.get(\"command\")}'
assert sl.get('type') == 'command', f'type incorreto: {sl.get(\"type\")}'
assert sl.get('enabled') is True, f'enabled incorreto: {sl.get(\"enabled\")}'
assert sl.get('stack_with_default') is True, f'stack_with_default perdido'
assert sl.get('refreshInterval') == 5, f'refreshInterval perdido'
"

# =============================================================================
# SEÇÃO 5: SUPORTE A VARIÁVEL DE AMBIENTE ANTIGRAVITY_SETTINGS_PATH
# =============================================================================
echo ""
echo "--- 5. [ENV VAR] Suporte a ANTIGRAVITY_SETTINGS_PATH ---"
ENV_SETTINGS="$TMP_DIR/env_settings.json"
cat << 'EOF' > "$ENV_SETTINGS"
{
  "model": "Gemini Pro"
}
EOF

ANTIGRAVITY_SETTINGS_PATH="$ENV_SETTINGS" "$INSTALL_SCRIPT"

check "Injeta via variável de ambiente ANTIGRAVITY_SETTINGS_PATH" python3 -c "
import json
data = json.load(open('$ENV_SETTINGS'))
assert data.get('model') == 'Gemini Pro'
assert data.get('statusLine', {}).get('command') == '$STATUSLINE_SCRIPT'
"

# =============================================================================
# SEÇÃO 6: SINTAXE DE ARGUMENTO COM IGUAL (--settings-path=...)
# =============================================================================
echo ""
echo "--- 6. [CLI ARG] Suporte a --settings-path=<caminho> ---"
EQUALS_SETTINGS="$TMP_DIR/equals_settings.json"
echo '{"theme": "nord"}' > "$EQUALS_SETTINGS"

"$INSTALL_SCRIPT" "--settings-path=$EQUALS_SETTINGS"

check "Funciona com formato --settings-path=VAL" python3 -c "
import json
data = json.load(open('$EQUALS_SETTINGS'))
assert data.get('theme') == 'nord'
assert data.get('statusLine', {}).get('command') == '$STATUSLINE_SCRIPT'
"

# =============================================================================
# SEÇÃO 7: IDEMPOTÊNCIA (MÚLTIPLAS EXECUÇÕES SUCESSIVAS)
# =============================================================================
echo ""
echo "--- 7. [IDEMPOTÊNCIA] Execuções Repetidas Sem Efeitos Colaterais ---"
IDEMPOTENT_SETTINGS="$TMP_DIR/idempotent_settings.json"
echo '{"initial": "value"}' > "$IDEMPOTENT_SETTINGS"

"$INSTALL_SCRIPT" --settings-path "$IDEMPOTENT_SETTINGS"
STATE_RUN1=$(cat "$IDEMPOTENT_SETTINGS")

"$INSTALL_SCRIPT" --settings-path "$IDEMPOTENT_SETTINGS"
STATE_RUN2=$(cat "$IDEMPOTENT_SETTINGS")

"$INSTALL_SCRIPT" --settings-path "$IDEMPOTENT_SETTINGS"
STATE_RUN3=$(cat "$IDEMPOTENT_SETTINGS")

check "Estado idêntico entre a 1ª e a 2ª execução" test "$STATE_RUN1" = "$STATE_RUN2"
check "Estado idêntico entre a 2ª e a 3ª execução" test "$STATE_RUN2" = "$STATE_RUN3"
check "JSON permanece válido e com uma única chave statusLine" python3 -c "
import json
data = json.load(open('$IDEMPOTENT_SETTINGS'))
assert data.get('initial') == 'value'
assert data.get('statusLine', {}).get('command') == '$STATUSLINE_SCRIPT'
"

# =============================================================================
# SEÇÃO 8: PERMISSÃO EXECUTÁVEL COM MOCK ISOLADO (SEM MUTAR ARQUIVO VERSIONADO)
# =============================================================================
echo ""
echo "--- 8. [PERMISSÕES] Script Alvo é Garantido como Executável via Mock Isolado ---"
MOCK_STATUSLINE="$TMP_DIR/mock-statusline.sh"
echo '#!/bin/bash' > "$MOCK_STATUSLINE"
echo 'echo "mock statusline"' >> "$MOCK_STATUSLINE"
chmod -x "$MOCK_STATUSLINE"

"$INSTALL_SCRIPT" --settings-path "$IDEMPOTENT_SETTINGS" --script-path "$MOCK_STATUSLINE"
check "Script alvo recupera permissão executável após install sem mutar repositório" test -x "$MOCK_STATUSLINE"

# =============================================================================
# SEÇÃO 8.1: SIMULAÇÃO SEGURA COM FLAG --dry-run
# =============================================================================
echo ""
echo "--- 8.1. [DRY-RUN] Simulação Sem Efeitos Colaterais no Disco ---"
DRY_RUN_SETTINGS="$TMP_DIR/dry_run_settings.json"
echo '{"before": "untouched"}' > "$DRY_RUN_SETTINGS"

OUT_DRY=$("$INSTALL_SCRIPT" --settings-path "$DRY_RUN_SETTINGS" --dry-run)
check "--dry-run não altera o arquivo de settings no disco" test "$(cat "$DRY_RUN_SETTINGS")" = '{"before": "untouched"}'
check "--dry-run não gera arquivo de backup .bak" test ! -f "${DRY_RUN_SETTINGS}.bak"
check "--dry-run imprime prévia das modificações" bash -c "echo '$OUT_DRY' | grep -qi 'DRY-RUN'"

# =============================================================================
# SEÇÃO 8.2: FAIL-FAST EM JSON INVÁLIDO OU CORROMPIDO (AGENTS.md 1.4)
# =============================================================================
echo ""
echo "--- 8.2. [FAIL-FAST] Falha Controlada em Settings com JSON Corrompido ---"
CORRUPT_SETTINGS="$TMP_DIR/corrupt_settings.json"
echo '{ "invalid_json": true, ' > "$CORRUPT_SETTINGS"
STDERR_INSTALL="$TMP_DIR/stderr_install.log"

check "Falha controlada (exit code 1) com settings.json corrompido" \
  bash -c "! \"$INSTALL_SCRIPT\" --settings-path \"$CORRUPT_SETTINGS\" 2>\"$STDERR_INSTALL\""
check "Emite mensagem explicativa em stderr com JSON corrompido" \
  grep -qi 'Falha ao interpretar JSON' "$STDERR_INSTALL"
check "Arquivo corrompido original é preservado sem modificação" \
  grep -q 'invalid_json' "$CORRUPT_SETTINGS"

# =============================================================================
# SEÇÃO 9: RESUMO FINAL
# =============================================================================
echo ""
echo "========================================================================"
if [ "$FAILED" -eq 0 ]; then
  echo " [GREEN] Todos os testes passaram! ($PASSED de $((PASSED + FAILED)))"
  echo "========================================================================"
  exit 0
else
  echo " [RED] Falhas detectadas! (Passaram: $PASSED | Falharam: $FAILED)"
  echo "========================================================================"
  exit 1
fi
