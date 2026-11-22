# 🛠️ Sumário de Scripts (`Scripts-Catalog`)

Este documento é o **índice central e resumo executivo** dos **21 scripts e utilitários** do ecossistema `my-agents` localizados em [`scripts/`](https://github.com/VitorJacom/my-agents/tree/main/scripts). Cada categoria possui sua própria **página dedicada na Wiki** com sintaxe CLI, contratos de uso, códigos de saída e exemplos práticos.

---

## 🛡️ 1. Padrões Obrigatórios de Engenharia em Scripts

Todos os scripts de automação seguem as diretrizes do [Manifesto AIDD](AIDD-Manifesto):
- **Fail-Fast Mandatório**: Todo script Bash inicia com `set -euo pipefail` e nunca mascara falhas com `exit 0`.
- **Timeouts Rígidos & Anti-Hang**: Subprocessos de teste e integração impõem timeout finito (padrão 60s), evitando travamentos silenciosos.
- **Modo Simulação (`--dry-run`)**: Scripts com efeitos colaterais remotos ou no sistema de arquivos oferecem `--dry-run` para validação segura.

---

## 📊 2. Tabela Resumo das Categorias de Scripts

Clique em qualquer categoria para acessar sua **página dedicada**:

| Categoria | Diretório | Scripts | Foco Principal |
| :--- | :--- | :---: | :--- |
| **[🪝 Hooks de Runtime](Script-hooks)** | `scripts/hooks/` | **2** | Interceptação `PreToolUse` (`safety-guard.sh`) e injeção de contexto dinâmico `SessionStart` (`session-start-context.sh`). |
| **[🚀 Esteira & Governança AIDD](Script-pipeline)** | `scripts/pipeline/` | **12** | Worktrees, portões de *Interface Contract*, *Contract Integration Gate*, reconciliação GitHub, promoção `tests/core/`, métricas e `update-plugin.sh`. |
| **[🔍 Revisor de PR & Telemetria](Script-pr-reviewer)** | `scripts/` *(raiz)* | **2** | Motor CLI da esteira `/review-pr` (`pr-reviewer.sh`) e wrapper de auditoria de eficiência de tokens (`audit-token-efficiency.py`). |
| **[⚡ Statusline & Quota CLI](Script-statusline)** | `scripts/statusline/` | **3** | Instalador idempotente, barra de status sub-50ms com quota Gemini e widget de atualização (`statusline-quota.sh`). |
| **[🏛️ Migrações Históricas](Script-migrations)** | `scripts/migrations/` | **2** | Utilitários *one-off* para migração de issues ao GitHub Projects v2 e reclassificação de Épicos/Releases. |

---

## 🗂️ 3. Mapa Rápido de Acesso

- **Operação Diária & Esteira**: [`worktree-manager.sh`](Script-pipeline), [`validate-interface-contract.sh`](Script-pipeline), [`contract-integration-gate.sh`](Script-pipeline), [`update-plugin.sh`](Script-pipeline)
- **Governança GitHub**: [`project-status-sync.sh`](Script-pipeline), [`reconcile-github-governance.sh`](Script-pipeline), [`promote-core-test.sh`](Script-pipeline)
- **Code Review & Telemetria**: [`pr-reviewer.sh`](Script-pr-reviewer), [`audit-token-efficiency.py`](Script-pr-reviewer), [`metrics-collector.py`](Script-pipeline)
- **Ambiente Local & CLI**: [`safety-guard.sh`](Script-hooks), [`session-start-context.sh`](Script-hooks), [`install-statusline.sh`](Script-statusline), [`statusline-quota.sh`](Script-statusline)

---

## 📚 4. Leituras Complementares

- [Sumário de Skills (`Skills-Catalog`)](Skills-Catalog): Skills que orquestram esses utilitários.
- [Sumário de Testes (`Tests-Catalog`)](Tests-Catalog): Suítes automatizadas que validam cada script.
- [Troubleshooting (`Troubleshooting`)](Troubleshooting): Diagnóstico de locks, permissões e falhas de execução.
