#!/usr/bin/env python3
"""
UI/UX Skill Assistant & Auditor for AI Agents.

This tool provides programmatic access to the 48 UI/UX techniques,
module catalogs, mathematical formulas, animation recipes, vocabulary glossary,
10-category ruleset, and static code auditing for AI agents implementing or reviewing interfaces.

Usage:
    python3 skill_assistant.py list
    python3 skill_assistant.py search <term>
    python3 skill_assistant.py module <1-7>
    python3 skill_assistant.py checklist [--type pdp|mobile-nav|paywall|landing-page|dashboard|motion|pre-delivery|general]
    python3 skill_assistant.py formulas
    python3 skill_assistant.py recipe [name]
    python3 skill_assistant.py vocab <term>
    python3 skill_assistant.py rules [category]
    python3 skill_assistant.py audit <file_path>
"""

import os
import sys
import re
import json
import argparse
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
MODULES_DIR = BASE_DIR / "modules"
REFERENCES_DIR = BASE_DIR / "references"

MODULE_MAP = {
    1: {
        "title": "Física de Movimento, Molas & Interação Fluida (Apple Standards)",
        "file": "01-motion-and-physics.md",
        "techs": [6, 7, 8, 9, 10],
        "domain": "motion"
    },
    2: {
        "title": "Anti-Slop, Refatoração de IA & Design System Canônico",
        "file": "02-anti-slop-refactoring.md",
        "techs": [11, 13, 29, 30, 31, 32, 34, 37, 38, 39, 41],
        "domain": "anti-slop"
    },
    3: {
        "title": "Navegação Mobile, Ergonomia & Bottom Tab Bars",
        "file": "03-mobile-and-navigation.md",
        "techs": [14, 19, 24, 25, 26, 27, 28],
        "domain": "mobile-nav"
    },
    4: {
        "title": "E-Commerce, Catálogos & Conversão Mobile (PDP)",
        "file": "04-ecommerce-conversion.md",
        "techs": [3, 4, 15, 16, 17, 18, 20],
        "domain": "pdp"
    },
    5: {
        "title": "Monetização, Paywalls Transparentes & Reservas Imersivas",
        "file": "05-pricing-and-paywalls.md",
        "techs": [21, 22, 23],
        "domain": "paywall"
    },
    6: {
        "title": "Landing Pages, Hero Assimétrico & Narrativa de Conversão",
        "file": "06-landing-pages-hero.md",
        "techs": [44, 45, 46, 47, 48],
        "domain": "landing-page"
    },
    7: {
        "title": "Arquitetura Adaptativa, UX Writing & Heurísticas Cognitivas",
        "file": "07-adaptive-decision-ux.md",
        "techs": [1, 2, 5, 12, 33, 35, 36, 40, 42, 43],
        "domain": "dashboard"
    }
}

