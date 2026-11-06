#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teste de Aceitação (TDD): Desacoplamento de Estado Volátil do Git do PROJECT_CONTEXT.md (Issue #35)
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SESSION_HOOK="$REPO_ROOT/scripts/session-start-context.sh"
SYNC_SCRIPT="$REPO_ROOT/scripts/sync-project-context.py"
PROJECT_CONTEXT="$REPO_ROOT/PROJECT_CONTEXT.md"

FAILED=0
PASSED=0

echo "========================================================================"
echo " [TEST] Issue #35: Decouple Volatile Git State from PROJECT_CONTEXT.md"
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

TMP_BASE="$(mktemp -d)"
trap 'rm -rf "$TMP_BASE"' EXIT

# =============================================================================
# SEÇÃO 1: HAPPY PATH
# =============================================================================
echo ""
echo "--- 1. [HAPPY PATH] PROJECT_CONTEXT.md Estável e Livre de Estado Volátil ---"
check "PROJECT_CONTEXT.md existe na raiz do repositório" test -f "$PROJECT_CONTEXT"
check "Preserva seção estável 'Stack Tecnológica & Dependências'" grep -q "Stack Tecnológica" "$PROJECT_CONTEXT"
check "Preserva seção estável 'Estrutura Canônica de Diretórios'" grep -q "Estrutura Canônica" "$PROJECT_CONTEXT"
check "Preserva seção estável 'Regras e Invariantes Estritas'" grep -q "Regras e Invariantes" "$PROJECT_CONTEXT"
check "NÃO contém seção volátil '## 📍 Estado Atual da Arquitetura & Entregas'" bash -c "! grep -q 'Estado Atual da Arquitetura & Entregas' '$PROJECT_CONTEXT'"
check "NÃO contém metadado volátil '**Última Atualização**:'" bash -c "! grep -q '\*\*Última Atualização\*\*:' '$PROJECT_CONTEXT'"
check "NÃO contém metadado volátil '**Branch Ativa**:'" bash -c "! grep -q '\*\*Branch Ativa\*\*:' '$PROJECT_CONTEXT'"
check "NÃO contém metadado volátil '**Último Commit**:'" bash -c "! grep -q '\*\*Último Commit\*\*:' '$PROJECT_CONTEXT'"

echo ""
echo "--- 2. [HAPPY PATH] Injeção Dinâmica em Tempo Real no session-start-context.sh ---"
LIVE_REPO="$TMP_BASE/live_repo"
mkdir -p "$LIVE_REPO"
git -C "$LIVE_REPO" init -b main >/dev/null 2>&1 || (git -C "$LIVE_REPO" init >/dev/null 2>&1 && git -C "$LIVE_REPO" checkout -b main >/dev/null 2>&1)
git -C "$LIVE_REPO" config user.name "Test Bot"
git -C "$LIVE_REPO" config user.email "bot@example.com"

cat <<'EOF' > "$LIVE_REPO/PROJECT_CONTEXT.md"
# Contexto Canônico do Projeto (`PROJECT_CONTEXT.md`)

## 🛠️ Stack Tecnológica & Dependências
- Stack de teste estática.

## 📂 Estrutura Canônica de Diretórios
- `src/`: Código-fonte.
- `docs/`: Documentação (`docs/ARCHITECTURE.md`).

## 🛑 Regras e Invariantes Estritas (Anti-Alucinação)
1. **Grounding Mandatório**: Invariante de teste.
EOF

git -C "$LIVE_REPO" add PROJECT_CONTEXT.md
git -C "$LIVE_REPO" commit -m "chore: initial static context" >/dev/null 2>&1
git -C "$LIVE_REPO" checkout -b feature/test-live-branch >/dev/null 2>&1
echo "hello" > "$LIVE_REPO/untracked_file.txt"

