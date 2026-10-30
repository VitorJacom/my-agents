---
name: plan-feature
description: >-
  Orquestra o ciclo completo de planejamento e design de software via GitHub (AIDD):
  Product Owner (Requisitos & Valor) ➔ System Architect (Impacto Técnico, ADR & Atomicidade) ➔ Gate de Aprovação ➔ Criação das Issues no GitHub.
---

# Feature Planning Pipeline (`/plan-feature`)

Esta Skill gerencia a esteira de planejamento e design de software no GitHub, decompondo ideias, refinando issues existentes e estruturando ADRs antes de qualquer linha de código ser escrita.

## 🚀 Como Invocar
```text
/plan-feature <ideia, descrição de funcionalidade, issue existente #XX ou decisão técnica>
```

---

## 🔄 Máquina de Estados de Planejamento

```text
[Entrada: Ideia / Épico / Issue #XX]
            │
            ▼
┌──────────────────────────────┐
│     1. Product Owner         │  (Define Personas, Casos de Uso e Critérios de Aceite)
└──────────────┬───────────────┘
               │  Produz: Especificação Funcional & Fatiamento de Valor
               ▼
┌──────────────────────────────┐
│     2. System Architect      │  (Mapeia código em src/, cria ADR e garante atomicidade <= 3 passos)
└──────────────┬───────────────┘
               │  Produz: planning_proposal.md
               ▼
┌──────────────────────────────┐
│     3. Gate de Aprovação     │  (Apresenta ao Dev para revisão interativa)
└──────────────┬───────────────┘
               │  [Dev Aprova]
               ▼
┌──────────────────────────────┐
│     4. Criação no GitHub     │  (Executa gh issue create para cada task fatiada)
└──────────────┬───────────────┘
               │  Produz: Issues vinculadas prontas para /run-issue
               ▼
         [ Handoff Final ]
```

---

## 📋 Protocolo de Execução por Estado

### 📍 ESTADO 1: DESCOBERTA FUNCIONAL (Product Owner)
1. Invoque o subagente `product-owner` via `invoke_subagent`:
   - Envie a descrição do requisito ou o número da Issue (#XX).
   - O PO analisa a dor do negócio, define personas e redige os critérios de aceite em formato Gherkin (`Dado / Quando / Então`) ou checklist verificável.
2. Aguarde a conclusão da especificação funcional.

### 📍 ESTADO 2: DESIGN TÉCNICO & ATOMICIDADE (System Architect)
1. Invoque o subagente `system-architect` via `invoke_subagent`:
   - Envie a especificação funcional do PO e o contexto do repositório (`PROJECT_CONTEXT.md`).
   - O Arquiteto mapeia quais módulos em `src/` serão alterados ou criados.
   - Caso haja escolha de design ou biblioteca, cria o ADR em `docs/adr/`.
   - **Regra de Atomicidade AIDD**: Cada issue gerada DEVE ter no máximo **3 passos concretos** para execução posterior em TDD.
   - Compila o artefato mestre `planning_proposal.md`.
2. Aguarde o retorno com o plano consolidado.

### 📍 ESTADO 3: GATE DE REVISÃO & APROVAÇÃO HUMANA
1. Apresente o `planning_proposal.md` ao desenvolvedor utilizando `write_file` com `RequestFeedback: true`.
2. O desenvolvedor revisa:
   - Se solicitar ajustes: reinvoque o subagente correspondente.
   - Se aprovar: avance para o **ESTADO 4**.

### 📍 ESTADO 4: CRIAÇÃO DETERMINÍSTICA NO GITHUB
1. Para cada issue fatiada no plano aprovado, execute o comando CLI do GitHub:
   ```bash
   gh issue create \
     --title "feat(<escopo>): <título da task atômica>" \
     --label "enhancement,planned" \
     --body "<descrição_completa_com_critérios_de_aceite_e_referência_ao_triângulo_AIDD>"
   ```
2. Caso seja um Épico, vincule as sub-issues criadas à issue principal utilizando a flag `--parent <numero_do_epico>` (se suportado pelo repositório) ou adicione a checklist de links na descrição do Épico.
3. Apresente ao desenvolvedor o sumário com os links de todas as Issues criadas no GitHub, prontas para serem executadas com `/run-issue #<numero>`.