TECHNIQUES = {
    1: {"name": "Arquitetura de Maturidade do Usuário", "en": "User-Stage Adaptive UI", "module": 7},
    2: {"name": "Busca Ativa Antecipatória", "en": "Proactive Empty Search", "module": 7},
    3: {"name": "Rastreio Tranquilizador Pós-Conversão", "en": "Reassurance Timeline UX", "module": 4},
    4: {"name": "Grade Semântica Harmonizada", "en": "Cohesive Taxonomy Grid", "module": 4},
    5: {"name": "Seleção Situacional de Input", "en": "Context-Driven Input Mapping", "module": 7},
    6: {"name": "Engenharia de Interfaces Fluidas e Física de Molas", "en": "Apple Fluid Motion & Spring Physics", "module": 1},
    7: {"name": "Manipulação Direta e Interrompibilidade Absoluta", "en": "Direct Manipulation & Interruptibility", "module": 1},
    8: {"name": "Materiais, Profundidade e Translucidez Funcional", "en": "Functional Materials, Vibrancy & Depth", "module": 1},
    9: {"name": "Tipografia Óptica e Escala Proporcional", "en": "Optical Typography & Dynamic Tracking", "module": 1},
    10: {"name": "Fundamentos de Excelência em Design Apple", "en": "Apple 8 Core Design Foundations", "module": 1},
    11: {"name": "Identidade Visual Autoral & Anti-Templates", "en": "Distinct Visual Identity & Anti-Templates", "module": 2},
    12: {"name": "Arquitetura de Microcopy e Redação Ativa", "en": "UX Writing & Action-Oriented Microcopy", "module": 7},
    13: {"name": "Processo em Dois Passos & Regra de Chanel", "en": "Two-Pass Planning & Restraint Critique", "module": 2},
    14: {"name": "Encapsulamento de Navegação Multifundo", "en": "Contrast-Safe Navigation Dock", "module": 3},
    15: {"name": "Produto em Isolamento Sistêmico", "en": "Catalog-Aware Product Isolation", "module": 4},
    16: {"name": "Tríade de Confiança Imediata", "en": "Title-Rating-Price Triad", "module": 4},
    17: {"name": "Sintaxe de Embalagem e Quantidade Autônoma", "en": "Decoupled Spec Title", "module": 4},
    18: {"name": "Microchips de Preset Comportamental", "en": "Data-Backed Quantity Presets", "module": 4},
    19: {"name": "Cabeçalho com Ancoragem Contextual", "en": "Persistent Context Bottom Sheet", "module": 3},
    20: {"name": "Botão de Conversão Transparente e Integrado", "en": "Pre-Committed CTA", "module": 4},
    21: {"name": "Cronograma de Transparência Radical", "en": "Transparent Trial Timeline", "module": 5},
    22: {"name": "Precificação Determinística e Enquadramento", "en": "Deterministic Rate Anchoring", "module": 5},
    23: {"name": "Interface Imersiva de Tranquilização", "en": "Sensory Immersion Booking", "module": 5},
    24: {"name": "Hierarquia de Navegação Canônica", "en": "Core-Routing Filter", "module": 3},
    25: {"name": "Ancoragem Ergonômica e Isolamento de Gesto", "en": "Safe-Zone Thumb Anchoring", "module": 3},
    26: {"name": "Contraste de Duplo Estado", "en": "Dual-State Affordance", "module": 3},
    27: {"name": "Separação Estrutural de Plano", "en": "Background Depth Delimitation", "module": 3},
    28: {"name": "Microinteração Tátil de Transição", "en": "Fluid Tab Transition", "module": 3},
    29: {"name": "Hierarquia por Espaçamento Plano", "en": "Flat-Canvas Proximity", "module": 2},
    30: {"name": "Encapsulamento de Ação Progressiva", "en": "Progressive Action Compaction", "module": 2},
    31: {"name": "Contenção Estrutural Invisível", "en": "Borderless Division", "module": 2},
    32: {"name": "Afinação Cromática Direcionada", "en": "Color Anchoring Focus", "module": 2},
    33: {"name": "Anatomia de Navegação Proporcional", "en": "In-Context Tab Switching", "module": 7},
    34: {"name": "Concisão de Cabeçalho Contextual", "en": "Zero-Redundancy Subheadings", "module": 2},
    35: {"name": "Prototipagem de Forma Antes do Esquema", "en": "Interface-First Experimentation", "module": 7},
    36: {"name": "Convergência por Divergência Multimodelo", "en": "Multi-Model Synthesis", "module": 7},
    37: {"name": "Descaracterização de Template Padrão", "en": "Un-Defaulting the System", "module": 2},
    38: {"name": "Calibração Fundamental de Design", "en": "Fundamentals-Backed Refinement", "module": 2},
    39: {"name": "Contenção Canônica de Design System", "en": "Strict Canonical UI Enforcement", "module": 2},
    40: {"name": "Funil de Refinamento Trifásico", "en": "The 80/20 Refinement Cycle", "module": 7},
    41: {"name": "Sanitização de Vícios de Slop", "en": "AI Cliché Purge", "module": 2},
    42: {"name": "Calibração de Densidade Situacional", "en": "Context-Tuned Density", "module": 7},
    43: {"name": "Grade Compacta de Preenchimento Contínuo", "en": "Auto-Flow Masonry", "module": 7},
    44: {"name": "Ancoragem de Valor Tangível", "en": "Clarity-First Value Hook", "module": 6},
    45: {"name": "Encadeamento Narrativo Progressivo", "en": "Conversion Argument Sequence", "module": 6},
    46: {"name": "Quebra Assimétrica de Dobra", "en": "Off-Grid Hero Depth", "module": 6},
    47: {"name": "Diferenciação Hierárquica de Recursos", "en": "Table-Stakes vs Flagship Isolation", "module": 6},
    48: {"name": "Assinatura Coesiva Recorrente", "en": "Cross-Page Visual Signature", "module": 6}
}