BEFORE_HASH="$(sha256sum "$LIVE_REPO/PROJECT_CONTEXT.md" | awk '{print $1}')"
HOOK_OUTPUT="$(printf '{"workspacePaths": ["%s"]}' "$LIVE_REPO" | "$SESSION_HOOK")"
AFTER_HASH="$(sha256sum "$LIVE_REPO/PROJECT_CONTEXT.md" | awk '{print $1}')"

check "Saída de session-start-context.sh é um JSON válido" bash -c "printf '%s' '$HOOK_OUTPUT' | python3 -c 'import sys, json; data = json.load(sys.stdin); assert \"injectSteps\" in data'"
check "JSON contém conteúdo estático do PROJECT_CONTEXT.md" bash -c "printf '%s' '$HOOK_OUTPUT' | grep -q 'Stack de teste estática'"
check "JSON injeta dinamicamente a branch ativa (feature/test-live-branch)" bash -c "printf '%s' '$HOOK_OUTPUT' | grep -q 'feature/test-live-branch'"
check "JSON injeta dinamicamente o último commit (chore: initial static context)" bash -c "printf '%s' '$HOOK_OUTPUT' | grep -q 'chore: initial static context'"
check "JSON injeta dinamicamente o status da working tree (untracked_file.txt)" bash -c "printf '%s' '$HOOK_OUTPUT' | grep -q 'untracked_file.txt'"
check "PROJECT_CONTEXT.md permanece 100% intocado no disco após o hook" test "$BEFORE_HASH" = "$AFTER_HASH"

rm -f "$LIVE_REPO/untracked_file.txt"
HOOK_CLEAN_OUTPUT="$(printf '{"workspacePaths": ["%s"]}' "$LIVE_REPO" | "$SESSION_HOOK")"
check "JSON injeta 'Working tree limpa' quando git status --short é vazio" bash -c "printf '%s' '$HOOK_CLEAN_OUTPUT' | grep -q 'Working tree limpa'"

echo ""
echo "--- 3. [HAPPY PATH] Execução Paralela em Múltiplas Branches sem Conflito de Merge ---"
PARALLEL_REPO="$TMP_BASE/parallel_repo"
mkdir -p "$PARALLEL_REPO"
git -C "$PARALLEL_REPO" init -b main >/dev/null 2>&1 || (git -C "$PARALLEL_REPO" init >/dev/null 2>&1 && git -C "$PARALLEL_REPO" checkout -b main >/dev/null 2>&1)
git -C "$PARALLEL_REPO" config user.name "Parallel Bot"
git -C "$PARALLEL_REPO" config user.email "parallel@example.com"

cp "$LIVE_REPO/PROJECT_CONTEXT.md" "$PARALLEL_REPO/PROJECT_CONTEXT.md"
git -C "$PARALLEL_REPO" add PROJECT_CONTEXT.md
git -C "$PARALLEL_REPO" commit -m "chore: base commit on main" >/dev/null 2>&1

# Branch A
git -C "$PARALLEL_REPO" checkout -b feature/branch-a >/dev/null 2>&1
echo "feature A" > "$PARALLEL_REPO/a.txt"
git -C "$PARALLEL_REPO" add a.txt
git -C "$PARALLEL_REPO" commit -m "feat: add feature A" >/dev/null 2>&1
python3 "$SYNC_SCRIPT" "$PARALLEL_REPO" >/dev/null 2>&1
STATUS_A="$(git -C "$PARALLEL_REPO" status --short PROJECT_CONTEXT.md)"
git -C "$PARALLEL_REPO" add -A
git -C "$PARALLEL_REPO" commit --amend --no-edit >/dev/null 2>&1

# Branch B
git -C "$PARALLEL_REPO" checkout main >/dev/null 2>&1
git -C "$PARALLEL_REPO" checkout -b feature/branch-b >/dev/null 2>&1
echo "feature B" > "$PARALLEL_REPO/b.txt"
git -C "$PARALLEL_REPO" add b.txt
git -C "$PARALLEL_REPO" commit -m "feat: add feature B" >/dev/null 2>&1
python3 "$SYNC_SCRIPT" "$PARALLEL_REPO" >/dev/null 2>&1
STATUS_B="$(git -C "$PARALLEL_REPO" status --short PROJECT_CONTEXT.md)"
git -C "$PARALLEL_REPO" add -A
git -C "$PARALLEL_REPO" commit --amend --no-edit >/dev/null 2>&1

