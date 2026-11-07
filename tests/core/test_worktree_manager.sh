#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Test Suite: Git Worktree Lifecycle Manager (scripts/pipeline/worktree-manager.sh)
# TDD Phase: RED
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKTREE_SCRIPT="$REPO_ROOT/scripts/pipeline/worktree-manager.sh"

echo "========================================================================"
echo " [TEST] Git Worktree Lifecycle Manager (scripts/pipeline/worktree-manager.sh)"
echo "========================================================================"

# Configuração de repositório git temporário e estéril para isolamento completo
TEMP_REPO=$(mktemp -d -t test_worktree_repo_XXXXXX)
TEMP_RESULTS="$TEMP_REPO/.test_results"
touch "$TEMP_RESULTS"

cleanup() {
  if [ -n "${DUMMY_PID:-}" ] && kill -0 "$DUMMY_PID" 2>/dev/null; then
    kill -9 "$DUMMY_PID" 2>/dev/null || true
  fi
  rm -rf "$TEMP_REPO"
}
trap cleanup EXIT

# Helpers de asserção resilientes a subshells
assert_equal() {
  local desc="$1"
  local expected="$2"
  local actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  [PASS] $desc"
    echo "PASS" >> "$TEMP_RESULTS"
  else
    echo "  [FAIL] $desc (Esperado: '$expected', Obtido: '$actual')"
    echo "FAIL" >> "$TEMP_RESULTS"
  fi
}

assert_true() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  [PASS] $desc"
    echo "PASS" >> "$TEMP_RESULTS"
  else
    echo "  [FAIL] $desc"
    echo "FAIL" >> "$TEMP_RESULTS"
  fi
}

# Inicialização do repositório git temporário
(
  cd "$TEMP_REPO"
  git init -b main >/dev/null 2>&1
  git config user.name "QA Engineer"
  git config user.email "qa@pipeline.local"

  mkdir -p tests/core tests/features src
  echo "Core security logic v1" > tests/core/auth_core.txt
  echo "Existing feature spec v1" > tests/features/existing_feature.txt
  echo "App baseline code v1" > src/app.txt

  git add .
  git commit -m "chore: baseline commit for test repository" >/dev/null 2>&1
)

# -----------------------------------------------------------------------------
# 0. Verificação Prévia de Existência do Script
# -----------------------------------------------------------------------------
echo ""
echo "--- 0. Verificação Prévia do Script ---"
assert_true "scripts/pipeline/worktree-manager.sh existe e é executável" test -x "$WORKTREE_SCRIPT"

# -----------------------------------------------------------------------------
# 1. Happy Path: Subcomandos Básicos e Ciclo de Vida
# -----------------------------------------------------------------------------
echo ""
echo "--- 1. Happy Path: create, list, custom --base, rebase-sync, remove ---"

# Happy Path 1: create
(
  cd "$TEMP_REPO"
  STATUS=0
  "$WORKTREE_SCRIPT" create 8 >/tmp/wt_create_8.log 2>&1 || STATUS=$?
  assert_equal "Happy Path 1.1: 'create 8' retorna exit code 0" "0" "$STATUS"
  assert_true "Happy Path 1.2: Diretório '.worktrees/issue-8' foi criado" test -d ".worktrees/issue-8"
  
  CURRENT_BRANCH=$(git -C ".worktrees/issue-8" branch --show-current 2>/dev/null || echo "")
  assert_equal "Happy Path 1.3: Worktree está na branch 'feature/issue-8'" "feature/issue-8" "$CURRENT_BRANCH"

  assert_true "Happy Path 1.4: Lockfile '.worktrees/.lock-8' existe" test -f ".worktrees/.lock-8"
  LOCK_PID=$(cat ".worktrees/.lock-8" 2>/dev/null || echo "")
  assert_true "Happy Path 1.5: Lockfile contém PID numérico válido" test -n "$LOCK_PID"
)