RECIPES = {
    "button": """// 1. Button Press Feedback (160ms var(--ease-out))
.button {
  transition: transform 160ms var(--ease-out);
}
.button:active {
  transform: scale(0.97);
}""",
    "popover": """// 2. Dropdown, Popover, Menu, Select
.popover {
  transform-origin: var(--transform-origin);
  transition:
    opacity 200ms var(--ease-out),
    transform 200ms var(--ease-out);
}
.popover[data-starting-style],
.popover[data-ending-style] {
  opacity: 0;
  transform: scale(0.95);
}""",
    "tooltip": """// 3. Tooltip (125ms + instant on neighbours)
.tooltip {
  transform-origin: var(--transform-origin);
  transition:
    transform 125ms var(--ease-out),
    opacity 125ms var(--ease-out);
}
.tooltip[data-starting-style],
.tooltip[data-ending-style] {
  opacity: 0;
  transform: scale(0.97);
}
.tooltip[data-instant] {
  transition-duration: 0ms;
}""",
    "modal": """// 4. Modal (Centered, 250ms var(--ease-out))
.modal {
  transform-origin: center;
  transition:
    opacity 250ms var(--ease-out),
    transform 250ms var(--ease-out);
}
.modal[data-starting-style],
.modal[data-ending-style] {
  opacity: 0;
  transform: scale(0.96);
}
.backdrop {
  transition: opacity 250ms var(--ease-out);
}""",
    "drawer": """// 5. Drawer / Sheet (500ms var(--ease-drawer))
.drawer {
  transform: translateY(0);
  transition: transform 500ms var(--ease-drawer);
}
.drawer[data-closed] {
  transform: translateY(100%);
}""",
    "toast": """// 6. Toast (400ms ease, @starting-style translateY(100%))
.toast {
  opacity: 1;
  transform: translateY(0);
  transition: opacity 400ms ease, transform 400ms ease;
  @starting-style {
    opacity: 0;
    transform: translateY(100%);
  }
}""",
    "accordion": """// 7. Accordion / Collapse (Height layout transition - measure via JS)
.content {
  overflow: hidden;
  transition:
    height 200ms var(--ease-out),
    opacity 200ms var(--ease-out);
}""",
    "stagger": """// 8. Stagger a Group Entrance (Cascading 50ms delays)
.item {
  opacity: 0;
  transform: translateY(8px);
  animation: fadeIn 300ms var(--ease-out) forwards;
}
.item:nth-child(2) { animation-delay: 50ms; }
.item:nth-child(3) { animation-delay: 100ms; }
.item:nth-child(4) { animation-delay: 150ms; }""",
    "hold-to-confirm": """// 9. Hold to Confirm (Destructive actions - 2s linear on press, 200ms ease-out on release)
.overlay {
  clip-path: inset(0 100% 0 0);
  transition: clip-path 200ms var(--ease-out);
}
.button:active .overlay {
  clip-path: inset(0 0 0 0);
  transition: clip-path 2s linear;
}
.button:active {
  transform: scale(0.97);
}""",
    "tab-clip": """// 10. Tab Indicator with Color Transition (Duplicate & Clip-path)
.tabs-active-copy {
  clip-path: inset(0 60% 0 20%);
  transition: clip-path 250ms var(--ease-in-out);
}""",
    "scroll-reveal": """// 11. Scroll Reveal (Marketing only, 600ms ease-in-out)
.reveal {
  clip-path: inset(0 0 100% 0);
  transition: clip-path 600ms var(--ease-in-out);
}
.reveal[data-visible] {
  clip-path: inset(0 0 0 0);
}""",
    "drag": """// 12. Drag to Dismiss (Gesture, flick velocity > 0.11 or distance threshold)
const timeTaken = Date.now() - dragStartTime.current;
const velocity = Math.abs(swipeAmount) / timeTaken;
if (Math.abs(swipeAmount) >= SWIPE_THRESHOLD || velocity > 0.11) {
  dismiss();
}
// Spring config for settling:
// { type: "spring", duration: 0.5, bounce: 0.2 }""",
    "crossfade": """// 13. Masking a Crossfade with Gaussian Blur Seam
.content {
  transition: filter 200ms ease, opacity 200ms ease;
}
.content.transitioning {
  filter: blur(2px);
  opacity: 0.7;
}""",
    "waapi": """// 14. Programmatic WAAPI without external library
element.animate(
  [{ clipPath: 'inset(0 0 100% 0)' }, { clipPath: 'inset(0 0 0 0)' }],
  { duration: 1000, fill: 'forwards', easing: 'cubic-bezier(0.77, 0, 0.175, 1)' }
);"""
}

