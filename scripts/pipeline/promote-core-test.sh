#!/usr/bin/env bash
# =============================================================================
# scripts/pipeline/promote-core-test.sh
# =============================================================================
# Utilitário determinístico para promoção segura de testes de aceitação
# de tests/features/ para a base invariante tests/core/.
#
# Suporta:
#   --list-candidates : identifica testes com marcador @core ou CORE_RULE
#   --dry-run         : simula a movimentação sem alterar o disco
#   --base <branch>   : branch base para comparações (default origin/main ou main)
#   --promote <arq>   : move o teste, valida suíte core e executa rollback se falhar
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Variáveis padrão
ACTION=""
DRY_RUN=false
CUSTOM_BASE=""
TARGET_FILE=""

show_help() {
  cat << EOF
Uso: scripts/pipeline/promote-core-test.sh [OPÇÕES]

Utilitário de promoção determinística de testes de aceitação para testes invariantes core.

Opções Principais:
  --list-candidates        Identifica e lista testes em tests/features/ candidatos a core
                           (marcados com @core ou CORE_RULE)
  --dry-run                Simula a promoção sem alterar arquivos em disco
  --base <branch>          Branch base para comparação de diff (default: origin/main ou main)
  --promote <arquivo>      Move com segurança o teste de tests/features/ para tests/core/,
                           executa a validação da suíte core e aciona rollback automático em falhas
  -h, --help               Exibe este manual de uso

Exemplos:
  ./scripts/pipeline/promote-core-test.sh --list-candidates
  ./scripts/pipeline/promote-core-test.sh --dry-run --promote tests/features/pipeline/test_foo.sh
  ./scripts/pipeline/promote-core-test.sh --promote tests/features/pipeline/test_foo.sh
EOF
}

# Parsing de argumentos
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --list-candidates)
      ACTION="list"
      shift
      ;;
    --base)
      if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
        echo "Erro: --base requer o nome de uma branch ou referência." >&2
        exit 1
      fi
      CUSTOM_BASE="$2"
      shift 2
      ;;
    --base=*)
      CUSTOM_BASE="${1#*=}"
      if [[ -z "$CUSTOM_BASE" ]]; then
        echo "Erro: --base requer o nome de uma branch ou referência." >&2
        exit 1
      fi
      shift
      ;;
    --promote)
      ACTION="promote"
      if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
        echo "Erro: --promote requer o caminho de um arquivo de teste." >&2
        exit 1
      fi
      TARGET_FILE="$2"
      shift 2
      ;;
    --promote=*)
      ACTION="promote"
      TARGET_FILE="${1#*=}"
      if [[ -z "$TARGET_FILE" ]]; then
        echo "Erro: --promote requer o caminho de um arquivo de teste." >&2
        exit 1
      fi
      shift
      ;;
    *)
      echo "Erro: Opção desconhecida: $1" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

if [[ -z "$ACTION" ]]; then
  echo "Erro: Nenhuma ação especificada (--list-candidates ou --promote <arquivo>)." >&2
  show_help >&2
  exit 1
fi

get_base_branch() {
  if [[ -n "$CUSTOM_BASE" ]]; then
    echo "$CUSTOM_BASE"
  elif git rev-parse --verify origin/main >/dev/null 2>&1; then
    echo "origin/main"
  elif git rev-parse --verify main >/dev/null 2>&1; then
    echo "main"
  else
    echo ""
  fi
}

list_candidates() {
  local base
  base="$(get_base_branch)"
  local candidates=()

  # Se houver base git válida, busca arquivos modificados/adicionados contra a base
  if [[ -n "$base" ]] && git rev-parse --verify "$base" >/dev/null 2>&1; then
    local changed_files
    changed_files=$( { git diff --name-only "$base"...HEAD 2>/dev/null || true; \
                       git diff --name-only "$base" 2>/dev/null || true; \
                       git ls-files --others --exclude-standard tests/features 2>/dev/null || true; } | sort -u )

    while IFS= read -r f; do
      if [[ -n "$f" && -f "$f" && "$f" =~ ^tests/features/.*\.sh$ ]]; then
        if grep -qiE '(@core|CORE_RULE)' "$f" 2>/dev/null; then
          candidates+=("$f")
        fi
      fi
    done <<< "$changed_files"
  fi

  # Se nenhum candidato foi localizado via diff ou não há base, varre tests/features/
  if [[ ${#candidates[@]} -eq 0 && -d "tests/features" ]]; then
    while IFS= read -r f; do
      if [[ -n "$f" && -f "$f" ]]; then
        if grep -qiE '(@core|CORE_RULE)' "$f" 2>/dev/null; then
          candidates+=("$f")
        fi
      fi
    done < <(find tests/features -type f -name "*.sh" 2>/dev/null | sort)
  fi

  for candidate in "${candidates[@]}"; do
    echo "$candidate"
  done
}

promote_test() {
  local src="$1"

  # Normaliza caminho se relativo
  if [[ ! -f "$src" && -f "tests/features/$src" ]]; then
    src="tests/features/$src"
  fi

  if [[ ! -f "$src" ]]; then
    echo "Erro: Arquivo '$src' não encontrado (inexistente)." >&2
    exit 1
  fi

  # Normaliza path relativo limpando ./ inicial
  src="${src#./}"

  if [[ "$src" != tests/features/* ]]; then
    echo "Erro: Arquivo de origem '$src' inválido. O arquivo deve estar dentro de tests/features/." >&2
    exit 1
  fi

  local filename
  filename="$(basename "$src")"
  local dest="tests/core/$filename"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Simulação de promoção: '$src' -> '$dest'"
    echo "[DRY-RUN] Validação que seria executada: ./tests/run.sh --core"
    exit 0
  fi

  mkdir -p "tests/core"

  # Executa movimentação segura
  mv "$src" "$dest"

  # Localiza executor de testes
  local test_runner=""
  if [[ -x "./tests/run.sh" ]]; then
    test_runner="./tests/run.sh"
  elif [[ -x "$WORKSPACE_ROOT/tests/run.sh" ]]; then
    test_runner="$WORKSPACE_ROOT/tests/run.sh"
  fi

  if [[ -z "$test_runner" ]]; then
    echo "Aviso: Executor ./tests/run.sh não encontrado. Validação ignorada."
    echo "[PASS] Teste '$src' promovido com sucesso para '$dest'."
    exit 0
  fi

  echo "Validando suíte core com: $test_runner --core"
  set +e
  "$test_runner" --core
  local test_status=$?
  set -e

  if [[ $test_status -eq 0 ]]; then
    echo "[PASS] Teste '$src' promovido com sucesso para '$dest' e suíte core validada (GREEN)."
    exit 0
  else
    echo "Erro: Validação da suíte core falhou com código $test_status após promover '$src'." >&2
    echo "[ROLLBACK] Revertendo promoção: movendo '$dest' de volta para '$src'..." >&2
    mkdir -p "$(dirname "$src")"
    mv "$dest" "$src"
    echo "[ROLLBACK] Rollback concluído com sucesso. Arquivo original restaurado." >&2
    exit 1
  fi
}

case "$ACTION" in
  list)
    list_candidates
    ;;
  promote)
    promote_test "$TARGET_FILE"
    ;;
esac
