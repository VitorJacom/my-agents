---
name: ui-ux-design
description: Hub executivo de UI/UX para agentes de IA com 48 técnicas avançadas de design, engenharia de movimento (Apple & Emil Kowalski), receitas prontas de animação, vocabulário reverso, regras canônicas em 10 categorias, checklist pré-entrega e assistente CLI de auditoria automatizada.
---

# UI/UX Design Skill: Hub Executivo & Roteador de Decisão para IA

Esta skill capacita agentes de inteligência artificial a projetar, refatorar e auditar interfaces com rigor estético, precisão cinemática e psicologia cognitiva de alto nível. O acervo é composto por **48 técnicas consolidadas**, **7 módulos temáticos**, **13 referências técnicas profundas** e um **assistente CLI automatizado** para inspeção, geração de receitas e auditoria de código em tempo real.

---

## 1. Protocolo Operacional para Agentes de IA

Para maximizar a eficiência cognitiva e preservar o orçamento de tokens da conversa, siga o protocolo de **Carregamento Progressivo (Progressive Loading)**:

```
[Prompt do Usuário / Tarefa de UI]
               │
               ▼
   1. Consulte a MATRIZ DE DECISÃO SITUACIONAL (Seção 2)
               │
               ▼
   2. Execute o ASSISTENTE CLI para busca rápida, receitas ou regras (Seção 3)
      Ex: python3 skills/ui-ux-design/scripts/skill_assistant.py recipe button
      Ex: python3 skills/ui-ux-design/scripts/skill_assistant.py checklist --type pre-delivery
               │
               ▼
   3. Carregue EXCLUSIVAMENTE o módulo correspondente (Seção 4)
      Ex: view_file skills/ui-ux-design/modules/01-motion-and-physics.md
               │
               ▼
   4. Consulte a REFERÊNCIA TÉCNICA apenas se precisar de código exaustivo (Seção 7)
```

> [!IMPORTANT]
> **Nunca carregue todos os módulos de uma vez.** Identifique o contexto do usuário (mobile, landing page, refatoração de slop, e-commerce, animação) e leia apenas o módulo temático necessário.

---

## 2. Matriz de Decisão Situacional

Consulte esta tabela para mapear a demanda do usuário ao módulo exato e suas técnicas primárias:

| Cenário de Interface / Problema do Usuário | Módulo Indicado | Técnicas Chave | Referência Técnica |
|---|---|---|---|
| **Animações, transições, física de molas, receitas prontas, WWDC & Emil Kowalski** | [Módulo 01: Física de Movimento](modules/01-motion-and-physics.md) | T06, T07, T08, T09, T10 | [animation-recipes.md](references/animation-recipes.md) • [building-animations-philosophy.md](references/building-animations-philosophy.md) |
| **Interface mobile, bottom bar, safe area, gestos táteis, checklist pré-entrega** | [Módulo 03: Navegação Mobile](modules/03-mobile-and-navigation.md) | T14, T19, T24, T25, T26, T27, T28 | [mobile-navigation-bottom-bar-ux.md](references/mobile-navigation-bottom-bar-ux.md) • [professional-ui-and-pre-delivery-checklist.md](references/professional-ui-and-pre-delivery-checklist.md) |
| **Limpeza de código gerado por IA, remoção de card-bloat, visual genérico** | [Módulo 02: Anti-Slop & Refatoração](modules/02-anti-slop-refactoring.md) | T11, T13, T29, T30, T31, T32, T37, T39, T41 | [refactoring-ai-ui-heuristics.md](references/refactoring-ai-ui-heuristics.md) |
| **Página de Produto (PDP), e-commerce, checkout, pós-compra** | [Módulo 04: E-Commerce & Conversão](modules/04-ecommerce-conversion.md) | T03, T04, T15, T16, T17, T18, T20 | [ecommerce-mobile-conversion-ux.md](references/ecommerce-mobile-conversion-ux.md) |
| **Telas de assinatura, paywalls, planos SaaS, reserva de diárias** | [Módulo 05: Preços & Paywalls](modules/05-pricing-and-paywalls.md) | T21, T22, T23 | [pricing-paywalls-booking-ux.md](references/pricing-paywalls-booking-ux.md) |
| **Hero section, landing page de lançamento, proposta de valor** | [Módulo 06: Landing Pages & Hero](modules/06-landing-pages-hero.md) | T44, T45, T46, T47, T48 | [landing-page-narrative-and-hero-architecture.md](references/landing-page-narrative-and-hero-architecture.md) |
| **Dashboards densos, onboarding adaptativo, microcopy, busca vazia, alvenaria** | [Módulo 07: Decisão & Adaptabilidade](modules/07-adaptive-decision-ux.md) | T01, T02, T05, T12, T33, T35, T36, T40, T42, T43 | [ai-slop-purge-and-refinement-cycle.md](references/ai-slop-purge-and-refinement-cycle.md) |
| **Auditoria abrangente em 10 categorias (A11y, Performance, Forms, Nav, Charts)** | Todos os Módulos | Regras Canônicas | [full-ruleset-10-categories.md](references/full-ruleset-10-categories.md) |

