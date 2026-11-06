# Arquitetura e Decisões Técnicas do Plugin `my-agents`

Este documento consolida a arquitetura estrutural do plugin `my-agents`, seus componentes canônicos e o histórico de decisões de engenharia tomadas ao longo do ciclo de vida do projeto.

---

## 🏛️ 1. Visão Geral da Arquitetura

O `my-agents` é um repositório central de governança, guardrails de segurança e automações para o **Antigravity CLI** (Gemini CLI), desenhado sob os 4 valores do **Manifesto AIDD** (*AI-Driven Development*):
1. **Método sobre o Modelo (Method over Model)**
2. **Responsabilidade sobre Delegação (Ownership over Delegation)**
3. **Compreensão sobre Aceitação (Understanding over Acceptance)**
4. **Resultado sobre Volume (Outcome over Output)**

### Taxonomia de Componentes

```text
my-agents/
├── rules/                    # Regras comportamentais carregadas no contexto global
│   └── AGENTS.md             # Manifesto AIDD, travas anti-fraude e governança
├── agents/                   # Subagentes especializados de ciclo fechado
│   ├── product-owner/        # Engenharia de requisitos e personas
│   ├── system-architect/     # Impacto técnico e consolidação arquitetural
│   ├── uiux-designer/        # Ergonomia, Value Contrast, WCAG e Game Feel
│   ├── planner/              # Triagem e plano atômico TDD (Interface Contract)
│   ├── qa-engineer/          # Engenharia de testes TDD (fase RED / Concorrente)
│   ├── coder/                # Construção em src/ (fase GREEN / Concorrente)
│   └── gatekeeper/           # Auditoria anti-fraude e publicação no PR
├── skills/                   # Habilidades sob demanda (Progressive Disclosure)
│   ├── game-dev-patterns/    # Física 2D, FPS independence e cinemática
│   ├── plan-feature/         # Esteira de planejamento funcional e técnico
│   ├── issue-pipeline/       # Esteira de execução TDD (Worktree + Fork/Join)
│   ├── architecture-decision/# Diretrizes de design técnico
│   └── ...                   # Outras skills especializadas
├── scripts/                  # Ferramental operacional e statusline
│   ├── statusline-quota.sh   # Renderizador modular da statusline
│   ├── install-statusline.sh # Automação de setup plug-and-play
│   ├── test-statusline.sh    # Benchmark sub-50ms e suite de integridade
│   └── worktree-manager.sh   # Gestor de ciclo de vida de worktrees isolados
├── hooks.json                # Guardrails de execução e injeção de contexto
└── docs/                     # Documentação viva e modular do sistema (espelhada na Wiki)
    ├── ARCHITECTURE.md       # Fonte única da verdade arquitetural (ADRs e Decisões Técnicas)
    ├── Home.md               # Landing Hub da GitHub Wiki
    ├── _Sidebar.md           # Navegação lateral estruturada da GitHub Wiki
    ├── _Footer.md            # Rodapé institucional padronizado da GitHub Wiki
    ├── Getting-Started.md    # Guia de onboarding e setup para desenvolvedores e agentes
    ├── AIDD-Manifesto.md     # Valores e governança do Manifesto AI-Driven Development
    ├── Architecture.md       # Visão estrutural de alto nível para a Wiki
    ├── Subagents.md          # Catálogo canônico das 7 personas de subagentes
    ├── Skills-Catalog.md     # Catálogo de skills sob demanda (Progressive Disclosure)
    └── Troubleshooting.md    # Resolução de problemas e procedimentos operacionais
```

---

## 🔄 2. Estratégia de Ciclo de Vida Híbrido (Local vs Nuvem)

Para equilibrar a velocidade e economia de tokens da IA com a visibilidade de gestão para humanos, o `my-agents` adota uma governança híbrida:

1. **Efemeridade Local de Execução (`.gitignore`)**:
   - `task.md`, `implementation_plan.md` e `walkthrough.md` vivem exclusivamente no disco local durante o desenvolvimento.
   - Não são comitados na branch `main`, mantendo o histórico do Git limpo de arquivos transitórios de semáforo.
