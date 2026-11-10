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
│   ├── hooks/                # Hooks do Antigravity CLI (safety-guard, session-start)
│   ├── pipeline/             # Esteira AIDD (worktree-manager, metrics, reconcile, sync, audit-token-efficiency)
│   ├── statusline/           # Statusline CLI (statusline-quota, install, test)
│   └── migrations/           # Migrações históricas one-off
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
* **Contexto**: A statusline personalizada atual (`scripts/statusline/statusline-quota.sh`) é monolítica e exige configuração manual em `~/.gemini/antigravity-cli/settings.json`. Adicionalmente, extensões futuras de widgets podem degradar o tempo de resposta do terminal.
* **Solução Adotada**:
  1. **Modularização de Widgets**: Decomposição em widgets desacoplados (Model, Git, Quota 5h/Semanal e Telemetria) com renderização combinada e fallback seguro caso o payload do Antigravity CLI seja parcial ou ausente.
  2. **Garantia de Latência Sub-50ms**: Proibição de chamadas externas de rede ou subprocessos pesados síncronos na renderização; adoção de script de validação e benchmark automatizado (`scripts/statusline/test-statusline.sh`).
  3. **Instalação Plug-and-Play**: Script idempotente (`scripts/statusline/install-statusline.sh`) com salvaguarda de backup para injetar o comando da statusline no `settings.json` do usuário de forma transparente.

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
     - Para eliminar 100% dos falsos conflitos em PRs paralelos, o bloco volátil (`Última Atualização`, `Branch Ativa`, `Último Commit`, `Resumo de Alterações Recentes`) deixa de ser comitado no `PROJECT_CONTEXT.md` pelas branches de feature e passa a ser extraído e injetado dinamicamente em tempo real pelo hook `scripts/hooks/session-start-context.sh`.
  4. **Branch Intermediária de Integração, Merge Queue e Auto-Reconciliação**:
     - Em execuções multi-issue, o Maestro cria uma branch intermediária (`integration/batch-<id>` ou `epic/issue-<id>`) a partir de `origin/main`, da qual derivam as worktrees das issues.
     - Conforme cada Worker conclui seu ciclo TDD e passa pelo Gatekeeper, o Maestro executa o **Rebase Train (`worktree-manager.sh rebase-sync`)**: faz rebase da branch da issue sobre a branch intermediária atualizada, roda 100% da suíte acumulada (`tests/core/` + todos os `tests/features/` já integrados) e realiza o auto-merge na branch intermediária.
     - Em caso de conflito textual ou falha de teste pós-rebase (conflito semântico), o Maestro aciona até **2 iterações de Auto-Reconciliação** com o `coder` na worktree da issue, sob Trava Anti-Fraude estrita (proibido modificar `tests/core/` ou arquivos de `tests/features/` pertencentes a outras issues já integradas).
     - Ao final das ondas, o Maestro abre **um único Pull Request consolidado** da branch intermediária para a `main` para revisão e aprovação humana.

---

### Decisão 0005 (2026-11-04): Paralelismo Intra-Task Baseado em Contrato Congelado (QA & Coder)
* **Status**: Aprovada
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
  4. **Garantia Determinística de Integridade via Testes TDD (`tests/features/wiki/test_wiki_structure_and_links.sh`)**:
     - Implementação de suíte de testes de conformidade que valida a presença física de todos os artefatos de documentação, verifica a resolução de todos os links internos de navegação (anti-dead link) e audita o pipeline do GitHub Actions contra regressões no script de sincronização.

---