def cmd_list(args):
    print("=" * 70)
    print("CATÁLOGO DE TÉCNICAS DE UI/UX (MY-AGENTS) — 48 TÉCNICAS")
    print("=" * 70)
    for mod_id, mod in MODULE_MAP.items():
        print(f"\n[Módulo {mod_id:02d}] {mod['title']} ({len(mod['techs'])} técnicas)")
        print(f" Arquivo: modules/{mod['file']}")
        for t_id in mod['techs']:
            t = TECHNIQUES[t_id]
            print(f"   • T{t_id:02d}: {t['name']} ({t['en']})")
    print("\nTotal: 48 técnicas organizadas em 7 módulos de domínio.")

def cmd_search(args):
    query = " ".join(args.term).lower()
    matches = []
    for t_id, t in TECHNIQUES.items():
        if query in t['name'].lower() or query in t['en'].lower() or query in str(t_id):
            matches.append((t_id, t))

    if not matches:
        print(f"Nenhuma técnica encontrada para '{query}'. Buscando no conteúdo dos módulos...")
        for mod_id, mod in MODULE_MAP.items():
            mod_path = MODULES_DIR / mod["file"]
            if mod_path.exists():
                text = mod_path.read_text(encoding="utf-8")
                if query in text.lower():
                    print(f"-> Menção encontrada no Módulo {mod_id:02d} ({mod['file']})")
        return

    print(f"\nResultados da busca por '{query}' ({len(matches)} técnicas encontradas):")
    print("-" * 70)
    for t_id, t in matches:
        mod = MODULE_MAP[t['module']]
        print(f"• T{t_id:02d}: {t['name']} [{t['en']}]")
        print(f"   -> Módulo {t['module']:02d}: modules/{mod['file']}")

def cmd_module(args):
    mod_id = args.id
    if mod_id not in MODULE_MAP:
        print(f"Erro: Módulo inválido ({mod_id}). Escolha de 1 a 7.", file=sys.stderr)
        sys.exit(1)
    mod = MODULE_MAP[mod_id]
    mod_path = MODULES_DIR / mod["file"]
    if mod_path.exists():
        print(mod_path.read_text(encoding="utf-8"))
    else:
        print(f"Erro: Arquivo do módulo não encontrado: {mod_path}", file=sys.stderr)
        sys.exit(1)

def cmd_formulas(args):
    print("=" * 70)
    print("TABELA DE FÓRMULAS & PARÂMETROS FÍSICOS (APPLE & UI ENGINEERING)")
    print("=" * 70)
    print("""
1. Projeção de Inércia (Decaimento Exponencial do iOS):
   function project(initialVelocity, decelerationRate = 0.998) {
       return (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate);
   }

2. Limites Elásticos (Rubber-Banding):
   function rubberband(overshoot, dimension, constant = 0.55) {
       return (overshoot * dimension * constant) / (dimension + constant * Math.abs(overshoot));
   }

3. Molas Apple (Damping & Response):
   - Padrão UI (Criticamente Amortecida): Damping 1.0 | Response 0.3s - 0.4s (bounce: 0)
   - Momento / Flick (Sub-Amortecida):   Damping 0.8 | Response 0.3s - 0.4s (bounce: 0.2)
   - Motion dev: { type: "spring", duration: 0.5, bounce: 0.2 }

4. Curvas Oficiais de Easing (Tokens CSS):
   --ease-out: cubic-bezier(0.23, 1, 0.32, 1);
   --ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);
   --ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);

5. Ergonomia Mobile & Hitbox:
   - Hitbox Mínima: min-width: 44px; min-height: 44px; (iOS: 44pt / Android: 48dp)
   - Safe Area iOS: padding-bottom: env(safe-area-inset-bottom, 34px);
   - Ícone de Barra: 24x24px | Rótulo: 10-12px (linha única)
   - Espaçamento mínimo entre toques: 8px / 8dp

6. Tipografia Óptica (Tracking):
   - Display (>28px): letter-spacing: -0.02em | line-height: 1.05 - 1.15
   - Body (14-18px):  letter-spacing: 0em     | line-height: 1.45 - 1.6
   - Small (<13px):   letter-spacing: +0.015em
""")

def cmd_recipe(args):
    r_name = args.name.lower() if args.name else None
    if not r_name:
        print("=" * 70)
        print("RECEITAS DE ANIMAÇÃO PRONTAS (ANIMATION RECIPES)")
        print("=" * 70)
        print("Receitas disponíveis: " + ", ".join(RECIPES.keys()))
        print("Execute: python3 skill_assistant.py recipe <nome> (ex: button, popover, modal, drawer, toast, drag)")
        return

    if r_name in RECIPES:
        print(f"\nRECEITA DE ANIMAÇÃO: '{r_name.upper()}'")
        print("=" * 70)
        print(RECIPES[r_name])
    else:
        print(f"Erro: Receita '{r_name}' não encontrada. Opções disponíveis: {', '.join(RECIPES.keys())}", file=sys.stderr)
        sys.exit(1)