---

## 3. Assistente CLI Integrado (`skill_assistant.py`)

Para acelerar inspeções sem poluir a memória, o agente dispõe do utilitário [skill_assistant.py](scripts/skill_assistant.py). Pode ser chamado via ferramenta de comando (`run_command`):

### Comandos Disponíveis:
```bash
# 1. Listar todos os 7 módulos e 48 técnicas:
python3 skills/ui-ux-design/scripts/skill_assistant.py list

# 2. Pesquisar técnica por palavra-chave (ex: "spring", "paywall", "safe-area"):
python3 skills/ui-ux-design/scripts/skill_assistant.py search "spring"

# 3. Exibir o conteúdo completo de um módulo específico (1 a 7):
python3 skills/ui-ux-design/scripts/skill_assistant.py module 1

# 4. Obter fórmulas físicas e parâmetros de movimento (Apple & CSS Tokens):
python3 skills/ui-ux-design/scripts/skill_assistant.py formulas

# 5. Obter implementação pronta de receita de animação:
# Nomes: button, popover, tooltip, modal, drawer, toast, accordion, stagger, hold-to-confirm, tab-clip, scroll-reveal, drag, crossfade, waapi
python3 skills/ui-ux-design/scripts/skill_assistant.py recipe button

# 6. Consultar termo no glossário reverso de animação (reverse-lookup):
python3 skills/ui-ux-design/scripts/skill_assistant.py vocab "rubber-banding"

# 7. Consultar regras canônicas por categoria (a11y, touch, performance, style, layout, typography, animation, forms, nav, charts):
python3 skills/ui-ux-design/scripts/skill_assistant.py rules a11y

# 8. Gerar checklist de validação situacional:
# Tipos: pdp, mobile-nav, paywall, landing-page, dashboard, motion, pre-delivery, general
python3 skills/ui-ux-design/scripts/skill_assistant.py checklist --type pre-delivery

# 9. Auditar arquivo de código contra AI Slop e regras Never Ship:
python3 skills/ui-ux-design/scripts/skill_assistant.py audit src/components/ProductCard.tsx
```

---

## 4. Estrutura dos 7 Módulos de Domínio

### [Módulo 01: Física de Movimento, Molas & Interação Fluida (Apple Standards)](modules/01-motion-and-physics.md)
*Física cinemática, modelos da WWDC, padrão Emil Kowalski, tokens canônicos de curvas e regras Never Ship.*
- **T06:** Engenharia de Interfaces Fluidas e Física de Molas (`Apple Fluid Motion & Spring Physics`)
- **T07:** Manipulação Direta e Interrompibilidade Absoluta (`Direct Manipulation & Interruptibility`)
- **T08:** Materiais, Profundidade e Translucidez Funcional (`Functional Materials, Vibrancy & Depth`)
- **T09:** Tipografia Óptica e Escala Proporcional (`Optical Typography & Dynamic Tracking`)
- **T10:** Fundamentos de Excelência em Design Apple (`Apple 8 Core Design Foundations`)

