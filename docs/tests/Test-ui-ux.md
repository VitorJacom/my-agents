[← Voltar ao Sumário de Testes](Tests-Catalog)

# 🎨 Testes: UI/UX & Mockups (`tests/features/ui-ux/`)

> **Diretório**: [`tests/features/ui-ux/`](https://github.com/VitorJacom/my-agents/tree/main/tests/features/ui-ux)  
> **Quantidade**: 7 suítes  
> **Comando**: `./tests/run.sh --category ui-ux`

---

## 🎯 Propósito da Camada

Valida todo o ecossistema visual *Figma-less* do `my-agents`: o protocolo **Mockup-as-Code** em 3 camadas, a integração condicional do `uiux-designer` nos pipelines `/plan-feature` e `/run-issue`, o **Visual Audit Gate** headless, a tabela de comparação visual em PRs e a integridade da skill [`ui-ux-design`](Skill-ui-ux-design) (48 técnicas, 7 módulos e CLI `skill_assistant.py`).

---

## 📋 Suítes da Categoria (7)

| Suíte | Origem | O que Valida |
| :--- | :--- | :--- |
| **`test_issue_pipeline_uiux_gate.sh`** | Issue #15 | Integração do `## Visual & UI/UX Contract` e do *Visual Audit Gate* (Estado 3.5) na esteira `/run-issue`. |
| **`test_issue_pipeline_visual_comparison.sh`** | Issue #33 | Comparação visual lado a lado (*Mockup vs. Implementado*) e validação de Living Mockups no `walkthrough.md` e PRs. |
| **`test_mockup_living_specs_structure.sh`** | Issue #31 | Estrutura do catálogo `docs/mockups/README.md`, template canônico `docs/mockups/TEMPLATE.md` e convenção de assets. |
| **`test_plan_feature_living_mockups.sh`** | Issues #32 & #81 | Persistência de Living Mockups em `docs/mockups/<slug>.md`, publicação de assets na branch `aidd-assets` e embedding visual nas issues. |
| **`test_plan_feature_uiux_state.sh`** | Issue #14 | Estado condicional `1.5` (`UI_UX_REQUIRED: YES/NO`) do `uiux-designer` na máquina de estados do `/plan-feature` (*Zero Token Waste* quando backend). |
| **`test_skill_ui_ux_design.sh`** | Issue #17 | Integridade dos 7 módulos temáticos, 48 técnicas, carregamento progressivo e comandos do assistente CLI `skill_assistant.py`. |
| **`test_uiux_mockup_protocol.sh`** | Issue #13 | Protocolo *Mockup-as-Code* em 3 camadas (Spatial Blueprint ASCII, Design Tokens com Value Contrast $\ge$ 2:1 / WCAG AA $\ge$ 4.5:1 e captura headless). |

---

## 🔗 Navegação

[← Anterior: Wiki & Documentação](Test-wiki) | [Sumário de Testes](Tests-Catalog) | [Próxima Categoria: Revisão de PR & Telemetria →](Test-pr-review)
