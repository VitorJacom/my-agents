[← Voltar ao Sumário de Testes](Tests-Catalog)

# 🔄 Testes: Pipeline & Maestro (`tests/features/pipeline/`)

> **Diretório**: [`tests/features/pipeline/`](https://github.com/VitorJacom/my-agents/tree/main/tests/features/pipeline)  
> **Quantidade**: 8 suítes  
> **Comando**: `./tests/run.sh --category pipeline`

---

## 🎯 Propósito da Camada

Valida o núcleo da máquina de estados multiagente do `my-agents`: ciclo de planejamento *Elephant-Goldfish*, validação de `## Interface Contract`, execução paralela *Concurrent Fork* (`qa-engineer` + `coder`), particionamento de *Execution Waves*, *Merge Queue* sequencial no Modo Maestro, promoção de testes para `tests/core/`, hardening do CLI `tests/run.sh` e atualização de plugins.

---

## 📋 Suítes da Categoria (8)

| Suíte | Origem | O que Valida |
| :--- | :--- | :--- |
| **`test_concurrent_qa_coder_fork.sh`** | ADR-0005 | Desacoplamento paralelo (*Concurrent Fork*) entre `qa-engineer` e `coder` sob `## Interface Contract` congelado e portão de integração `contract-integration-gate.sh`. |
| **`test_elephant_goldfish_governance.sh`** | Ciclo Planejamento | Modelo *Elephant-Goldfish* no [`plan-feature`](Skill-plan-feature): *Cold Audit* stateless do `gatekeeper` e teto determinístico de 2 iterações no loop de auto-healing. |
| **`test_execution_waves_planning.sh`** | Issue #36 | Mapeamento de *Blast Radius* (`Target Files & Dependencies`) e particionamento em *Execution Waves* disjuntas (máx. 3 issues por onda). |
| **`test_maestro_merge_queue_pipeline.sh`** | Issue #9 | Orquestração multi-issue no Modo Maestro: branch intermediária, worktrees paralelas, Merge Queue sequencial e auto-reconciliação. |
| **`test_planner_interface_contract.sh`** | ADR-0005 | Validação determinística do `## Interface Contract` (Signatures, Types, Inputs, Outputs, Errors) via `validate-interface-contract.sh` bloqueando placeholders (`TODO`/`TBD`). |
| **`test_promote_core_test_script.sh`** | Issue #64 | Utilitário `promote-core-test.sh` e protocolo interativo de promoção auditada de testes de `tests/features/` para `tests/core/`. |
| **`test_runner_cli.sh`** | Issue #601 | Hardening, fail-fast, parsing de flags (`--all`, `--core`, `--features`, `--category`, `--filter`) e validação de regex do executor `tests/run.sh`. |
| **`test_update_plugin.sh`** | Issue #66 | Utilitário de atualização de plugins, verificação de versões e integridade pós-atualização. |

---

## 🔗 Navegação

[← Anterior: Governança GitHub](Test-governance) | [Sumário de Testes](Tests-Catalog) | [Próxima Categoria: Wiki & Documentação →](Test-wiki)