### [Módulo 02: Anti-Slop, Refatoração de IA & Design System Canônico](modules/02-anti-slop-refactoring.md)
*Purga de clichês gerados por IA, desconstrução de templates óbvios e contenção estrita.*
- **T11:** Identidade Visual Autoral & Anti-Templates (`Distinct Visual Identity & Anti-Templates`)
- **T13:** Processo em Dois Passos & Regra de Chanel (`Two-Pass Planning & Restraint Critique`)
- **T29:** Hierarquia por Espaçamento Plano (`Flat-Canvas Proximity`)
- **T30:** Encapsulamento de Ação Progressiva (`Progressive Action Compaction`)
- **T31:** Contenção Estrutural Invisível (`Borderless Division`)
- **T32:** Afinação Cromática Direcionada (`Color Anchoring Focus`)
- **T34:** Concisão de Cabeçalho Contextual (`Zero-Redundancy Subheadings`)
- **T37:** Descaracterização de Template Padrão (`Un-Defaulting the System`)
- **T38:** Calibração Fundamental de Design (`Fundamentals-Backed Refinement`)
- **T39:** Contenção Canônica de Design System (`Strict Canonical UI Enforcement`)
- **T41:** Sanitização de Vícios de Slop (`AI Cliché Purge`)

### [Módulo 03: Navegação Mobile, Ergonomia & Bottom Tab Bars](modules/03-mobile-and-navigation.md)
*Ergonomia polegar, limites fisiológicos, safe area de 34px e hitboxes mínimas de 44px.*
- **T14:** Encapsulamento de Navegação Multifundo (`Contrast-Safe Navigation Dock`)
- **T19:** Cabeçalho com Ancoragem Contextual (`Persistent Context Bottom Sheet`)
- **T24:** Hierarquia de Navegação Canônica (`Core-Routing Filter`)
- **T25:** Ancoragem Ergonômica e Isolamento de Gesto (`Safe-Zone Thumb Anchoring`)
- **T26:** Contraste de Duplo Estado (`Dual-State Affordance`)
- **T27:** Separação Estrutural de Plano (`Background Depth Delimitation`)
- **T28:** Microinteração Tátil de Transição (`Fluid Tab Transition`)

### [Módulo 04: E-Commerce, Catálogos & Conversão Mobile (PDP)](modules/04-ecommerce-conversion.md)
*Anatomia de conversão móvel, redução de ansiedade pós-compra e microchips preditivos.*
- **T03:** Rastreio Tranquilizador Pós-Conversão (`Reassurance Timeline UX`)
- **T04:** Grade Semântica Harmonizada (`Cohesive Taxonomy Grid`)
- **T15:** Produto em Isolamento Sistêmico (`Catalog-Aware Product Isolation`)
- **T16:** Tríade de Confiança Imediata (`Title-Rating-Price Triad`)
- **T17:** Sintaxe de Embalagem e Quantidade Autônoma (`Decoupled Spec Title`)
- **T18:** Microchips de Preset Comportamental (`Data-Backed Quantity Presets`)
- **T20:** Botão de Conversão Transparente e Integrado (`Pre-Committed CTA`)

### [Módulo 05: Monetização, Paywalls Transparentes & Reservas Imersivas](modules/05-pricing-and-paywalls.md)
*Despressurização comercial, transparência radical de trials e precificação determinística.*
- **T21:** Cronograma de Transparência Radical (`Transparent Trial Timeline`)
- **T22:** Precificação Determinística e Enquadramento de Conveniência (`Deterministic Rate Anchoring`)
- **T23:** Interface Imersiva de Tranquilização (`Sensory Immersion Booking`)