2. **Persistência de Provas no GitHub**:
   - O subagente `gatekeeper` lê o `walkthrough.md` local e o injeta como o corpo oficial do Pull Request (`gh pr create --body-file walkthrough.md`).
   - O histórico de auditoria, diffs e screenshots fica permanentemente arquivado no GitHub PR.
3. **Sincronização Contínua com a GitHub Wiki**:
   - O workflow `.github/workflows/wiki-sync.yml` espelha automaticamente a pasta `docs/` para a aba **Wiki** oficial do GitHub em cada push na `main`, garantindo visibilidade web sem esforço manual.

---

## 📜 3. Histórico Consolidado de Decisões de Arquitetura

### Decisão 0001 (2026-11-04): Generalização de Regras Visuais, Subagente UI/UX e Desacoplamento de Domínio (Game Dev)
* **Status**: Implementada
* **Contexto**: Demandas originadas no projeto `mels-game` (jogo 2D em Phaser 3) solicitando regras de física e testes visuais (Issues #1 e #2).
* **Problema de Viés**: Injetar regras de física 2D e frameworks de jogos em `rules/` poluía o contexto de projetos backend/CLI e consumiria desnecessariamente o orçamento de 20.000 tokens de regras globais do Antigravity.
* **Solução em 3 Camadas**:
  1. **Governança Global**: Cláusula condicional no Manifesto AIDD (`rules/AGENTS.md`) exigindo provas visuais no `walkthrough.md` apenas para tarefas com interface gráfica (Web, Mobile, Jogos).
  2. **Subagente UI/UX Transversal (`uiux-designer`)**: Especialista em hierarquia visual, usabilidade, acessibilidade (WCAG), Contraste de Valor monocromático e *Game Feel / Juiciness*.
  3. **Skill Especializada (`game-dev-patterns`)**: Encapsulamento das regras de física 2D (*Fixed Timestep*, *FPS independence*, debounce de colisões e alcance cinemático) em uma skill sob demanda com *Progressive Disclosure*.

---

### Decisão 0002 (2026-11-04): Governança Efêmera de Arquivos de Tarefa, Fonte Única ARCHITECTURE.md e Wiki Sync
* **Status**: Implementada
* **Contexto**: Discussão sobre o versionamento repetitivo de `task.md`, `implementation_plan.md` e `walkthrough.md` na raiz da `main` e a dispersão de documentos em múltiplos arquivos `docs/adr/`.
* **Solução Adotada**:
  1. **Arquivos de Ciclo de Vida Efêmeros**: Adicionados ao `.gitignore`. O `gatekeeper` publica o relatório diretamente no corpo do PR no GitHub.
  2. **Fonte Única da Verdade (`docs/ARCHITECTURE.md`)**: Unificação da visão de sistema e de todas as decisões técnicas em um documento vivo, eliminando a pasta `docs/adr/`.
  3. **Automação com a GitHub Wiki**: Workflow no GitHub Actions para espelhar a documentação do repositório diretamente na Wiki web do GitHub.

---

### Decisão 0003 (2026-11-04): Arquitetura Modular de Statusline Plug-and-Play e Performance Sub-50ms
* **Status**: Proposta
* **Contexto**: A statusline personalizada atual (`scripts/statusline-quota.sh`) é monolítica e exige configuração manual em `~/.gemini/antigravity-cli/settings.json`. Adicionalmente, extensões futuras de widgets podem degradar o tempo de resposta do terminal.
* **Solução Adotada**:
  1. **Modularização de Widgets**: Decomposição em widgets desacoplados (Model, Git, Quota 5h/Semanal e Telemetria) com renderização combinada e fallback seguro caso o payload do Antigravity CLI seja parcial ou ausente.
  2. **Garantia de Latência Sub-50ms**: Proibição de chamadas externas de rede ou subprocessos pesados síncronos na renderização; adoção de script de validação e benchmark automatizado (`scripts/test-statusline.sh`).
  3. **Instalação Plug-and-Play**: Script idempotente (`scripts/install-statusline.sh`) com salvaguarda de backup para injetar o comando da statusline no `settings.json` do usuário de forma transparente.

---

### Decisão 0004 (2026-11-06): Orquestração Multi-Task Concorrente (Maestro), Git Worktrees, Ondas de Execução e Merge Queue em Branch Intermediária
* **Status**: Proposta
* **Contexto**: A execução simultânea de múltiplas issues por agentes exige mais do que o isolamento local de diretórios: é necessário evitar a contaminação de contexto na sessão principal, prevenir colisões de escopo antes da codificação, eliminar falsos conflitos sistêmicos no `PROJECT_CONTEXT.md` e garantir que a integração sequencial das entregas não quebre a branch `main` (conflitos textuais ou semânticos).
* **Solução Adotada**:
  1. **Arquitetura Maestro + Subagentes Worker Isolados (`invoke_subagent 'self'` + Worktree)**:
     - Quando `/run-issue` é invocado para múltiplas issues (`/run-issue #24 #25 #26`) ou um épico (`/run-issue --epic #20`), a sessão principal atua exclusivamente como **Maestro (Control Plane)**, sem ler código de produção diretamente.
     - Cada issue é delegada a um subagente Worker dedicado (`invoke_subagent` com `TypeName: 'self'`, `ConversationID` isolado e teto máximo de **3 Workers simultâneos** por onda), operando em um diretório estéril `.worktrees/issue-<id>` protegido por lock atômico (`.worktrees/.lock-<id>`).
  2. **Prevenção de Conflitos na Origem (`Target Files` & `Execution Waves`)**:
     - O `system-architect` (em `/plan-feature`) e o `planner` declaram formalmente os `Target Files` (blast radius) e `Depends On` de cada issue.
     - O Maestro realiza checagem pre-flight de interseção de `Target Files`: issues que tocam no mesmo arquivo nunca rodam simultaneamente, sendo escalonadas automaticamente em Ondas de Execução (*Execution Waves*) sequenciais.
  3. **Desacoplamento de Estado Volátil do `PROJECT_CONTEXT.md`**:
     - Para eliminar 100% dos falsos conflitos em PRs paralelos, o bloco volátil (`Última Atualização`, `Branch Ativa`, `Último Commit`, `Resumo de Alterações Recentes`) deixa de ser comitado no `PROJECT_CONTEXT.md` pelas branches de feature e passa a ser extraído e injetado dinamicamente em tempo real pelo hook `scripts/session-start-context.sh`.
  4. **Branch Intermediária de Integração, Merge Queue e Auto-Reconciliação**:
     - Em execuções multi-issue, o Maestro cria uma branch intermediária (`integration/batch-<id>` ou `epic/issue-<id>`) a partir de `origin/main`, da qual derivam as worktrees das issues.
     - Conforme cada Worker conclui seu ciclo TDD e passa pelo Gatekeeper, o Maestro executa o **Rebase Train (`worktree-manager.sh rebase-sync`)**: faz rebase da branch da issue sobre a branch intermediária atualizada, roda 100% da suíte acumulada (`tests/core/` + todos os `tests/features/` já integrados) e realiza o auto-merge na branch intermediária.
     - Em caso de conflito textual ou falha de teste pós-rebase (conflito semântico), o Maestro aciona até **2 iterações de Auto-Reconciliação** com o `coder` na worktree da issue, sob Trava Anti-Fraude estrita (proibido modificar `tests/core/` ou arquivos de `tests/features/` pertencentes a outras issues já integradas).
     - Ao final das ondas, o Maestro abre **um único Pull Request consolidado** da branch intermediária para a `main` para revisão e aprovação humana.

---

### Decisão 0005 (2026-11-04): Paralelismo Intra-Task Baseado em Contrato Congelado (QA & Coder)
* **Status**: Proposta
* **Contexto**: A esteira `/run-issue` operava estritamente em série (Planner ➔ QA RED ➔ Coder GREEN), criando gargalo temporal onde o Coder aguardava passivamente a escrita dos testes.
* **Solução Adotada**:
  1. **Interface Contract Inviolável**: O `implementation_plan.md` passa a conter obrigatoriamente a seção `## Interface Contract`, com tipagens, assinaturas de funções e contratos de dados 100% congelados na etapa de Planejamento.
  2. **Fork Concorrente**: QA Engineer (em `tests/features/`) e Coder (em `src/`) são disparados simultaneamente, ambos trabalhando de forma independente orientados exclusivamente pelo contrato.
  3. **Portão de Sincronização (Join Point)**: O orquestrador executa a suíte ao término de ambas as entregas. Se os testes passarem imediatamente, segue para o Gatekeeper; se houver desalinhamento, inicia-se um loop curto de refinamento (máx 2 iterações) para convergência.

---

### Decisão 0006 (2026-11-06): Orquestração Condicional do `uiux-designer` e Protocolo de Mockup-as-Code (Figma-less)
* **Status**: Proposta
* **Contexto**: Embora o subagente `agents/uiux-designer/agent.md` tenha sido criado na Decisão 0001, ele permanecia órfão (nunca invocado nas máquinas de estado de `skills/plan-feature/SKILL.md` nem de `skills/issue-pipeline/SKILL.md`). Como consequência, em tarefas visuais o `coder` improvisava layouts, paletas e estilos sem contrato visual prévio e sem auditoria estética pós-implementação. Além disso, o fluxo carecia de um substituto determinístico e versionável para a etapa tradicional de telas no Figma.
* **Solução Adotada**:
  1. **Protocolo Mockup-as-Code em 3 Camadas (Figma-less)**:
     - **Camada 1 (Wireframe Estrutural ASCII / Spatial Blueprint)**: Diagrama Box-drawing em Markdown definindo zonas, hierarquia, proporções, grid de 4px/8px e estados interativos.
     - **Camada 2 (Design Tokens & Luminance Contract)**: Tabela determinística de tokens congelados (Hex + conversão monocromática comprovando Value Contrast $\ge$ 2:1 para superfícies/elementos e WCAG AA $\ge$ 4.5:1 para textos, tipografia modular, bordas, sombras de oclusão e curvas de easing).
     - **Camada 3 (Protótipo Estático Autocontido + Screenshot Headless)**: Geração de protótipo efêmero `.mockup-preview.html` (HTML/CSS/SVG inline) renderizado em `.mockup-preview.png` via `chromium --headless --screenshot` para aprovação humana no Gate do `/plan-feature` e referência para o `coder`.
  2. **Orquestração Condicional Zero-Overhead**:
     - Em `/plan-feature`: Estado condicional **UI/UX & Mockup Design** acionado entre o `product-owner` e o `system-architect` exclusivamente quando a demanda possuir impacto visual (`[UI/UX Required: YES]`), injetando o `## Visual & UI/UX Contract` no `planning_proposal.md` e no corpo das Issues do GitHub.
     - Em `/run-issue`: No Estado de Planejamento, se a Issue for visual mas não possuir contrato prévio, o `uiux-designer` é acionado em Modo 1 para estabelecer o contrato; durante a codificação, o `coder` implementa estritamente os Design Tokens; antes do PR, o `uiux-designer` opera em Modo 2 (Auditoria Visual Headless) validando a tela real contra o mockup aprovado antes da liberação pelo `gatekeeper`.
  3. **Efemeridade de Artefatos de Preview**: Arquivos temporários `.mockup-preview.html` e `.mockup-preview.png` são adicionados ao `.gitignore` para não poluir a árvore Git de produção.

---

### Decisão 0007 (2026-11-06): Integração Nativa de Milestones e GitHub Projects v2 com Degradação Graciosa
* **Status**: Proposta
* **Contexto**: O ciclo AIDD gerenciava o ciclo de vida de issues de forma pontual no GitHub (`gh issue create`, `gh pr create`), sem integração com a camada de gestão de projetos (GitHub Projects v2) e sem amarração a metas de entrega (Milestones). Isso impedia que times humanos acompanhassem o progresso visual em tempo real em quadros Kanban/Views ou agrupassem entregas atômicas em sprints/versões oficiais sem trabalho manual pós-criação.
* **Solução Adotada**:
  1. **Declaração Canônica em `PROJECT_CONTEXT.md`**:
     - Introdução da seção `## 🎯 Rastreamento & GitHub Governance` para declarar `Active Milestone` e metadados do `GitHub Project v2` (Owner, Project Number e mapeamento de campos de Status: `Planned`, `In Progress`, `In Review`, `Done`).
  2. **Amarração Nativa de Milestones em `/plan-feature`**:
     - O Estado 4 do `/plan-feature` detecta se há uma Milestone ativa declarada no contexto ou passada na invocação e inclui a flag `--milestone "<milestone>"` na execução de `gh issue create`.
  3. **Adição e Transição de Status em GitHub Projects v2**:
     - Em `/plan-feature` (Estado 4): Ao criar cada issue, o orquestrador invoca `gh project item-add <project_number> --owner <owner> --url <issue_url>`, vinculando-a ao quadro do projeto de forma automatizada.
     - Em `/run-issue` (`issue-pipeline`): No início da execução (Estado 1/2), o status do item é atualizado para `In Progress`; na fase final (Estado 4 / Gatekeeper), o status transita para `In Review` com o PR aberto.
  4. **Princípio da Degradação Graciosa (Non-Blocking)**:
     - Todas as chamadas ao `gh project` são executadas com fallback resiliente e alertas informativos. Falhas por ausência de permissões no token (ex: falta de escopo `project`), projetos não configurados ou erros de rede NUNCA quebram a esteira de desenvolvimento AIDD.
  5. **Taxonomia Padronizada de Labels e Views AIDD**:
     - Padronização de labels para consistência entre boards e automações (`type:*`, `status:*`, `aidd:*`).
     - Definição canônica de Views recomendadas no GitHub Projects v2 (Board Kanban, Sprint/Milestone View e Roadmap).

---

### Decisão 0008 (2026-11-06): Arquitetura da Informação Modular e Governança da GitHub Wiki
* **Status**: Proposta
* **Contexto**: A documentação pública na GitHub Wiki dependia de um espelhamento monolítico de `docs/ARCHITECTURE.md` sobrescrito como `Home.md` em `.github/workflows/wiki-sync.yml`. Esse comportamento resultava em uma página única de texto corrido com mais de 150 linhas e centenas de tópicos misturados, ausência de barra de navegação lateral (`_Sidebar.md`), ausência de rodapé institucional (`_Footer.md`), e falta de guias dedicados de onboarding, catálogo de subagentes e catálogo de skills. Além disso, não existia verificação automatizada de integridade sintática e de links internos, arriscando dead links na Wiki do repositório.
* **Solução Adotada**:
  1. **Taxonomia Modular de Arquitetura da Informação**:
     - Decomposição funcional de `docs/` em 9 artefatos temáticos coesos: `Home.md`, `_Sidebar.md`, `_Footer.md`, `Getting-Started.md`, `Subagents.md`, `Skills-Catalog.md`, `AIDD-Manifesto.md`, `Architecture.md` e `Troubleshooting.md`.
     - `ARCHITECTURE.md` (em maiúsculas) permanece como a fonte canônica interna de decisões arquiteturais do repositório, enquanto `Architecture.md` atua como a página de visão geral voltada para o leitor da Wiki.
  2. **Navegação Canônica da Wiki (`_Sidebar.md` e `_Footer.md`)**:
     - Adoção dos recursos nativos do GitHub Wiki para barra lateral fixa e rodapé comum, permitindo que o leitor navegue rapidamente entre Manuais, Governança AIDD e Catálogo de Recursos sem perder o contexto.
  3. **Refatoração do Pipeline de Sincronização (`.github/workflows/wiki-sync.yml`)**:
     - Eliminação do workaround legado que sobrescrevia `Home.md` a partir de `ARCHITECTURE.md`.
     - Preservação da integridade estrutural: cópia de todos os arquivos de `docs/` diretamente para o clone da Wiki, mantendo cada documento em seu escopo de URL nativo do GitHub (`https://github.com/<owner>/<repo>/wiki/<slug>`).
  4. **Garantia Determinística de Integridade via Testes TDD (`tests/features/test_wiki_structure_and_links.sh`)**:
     - Implementação de suíte de testes de conformidade que valida a presença física de todos os artefatos de documentação, verifica a resolução de todos os links internos de navegação (anti-dead link) e audita o pipeline do GitHub Actions contra regressões no script de sincronização.
