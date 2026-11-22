[← Voltar ao Sumário de Scripts](Scripts-Catalog)

# 🚀 Scripts: Esteira & Governança AIDD (`scripts/pipeline/`)

> **Diretório**: [`scripts/pipeline/`](https://github.com/VitorJacom/my-agents/tree/main/scripts/pipeline)  
> **Quantidade**: 12 scripts (Bash + Python)

---

## 🎯 Propósito

Concentra os motores determinísticos da máquina de estados do [`AIDD-Manifesto`](AIDD-Manifesto) usados pelas esteiras [`plan-feature`](Skill-plan-feature) e [`issue-pipeline`](Skill-issue-pipeline): isolamento de **Git Worktrees** no Modo Maestro, portões de contrato (*Interface Contract* e *Contract Integration Gate*), sincronização de governança no GitHub Projects v2, promoção segura para [`tests/core/`](Test-core), telemetria de tokens e atualização do plugin — validados pelas suítes [`Test-pipeline`](Test-pipeline) e [`Test-governance`](Test-governance).

---

## 📋 Catálogo de Scripts (12)

### 🔄 Orquestração, Worktrees & Portões de Contrato

| Script | Linguagem | Função e Uso Principal |
| :--- | :--- | :--- |
| **`worktree-manager.sh`** | Bash | Gerencia ciclo de vida de Git Worktrees isoladas (`.worktrees/issue-<id>`) para o Modo Maestro: `create`, `rebase-sync --base`, `remove`. |
| **`validate-interface-contract.sh`** / **`.py`** | Bash + Python | Valida o *Interface Contract Gate* produzido pelo [`planner`](Agent-planner) (presença dos 5 pilares: Signatures, Types & Interfaces, Inputs, Outputs, Errors e ausência de `TODO`/`TBD`). |
| **`contract-integration-gate.sh`** / **`.py`** | Bash + Python | Executa o Join Point do *Concurrent Fork* ([`ARCHITECTURE`](ARCHITECTURE) — ADR-0005) com `--test-cmd` explícito, timeout rígido de 60s, cobertura $\ge 85\%$ e verificação de confinamento entre [`qa-engineer`](Agent-qa-engineer) e [`coder`](Agent-coder). |
| **`promote-core-test.sh`** | Bash | Promove de forma auditada e interativa um teste aprovado de `tests/features/` para a zona intocável [`tests/core/`](Test-core) (ADR-0015). |
| **`update-plugin.sh`** | Bash | Gerencia verificação (`--check`), status (`--status`) e aplicação segura (`--apply`) de atualizações do plugin `my-agents` com proteção contra *dirty working tree*. |

### 🏛️ Governança GitHub & Contexto

| Script | Linguagem | Função e Uso Principal |
| :--- | :--- | :--- |
| **`project-status-sync.sh`** | Bash | Atualiza o campo `Status` (`Planned`, `In Progress`, `Done`) de uma issue no GitHub Project v2 com auto-inclusão idempotente. |
| **`reconcile-github-governance.sh`** | Bash | Reconcilia issues, Milestones (Épicos), labels e campos (`Status`, `Release`) no GitHub Projects v2. Suporta `--dry-run`. |
| **`sync-project-context.py`** | Python | Remove seções voláteis do Git de `PROJECT_CONTEXT.md`, mantendo apenas a estrutura arquitetural canônica versionada. |

### 📊 Telemetria & Eficiência de Tokens

| Script | Linguagem | Função e Uso Principal |
| :--- | :--- | :--- |
| **`metrics-collector.py`** | Python | Analisa `transcript.jsonl` de subagentes e gera relatório de tokens (input/output/cached) e tool calls por issue (`--markdown`). |
| **`audit-token-efficiency.py`** | Python | Mapeia consumo de tokens por fase ([`planner`](Agent-planner), [`qa-engineer`](Agent-qa-engineer), [`coder`](Agent-coder), [`gatekeeper`](Agent-gatekeeper)), detecta hotspots/anomalias de cache e aplica quality gate (`--min-score`). |

---

## 💻 Exemplos Rápidos

```bash
# 1. Validar Interface Contract antes do Concurrent Fork
./scripts/pipeline/validate-interface-contract.sh implementation_plan.md

# 2. Executar o Join Point com timeout rígido e checagem de cobertura
./scripts/pipeline/contract-integration-gate.sh --iteration 1 --test-cmd "./tests/run.sh" --coverage 88.5

# 3. Gerenciar worktree isolada no Modo Maestro
./scripts/pipeline/worktree-manager.sh create 42 --base integration/wave-1
./scripts/pipeline/worktree-manager.sh rebase-sync 42 --base integration/wave-1

# 4. Reconciliar governança GitHub em modo simulação
./scripts/pipeline/reconcile-github-governance.sh --dry-run

# 5. Checar atualizações do plugin
./scripts/pipeline/update-plugin.sh --check
```

---

## 🔗 Navegação

[← Anterior: Hooks de Runtime](Script-hooks) | [Sumário de Scripts](Scripts-Catalog) | [Próxima Categoria: Revisor de PR & Telemetria →](Script-pr-reviewer)