# Happy Path 2: list
(
  cd "$TEMP_REPO"
  STATUS=0
  LIST_OUTPUT=$("$WORKTREE_SCRIPT" list 2>&1) || STATUS=$?
  assert_equal "Happy Path 2.1: 'list' retorna exit code 0" "0" "$STATUS"
  assert_true "Happy Path 2.2: 'list' lista a issue-8 criada" bash -c "echo '$LIST_OUTPUT' | grep -q 'issue-8'"
  assert_true "Happy Path 2.3: 'list' exibe status de lock ativo" bash -c "echo '$LIST_OUTPUT' | grep -qi 'lock'"
)

# Happy Path 3: create com branch base customizada (--base <branch>)
(
  cd "$TEMP_REPO"
  # Cria branch base customizada com commit próprio
  git checkout -b integration/wave-1 >/dev/null 2>&1
  echo "wave 1 content" > src/wave1.txt
  git add src/wave1.txt
  git commit -m "feat: wave 1 integration baseline" >/dev/null 2>&1
  BASE_COMMIT=$(git rev-parse HEAD)
  git checkout main >/dev/null 2>&1

  STATUS=0
  "$WORKTREE_SCRIPT" create 9 --base integration/wave-1 >/tmp/wt_create_9.log 2>&1 || STATUS=$?
  assert_equal "Happy Path 3.1: 'create 9 --base integration/wave-1' retorna exit code 0" "0" "$STATUS"
  assert_true "Happy Path 3.2: Diretório '.worktrees/issue-9' foi criado" test -d ".worktrees/issue-9"

  WT9_BASE_COMMIT=$(git -C ".worktrees/issue-9" rev-parse HEAD 2>/dev/null || echo "")
  assert_equal "Happy Path 3.3: Worktree deriva exatamente do commit de 'integration/wave-1'" "$BASE_COMMIT" "$WT9_BASE_COMMIT"
)

# Happy Path 4: rebase-sync limpo
(
  cd "$TEMP_REPO"
  # Adiciona commit na main
  echo "new main feature" > src/main_feat.txt
  git add src/main_feat.txt
  git commit -m "feat: new main feature commit" >/dev/null 2>&1

  # Adiciona commit na branch da issue-8 dentro de sua worktree se existir
  if [ -d ".worktrees/issue-8" ]; then
    mkdir -p .worktrees/issue-8/src
    echo "issue 8 implementation" > .worktrees/issue-8/src/feat8.txt
    (
      cd .worktrees/issue-8
      git add src/feat8.txt
      git commit -m "feat(issue-8): implemented feature 8" >/dev/null 2>&1
    )
  fi

  STATUS=0
  "$WORKTREE_SCRIPT" rebase-sync 8 >/tmp/wt_rebase_sync_8.log 2>&1 || STATUS=$?
  assert_equal "Happy Path 4.1: 'rebase-sync 8' em árvore limpa retorna exit code 0" "0" "$STATUS"

  # Valida que main agora é ancestral da HEAD da issue-8
  IS_ANCESTOR=0
  git -C ".worktrees/issue-8" merge-base --is-ancestor main HEAD 2>/dev/null || IS_ANCESTOR=$?
  assert_equal "Happy Path 4.2: Branch da issue foi rebaseada no topo de main" "0" "$IS_ANCESTOR"
)

# Happy Path 5: remove (garante anti-trivialidade com pre-state)
(
  cd "$TEMP_REPO"
  # Para testar a remoção de forma não-trivial mesmo se create 8 tiver falhado na fase RED
  mkdir -p .worktrees/issue-8
  echo "$$" > .worktrees/.lock-8

  STATUS=0
  "$WORKTREE_SCRIPT" remove 8 >/tmp/wt_remove_8.log 2>&1 || STATUS=$?
  assert_equal "Happy Path 5.1: 'remove 8' retorna exit code 0" "0" "$STATUS"
  assert_true "Happy Path 5.2: Diretório '.worktrees/issue-8' foi desmontado e removido" test ! -d ".worktrees/issue-8"
  assert_true "Happy Path 5.3: Lockfile '.worktrees/.lock-8' foi purgado" test ! -f ".worktrees/.lock-8"

  WT_LIST=$(git worktree list)
  assert_true "Happy Path 5.4: Git worktrees não contém mais registro de 'issue-8'" bash -c "! echo '$WT_LIST' | grep -q 'issue-8'"
)