### [Módulo 06: Landing Pages, Hero Assimétrico & Narrativa de Conversão](modules/06-landing-pages-hero.md)
*Arquitetura de persuasão em 6 atos, quebra assimétrica de dobra e proposta palpável.*
- **T44:** Ancoragem de Valor Tangível (`Clarity-First Value Hook`)
- **T45:** Encadeamento Narrativo Progressivo (`Conversion Argument Sequence`)
- **T46:** Quebra Assimétrica de Dobra (`Off-Grid Hero Depth`)
- **T47:** Diferenciação Hierárquica de Recursos (`Table-Stakes vs Flagship Isolation`)
- **T48:** Assinatura Coesiva Recorrente (`Cross-Page Visual Signature`)

### [Módulo 07: Arquitetura Adaptativa, UX Writing & Heurísticas Cognitivas](modules/07-adaptive-decision-ux.md)
*Onboarding por maturidade, redação ativa, calibração de densidade e ciclo 80/20.*
- **T01:** Arquitetura de Maturidade do Usuário (`User-Stage Adaptive UI`)
- **T02:** Busca Ativa Antecipatória (`Proactive Empty Search`)
- **T05:** Seleção Situacional de Input (`Context-Driven Input Mapping`)
- **T12:** Arquitetura de Microcopy e Redação Ativa (`UX Writing & Action-Oriented Microcopy`)
- **T33:** Anatomia de Navegação Proporcional (`In-Context Tab Switching`)
- **T35:** Prototipagem de Forma Antes do Esquema (`Interface-First Experimentation`)
- **T36:** Convergência por Divergência Multimodelo (`Multi-Model Synthesis`)
- **T40:** Funil de Refinamento Trifásico (`The 80/20 Refinement Cycle`)
- **T42:** Calibração de Densidade Situacional (`Context-Tuned Density`)
- **T43:** Grade Compacta de Preenchimento Contínuo (`Auto-Flow Masonry`)

---

## 5. Índice Mestre das 48 Técnicas

