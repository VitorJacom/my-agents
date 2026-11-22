[← Voltar ao Sumário de Testes](Tests-Catalog)

> **Pipeline & Maestro**  
> **Diretório**: [`tests/features/pipeline/`](https://github.com/VitorJacom/my-agents/tree/main/tests/features/pipeline)  
> **Quantidade**: 8 suítes  
> **Comando**: `./tests/run.sh --category pipeline`

---

## 🎯 Propósito da Camada

Valida o núcleo da máquina de estados multiagente do `my-agents` ([`plan-feature`](Skill-plan-feature) e [`issue-pipeline`](Skill-issue-pipeline)): ciclo de planejamento *Elephant-Goldfish*, validação de `## Interface Contract`, execução paralela *Concurrent Fork* ([`qa-engineer`](Agent-qa-engineer) + [`coder`](Agent-coder)), particionamento de *Execution Waves*, *Merge Queue* sequencial no Modo Maestro, promoção de testes para [`tests/core/`](Test-core), hardening do CLI `tests/run.sh` e atualização de plugins.

---

## 📋 Suítes da Categoria (8)

| Suíte | Origem | O que Valida |
| :--- | :--- | :--- |
| **`test_concurrent_qa_coder_fork.sh`** | [`ARCHITECTURE`](ARCHITECTURE) (ADR-0005) | Desacoplamento paralelo (*Concurrent Fork*) entre [`qa-engineer`](Agent-qa-engineer) e [`coder`](Agent-coder) sob `## Interface Contract` congelado e portão de integração [`contract-integration-gate.sh`](Script-pipeline). |
| **`test_elephant_goldfish_governance.sh`** | Ciclo Planejamento | Modelo *Elephant-Goldfish* no [`plan-feature`](Skill-plan-feature): *Cold Audit* stateless do [`gatekeeper`](Agent-gatekeeper) e teto determinístico de 2 iterações no loop de auto-healing. |
| **`test_execution_waves_planning.sh`** | Issue #36 | Mapeamento de *Blast Radius* (`Target Files & Dependencies`) e particionamento em *Execution Waves* disjuntas (máx. 3 issues por onda). |
| **`test_maestro_merge_queue_pipeline.sh`** | Issue #9 | Orquestração multi-issue no Modo Maestro ([`issue-pipeline`](Skill-issue-pipeline)): branch intermediária, worktrees paralelas, Merge Queue sequencial e auto-reconciliação. |
| **`test_planner_interface_contract.sh`** | [`ARCHITECTURE`](ARCHITECTURE) (ADR-0005) | Validação determinística do `## Interface Contract` produzido pelo [`planner`](Agent-planner) via [`validate-interface-contract.sh`](Script-pipeline), bloqueando placeholders (`TODO`/`TBD`). |
| **`test_promote_core_test_script.sh`** | Issue #64 | Utilitário [`promote-core-test.sh`](Script-pipeline) e protocolo interativo de promoção auditada de testes de `tests/features/` para [`tests/core/`](Test-core). |
| **`test_runner_cli.sh`** | Issue #601 | Hardening, fail-fast, parsing de flags (`--all`, `--core`, `--features`, `--category`, `--filter`) e validação de regex do executor `tests/run.sh`. |
| **`test_update_plugin.sh`** | Issue #66 | Utilitário [`update-plugin.sh`](Script-pipeline) de atualização de plugins, verificação de versões e integridade pós-atualização. |

---

## 🔗 Navegação

[← Anterior: Governança GitHub](Test-governance) | [Sumário de Testes](Tests-Catalog) | [Próxima Categoria: Wiki & Documentação →](Test-wiki)
