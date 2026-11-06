# Bem-vindo à Wiki do `my-agents` 🚀

[![Antigravity CLI](https://img.shields.io/badge/Antigravity-CLI_Plugin-blue.svg)](https://github.com/VitorJacom/my-agents)
[![AIDD Manifesto](https://img.shields.io/badge/Methodology-AIDD_Manifesto-success.svg)](AIDD-Manifesto)
[![Governance](https://img.shields.io/badge/Governance-Dual_Gate_&_Anti--Fraud-orange.svg)](AIDD-Manifesto)
[![Wiki Sync](https://img.shields.io/badge/Docs-Wiki_Automated_Sync-blueviolet.svg)](https://github.com/VitorJacom/my-agents/blob/main/.github/workflows/wiki-sync.yml)

Repositório central de padrões de engenharia, governança determinística, guardrails de segurança e automações para agentes de inteligência artificial (**Antigravity CLI / Gemini CLI**).

---

## 🏛️ Os 4 Valores do Manifesto AIDD (*AI-Driven Development*)

O ecossistema `my-agents` é regido pelos 4 valores inegociáveis do **Manifesto AIDD**:

1. **Método sobre o Modelo (*Method over Model*)**: O processo, o sandboxing, as travas de Git e a máquina de estados determinística importam mais do que qual LLM está sendo executado.
2. **Responsabilidade sobre Delegação (*Ownership over Delegation*)**: A IA acelera e gera, mas os contratos determinísticos e você garantem as regras inegociáveis.
3. **Compreensão sobre Aceitação (*Understanding over Acceptance*)**: Não se aceita código por presunção; aceita-se por testes determinísticos executados com evidências irrefutáveis no relatório de entrega (`walkthrough.md`).
4. **Resultado sobre Volume (*Outcome over Output*)**: Gerar milhares de linhas ou queimar tokens desnecessariamente é desperdício; o valor real reside na issue atômica resolvida com suíte 100% verde e zero regressão.

---

## 🤖 Taxonomia dos Subagentes Especializados

Para evitar agentes monolíticos sobrecarregados, o `my-agents` adota uma divisão rigorosa de responsabilidades com permissões confinadas:

| Subagente | Papel e Especialidade | Modo de Operação |
| :--- | :--- | :--- |
| **`product-owner`** | Engenharia de requisitos, personas, critérios de aceitação Gherkin e priorização de valor. | Somente Leitura / Planejamento |
| **`system-architect`** | Mapeamento de impacto técnico em `src/`, ADRs em `docs/ARCHITECTURE.md` e decomposição em issues atômicas. | Somente Leitura / Planejamento |
| **`uiux-designer`** | Hierarquia visual, ergonomia, contraste de luminância monocromático (Value Contrast / WCAG AA) e prova visual headless. | Design Tokens / Auditoria Headless |
| **`planner`** | Triagem técnica de issues, validação de blast radius e criação do `implementation_plan.md` com *Interface Contract*. | Somente Leitura / Triagem |
| **`qa-engineer`** | Engenharia de testes TDD em `tests/features/` garantindo estado inicial RED (falha determinística antes do código). | Confinado a `tests/features/` |
| **`coder`** | Construção cirúrgica de código de produção em `src/` orientado a contratos, sem permissão de alterar testes. | Confinado a `src/` |
| **`gatekeeper`** | Auditoria anti-fraude (*Golden Rule*), checagem de integridade de testes, compilação de evidências e abertura de PR. | Auditoria / Git & GitHub CLI |

---

## 🚀 Navegação e Atalhos Rápidos

Explore os módulos e documentações completas do ecossistema:

- 🏁 **[Primeiros Passos](Getting-Started)**: Guia completo de instalação do plugin, configuração no Antigravity CLI e verificação de ambiente.
- 📜 **[Manifesto AIDD](AIDD-Manifesto)**: Princípios fundamentais, ciclo de arquivos efêmeros (`task.md`, `implementation_plan.md`, `walkthrough.md`) e Trava Dupla Anti-Fraude.
- 🏛️ **[Arquitetura do Sistema](System-Architecture)**: Visão estrutural de alto nível, ciclo de vida híbrido (Local vs Nuvem), Worktrees, Ondas de Execução e Merge Queue.
- 🤖 **[Catálogo de Subagentes](Subagents)**: Detalhamento de cada persona, fluxos de trabalho, permissões de tools e interfaces.
- 🧰 **[Catálogo de Skills](Skills-Catalog)**: Guia das habilidades sob demanda (*Progressive Disclosure*), incluindo `/plan-feature`, `/run-issue`, `game-dev-patterns` e mais.
- 🛠️ **[Troubleshooting e FAQ](Troubleshooting)**: Diagnóstico e resolução de problemas comuns de permissão, worktrees, hooks e execução de testes.
