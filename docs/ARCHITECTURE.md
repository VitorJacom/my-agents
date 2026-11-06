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
│   ├── worktree-manager.sh   # Gestor de ciclo de vida de worktrees isolados
│   └── reconcile-github-governance.sh # Reconciliação idempotente de governança e backlog
├── hooks.json                # Guardrails de execução e injeção de contexto
└── docs/                     # Documentação viva e modular do sistema (espelhada na Wiki)
    ├── ARCHITECTURE.md       # Fonte única da verdade arquitetural (ADRs e Decisões Técnicas)
    ├── Home.md               # Landing Hub da GitHub Wiki
    ├── _Sidebar.md           # Navegação lateral estruturada da GitHub Wiki
    ├── _Footer.md            # Rodapé institucional padronizado da GitHub Wiki
    ├── Getting-Started.md    # Guia de onboarding e setup para desenvolvedores e agentes
    ├── AIDD-Manifesto.md     # Valores e governança do Manifesto AI-Driven Development
    ├── System-Architecture.md # Visão estrutural de alto nível para a Wiki
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
  5. **Taxonomia Padronizada de Labels e Guia Canônico de Views no GitHub Projects v2**:
     - **Views Essenciais no GitHub Projects v2**:
       1. **Kanban Board** (Layout: Board):
          - Agrupamento principal por colunas no campo `Status` (`Planned`, `In Progress`, `In Review`, `Done`).
          - Visibilidade direta do fluxo contínuo de trabalho e gargalos de execução ativa.
       2. **Milestone Roadmap** (Layout: Roadmap / Timeline):
          - Agrupamento e ordenação por `Milestone` e data/iteração.
          - Visualização macro de entregas de versões, sprints e épicos planejados.
       3. **Backlog View** (Layout: Table / List):
          - Visão em tabela com filtros para triagem e priorização (ex: itens sem milestone ou em estado `status:planned`).
          - Campos visíveis: Title, Status, Milestone, Labels e Assignees.
     - **Taxonomia Oficial de Labels AIDD**:
       | Categoria | Label | Descrição / Uso |
       | :--- | :--- | :--- |
       | **`type:*`** | `type:feat` | Nova funcionalidade para o sistema ou usuário |
       | | `type:fix` | Correção de defeito / bug |
       | | `type:docs` | Documentação técnica, arquitetura ou guias |
       | | `type:refactor` | Refatoração de código sem alteração funcional ou testes |
       | | `type:chore` | Dependências, build, infraestrutura e manutenção |
       | | `type:test` | Adição ou reestruturação de testes automatizados |
       | **`status:*`** | `status:planned` | Issue decomposta e pronta para execução no backlog |
       | | `status:in-progress` | Issue em desenvolvimento ativo pelo subagente ou desenvolvedor |
       | | `status:blocked` | Trabalho impedido por dependência externa ou bloqueio técnico |
       | | `status:ready-for-review` | Código e testes verdes concluídos, aguardando revisão do PR |
       | **`aidd:*`** | `aidd:wave-*` | Escalonamento em ondas concorrentes do Maestro (ex: `aidd:wave-1`, `aidd:wave-2`) |
       | | `aidd:clean-room` | Validação isolada em ambiente estéril / sandbox desacoplado |
       | | `aidd:reconciled` | Marcador de merge queue indicando resolução automatizada de divergência |

---