def cmd_vocab(args):
    query = " ".join(args.term).lower()
    vocab_file = REFERENCES_DIR / "animation-vocabulary.md"
    if not vocab_file.exists():
        print(f"Erro: Glossário não encontrado: {vocab_file}", file=sys.stderr)
        sys.exit(1)

    text = vocab_file.read_text(encoding="utf-8")
    lines = text.splitlines()
    matches = []
    curr_category = "Geral"
    for line in lines:
        if line.startswith("### "):
            curr_category = line.replace("### ", "").strip()
        elif line.startswith("- **") and ":" in line:
            term_part = line.split(":")[0].replace("- **", "").replace("**", "").strip()
            desc_part = ":".join(line.split(":")[1:]).strip()
            if query in term_part.lower() or query in desc_part.lower():
                matches.append((term_part, desc_part, curr_category))

    print(f"\nResultados do Glossário de Animação para '{query}' ({len(matches)} termos):")
    print("=" * 70)
    if not matches:
        print("Nenhum termo exato localizado. Tente palavras como 'spring', 'stagger', 'rubber', 'blur', 'scale'.")
    else:
        for term, desc, cat in matches:
            print(f"• **{term}** [{cat}]")
            print(f"  -> {desc}\n")

def cmd_rules(args):
    cat_query = args.category.lower() if args.category else "all"
    rules_file = REFERENCES_DIR / "full-ruleset-10-categories.md"
    if not rules_file.exists():
        print("Erro: Arquivo de regras não encontrado.", file=sys.stderr)
        sys.exit(1)

    aliases = {
        "a11y": "acessibilidade",
        "accessibility": "acessibilidade",
        "touch": "toque",
        "motion": "animação",
        "animation": "animação",
        "type": "tipografia",
        "typography": "tipografia",
        "nav": "navegação",
        "navigation": "navegação",
        "charts": "gráficos",
        "data": "gráficos",
        "forms": "formulários",
        "style": "estilo",
        "perf": "performance"
    }
    normalized_query = aliases.get(cat_query, cat_query)

    text = rules_file.read_text(encoding="utf-8")
    sections = text.split("## ")
    
    print(f"\nCONSULTA DE REGRAS CANÔNICAS (Categoria: '{cat_query.upper()}')")
    print("=" * 70)
    found = False
    for sec in sections[1:]:
        header = sec.splitlines()[0].strip()
        if normalized_query == "all" or normalized_query in header.lower():
            found = True
            print(f"\n## {header}")
            rules = [l for l in sec.splitlines()[1:] if l.strip().startswith("- `")]
            for r in rules[:8]:
                print(f"  {r}")
            if len(rules) > 8:
                print(f"  ... e mais {len(rules) - 8} regras em references/full-ruleset-10-categories.md")
    if not found:
        print(f"Nenhuma seção encontrada para '{cat_query}'. Categorias disponíveis: a11y, touch, performance, style, layout, typography, animation, forms, nav, charts, all.")

