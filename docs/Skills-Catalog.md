# 🧰 Sumário de Skills (`Skills-Catalog`)

> **Cabeçalho de Controle (Pressman / Sommerville)**  
> - **Escopo / Filtros Aplicados**: `skills/*/SKILL.md` • Carregamento: `Progressive Disclosure` • Ordenação: `Categoria ➔ Fluxo AIDD`  
> - **Data/Hora de Emissão**: `2026-11-22 15:33 BRT` *(sincronizado via `.github/workflows/wiki-sync.yml`)*  
> - **Fonte Canônica**: [`skills/`](https://github.com/VitorJacom/my-agents/tree/main/skills)

Este documento é o **índice central e resumo executivo** das **11 skills sob demanda** integradas ao plugin `my-agents`. Cada skill possui agora sua própria **página dedicada na Wiki** com diagramas, protocolo de execução, comandos e artefatos.

---

## 🎯 1. Progressive Disclosure & Zero Token Waste

O Antigravity CLI impõe limites de contexto para regras globais para preservar a memória de trabalho do modelo. Em vez de injetar convenções de nicho (como física de jogos 2D, Docker ou esteiras completas de planejamento) em todas as sessões:

- **Zero Token Waste**: As skills permanecem adormecidas até serem acionadas expressamente ou por intenção compatível.
- **Progressive Disclosure**: O agente carrega apenas o `skills/<nome>/SKILL.md` necessário no momento exato da tarefa.
- **Modularidade Canônica**: Cada skill tem ciclo de vida próprio, independente das regras globais em `rules/AGENTS.md`.

---

## 🗂️ 2. Guia Rápido por Categoria

### 🔄 Esteiras & Orquestração AIDD (2)
- **[`plan-feature`](Skill-plan-feature)** — Transforma ideias ou issues macro em especificações auditadas (*The Elephant* ➔ *UI/UX* ➔ *Architect* ➔ *The Goldfish*), congelando `## Interface Contract` e particionando em *Execution Waves*.
- **[`issue-pipeline`](Skill-issue-pipeline)** — Executa issues do GitHub com *Concurrent Fork* (`qa-engineer` + `coder` sob contrato), cobertura $\ge 85\%$, *Visual Audit Gate* e *Golden Rule* via `gatekeeper`.

### 🛡️ Qualidade, Testes & Revisão (3)
- **[`review-pr`](Skill-review-pr)** — Orquestra a revisão de Pull Requests no GitHub em 5 fases via `scripts/pr-reviewer.sh`, com bloqueio anti-fraude (exit code 3) e confirmação humana obrigatória.
- **[`code-review`](Skill-code-review)** — Aplica auditoria local em 4 dimensões (OWASP, SOLID, Robustez, Testabilidade) com relatório em 3 níveis de severidade (🚨 Crítico, ⚠️ Importante, 💡 Sugestão).
- **[`test-runner`](Skill-test-runner)** — Roda testes focados antes da suíte completa, diagnostica diffs sem adulterar asserções e suporta testes isolados em *Clean Room* (`sandbox/`).

### 🏗️ Engenharia, Arquitetura & Infraestrutura (4)
- **[`git-workflow`](Skill-git-workflow)** — Padroniza branches (`feature/`, `fix/`, `refactor/`), commits em inglês (*Conventional Commits*) e diretivas `Fixes #<id>` em texto puro.
- **[`architecture-decision`](Skill-architecture-decision)** — Documenta decisões técnicas estruturais no padrão Michael Nygard em `docs/adr/` ou [`docs/ARCHITECTURE.md`](ARCHITECTURE).
- **[`docker-dev`](Skill-docker-dev)** — Diagnostica falhas de containers/Compose e aplica *multi-stage builds*, usuário não-root e `.dockerignore`.
- **[`publish-rule-issue`](Skill-publish-rule-issue)** — Globaliza regras descobertas via `/learn` em qualquer projeto criando uma issue pronta para `/run-issue` no `my-agents`.

### 🎨 Domínios Especializados (2)
- **[`ui-ux-design`](Skill-ui-ux-design)** — 48 técnicas de UI/UX em 7 módulos de carregamento progressivo, fórmulas de molas e CLI `skill_assistant.py` para receitas, checklists e auditoria anti-slop.
- **[`game-dev-patterns`](Skill-game-dev-patterns)** — 4 invariantes de física e renderização para jogos 2D (Phaser, Canvas, PixiJS) com *Zero Token Waste* fora do nicho de jogos.

---

## 📊 3. Tabela Resumo das 11 Skills

Clique no nome de qualquer skill para acessar sua **página dedicada**:

| # | Skill | Categoria | Resumo do Propósito | Gatilho / Invocação | Definição |
| ---: | :--- | :--- | :--- | :--- | :--- |
| 1 | **[`plan-feature`](Skill-plan-feature)** | Esteiras AIDD | Planejamento funcional, UI/UX e design técnico sob o ciclo *Elephant-Goldfish* antes de codificar. | `/plan-feature <ideia ou #issue>` | [`SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/plan-feature/SKILL.md) |
| 2 | **[`issue-pipeline`](Skill-issue-pipeline)** | Esteiras AIDD | Esteira TDD determinística em Modo Unitário (1 issue) ou Modo Maestro (multi-issue com Worktrees e Merge Queue). | `/run-issue <#ID>` ou `/run-issue --epic <#ID>` | [`SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/issue-pipeline/SKILL.md) |
| 3 | **[`review-pr`](Skill-review-pr)** | Qualidade & Revisão | Revisão determinística de Pull Requests em 5 fases com *Golden Rule*, Gate Humano e criação de issues. | `/review-pr <#PR \| URL>` | [`SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/review-pr/SKILL.md) |
| 4 | **[`code-review`](Skill-code-review)** | Qualidade & Revisão | Auditoria rigorosa de código local em 4 dimensões (OWASP, SOLID, Robustez e Testabilidade). | `/code-review` | [`SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/code-review/SKILL.md) |
| 5 | **[`test-runner`](Skill-test-runner)** | Qualidade & Revisão | Execução cirúrgica de testes (Node/TS, Python, Go), diagnóstico de falhas e validação *Clean Room*. | `/test` | [`SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/test-runner/SKILL.md) |
| 6 | **[`git-workflow`](Skill-git-workflow)** | Engenharia & Infra | Branches semânticas, *Conventional Commits*, checklist pré-commit e PRs com *auto-close* em texto puro. | Contextual (commits, branches e PRs) | [`SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/git-workflow/SKILL.md) |
| 7 | **[`architecture-decision`](Skill-architecture-decision)** | Engenharia & Infra | Registro formal de ADRs (template Michael Nygard) documentando contexto, alternativas e trade-offs. | Contextual ("Registre uma ADR...") | [`SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/architecture-decision/SKILL.md) |
| 8 | **[`docker-dev`](Skill-docker-dev)** | Engenharia & Infra | Diagnóstico de containers/Compose, gestão local e boas práticas de segurança em `Dockerfile`. | Contextual (Docker / Compose) | [`SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/docker-dev/SKILL.md) |
| 9 | **[`publish-rule-issue`](Skill-publish-rule-issue)** | Engenharia & Infra | Publica aprendizados de `/learn` como issues atômicas no repositório central `VitorJacom/my-agents`. | `/publish-rule-issue` | [`SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/publish-rule-issue/SKILL.md) |
| 10 | **[`game-dev-patterns`](Skill-game-dev-patterns)** | Domínios Especializados | Física 2D independente de FPS, debounce de colisões, preservação dimensional de sprites e alcance cinemático. | Contextual (Phaser, Canvas, jogos 2D) | [`SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/game-dev-patterns/SKILL.md) |
| 11 | **[`ui-ux-design`](Skill-ui-ux-design)** | Domínios Especializados | Hub executivo de UI/UX com 48 técnicas, 7 módulos, física de movimento (Apple) e assistente CLI anti-slop. | Contextual / `uiux-designer` | [`SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/ui-ux-design/SKILL.md) |
| **Total** | **11 Skills** | **4 Categorias** | **100% sob demanda (Zero Token Waste)** | **6 comandos slash • 5 contextuais** | **11/11 ativas** |

---

## 📚 4. Leituras Complementares

- [Guia de Introdução (`Getting-Started`)](Getting-Started): Setup de plugins e primeiro comando.
- [Sumário de Subagentes (`Subagents`)](Subagents): Detalhamento das 7 personas executoras e matriz de permissões.
- [Especificação & ADRs (`ARCHITECTURE`)](ARCHITECTURE): Visão técnica canônica e histórico de decisões.

---

> **Rodapé de Controle — Totalizadores & Paginação**  
> **Totalizadores**: `11 Skills` • `4 Categorias` • `6 Comandos Slash` • `5 Contextuais` • `11 Páginas Dedicadas`  
> **Paginação**: `Catálogo 2 de 4` — [← Anterior: 🤖 Subagentes](Subagents) | [🏠 Home](Home) | [Próximo: 🛠️ Scripts →](Scripts-Catalog)
