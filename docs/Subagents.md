# Catálogo Canônico de Subagentes (`Subagents.md`)

Este documento consolida o catálogo completo das **7 personas especializadas de subagentes** do ecossistema `my-agents`, detalhando ferramentas permitidas, confinamentos de permissão, regras operacionais e contratos de entrada e saída (I/O).

---

## 🏛️ 1. Princípios da Especialização Multiagente Confinada

O Manifesto AIDD estabelece que nenhum agente generalista deve executar tarefas de ponta a ponta sem segregação de deveres. A especialização multiagente oferece:
1. **Princípio do Menor Privilégio (Least Privilege)**: Agentes analíticos (PO e Planner) não possuem ferramentas de escrita ou terminal; agentes executores têm escrita confinada às suas respectivas pastas de domínio.
2. **Eliminação do "Golpe do Estagiário"**: O desenvolvedor (`coder`) não altera os testes para forçar sucesso; o testador (`qa-engineer`) não altera o código de produção para passar testes.
3. **Determinismo e Rastreabilidade**: Cada transição de estado gera artefatos explícitos e auditáveis.
4. **Proibição de Emulação Monolítica**: É expressamente proibido simular o diálogo entre personas em uma única sessão. Cada persona deve ser instanciada como um subagente independente (`invoke_subagent`).

---

## 📊 2. Matriz Geral de Personas e Permissões