| ID | Nome Canônico da Técnica | Módulo de Destino |
|:---:|:---|:---|
| **T01** | Arquitetura de Maturidade do Usuário (`User-Stage Adaptive UI`) | [Módulo 07](modules/07-adaptive-decision-ux.md) |
| **T02** | Busca Ativa Antecipatória (`Proactive Empty Search`) | [Módulo 07](modules/07-adaptive-decision-ux.md) |
| **T03** | Rastreio Tranquilizador Pós-Conversão (`Reassurance Timeline UX`) | [Módulo 04](modules/04-ecommerce-conversion.md) |
| **T04** | Grade Semântica Harmonizada (`Cohesive Taxonomy Grid`) | [Módulo 04](modules/04-ecommerce-conversion.md) |
| **T05** | Seleção Situacional de Input (`Context-Driven Input Mapping`) | [Módulo 07](modules/07-adaptive-decision-ux.md) |
| **T06** | Engenharia de Interfaces Fluidas e Física de Molas (`Apple Fluid Motion & Spring Physics`) | [Módulo 01](modules/01-motion-and-physics.md) |
| **T07** | Manipulação Direta e Interrompibilidade Absoluta (`Direct Manipulation & Interruptibility`) | [Módulo 01](modules/01-motion-and-physics.md) |
| **T08** | Materiais, Profundidade e Translucidez Funcional (`Functional Materials, Vibrancy & Depth`) | [Módulo 01](modules/01-motion-and-physics.md) |
| **T09** | Tipografia Óptica e Escala Proporcional (`Optical Typography & Dynamic Tracking`) | [Módulo 01](modules/01-motion-and-physics.md) |
| **T10** | Fundamentos de Excelência em Design Apple (`Apple 8 Core Design Foundations`) | [Módulo 01](modules/01-motion-and-physics.md) |
| **T11** | Identidade Visual Autoral & Anti-Templates (`Distinct Visual Identity & Anti-Templates`) | [Módulo 02](modules/02-anti-slop-refactoring.md) |
| **T12** | Arquitetura de Microcopy e Redação Ativa (`UX Writing & Action-Oriented Microcopy`) | [Módulo 07](modules/07-adaptive-decision-ux.md) |
| **T13** | O Processo em Dois Passos & A "Regra de Chanel" (`Two-Pass Planning & Restraint Critique`) | [Módulo 02](modules/02-anti-slop-refactoring.md) |
| **T14** | Encapsulamento de Navegação Multifundo (`Contrast-Safe Navigation Dock`) | [Módulo 03](modules/03-mobile-and-navigation.md) |
| **T15** | Produto em Isolamento Sistêmico (`Catalog-Aware Product Isolation`) | [Módulo 04](modules/04-ecommerce-conversion.md) |
| **T16** | Tríade de Confiança Imediata (`Title-Rating-Price Triad`) | [Módulo 04](modules/04-ecommerce-conversion.md) |
| **T17** | Sintaxe de Embalagem e Quantidade Autônoma (`Decoupled Spec Title`) | [Módulo 04](modules/04-ecommerce-conversion.md) |
| **T18** | Microchips de Preset Comportamental (`Data-Backed Quantity Presets`) | [Módulo 04](modules/04-ecommerce-conversion.md) |
| **T19** | Cabeçalho com Ancoragem Contextual (`Persistent Context Bottom Sheet`) | [Módulo 03](modules/03-mobile-and-navigation.md) |
| **T20** | Botão de Conversão Transparente e Integrado (`Pre-Committed CTA`) | [Módulo 04](modules/04-ecommerce-conversion.md) |
| **T21** | Cronograma de Transparência Radical (`Transparent Trial Timeline`) | [Módulo 05](modules/05-pricing-and-paywalls.md) |
| **T22** | Precificação Determinística e Enquadramento (`Deterministic Rate Anchoring`) | [Módulo 05](modules/05-pricing-and-paywalls.md) |
| **T23** | Interface Imersiva de Tranquilização (`Sensory Immersion Booking`) | [Módulo 05](modules/05-pricing-and-paywalls.md) |
| **T24** | Hierarquia de Navegação Canônica (`Core-Routing Filter`) | [Módulo 03](modules/03-mobile-and-navigation.md) |
| **T25** | Ancoragem Ergonômica e Isolamento de Gesto (`Safe-Zone Thumb Anchoring`) | [Módulo 03](modules/03-mobile-and-navigation.md) |
| **T26** | Contraste de Duplo Estado (`Dual-State Affordance`) | [Módulo 03](modules/03-mobile-and-navigation.md) |
| **T27** | Separação Estrutural de Plano (`Background Depth Delimitation`) | [Módulo 03](modules/03-mobile-and-navigation.md) |
| **T28** | Microinteração Tátil de Transição (`Fluid Tab Transition`) | [Módulo 03](modules/03-mobile-and-navigation.md) |
| **T29** | Hierarquia por Espaçamento Plano (`Flat-Canvas Proximity`) | [Módulo 02](modules/02-anti-slop-refactoring.md) |
| **T30** | Encapsulamento de Ação Progressiva (`Progressive Action Compaction`) | [Módulo 02](modules/02-anti-slop-refactoring.md) |
| **T31** | Contenção Estrutural Invisível (`Borderless Division`) | [Módulo 02](modules/02-anti-slop-refactoring.md) |
| **T32** | Afinação Cromática Direcionada (`Color Anchoring Focus`) | [Módulo 02](modules/02-anti-slop-refactoring.md) |
| **T33** | Anatomia de Navegação Proporcional (`In-Context Tab Switching`) | [Módulo 07](modules/07-adaptive-decision-ux.md) |
| **T34** | Concisão de Cabeçalho Contextual (`Zero-Redundancy Subheadings`) | [Módulo 02](modules/02-anti-slop-refactoring.md) |
| **T35** | Prototipagem de Forma Antes do Esquema (`Interface-First Experimentation`) | [Módulo 07](modules/07-adaptive-decision-ux.md) |
| **T36** | Convergência por Divergência Multimodelo (`Multi-Model Synthesis`) | [Módulo 07](modules/07-adaptive-decision-ux.md) |
| **T37** | Descaracterização de Template Padrão (`Un-Defaulting the System`) | [Módulo 02](modules/02-anti-slop-refactoring.md) |
| **T38** | Calibração Fundamental de Design (`Fundamentals-Backed Refinement`) | [Módulo 02](modules/02-anti-slop-refactoring.md) |
| **T39** | Contenção Canônica de Design System (`Strict Canonical UI Enforcement`) | [Módulo 02](modules/02-anti-slop-refactoring.md) |
| **T40** | Funil de Refinamento Trifásico (`The 80/20 Refinement Cycle`) | [Módulo 07](modules/07-adaptive-decision-ux.md) |
| **T41** | Sanitização de Vícios de Slop (`AI Cliché Purge`) | [Módulo 02](modules/02-anti-slop-refactoring.md) |
| **T42** | Calibração de Densidade Situacional (`Context-Tuned Density`) | [Módulo 07](modules/07-adaptive-decision-ux.md) |
| **T43** | Grade Compacta de Preenchimento Contínuo (`Auto-Flow Masonry`) | [Módulo 07](modules/07-adaptive-decision-ux.md) |
| **T44** | Ancoragem de Valor Tangível (`Clarity-First Value Hook`) | [Módulo 06](modules/06-landing-pages-hero.md) |
| **T45** | Encadeamento Narrativo Progressivo (`Conversion Argument Sequence`) | [Módulo 06](modules/06-landing-pages-hero.md) |
| **T46** | Quebra Assimétrica de Dobra (`Off-Grid Hero Depth`) | [Módulo 06](modules/06-landing-pages-hero.md) |
| **T47** | Diferenciação Hierárquica de Recursos (`Table-Stakes vs Flagship Isolation`) | [Módulo 06](modules/06-landing-pages-hero.md) |
| **T48** | Assinatura Coesiva Recorrente (`Cross-Page Visual Signature`) | [Módulo 06](modules/06-landing-pages-hero.md) |

