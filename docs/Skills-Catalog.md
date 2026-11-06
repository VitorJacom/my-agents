# Catálogo Canônico de Skills (`Skills-Catalog.md`)

Este documento apresenta a documentação exaustiva de todas as **9 skills sob demanda** integradas ao plugin `my-agents`, detalhando seus objetivos, gatilhos por *Progressive Disclosure*, exemplos práticos de invocação e os artefatos produzidos por cada uma.

---

## 🎯 1. O Princípio de Progressive Disclosure e Zero Token Waste

O Antigravity CLI impõe limites de contexto para regras globais para preservar a memória de trabalho do modelo. A injeção de padrões de domínios específicos (como física de jogos 2D, orquestração de containers ou fluxos extensos de planejamento) diretamente em regras globais consumiria tokens desnecessariamente e causaria viés cognitivo em projetos irrelevantes.

### Por que Skills?
- **Zero Token Waste**: As skills permanecem adormecidas e só são injetadas no contexto quando o desenvolvedor as convoca expressamente ou quando uma intenção compatível é detectada.
- **Progressive Disclosure**: O agente carrega apenas a instrução necessária no momento exato em que vai executar a tarefa.
- **Modularidade e Reutilização**: Cada skill possui seu próprio ciclo de vida em `skills/<nome>/SKILL.md`.

---

## 📊 2. Tabela Resumo das Skills Disponíveis

