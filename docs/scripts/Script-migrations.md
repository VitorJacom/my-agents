[← Voltar ao Sumário de Scripts](Scripts-Catalog)

# 🏛️ Scripts: Migrações Históricas (`scripts/migrations/`)

> **Diretório**: [`scripts/migrations/`](https://github.com/VitorJacom/my-agents/tree/main/scripts/migrations)  
> **Quantidade**: 2 scripts (*one-off*)

---

## 🎯 Propósito

Reúne utilitários históricos construídos para operações em lote de migração e reclassificação de backlog no GitHub. Servem como referência auditável e podem ser reutilizados como base ao onboardar repositórios legados no modelo de governança AIDD.

---

## 📋 Catálogo de Scripts (2)

| Script | Linguagem | Função |
| :--- | :---: | :--- |
| **`migrate-issues-to-project.sh`** | Bash | Importa backlog aberto e issues históricas fechadas para o **GitHub Projects v2**, sincronizando status iniciais em lote. |
| **`reclassify-epics-and-releases.py`** | Python | Converte Milestones temporais antigos em **Épicos temáticos** canônicos e preenche o campo Single Select `Release` (`v1.0.0`, `v1.1.0`, etc.) no GitHub Project v2. |

> [!NOTE]
> Para a manutenção contínua do backlog no dia a dia, utilize sempre [`reconcile-github-governance.sh`](Script-pipeline) em vez dos scripts de migração *one-off*.

---

## 🔗 Navegação

[← Anterior: Statusline & Quota CLI](Script-statusline) | [Sumário de Scripts](Scripts-Catalog)