check "sync-project-context.py na branch A não suja PROJECT_CONTEXT.md (idempotente)" test -z "$STATUS_A"
check "sync-project-context.py na branch B não suja PROJECT_CONTEXT.md (idempotente)" test -z "$STATUS_B"
check "git merge entre feature/branch-a e feature/branch-b ocorre com ZERO conflitos" git -C "$PARALLEL_REPO" merge --no-edit feature/branch-a

echo ""
echo "--- 4. [HAPPY PATH] Higienização Automática de PROJECT_CONTEXT.md Legado ---"
LEGACY_REPO="$TMP_BASE/legacy_repo"
mkdir -p "$LEGACY_REPO"
cat <<'EOF' > "$LEGACY_REPO/PROJECT_CONTEXT.md"
# Contexto Canônico do Projeto (`PROJECT_CONTEXT.md`)

## 🛠️ Stack Tecnológica & Dependências
- Definida no manifesto do projeto.

## 📂 Estrutura Canônica de Diretórios
- `src/`: Código-fonte de produção.
- `docs/`: Documentação técnica viva (`docs/ARCHITECTURE.md`).

## 📍 Estado Atual da Arquitetura & Entregas (Auto-Sync)
- **Última Atualização**: 2026-11-06 01:00
- **Branch Ativa**: `feature/old-branch`
- **Último Commit**: `abc1234 - old commit`
- **Resumo de Alterações Recentes**:
```text
PROJECT_CONTEXT.md | 10 +++++-----
```

## 🛑 Regras e Invariantes Estritas (Anti-Alucinação)
1. **Grounding Mandatório**: Regra preservada.
EOF

python3 "$SYNC_SCRIPT" "$LEGACY_REPO" >/dev/null 2>&1
check "sync-project-context.py remove seção legada '## 📍 Estado Atual da Arquitetura & Entregas'" bash -c "! grep -q 'Estado Atual da Arquitetura & Entregas' '$LEGACY_REPO/PROJECT_CONTEXT.md'"
check "sync-project-context.py remove campos voláteis legados ('Branch Ativa', 'Último Commit')" bash -c "! grep -q 'Branch Ativa' '$LEGACY_REPO/PROJECT_CONTEXT.md' && ! grep -q 'Último Commit' '$LEGACY_REPO/PROJECT_CONTEXT.md'"
check "sync-project-context.py preserva seções estáveis anteriores e posteriores ao bloco legado" bash -c "grep -q 'Stack Tecnológica' '$LEGACY_REPO/PROJECT_CONTEXT.md' && grep -q 'Grounding Mandatório' '$LEGACY_REPO/PROJECT_CONTEXT.md'"

# =============================================================================
# SEÇÃO 2: EDGE CASES & FAILURE MODES
# =============================================================================
echo ""
echo "--- 5. [EDGE CASE] Workspace Sem PROJECT_CONTEXT.md ---"
EMPTY_WS="$TMP_BASE/empty_ws"
mkdir -p "$EMPTY_WS"
NO_CTX_OUTPUT="$(printf '{"workspacePaths": ["%s"]}' "$EMPTY_WS" | "$SESSION_HOOK")"
check "session-start-context.sh retorna JSON válido quando PROJECT_CONTEXT.md não existe" bash -c "printf '%s' '$NO_CTX_OUTPUT' | python3 -c 'import sys, json; json.load(sys.stdin)'"
check "session-start-context.sh informa ausência de PROJECT_CONTEXT.md no JSON" bash -c "printf '%s' '$NO_CTX_OUTPUT' | grep -q 'Nenhum PROJECT_CONTEXT.md detectado'"
check "session-start-context.sh não cria PROJECT_CONTEXT.md indevidamente no disco" test ! -f "$EMPTY_WS/PROJECT_CONTEXT.md"

