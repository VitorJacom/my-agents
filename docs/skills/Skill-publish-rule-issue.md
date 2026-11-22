[← Voltar ao Sumário de Skills](Skills-Catalog)

# Skill: `publish-rule-issue` (Publicação Global de Regras)

> **Definição Canônica**: [`skills/publish-rule-issue/SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/publish-rule-issue/SKILL.md)  
> **Categoria**: Engenharia, Arquitetura & Infra  
> **Comando de Invocação**: `/publish-rule-issue` (ou pós-ciclo de `/learn`)

---

## 🎯 Objetivo

A skill **`publish-rule-issue`** fecha o ciclo de aprendizado contínuo do ecossistema AIDD: quando um desenvolvedor corrige um comportamento ou descobre um novo padrão via `/learn` em **qualquer projeto**, ela publica uma issue estruturada e atômica diretamente no repositório central `VitorJacom/my-agents`.

---

## ⚡ Quando Acionar (*Progressive Disclosure*)

- **Pós-Learn**: Automaticamente oferecida ao final de um ciclo de `/learn` para globalizar a regra aprendida.
- **Sob Demanda**: Quando o desenvolvedor solicita explicitamente o registro de uma nova regra ou melhoria no `my-agents`.

---

## 🚀 Exemplos de Invocação

```text
/publish-rule-issue
Publique a regra aprendida nesta sessão no repositório central my-agents
```

---

## 🔄 Procedimento de Execução

1. **Coleta de Evidências**: Inspeciona o `learning_proposal.md` ou a sessão atual para extrair:
   - Projeto de origem, gatilho/situação, causa-raiz e texto/diff da regra proposta.
2. **Formatação Atômica da Issue**: Gera um corpo padronizado contendo:
   - `## 📌 Contexto de Origem`, `## 🔍 Causa-Raiz & Racional Técnico`, `## 📝 Regra Proposta / Aprendizado`
   - `## 🎯 Escopo Recomendado no my-agents` (`rules/AGENTS.md`, `skills/` ou `hooks.json`)
   - `## Target Files & Dependencies` e `## Passos de Implementação (<= 3 passos)`
3. **Abertura no GitHub (`gh CLI`)**:
   ```bash
   gh issue create --repo VitorJacom/my-agents \
     --title "feat(rules): <título no imperativo>" \
     --label "enhancement,planned" \
     [--milestone "<milestone>"] --body "<corpo>"
   ```
4. **Governança no Project v2 (Fallback Resiliente)**: Vincula automaticamente ao GitHub Project v2 (`gh project item-add`) e atribui o campo `Release` sem bloquear a esteira em caso de falha de rede.

---

## 📦 Artefatos Produzidos

- Issue pronta para execução imediata no `my-agents` via [`/run-issue`](Skill-issue-pipeline).

---

## 🔗 Navegação

[← Anterior: `game-dev-patterns`](Skill-game-dev-patterns) | [Sumário de Skills](Skills-Catalog) | [Próxima Skill: `ui-ux-design` →](Skill-ui-ux-design)
