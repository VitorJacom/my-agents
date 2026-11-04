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
│   ├── planner/              # Triagem e plano atômico TDD (somente leitura)
│   ├── qa-engineer/          # Engenharia de testes TDD (fase RED)
│   ├── coder/                # Construção em src/ (fase GREEN)
│   └── gatekeeper/           # Auditoria anti-fraude e publicação no PR
├── skills/                   # Habilidades sob demanda (Progressive Disclosure)
│   ├── game-dev-patterns/    # Física 2D, FPS independence e cinemática
│   ├── plan-feature/         # Esteira de planejamento funcional e técnico
│   ├── issue-pipeline/       # Esteira de execução TDD automatizada
│   ├── architecture-decision/# Diretrizes de design técnico
│   └── ...                   # Outras skills especializadas
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