### Decisão 0009 (2026-11-06): Reconciliação Idempotente de Governança no GitHub e Backfill de Backlog
* **Status**: Implementada
* **Contexto**: Com o suporte nativo a Milestones e GitHub Projects v2 (Decisão 0007), issues existentes, épicos desmembrados ou itens criados fora do pipeline AIDD sofrem deriva de governança (ausência de milestone ativa ou não vinculação ao quadro do Project v2). Além disso, falhas transitórias de conectividade ou execuções legadas necessitavam de um mecanismo determinístico de auditoria e reconciliação em lote.
* **Solução Adotada**:
  1. **Script Utilitário de Reconciliação (`scripts/pipeline/reconcile-github-governance.sh`)**:
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
* **Contexto**: No Modo Maestro (`issue-pipeline`), tarefas e issues são particionadas e despachadas em ondas concorrentes (*Execution Waves*) de até 3 workers simultâneos em worktrees isoladas. Contudo, o coletor de telemetria legado (`scripts/pipeline/metrics-collector.py`) realizava apenas o somatório linear das durações dos agentes (`tot_time += duration_seconds`). Essa abordagem distorcia a telemetria em execuções concorrentes, apresentando um "tempo total" irreal que somava tempos de tarefas executadas em paralelo e ocultava os ganhos reais de velocidade (*speedup*), além de não identificar o worker gargalo de cada onda.
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
     - Reconciliação Imediata de Governança: Acionamento determinístico de `scripts/pipeline/reconcile-github-governance.sh` garantindo atribuição da `Active Milestone` e vinculação ao `GitHub Project v2` conforme configurado em `PROJECT_CONTEXT.md`.
  4. **Orquestrador de Alto Nível (`/review-pr` & `skills/review-pr/SKILL.md`)**:
     - Máquina de estados de 5 fases (Pre-flight ➔ Deep Audit ➔ Human Gate ➔ PR Review ➔ Issue Generation & Governance).
     - Gate de Validação Humana mandatório antes de qualquer ação com efeitos colaterais externos no GitHub.
     - Documentação atualizada no catálogo canônico da Wiki (`docs/Skills-Catalog.md`).

---

### Decisão 0012 (2026-11-06): Telemetria Resiliente de Quotas na Statusline do Antigravity CLI, Isolamento Multiterminal e Portabilidade Universal
* **Status**: Aprovada
* **Contexto**: O extrator de telemetria da statusline modular (`scripts/statusline/statusline-quota.sh`) apresentava fragilidades no ambiente de produção do Antigravity CLI:
  1. **Contaminação Cruzada de Schemas**: O schema JSON do Antigravity CLI provê quotas sob a chave `"quota"` com identificadores nominais e disponibilidade expressa em `"remaining_fraction"` (float $0.0 \dots 1.0$). O parser anterior tentava casar `"5h"` e `"used_percentage"`; ao falhar, caía em um fallback desprovido de escopo que capturava o `used_percentage` de `context_window` (atribuindo a ocupação de contexto à quota de 5h) e deixava a quota semanal estática em `[ok]`.
  2. **Interferência Multissessão / Multiterminal**: Dois ou mais terminais operando simultaneamente (ex.: um com `gemini-3.8-flash` e outro com `gemini-4-argon`) arriscavam sobrescrever ou misturar seus estados voláteis caso compartilhassem arquivos transitórios sem indexação por sessão.
  3. **Diversidade de Provedores e Modelos Especializados**: Falta de seletor inteligente para modelos Argon (que utilizam quotas dedicadas como `gemini-argon-wtu-weekly`) e modelos de terceiros 3P (Claude, GPT via `3p-5h`), além dos modelos Gemini padrão (`gemini-5h`).
  4. **Experiência Visual de Telemetria**: A exibição de telemetria necessitava de uma transição intuitiva entre a execução ativa de uma tarefa (`🚀 Feito: X%`, com incremento monotônico contínuo baseado em passos e sem saltos de 0 para 100) e o estado idle final (`🧠 Context: X%`).
  5. **Latência Sub-50ms e Cache com Fallback Assíncrono**: Em eventuais invocações onde o payload STDIN venha temporariamente sem o bloco `"quota"`, chamadas diretas de recuperação (`agy -p /usage`) poderiam bloquear a renderização síncrona do prompt, violando o teto mandatório de 50ms.
  6. **Acoplamento a Caminhos Locais**: O arquivo `README.md` continha referências fixas à máquina de desenvolvimento do autor (`/home/vitor/Projetos/03-pessoal/my-agents`), gerando atritos para novos usuários e esteiras externas.