def cmd_checklist(args):
    t = args.type or "general"
    print(f"\nCHECKLIST DE AUDITORIA UI/UX: Tipo '{t.upper()}'")
    print("=" * 70)
    
    checklists = {
        "pdp": [
            "Ícones de navegação sobre imagens possuem contêiner com contraste seguro (dock com blur 12px e borda 1px)?",
            "A imagem do produto está isolada em fundo neutro (#FAFAFA) com sombra de contato calculada?",
            "A Tríade de Confiança (Título, Avaliações e Preço) está unificada no topo sem o rótulo óbvio 'Preço:'?",
            "O peso/volume (kg, ml) está desacoplado do título e confinado ao seletor de porções?",
            "Quantidades habituais possuem microchips de preset comportamental em 1 toque (ex: 500g, 1kg)?",
            "O botão de conversão inferior é fixo, unificado ao stepper e exibe o valor total recalculado em tempo real?"
        ],
        "mobile-nav": [
            "A barra inferior limita-se a 3-5 destinos essenciais sem logos ou botões de voltar?",
            "A Safe Area inferior é respeitada rigorosamente (34px no iOS / env(safe-area-inset-bottom))?",
            "Cada aba possui hitbox invisível de no mínimo 44x44px?",
            "A aba ativa apresenta contraste de duplo estado (ícone preenchido + tipografia semibold/cor primária)?",
            "A barra possui demarcação estrutural (borda superior de 1px, elevação ou contraste tonal)?",
            "As trocas de abas possuem microinteração de toque (:active scale) e transição fluida?"
        ],
        "paywall": [
            "O paywall apresenta cronograma transparente vertical (Hoje R$ 0 -> Dia 5 Alerta -> Dia 7 Cobrança)?",
            "O CTA usa microcopy despressurizada ('Iniciar teste grátis • Comece em 2 toques') em vez de 'Assinar'?",
            "Foram utilizadas capturas reais do produto em vez de ilustrações abstratas vazias?",
            "A política de cancelamento em 1 clique a qualquer momento está explícita e visível?"
        ],
        "landing-page": [
            "A proposta de valor na dobra de entrada foca em clareza, previsibilidade e alívio mental (zero clichês de velocidade)?",
            "A página segue a sequência canônica em 6 etapas com capítulos identificáveis?",
            "A dobra inicial adota layout assimétrico off-grid com 2 cards flutuantes de métricas reais?",
            "A prova social (avatares e nota) está posicionada contiguamente abaixo do CTA principal?",
            "As funcionalidades foram separadas entre table-stakes (3 cards compactos) e o flagship exclusivo (painel amplo)?",
            "A página mantém exatamente duas assinaturas visuais consistentes do topo ao rodapé?"
        ],
        "dashboard": [
            "O layout substituiu caixas elevadas por espaçamento plano e proximidade relacional (Gestalt)?",
            "Ações secundárias de linhas de tabelas foram compactadas em badges ou menus contextuais (...) ?",
            "Divisões dispensaram bordas de linhas excessivas, utilizando whitespace e variações tonais milimétricas?",
            "O uso de cores saturadas é estritamente direcionado para o CTA primário ou erros críticos?",
            "Abas embutidas (inset tabs) são usadas apenas para toggles locais de bloco, nunca para rotas mestras?",
            "Foram eliminados subtítulos redundantes que repetem a ação do título?",
            "A densidade tipográfica e de espaçamento foi compactada para trabalho analítico (13px/14px)?"
        ],
        "motion": [
            "A ação justifica-se nas 4 faixas de frequência (100+/dia: ZERO animação; dezenas/dia: <150ms; ocasional: 200ms)?",
            "Foi eliminada qualquer animação atrelada a atalhos de teclado?",
            "O código utilizou as curvas canônicas (--ease-out, --ease-in-out, --ease-drawer) sem curvas fracas nativas?",
            "Entradas de UI utilizam scale(0.95) a scale(0.97) com opacity: 0 (nunca scale(0))?",
            "As transições afetam exclusivamente 'transform' e 'opacity' aceleradas por GPU?",
            "Transições com arraste e gestos utilizam molas (springs) com amortecimento e momento?",
            "Foi incluído suporte obrigatório a @media (prefers-reduced-motion: reduce)?"
        ],
        "pre-delivery": [
            "[Processo] Testado em 375px e em modo paisagem sem quebras de layout?",
            "[Processo] Verificado comportamento com prefers-reduced-motion e Dynamic Type ativados?",
            "[Processo] Contraste do Dark Mode validado independentemente do Light Mode (texto >= 4.5:1)?",
            "[Visual] Zero emojis usados como ícones estruturais de navegação ou controles de sistema?",
            "[Visual] Família de ícones vetorizada com stroke e raio consistentes?",
            "[Interação] Todo controle clicável oferece feedback visual perceptível em menos de 100ms?",
            "[Interação] Hitbox mínima de 44pt (iOS) / 48dp (Android) respeitada em botões?",
            "[Layout] Safe Area inferior respeitada (padding-bottom: env(safe-area-inset-bottom, 34px))?",
            "[Layout] Ritmo de espaçamento modular 4/8dp mantido do topo ao rodapé?",
            "[Acessibilidade] Ícones decorativos com aria-hidden='true' e ícones isolados com aria-label?",
            "[Acessibilidade] Formulários com labels visíveis e mensagens conectadas via aria-describedby?"
        ],
        "general": [
            "A interface escapa dos 5 clichês de IA (sem terracota automático, sem dark neon clichê, sem broadsheet forçado, sem kit de cards idênticos, sem template chrome)?",
            "O microcopy está em voz ativa, com verbos consistentes (ex: 'Publicar' -> 'Publicado') e em Sentence Case?",
            "Foi aplicada a 'Regra de Chanel', removendo um acessório/decoração supérflua antes da entrega?",
            "A IA utilizou os componentes canônicos oficiais da biblioteca sem inventar divs ou botões ad-hoc ('Zero AI Slop')?",
            "Foram bloqueados overrides arbitrários de estilos, preservando a coerência visual e a acessibilidade original?",
            "Foi executada a sanitização de slop (zero emojis em menus/títulos, zero bordas supérfluas, zero roxos clichê, zero faíscas)?"
        ]
    }

    items = checklists.get(t.lower(), checklists["general"])
    for i, item in enumerate(items, 1):
        print(f"[ ] {i:02d}. {item}")

