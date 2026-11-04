# Plugin `my-agents` 🚀

Repositório central de padrões de engenharia, governança, segurança e automações para agentes de inteligência artificial (Antigravity CLI / Gemini CLI).

---

## 📦 O que este Plugin inclui

### 1. 📋 Diretrizes Centrais & Manifesto AIDD (`rules/AGENTS.md`)
Regras sempre ativas para o agente durante todo o ciclo de desenvolvimento:
- **Os 4 Valores do Manifesto AIDD**: *Method over Model*, *Ownership over Delegation*, *Understanding over Acceptance* e *Outcome over Output*.
- **O Triângulo Canônico de Arquivos**: `task.md` (com regra de semáforo rígida: apenas UMA tarefa em `[/]` por vez), `implementation_plan.md` (contrato prévio obrigatório) e `walkthrough.md` (relatório de provas determinísticas com exigência de prova visual condicional para interfaces gráficas e UIs).
- **A Trava Dupla Anti-Fraude**: Separação física de pastas (`tests/core/` intocável vs `tests/features/` para novas features) + a *Golden Rule* em bash executada no Gatekeeper/CI.
- **Mutation Testing (Anti-Testes Falsos)**: Reprovação imediata de testes tautológicos ou vazios.
- **Comunicação Híbrida**: Relatórios e interação em Português; código, commits e docstrings em Inglês.
- **Anti-Token Waste**: Busca cirúrgica, leitura paginada e persistência de contexto sem ler o disco inteiro.
- **Blindagem Anti-Alucinação (Duplo Gate)**: Proibição de suposições ou invenção de estruturas fora do `PROJECT_CONTEXT.md` (Gate 1) + auditoria de conformidade no Gatekeeper (Gate 2).

### 2. 🛡️ Guardrails de Segurança & Persistência de Contexto (`hooks.json`)
- **`safety-guard` (`PreToolUse`)**: Intercepta `run_command` e bloqueia comandos destrutivos sistêmicos (`rm -rf /`, `mkfs`) e tentativas de exibir chaves privadas SSH (`id_rsa`, etc.).
- **`context-loader` (`SessionStart`)**: Injeta automaticamente o resumo do `PROJECT_CONTEXT.md` ao iniciar qualquer novo chat, garantindo zero desperdício de tokens.

### 3. 🤖 Esteiras Especializadas de Subagentes (`agents/`)
Subagentes com papéis estritos, travas anti-fraude e isolamento físico de processos:
- **Planejamento de Produto & Arquitetura**:
  - **`product-owner`**: Engenharia de requisitos, personas e critérios Gherkin/Checklist.
  - **`system-architect`**: Mapeamento de impacto em `src/`, ADRs em `docs/adr/` e garantia de atomicidade (<= 3 passos).
- **Design de Interface & Experiência do Usuário**:
  - **`uiux-designer`**: Hierarquia visual, ergonomia, contraste de luminância monocromático (Value Contrast / WCAG), affordance, prova visual headless e *game feel / juiciness*.
- **Execução Técnica TDD**:
  - **`planner`**: Arquiteto e triagem de requisitos (somente leitura; rejeita escopos com > 3 passos).
  - **`qa-engineer`**: Engenheiro de testes TDD (cria testes de aceite em `tests/features/` e valida estado RED).
  - **`coder`**: Construtor de software (escrita restrita a `src/`; zero permissão de alterar testes; loop máximo de 3 tentativas).
  - **`gatekeeper`**: Auditor de integridade (executa a Golden Rule em bash, audita `git diff` contra fraudes, compila `walkthrough.md` e abre PR no GitHub).

### 4. 🧠 Skills Especializadas (`skills/`)
Procedimentos acionados sob demanda pelo agente ou pelo desenvolvedor:
- **`plan-feature`** (`/plan-feature <ideia_ou_issue>`): Esteira de planejamento no GitHub (PO ➔ Arquiteto ➔ Gate de Aprovação ➔ Issues no GitHub).
- **`issue-pipeline`** (`/run-issue <numero_ou_url>`): Orquestra o ciclo técnico completo de TDD (Planner ➔ QA ➔ Coder ➔ Gatekeeper ➔ PR).
- **`publish-rule-issue`** (`/publish-rule-issue`): Publica aprendizados do `/learn` diretamente como Issue no repositório `VitorJacom/my-agents`.
- **`game-dev-patterns`**: Engenharia e física para jogos 2D (fixed timestep, independência de FPS, debounce de overlap e alcance cinemático).
- **`git-workflow`**: Criação de branches semânticas, commits Conventional Commits e templates de PR.
- **`code-review`**: Análise estática, segurança (OWASP), arquitetura e refatoração com relatório de severidade.
- **`test-runner`**: Deteção automática do framework de testes e execução cirúrgica com diagnóstico de causas-raiz.
- **`docker-dev`**: Resolução de problemas com containers, compose, logs e boas práticas de Dockerfile.
- **`architecture-decision`**: Elaboração padronizada de registros de arquitetura (ADRs).

---