* **Solução Adotada**:
  1. **Isolamento Estrito por Sessão / Terminal via STDIN**:
     - Cada invocação da statusline é desacoplada e consome o payload JSON via STDIN específico daquele terminal.
     - As métricas voláteis (modelo ativo, progresso de execução e ocupação de contexto) são extraídas exclusivamente do payload recebido (indexado por `session_id`), garantindo isolamento total entre múltiplos terminais abertos simultaneamente.
  2. **Seletor Inteligente de Quota Polimórfico por Modelo**:
     - **Modelos Argon** (ex.: `gemini-4-argon`): Exibição de `⚡ Argon: [XX%]`, priorizando o bucket de cota Argon correspondente (ex.: `gemini-argon-wtu-weekly`).
     - **Modelos 3P** (`claude`, `gpt`): Exibição de `⚡ 3P 5h: [XX%]`, extraindo de `3p-5h`.
     - **Modelos Gemini Regulares** (`gemini-3.8-flash`, `gemini-3.8-pro`): Exibição de `⚡ Quota 5h: [XX%]`, extraindo de `gemini-5h`.
     - **Indicador Semanal Global**: Exibição complementar de `📅 Semanal: [XX%]`, extraindo de `gemini-weekly` ou `3p-weekly`.
     - **Normalização Numérica e Semáforo ANSI**: Isolamento de locale (`LC_ALL=C LC_NUMERIC=C`) e mapeamento semântico de quota restante: $\ge 50\%$ Verde, $20-49\%$ Amarelo, e $< 20\%$ Vermelho.
  3. **Transição de Telemetria Volátil ('Feito: X%' vs 'Context: X%')**:
     - Durante a execução de uma tarefa (quando o estado do agente for `working`, `busy`, `running`, `in_progress` ou houver tasks ativas `[/]`): exibição de `🚀 Feito: X%`, iniciando em 0% e progredindo monotonicamente ao longo da execução.
     - Ao concluir a tarefa (100% ou retorno ao estado `idle`/entrega da resposta final): alternância imediata e automática para o modo de contexto: `🧠 Context: X%`.
  4. **Cache Resiliente de Quotas e Fallback Assíncrono (`/usage`)**:
     - O bloco de quotas recebido via STDIN atualiza atomicamente o cache local em `/tmp/antigravity_quota_cache.json` com lockfile seguro (`flock` / `mkdir.lock`) e timestamp.
     - Caso o payload venha desprovido de quotas e o cache local esteja expirado ou ausente, a statusline exibe graciosamente o estado em cache ou `[ok]` e dispara uma atualização em segundo plano (background assíncrono desacoplado via `agy -p /usage`), preservando incondicionalmente a latência média da statusline abaixo de 50ms.
  5. **Portabilidade Universal da Documentação e Prévia Visual**:
     - Elevação da instalação remota oficial via GitHub (`agy plugin install https://github.com/VitorJacom/my-agents.git`) a método principal recomendado na Opção 1 do `README.md`.
     - Padronização de comandos portáveis de invocação dos scripts utilitários (`install-statusline.sh`, `sync-project-context.py`, `statusline-quota.sh`) com caminhos canônicos no home do usuário (`~/.gemini/config/plugins/my-agents/scripts/...`) e relativos de workspace.
     - Inclusão de prévia visual estilizada em arte ASCII/ANSI no `README.md` demonstrando a ergonomia e estados da statusline.

---

