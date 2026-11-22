[← Voltar ao Sumário de Skills](Skills-Catalog)

# Skill: `ui-ux-design` (Hub Executivo de Interface, Motion & Anti-Slop)

> **Definição Canônica**: [`skills/ui-ux-design/SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/ui-ux-design/SKILL.md)  
> **Categoria**: Domínios Especializados  
> **Comando de Invocação**: Invocação contextual em UI/UX ou via subagente [`uiux-designer`](Agent-uiux-designer)

---

## 🎯 Objetivo

A skill **`ui-ux-design`** é um hub executivo de engenharia de interface para agentes de IA, reunindo **48 técnicas consolidadas**, **7 módulos temáticos**, **13 referências técnicas profundas** (incluindo *Apple WWDC Fluid Interfaces* e padrões de *Emil Kowalski*) e um **assistente CLI automatizado** (`skill_assistant.py`) para busca de receitas, checklists e auditoria anti-slop em tempo real — validada continuamente pela suíte [`Test-ui-ux`](Test-ui-ux).

---

## ⚡ Quando Acionar (*Progressive Disclosure*)

- Automaticamente pelo subagente [`uiux-designer`](Agent-uiux-designer) nos Modos 1 (Concepção & Mockup-as-Code na esteira [`plan-feature`](Skill-plan-feature)) e 2 (Auditoria Visual Headless na esteira [`issue-pipeline`](Skill-issue-pipeline)).
- Ao projetar telas, landing pages, fluxos mobile, e-commerce/PDPs, paywalls ou dashboards.
- Ao refatorar interfaces geradas por IA com clichês visuais (*AI-Slop*) ou calibrar física de animações.

---

## 🚀 Exemplos de Invocação

```text
Audite o arquivo src/components/Hero.tsx contra clichês visuais de IA
Aplique as curvas de mola e easing canônicas no menu lateral
Gere o checklist pré-entrega para nossa navegação mobile
```

---

## 🧭 Os 7 Módulos Temáticos (Carregamento Progressivo)

> [!IMPORTANT]
> Para preservar o orçamento de tokens, o agente **nunca carrega todos os módulos de uma vez** — ele consulta a matriz situacional ou o assistente CLI e carrega apenas o módulo exato da tarefa.

| Módulo | Foco Principal | Técnicas Chave |
| :--- | :--- | :--- |
| **01. Física de Movimento & Molas** | Apple Fluid Motion, interrompibilidade, materiais, tipografia óptica | T06–T10 |
| **02. Anti-Slop & Refatoração IA** | Purga de clichês de IA, *Borderless Division*, *Un-Defaulting*, contenção canônica | T11, T13, T29–T32, T34, T37–T39, T41 |
| **03. Navegação Mobile & Ergonomia** | Bottom Tab Bars, *Safe Area* (34px), hitboxes $\ge$ 44px, contraste duplo | T14, T19, T24–T28 |
| **04. E-Commerce & Conversão (PDP)** | Isolamento de produto, tríade de confiança, presets, timeline pós-compra | T03, T04, T15–T18, T20 |
| **05. Preços, Paywalls & Reservas** | Transparência radical de trials, ancoragem determinística de preços | T21–T23 |
| **06. Landing Pages & Hero** | Narrativa de conversão em 6 atos, quebra assimétrica de dobra | T44–T48 |
| **07. Arquitetura Adaptativa & UX Writing** | Onboarding por maturidade, microcopy ativa, busca vazia antecipatória | T01, T02, T05, T12, T33, T35–T36, T40, T42–T43 |

---

## 🤖 Assistente CLI (`skill_assistant.py`)

```bash
# Listar módulos e 48 técnicas
python3 skills/ui-ux-design/scripts/skill_assistant.py list

# Buscar técnica ou termo no vocabulário reverso
python3 skills/ui-ux-design/scripts/skill_assistant.py search "spring"
python3 skills/ui-ux-design/scripts/skill_assistant.py vocab "rubber-banding"

# Obter receitas prontas de animação e fórmulas físicas
python3 skills/ui-ux-design/scripts/skill_assistant.py recipe button
python3 skills/ui-ux-design/scripts/skill_assistant.py formulas

# Consultar regras canônicas (a11y, touch, performance, layout, etc.) e checklists
python3 skills/ui-ux-design/scripts/skill_assistant.py rules a11y
python3 skills/ui-ux-design/scripts/skill_assistant.py checklist --type pre-delivery

# Auditar arquivo contra AI-Slop e regras Never Ship
python3 skills/ui-ux-design/scripts/skill_assistant.py audit src/components/ProductCard.tsx
```

---

## 📦 Artefatos Produzidos

- Especificações vivas (*Living Specs*) em `docs/mockups/<slug>.md` e capturas em `docs/assets/mockups/<slug>.png`.
- Relatórios de auditoria anti-slop e checklists determinísticos pré-entrega.

---

## 🔗 Navegação

[← Anterior: `publish-rule-issue`](Skill-publish-rule-issue) | [Sumário de Skills](Skills-Catalog)
