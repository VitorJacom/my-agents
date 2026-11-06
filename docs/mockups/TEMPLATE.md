# Mockup Living Spec: <Nome da Tela / Componente>

Template canônico para especificações vivas de telas (Living Specs) segundo o protocolo **Figma-less Mockup-as-Code** conduzido pelo subagente `uiux-designer`.

---

## 📋 Metadados

| Campo | Valor | Descrição |
| :--- | :--- | :--- |
| **Slug** | `<slug>` | Identificador kebab-case único (ex.: `dashboard-home`) |
| **Status** | `Draft` \| `In Review` \| `Approved` \| `Deprecated` | Estado do ciclo de vida da tela |
| **Origem** | `Issue #<numero>` | Issue, User Story ou Feature de origem |
| **Viewport** | `1280x720` (Desktop) / `375x812` (Mobile) | Dimensão de renderização e captura headless |
| **Última Atualização** | `YYYY-MM-DD` | Data da última revisão visual |

---

## 🖼️ Visual Preview

> [!NOTE]
> Esta imagem é a captura determinística gerada pelo browser headless (`chromium --headless`) ou protótipo estático autocontido.

![Mockup](../assets/mockups/<slug>.png)

---

## 📐 Camada 1: Spatial Blueprint (ASCII)

Wireframe estrutural delimitando zonas espaciais, hierarquia e zonas de respiro no grid padronizado (múltiplos de 4px ou 8px), utilizando caracteres Box-drawing Unicode (`┌`, `─`, `┐`, `│`, `└`, `┘`, `├`, `┤`, `┬`, `┴`, `┼`).

```text
┌────────────────────────────────────────────────────────────────────────┐
│ Header / Top Navigation (h: 64px, grid: 8px)                           │
│ [Logo]                   [Nav Item 1]  [Nav Item 2]        [User/Icon] │
├────────────────────────────────────────────────────────────────────────┤
│ Main Content Area                                                      │
│                                                                        │
│ ┌───────────────────────────────┐  ┌─────────────────────────────────┐ │
│ │ Card / Panel A (w: 50%, 16px) │  │ Card / Panel B (w: 50%, 16px)   │ │
│ │ ┌───────────────────────────┐ │  │                                 │ │
│ │ │ Title                     │ │  │                                 │ │
│ │ │ Body content text...      │ │  │                                 │ │
│ │ └───────────────────────────┘ │  │                                 │ │
│ │ [Primary Action]              │  │ [Secondary Action]              │ │
│ └───────────────────────────────┘  └─────────────────────────────────┘ │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Footer / Status Bar (h: 40px)                                          │
│ © 2026 my-agents • Status: Ready                                       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🎨 Camada 2: Design Tokens & Luminance Contract

Definição formal de tokens semânticos e contratos de luminância para garantir estética e acessibilidade.

### 1. Paleta de Cores & Contrato de Luminância

| Token | Hex / HSL | Escala de Cinza (Luminância) | Aplicação | Contrato / Ratio |
| :--- | :--- | :--- | :--- | :--- |
| `--surface-bg` | `#0f172a` | L ~ 9% | Fundo geral da aplicação | Base de contraste |
| `--surface-card` | `#1e293b` | L ~ 16% | Superfície de cartões/painéis | **Value Contrast >= 2:1** vs Fundo |
| `--surface-card-border`| `#334155` | L ~ 26% | Bordas e oclusão de cartões | Delimitação tátil |
| `--text-primary` | `#f8fafc` | L ~ 98% | Textos principais, títulos | **WCAG AA >= 4.5:1** vs Cards |
| `--text-secondary` | `#94a3b8` | L ~ 65% | Metadados, subtítulos | **WCAG AA >= 4.5:1** vs Cards |
| `--interactive-primary`| `#2563eb` | L ~ 35% | Botões e ações principais | **Value Contrast >= 2:1** vs Cards |
| `--interactive-text` | `#ffffff` | L ~ 100%| Rótulos de botões primários | **WCAG AA >= 4.5:1** vs Botão |

> [!IMPORTANT]
> - **Value Contrast >= 2:1**: Todos os elementos interativos, cartões e superfícies devem manter contraste mínimo de 2:1 em escala de cinza contra o plano de fundo imediato.
> - **WCAG AA >= 4.5:1**: Textos e ícones informativos normais devem atingir contraste mínimo de 4.5:1 contra a superfície de apoio (ou 3:1 para textos grandes >= 24px).

### 2. Tipografia Modular

| Token | Tamanho / Line-Height | Peso | Uso Pretendido |
| :--- | :--- | :--- | :--- |
| `--font-heading-xl` | `24px` / `32px` | Semi-Bold (600) | Títulos principais |
| `--font-heading-md` | `18px` / `24px` | Medium (500) | Títulos de seções e cartões |
| `--font-body-base` | `14px` / `20px` | Regular (400) | Corpo de texto principal |
| `--font-caption` | `12px` / `16px` | Regular (400) | Metadados e legendas |

### 3. Elevação, Bordas e Sombras

| Token | Valor | Finalidade |
| :--- | :--- | :--- |
| `--radius-sm` | `4px` | Badges e micro-elementos |
| `--radius-md` | `8px` | Botões e inputs |
| `--radius-lg` | `12px` | Cartões e modais |
| `--shadow-card` | `0 4px 6px -1px rgba(0, 0, 0, 0.3)` | Ancoragem visual e oclusão de profundidade |

---

## ⚡ Estados Interativos & Acessibilidade

Mapeamento determinístico dos estados interativos e conformidade com acessibilidade.

### Matriz de Estados Interativos

| Elemento | Default | Hover | Active / Press | Focus (Teclado) | Disabled |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Botão Primário** | `--interactive-primary` | Luminância +10%, cursor pointer | Deslocamento `y + 2px`, sombra reduzida | Ring 2px outline `--interactive-focus` | Opacidade 40%, cursor not-allowed |
| **Item de Navegação**| Texto `--text-secondary` | Texto `--text-primary`, bg sutil | Fundo ativo destacado | Ring 2px outline | Sem interação |
| **Card Clicável** | Borda 1px `--surface-card-border` | Borda `--interactive-primary`, elevação +2px | Scale 0.99 | Ring 2px outline | Opacidade 60% |

### Checklist de Acessibilidade & Ergonomia
- [ ] **Navegação por Teclado**: Todo componente interativo é acessível via `Tab` / `Shift+Tab` e acionável via `Enter` / `Space`.
- [ ] **Indicador de Foco**: Foco visível com contraste adequado (mínimo de 3:1 contra o fundo).
- [ ] **Semântica ARIA**: Landmarks estruturais (`<header>`, `<main>`, `<nav>`, `<aside>`) e atributos `aria-label` / `aria-expanded` onde aplicável.
- [ ] **Affordance Inequívoca**: Elementos clicáveis possuem pistas táteis evidentes (elevação, chanfro ou estados claros de hover).