### Decisão 0013 (2026-11-06): Modernização do Ciclo de Vida de Issues: Épicos Temáticos via Milestones, Releases no Project v2 e Sub-issues Hierárquicas
* **Status**: Aprovada
* **Contexto**: A governança anterior associava Milestones do GitHub diretamente a versões semânticas com datas rígidas (`v1.0.0`, `v1.1.0`), gerando rigidez no planejamento de longo prazo, dificultando o agrupamento temático de grandes frentes arquiteturais e impedindo uma taxonomia hierárquica nativa entre épicos e tarefas fatiadas. Além disso, o refinamento de tarefas preexistentes frequentemente duplicava issues em vez de reorganizar o backlog existente.
* **Solução Adotada**:
  1. **Milestones como Épicos Temáticos Canônicos**:
     - Milestones passam a representar grandes Épicos (ex.: `"Epic: AIDD Core & Engineering Governance"`, `"Epic: UI/UX Design System & Living Mockups"`, `"Epic: Wiki & Living Documentation"`) em vez de janelas de release temporal fixas.
     - Suporte canônico em `PROJECT_CONTEXT.md` sob a chave `Active Epic (Milestone)` com retrocompatibilidade resiliente para a chave legada `Active Milestone`.
  2. **Ciclo de Versões Desacoplado via Campo Release no GitHub Project v2**:
     - Versionamento semântico (`v1.0.0`, `v1.1.0`, `v1.2.0`, `Backlog / Future`) gerenciado pelo campo customizado Single-Select `Release` no GitHub Project v2 (`Project Number: 1`).
     - Integração determinística e não-bloqueante via CLI oficial (`gh project item-edit <number> --owner <owner> --url <issue_url> --field "Release" --value "<release>"`).
  3. **Sub-issues Nativas com `--parent`**:
     - Suporte nativo nas skills `/plan-feature` para vinculação hierárquica de sub-tarefas a issues mãe ou Épicos via `gh issue create --parent <parent_id>`.
     - Degradação graciosa com checklist de rastreamento no corpo do épico caso a flag não seja aplicável.
  4. **Refinamento In-place e Reorganização do Backlog**:
     - Diretriz e automação em `/plan-feature` e `rules/AGENTS.md` para priorizar a atualização in-place de issues existentes via `gh issue edit`, eliminando a criação de tickets redundantes ou duplicatas.
  5. **Scripts Utilitários de Migração e Reconciliação**:
     - Scripts de apoio `scripts/migrations/reclassify-epics-and-releases.py` e `scripts/migrations/migrate-issues-to-project.sh` para classificação retrospectiva e integridade do backlog.
     - Atualização do `scripts/pipeline/reconcile-github-governance.sh` para manter coerência contínua entre issues abertas, épicos e releases.

---

### Decisão 0014 (2026-11-09): Incorporação do Modelo Elephant-Goldfish no Ciclo AIDD
* **Status**: Aprovada
* **Contexto**:
  - Em esteiras de desenvolvimento orientadas por IA, longas sessões de refinamento sofrem frequentemente com *context collapse*, perda gradual de restrições de negócio e acúmulo de ruído conversacional (*conversational slop*).
  - Além disso, o agente de planejamento tende ao viés de confirmação (*confirmation bias*): assume que especificações vagas ou incompletas "obviamente funcionarão", transferindo premissas implícitas não testadas e quebras de atomicidade para a fase de codificação.
* **Solução Adotada (Modelo Elephant-Goldfish)**:
  1. **The Elephant (Product Owner - Long-Horizon Context)**:
     - O PO assume o papel de "The Elephant", detentor do contexto de longo alcance, visão holística e retenção de contexto cumulativo sem escrita prematura de código.
     - Pratica a postura socrática na engenharia de requisitos, desafiando premissas e antecipando edge cases antes de consolidar especificações funcionais autocontidas que passam no teste do olhar frio.
  2. **The Goldfish (Gatekeeper Modo 1 - Cold Audit Stateless)**:
     - O Gatekeeper opera em Modo 1 como "The Goldfish Reviewer": um auditor sem memória prévia (stateless) que avalia a especificação sob o teste do olhar frio (*Cold Audit*).
     - Bloqueio determinístico de premissas implícitas não testadas ("obviamente", "supõe-se", "presume-se", "deve funcionar") e quebras de atomicidade (> 3 passos por issue).
  3. **Loop de Auto-Healing de Especificação com Circuit Breaker**:
     - Caso o Goldfish rejeite a especificação (`SPEC_AUDIT: REJECTED`), Arquiteto e PO realizam a auto-reparação pontual com teto determinístico de **2 iterações**.
     - Se o alinhamento não for obtido após 2 iterações, ativa-se o Circuit Breaker determinístico, interrompendo a esteira e prevenindo degradação de contexto (*context collapse*), conversational slop e loops infinitos.