| Skill | Domínio / Propósito | Gatilho (*Progressive Disclosure*) | Comando / Invocação |
| :--- | :--- | :--- | :--- |
| [`plan-feature`](#31-plan-feature-esteira-de-planejamento-e-design) | Planejamento funcional e técnico de requisitos | Início de novas funcionalidades, épicos ou refinamento de issues | `/plan-feature <ideia ou #issue>` |
| [`issue-pipeline`](#32-issue-pipeline-esteira-tdd-unitária-e-maestro) | Orquestração da esteira determinística TDD | Implementação e resolução de issues do GitHub | `/run-issue <#ID>` ou `/run-issues <#1, #2>` |
| [`code-review`](#33-code-review-auditoria-de-qualidade-e-segurança) | Revisão rigorosa em 4 dimensões (OWASP, SOLID) | Pré-merge, auditoria de PR ou solicitação de revisão | `/code-review` ou "Revise o código" |
| [`test-runner`](#34-test-runner-diagnóstico-e-reparo-de-testes) | Execução inteligente e reparo cirúrgico de testes | Falhas na suíte de testes, quebras de build | `/test` ou "Conserte os testes quebrados" |
| [`git-workflow`](#35-git-workflow-branches-semânticas-e-commits) | Padronização de branches e Conventional Commits | Criação de commits, novas branches ou abertura de PR | "Prepare o commit" ou "Crie a branch" |
| [`architecture-decision`](#36-architecture-decision-registros-de-adr) | Documentação formal de decisões e trade-offs | Seleção de tecnologias, bancos de dados e padrões | "Registre uma ADR sobre a escolha de X" |
| [`docker-dev`](#37-docker-dev-diagnóstico-e-containers) | Gestão e troubleshooting de Docker e Compose | Containers falhando, portas ocupadas, montagens | "Diagnostique a falha do container Docker" |
| [`game-dev-patterns`](#38-game-dev-patterns-padrões-e-física-para-jogos-2d) | Física 2D, FPS independence e cinemática | Jogos em Phaser, HTML5 Canvas, bugs de taxa de quadros | "Corrija a velocidade do pulo em 120Hz" |
| [`publish-rule-issue`](#39-publish-rule-issue-publicação-global-de-regras) | Registro de regras aprendidas no repo central | Pós-ciclo de `/learn` ou solicitação explícita | `/publish-rule-issue` |

---

## 🛠️ 3. Detalhamento Exaustivo das Skills

### 3.1. `plan-feature` (Esteira de Planejamento e Design)
- **Definição**: [skills/plan-feature/SKILL.md](https://github.com/VitorJacom/my-agents/blob/main/skills/plan-feature/SKILL.md)
- **Objetivo**: Conduzir o ciclo completo de planejamento e refinamento arquitetural antes de qualquer linha de código de produção ser escrita. Orquestra a colaboração entre `product-owner`, `uiux-designer` (quando houver interface) e `system-architect`.
- **Gatilho de Progressive Disclosure**:
  - Quando o usuário deseja desenhar uma nova funcionalidade do zero.
  - Quando há uma issue macro/épico que precisa de fatiamento atômico e análise de Blast Radius.
- **Formas de Invocação**:
  ```text
  /plan-feature Sistema de notificações push com suporte a WebSockets
  /plan-feature Refinar a issue #14 adicionando suporte a autenticação multifator
  ```
- **Artefatos Produzidos**:
  - `planning_proposal.md`: Contém a visão funcional, Personas, Critérios Gherkin, Contrato Visual (Mockup ASCII e Tokens), Mapeamento de Blast Radius e Matriz de Execution Waves.
  - Atualização viva em `docs/ARCHITECTURE.md`.
  - Criação automática de Milestones e Issues no GitHub após aprovação explícita do usuário.

---

### 3.2. `issue-pipeline` (Esteira TDD Unitária e Maestro)
- **Definição**: [skills/issue-pipeline/SKILL.md](https://github.com/VitorJacom/my-agents/blob/main/skills/issue-pipeline/SKILL.md)
- **Objetivo**: Executar a máquina de estados determinística AIDD para implementar issues do GitHub garantindo integridade de testes, TDD rigoroso e proteção anti-fraude.
- **Dois Modos de Trabalho**:
  1. **Modo Unitário**: Execução atômica de uma única issue via subagentes (`planner` ➔ `qa-engineer` ➔ `coder` ➔ `gatekeeper`).
  2. **Modo Maestro (Multi-Issue)**: Pre-flight de governança, particionamento em Git Worktrees isolados (`scripts/worktree-manager.sh`), paralelização por Execution Waves com arquivos disjuntos, Merge Queue sequencial com rebase-sync e Auto-Reconciliação.
- **Gatilho de Progressive Disclosure**:
  - Solicitação de resolução ou implementação de issues no GitHub.
- **Formas de Invocação**:
  ```text
  # Modo Unitário
  /run-issue #12
  /run-issue 12

  # Modo Maestro Multi-Issue
  /run-issues #12, #13, #14
  /run-issues 12 13 14 --base integration/wave-1
  ```
- **Artefatos Produzidos**:
  - `task.md` e `implementation_plan.md` (efêmeros locais).
  - Testes de critérios de aceite em `tests/features/`.
  - Código de produção em `src/`.
  - `walkthrough.md` com provas completas de testes, cobertura e diff.
  - Pull Request no GitHub criado pelo `gatekeeper`.

---

### 3.3. `code-review` (Auditoria de Qualidade e Segurança)
- **Definição**: [skills/code-review/SKILL.md](https://github.com/VitorJacom/my-agents/blob/main/skills/code-review/SKILL.md)
- **Objetivo**: Auditoria aprofundada de código-fonte antes de merges ou submissões de PR, avaliando 4 dimensões críticas:
  1. **Segurança (OWASP)**: Injeção de SQL/Shell, exposição de dados sensíveis e sanitização de inputs.
  2. **Arquitetura & Clean Code**: Aderência ao SOLID, injeção de dependências e complexidade ciclomática.
  3. **Performance & Recursos**: Vazamentos de memória, queries N+1 e bloqueio do event loop.
  4. **Testabilidade & Integridade**: Ausência de falsos positivos e cobertura de edge cases.
- **Gatilho de Progressive Disclosure**:
  - Solicitação de revisão de PR ou auditoria de arquivos modificados na branch.
- **Formas de Invocação**:
  ```text
  /code-review
  Revise as alterações da branch atual contra vulnerabilidades de segurança
  ```
- **Artefatos Produzidos**:
  - Parecer estruturado com categorização por severidade (Crítico, Médio, Baixo) e sugestões de refatoração imediata.

---

### 3.4. `test-runner` (Diagnóstico e Reparo de Testes)
- **Definição**: [skills/test-runner/SKILL.md](https://github.com/VitorJacom/my-agents/blob/main/skills/test-runner/SKILL.md)
- **Objetivo**: Diagnóstico inteligente de falhas em suítes de testes automatizados e reparo cirúrgico de código quebrado em múltiplos ecossistemas (Node/TS, Python, Go, Rust).
- **Gatilho de Progressive Disclosure**:
  - Falha na execução de testes, pipelines de CI vermelhos ou quebras de regressão.
- **Formas de Invocação**:
  ```text
  /test
  Execute a suíte de testes e corrija as falhas em tests/features/
  ```
- **Artefatos Produzidos**:
  - Relatório de causas-raiz de quebras, plano de correção pontual e suíte re-executada com status 100% verde (GREEN).

---

### 3.5. `git-workflow` (Branches Semânticas e Commits)
- **Definição**: [skills/git-workflow/SKILL.md](https://github.com/VitorJacom/my-agents/blob/main/skills/git-workflow/SKILL.md)
- **Objetivo**: Padronização da criação de branches semânticas (`feature/`, `fix/`, `refactor/`), elaboração de mensagens de commit seguindo a especificação de **Conventional Commits** e preparação de Pull Requests.
- **Gatilho de Progressive Disclosure**:
  - Sempre que o agente for realizar operações de versionamento no Git ou preparar commits e PRs.
- **Formas de Invocação**:
  ```text
  Crie a branch de trabalho para a issue #20
  Prepare o commit com as mudanças de documentação seguindo o Conventional Commits
  ```
- **Artefatos Produzidos**:
  - Commits padronizados (ex.: `feat(docs): ...`, `fix(auth): ...`) e branches organizadas.

---

### 3.6. `architecture-decision` (Registros de ADR)
- **Definição**: [skills/architecture-decision/SKILL.md](https://github.com/VitorJacom/my-agents/blob/main/skills/architecture-decision/SKILL.md)
- **Objetivo**: Registro formal e padronizado de decisões de arquitetura e design de software (ADRs), preservando o contexto histórico, opções consideradas e trade-offs assumidos.
- **Gatilho de Progressive Disclosure**:
  - Escolhas de banco de dados, adoção de protocolos de comunicação, introdução de novos frameworks ou consolidação estrutural.
- **Formas de Invocação**:
  ```text
  Crie uma ADR documentando a escolha de SQLite para armazenamento local de cache
  Documente a decisão de adotar Git Worktrees para concorrência de issues
  ```
- **Artefatos Produzidos**:
  - Registro estruturado no formato Michael Nygard consolidado em `docs/ARCHITECTURE.md` ou mantido sob `docs/adr/`.

---

### 3.7. `docker-dev` (Diagnóstico e Containers)
- **Definição**: [skills/docker-dev/SKILL.md](https://github.com/VitorJacom/my-agents/blob/main/skills/docker-dev/SKILL.md)
- **Objetivo**: Diagnóstico, validação e manutenção de ambientes locais baseados em Docker e Docker Compose, tratando portas ocupadas, montagens de volume incorretas e containers falhando.
- **Gatilho de Progressive Disclosure**:
  - Erros de inicialização de containers locais, falha de comunicação entre serviços ou diagnóstico de logs.
- **Formas de Invocação**:
  ```text
  O container da API está reiniciando em loop, descubra o motivo
  Verifique as portas em conflito no docker-compose.yml
  ```
- **Artefatos Produzidos**:
  - Diagnóstico com saída de `docker logs`, identificação da causa-raiz e correções nas variáveis de ambiente ou montagem de volumes.

---

### 3.8. `game-dev-patterns` (Padrões e Física para Jogos 2D)
- **Definição**: [skills/game-dev-patterns/SKILL.md](https://github.com/VitorJacom/my-agents/blob/main/skills/game-dev-patterns/SKILL.md)
- **Objetivo**: Garantir boas práticas de engenharia e física cinemática em jogos 2D (HTML5, Phaser 3, PixiJS, Canvas API), eliminando armadilhas de renderização dependente de taxa de atualização.
- **Principais Padrões Abordados**:
  1. **Independência de Taxa de Quadros (FPS Independence & Timestep)**:
     - Utilização obrigatória de `delta` de tempo (`deltaInSeconds = delta / 1000`) para movimentos e acelerações.
     - Simulação de física com *Fixed Timestep* (acumulador de tempo fixo).
  2. **Debounce em Colisões Contínuas**: Prevenção de múltiplos disparos de dano ou som em um único toque.
  3. **Preservação Dimensional de Sprites**: Separação de container lógico e sprite visual para evitar explosão de escala em animações.
  4. **Alcance Cinemático Procedural**: Fórmulas balísticas para garantir que plataformas geradas proceduralmente sejam sempre alcançáveis pelo pulo do personagem.
- **Gatilho de Progressive Disclosure**:
  - Exclusivo para projetos de jogos 2D ou simulações interativas no navegador. Permanece completamente adormecido em projetos de outros domínios (*Zero Token Waste*).
- **Formas de Invocação**:
  ```text
  O personagem pula mais alto em monitores de 144Hz, ajuste para delta time
  Aplique debounce no som de impacto da colisão entre o projétil e o inimigo
  ```
- **Artefatos Produzidos**:
  - Funções de física desacopladas da taxa de atualização e testes de física determinísticos.

---

### 3.9. `publish-rule-issue` (Publicação Global de Regras)
- **Definição**: [skills/publish-rule-issue/SKILL.md](https://github.com/VitorJacom/my-agents/blob/main/skills/publish-rule-issue/SKILL.md)
- **Objetivo**: Publicar uma issue estruturada no repositório canônico central `VitorJacom/my-agents` contendo o contexto, causa-raiz e proposta de nova regra aprendida via comando `/learn` em qualquer workspace do desenvolvedor.
- **Gatilho de Progressive Disclosure**:
  - Execução pós-ciclo de `/learn`, quando o agente identifica uma regra reutilizável e pergunta ao desenvolvedor se deseja registrá-la centralmente.
- **Formas de Invocação**:
  ```text
  /publish-rule-issue
  Publique a regra aprendida nesta sessão no repositório central my-agents
  ```
- **Artefatos Produzidos**:
  - Issue aberta via GitHub CLI (`gh issue create --repo VitorJacom/my-agents`) com labels `rule-proposal`, `enhancement` e corpo padronizado.

---

## 📚 4. Leituras Complementares

- [Guia de Introdução (`docs/Getting-Started.md`)](./Getting-Started.md): Setup de plugins e primeiro comando.
- [Catálogo de Subagentes (`docs/Subagents.md`)](./Subagents.md): Detalhamento das personas executoras.
- [Arquitetura Geral (`docs/ARCHITECTURE.md`)](https://github.com/VitorJacom/my-agents/blob/main/docs/ARCHITECTURE.md): Visão de sistema e histórico de decisões técnicas.