## 🛠️ Como Inserir e Utilizar o Plugin em Outros Projetos

Você pode habilitar o plugin nos seus outros projetos de **três maneiras**, dependendo da sua preferência de escopo:

---

### Opção 1: Instalação Global na Máquina (Recomendada)
Esta é a forma mais prática: o plugin fica ativo para **todos** os repositórios e projetos que você abrir no Antigravity CLI.

Execute uma única vez no terminal:

```bash
# A partir do caminho local
agy plugin install /home/vitor/Projetos/03-pessoal/my-agents

# Ou diretamente do repositório remoto do GitHub
agy plugin install https://github.com/VitorJacom/my-agents.git
```

> [!TIP]
> **Como verificar se está ativo:**
> Rode `agy plugin list`. O `my-agents` deve aparecer com status `(enabled)`.

---

### Opção 2: Ativação Declarada por Projeto via `plugins.json`
Se você deseja controlar explicitamente quais projetos utilizam o plugin sem instalar tudo de forma global, adicione a configuração no projeto de destino:

No seu projeto alvo (ex.: `meu-app/`):
1. Crie ou edite o arquivo `.agents/plugins.json`:
```json
{
  "plugins": [
    "/home/vitor/Projetos/03-pessoal/my-agents"
  ]
}
```

2. O Antigravity carregará automaticamente todas as regras, skills, hooks e subagentes sempre que esse workspace estiver aberto.

---

### Opção 3: Git Submodule no Workspace (Para Times e CI/CD)
Se você compartilha o projeto com outros desenvolvedores ou executa em esteiras de CI/CD, vincule o plugin como submódulo Git dentro da pasta de plugins do workspace:

```bash
# Na raiz do seu projeto de destino:
mkdir -p .agents/plugins
git submodule add https://github.com/VitorJacom/my-agents.git .agents/plugins/my-agents
```

O Antigravity detecta automaticamente plugins localizados em `.agents/plugins/<nome_do_plugin>`.

---

## 📋 Preparando o Projeto de Destino: `PROJECT_CONTEXT.md`

Para que o novo projeto usufrua da **Persistência de Contexto Econômica** e da **Blindagem Anti-Alucinação (Duplo Gate)**:

1. Execute o script sincronizador apontando para a raiz do seu projeto:
   ```bash
   /home/vitor/Projetos/03-pessoal/my-agents/scripts/sync-project-context.py /caminho/do/meu-projeto
   ```
   Isso criará o arquivo canônico `PROJECT_CONTEXT.md` na raiz do seu projeto com o template oficial.

2. Ajuste as seções `## 🛠️ Stack Tecnológica` e `## 📂 Estrutura Canônica de Diretórios` para refletir a arquitetura daquele projeto.

---

## 🚀 Comandos Rápidos nos Seus Projetos

Uma vez ativo no seu projeto, você tem acesso aos seguintes comandos no chat do Antigravity:

- **Executar uma Issue do GitHub na esteira TDD determinística**:
  ```text
  /run-issue #42
  ```
- **Publicar uma regra aprendida via `/learn` de volta para o repo central**:
  ```text
  /publish-rule-issue
  ```
- **Auditar código antes de abrir PR**:
  ```text
  /code-review
  ```
- **Criar commits e branches semânticas**:
  ```text
  /git-workflow
  ```
- **Ativar a statusline customizada com modelo e alerta de quota**:
  ```text
  /statusline /home/vitor/Projetos/03-pessoal/my-agents/scripts/statusline-quota.sh
  ```

---

## 📂 Estrutura de Arquivos

```text
my-agents/
├── plugin.json                 # Manifesto do plugin
├── README.md                   # Documentação completa
├── PROJECT_CONTEXT.md          # Contexto canônico da arquitetura
├── hooks.json                  # Registro de hooks de ciclo de vida (SessionStart, PreToolUse)
├── scripts/
│   ├── safety-guard.sh         # Validador de segurança PreToolUse
│   ├── session-start-context.sh# Injetor leve de contexto SessionStart
│   ├── sync-project-context.py # Atualizador automático do PROJECT_CONTEXT.md
│   ├── metrics-collector.py    # Coletor de telemetria e tokens por agente
│   └── statusline-quota.sh     # Renderizador customizado da statusline
├── rules/
│   └── AGENTS.md               # Diretrizes mandatórias globais e Duplo Gate
├── agents/                     # Subagentes especializados da esteira
│   ├── planner/
│   │   └── agent.md
│   ├── qa-engineer/
│   │   └── agent.md
│   ├── coder/
│   │   └── agent.md
│   └── gatekeeper/
│       └── agent.md
└── skills/
    ├── issue-pipeline/         # Orquestrador da esteira /run-issue
    ├── publish-rule-issue/     # Publicador de regras pós-learn no GitHub
    ├── git-workflow/           # Fluxo de branches, commits e PRs
    ├── code-review/            # Auditoria e refatoração de código
    ├── test-runner/            # Execução e diagnóstico de testes
    ├── docker-dev/             # Gestão de containers e Docker
    └── architecture-decision/  # Documentação de ADRs
```