* **Consequências**:
  - Elimina conversational slop e premissas implícitas antes que cheguem ao código ou aos testes TDD.
  - Mitiga viés de confirmação e context collapse com rigor formal de especificação.
  - Garante issues atômicas (<= 3 passos) com critérios verificáveis prontos para execução autônoma.

---

### Decisão 0015 (2026-11-09): Promoção Interativa de Testes de Regras de Negócio para `tests/core/` e Modernização da Golden Rule Anti-Fraude
* **Status**: Aprovada
* **Contexto**:
  - No ecossistema AIDD, `tests/core/` atua como a base imutável e protegida de testes invariantes, enquanto `tests/features/` recebe os novos testes criados pelos agentes durante cada ciclo de desenvolvimento.
  - Testes que comprovam regras de negócio fundamentais permaneciam indefinidamente em `tests/features/`, deixando-os suscetíveis a afrouxamento ou adulteração por agentes em sprints subsequentes.
  - Ao mesmo tempo, a implementação histórica da Golden Rule Anti-Fraude (`git diff --name-only ... | grep -E '^tests/core/'`) tratava qualquer alteração no diretório `tests/core/` como fraude, bloqueando indiscriminadamente qualquer tentativa de adicionar novos testes aprovados à base protegida.
* **Solução Adotada**:
  1. **Duplo Portão Interativo Human-in-the-Loop**:
     - *Portão 1 (Descoberta & Planejamento / `/plan-feature`)*: Identificação explícita das regras de negócio concretas extraídas dos requisitos. O agente não pergunta no vácuo se haverá uma regra core; ele indica especificamente qual é a regra identificada (ex.: *"A regra '[Descrição Concreta da Regra]' é uma regra Core?"*) e consulta o desenvolvedor humano via `ask_question`. Se for classificada como regra core invariante (`CORE_RULE: true`), os testes de aceitação correspondentes são registrados formalmente no plano como candidatos à promoção para `tests/core/`.
     - *Portão 2 (Handoff & Gatekeeping / `/run-issue`)*: Ao concluir o loop de implementação (`GREEN >= 85%`), o `gatekeeper` inspeciona os testes criados em `tests/features/` e consulta interativamente o desenvolvedor humano (`ask_question`), discriminando os testes específicos para autorizar a promoção dos arquivos selecionados para `tests/core/`.
  2. **Utilitário Desacoplado `scripts/pipeline/promote-core-test.sh`**:
     - Ferramenta de linha de comando idempotente e independente para gerenciar a promoção segura de testes.
     - Suporta listagem de candidatos (`--list-candidates`), modo de simulação (`--dry-run`), migração segura com preservação de histórico, execução de suíte de integridade pós-promoção (`./tests/run.sh --core`) e rollback imediato caso os testes falhem no novo diretório.
  3. **Modernização da Golden Rule Anti-Fraude (`--diff-filter=MD`)**:
     - A Golden Rule passa a segregar estritamente adulterações ilícitas de adições legítimas promovidas:
       - *Adulteração / Fraude*: Qualquer alteração (`M`) ou deleção (`D`) em testes preexistentes de `tests/core/` em relação à branch base aciona o Circuit-Breaker determinístico com erro fatal (`git diff --diff-filter=MD --name-only "$BASE_BRANCH...HEAD" | grep -E '^tests/core/'`).
       - *Adição Legítima Auditada*: Novos arquivos adicionados (`A`) em `tests/core/` são autorizados e auditados, exigindo que a suíte `tests/core/` execute com 100% de sucesso e que a evidência conste no `walkthrough.md`.
  4. **Documentação Viva e Atualização da Wiki**:
     - Sincronização conceitual imediata das regras em `rules/AGENTS.md`, personas de subagentes (`gatekeeper`, `product-owner`, `planner`, `system-architect`) e páginas canônicas da Wiki (`docs/AIDD-Manifesto.md`, `docs/System-Architecture.md`, `docs/Subagents.md`).

