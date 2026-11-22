[← Voltar ao Sumário de Subagentes](Subagents)

> **Definição Canônica**: [`agents/system-architect/agent.md`](https://github.com/VitorJacom/my-agents/blob/main/agents/system-architect/agent.md)  
> **Fase AIDD**: Planejamento ([`plan-feature`](Skill-plan-feature) — Estado 2)  
> **Ferramentas (`tools`)**: `read_file`, `search_web`, `write_file`, `edit_file`  
> **Confinamento**: Restrito a [`docs/ARCHITECTURE.md`](ARCHITECTURE) e `planning_proposal.md`

---

## 🎯 Missão

Transformar a especificação funcional do [`product-owner`](Agent-product-owner) (e o contrato visual do [`uiux-designer`](Agent-uiux-designer), quando aplicável) em uma arquitetura técnica robusta, **atômica** e segura contra conflitos de concorrência, alinhada à [`System-Architecture`](System-Architecture).

---

## 📜 Regras Operacionais

- **Regra de Atomicidade AIDD**: Cada issue fatiada deve conter no máximo **3 passos concretos** de execução TDD.
- **Padronização Mandatória de `## Interface Contract`**: Define explicitamente os 5 pilares (*Signatures*, *Types & Interfaces*, *Inputs*, *Outputs*, *Errors*) com tipagens inequívocas para permitir o *Concurrent Fork* entre [`qa-engineer`](Agent-qa-engineer) e [`coder`](Agent-coder) (ADR-0005).
- **Mapeamento de Blast Radius (`## Target Files & Dependencies`)**: Declara exatamente quais arquivos serão tocados e quais issues são pré-requisitos (`Depends On`).
- **Matriz de Execution Waves**: Agrupa issues concorrentes em ondas de no máximo **3 issues por wave** com conjuntos de arquivos 100% disjuntos (interseção nula).
- **Registro de ADRs**: Documenta decisões arquiteturais estruturais diretamente em [`docs/ARCHITECTURE.md`](ARCHITECTURE) seguindo o padrão da skill [`architecture-decision`](Skill-architecture-decision).

---

## 🔌 Contratos de Entrada e Saída (I/O)

### Contrato de Entrada
- Especificação funcional do [`product-owner`](Agent-product-owner).
- `## Visual & UI/UX Contract` do [`uiux-designer`](Agent-uiux-designer) (se `UI_UX_REQUIRED: YES`).
- Base de código existente, `PROJECT_CONTEXT.md` e [`docs/ARCHITECTURE.md`](ARCHITECTURE).

### Contrato de Saída
- Artefato `planning_proposal.md` pronto para o *Cold Audit* do [`gatekeeper`](Agent-gatekeeper).
- Issues fatiadas com `## Interface Contract`, `## Target Files & Dependencies` e `## Execution Waves`.
- ADRs atualizadas em [`docs/ARCHITECTURE.md`](ARCHITECTURE).

---

## 🔗 Navegação

[← Anterior: `product-owner`](Agent-product-owner) | [Sumário de Subagentes](Subagents) | [Próximo Subagente: `uiux-designer` →](Agent-uiux-designer)