### Decisão 0008 (2026-11-06): Arquitetura da Informação Modular e Governança da GitHub Wiki
* **Status**: Proposta
* **Contexto**: A documentação pública na GitHub Wiki dependia de um espelhamento monolítico de `docs/ARCHITECTURE.md` sobrescrito como `Home.md` em `.github/workflows/wiki-sync.yml`. Esse comportamento resultava em uma página única de texto corrido com mais de 150 linhas e centenas de tópicos misturados, ausência de barra de navegação lateral (`_Sidebar.md`), ausência de rodapé institucional (`_Footer.md`), e falta de guias dedicados de onboarding, catálogo de subagentes e catálogo de skills. Além disso, não existia verificação automatizada de integridade sintática e de links internos, arriscando dead links na Wiki do repositório.
* **Solução Adotada**:
  1. **Taxonomia Modular de Arquitetura da Informação**:
     - Decomposição funcional de `docs/` em 9 artefatos temáticos coesos: `Home.md`, `_Sidebar.md`, `_Footer.md`, `Getting-Started.md`, `Subagents.md`, `Skills-Catalog.md`, `AIDD-Manifesto.md`, `System-Architecture.md` e `Troubleshooting.md`.
     - `ARCHITECTURE.md` (em maiúsculas) permanece como a fonte canônica interna de decisões arquiteturais do repositório, enquanto `System-Architecture.md` atua como a página de visão geral voltada para o leitor da Wiki, eliminando colisões de casing em sistemas de arquivos case-insensitive.
  2. **Navegação Canônica da Wiki (`_Sidebar.md` e `_Footer.md`)**:
     - Adoção dos recursos nativos do GitHub Wiki para barra lateral fixa e rodapé comum, permitindo que o leitor navegue rapidamente entre Manuais, Governança AIDD e Catálogo de Recursos sem perder o contexto.
  3. **Refatoração do Pipeline de Sincronização (`.github/workflows/wiki-sync.yml`)**:
     - Eliminação do workaround legado que sobrescrevia `Home.md` a partir de `ARCHITECTURE.md`.
     - Preservação da integridade estrutural: cópia de todos os arquivos de `docs/` diretamente para o clone da Wiki, mantendo cada documento em seu escopo de URL nativo do GitHub (`https://github.com/<owner>/<repo>/wiki/<slug>`).
  4. **Garantia Determinística de Integridade via Testes TDD (`tests/features/test_wiki_structure_and_links.sh`)**:
     - Implementação de suíte de testes de conformidade que valida a presença física de todos os artefatos de documentação, verifica a resolução de todos os links internos de navegação (anti-dead link) e audita o pipeline do GitHub Actions contra regressões no script de sincronização.

---

### Decisão 0009 (2026-11-06): Reconciliação Idempotente de Governança no GitHub e Backfill de Backlog
* **Status**: Implementada
* **Contexto**: Com o suporte nativo a Milestones e GitHub Projects v2 (Decisão 0007), issues existentes, épicos desmembrados ou itens criados fora do pipeline AIDD sofrem deriva de governança (ausência de milestone ativa ou não vinculação ao quadro do Project v2). Além disso, falhas transitórias de conectividade ou execuções legadas necessitavam de um mecanismo determinístico de auditoria e reconciliação em lote.
* **Solução Adotada**:
  1. **Script Utilitário de Reconciliação (`scripts/reconcile-github-governance.sh`)**:
     - Varredura determinística de issues abertas via GitHub CLI (`gh issue list`).
     - Extração canônica de `Active Milestone`, `Owner` e `Project Number` a partir de `PROJECT_CONTEXT.md` (ou caminho alternativo via `--context-file`).
     - Atribuição idempotente da Milestone ativa às issues desprovidas de marco (`gh issue edit --milestone`), preservando milestones distintas pré-existentes.
     - Vinculação resiliente ao GitHub Projects v2 (`gh project item-add`) operando sob o princípio da degradação graciosa (não bloqueante em falhas de API/permissões).
     - Suporte mandatório a execução simulada (`--dry-run`) e especificação de repositório remoto (`--repo` / `-R`).
  2. **Integração Operacional com o Pipeline de Planejamento (`skills/plan-feature/SKILL.md`)**:
     - Inclusão do procedimento de reconciliação de governança no ciclo operacional de fatiamento de backlog, garantindo que o breakdown de épicos e sub-issues reflita imediatamente nas Views canônicas (Kanban Board, Milestone Roadmap e Backlog Table) do GitHub Projects v2.

---

