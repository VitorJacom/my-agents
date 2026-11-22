[← Voltar ao Sumário de Skills](Skills-Catalog)

> **Publicação Global de Regras**  
> **Definição Canônica**: [`skills/publish-rule-issue/SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/publish-rule-issue/SKILL.md)  
> **Categoria**: Engenharia, Arquitetura & Infra  
> **Comando de Invocação**: `/publish-rule-issue` (ou pós-ciclo de `/learn`)

---

## 🎯 Objetivo

A skill **`publish-rule-issue`** fecha o ciclo de aprendizado contínuo do ecossistema ([`AIDD-Manifesto`](AIDD-Manifesto)): quando um desenvolvedor corrige um comportamento ou descobre um novo padrão via `/learn` em **qualquer projeto**, ela publica uma issue estruturada e atômica diretamente no repositório central `VitorJacom/my-agents`.

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

| Etapa | O que acontece |
| :--- | :--- |
| **1. Coleta de Evidências** | Analisa a proposta de aprendizado da sessão para extrair projeto de origem, situação gatilho, causa-raiz e a regra recomendada. |
| **2. Formatação Atômica** | Monta a especificação da issue em seções padronizadas (contexto, causa-raiz, escopo em `rules/`, `skills/` ou `hooks`, arquivos-alvo e passos $\le 3$). |
| **3. Abertura no GitHub** | Cria a issue no repositório central `VitorJacom/my-agents` com título padronizado, labels e Milestone correspondente. |
| **4. Governança no Project v2** | Vincula a issue ao quadro do projeto e atribui o campo `Release` (em conjunto com os utilitários de [`Script-pipeline`](Script-pipeline)), operando com fallback resiliente em caso de falha de rede. |

---

## 📦 Artefatos Produzidos

- Issue pronta para execução imediata no `my-agents` via [`/issue-pipeline`](Skill-issue-pipeline).

---

## 🔗 Navegação

[← Anterior: `game-dev-patterns`](Skill-game-dev-patterns) | [Sumário de Skills](Skills-Catalog) | [Próxima Skill: `ui-ux-design` →](Skill-ui-ux-design)
