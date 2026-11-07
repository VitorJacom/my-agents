# 🧪 Arquitetura e Guia da Suíte de Testes (`tests/`)

Este diretório contém a infraestrutura e todas as suítes determinísticas de testes automatizados do ecossistema `my-agents`, projetadas em conformidade estrita com o Manifesto AI-Driven Development (AIDD).

---

## 🏛️ 1. Arquitetura em Dupla Camada

Para garantir governança anti-fraude e evolução contínua, os testes são divididos em duas zonas canônicas:

```
tests/
├── run.sh                  # Test Runner centralizado com relatórios determinísticos
├── core/                   # 🛡️ ZONA INTOCÁVEL (Pilares Invariantes AIDD)
└── features/               # 🚀 ZONA DE EVOLUÇÃO TDD (Critérios de Aceite por Domínio)
    ├── pipeline/           # Testes de orquestração multiagente, ondas e worktrees
    ├── governance/         # Testes de GitHub Project v2, Milestones, labels e reconciliação
    ├── ui-ux/              # Testes do motor UI/UX, Design Tokens e Mockup-as-Code
    ├── wiki/               # Testes de integridade da GitHub Wiki e links relativos
    └── statusline/         # Testes de latência sub-50ms e injeção do prompt de status
```

---

### 🛡️ 1.1. Camada `tests/core/` (Regras Fundamentais e Intocáveis)

Contém os pilares estruturais e regras inegociáveis do ecossistema:
- **`test_governance_coverage_and_test_cases.sh`**: Valida a exigência de cobertura $\ge 85\%$ e separação obrigatória entre Happy Path e Edge Cases.
- **`test_context_volatile_decoupling.sh`**: Garante que metadados voláteis do Git não poluam o `PROJECT_CONTEXT.md` estável.
- **`test_maestro_subagent_delegation_rules.sh`**: Assegura a proibição estrita de execução de código inline pelo Maestro no Control Plane.
- **`test_worktree_manager.sh`**: Valida o isolamento físico de workspaces, locks atômicos e sanitização de branches.

> [!IMPORTANT]
> **A Golden Rule Anti-Fraude**:
> Qualquer alteração (mesmo de 1 caractere) em arquivos dentro de `tests/core/` durante a execução de uma feature resulta em **rejeição imediata (Circuit-Breaker)** pelo Gatekeeper e pelo CI. O subagente `coder` não tem autorização para modificar esta pasta.

---

### 🚀 1.2. Camada `tests/features/` (Critérios de Aceite TDD)

Onde novos testes de aceitação são adicionados pelo subagente `qa-engineer` durante o ciclo de vida de uma issue, organizados por domínio funcional:

| Domínio | Subpasta | Descrição |
|---|---|---|
| **Pipeline & Maestro** | `tests/features/pipeline/` | Valida planejamento em ondas, concorrência $\le 3$ workers e merge queue sequencial com auto-reconciliação. |
| **Governança GitHub** | `tests/features/governance/` | Valida mapeamento de épicos/releases, convenções de labels/views e sincronização com o GitHub Projects v2. |
| **Design & UI/UX** | `tests/features/ui-ux/` | Valida o catálogo de 48 regras, protocolos de Living Mockups side-by-side e gates visuais. |
| **Wiki & Docs** | `tests/features/wiki/` | Valida links internos, sintaxe Markdown, integridade de navegação e espelhamento da Wiki. |
| **Statusline CLI** | `tests/features/statusline/` | Valida benchmark de performance < 50ms, cache TTL e instalação idempotente da statusline. |

---

## ⚡ 2. Como Executar os Testes (`tests/run.sh`)

O runner unificado [`tests/run.sh`](run.sh) descobre e executa as suítes de teste de forma determinística, fornecendo logs estruturados e relatório final.

```bash
# Executa TODOS os testes (core + features)
./tests/run.sh

# Executa apenas os testes invariantes do core (Golden Rule)
./tests/run.sh --core

# Executa todos os testes de features
./tests/run.sh --features

# Executa os testes de uma categoria específica
./tests/run.sh --category pipeline
./tests/run.sh --category governance
./tests/run.sh --category ui-ux
./tests/run.sh --category wiki
./tests/run.sh --category statusline

# Filtra testes por padrão de nome
./tests/run.sh --filter "mockup"
./tests/run.sh --category governance --filter "reconcile"
```

---

## 📋 3. Padrões Obrigatórios para Novos Testes

Todo novo teste adicionado em `tests/features/` deve respeitar:
1. **Fail-Fast**: Iniciar obrigatoriamente com `#!/usr/bin/env bash` e `set -euo pipefail`.
2. **Discriminação de Casos de Teste**: Separar explicitamente blocos de **Happy Path** (caminho feliz) e **Edge Cases / Failure Modes** (cenários de borda e falha resiliente).
3. **Anti-Trivialidade**: Proibido testes vazios, `exit 0` incondicionais ou asserções tautológicas.
4. **Independência de Ambiente**: Testes que criam repositórios Git ou arquivos temporários devem operar em diretórios efêmeros (`mktemp -d`) e realizar limpeza garantida via `trap 'rm -rf "$TMP_DIR"' EXIT`.
