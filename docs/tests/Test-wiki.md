[← Voltar ao Sumário de Testes](Tests-Catalog)

# 📚 Testes: Wiki & Documentação (`tests/features/wiki/`)

> **Diretório**: [`tests/features/wiki/`](https://github.com/VitorJacom/my-agents/tree/main/tests/features/wiki)  
> **Quantidade**: 8 suítes  
> **Comando**: `./tests/run.sh --category wiki`

---

## 🎯 Propósito da Camada

Garante que toda a documentação *Docs-as-Code* em `docs/` e sua sincronização com a **GitHub Wiki** (`.github/workflows/wiki-sync.yml`) permaneçam íntegras, sem links quebrados, sem URLs locais `file://` e com aderência às regras de catálogos duplos de telas e guias de onboarding.

---

## 📋 Suítes da Categoria (8)

| Suíte | Origem | O que Valida |
| :--- | :--- | :--- |
| **`test_dual_screen_catalogs_governance.sh`** | Issue #83 | Governança do portal Wiki e duplo catálogo de telas (`Mockups-Catalog` vs. `Implemented-Screens-Catalog`) e normalização segura para Gollum. |
| **`test_issue_24_wiki_landing.sh`** | Issue #24 | Estrutura da landing page ([Home](Home)), `_Sidebar.md` e `_Footer.md` como hub central de navegação. |
| **`test_issue_25_onboarding_catalogs.sh`** | Issue #25 | Conteúdo e integridade dos manuais de onboarding ([Getting-Started](Getting-Started)), [Subagents](Subagents) e [Skills-Catalog](Skills-Catalog). |
| **`test_issue_26_governance_troubleshooting.sh`** | Issue #26 | Guias de governança ([AIDD-Manifesto](AIDD-Manifesto), [System-Architecture](System-Architecture)) e diagnósticos em [Troubleshooting](Troubleshooting). |
| **`test_issue_46_governance_reconciliation_docs.sh`** | Issue #46 | Documentação determinística do fluxo de reconciliação de governança GitHub na Wiki. |
| **`test_scripts_readme_and_troubleshooting_links.sh`** | Issue #602 | Ausência de links locais `file://` em `scripts/README.md` e alinhamento dos contratos CLI com a documentação de troubleshooting. |
| **`test_wiki_structure_and_links.sh`** | Issue #27 | Existência de todas as páginas canônicas (incluindo `docs/skills/` e `docs/tests/`), **zero links quebrados**, conformidade de `wiki-sync.yml` e `PROJECT_CONTEXT.md`. |
| **`test_wiki_update_documentation.sh`** | Update Docs | Validação da documentação do mecanismo de atualização e notificação de novas versões do plugin. |

---

## 🔗 Navegação

[← Anterior: Pipeline & Maestro](Test-pipeline) | [Sumário de Testes](Tests-Catalog) | [Próxima Categoria: UI/UX & Mockups →](Test-ui-ux)
