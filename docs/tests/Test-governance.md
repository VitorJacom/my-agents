[← Voltar ao Sumário de Testes](Tests-Catalog)

# 🏛️ Testes: Governança GitHub & AIDD (`tests/features/governance/`)

> **Diretório**: [`tests/features/governance/`](https://github.com/VitorJacom/my-agents/tree/main/tests/features/governance)  
> **Quantidade**: 16 suítes  
> **Comando**: `./tests/run.sh --category governance`

---

## 🎯 Propósito da Camada

Valida todas as regras de governança de ciclo de vida no GitHub, integração com **GitHub Projects v2**, **Milestones/Épicos**, taxonomia de labels, convenções de Pull Requests, proteção da *Golden Rule* e portabilidade de scripts e documentação.

---

## 📋 Suítes da Categoria (16)

| Suíte | Origem | O que Valida |
| :--- | :--- | :--- |
| **`test_canonical_taxonomy_alignment.sh`** | Issue #603 | Alinhamento da taxonomia canônica de diretórios entre `PROJECT_CONTEXT.md` e `agents/qa-engineer/agent.md`. |
| **`test_golden_rule_diff_filter.sh`** | Issue #65 | Modernização da *Golden Rule* Anti-Fraude com `--diff-filter=MD` (ADR-0015), bloqueando `M`/`D` e permitindo adições legítimas (`A`) auditadas. |
| **`test_issue_lifecycle_modernization.sh`** | Issue #58 | Modernização do ciclo de vida de issues: Épicos via Milestones, campo `Release` no Project v2, sub-issues `--parent` e refinamento *in-place*. |
| **`test_labels_views_conventions.sh`** | Issue #22 | Padronização de Views no GitHub Projects v2 e taxonomia canônica de labels AIDD (`type:*`, `status:*`, `aidd:wave-*`). |
| **`test_milestone_plan_feature.sh`** | Issue #19 | Suporte nativo à vinculação dinâmica de Milestones (`--milestone`) no `/plan-feature`. |
| **`test_plan_core_rule_detection.sh`** | Issue #63 | Protocolo socrático de detecção concreta de Regras Core no `/plan-feature` (proibindo perguntas genéricas no vácuo). |
| **`test_pr_closing_keyword_convention.sh`** | Issue #69 | Obrigatoriedade de palavras-chave de fechamento (`Fixes #<id>`) em texto puro nos corpos de PR para garantir *auto-close* no GitHub. |
| **`test_project_v2_plan_feature.sh`** | Issue #20 | Vinculação de issues ao GitHub Projects v2 durante o `/plan-feature` com degradação graciosa em caso de erro de rede. |
| **`test_project_v2_status_transition.sh`** | Issue #71 | Sincronização resiliente de transições de status (`Planned` ➔ `In Progress` ➔ `Done`) via `project-status-sync.sh`. |
| **`test_project_v2_workflow.sh`** | Issue #72 | Workflow automatizado de sincronização contínua do GitHub Projects v2 no GitHub Actions. |
| **`test_publish_rule_issue_governance.sh`** | Issue #44 | Modernização da skill [`publish-rule-issue`](Skill-publish-rule-issue) com contratos atômicos, milestones e Project v2. |
| **`test_readme_portability.sh`** | Issue #57 | Portabilidade universal, guias de instalação remota e preview da statusline no `README.md`. |
| **`test_reconcile_github_governance.sh`** | Issue #45 | Comportamento idempotente do script `reconcile-github-governance.sh` na sincronização de labels, milestones e Project v2. |
| **`test_reconcile_status_init.sh`** | Issue #70 | Status inicial `Planned`, fechamento para `Done` e idempotência no reconciliador de governança. |
| **`test_scripts_usage_canonical_paths.sh`** | Issue #604 | Padronização de cabeçalhos canônicos e strings de `usage`/`--help` nos scripts categorizados sob `scripts/`. |
| **`test_walkthrough_image_url_governance.sh`** | Issue #75 | Proibição de caminhos relativos e exigência de URLs absolutas `raw.githubusercontent.com` para imagens em `walkthrough.md` e PRs. |

---

## 🔗 Navegação

[← Anterior: Core Invariants](Test-core) | [Sumário de Testes](Tests-Catalog) | [Próxima Categoria: Pipeline & Maestro →](Test-pipeline)