---

## 6. Cheat Sheet, Parâmetros Físicos & Regras "Never Ship"

### 1. Curvas Canônicas de Easing (Tokens CSS)
```css
:root {
  --ease-out: cubic-bezier(0.23, 1, 0.32, 1);        /* Forte ease-out para entrada de UI */
  --ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);    /* Forte ease-in-out para reposicionamento em tela */
  --ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);     /* Curva de gaveta estilo iOS (Ionic) */
}
```

### 2. Física de Molas (Apple Standards)
- **UI Padrão (Sem Quique):** `damping: 1.0`, `response: 0.35s` (`{ type: "spring", bounce: 0, duration: 0.35 }`).
- **Gesto com Momento (Throw/Flick):** `damping: 0.8`, `response: 0.3s` (`{ type: "spring", bounce: 0.2, duration: 0.3 }`).
- **Inércia iOS:** `(v / 1000) * 0.998 / (1 - 0.998)`.
- **Rubber-Banding:** `(x * d * 0.55) / (d + 0.55 * |x|)`.

### 3. Ergonomia Mobile & Hitbox
- **Hitbox Mínima:** `min-height: 44px; min-width: 44px;` (iOS: 44pt / Android: 48dp).
- **Safe Area Inferior (iOS):** `padding-bottom: env(safe-area-inset-bottom, 34px);`.
- **Espaçamento entre Toques:** Mínimo de 8px / 8dp.
- **Destinos na Bottom Bar:** Estritamente **3 a 5 abas** (máximo absoluto 6).