def cmd_audit(args):
    target = Path(args.file)
    if not target.exists():
        print(f"Erro: Arquivo '{target}' não encontrado.", file=sys.stderr)
        sys.exit(1)

    content = target.read_text(encoding="utf-8", errors="ignore")
    issues = []
    
    # 1. Checagem de Emojis em UI
    emoji_pattern = re.compile(r'[\U00010000-\U0010ffff]|[\u2600-\u27BF]')
    found_emojis = emoji_pattern.findall(content)
    if found_emojis:
        issues.append({
            "severidade": "ALTA",
            "regra": "T41 - AI Cliché Purge & Professional Icon Standard",
            "detalhe": f"Foram detectados {len(found_emojis)} emojis no código (ex: {found_emojis[:3]}). Emojis são proibidos como ícones estruturais. Substitua por ícones vetoriais monocromáticos (Lucide, Heroicons)."
        })

    # 2. Checagem de Gradientes Roxos Clichê de IA
    if re.search(r'(from-purple|to-indigo|from-violet|bg-gradient-to-r.*purple)', content, re.IGNORECASE):
        issues.append({
            "severidade": "MÉDIA",
            "regra": "T41 - AI Cliché Purge (Erradicação de Roxo Genérico)",
            "detalhe": "Detectado gradiente roxo/índigo característico de IA. Substitua por escala neutra e a cor oficial da marca."
        })

    # 3. Checagem de Overuse de Bordas Cinzas
    border_count = len(re.findall(r'border-(gray|slate|zinc)-[23]00', content))
    if border_count > 6:
        issues.append({
            "severidade": "MÉDIA",
            "regra": "T29/T31 - Borderless Division & Flat Canvas",
            "detalhe": f"Detectadas {border_count} bordas cinzas repetitivas. Elimine caixas e use espaçamento (whitespace) ou variações tonais."
        })

    # 4. Checagem de Uppercase Gritante
    if "uppercase" in content:
        issues.append({
            "severidade": "BAIXA",
            "regra": "T11/T42 - Sentence Case vs Screaming Uppercase",
            "detalhe": "Classes 'uppercase' detectadas. Avalie converter rótulos e botões para Sentence Case com peso tipográfico semibold."
        })

    # 5. Checagem de Safe Area em Barras Inferiores Fixas
    if ("fixed" in content and "bottom-0" in content) and ("safe-area" not in content and "env(safe-area" not in content and "pb-" not in content):
        issues.append({
            "severidade": "ALTA",
            "regra": "T25 - Safe-Zone Thumb Anchoring",
            "detalhe": "Barra fixa no rodapé sem reserva de Safe Area detectada. Pode causar disparos acidentais do Home Indicator no iOS. Adicione env(safe-area-inset-bottom, 34px)."
        })

    # 6. Checagem de Divs atuando como Botões (AI Slop)
    div_btn = len(re.findall(r'<div[^>]+onClick', content))
    if div_btn > 0:
        issues.append({
            "severidade": "ALTA",
            "regra": "T39 - Strict Canonical UI Enforcement",
            "detalhe": f"Detectados {div_btn} elementos '<div onClick=...>'. É proibido criar botões improvisados com divs. Utilize o componente canônico <Button> para garantir foco e acessibilidade ARIA."
        })

    # 7. Checagem de Botões com Hitbox Pequena (<44px)
    small_hits = re.findall(r'\b(h-6|h-7|h-8|w-6|w-7|w-8)\b', content)
    if small_hits and ("button" in content or "onClick" in content):
        issues.append({
            "severidade": "MÉDIA",
            "regra": "T25 - Safe-Zone Thumb Anchoring (44x44px Hitbox)",
            "detalhe": f"Detectadas classes de dimensões reduzidas ({set(small_hits)}). Elementos interativos touch requerem área mínima invisível de 44x44px."
        })

    # 8. Checagem "Never Ship" de Animação: transition: all
    if "transition: all" in content or "transition-all" in content:
        issues.append({
            "severidade": "MÉDIA",
            "regra": "Never Ship: transition: all detectado",
            "detalhe": "Especificar 'transition: all' força cálculo de layout desnecessário. Nomeie explicitamente as propriedades alteradas (ex: transition: transform 160ms var(--ease-out))."
        })

    # 9. Checagem "Never Ship" de Animação: scale(0)
    if "scale(0)" in content or "scale-0" in content:
        issues.append({
            "severidade": "ALTA",
            "regra": "Never Ship: scale(0) em animação de entrada",
            "detalhe": "Nada no mundo real surge do zero absoluto. Inicie animações de entrada com scale(0.95) a scale(0.97) acompanhado de opacity: 0."
        })

    # 10. Checagem "Never Ship" de Animação: ease-in em UI
    if "ease-in" in content and "ease-in-out" not in content:
        issues.append({
            "severidade": "MÉDIA",
            "regra": "Never Ship: ease-in em componente de interface",
            "detalhe": "O início lento do ease-in retarda a percepção de resposta. Utilize ease-out ou cubic-bezier(0.23, 1, 0.32, 1)."
        })

    # 11. Checagem de Hover Não Protegido
    if ":hover" in content and "@media (hover: hover)" not in content and "@media(hover:hover)" not in content:
        issues.append({
            "severidade": "BAIXA",
            "regra": "Mobile Pointer Protection: Hover não encapsulado",
            "detalhe": "Pseudo-classe :hover encontrada sem proteção de ponteiro. Telas de toque disparam hover falso no tap. Envolva em '@media (hover: hover) and (pointer: fine)'."
        })

    print("=" * 70)
    print(f"RELATÓRIO DE AUDITORIA UI/UX: {target.name}")
    print("=" * 70)
    if not issues:
        print("✅ Parabéns! Nenhuma patologia de AI Slop ou quebra de diretrizes foi detectada.")
    else:
        print(f"⚠️  Foram encontradas {len(issues)} oportunidades de melhoria:\n")
        for i, issue in enumerate(issues, 1):
            print(f"[{issue['severidade']}] {i:02d}. {issue['regra']}")
            print(f"       -> {issue['detalhe']}\n")

