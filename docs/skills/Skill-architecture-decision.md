[← Voltar ao Sumário de Skills](Skills-Catalog)

# Skill: `architecture-decision` (Registros de Decisão de Arquitetura — ADRs)

> **Definição Canônica**: [`skills/architecture-decision/SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/architecture-decision/SKILL.md)  
> **Categoria**: Engenharia, Arquitetura & Infra  
> **Comando de Invocação**: Invocação contextual ao registrar escolhas técnicas e trade-offs

---

## 🎯 Objetivo

A skill **`architecture-decision`** padroniza a elaboração de **Architecture Decision Records (ADRs)** seguindo o template clássico de **Michael Nygard**, preservando o contexto histórico, alternativas descartadas e trade-offs assumidos em escolhas estruturais de software — utilizada frequentemente pelo [`system-architect`](Agent-system-architect) durante a esteira [`plan-feature`](Skill-plan-feature).

---

## ⚡ Quando Acionar (*Progressive Disclosure*)

- Ao introduzir ou trocar banco de dados, mensageria, cache ou bibliotecas fundamentais.
- Ao definir padrões de comunicação entre serviços (REST vs. gRPC vs. GraphQL).
- Ao adotar mudanças estruturais de arquitetura (ex.: Git Worktrees para concorrência, Monólito Modular vs. Microsserviços), documentadas também em [`System-Architecture`](System-Architecture).

---

## 🚀 Exemplos de Invocação

```text
Crie uma ADR documentando a escolha de SQLite para cache local
Registre uma ADR sobre a adoção de Concurrent Fork sob Interface Contract
```

---

## 📄 Estrutura Canônica (Template Michael Nygard)

Os registros são mantidos em `docs/adr/XXXX-titulo-curto.md` ou consolidados em [`docs/ARCHITECTURE.md`](ARCHITECTURE), sempre concisos (1 a 2 páginas):

```markdown
# [Número]. [Título Curto da Decisão]

* Status: [Proposta | Aceita | Rejeitada | Substituída por ADR-XXXX]
* Data: [AAAA-MM-DD]
* Decisores: [Nomes / Agente]

## Contexto
Problema ou necessidade técnica, limitações e requisitos que motivaram a decisão.

## Decisão
Solução técnica escolhida e como será implementada.

## Alternativas Consideradas
- **Alternativa A**: Descrição e motivos pelos quais foi descartada.
- **Alternativa B**: Descrição e motivos pelos quais foi descartada.

## Consequências
### Positivas
- Vantagens obtidas, ganhos de escala, manutenibilidade ou performance.
### Negativas / Riscos (Trade-offs)
- Complexidade adicional, custos ou limitações futuras conhecidas.
```

---

## 🔗 Navegação

[← Anterior: `git-workflow`](Skill-git-workflow) | [Sumário de Skills](Skills-Catalog) | [Próxima Skill: `docker-dev` →](Skill-docker-dev)
