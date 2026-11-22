[← Voltar ao Sumário de Testes](Tests-Catalog)

> **Core Invariants**  
> **Diretório**: [`tests/core/`](https://github.com/VitorJacom/my-agents/tree/main/tests/core)  
> **Quantidade**: 4 suítes imutáveis  
> **Comando**: `./tests/run.sh --core`

---

## 🎯 Propósito da Camada

A pasta `tests/core/` é a **zona intocável** do repositório definida no [`AIDD-Manifesto`](AIDD-Manifesto). Ela concentra as regras invariantes de engenharia que nunca podem sofrer regressão durante o desenvolvimento de novas features.

> [!IMPORTANT]
> **Golden Rule Anti-Fraude**: Qualquer modificação (`M`) ou deleção (`D`) de arquivos em `tests/core/` durante uma branch de feature dispara aborto imediato (**Circuit Breaker**) pelo [`gatekeeper`](Agent-gatekeeper) e pelo CI. Novos testes só entram nesta camada via promoção auditada com [`promote-core-test.sh`](Script-pipeline).

---

## 📋 Suítes da Categoria (4)

| Suíte | Origem | O que Valida |
| :--- | :--- | :--- |
| **`test_context_volatile_decoupling.sh`** | Issue #35 | Garante que metadados voláteis do Git (branch ativa, último commit, status da working tree) sejam injetados dinamicamente via hook ([`Script-hooks`](Script-hooks)) e **nunca poluam** o `PROJECT_CONTEXT.md` estável. |
| **`test_governance_coverage_and_test_cases.sh`** | Issue #12 | Valida a exigência de cobertura mínima $\ge 85\%$, separação mandatória entre *Happy Path* e *Edge Cases / Failure Modes* e provas demonstrativas universais no `walkthrough.md`. |
| **`test_maestro_subagent_delegation_rules.sh`** | Issue #42 | Assegura a segregação estrita Control Plane vs. Execution Plane no Modo Maestro ([`issue-pipeline`](Skill-issue-pipeline)), proibindo execução de código inline e exigindo delegação via `invoke_subagent`. |
| **`test_worktree_manager.sh`** | Core Infra | Valida o ciclo de vida de [`worktree-manager.sh`](Script-pipeline): isolamento físico de worktrees, locks atômicos, sanitização de branches e `rebase-sync`. |

---

## 🔗 Navegação

[← Voltar ao Sumário de Testes](Tests-Catalog) | [Próxima Categoria: Governança GitHub →](Test-governance)