### 4. A Blacklist do AI Slop & "Never Ship" (Reprovação Automática)
- ❌ **`transition: all`** (nomeie explicitamente as propriedades alteradas).
- ❌ **`scale(0)` em entradas** (inicie em `scale(0.95)` com `opacity: 0`).
- ❌ **`ease-in` em componentes de UI** (use `--ease-out` para respostas rápidas).
- ❌ **Animações em atalhos de teclado ou ações 100+/dia** (mudança instantânea sem animação).
- ❌ **Emojis soltos em cards técnicos ou métricas** (substituir por ícones SVG vetorizados monocromáticos).
- ❌ **Gradientes roxo-azuis genéricos em botões e fundos** (usar contraste tonal deliberado).
- ❌ **Cards dentro de cards** (substituir por espaçamento e proximidade de Gestalt).
- ❌ **`div` fingindo ser botão com `onClick`** (usar `<button>` semântico com estados `:focus-visible`).
- ❌ **Hover sem proteção de ponteiro móvel** (envolver em `@media (hover: hover) and (pointer: fine)`).

---

## 7. Acervo de Referências Técnicas Profundas (13 Documentos)

Documentação técnica exaustiva para consultas avançadas:

### Engenharia de Movimento & Animações
1. [references/animation-recipes.md](references/animation-recipes.md)
   *14 implementações prontas de código: button press, popover, tooltip, modal, drawer, toast, accordion, stagger, drag-to-dismiss, WAAPI.*
2. [references/building-animations-philosophy.md](references/building-animations-philosophy.md)
   *Padrão de engenharia Emil Kowalski, sequência de construção em 7 etapas, filtros de frequência e tabela Never Ship.*
3. [references/animation-vocabulary.md](references/animation-vocabulary.md)
   *Glossário reverso de termos de animação em 12 categorias para converter descrições visuais vagas em nomes técnicos exatos.*
4. [references/apple-design-fluid-interfaces.md](references/apple-design-fluid-interfaces.md)
   *Física de molas WWDC, interrupção fluida, projeção de inércia exponencial e rubber-banding.*

### Auditoria, Qualidade & Regras Canônicas
5. [references/full-ruleset-10-categories.md](references/full-ruleset-10-categories.md)
   *Mais de 150 regras canônicas estruturadas nas 10 categorias oficiais de usabilidade e engenharia de software.*
6. [references/professional-ui-and-pre-delivery-checklist.md](references/professional-ui-and-pre-delivery-checklist.md)
   *Diretrizes rígidas para mobile app nativo/híbrido, disciplina de ícones/contraste e o Checklist Canônico Pré-Entrega.*
7. [references/refactoring-ai-ui-heuristics.md](references/refactoring-ai-ui-heuristics.md)
   *Auditoria heurística, espaçamento plano estilo Linear/Stripe e un-defaulting de bibliotecas.*
8. [references/ai-slop-purge-and-refinement-cycle.md](references/ai-slop-purge-and-refinement-cycle.md)
   *Ciclo de refinamento 80/20, matriz situacional de densidade e CSS auto-flow masonry.*

### Telas Especializadas & Conversão
9. [references/landing-page-narrative-and-hero-architecture.md](references/landing-page-narrative-and-hero-architecture.md)
   *Narrativa de conversão em 6 atos, hero assimétrico off-grid e isolamento de flagships.*
10. [references/distinct-frontend-anti-templates.md](references/distinct-frontend-anti-templates.md)
    *Os 5 clichês de IA, processo em dois passos e a regra de Chanel de restrição visual.*
11. [references/ecommerce-mobile-conversion-ux.md](references/ecommerce-mobile-conversion-ux.md)
    *Anatomia de PDP mobile, docks de navegação com contraste seguro e CTAs pré-comprometidos.*
12. [references/pricing-paywalls-booking-ux.md](references/pricing-paywalls-booking-ux.md)
    *Paywalls com linha do tempo transparente, precificação determinística e reservas sensoriais.*
13. [references/mobile-navigation-bottom-bar-ux.md](references/mobile-navigation-bottom-bar-ux.md)
    *Navegação inferior móvel, ergonomia da safe-area (34px), hitboxes de 44px e duplo estado.*