---

### Decisão 0016 (2026-11-09): Mecanismo Desacoplado de Atualização de Plugins e Notificação Zero-Noise na Statusline
* **Status**: Aprovada
* **Contexto**:
  - Usuários do plugin `my-agents` operando via Antigravity CLI não recebiam avisos quando novas versões, correções ou melhorias eram lançadas no repositório GitHub upstream.
  - Realizar checagens de rede síncronas na statusline violaria a invariante de latência sub-50ms (SLA estrito), travando a interatividade do prompt caso a rede ficasse lenta ou instável.
  - Atualizações precipitadas ou forçadas arriscavam sobrescrever ou corromper alterações locais em branches de desenvolvimento ou working trees com arquivos modificados.
* **Solução Adotada**:
  1. **Arquitetura Assíncrona de Verificação com Cache Local e TTL**:
     - O utilitário `scripts/pipeline/update-plugin.sh` encapsula a inspeção de versões remotas (`git ls-remote --tags origin`) e persiste os metadados em cache estruturado (`~/.cache/antigravity/my-agents-update.json`) com TTL configurável (padrão de 24 horas).
     - Escrita atômica protegida por lock para evitar concorrência em múltiplos terminais abertos simultaneamente.
  2. **Widget Zero-Noise na Statusline Modular (`widget_update`)**:
     - O renderizador `scripts/statusline/statusline-quota.sh` consulta exclusivamente o cache local em disco (I/O < 5ms).
     - Se o plugin estiver na versão mais recente (`update_available: false` ou cache ausente), o widget retorna string vazia sem renderizar espaços ou separadores `│` órfãos (Invariante Zero-Noise / Estado A).
     - Se houver versão mais recente (`update_available: true`), o widget é ativado no slot à extrema direita em âmbar bold (`\033[1;33m` ou `\033[38;5;214m`), assegurando WCAG AA $\ge$ 4.5:1 e Value Contrast $\ge$ 2:1 sem uso de vermelho (Estado B).
     - Caso o cache expire durante o uso, a statusline dispara a verificação em segundo plano desanexado (`&`), garantindo que o tempo de resposta síncrono permaneça estritamente abaixo de 50ms.
  3. **Mecanismo de Atualização Seguro e Fail-Safe (`update-plugin.sh`)**:
     - Subcomandos e flags formais: `--check` (inspeção não bloqueante), `--status` (detalhamento de versões e TTL), `--apply` (aplicação segura) e `--auto` (atualização automática opt-in).
     - *Dirty Working Tree Fail-Safe*: Inspeção prévia de `git status --porcelain` antes do pull/checkout. Existindo alterações não comitadas, o processo é abortado com instruções claras de segurança.
     - Suporte a variável de ambiente `MY_AGENTS_AUTO_UPDATE=1` para automação desassistida com confirmação explícita.
  4. **Documentação Viva e Sincronizada na Wiki**:
     - Atualização dos guias de introdução (`docs/Getting-Started.md`, `README.md`), guia de solução de problemas (`docs/Troubleshooting.md`) e topologia técnica (`docs/System-Architecture.md`) com verificação determinística de ausência de dead links via suíte de testes.

---

