#!/usr/bin/env python3
"""
sync-project-context.py: Sincroniza e atualiza o PROJECT_CONTEXT.md com o estado recente
do repositório Git (último commit, branch e arquivos afetados), garantindo persistência
entre sessões sem esforço manual.
"""

import os
import sys
import subprocess
from datetime import datetime

def run_cmd(cmd, cwd=None):
    try:
        res = subprocess.run(cmd, cwd=cwd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return res.stdout.strip()
    except subprocess.CalledProcessError:
        return ""

def sync_context(workspace_dir):
    context_path = os.path.join(workspace_dir, "PROJECT_CONTEXT.md")
    
    branch = run_cmd("git branch --show-current", cwd=workspace_dir) or "main"
    last_commit = run_cmd("git log -1 --pretty=format:'%h - %s (%an)'", cwd=workspace_dir) or "Sem commits registrados"
    diff_stat = run_cmd("git diff --stat HEAD~1 HEAD 2>/dev/null", cwd=workspace_dir)
    if not diff_stat:
        diff_stat = run_cmd("git status --short", cwd=workspace_dir) or "Working tree limpa"
        
    date_str = datetime.now().strftime("%Y-%m-%d %H:%M")

    state_block = f"""## 📍 Estado Atual da Arquitetura & Entregas (Auto-Sync)
- **Última Atualização**: {date_str}
- **Branch Ativa**: `{branch}`
- **Último Commit**: `{last_commit}`
- **Resumo de Alterações Recentes**:
```text
{diff_stat[:400]}
```
"""

    if not os.path.exists(context_path):
        # Cria arquivo canônico inicial caso não exista
        initial_content = f"""# Contexto Canônico do Projeto (`PROJECT_CONTEXT.md`)

## 🛠️ Stack Tecnológica & Dependências
- Definida no manifesto do projeto (consulte `package.json` / `pyproject.toml`).
- **Invariante**: Proibido adicionar ou supor dependências externas sem aprovação explícita.

## 📂 Estrutura Canônica de Diretórios
- `src/`: Código-fonte de produção.
- `tests/`: Suíte de testes automatizados (`tests/core/` para testes de base e `tests/features/` para novas features TDD).
- `docs/`: Documentação técnica e ADRs (`docs/adr/`).

{state_block}
## 🛑 Regras e Invariantes Estritas (Anti-Alucinação)
1. **Grounding Mandatório**: Não invente diretórios ou convenções de nomenclatura fora do padrão declarado acima.
2. **Duplo Gate**: Nenhuma alteração é comitada sem passar pela auditoria de conformidade do Gatekeeper.
"""
        with open(context_path, "w", encoding="utf-8") as f:
            f.write(initial_content)
        print(f"[OK] {context_path} inicializado com sucesso.")
        return

    # Atualiza bloco de estado existente sem destruir o restante
    with open(context_path, "r", encoding="utf-8") as f:
        content = f.read()

    marker = "## 📍 Estado Atual da Arquitetura & Entregas"
    if marker in content:
        parts = content.split(marker)
        # Encontra o próximo cabeçalho h2 após o marker, se houver
        rest = parts[1]
        next_h2_idx = rest.find("\n## ")
        if next_h2_idx != -1:
            remaining_content = rest[next_h2_idx:]
        else:
            remaining_content = ""
        new_content = parts[0].rstrip() + "\n\n" + state_block.rstrip() + "\n\n" + remaining_content.lstrip()
    else:
        new_content = content.rstrip() + "\n\n" + state_block

    with open(context_path, "w", encoding="utf-8") as f:
        f.write(new_content)
    print(f"[OK] {context_path} sincronizado com o commit `{last_commit}`.")

def main():
    target_dir = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    sync_context(target_dir)

if __name__ == "__main__":
    main()