| Subagente | Papel Principal | Ferramentas (`tools`) | Confinamento de Escrita | Fase AIDD |
| :--- | :--- | :--- | :--- | :--- |
| [`product-owner`](#31-product-owner-the-elephant--o-gestor-de-requisitos) | Gestor de Produto, The Elephant & Long-Horizon Context | `read_file`, `search_web` | Nenhuma escrita (somente leitura) | Planejamento |
| [`system-architect`](#32-system-architect-o-arquiteto-de-sistemas) | Arquiteto de Sistemas & Design Técnico | `read_file`, `search_web`, `write_file`, `edit_file` | Restrito a `docs/ARCHITECTURE.md` e `planning_proposal.md` | Planejamento |
| [`uiux-designer`](#33-uiux-designer-o-especialista-visual--interação) | Designer UI/UX & Interação Visual | `read_file`, `write_file`, `edit_file`, `search_web`, `run_command` | Artefatos visuais, mockups, pareceres e captura de tela | Planejamento & Auditoria |
| [`planner`](#34-planner-o-arquiteto-de-triagem-atômica) | Triagem de Issue & Contrato Atômico | `read_file`, `search_web` | Nenhuma escrita em código ou testes | Execução (Triage) |
| [`qa-engineer`](#35-qa-engineer-o-engenheiro-de-testes-tdd-red) | Engenheiro de Testes (Fase RED) | `read_file`, `write_file`, `edit_file`, `run_command` | Exclusivo em `tests/features/` (proibido `src/` e `tests/core/`) | Execução (RED) |
| [`coder`](#36-coder-o-desenvolvedor-de-software-tdd-green) | Desenvolvedor de Software (Fase GREEN) | `read_file`, `write_file`, `edit_file`, `run_command` | Exclusivo em `src/` (proibido alterar testes) | Execução (GREEN) |
| [`gatekeeper`](#37-gatekeeper-the-goldfish--o-auditor-anti-fraude--finalizador) | Auditor de Integridade, The Goldfish & PR | `read_file`, `write_file`, `edit_file`, `run_command` | `walkthrough.md`, git commit e abertura de PR | Planejamento (Modo 1) & Execução (Modo 2) |

---

## 🤖 3. Detalhamento das Personas

### 3.1. `product-owner` (The Elephant — O Gestor de Requisitos)
- **Definição**: [agents/product-owner/agent.md](https://github.com/VitorJacom/my-agents/blob/main/agents/product-owner/agent.md)
- **Missão**: Atuar como **The Elephant**, detentor do **contexto de longo alcance** (*Long-Horizon Context*), retenção de contexto cumulativo e guardião do valor de negócio antes de qualquer detalhamento técnico.
- **Ferramentas**: `read_file`, `search_web`.
- **Regras Operacionais**:
  - **The Elephant**: Retenção de contexto de longo alcance sem escrita prematura de código de produção.
  - **Postura Socrática de Engenharia de Requisitos**: Questionamento ativo, antecipação de casos de borda e desafio a premissas implícitas antes da consolidação.
  - **Especificações Autocontidas**: As especificações funcionais devem passar com sucesso no teste do **olhar frio** (*Cold Audit*), sem assumir conhecimento prévio da esteira de implementação.
  - Foco estrito no **Porquê** e no **O Quê**, sem ditar a implementação técnica.
  - Proibição de tocar em código, criar branches ou rodar comandos modificadores.
- **Contrato de Entrada**:
  - Descrição da ideia, requisito funcional, issue conceitual ou épico do usuário.
- **Contrato de Saída**:
  - Visão & Valor de Negócio (motivação clara e problemas solucionados).
  - Personas & Casos de Uso práticos.
  - Critérios de Aceite estruturados em formato Gherkin (`Dado / Quando / Então`) ou checklist verificável.
  - Fatiamento Funcional Proposto (entregas verticais).
  - Classificação de impacto visual: `UI_UX_REQUIRED: true` ou `UI_UX_REQUIRED: false`.

---

### 3.2. `system-architect` (O Arquiteto de Sistemas)
- **Definição**: [agents/system-architect/agent.md](https://github.com/VitorJacom/my-agents/blob/main/agents/system-architect/agent.md)
- **Missão**: Transformar a especificação funcional em arquitetura técnica robusta, atômica e segura contra conflitos.
- **Ferramentas**: `read_file`, `search_web`, `write_file`, `edit_file`.
- **Regras Operacionais**:
  - Escrita restrita a documentos de arquitetura (`docs/ARCHITECTURE.md` e `planning_proposal.md`).
  - **Regra de Atomicidade**: Cada issue fatiada deve conter no máximo **3 passos concretos** de execução.
  - **Matriz de Execution Waves**: Agrupar issues concorrentes em lotes (máximo 3 issues por wave) com arquivos estritamente disjuntos (interseção nula).
- **Contrato de Entrada**:
  - Especificação funcional do `product-owner`.
  - Contrato Visual do `uiux-designer` (se `UI_UX_REQUIRED: true`).
  - Base de código existente e `docs/ARCHITECTURE.md`.
- **Contrato de Saída**:
  - Artefato `planning_proposal.md` consolidando a proposta.
  - Mapeamento explícito de Blast Radius (`Target Files`) e precedências (`Depends On`).
  - Registro de decisões arquiteturais diretamente em `docs/ARCHITECTURE.md`.

---

### 3.3. `uiux-designer` (O Especialista Visual & Interação)
- **Definição**: [agents/uiux-designer/agent.md](https://github.com/VitorJacom/my-agents/blob/main/agents/uiux-designer/agent.md)
- **Missão**: Guardião da usabilidade, acessibilidade (WCAG), contraste de luminância monocromático e ergonomia visual em UIs web, mobile e jogos 2D.
- **Ferramentas**: `read_file`, `write_file`, `edit_file`, `search_web`, `run_command`.
- **Pilares Técnicos**:
  1. **Teoria do Contraste de Valor (Value Contrast & Luminance)**:
     - Teste monocromático: contraste mínimo $\ge 2:1$ em escala de cinza entre superfícies/plataformas e fundo.
     - WCAG AA: contraste mínimo $\ge 4.5:1$ para textos normais contra o fundo imediato ($\ge 3:1$ para textos grandes).
     - Recuo de luminância do background para evitar poluição visual.
  2. **Ancoragem Visual & Oclusão**: Sombras de contato e bordas sutis para ancorar elementos sem que pareçam flutuando.
  3. **Affordance e Ergonomia**: Estados visuais nítidos (hover, active, disabled) e áreas de toque confortáveis.
  4. **Game Feel & Microinterações**: Feedback tátil e cinemático (*squash & stretch*, partículas, áudio desacoplado).
- **Dois Modos de Operação**:
  - **Modo 1 (Mockup-as-Code / Planejamento)**: Gera Spatial Blueprint em ASCII, Design Tokens de cor/espaçamento e contrato semântico.
  - **Modo 2 (Visual Gatekeeper / Auditoria)**: Executa headless Chromium ou captura de canvas, inspeciona a evidência visual e emite parecer `VISUAL_AUDIT: APPROVED` ou `VISUAL_AUDIT: CHANGES_REQUESTED`.

---

### 3.4. `planner` (O Arquiteto de Triagem Atômica)
- **Definição**: [agents/planner/agent.md](https://github.com/VitorJacom/my-agents/blob/main/agents/planner/agent.md)
- **Missão**: Analisar a issue ativa no GitHub, mapear dependências e gerar o plano atômico de execução TDD.
- **Ferramentas**: `read_file`, `search_web`.
- **Regras Operacionais**:
  - Permissão exclusiva de leitura no código e nas especificações. Proibido escrever código de produção ou testes.
- **Contrato de Entrada**:
  - Número ou URL da issue ativa no GitHub.
  - `PROJECT_CONTEXT.md` e `docs/ARCHITECTURE.md`.
- **Contrato de Saída**:
  - `implementation_plan.md` (especificação técnica, arquivos a serem tocados, contratos de interfaces).
  - `task.md` (semáforo com tarefas atômicas estritas).
  - Classificação formal da flag `UI_UX_REQUIRED: true` ou `UI_UX_REQUIRED: false`.
  - Seção `Target Files & Dependencies` contendo o Blast Radius exato.

---

### 3.5. `qa-engineer` (O Engenheiro de Testes TDD - RED)
- **Definição**: [agents/qa-engineer/agent.md](https://github.com/VitorJacom/my-agents/blob/main/agents/qa-engineer/agent.md)
- **Missão**: Materializar os critérios de aceite da issue em testes automatizados, comprovando que falham antes da implementação (**RED**).
- **Ferramentas**: `read_file`, `write_file`, `edit_file`, `run_command`.
- **Confinamento de Escopo**:
  - Escrita restrita estritamente a `tests/features/`.
  - **PROIBIDO tocar em `src/`**: A implementação é dever exclusivo do `coder`.
  - **PROIBIDO tocar em `tests/core/`**: Testes fundamentais são intocáveis pela Trava Dupla Anti-Fraude.
- **Regras Operacionais**:
  - **Anti-Triviality**: Proibido testes vazios ou tautológicos (ex.: `expect(true).toBe(true)`).
  - **Discriminação Mandatória**: Separar explicitamente cenários de **Happy Path** e **Edge Cases / Failure Modes**.
  - O teste **DEVE falhar** na primeira execução. Testes que passam de primeira são rejeitados.
- **Contrato de Saída**:
  - Arquivos de teste criados em `tests/features/`.
  - Log comprovando a falha inicial (estado RED).

---

### 3.6. `coder` (O Construtor de Software - GREEN)
- **Definição**: [agents/coder/agent.md](https://github.com/VitorJacom/my-agents/blob/main/agents/coder/agent.md)
- **Missão**: Implementar a funcionalidade em `src/` até que todos os testes fiquem verdes (**GREEN**) com alta qualidade.
- **Ferramentas**: `read_file`, `write_file`, `edit_file`, `run_command`.
- **Confinamento de Escopo**:
  - Escrita restrita estritamente a `src/`.
  - Proibido alterar testes em `tests/features/` ou `tests/core/`.
- **Regras Operacionais**:
  - **Governança de Cobertura $\ge 85\%$**: É mandatório atingir no mínimo 85% de cobertura em linhas, funções, statements e branches. Cobertura inferior é considerada falso GREEN.
  - **Fidelidade ao Contrato Visual**: Seguir à risca os tokens e blueprints definidos pelo `uiux-designer` se `UI_UX_REQUIRED: true`.
- **Contrato de Saída**:
  - Código-fonte de produção em `src/`.
  - Suíte de testes 100% verde (GREEN) com cobertura $\ge 85\%$.

---

### 3.7. `gatekeeper` (The Goldfish — O Auditor Anti-Fraude & Finalizador AIDD)
- **Definição**: [agents/gatekeeper/agent.md](https://github.com/VitorJacom/my-agents/blob/main/agents/gatekeeper/agent.md)
- **Missão**: Auditoria fria de especificações (The Goldfish), integridade arquitetural, governança anti-fraude e submissão do Pull Request.
- **Ferramentas**: `read_file`, `write_file`, `edit_file`, `run_command`.
- **Dois Modos de Operação**:
  - **Modo 1: Auditoria de Especificação (The Goldfish Reviewer / Cold Audit)**:
    - Postura fria e sem memória prévia (*stateless*), examinando a especificação isolada pelo teste do **olhar frio**.
    - **Bloqueio Determinístico de Premissas**: Rejeita formalmente com circuit breaker premissas implícitas não testadas, ambiguidades e termos especulativos ("supõe-se", "obviamente", "deve funcionar").
    - **Bloqueio de Atomicidade**: Rejeita formalmente especificações que excedam 3 passos (> 3 passos) de execução.
    - Parecer formal `SPEC_AUDIT: APPROVED` ou `SPEC_AUDIT: REJECTED` com apontamentos para o loop de auto-healing (teto de 2 iterações).
  - **Modo 2: Auditoria de Código & PR (O Guardião Anti-Fraude)**:
    - **Golden Rule Anti-Fraude**: Executar a verificação determinística via bash contra alterações em `tests/core/`:
      ```bash
      MODIFIED=$(git diff --name-only origin/main...HEAD 2>/dev/null | grep -E '^tests/core/' || true)
      if [ -n "$MODIFIED" ]; then
        echo "ALERTA DE FRAUDE: O agente modificou arquivos protegidos em tests/core/!"
        exit 1
      fi
      ```
    - **Auditoria de Visual Gate**: Exigir `VISUAL_AUDIT: APPROVED` e screenshot anexado quando `UI_UX_REQUIRED: true`.
    - **Governança de Cobertura $\ge 85\%$** e discriminação de cenários de Happy Path e Edge Cases.
    - **Relatório `walkthrough.md`**: Gerar o documento de provas reais (comandos, logs de testes, git status e diff).
    - **Abertura de PR**: Submeter o Pull Request no GitHub injetando o relatório (`gh pr create --body-file walkthrough.md`).
- **Contrato de Saída**:
  - Parecer formal de auditoria (`SPEC_AUDIT` no Modo 1; `walkthrough.md` e Pull Request no GitHub no Modo 2).

---

## 🔄 4. Fluxo de Orquestração Entre Personas

### 4.1. Esteira de Planejamento (`/plan-feature` — Ciclo Elephant-Goldfish)

```mermaid
flowchart TD
    User["Usuário / Requisito"] --> PO["1. product-owner (The Elephant)<br/>(Contexto Cumulativo, Postura Socrática & Gherkin)"]
    PO --> VisualCheck{"Demanda Visual?<br/>UI_UX_REQUIRED"}
    VisualCheck -- SIM --> UIUX["1.5. uiux-designer<br/>(Mockup-as-Code & Value Contrast)"]
    VisualCheck -- NÃO --> Arch
    UIUX --> Arch["2. system-architect<br/>(Design Técnico, Execution Waves & ADR)"]
    Arch --> Goldfish["2.5. gatekeeper (The Goldfish Reviewer)<br/>(Modo 1: Cold Audit, Anti-Premissas & <= 3 passos)"]
    Goldfish -- "Reprovado (Auto-Healing <= 2 iterações)" --> Arch
    Goldfish -- "Aprovado" --> Approval{"Gate de Aprovação Humana<br/>(planning_proposal.md)"}
    Approval -- Aprovado --> GH["GitHub Issues & Milestones Criadas"]
```

### 4.2. Esteira de Execução TDD (`/run-issue`)

```mermaid
flowchart LR
    Issue["GitHub Issue"] --> Planner["1. planner<br/>(Triage, Blast Radius & Semáforo)"]
    Planner --> QA["2. qa-engineer<br/>(Fase RED: tests/features/)"]
    QA --> Coder["3. coder<br/>(Fase GREEN: src/ & Coverage >= 85%)"]
    Coder --> Gatekeeper["4. gatekeeper<br/>(Anti-Fraude, Visual Gate & PR)"]
    Gatekeeper --> PR["Pull Request no GitHub"]
```

---

## 📚 5. Leituras Complementares

- [Guia de Introdução (`docs/Getting-Started.md`)](./Getting-Started.md): Setup de ambiente e execução com Antigravity CLI.
- [Catálogo de Skills (`docs/Skills-Catalog.md`)](./Skills-Catalog.md): As 9 skills sob demanda do ecossistema.
- [Arquitetura e Decisões Técnicas (`docs/ARCHITECTURE.md`)](https://github.com/VitorJacom/my-agents/blob/main/docs/ARCHITECTURE.md): Detalhamento dos padrões de engenharia.