### Decisão 0010 (2026-11-06): Telemetria de Concorrência e Eficiência no Modo Maestro (Wall-Clock Time e Speedup)
* **Status**: Proposta
* **Contexto**: No Modo Maestro (`issue-pipeline`), tarefas e issues são particionadas e despachadas em ondas concorrentes (*Execution Waves*) de até 3 workers simultâneos em worktrees isoladas. Contudo, o coletor de telemetria legado (`scripts/metrics-collector.py`) realizava apenas o somatório linear das durações dos agentes (`tot_time += duration_seconds`). Essa abordagem distorcia a telemetria em execuções concorrentes, apresentando um "tempo total" irreal que somava tempos de tarefas executadas em paralelo e ocultava os ganhos reais de velocidade (*speedup*), além de não identificar o worker gargalo de cada onda.
* **Solução Adotada**:
  1. **Modelo Hierárquico de Ondas de Execução**:
     - Suporte nativo ao argumento `--waves` recebendo estruturas mapeadas por onda: `{"Wave 1": {"Worker #1": "cid1", ...}, "Wave 2": {...}}`.
     - Preservação estrita de retrocompatibilidade com `--agents` para chamadas planas unitárias da esteira `/run-issue`.
  2. **Cálculo Determinístico de Wall-Clock Time e Eficiência**:
     - **Duração da Onda (Wall-Clock)**: Computada como o maior tempo decorrido entre os workers da onda: $T_{\text{wave}} = \max(T_{\text{worker}})$.
     - **Tempo Total do Batch**: Soma dos tempos de relógio de cada onda sequencial: $T_{\text{batch}} = \sum T_{\text{wave}_i}$.
     - **Esforço Cumulativo dos Agentes**: Somatório linear do tempo de computação de todos os subagentes: $T_{\text{cumulativo}} = \sum T_{\text{worker}}$.
     - **Métricas de Ganho**: Cálculo de Speedup ($S = \frac{T_{\text{cumulativo}}}{T_{\text{batch}}}$) e Tempo Economizado ($T_{\text{saved}} = T_{\text{cumulativo}} - T_{\text{batch}}$).
     - **Identificação do Worker Crítico**: Marcação explícita do worker de maior duração em cada onda como o caminho crítico (*critical path / bottleneck*).
  3. **Renderização Transparente (Terminal & Markdown)**:
     - Exibição tabular agrupada por ondas, com subtotais de Wall-Clock e destaque visual do gargalo de cada onda.
     - Resumo consolidado destacando o tempo real decorrido (*Wall-Clock*), esforço total cumulativo e fator de aceleração (*Speedup*) para publicação transparente no `walkthrough.md` e PR consolidado.


---

### Decisão 0011 (2026-11-06): Esteira Automatizada de Code Review de Pull Requests com Geração de Issues e Governança (/review-pr)
* **Status**: Proposta
* **Contexto**: A revisão de código no ciclo AIDD era realizada apenas sob demanda manual via `skills/code-review/SKILL.md`, sem integração nativa com o GitHub CLI para submissão oficial de revisões (`gh pr review`), sem validação determinística contra quebra de invariantes do ecossistema (como a Golden Rule em `tests/core/` em PRs abertos) e sem capacidade de converter automaticamente apontamentos de qualidade/segurança em issues rastreáveis no backlog com herança de Milestone e Project v2.
* **Solução Adotada**:
  1. **Motor Determinístico de Inspeção e Auditoria de PR (`scripts/pr-reviewer.sh`)**:
     - Subcomando `fetch-diff`: Extração de metadados de PR (`gh pr view`) e diff unificado (`gh pr diff`) com validação de status (`state: OPEN`) e parsing resiliente via Python3/jq.
     - Subcomando `audit-integrity`: Execução automatizada e fail-fast da Golden Rule Anti-Fraude (bloqueio imediato se `tests/core/` for adulterado na PR) e checagem de Anti-Triviality em novos testes incluídos no diff.
  2. **Interação Determinística com a PR no GitHub**:
     - Subcomando `submit-review`: Submissão de parecer formal com suporte a `--approve`, `--request-changes` e `--comment`, mapeados com base na severidade dos achados:
       - `REQUEST_CHANGES`: Presença de apontamentos classificados como `🚨 Crítico` ou violação da Golden Rule.
       - `COMMENT`: Presença de apontamentos `⚠️ Importante` ou `💡 Sugestão`.
       - `APPROVE`: Nenhuma não-conformidade identificada.
     - Suporte nativo a `--dry-run` para pre-flights seguros e execução em ambientes de teste.
  3. **Gerador Automático de Issues Rastreadas com Governança**:
     - Subcomando `create-issues`: Extração estruturada de apontamentos `🚨 Crítico` e `⚠️ Importante` para criação em lote de issues no GitHub via `gh issue create`.
     - Taxonomia Semântica AIDD: Injeção de labels `type:fix` / `type:refactor`, `status:planned` e `source:code-review`.
     - Cross-Reference Bidirecional: A issue gerada contém o link direto e commit SHA do PR de origem, e o parecer do PR referencia as issues criadas para rastreamento.
     - Reconciliação Imediata de Governança: Acionamento determinístico de `scripts/reconcile-github-governance.sh` garantindo atribuição da `Active Milestone` e vinculação ao `GitHub Project v2` conforme configurado em `PROJECT_CONTEXT.md`.
  4. **Orquestrador de Alto Nível (`/review-pr` & `skills/review-pr/SKILL.md`)**:
     - Máquina de estados de 5 fases (Pre-flight ➔ Deep Audit ➔ Human Gate ➔ PR Review ➔ Issue Generation & Governance).
     - Gate de Validação Humana mandatório antes de qualquer ação com efeitos colaterais externos no GitHub.
     - Documentação atualizada no catálogo canônico da Wiki (`docs/Skills-Catalog.md`).
