#!/usr/bin/env python3
"""
scripts/pipeline/contract-integration-gate.py
=============================================================================
Portão determinístico de integração do contrato (Join Point) da esteira AIDD.
Executa a validação consolidada entre os testes criados pelo qa-engineer em
tests/features/ e o código de produção implementado pelo coder em src/.

Coordena:
1. Validação do Join Point (Suíte 100% verde & Cobertura >= 85%).
2. Loop de Reconciliação com teto rígido de até 2 iterações.
3. Fail-safe determinístico (Exit Code 2) caso as 2 iterações se esgotem.
4. Verificação de confinamento de escopo e travas anti-fraude (Exit Code 3).
=============================================================================
"""

import sys
import os
import re
import json
import argparse
import subprocess
from typing import Literal, TypedDict

GateStatus = Literal[
    "APPROVED",
    "RECONCILE_REQUIRED",
    "FAILED_CONTRACT_INTEGRATION",
    "ANTI_FRAUD_VIOLATION"
]

class JoinPointResult(TypedDict):
    status: GateStatus
    iteration: int
    max_iterations: int
    test_exit_code: int
    coverage: float | None
    min_coverage: float
    message: str


def evaluate_join_point(
    test_exit_code: int,
    iteration: int,
    max_iterations: int = 2,
    coverage: float | None = None,
    min_coverage: float = 85.0
) -> dict:
    """
    Avalia o estado do Join Point considerando o código de retorno da suíte,
    o número da iteração e a cobertura aferida.
    """
    if iteration < 1:
        raise ValueError("O número da iteração deve ser um inteiro maior ou igual a 1.")
    if max_iterations < 1:
        raise ValueError("O número máximo de iterações deve ser maior ou igual a 1.")
    if coverage is not None and (coverage < 0.0 or coverage > 100.0):
        raise ValueError("A cobertura deve ser um valor percentual entre 0.0 e 100.0.")
    if min_coverage < 0.0 or min_coverage > 100.0:
        raise ValueError("A cobertura mínima deve ser um valor percentual entre 0.0 e 100.0.")

    tests_passed = (test_exit_code == 0)
    coverage_passed = (coverage is None or coverage >= min_coverage)

    if tests_passed and coverage_passed:
        cov_info = f" e cobertura de {coverage:.1f}% >= {min_coverage:.1f}%" if coverage is not None else ""
        return {
            "status": "APPROVED",
            "iteration": iteration,
            "max_iterations": max_iterations,
            "test_exit_code": test_exit_code,
            "coverage": coverage,
            "min_coverage": min_coverage,
            "message": f"Suíte 100% GREEN (Exit code 0){cov_info}. Avanço autorizado para o próximo portão."
        }

    # Houve falha na suíte ou déficit de cobertura
    if not tests_passed and not coverage_passed:
        motivo = f"falha na suíte (exit code {test_exit_code}) e cobertura insuficiente ({coverage:.1f}% < {min_coverage:.1f}%)"
    elif not tests_passed:
        motivo = f"falha na suíte de testes (exit code {test_exit_code})"
    else:
        motivo = f"cobertura de código insuficiente ({coverage:.1f}% < {min_coverage:.1f}%)"

    if iteration > max_iterations:
        return {
            "status": "FAILED_CONTRACT_INTEGRATION",
            "iteration": iteration,
            "max_iterations": max_iterations,
            "test_exit_code": test_exit_code,
            "coverage": coverage,
            "min_coverage": min_coverage,
            "message": f"Circuit breaker acionado: limite de {max_iterations} iterações esgotado por {motivo}."
        }
    else:
        return {
            "status": "RECONCILE_REQUIRED",
            "iteration": iteration,
            "max_iterations": max_iterations,
            "test_exit_code": test_exit_code,
            "coverage": coverage,
            "min_coverage": min_coverage,
            "message": f"Discrepâncias detectadas no Join Point ({motivo}) na tentativa {iteration} de {max_iterations}. Reconciliação requerida com coder em src/."
        }


def normalize_canonical_path(path: str) -> str:
    """
    Normaliza o caminho removendo barras iniciais, './' e extraindo o prefixo canônico
    (src/ ou tests/) mesmo se o caminho fornecido for absoluto ou contiver diretórios pais.
    """
    p = path.strip()
    match = re.search(r"(?:^|/)(src/.*|tests/.*)$", p)
    if match:
        return match.group(1)
    return p.lstrip("./")