### Decisão 0017 (2026-11-09): Auditor Automatizado de Eficiência de Tokens e Telemetria da Esteira AIDD
* **Status**: Aprovada
* **Contexto**:
  - A execução de múltiplos subagentes (Product Owner, Architect, Planner, QA, Coder, Gatekeeper) consome tokens em diferentes fases e operações de ferramentas (tool calls).
  - Sem uma auditoria estruturada e contínua dos transcripts de execução (`transcript.jsonl`), anomalias como *cache miss* sistemático, leituras redundantes de arquivos e picos excessivos de tokens em etapas individuais passavam despercebidas, desafiando os princípios de *Zero Token Waste* e *Resultado sobre Volume* do Manifesto AIDD.
* **Solução Adotada**:
  1. **Utilitário Canônico `scripts/pipeline/audit-token-efficiency.py` e Wrapper `scripts/audit-token-efficiency.py`**:
     - Analisador determinístico que processa transcripts individuais (`--transcript`), fluxos contínuos (`--stdin`) ou matrizes de subagentes da esteira (`--agents` com `--brain-dir`).
     - Mapeia o consumo de tokens discriminado por agente, por fase canônica (Planning, QA, Coding, Gatekeeper) e por operação de ferramenta (`read_file`, `write_file`, `run_command`, etc.).
  2. **Identificação de Hotspots e Anomalias de Cache**:
     - Detecção de etapas com spikes de tokens ($\ge$ 50.000 tokens de entrada).
     - Identificação de anomalias de cache miss (taxa de cache $< 50\%$ ou quedas bruscas entre steps consecutivos).
     - Alerta de operações redundantes de ferramentas (ex.: leitura repetida do mesmo arquivo $> 2$ vezes).
  3. **Score Determinístico de Eficiência (0-100) e Quality Gate**:
     - Base de 100 pontos com deduções calibradas para cache miss, hotspots e operações redundantes, classificando em faixas (Classe A: $\ge 90$, Classe B: $\ge 75$, Classe C: $\ge 50$, Classe D/F: $< 50$).
     - Diagnósticos objetivos de acertos e falhas com recomendações acionáveis de engenharia de prompt.
     - Suporte a flag fail-fast `--min-score <N>` para validação automatizada em pipelines de CI/CD.
  4. **Multi-Formato de Renderização**:
     - Formato Terminal com cores ANSI, formato Markdown estruturado para PRs e formato JSON padronizado para integração programática.

---

### Decisão 0018 (2026-11-09): Ciclo de Vida Reativo, Inicialização Idempotente e Reconciliação Contínua de Status no GitHub Projects v2
* **Status**: Aprovada
* **Contexto**:
  - No ecossistema AIDD, o gerenciamento de issues e o acompanhamento visual do progresso de engenharia dependem do GitHub Projects v2 (Kanban Board / View 2).
  - Anteriormente, a criação ou transição de issues pelo CLI (`gh issue create`) ou durante o fatiamento de épicos não garantia a inicialização imediata do campo de status, gerando o problema crônico de cartões órfãos na coluna *"No Status"* do Kanban.
  - Além disso, a evolução do ciclo de vida das issues durante o desenvolvimento (do planejamento e confinamento em worktrees até a abertura de Pull Requests e merge/fechamento) dependia de intervenções manuais ou ficava assíncrona em relação ao quadro do projeto, sem reatividade a eventos nativos do GitHub.
  - Havia a necessidade de consolidar uma arquitetura de sincronização resiliente que operasse tanto localmente via CLI nos subagentes (com degradação graciosa caso o token não possua privilégios em Projects v2) quanto remotamente no CI/CD via GitHub Actions com tratamento estrito de concorrência e fail-fast.
