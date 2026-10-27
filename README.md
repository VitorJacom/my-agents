# Plugin `my-agents` 🚀

Repositório central de padrões de engenharia, governança, segurança e automações para agentes de inteligência artificial (Antigravity CLI / Gemini CLI).

---

## 📦 O que este Plugin inclui

### 1. 📋 Diretrizes Centrais (`rules/AGENTS.md`)
Regras sempre ativas para o agente durante todo o ciclo de desenvolvimento:
- **Comunicação Híbrida**: Relatórios, explicações e interação com o usuário em Português; código, commits e identificadores em Inglês.
- **Git Flow & Conventional Commits**: Padrão de commits semânticos (`feat`, `fix`, `refactor`, `test`, etc.) e nomenclatura de branches.
- **TDD & Testes Obrigatórios**: Nenhuma entrega sem testes automatizados que cubram tanto o caminho feliz quanto casos de borda.
- **Clean Architecture & SOLID**: Código desacoplado, sem complexidade ciclomática desnecessária e tratamento explícito de erros.
- **Segurança**: Proibição de exposição de secrets, credenciais ou arquivos `.env`.

### 2. 🛡️ Guardrails de Segurança (`hooks.json` + `scripts/safety-guard.sh`)
- Hook `PreToolUse` bloqueante para interceptar comandos com potencial destrutivo (ex: `rm -rf /`) ou tentativas de leitura inadvertida de credenciais/chaves privadas SSH.

### 3. 🤖 Esteira Multiagente Determinística (`agents/`)
Subagentes com papéis estritos e travas anti-fraude:
- **`planner`**: Arquiteto e triagem de requisitos (somente leitura; rejeita escopos com > 3 passos).
- **`qa-engineer`**: Engenheiro de testes TDD (cria testes de aceite em `tests/features/` e valida estado RED).
- **`coder`**: Construtor de software (escrita restrita a `src/`; zero permissão de alterar testes; loop máximo de 3 tentativas).
- **`gatekeeper`**: Auditor de integridade (audita `git diff` contra fraudes, compila `walkthrough.md` e abre PR no GitHub).

### 4. 🧠 Skills Especializadas (`skills/`)
Procedimentos acionados sob demanda pelo agente ou pelo desenvolvedor:
- **`issue-pipeline`** (`/run-issue <numero_ou_url>`): Orquestra o ciclo completo ponta a ponta (Planner ➔ QA ➔ Coder ➔ Gatekeeper ➔ PR).
- **`git-workflow`**: Criação de branches semânticas, commits Conventional Commits e templates de PR.
- **`code-review`**: Análise estática, segurança (OWASP), arquitetura e refatoração com relatório de severidade.
- **`test-runner`**: Deteção automática do framework de testes e execução cirúrgica com diagnóstico de causas-raiz.
- **`docker-dev`**: Resolução de problemas com containers, compose, logs e boas práticas de Dockerfile.
- **`architecture-decision`**: Elaboração padronizada de registros de arquitetura (ADRs).

---

## 🛠️ Como Instalar e Utilizar

### Instalação via CLI (`agy plugin`)
Você pode instalar este plugin globalmente ou no seu projeto usando a CLI do Antigravity:

```bash
# A partir do caminho local
agy plugin install /home/vitor/Projetos/03-pessoal/my-agents

# Ou diretamente do repositório Git (quando publicado)
agy plugin install https://github.com/vitor/my-agents.git
```

### Executando a Esteira de Issues
No chat ou terminal do Antigravity no projeto onde o plugin estiver ativo:
```text
/run-issue #12
```

---

## 📂 Estrutura de Arquivos

```text
my-agents/
├── plugin.json                 # Manifesto do plugin
├── README.md                   # Documentação do plugin
├── hooks.json                  # Registro de hooks de ciclo de vida
├── scripts/
│   └── safety-guard.sh         # Validador de segurança PreToolUse
├── rules/
│   └── AGENTS.md               # Diretrizes mandatórias de engenharia
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
    │   └── SKILL.md
    ├── git-workflow/           # Fluxo de branches, commits e PRs
    │   └── SKILL.md
    ├── code-review/            # Auditoria e refatoração de código
    │   └── SKILL.md
    ├── test-runner/            # Execução e diagnóstico de testes
    │   └── SKILL.md
    ├── docker-dev/             # Gestão de containers e Docker
    │   └── SKILL.md
    └── architecture-decision/  # Documentação de ADRs
        └── SKILL.md
```
