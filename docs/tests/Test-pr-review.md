[← Voltar ao Sumário de Testes](Tests-Catalog)

# 🔍 Testes: Revisão de PR & Telemetria (`tests/features/*.sh`)

> **Diretório**: [`tests/features/`](https://github.com/VitorJacom/my-agents/tree/main/tests/features) *(raiz de features)*  
> **Quantidade**: 5 suítes  
> **Comando**: `./tests/run.sh --filter "pr_|review_pr|token"`

---

## 🎯 Propósito da Camada

Valida a esteira determinística de revisão de Pull Requests ([`/review-pr`](Skill-review-pr)) de ponta a ponta — extração de diff, verificação anti-fraude da *Golden Rule*, submissão de pareceres, geração de issues rastreadas com governança — além do auditor de eficiência de tokens e telemetria do pipeline.

---

## 📋 Suítes da Categoria (5)

| Suíte | Origem | O que Valida |
| :--- | :--- | :--- |
| **`test_audit_token_efficiency.sh`** | Issue #49 | Auditoria de eficiência de tokens e telemetria da esteira, garantindo *Zero Token Waste* e detecção de bloat em contextos. |
| **`test_pr_auditor.sh`** | Issue #51 | Subcomandos `fetch-diff` e `audit-integrity` de `scripts/pr-reviewer.sh`, incluindo Circuit Breaker (exit code 3) em alterações na zona protegida `tests/core/`. |
| **`test_pr_review_submission.sh`** | Issue #52 | Submissão determinística de pareceres de code review (`submit-review` com `approve`, `request-changes`, `comment` e `--dry-run`). |
| **`test_pr_issue_generator.sh`** | Issue #53 | Geração automática de issues rastreadas no backlog (`create-issues`) com labels semânticas (`type:fix`, `type:refactor`, `source:code-review`), vínculo de PR/SHA e reconciliação. |
| **`test_review_pr_skill.sh`** | Issue #54 | Orquestrador da skill [`review-pr`](Skill-review-pr) em 5 fases com Gate de Validação Humana mandatório antes de qualquer mutação remota. |

---

## 🔗 Navegação

[← Anterior: UI/UX & Mockups](Test-ui-ux) | [Sumário de Testes](Tests-Catalog) | [Próxima Categoria: Statusline & Performance →](Test-statusline)