# -----------------------------------------------------------------------------
# 2. Edge Cases / Failure Modes: Concorrência, Stale Lock, Parâmetros e Fraude
# -----------------------------------------------------------------------------
echo ""
echo "--- 2. Edge Cases: Concorrência, Stale Lock, Fraude e Conflito ---"

# Edge Case 1: Concorrência fail-fast (Lock ativo -> exit code 2)
(
  cd "$TEMP_REPO"
  mkdir -p .worktrees
  # Inicia processo ativo em background para segurar PID
  sleep 30 &
  DUMMY_PID=$!
  echo "$DUMMY_PID" > .worktrees/.lock-20

  STATUS=0
  OUTPUT=$("$WORKTREE_SCRIPT" create 20 2>&1) || STATUS=$?
  kill -9 "$DUMMY_PID" 2>/dev/null || true
  rm -f .worktrees/.lock-20

  assert_equal "Edge Case 1.1: Concorrência ativa retorna exit code 2" "2" "$STATUS"
  assert_true "Edge Case 1.2: Mensagem indica bloqueio por lock ativo" bash -c "echo '$OUTPUT' | grep -qi 'lock'"
)

# Edge Case 2: Recuperação graciosa de Stale Lock (PID morto -> prossegue exit 0)
(
  cd "$TEMP_REPO"
  mkdir -p .worktrees
  # PID 999999 quase certamente não existe em Linux padrão
  STALE_PID=999999
  while kill -0 "$STALE_PID" 2>/dev/null; do
    STALE_PID=$((STALE_PID + 1))
  done
  echo "$STALE_PID" > .worktrees/.lock-21

  STATUS=0
  "$WORKTREE_SCRIPT" create 21 >/tmp/wt_create_21.log 2>&1 || STATUS=$?
  assert_equal "Edge Case 2.1: Recuperação de stale lock permite 'create 21' com exit code 0" "0" "$STATUS"
  assert_true "Edge Case 2.2: Worktree '.worktrees/issue-21' criada após recuperação de stale lock" test -d ".worktrees/issue-21"

  NEW_LOCK_PID=$(cat ".worktrees/.lock-21" 2>/dev/null || echo "")
  assert_true "Edge Case 2.3: Lockfile foi sobrescrito com novo PID ativo" bash -c "[ -n '$NEW_LOCK_PID' ] && [ '$NEW_LOCK_PID' != '$STALE_PID' ]"
)

# Edge Case 3: Parâmetros inválidos ou base inexistente (exit code 1)
(
  cd "$TEMP_REPO"
  STATUS=0
  "$WORKTREE_SCRIPT" >/dev/null 2>&1 || STATUS=$?
  assert_equal "Edge Case 3.1: Chamada sem argumentos retorna exit code 1" "1" "$STATUS"

  STATUS=0
  "$WORKTREE_SCRIPT" create >/dev/null 2>&1 || STATUS=$?
  assert_equal "Edge Case 3.2: 'create' sem issue_id retorna exit code 1" "1" "$STATUS"

  STATUS=0
  "$WORKTREE_SCRIPT" create 22 --base branch-fantasma-inexistente >/dev/null 2>&1 || STATUS=$?
  assert_equal "Edge Case 3.3: 'create' com branch base inexistente retorna exit code 1" "1" "$STATUS"
)

# Edge Case 4: Fraude no rebase-sync - violação em tests/core/ (exit code 3)
(
  cd "$TEMP_REPO"
  # Criar worktree para issue-30
  "$WORKTREE_SCRIPT" create 30 >/dev/null 2>&1 || true

  # Simula alteração fraudulenta em tests/core/
  if [ -d ".worktrees/issue-30" ]; then
    echo "malicious modification" >> .worktrees/issue-30/tests/core/auth_core.txt
    (
      cd .worktrees/issue-30
      git add tests/core/auth_core.txt
      git commit -m "fraud: illegal modification in tests/core" >/dev/null 2>&1
    )
  fi

  STATUS=0
  OUTPUT=$("$WORKTREE_SCRIPT" rebase-sync 30 2>&1) || STATUS=$?
  assert_equal "Edge Case 4.1: Fraude em tests/core/ durante rebase-sync retorna exit code 3" "3" "$STATUS"
  assert_true "Edge Case 4.2: Mensagem reporta fraude/violação de integridade em tests/core/" bash -c "echo '$OUTPUT' | grep -qiE '(fraude|tests/core|violação|golden rule)'"
)

