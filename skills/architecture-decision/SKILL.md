---
name: architecture-decision
description: >-
  Padronização e elaboração de registros de decisões de arquitetura (ADRs - Architecture Decision Records)
  para documentar escolhas técnicas e trade-offs.
---

# Architecture Decision Records (ADR)

Esta Skill orienta o registro formal de decisões de arquitetura e design de software tomadas no projeto, permitindo rastrear o contexto e os trade-offs ao longo do tempo.

## 1. Localização e Nomenclatura

Os registros devem ser mantidos no diretório `docs/adr/` (ou `doc/adr/`), numerados sequencialmente:
- `docs/adr/0001-escolha-do-banco-de-dados.md`
- `docs/adr/0002-adotando-autenticacao-jwt.md`

---

## 2. Estrutura Padrão (Template Michael Nygard)

Cada arquivo de ADR deve seguir a estrutura:

```markdown
# [Número]. [Título Curto da Decisão]

* Status: [Proposta | Aceita | Rejeitada | Substituída por ADR-XXXX]
* Data: [AAAA-MM-DD]
* Decisores: [Nomes / Agente]

## Contexto
Qual é o problema ou necessidade técnica que motivou essa decisão? Quais eram as limitações existentes, requisitos de negócio ou gargalos atuais?

## Decisão
Qual solução técnica foi escolhida? Descreva de forma objetiva como será implementada.

## Alternativas Consideradas
- **Alternativa A**: Descrição e motivos pelos quais não foi escolhida.
- **Alternativa B**: Descrição e motivos pelos quais não foi escolhida.

## Consequências

### Positivas
- Vantagens obtidas, ganhos de escala, facilidade de manutenção ou performance.

### Negativas / Riscos (Trade-offs)
- Complexidade adicional introduzida, custos de infraestrutura ou limitações futuras conhecidas.
```

---

## 3. Diretrizes de Uso

- **Quando criar um ADR**:
  - Mudança ou introdução de banco de dados, mensageria ou libs fundamentais.
  - Definição do padrão de comunicação entre serviços (ex: REST vs gRPC vs GraphQL).
  - Mudança estrutural de paradigma ou arquitetura (ex: Monolito modular vs Microserviços).
- **Consistência**: Mantenha as decisões concisas (1 a 2 páginas no máximo).