python3 "$SYNC_SCRIPT" "$EMPTY_WS" >/dev/null 2>&1
check "sync-project-context.py inicializa PROJECT_CONTEXT.md quando ausente" test -f "$EMPTY_WS/PROJECT_CONTEXT.md"
check "PROJECT_CONTEXT.md recém-inicializado NÃO contém bloco volátil" bash -c "! grep -q 'Estado Atual da Arquitetura & Entregas' '$EMPTY_WS/PROJECT_CONTEXT.md' && ! grep -q 'Branch Ativa' '$EMPTY_WS/PROJECT_CONTEXT.md'"
check "PROJECT_CONTEXT.md recém-inicializado referencia docs/ARCHITECTURE.md" grep -q "docs/ARCHITECTURE.md" "$EMPTY_WS/PROJECT_CONTEXT.md"

echo ""
echo "--- 6. [EDGE CASE] Diretório Não-Git e Repositório Git Recém-Iniciado (Sem Commits) ---"
NON_GIT_WS="$TMP_BASE/non_git_ws"
mkdir -p "$NON_GIT_WS"
cp "$LIVE_REPO/PROJECT_CONTEXT.md" "$NON_GIT_WS/PROJECT_CONTEXT.md"
NON_GIT_OUT="$(printf '{"workspacePaths": ["%s"]}' "$NON_GIT_WS" | "$SESSION_HOOK")"
check "session-start-context.sh não quebra em diretório fora do Git e emite JSON válido" bash -c "printf '%s' '$NON_GIT_OUT' | python3 -c 'import sys, json; json.load(sys.stdin)'"
check "session-start-context.sh aplica fallbacks ('detached/none' e 'Sem commits registrados') fora do Git" bash -c "printf '%s' '$NON_GIT_OUT' | grep -q 'detached/none' && printf '%s' '$NON_GIT_OUT' | grep -q 'Sem commits registrados'"

UNBORN_GIT_WS="$TMP_BASE/unborn_git_ws"
mkdir -p "$UNBORN_GIT_WS"
git -C "$UNBORN_GIT_WS" init >/dev/null 2>&1
cp "$LIVE_REPO/PROJECT_CONTEXT.md" "$UNBORN_GIT_WS/PROJECT_CONTEXT.md"
UNBORN_OUT="$(printf '{"workspacePaths": ["%s"]}' "$UNBORN_GIT_WS" | "$SESSION_HOOK")"
check "session-start-context.sh não quebra em repositório Git sem commits e emite JSON válido" bash -c "printf '%s' '$UNBORN_OUT' | python3 -c 'import sys, json; json.load(sys.stdin)'"
check "session-start-context.sh usa fallback 'Sem commits registrados' em repo sem commits" bash -c "printf '%s' '$UNBORN_OUT' | grep -q 'Sem commits registrados'"

echo ""
echo "--- 7. [EDGE CASE] Entrada stdin Vazia ou JSON Malformado & Diretório Inexistente ---"
EMPTY_STDIN_OUT="$( (cd "$LIVE_REPO" && "$SESSION_HOOK" < /dev/null) )"
MALFORMED_STDIN_OUT="$( (cd "$LIVE_REPO" && printf '{malformed json' | "$SESSION_HOOK") )"
check "session-start-context.sh faz fallback para pwd com stdin vazia e retorna JSON válido" bash -c "printf '%s' '$EMPTY_STDIN_OUT' | python3 -c 'import sys, json; json.load(sys.stdin)'"
check "session-start-context.sh faz fallback para pwd com JSON malformado e retorna JSON válido" bash -c "printf '%s' '$MALFORMED_STDIN_OUT' | python3 -c 'import sys, json; json.load(sys.stdin)'"
check "sync-project-context.py falha com exit code != 0 para diretório inexistente" bash -c "! python3 '$SYNC_SCRIPT' '$TMP_BASE/diretorio_inexistente_xyz'"

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