# Edge Case 5: Fraude no rebase-sync - violação em tests/features/ pré-existente (exit code 3)
(
  cd "$TEMP_REPO"
  # Criar worktree para issue-31
  "$WORKTREE_SCRIPT" create 31 >/dev/null 2>&1 || true

  # Simula alteração fraudulenta sobrescrevendo teste pré-existente
  if [ -d ".worktrees/issue-31" ]; then
    echo "tampered existing test" >> .worktrees/issue-31/tests/features/existing_feature.txt
    (
      cd .worktrees/issue-31
      git add tests/features/existing_feature.txt
      git commit -m "fraud: overwrite pre-existing feature test" >/dev/null 2>&1
    )
  fi

  STATUS=0
  OUTPUT=$("$WORKTREE_SCRIPT" rebase-sync 31 2>&1) || STATUS=$?
  assert_equal "Edge Case 5.1: Alteração em feature test pré-existente retorna exit code 3" "3" "$STATUS"
  assert_true "Edge Case 5.2: Mensagem reporta fraude/alteração em testes pré-existentes de features" bash -c "echo '$OUTPUT' | grep -qiE '(fraude|pré-existente|pre-existing|violação)'"
)

# Edge Case 6: Conflito textual com auto-abort no rebase-sync (exit code 4)
(
  cd "$TEMP_REPO"
  # Criar worktree para issue-32
  "$WORKTREE_SCRIPT" create 32 >/dev/null 2>&1 || true

  # Provoca conflito direto na mesma linha de app.txt
  if [ -d ".worktrees/issue-32" ]; then
    echo "line modified by issue 32" > .worktrees/issue-32/src/app.txt
    (
      cd .worktrees/issue-32
      git add src/app.txt
      git commit -m "feat(32): change app line" >/dev/null 2>&1
    )
  fi

  # Na main, modifica a mesma linha
  echo "line modified by main concurrently" > src/app.txt
  git add src/app.txt
  git commit -m "feat(main): conflicting change on app line" >/dev/null 2>&1

  STATUS=0
  OUTPUT=$("$WORKTREE_SCRIPT" rebase-sync 32 2>&1) || STATUS=$?
  assert_equal "Edge Case 6.1: Conflito textual de rebase retorna exit code 4" "4" "$STATUS"
  assert_true "Edge Case 6.2: Mensagem reporta conflito de rebase" bash -c "echo '$OUTPUT' | grep -qi 'conflito'"

  # Verifica que a worktree NÃO ficou presa em rebase em andamento (auto-abort)
  IS_REBASING=0
  if [ -d ".worktrees/issue-32" ]; then
    GIT_DIR=$(git -C ".worktrees/issue-32" rev-parse --git-dir 2>/dev/null || echo "")
    if [ -n "$GIT_DIR" ] && { [ -d "$GIT_DIR/rebase-apply" ] || [ -d "$GIT_DIR/rebase-merge" ]; }; then
      IS_REBASING=1
    fi
  else
    # Se worktree não foi criada (fase RED), não podemos considerar auto-abort cumprido
    IS_REBASING=1
  fi
  assert_equal "Edge Case 6.3: Auto-abort executado (worktree limpa sem rebase pendente)" "0" "$IS_REBASING"
)

# -----------------------------------------------------------------------------
# Resumo Final
# -----------------------------------------------------------------------------
echo ""
PASSED_TESTS=$(grep -c "^PASS$" "$TEMP_RESULTS" || true)
FAILED_TESTS=$(grep -c "^FAIL$" "$TEMP_RESULTS" || true)
TOTAL_TESTS=$((PASSED_TESTS + FAILED_TESTS))

echo "========================================================================"
echo " Resumo dos Testes: $PASSED_TESTS de $TOTAL_TESTS passaram."
echo "========================================================================"

if [ "$FAILED_TESTS" -ne 0 ]; then
  echo " [RED] Suíte falhou conforme o esperado para a fase RED do TDD ($FAILED_TESTS falhas)."
  exit 1
else
  echo " [GREEN] Todos os testes passaram."
  exit 0
fi
