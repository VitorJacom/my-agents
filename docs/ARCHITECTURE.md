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
└── docs/                     # Documentação viva do sistema
    └── ARCHITECTURE.md       # Fonte única da verdade (este documento)
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

### Decisão 0004 (2026-11-04): Isolamento de Ambientes de Agentes Concorrentes via Git Worktree
* **Status**: Proposta
* **Contexto**: A execução simultânea de múltiplas issues por agentes geraria colisões de estado e arquivos efêmeros sobrepostos no mesmo repositório local de trabalho.
* **Solução Adotada**:
  1. **Worktrees Efêmeros**: Cada tarefa em execução recebe um diretório estéril e dedicado em `.worktrees/issue-<id>`, criado a partir da branch base atualizada (`origin/main`), mantendo a raiz limpa.
  2. **Mecanismo Anti-Colisão (Locks)**: Arquivos de trava atômica `.worktrees/.lock-<id>` asseguram que nenhuma issue seja processada em duplicidade.
  3. **Ciclo de Vida Determinístico**: Script utilitário (`scripts/worktree-manager.sh`) gerencia `create`, `list`, `check-sync` e `remove`, garantindo a remoção do worktree após a abertura do PR pelo Gatekeeper.

---

### Decisão 0005 (2026-11-04): Paralelismo Intra-Task Baseado em Contrato Congelado (QA & Coder)
* **Status**: Proposta
* **Contexto**: A esteira `/run-issue` operava estritamente em série (Planner ➔ QA RED ➔ Coder GREEN), criando gargalo temporal onde o Coder aguardava passivamente a escrita dos testes.
* **Solução Adotada**:
  1. **Interface Contract Inviolável**: O `implementation_plan.md` passa a conter obrigatoriamente a seção `## Interface Contract`, com tipagens, assinaturas de funções e contratos de dados 100% congelados na etapa de Planejamento.
  2. **Fork Concorrente**: QA Engineer (em `tests/features/`) e Coder (em `src/`) são disparados simultaneamente, ambos trabalhando de forma independente orientados exclusivamente pelo contrato.
  3. **Portão de Sincronização (Join Point)**: O orquestrador executa a suíte ao término de ambas as entregas. Se os testes passarem imediatamente, segue para o Gatekeeper; se houver desalinhamento, inicia-se um loop curto de refinamento (máx 2 iterações) para convergência.
