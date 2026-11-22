> **Cabeçalho de Controle (Pressman / Sommerville)**  
> - **Escopo / Filtros Aplicados**: `tests/core/*.sh` + `tests/features/**/*.sh` • Runner: `./tests/run.sh` • Ordenação: `Camada ➔ Volume de Suítes`  
> - **Data/Hora de Emissão**: `2026-11-22 15:33 BRT` *(sincronizado via `.github/workflows/wiki-sync.yml`)*  
> - **Fonte Canônica**: [`tests/`](https://github.com/VitorJacom/my-agents/tree/main/tests)

Este documento é o **índice central e resumo executivo** das **51 suítes determinísticas de testes** do ecossistema `my-agents`, executadas pelo runner unificado [`tests/run.sh`](https://github.com/VitorJacom/my-agents/blob/main/tests/run.sh). Cada categoria possui sua própria **página dedicada na Wiki** com a lista completa de suítes, objetivos, issues de origem e comandos de execução.

---

## 🏛️ 1. Arquitetura em Dupla Camada & Golden Rule

Os testes seguem a **Trava Dupla Anti-Fraude** do [Manifesto AIDD](AIDD-Manifesto):

- **`tests/core/` (Zona Intocável — 4 suítes)**: Guarda invariantes fundamentais do ecossistema. Qualquer modificação (`M`) ou remoção (`D`) nessa pasta dispara **Circuit Breaker (exit code 1)** no Gatekeeper e no CI (`git diff --diff-filter=MD`). Adições auditadas são feitas apenas via `promote-core-test.sh`.
- **`tests/features/` (Zona de Evolução TDD — 47 suítes)**: Critérios de aceite criados pelo `qa-engineer` em estado inicial **RED**, organizados por domínio funcional, com separação obrigatória entre **Happy Path** e **Edge Cases / Failure Modes**.

---

## ⚡ 2. Como Executar (`./tests/run.sh`)

```bash
# Executar TODAS as 51 suítes (core + features)
./tests/run.sh

# Executar apenas a zona imutável (core)
./tests/run.sh --core

# Executar apenas features
./tests/run.sh --features

# Executar por categoria canônica
./tests/run.sh --category pipeline
./tests/run.sh --category governance
./tests/run.sh --category ui-ux
./tests/run.sh --category wiki
./tests/run.sh --category statusline

# Filtrar por regex no nome do arquivo
./tests/run.sh --filter "mockup"
./tests/run.sh --category governance --filter "reconcile"
```

---

## 📊 3. Tabela Resumo das Categorias de Teste

Clique em qualquer categoria para acessar sua **página dedicada**:

| # | Categoria | Diretório | Suítes | % Total | Foco Principal | Comando Rápido |
| ---: | :--- | :--- | ---: | ---: | :--- | :--- |
| 1 | **[🛡️ Core Invariants](Test-core)** | `tests/core/` | 4 | 7.8% | Pilares imutáveis protegidos pela *Golden Rule* (cobertura $\ge 85\%$, worktrees, delegação Maestro, contexto). | `./tests/run.sh --core` |
| 2 | **[🏛️ Governança GitHub](Test-governance)** | `tests/features/governance/` | 16 | 31.4% | Project v2, Milestones, Labels, reconciliação idempotente, *closing keywords* e *Golden Rule*. | `./tests/run.sh -c governance` |
| 3 | **[🔄 Pipeline & Maestro](Test-pipeline)** | `tests/features/pipeline/` | 8 | 15.7% | Ciclo *Elephant-Goldfish*, *Interface Contract*, *Concurrent Fork*, *Execution Waves* e *Merge Queue*. | `./tests/run.sh -c pipeline` |
| 4 | **[📚 Wiki & Documentação](Test-wiki)** | `tests/features/wiki/` | 8 | 15.7% | Integridade de links internos, `wiki-sync.yml`, catálogos duplos de telas e guias de onboarding. | `./tests/run.sh -c wiki` |
| 5 | **[🎨 UI/UX & Mockups](Test-ui-ux)** | `tests/features/ui-ux/` | 7 | 13.7% | Protocolo *Mockup-as-Code*, Living Specs, *Visual Audit Gate*, comparação visual e skill `ui-ux-design`. | `./tests/run.sh -c ui-ux` |
| 6 | **[🔍 Revisão de PR & Telemetria](Test-pr-review)** | `tests/features/*.sh` | 5 | 9.8% | Esteira `/review-pr` (5 fases), auditoria de PR, submissão de parecer, geração de issues e eficiência de tokens. | `./tests/run.sh -f "pr_\|review_pr\|token"` |
| 7 | **[⚡ Statusline & Performance](Test-statusline)** | `tests/features/statusline/` | 3 | 5.9% | Arquitetura modular da statusline, benchmark sub-50ms, instalador e widget de atualização. | `./tests/run.sh -c statusline` |
| **Total** | **7 Categorias** | **`tests/`** | **51** | **100.0%** | **4 Core (Imutáveis) + 47 Features (TDD)** | **`./tests/run.sh`** |

---

## 📋 4. Padrões Obrigatórios para Novos Testes

Todo teste adicionado em `tests/features/` deve obedecer:
1. **Fail-Fast**: Iniciar com `#!/usr/bin/env bash` e `set -euo pipefail`.
2. **Happy Path + Edge Cases / Failure Modes**: Cobertura explícita de fluxos de sucesso e cenários de borda/falha.
3. **Anti-Trivialidade**: Proibido testes vazios, `exit 0` incondicional ou asserções tautológicas.
4. **Isolamento & Mocks Determinísticos**: Diretórios temporários via `mktemp -d` com limpeza garantida (`trap 'rm -rf "$TMP_DIR"' EXIT`) e mocks determinísticos para evitar recursão.

---

## 📚 5. Leituras Complementares

- [Manifesto AIDD (`AIDD-Manifesto`)](AIDD-Manifesto): Regras de cobertura $\ge 85\%$, *Golden Rule* e *Mutation Testing*.
- [Skill `test-runner`](Skill-test-runner): Fluxo cirúrgico de execução, diagnóstico e validação *Clean Room*.
- [Troubleshooting (`Troubleshooting`)](Troubleshooting): Diagnóstico de falhas comuns na suíte e locks de worktree.

---

> **Rodapé de Controle — Totalizadores & Paginação**  
> **Totalizadores**: `51 Suítes` (`4 Core` + `47 Features`) • `7 Categorias` • `7 Páginas Dedicadas`  
> **Paginação**: `Catálogo 4 de 4` — [← Anterior: 🛠️ Scripts](Scripts-Catalog) | [🏠 Home](Home)
