[← Voltar ao Sumário de Subagentes](Subagents)

> **Definição Canônica**: [`agents/planner/agent.md`](https://github.com/VitorJacom/my-agents/blob/main/agents/planner/agent.md)  
> **Fase AIDD**: Execução ([`issue-pipeline`](Skill-issue-pipeline) — Estado 1: Triage & Planning)  
> **Ferramentas (`tools`)**: `read_file`, `search_web`  
> **Confinamento**: Somente leitura (proibido escrever código de produção ou testes)

---

## 🎯 Missão

Realizar a triagem técnica da issue ativa no GitHub, validar sua atomicidade e *Blast Radius*, congelar a seção `## Interface Contract` e materializar o contrato preliminar de execução (`implementation_plan.md` e `task.md`, conforme o [`AIDD-Manifesto`](AIDD-Manifesto)) antes de qualquer código ser escrito.

---

## 📜 Regras Operacionais

- **Somente Leitura**: Sem permissão de modificar `src/` ou `tests/`.
- **Atomicity Gate**: Rejeita planos que ultrapassem **3 passos concretos** ou misturem domínios desconexos.
- **Interface Contract Gate**: Produz obrigatoriamente a seção `## Interface Contract` (Signatures, Types & Interfaces, Inputs, Outputs, Errors) validada deterministicamente por [`validate-interface-contract.sh`](Script-pipeline) — zero placeholders (`TODO`/`TBD`).
- **Classificação Visual**: Declara explicitamente `UI_UX_REQUIRED: true` ou `UI_UX_REQUIRED: false` para acionar ou pular o [`uiux-designer`](Agent-uiux-designer).

---

## 🔌 Contratos de Entrada e Saída (I/O)

### Contrato de Entrada
- Número ou URL da issue ativa no GitHub.
- `PROJECT_CONTEXT.md`, [`docs/ARCHITECTURE.md`](ARCHITECTURE) e eventuais Living Specs em `docs/mockups/`.

### Contrato de Saída
- **`implementation_plan.md`**: Contrato técnico preliminar com `## Interface Contract` e `## Target Files & Dependencies`.
- **`task.md`**: Semáforo de tarefas atômicas (`[ ]`, `[/]`, `[x]`).
- Flag formal `UI_UX_REQUIRED: true | false`.

---

## 🔗 Navegação

[← Anterior: `uiux-designer`](Agent-uiux-designer) | [Sumário de Subagentes](Subagents) | [Próximo Subagente: `qa-engineer` →](Agent-qa-engineer)
