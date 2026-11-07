#!/usr/bin/env bash
# =============================================================================
# tests/run.sh - Unified Deterministic Test Runner for AIDD Ecosystem
# =============================================================================
# Executa suítes de teste de aceitação e regras invariantes com fail-fast,
# métricas de execução e relatórios determinísticos por camada ou categoria.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Cores ANSI
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_GREEN="\033[32m"
C_RED="\033[31m"
C_YELLOW="\033[33m"
C_CYAN="\033[36m"
C_GRAY="\033[90m"

# Variáveis de Configuração
MODE="all"
CATEGORY=""
FILTER=""

show_help() {
  cat << EOF
${C_BOLD}tests/run.sh${C_RESET} - Executor Canônico de Testes do my-agents

${C_BOLD}Uso:${C_RESET}
  ./tests/run.sh [OPÇÕES]

${C_BOLD}Opções Principais:${C_RESET}
  --all                     Executa todos os testes (core e features) [Padrão]
  --core                    Executa apenas os testes invariantes em tests/core/
  --features                Executa todos os testes em tests/features/
  -c, --category <nome>     Executa testes de uma categoria específica:
                            (core, pipeline, governance, ui-ux, wiki, statusline)
  -f, --filter <regex>      Filtra os testes por padrão no nome do arquivo
  -h, --help                Exibe esta ajuda

${C_BOLD}Exemplos:${C_RESET}
  ./tests/run.sh
  ./tests/run.sh --core
  ./tests/run.sh --category pipeline
  ./tests/run.sh --category ui-ux --filter mockup
EOF
}

# Parsing de Argumentos
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      MODE="all"
      shift
      ;;
    --core)
      MODE="core"
      shift
      ;;
    --features)
      MODE="features"
      shift
      ;;
    -c|--category)
      if [[ -z "${2:-}" ]]; then
        echo -e "${C_RED}Erro: --category requer um nome de categoria.${C_RESET}" >&2
        exit 1
      fi
      CATEGORY="$2"
      MODE="category"
      shift 2
      ;;
    -f|--filter)
      if [[ -z "${2:-}" ]]; then
        echo -e "${C_RED}Erro: --filter requer uma expressão de filtro.${C_RESET}" >&2
        exit 1
      fi
      FILTER="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo -e "${C_RED}Opção desconhecida: $1${C_RESET}" >&2
      show_help
      exit 1
      ;;
  esac
done

# Coleta de Arquivos de Teste
TEST_FILES=()

collect_tests() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    while IFS= read -r file; do
      if [[ -n "$file" ]]; then
        if [[ -z "$FILTER" ]] || [[ "$file" =~ $FILTER ]]; then
          TEST_FILES+=("$file")
        fi
      fi
    done < <(find "$dir" -maxdepth 2 -type f -name "*.sh" ! -name "run.sh" | sort)
  fi
}

case "$MODE" in
  all)
    collect_tests "$SCRIPT_DIR/core"
    collect_tests "$SCRIPT_DIR/features"
    ;;
  core)
    collect_tests "$SCRIPT_DIR/core"
    ;;
  features)
    collect_tests "$SCRIPT_DIR/features"
    ;;
  category)
    if [[ "$CATEGORY" == "core" ]]; then
      collect_tests "$SCRIPT_DIR/core"
    elif [[ -d "$SCRIPT_DIR/features/$CATEGORY" ]]; then
      collect_tests "$SCRIPT_DIR/features/$CATEGORY"
    else
      echo -e "${C_RED}Erro: Categoria '$CATEGORY' não encontrada em tests/features/ ou tests/core/.${C_RESET}" >&2
      echo -e "${C_YELLOW}Categorias válidas: core, pipeline, governance, ui-ux, wiki, statusline${C_RESET}" >&2
      exit 1
    fi
    ;;
esac

