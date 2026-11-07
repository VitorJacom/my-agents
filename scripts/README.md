# 🛠️ Catálogo de Scripts e Utilitários (`scripts/`)

Este diretório contém os utilitários de suporte, automação de esteira AIDD, hooks do Antigravity CLI e ferramentas de telemetria e governança do ecossistema `my-agents`.

---

## 📂 Estrutura de Diretórios

```
scripts/
├── hooks/        # Scripts de ciclo de vida e eventos do Antigravity CLI (hooks.json)
├── pipeline/     # Orquestração do ciclo AIDD, governança GitHub e isolamento de worktrees
├── statusline/   # Prompt statusline em tempo real e monitoramento de quota da API
└── migrations/   # Scripts históricos de migração e reclassificação de dados
```

---

## 🪝 1. `scripts/hooks/` (Hooks de Runtime)

Scripts executados dinamicamente pelo Antigravity CLI nos pontos de interceptação declarados em `hooks.json`.

| Script | Evento (`hooks.json`) | Descrição |
|---|---|---|
| [`safety-guard.sh`](file:///home/vitor/Projetos/03-pessoal/my-agents/scripts/hooks/safety-guard.sh) | `BeforeToolExecution` | Intercepta comandos no terminal impedindo operações destrutivas não autorizadas (ex: `rm -rf /`, force push descontrolado). |
| [`session-start-context.sh`](file:///home/vitor/Projetos/03-pessoal/my-agents/scripts/hooks/session-start-context.sh) | `SessionStart` | Injeta o estado volátil do Git dinamicamente no início da sessão do agente, garantindo contexto atualizado sem poluir `PROJECT_CONTEXT.md`. |

---

## 🚀 2. `scripts/pipeline/` (Esteira e Governança AIDD)

Utilitários de suporte à orquestração multiagente, gestão de branch/worktree, governança e métricas.

### 2.1. `worktree-manager.sh`
Gerencia o ciclo de vida completo de Git Worktrees para execução concorrente e estéril de subagentes workers (Maestro Mode).
```bash
# Criar uma worktree isolada para uma issue
./scripts/pipeline/worktree-manager.sh create <id_ou_issue> --base <branch_intermediaria>

# Sincronizar (rebase) da branch intermediária para a worktree
./scripts/pipeline/worktree-manager.sh rebase-sync <id_ou_issue> --base <branch_intermediaria>

# Remover a worktree e fazer cleanup da branch local de trabalho
./scripts/pipeline/worktree-manager.sh remove <id_ou_issue>
```

### 2.2. `metrics-collector.py`
Analisa os logs dos transcripts (`transcript.jsonl`) e calcula o consumo determinístico de tokens (input/output/cached) e chamadas de ferramentas por issue ou sessão.
```bash
# Coletar métricas da sessão ativa
./scripts/pipeline/metrics-collector.py

# Coletar métricas atribuídas a uma issue específica
./scripts/pipeline/metrics-collector.py --issue 58
```

### 2.3. `sync-project-context.py`
Remove seções voláteis e dinâmicas (como estado efêmero do Git) do `PROJECT_CONTEXT.md`, assegurando que apenas o contexto arquitetural estável permaneça commitado no repositório.
```bash
./scripts/pipeline/sync-project-context.py .
```

### 2.4. `project-status-sync.sh`
Atualiza o campo "Status" de um item no GitHub Project v2 de forma determinística via GitHub CLI (`gh`).
```bash
./scripts/pipeline/project-status-sync.sh <numero_ou_url_da_issue> "In Progress"
./scripts/pipeline/project-status-sync.sh 42 "Done"
```

### 2.5. `reconcile-github-governance.sh`
Reconcilia issues, Milestones (Épicos) e campos do GitHub Projects v2 (Status, Release), prevenindo desvios de rastreamento no Kanban e Roadmap.
```bash
# Modo de simulação sem efeitos colaterais
./scripts/pipeline/reconcile-github-governance.sh --dry-run

# Execução de reconciliação completa
./scripts/pipeline/reconcile-github-governance.sh
```

---

## 📊 3. `scripts/statusline/` (Statusline CLI & Quota Indicator)

Componentes visuais e telemetria integrados ao rodapé do terminal do Antigravity CLI.

| Script | Descrição |
|---|---|
| [`install-statusline.sh`](file:///home/vitor/Projetos/03-pessoal/my-agents/scripts/statusline/install-statusline.sh) | Configura e injeta automaticamente a statusline do `my-agents` no `~/.gemini/antigravity-cli/settings.json`. Suporta `--dry-run`. |
| [`statusline-quota.sh`](file:///home/vitor/Projetos/03-pessoal/my-agents/scripts/statusline/statusline-quota.sh) | Script de alta performance (< 50ms com cache TTL) que consulta quotas da API Gemini e formata o rodapé em tempo real. |
| [`test-statusline.sh`](file:///home/vitor/Projetos/03-pessoal/my-agents/scripts/statusline/test-statusline.sh) | Validação rápida e benchmark sub-50ms da renderização da statusline. |

---

## 🏛️ 4. `scripts/migrations/` (Migrações Históricas One-Off)

Scripts utilitários construídos para migrações em lote ou reclassificações históricas de dados do repositório.

- **`migrate-issues-to-project.sh`**: Importa backlog e issues históricas fechadas para o GitHub Projects v2.
- **`reclassify-epics-and-releases.py`**: Converte Milestones em Épicos temáticos e preenche o campo de versão `Release` das issues históricas.