* **Solução Adotada**:
  1. **Taxonomia Canônica Unificada de Status (Planned, In Progress, In Review, Done)**:
     - Mapeamento determinístico dos quatro estados canônicos do ciclo de vida AIDD para as colunas do Kanban View 2:
       - `Planned`: Issue recém-criada, reaberta ou refinada no backlog, aguardando alocação e despacho de desenvolvimento.
       - `In Progress`: Desenvolvimento ativo iniciado por subagentes (fase de planejamento, TDD em fork concorrente QA/Coder ou worker confinado em worktree isolada).
       - `In Review`: Pull Request aberto e pronto para inspeção (estado pronto para auditoria/gatekeeping, excluindo rascunhos / *drafts*).
       - `Done`: Issue resolvida e fechada, ou Pull Request integrado/mergeado com sucesso.
     - Normalização inteligente e tolerante a sinônimos no sincronizador (mapeando termos comuns como `todo`, `doing`, `wip`, `review` e `completed` diretamente para os 4 valores canônicos).
  2. **Auto-Inclusão Idempotente e Transição Resiliente (`scripts/pipeline/project-status-sync.sh`)**:
     - Utilitário desacoplado de CLI que garante a auto-inclusão prévia da issue no Project v2 (`gh project item-add`) caso ela ainda não conste no quadro, prevenindo erros de item inexistente antes de aplicar a alteração de status (`gh project item-edit`).
     - Resolução resiliente de metadados internos de schema (Project ID, Status Field ID e Option ID) via queries GraphQL e CLI, suportando nomes parametrizados de campos definidos em `PROJECT_CONTEXT.md` (fallback para `"Status"`).
     - *Degradação Graciosa (Non-Blocking)*: Falhas decorrentes de falta de escopo no token (`project`), permissões insuficientes ou falha transitória de rede emitem avisos explicativos (`⚠️ [WARN]`) sem abortar o processo com erro fatal, preservando a continuidade operacional dos subagentes locais.
  3. **Reconciliação Idempotente de Backlog e Encerramento (`scripts/pipeline/reconcile-github-governance.sh`)**:
     - Utilitário central de governança e backfill idempotente, executado pós-planejamento em lote (`/plan-feature`) ou em auditorias periódicas.
     - Inicialização preventiva: atribui automaticamente o status inicial `Planned` a todas as issues abertas sem status, erradicando cartões na coluna *"No Status"*.
     - Preservação estrita de estado: issues abertas que já possuam qualquer status atribuído (`In Progress`, `In Review`, etc.) não têm seus valores sobrescritos.
     - Suporte ao ciclo de encerramento (`--include-closed`): varre issues fechadas e transita seu status no Project v2 deterministicamente para `Done`.
     - Suporte a `--dry-run` para auditoria e pré-visualização segura de mutações sem escrita na API do GitHub.
  4. **Reatividade Orientada a Eventos no CI/CD (`.github/workflows/project-v2-automation.yml`)**:
     - Workflow automatizado de GitHub Actions engatilhado reativamente por eventos de repositório:
       - `issues: [opened, reopened, closed]`: Inclusão e transição imediata (`opened/reopened` $\rightarrow$ `Planned`; `closed` $\rightarrow$ `Done`).
       - `pull_request: [opened, reopened, ready_for_review, closed]`: Transição automática (`opened/reopened/ready_for_review` $\rightarrow$ `In Review`, ignorando PRs marcados como draft; `closed` $\rightarrow$ `Done`).
       - `workflow_dispatch`: Disparo manual sob demanda invocando a reconciliação completa via `reconcile-github-governance.sh`.
     - Controle estrito de concorrência por issue/PR (`concurrency: group: project-v2-sync-...`, `cancel-in-progress: false`), prevenindo *race conditions* e execuções conflitantes.
     - Condução com tolerância zero a falsos positivos: execução sob `set -euo pipefail` e diagnósticos com anotações de log do GitHub Actions (`::error::` e `::warning::`).
* **Consequências Técnicas**:
  - Elimina completamente o problema de cartões órfãos ("No Status") no Kanban View 2 do GitHub Projects v2.
  - Visibilidade em tempo real do estado real de engenharia para observadores e stakeholders, sem necessidade de sincronização manual.
  - Desacoplamento entre execução local e automação remota: scripts locais e workflows de CI compartilham a mesma taxonomia e regras idempotentes.
  - Degradação graciosa no ambiente local evita que desenvolvedores e agentes sem tokens com escopo de escrita em projetos corporativos tenham seu fluxo de código bloqueado.