TOTAL_TESTS=${#TEST_FILES[@]}

if [[ $TOTAL_TESTS -eq 0 ]]; then
  echo -e "${C_YELLOW}Nenhum teste encontrado para os critérios especificados (Modo: $MODE, Categoria: '$CATEGORY', Filtro: '$FILTER').${C_RESET}"
  exit 0
fi

echo -e "${C_BOLD}==============================================================================${C_RESET}"
echo -e "${C_CYAN}${C_BOLD}🧪 AIDD Test Runner - Executando $TOTAL_TESTS suíte(s) de teste${C_RESET}"
echo -e "${C_GRAY}Modo: $MODE | Categoria: ${CATEGORY:-"todas"} | Filtro: ${FILTER:-"nenhum"}${C_RESET}"
echo -e "${C_BOLD}==============================================================================${C_RESET}"
echo ""

PASSED_COUNT=0
FAILED_COUNT=0
FAILED_TESTS=()
START_TOTAL_TIME=$(date +%s)

for test_path in "${TEST_FILES[@]}"; do
  rel_path="${test_path#"$WORKSPACE_ROOT/"}"
  test_name="$(basename "$test_path")"
  test_dir="$(basename "$(dirname "$test_path")")"

  echo -e "${C_BOLD}▶ [RUN] ${test_dir}/${test_name}${C_RESET} ${C_GRAY}(${rel_path})${C_RESET}"

  START_TEST_TIME=$(date +%s)

  # Executar teste em subshell capturando saída se necessário
  set +e
  bash "$test_path"
  TEST_EXIT_CODE=$?
  set -e

  END_TEST_TIME=$(date +%s)
  DURATION=$((END_TEST_TIME - START_TEST_TIME))

  if [[ $TEST_EXIT_CODE -eq 0 ]]; then
    echo -e "${C_GREEN}${C_BOLD}✔ [PASS]${C_RESET} ${test_dir}/${test_name} ${C_GRAY}(${DURATION}s)${C_RESET}"
    PASSED_COUNT=$((PASSED_COUNT + 1))
  else
    echo -e "${C_RED}${C_BOLD}✘ [FAIL]${C_RESET} ${test_dir}/${test_name} (Exit code: $TEST_EXIT_CODE) ${C_GRAY}(${DURATION}s)${C_RESET}"
    FAILED_COUNT=$((FAILED_COUNT + 1))
    FAILED_TESTS+=("${rel_path} (Exit: $TEST_EXIT_CODE)")
  fi
  echo -e "${C_GRAY}------------------------------------------------------------------------------${C_RESET}"
done

END_TOTAL_TIME=$(date +%s)
TOTAL_DURATION=$((END_TOTAL_TIME - START_TOTAL_TIME))

echo ""
echo -e "${C_BOLD}==============================================================================${C_RESET}"
echo -e "${C_BOLD}📊 Relatório Consolidado de Execução${C_RESET}"
echo -e "${C_BOLD}==============================================================================${C_RESET}"
echo -e "Total de Suítes Executadas: ${C_BOLD}$TOTAL_TESTS${C_RESET}"
echo -e "Sucessos:                   ${C_GREEN}${C_BOLD}$PASSED_COUNT${C_RESET}"
echo -e "Falhas:                     ${C_RED}${C_BOLD}$FAILED_COUNT${C_RESET}"
echo -e "Duração Total:              ${C_BOLD}${TOTAL_DURATION}s${C_RESET}"
echo -e "${C_BOLD}==============================================================================${C_RESET}"

if [[ $FAILED_COUNT -gt 0 ]]; then
  echo -e "${C_RED}${C_BOLD}🚨 Testes com Falha:${C_RESET}"
  for failed in "${FAILED_TESTS[@]}"; do
    echo -e "  ${C_RED}✘ $failed${C_RESET}"
  done
  echo -e "${C_RED}${C_BOLD}CIRCUIT BREAKER ACIONADO: A suíte de testes falhou!${C_RESET}"
  exit 1
fi

echo -e "${C_GREEN}${C_BOLD}🎉 100% DAS SUÍTES DE TESTE PASSARAM COM SUCESSO!${C_RESET}"
exit 0
