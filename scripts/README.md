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
| [`safety-guard.sh`](hooks/safety-guard.sh) | `PreToolUse` | Intercepta comandos no terminal impedindo operações destrutivas não autorizadas (ex: `rm -rf /`, force push descontrolado). |
| [`session-start-context.sh`](hooks/session-start-context.sh) | `SessionStart` | Injeta o estado volátil do Git dinamicamente no início da sessão do agente, garantindo contexto atualizado sem poluir `PROJECT_CONTEXT.md`. |

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
# Coletar métricas dos subagentes da sessão
./scripts/pipeline/metrics-collector.py --agents '{"Planner": "<cid>", "QA": "<cid>", "Coder": "<cid>"}'

# Coletar métricas atribuídas a uma issue específica em formato Markdown
./scripts/pipeline/metrics-collector.py --issue 58 --agents '{"Planner": "<cid>", "Coder": "<cid>"}' --markdown
```

### 2.3. `audit-token-efficiency.py`
Analisa telemetria, transcripts do Antigravity CLI e dados de execução dos agentes, mapeando o consumo de tokens por fase (Planning, QA, Coding, Gatekeeper) e operações (tool calls), identificando hotspots de tokens e anomalias de cache com cálculo determinístico de score (0-100) e quality gate.
```bash
# Auditoria de transcript individual
./scripts/audit-token-efficiency.py --transcript ~/.gemini/antigravity-cli/brain/<cid>/.system_generated/logs/transcript.jsonl

# Auditoria multi-agente por fase com quality gate de score mínimo (fail-fast)
./scripts/audit-token-efficiency.py --agents '{"Planner": "<cid1>", "QA": "<cid2>", "Coder": "<cid3>", "Gatekeeper": "<cid4>"}' --min-score 80

# Emissão em JSON ou Markdown
./scripts/audit-token-efficiency.py --transcript transcript.jsonl --markdown
./scripts/audit-token-efficiency.py --transcript transcript.jsonl --json
```

### 2.4. `sync-project-context.py`
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

### 2.6. `validate-interface-contract.sh`
Valida o **Interface Contract Gate** de forma determinística, garantindo a presença da seção `## Interface Contract` e a integridade de seus 5 pilares (Signatures, Types & Interfaces, Inputs, Outputs, Errors) com assinaturas tipadas e sem ambiguidades.
```bash
# Validar um arquivo de plano existente
./scripts/pipeline/validate-interface-contract.sh implementation_plan.md

# Validar via stdin
cat planning_proposal.md | ./scripts/pipeline/validate-interface-contract.sh
```

### 2.7. `contract-integration-gate.sh`
Valida o ponto de convergência (Join Point) entre os testes em `tests/features/` (criados pelo `qa-engineer`) e o código em `src/` (implementado pelo `coder`), gerenciando o loop de reconciliação de até 2 iterações e o fail-safe determinístico (ADR-0005).
```bash
# Executar validação padrão do Join Point (executa ./tests/run.sh)
./scripts/pipeline/contract-integration-gate.sh

# Avaliar tentativa de reconciliação específica com cobertura
./scripts/pipeline/contract-integration-gate.sh --iteration 2 --coverage 88.5

# Simulação determinística com código de saída injetado
./scripts/pipeline/contract-integration-gate.sh --test-exit-code 0 --coverage 92.0

# Validação estrita de confinamento anti-fraude de personas
./scripts/pipeline/contract-integration-gate.sh --qa-files "tests/features/test_foo.sh" --coder-files "src/foo.py"
```

---

## 📊 3. `scripts/statusline/` (Statusline CLI & Quota Indicator)

Componentes visuais e telemetria integrados ao rodapé do terminal do Antigravity CLI.

| Script | Descrição |
|---|---|
| [`install-statusline.sh`](statusline/install-statusline.sh) | Configura e injeta automaticamente a statusline do `my-agents` no `~/.gemini/antigravity-cli/settings.json`. Suporta `--dry-run`. |
| [`statusline-quota.sh`](statusline/statusline-quota.sh) | Script de alta performance (< 50ms com cache TTL) que consulta quotas da API Gemini e formata o rodapé em tempo real. |
| [`test-statusline.sh`](statusline/test-statusline.sh) | Validação rápida e benchmark sub-50ms da renderização da statusline. |

---

## 🏛️ 4. `scripts/migrations/` (Migrações Históricas One-Off)

Scripts utilitários construídos para migrações em lote ou reclassificações históricas de dados do repositório.

- **`migrate-issues-to-project.sh`**: Importa backlog e issues históricas fechadas para o GitHub Projects v2.
- **`reclassify-epics-and-releases.py`**: Converte Milestones em Épicos temáticos e preenche o campo de versão `Release` das issues históricas.