def main():
    parser = argparse.ArgumentParser(description="UI/UX Skill Assistant & Auditor")
    subparsers = parser.add_subparsers(dest="command")

    # list
    subparsers.add_parser("list", help="Lista todos os módulos e as 48 técnicas")

    # search
    search_p = subparsers.add_parser("search", help="Busca técnicas por palavra-chave")
    search_p.add_argument("term", nargs="+", help="Termo de busca")

    # module
    mod_p = subparsers.add_parser("module", help="Exibe o conteúdo de um módulo (1 a 7)")
    mod_p.add_argument("id", type=int, help="Número do módulo (1-7)")

    # formulas
    subparsers.add_parser("formulas", help="Exibe a tabela de fórmulas matemáticas e parâmetros de física")

    # recipe
    recipe_p = subparsers.add_parser("recipe", help="Exibe código de implementação pronta de animação")
    recipe_p.add_argument("name", nargs="?", help="Nome da receita (button, popover, modal, drawer, toast, drag, etc.)")

    # vocab
    vocab_p = subparsers.add_parser("vocab", help="Busca termo no glossário reverso de animação")
    vocab_p.add_argument("term", nargs="+", help="Termo descritivo ou visual")

    # rules
    rules_p = subparsers.add_parser("rules", help="Consulta as regras canônicas do acervo de 10 categorias")
    rules_p.add_argument("category", nargs="?", default="all", help="Categoria (a11y, touch, performance, style, layout, typography, animation, forms, nav, charts)")

    # checklist
    check_p = subparsers.add_parser("checklist", help="Exibe checklist por tipo de interface")
    check_p.add_argument("--type", choices=["pdp", "mobile-nav", "paywall", "landing-page", "dashboard", "motion", "pre-delivery", "general"], default="general")

    # audit
    audit_p = subparsers.add_parser("audit", help="Audita estaticamente um arquivo frontend em busca de AI Slop")
    audit_p.add_argument("file", help="Caminho do arquivo a auditar")

    args = parser.parse_args()
    if args.command == "list":
        cmd_list(args)
    elif args.command == "search":
        cmd_search(args)
    elif args.command == "module":
        cmd_module(args)
    elif args.command == "formulas":
        cmd_formulas(args)
    elif args.command == "recipe":
        cmd_recipe(args)
    elif args.command == "vocab":
        cmd_vocab(args)
    elif args.command == "rules":
        cmd_rules(args)
    elif args.command == "checklist":
        cmd_checklist(args)
    elif args.command == "audit":
        cmd_audit(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
