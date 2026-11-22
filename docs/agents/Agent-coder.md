[← Voltar ao Sumário de Subagentes](Subagents)

> **Definição Canônica**: [`agents/coder/agent.md`](https://github.com/VitorJacom/my-agents/blob/main/agents/coder/agent.md)  
> **Fase AIDD**: Execução ([`issue-pipeline`](Skill-issue-pipeline) — Estado 2: Concurrent Fork / Fase GREEN)  
> **Ferramentas (`tools`)**: `read_file`, `write_file`, `edit_file`, `run_command`  
> **Confinamento**: Exclusivo em `src/` (**PROIBIDO** alterar qualquer arquivo em `tests/`)

---

## 🎯 Missão

Construir a implementação de produção em `src/` de forma cirúrgica e orientada exclusivamente pela seção congelada `## Interface Contract` (operando em paralelo ao [`qa-engineer`](Agent-qa-engineer) no *Concurrent Fork* definido no [`AIDD-Manifesto`](AIDD-Manifesto)), atingindo suíte **100% GREEN** e cobertura $\ge 85\%$.

---

## 📜 Regras Operacionais

- **Confinamento Anti-Fraude**: Escrita restrita a `src/`. É expressamente proibido modificar, comentar ou remover testes em `tests/features/` ou [`tests/core/`](Test-core).
- **Contract-Driven Development**: Assinaturas, tipos, entradas, saídas e tratamento de erros devem refletir com 100% de fidelidade o `## Interface Contract`.
- **Governança de Cobertura $\ge 85\%$**: Cobertura inferior a 85% em linhas, funções, statements ou branches é rejeitada como falso GREEN.
- **Fidelidade Visual**: Quando `UI_UX_REQUIRED: true`, segue à risca o *Spatial Blueprint* e os *Design Tokens* do [`uiux-designer`](Agent-uiux-designer), respondendo ao loop de reconciliação visual se necessário.
- **Reconciliação Limitada**: No *Contract Integration Gate* (Estado 3) ou na *Merge Queue* do Modo Maestro, atua em loops determinísticos de no máximo **2 iterações**.

---

## 🔌 Contratos de Entrada e Saída (I/O)

### Contrato de Entrada
- `implementation_plan.md` com `## Interface Contract` congelado.
- `## Visual & UI/UX Contract` (quando aplicável).

### Contrato de Saída
- Código de produção limpo e tipado em `src/`.
- Convergência **GREEN** no Join Point ([`contract-integration-gate.sh`](Script-pipeline)) com cobertura $\ge 85\%$.

---

## 🔗 Navegação

[← Anterior: `qa-engineer`](Agent-qa-engineer) | [Sumário de Subagentes](Subagents) | [Próximo Subagente: `gatekeeper` →](Agent-gatekeeper)
