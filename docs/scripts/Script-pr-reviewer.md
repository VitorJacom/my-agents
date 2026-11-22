[← Voltar ao Sumário de Scripts](Scripts-Catalog)

> **Revisor de PR & Telemetria**  
> **Diretório**: [`scripts/`](https://github.com/VitorJacom/my-agents/tree/main/scripts) *(raiz)*  
> **Quantidade**: 2 scripts (`pr-reviewer.sh` e wrapper `audit-token-efficiency.py`)

---

## 🎯 Propósito

Disponibiliza os pontos de entrada de alto nível para a esteira determinística de revisão de Pull Requests ([`/review-pr`](Skill-review-pr)) e para a auditoria de eficiência de tokens da execução multiagente — validados continuamente pelas suítes em [`Test-pr-review`](Test-pr-review).

---

## 📋 Catálogo de Scripts (2)

### 1. `scripts/pr-reviewer.sh`
Motor CLI determinístico que implementa as operações automatizadas da skill [`review-pr`](Skill-review-pr):

| Subcomando | Fase `/review-pr` | Função |
| :--- | :--- | :--- |
| **`fetch-diff <#PR>`** | Fase 1 | Valida que a PR está `OPEN`, extrai metadados (autor, head/base, `headRefOid`) e obtém o diff unificado completo. |
| **`audit-integrity <#PR>`** | Fase 2 | Verifica a *Golden Rule* do [`AIDD-Manifesto`](AIDD-Manifesto): se detectar alterações em [`tests/core/`](Test-core), encerra imediatamente com **exit code 3** (Circuit Breaker). |
| **`submit-review <#PR>`** | Fase 5 | Publica o parecer formal na PR (`--body-file`, `--status auto\|approve\|request-changes\|comment`). Suporta `--dry-run`. |
| **`create-issues <#PR>`** | Fase 5 | Cria issues rastreadas no backlog (`--findings-file`) com labels semânticas, vínculo de PR/SHA e reconciliação automática via [`Script-pipeline`](Script-pipeline). Suporta `--dry-run`. |

```bash
# Exemplos de uso
./scripts/pr-reviewer.sh fetch-diff 54
./scripts/pr-reviewer.sh audit-integrity 54
./scripts/pr-reviewer.sh submit-review 54 --body-file parecer.md --status auto --dry-run
./scripts/pr-reviewer.sh create-issues 54 --findings-file findings.md --dry-run
```

### 2. `scripts/audit-token-efficiency.py`
Wrapper de compatibilidade na raiz que delega diretamente para [`scripts/pipeline/audit-token-efficiency.py`](Script-pipeline), permitindo invocação curta para auditoria de transcripts e quality gate de score mínimo (`--min-score 80`).

---

## 🔗 Navegação

[← Anterior: Esteira & Governança AIDD](Script-pipeline) | [Sumário de Scripts](Scripts-Catalog) | [Próxima Categoria: Statusline & Quota CLI →](Script-statusline)
