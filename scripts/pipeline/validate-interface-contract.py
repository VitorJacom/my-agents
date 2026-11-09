#!/usr/bin/env python3
"""
scripts/pipeline/validate-interface-contract.py
=============================================================================
Portão determinístico de validação estrita do Interface Contract (AIDD).
Valida a presença e conformidade da seção '## Interface Contract' em planos
de implementação (implementation_plan.md, planning_proposal.md ou issues).

Pilares Obrigatórios:
1. Signatures (Assinaturas completas tipadas de métodos e funções)
2. Types & Interfaces (Tipos, modelos de dados, structs e schemas)
3. Inputs (Parâmetros tipados e restrições de validação)
4. Outputs (Retornos esperados tipados)
5. Errors (Tratamento de erros e exceções mapeadas)
=============================================================================
"""

import sys
import os
import re
import argparse

REQUIRED_PILLARS = {
    "Signatures": [r"signatures?", r"assinaturas?"],
    "Types & Interfaces": [r"types?\s*(?:&|e)?\s*interfaces?", r"interfaces?", r"tipagens?", r"tipos?", r"structs?"],
    "Inputs": [r"inputs?", r"entradas?", r"par[âa]metros?"],
    "Outputs": [r"outputs?", r"sa[íi]das?", r"retornos?"],
    "Errors": [r"errors?", r"erros?", r"exce[çc][õo]es?", r"failure\s+modes?"]
}

ALL_PILLAR_KEYWORDS = [
    r"signatures?", r"assinaturas?",
    r"types?\s*(?:&|e)?\s*interfaces?", r"interfaces?", r"tipagens?", r"tipos?", r"structs?",
    r"inputs?", r"entradas?", r"par[âa]metros?",
    r"outputs?", r"sa[íi]das?", r"retornos?",
    r"errors?", r"erros?", r"exce[çc][õo]es?", r"failure\s+modes?"
]
COMBINED_DELIM_PATTERN = rf"(?:^|\n)\s*[-*#\s]*\b(?:{'|'.join(ALL_PILLAR_KEYWORDS)})\b[-*#\s]*[:\-]"

AMBIGUOUS_PATTERNS = [
    r"^[\s\*\-\.\:\`]*(todo|tbd|a\s+definir|em\s+breve|n/a|na|none|nenhum|indefinido|qualquer|any|placeholder)[\s\*\-\.\:\`]*$",
    r"(supõe-se|presume-se|obviamente|deve\s+funcionar|assumindo\s+que)"
]

def extract_interface_contract_section(text: str) -> str | None:
    """Extrai o conteúdo da seção ## Interface Contract."""
    match = re.search(r"^##+\s+.*Interface\s+Contract.*$", text, re.MULTILINE | re.IGNORECASE)
    if not match:
        return None
    
    start_pos = match.end()
    # Encontra o próximo cabeçalho h1 ou h2 (ex: ## Próximo ou # Título)
    next_header = re.search(r"^##?\s+[^#].*$", text[start_pos:], re.MULTILINE)
    if next_header:
        section = text[start_pos:start_pos + next_header.start()]
    else:
        section = text[start_pos:]
    return section

def extract_pillar_text(section: str, patterns: list[str]) -> str | None:
    """Extrai o texto isolado pertencente a um pilar específico."""
    pat_str = "|".join(patterns)
    start_regex = re.compile(
        rf"(?:^|\n)\s*[-*#\s]*\b(?P<tag>{pat_str})\b[-*#\s]*[:\-]\s*(?P<inline>.*)",
        re.IGNORECASE
    )
    
    match = start_regex.search(section)
    if not match:
        # Tenta cabeçalho markdown isolado (ex: "### Signatures")
        header_regex = re.compile(
            rf"(?:^|\n)\s*###+\s+(?:{pat_str})\s*$",
            re.IGNORECASE
        )
        h_match = header_regex.search(section)
        if not h_match:
            return None
        start_idx = h_match.end()
        inline_val = ""
    else:
        start_idx = match.end()
        inline_val = match.group("inline").strip()

    remaining = section[start_idx:]
    next_delim = re.search(COMBINED_DELIM_PATTERN, remaining, re.IGNORECASE)
    if next_delim:
        block = remaining[:next_delim.start()].strip()
    else:
        block = remaining.strip()
        
    full_text = f"{inline_val}\n{block}".strip()
    return full_text

def validate_interface_contract(content: str) -> tuple[bool, list[str]]:
    """Valida o conteúdo de um plano contra o Interface Contract Gate."""
    errors = []
    
    if not content.strip():
        return False, ["Arquivo ou conteúdo está vazio."]
    
    section = extract_interface_contract_section(content)
    if section is None:
        return False, [
            "Seção '## Interface Contract' ausente no plano.",
            "O contrato de interface tipado é obrigatório para que QA e Coder operem simultaneamente."
        ]
    
    if not section.strip():
        return False, ["A seção '## Interface Contract' está vazia."]
    
    # Valida cada um dos 5 pilares
    for pillar_name, patterns in REQUIRED_PILLARS.items():
        val_text = extract_pillar_text(section, patterns)
        
        if val_text is None:
            errors.append(f"Pilar obrigatório ausente no Interface Contract: '{pillar_name}'.")
            continue
        
        if not val_text:
            errors.append(f"Pilar '{pillar_name}' está sem conteúdo ou definição técnica.")
            continue
        
        # Checa termos ambíguos ou placeholders
        for amb_pattern in AMBIGUOUS_PATTERNS:
            if re.search(amb_pattern, val_text, re.IGNORECASE):
                errors.append(
                    f"Pilar '{pillar_name}' contém placeholder ou especulação ambígua ('{val_text[:60]}...'). "
                    "Assinaturas e tipagens devem ser estritamente tipadas e concretas."
                )
                break

    is_valid = len(errors) == 0
    return is_valid, errors

def main():
    parser = argparse.ArgumentParser(
        description="Portão determinístico de validação estrita do Interface Contract (AIDD)."
    )
    parser.add_argument(
        "file",
        nargs="?",
        default=None,
        help="Caminho do arquivo contendo o plano (ex: implementation_plan.md). Se omitido, lê de stdin."
    )
    args = parser.parse_args()

    if args.file and args.file != "-":
        if not os.path.exists(args.file):
            print(f"❌ [INTERFACE_CONTRACT_ERROR] Arquivo alvo '{args.file}' não encontrado.", file=sys.stderr)
            sys.exit(1)
        with open(args.file, "r", encoding="utf-8") as f:
            content = f.read()
    else:
        content = sys.stdin.read()

    is_valid, errors = validate_interface_contract(content)

    if not is_valid:
        for err in errors:
            print(f"❌ [INTERFACE_CONTRACT_ERROR] {err}", file=sys.stderr)
        print("", file=sys.stderr)
        print("🚨 [INTERFACE_CONTRACT_ERROR] Validação falhou: Interface Contract ausente, incompleto ou ambíguo.", file=sys.stderr)
        print("   O planejamento foi REJEITADO. Concretize assinaturas, tipagens, inputs, outputs e erros.", file=sys.stderr)
        sys.exit(1)

    print("✅ [INTERFACE_CONTRACT_VALID] Interface Contract padronizado e aprovado com sucesso.")
    print("   Símbolos, tipagens, inputs, outputs e erros estão formalmente definidos para QA e Coder.")
    sys.exit(0)

if __name__ == "__main__":
    main()
