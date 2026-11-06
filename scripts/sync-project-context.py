#!/usr/bin/env python3
"""
sync-project-context.py: Valida e mantém a estrutura estática e invariantes canônicas
do PROJECT_CONTEXT.md sem injetar estado volátil do Git (branch, commit, timestamp),
garantindo idempotência pura e zero conflitos em Pull Requests ou Worktrees paralelos.
"""

import os
import sys

INITIAL_TEMPLATE = """# Contexto Canônico do Projeto (`PROJECT_CONTEXT.md`)

## 🛠️ Stack Tecnológica & Dependências
- Definida no manifesto do projeto (consulte `package.json` / `pyproject.toml`).
- **Invariante**: Proibido adicionar ou supor dependências externas sem aprovação explícita.

## 📂 Estrutura Canônica de Diretórios
- `src/`: Código-fonte de produção.
- `tests/`: Suíte de testes automatizados (`tests/core/` para testes de base e `tests/features/` para novas features TDD).
- `docs/`: Documentação técnica viva e decisões consolidadas (`docs/ARCHITECTURE.md`).

## 🛑 Regras e Invariantes Estritas (Anti-Alucinação)
1. **Grounding Mandatório**: Não invente diretórios ou convenções de nomenclatura fora do padrão declarado acima.
2. **Duplo Gate**: Nenhuma alteração é comitada sem passar pela auditoria de conformidade do Gatekeeper.
"""

LEGACY_VOLATILE_MARKER = "## 📍 Estado Atual da Arquitetura & Entregas"


def strip_legacy_volatile_section(content: str) -> str:
    """Remove o bloco volátil legado de Auto-Sync caso exista, preservando o restante."""
    if LEGACY_VOLATILE_MARKER not in content:
        return content

    parts = content.split(LEGACY_VOLATILE_MARKER, 1)
    before = parts[0].rstrip()
    rest = parts[1]
    next_h2_idx = rest.find("\n## ")
    if next_h2_idx != -1:
        after = rest[next_h2_idx + 1 :].lstrip()
        return f"{before}\n\n{after}"
    return f"{before}\n"


def sync_context(workspace_dir: str) -> None:
    if not os.path.isdir(workspace_dir):
        print(f"[ERRO] Diretório de workspace inexistente: {workspace_dir}", file=sys.stderr)
        sys.exit(1)

    context_path = os.path.join(workspace_dir, "PROJECT_CONTEXT.md")

    if not os.path.exists(context_path):
        with open(context_path, "w", encoding="utf-8") as f:
            f.write(INITIAL_TEMPLATE)
        print(f"[OK] {context_path} inicializado com contexto estático canônico.")
        return

    with open(context_path, "r", encoding="utf-8") as f:
        content = f.read()

    cleaned_content = strip_legacy_volatile_section(content)
    if cleaned_content != content:
        with open(context_path, "w", encoding="utf-8") as f:
            f.write(cleaned_content)
        print(f"[OK] {context_path} higienizado (bloco volátil legado removido).")
    else:
        print(f"[OK] {context_path} já está sincronizado e livre de estado volátil (no-op).")


def main() -> None:
    target_dir = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    sync_context(target_dir)


if __name__ == "__main__":
    main()