def verify_persona_confinement(
    qa_modified_files: list[str],
    coder_modified_files: list[str]
) -> tuple[bool, str]:
    """
    Valida as travas de integridade e confinamento de escopo:
    - qa-engineer é proibido de tocar em src/ e tests/core/
    - coder é proibido de tocar em tests/
    Suporta tanto caminhos relativos quanto absolutos.
    """
    violations = []

    for path in qa_modified_files:
        clean = normalize_canonical_path(path)
        if clean.startswith("src/"):
            violations.append(f"qa-engineer modificou arquivo de produção proibido: '{clean}'")
        elif clean.startswith("tests/core/"):
            violations.append(f"qa-engineer violou a Golden Rule em tests/core/: '{clean}'")

    for path in coder_modified_files:
        clean = normalize_canonical_path(path)
        if clean.startswith("tests/"):
            violations.append(f"coder violou a Trava Anti-Fraude ao modificar arquivo em tests/: '{clean}'")

    if violations:
        return False, " | ".join(violations)

    return True, "Confinamento de escopo validado com sucesso (zero violação anti-fraude)."


def run_test_command(cmd: str) -> tuple[int, str]:
    """Executa o comando da suíte de testes em subprocesso com captura de saída."""
    try:
        proc = subprocess.run(
            cmd,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )
        return proc.returncode, proc.stdout
    except Exception as e:
        return 127, f"Erro catastrófico ao invocar o comando de teste '{cmd}': {e}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Portão determinístico de integração do contrato (Join Point) - AIDD",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--test-cmd", default="./tests/run.sh", help="Comando para executar a suíte de testes")
    parser.add_argument("--test-exit-code", type=int, default=None, help="Código de saída simulado ou pré-executado")
    parser.add_argument("--iteration", type=int, default=1, help="Número da iteração ativa de reconciliação (>= 1)")
    parser.add_argument("--max-iterations", type=int, default=2, help="Teto máximo de iterações permitidas (default: 2)")
    parser.add_argument("--coverage", type=float, default=None, help="Percentual de cobertura de código aferido")
    parser.add_argument("--min-coverage", type=float, default=85.0, help="Cobertura mínima exigida em %% (default: 85.0)")
    parser.add_argument("--qa-files", default="", help="Lista separada por vírgulas de arquivos tocados pelo QA")
    parser.add_argument("--coder-files", default="", help="Lista separada por vírgulas de arquivos tocados pelo Coder")
    parser.add_argument("--json", action="store_true", help="Emite resultado em formato JSON")

    args = parser.parse_args(argv)

    # 1. Validação de Confinamento de Escopo (Anti-Fraude)
    qa_list = [f.strip() for f in args.qa_files.split(",") if f.strip()]
    coder_list = [f.strip() for f in args.coder_files.split(",") if f.strip()]

    if qa_list or coder_list:
        confinement_ok, confinement_msg = verify_persona_confinement(qa_list, coder_list)
        if not confinement_ok:
            if args.json:
                print(json.dumps({
                    "status": "ANTI_FRAUD_VIOLATION",
                    "iteration": args.iteration,
                    "max_iterations": args.max_iterations,
                    "test_exit_code": args.test_exit_code if args.test_exit_code is not None else -1,
                    "coverage": args.coverage,
                    "min_coverage": args.min_coverage,
                    "message": confinement_msg
                }, indent=2))
            else:
                print(f"🚨 [JOIN_POINT: ANTI_FRAUD_VIOLATION] {confinement_msg}")
            return 3

    # 2. Obtenção do resultado do teste
    output_log = ""
    if args.test_exit_code is not None:
        exit_code = args.test_exit_code
    else:
        exit_code, output_log = run_test_command(args.test_cmd)

    # 3. Avaliação do Join Point
    try:
        result = evaluate_join_point(
            test_exit_code=exit_code,
            iteration=args.iteration,
            max_iterations=args.max_iterations,
            coverage=args.coverage,
            min_coverage=args.min_coverage
        )
    except ValueError as ve:
        print(f"❌ [JOIN_POINT: ERROR] Parâmetro inválido: {ve}", file=sys.stderr)
        return 1

    # 4. Formatação de Saída
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        status_tag = result["status"]
        msg = result["message"]
        if status_tag == "APPROVED":
            print(f"✅ [JOIN_POINT: APPROVED] {msg}")
        elif status_tag == "RECONCILE_REQUIRED":
            print(f"⚠️ [JOIN_POINT: RECONCILE_REQUIRED] {msg}")
        elif status_tag == "FAILED_CONTRACT_INTEGRATION":
            print(f"🚨 [JOIN_POINT: FAILED_CONTRACT_INTEGRATION] {msg}")

    # 5. Código de saída determinístico
    if result["status"] == "APPROVED":
        return 0
    elif result["status"] == "RECONCILE_REQUIRED":
        return 1
    elif result["status"] == "FAILED_CONTRACT_INTEGRATION":
        return 2
    else:
        return 3


if __name__ == "__main__":
    sys.exit(main())
