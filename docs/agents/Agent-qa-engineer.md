[← Voltar ao Sumário de Subagentes](Subagents)

# 🤖 Subagente: `qa-engineer`

> **Definição Canônica**: [`agents/qa-engineer/agent.md`](https://github.com/VitorJacom/my-agents/blob/main/agents/qa-engineer/agent.md)  
> **Fase AIDD**: Execução (`/run-issue` — Estado 2: Concurrent Fork / Fase RED)  
> **Ferramentas (`tools`)**: `read_file`, `write_file`, `edit_file`, `run_command`  
> **Confinamento**: Exclusivo em `tests/features/<categoria>/` (**PROIBIDO** tocar em `src/` ou `tests/core/`)

---

## 🎯 Missão

Materializar os critérios de aceite da issue em testes determinísticos sob a seção congelada `## Interface Contract`, comprovando que a suíte falha inicialmente (**RED**) antes de convergir com a implementação do [`coder`](Agent-coder).

---

## 📜 Regras Operacionais

- **Confinamento Estrito**:
  - Escreve exclusivamente na subpasta de domínio de `tests/features/` (`pipeline/`, `governance/`, `ui-ux/`, `wiki/`, `statusline/`).
  - **Proibido tocar em `src/`** (dever exclusivo do `coder`).
  - **Proibido tocar em `tests/core/`** (zona intocável da *Golden Rule*).
- **Anti-Triviality**: Proibido testes vazios, `exit 0` incondicional ou asserções tautológicas (`expect(true).toBe(true)`).
- **Discriminação Mandatória de Cenários**: Todo arquivo de teste deve separar explicitamente blocos de **Happy Path** e **Edge Cases / Failure Modes**.
- **Mocks Determinísticos**: Testes de infraestrutura/scripts usam mocks rápidos (`--test-cmd "true"`) e diretórios `mktemp -d` com limpeza via `trap`.

---

## 🔌 Contratos de Entrada e Saída (I/O)

### Contrato de Entrada
- `implementation_plan.md` com `## Interface Contract` congelado e validado.
- Critérios de aceite Gherkin da issue.

### Contrato de Saída
- Suítes de teste criadas em `tests/features/<categoria>/`.
- Evidência de execução comprovando estado inicial **RED** por ausência da implementação.

---

## 🔗 Navegação

[← Anterior: `planner`](Agent-planner) | [Sumário de Subagentes](Subagents) | [Próximo Subagente: `coder` →](Agent-coder)
