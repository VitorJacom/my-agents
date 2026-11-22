Bem-vindo ao **`my-agents`**! Este guia fornece instruções passo a passo para configurar e utilizar o ecossistema de governança, personas especializadas e esteiras determinísticas do Manifesto AIDD (*AI-Driven Development*) com o **Antigravity CLI** (`agy`).

---

## 🚀 1. Visão Geral

O `my-agents` é um pacote de extensões (plugin) projetado para potencializar o desenvolvimento assistido por agentes de IA no Antigravity CLI. Ele fornece:
- **Governança AIDD**: Proteções contra falsos positivos, fraudes em testes e poluição de contexto (*Zero Token Waste*) descritas no [`AIDD-Manifesto`](AIDD-Manifesto).
- **Subagentes Confinados**: Personas com papéis bem delimitados catalogadas em [`Subagents`](Subagents).
- **Skills Sob Demanda**: Habilidades especializadas ativadas por *Progressive Disclosure* catalogadas em [`Skills-Catalog`](Skills-Catalog).
- **Statusline de Alta Performance**: Monitoramento em tempo real de quota e status do Git com latência garantida sub-50ms ([`Script-statusline`](Script-statusline)).

---

## 📋 2. Pré-requisitos

Antes de iniciar, certifique-se de possuir instalado e configurado em seu sistema:

1. **Git (>= 2.30+)**:
   ```bash
   git --version
   ```
2. **GitHub CLI (`gh`)**:
   - Necessário para que os agentes possam interagir com issues, milestones e pull requests.
   - Verifique e autentique-se:
     ```bash
     gh auth status
     # Caso não autenticado:
     gh auth login
     ```
3. **Antigravity CLI (`agy`)**:
   - O cliente de IA da Google para terminal.
   ```bash
   agy --version
   ```
4. **Ecossistema de Execução do seu Projeto**:
   - Node.js (npm/pnpm/yarn), Python (pytest), Go ou a stack tecnológica correspondente ao repositório consumidor.

---

## ⚙️ 3. Instalação e Configuração de Plugins via `plugins.json`

O Antigravity CLI descobre e carrega plugins declarados em arquivos de configuração `plugins.json`.

### 3.1. Clonando o Repositório do Plugin

Clone o repositório `my-agents` em um diretório de sua preferência (por exemplo, dentro de seus projetos pessoais ou central de plugins):

```bash
git clone https://github.com/vitor/my-agents.git ~/Projetos/my-agents
```

### 3.2. Configurando o Plugin no Projeto Consumidor (Recomendado)

Para que um projeto específico consuma as personas, regras e skills do `my-agents`, crie ou edite o arquivo `.agents/plugins.json` na raiz do seu projeto consumidor:

```bash
mkdir -p .agents
```

Crie o arquivo `.agents/plugins.json` com a declaração do caminho absoluto para o `my-agents`:

```json
{
  "entries": [
    {
      "path": "/home/seu-usuario/Projetos/my-agents"
    }
  ]
}
```

> [!TIP]
> Caminhos relativos também são suportados em `path` e resolvem em relação ao diretório onde está localizada a pasta `.agents/`.

### 3.3. Configurando o Plugin Globalmente (Opcional)

Se você preferir que o `my-agents` esteja ativo em todos os projetos abertos no seu terminal, declare a entrada no arquivo global em `~/.gemini/config/plugins.json`:

```json
{
  "entries": [
    {
      "path": "/home/seu-usuario/Projetos/my-agents"
    }
  ]
}
```

### 3.4. Validando o Carregamento

Abra uma sessão no terminal do seu projeto:

```bash
agy
```

Ao iniciar, o Antigravity registrará automaticamente os hooks, regras em `rules/AGENTS.md`, personas de subagentes e o catálogo de skills do `my-agents`.

---

## 🏛️ 4. Estrutura Canônica no Repositório Consumidor

Para tirar o máximo proveito da esteira determinística e das travas de segurança do AIDD, o repositório consumidor deve seguir a seguinte organização:

```text
meu-projeto/
├── .agents/
│   └── plugins.json          # Registro do plugin my-agents
├── PROJECT_CONTEXT.md        # Mapa de arquitetura e regras canônicas do projeto
├── .gitignore                # Proteção de arquivos transitórios
├── src/                      # Código de produção (exclusivo do Coder)
└── tests/
    ├── core/                 # Testes legados intocáveis (protegidos pela Trava Dupla)
    └── features/             # Novos testes de aceitação da issue ativa (QA Engineer)
```

### 4.1. Configuração do `.gitignore`
Os arquivos de semáforo e relatório de execução são efêmeros e **não devem** ser comitados na branch principal:

```gitignore
# Arquivos de ciclo de vida efêmero do AIDD
task.md
implementation_plan.md
walkthrough.md
```

### 4.2. O Arquivo `PROJECT_CONTEXT.md`
Crie um arquivo `PROJECT_CONTEXT.md` na raiz do seu projeto contendo:
- Stack tecnológica e versões de dependências.
- Estrutura de pastas canônicas.
- Invariantes de negócio que o agente deve respeitar sem varrer o repositório cegamente (*Zero Token Waste*).

### 4.3. Estrutura de Testes: `tests/core/` vs `tests/features/`
Para garantir a Trava Dupla Anti-Fraude do Manifesto AIDD:
- **`tests/core/`**: Guarda os testes fundamentais e regras de negócio históricas. Esta pasta é **estritamente intocável** por qualquer subagente durante a execução de issues.
- **`tests/features/`**: Destinada exclusivamente aos novos testes de critérios de aceite escritos pelo `qa-engineer` para validar o comportamento da issue ativa.

---

## 🎯 5. Executando o Primeiro Comando com Antigravity CLI (`agy`)

O Antigravity CLI pode ser utilizado tanto de modo interativo quanto através de comandos pontuais com a flag `-p`.

### Modo Interativo

```bash
cd /caminho/do/meu-projeto
agy
```

No prompt, você pode conversar com o agente e acionar slash commands como `/plan-feature` e `/issue-pipeline`.

### Modo Pontual (Headless Execution)

Para automações ou testes isolados em terminal:

```bash
agy -p "Liste as personas de subagentes disponíveis neste workspace"
```

---

## 🔄 6. O Primeiro Ciclo AIDD Passo a Passo

O fluxo padrão do ecossistema `my-agents` segue uma esteira determinística em duas fases principais ([`plan-feature`](Skill-plan-feature) e [`issue-pipeline`](Skill-issue-pipeline)):

```mermaid
flowchart TD
    Idea["💡 Ideia ou Requisito"] --> Plan["1. Planejamento Funcional e Técnico<br/>(/plan-feature)"]
    Plan --> Approval{"Aprovação Humana<br/>do Plano?"}
    Approval -- "APPROVED" --> Issues["2. Publicação de Issues<br/>Atômicas no GitHub"]
    Issues --> Run["3. Execução TDD Isolada<br/>(/issue-pipeline #ID)"]
    Run --> PR["4. Pull Request com<br/>Evidências (walkthrough.md)"]
```

### Passo 1: Planejamento com [`/plan-feature`](Skill-plan-feature)
No prompt do `agy`, digite a descrição da funcionalidade desejada:

```text
/plan-feature Sistema de autenticação JWT com rota de login e validação de token
```

O orquestrador acionará o [`product-owner`](Agent-product-owner) para definir requisitos e critérios de aceite, o [`uiux-designer`](Agent-uiux-designer) (se envolver interface) e o [`system-architect`](Agent-system-architect) para estruturar a arquitetura técnica, verificar impacto na base e fatiar a demanda em issues atômicas (com no máximo 3 passos por issue).

### Passo 2: Aprovação e Criação das Issues
Ao final do planejamento, o agente apresenta a proposta estruturada em `planning_proposal.md`. Com a sua aprovação, as issues serão criadas automaticamente no repositório GitHub com os metadados e dependências corretas.

### Passo 3: Execução Determinística com [`/issue-pipeline`](Skill-issue-pipeline)
Com a issue criada (por exemplo, `#1`), dispare a esteira de construção:

```text
/issue-pipeline #1
```

