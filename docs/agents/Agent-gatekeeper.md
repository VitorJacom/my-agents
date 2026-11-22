[← Voltar ao Sumário de Subagentes](Subagents)

# 🤖 Subagente: `gatekeeper` (*The Goldfish*)

> **Definição Canônica**: [`agents/gatekeeper/agent.md`](https://github.com/VitorJacom/my-agents/blob/main/agents/gatekeeper/agent.md)  
> **Fase AIDD**: Planejamento ([`plan-feature`](Skill-plan-feature) — Estado 2.5) & Finalização ([`issue-pipeline`](Skill-issue-pipeline) — Estado 4)  
> **Ferramentas (`tools`)**: `read_file`, `write_file`, `edit_file`, `run_command`  
> **Confinamento**: Auditoria, geração de `walkthrough.md`, commits padronizados e abertura de Pull Request

---

## 🎯 Missão

Atuar como o **portão final de integridade** do ecossistema ([`AIDD-Manifesto`](AIDD-Manifesto)) em dois papéis complementares: auditoria fria de especificações (**The Goldfish Reviewer**) e guardião anti-fraude/finalizador de Pull Requests (**Modo 2**), com travas verificadas continuamente por [`Test-governance`](Test-governance).

---

## 🔄 Os Dois Modos de Operação

### Modo 1 — Auditoria de Especificação (*The Goldfish Reviewer* / Cold Audit)
- Opera sem estado prévio (*stateless*), avaliando o `planning_proposal.md` pelo teste do **olhar frio**.
- **Interface Contract Gate**: Rejeita imediatamente (`SPEC_AUDIT: REJECTED`) planos sem `## Interface Contract` explícito ou com termos vagos/placeholders.
- **Bloqueio de Atomicidade**: Rejeita qualquer issue com mais de **3 passos**.
- **Bloqueio Anti-Premissas**: Rejeita premissas implícitas ou especulativas ("supõe-se", "obviamente", "deve funcionar").
- Controla o loop de auto-healing com teto rígido de **2 iterações** antes de disparar o Circuit Breaker.

### Modo 2 — Auditoria de Código, Golden Rule & PR
- **Golden Rule Anti-Fraude (`--diff-filter=MD`)**:
  ```bash
  MODIFIED=$(git diff --diff-filter=MD --name-only origin/main...HEAD 2>/dev/null | grep -E '^tests/core/' || true)
  if [ -n "$MODIFIED" ]; then
    echo "ALERTA DE FRAUDE: O agente modificou ou removeu arquivos protegidos em tests/core/!"
    exit 1
  fi
  ```
  Bloqueia modificações (`M`) e remoções (`D`) em [`tests/core/`](Test-core), permitindo adições legítimas (`A`) promovidas via [`promote-core-test.sh`](Script-pipeline).
- **Auditoria Visual & Wiki**: Quando `UI_UX_REQUIRED: true`, exige parecer `VISUAL_AUDIT: APPROVED` do [`uiux-designer`](Agent-uiux-designer), URLs canônicas `raw.githubusercontent.com` na tabela comparativa e atualização de `Implemented-Screens-Catalog`.
- **Relatório `walkthrough.md` & PR**: Seguindo a skill [`git-workflow`](Skill-git-workflow), compila logs reais de testes, cobertura $\ge 85\%$, `git status`, `Fixes #<id>` em texto puro e abre o PR com `gh pr create --body-file walkthrough.md`.

---

## 🔗 Navegação

[← Anterior: `coder`](Agent-coder) | [Sumário de Subagentes](Subagents)