A máquina de estados executará:
1. **[`planner`](Agent-planner)**: Triagem e contrato atômico (`implementation_plan.md` e `task.md`).
2. **[`qa-engineer`](Agent-qa-engineer)** e **[`coder`](Agent-coder)** *(em paralelo sob contrato congelado)*: Criação de testes de aceitação em `tests/features/` (**RED**) e implementação cirúrgica em `src/` até atingir **GREEN** com cobertura $\ge 85\%$, mantendo [`tests/core/`](Test-core) intocado.
3. **[`gatekeeper`](Agent-gatekeeper)**: Auditoria anti-fraude (*Golden Rule*), verificação de interface gráfica se aplicável, compilação das evidências em `walkthrough.md` e criação do Pull Request no GitHub.

---

## 📊 7. Setup da Statusline de Alta Performance (Opcional)

O repositório inclui um renderizador de statusline de alta performance com latência garantida sub-50ms, exibindo consumo de quota (5 horas e semanal), status do Git e modelo ativo:

```bash
cd ~/Projetos/my-agents
bash scripts/statusline/install-statusline.sh
```

O script fará backup da sua configuração em `~/.gemini/antigravity-cli/settings.json` e ativará a statusline automaticamente. Para validar o benchmark de performance:

```bash
bash scripts/statusline/test-statusline.sh
```

---

## 🔄 8. Mecanismo de Atualização e Notificação na Statusline

O `my-agents` conta com um sistema desacoplado de gestão de versões projetado para garantir que você sempre usufrua das regras, skills e guardrails mais recentes sem interromper seu fluxo de desenvolvimento:

### 8.1. Notificação Visual Zero-Noise na Statusline
A statusline modular monitora versões em segundo plano através do widget `widget_update` (`scripts/statusline/statusline-quota.sh`), consultando um cache local indexado (`~/.cache/antigravity/my-agents-update.json`):
- **Estado A (Up to date)**: Quando o plugin estiver na versão mais recente ou o cache estiver ausente/expirado, o widget permanece **100% invisível** (Zero-Noise Invariant), sem renderizar espaços nem separadores órfãos.
- **Estado B (Update Available)**: Quando uma nova tag ou versão for detectada no repositório remoto, o widget é ativado elegantemente na extrema direita do terminal exibindo `📦 Update: vX.Y.Z` em âmbar bold, indicando que uma atualização está disponível.

### 8.2. Comandos de Gerenciamento (`update-plugin.sh`)
O utilitário `scripts/pipeline/update-plugin.sh` encapsula as operações de inspeção e aplicação:

```bash
# 1. Verificação manual não bloqueante (atualiza o cache local via git ls-remote):
./scripts/pipeline/update-plugin.sh --check

# 2. Exibição do status detalhado da versão local, remota e validade do TTL:
./scripts/pipeline/update-plugin.sh --status

# 3. Aplicação segura da atualização:
./scripts/pipeline/update-plugin.sh --apply
```

> [!IMPORTANT]
> **Dirty Working Tree Fail-Safe**: Antes de realizar checkout ou pull da nova versão, o comando `--apply` verifica se o repositório local possui alterações não comitadas (`git status --porcelain`). Se a árvore estiver suja, o processo é abortado imediatamente com instruções de segurança para evitar perda acidental de trabalho em andamento.

### 8.3. Atualização Automática Desassistida (Opt-in)
Para ambientes de desenvolvimento ou estações onde se deseja atualização contínua e transparente, você pode ativar a atualização automática exportando a variável de ambiente:

```bash
export MY_AGENTS_AUTO_UPDATE=1
```

Com esta variável ativa, quando `update-plugin.sh` for acionado ou o ciclo de verificação for concluído, o plugin atualizará automaticamente para a versão mais recente caso a working tree esteja perfeitamente limpa.

---

## 📚 9. Próximos Passos e Leituras Recomendadas

- [Catálogo de Subagentes (`docs/Subagents.md`)](./Subagents.md): Detalhamento das 7 personas, ferramentas concedidas e contratos de entrada/saída.
- [Catálogo de Skills (`docs/Skills-Catalog.md`)](./Skills-Catalog.md): Documentação completa de todas as habilidades sob demanda e gatilhos de *Progressive Disclosure*.
- [Arquitetura e Decisões Técnicas (`docs/ARCHITECTURE.md`)](https://github.com/VitorJacom/my-agents/blob/main/docs/ARCHITECTURE.md): Fonte única da verdade das decisões de engenharia do repositório.
