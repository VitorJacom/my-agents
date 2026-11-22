[← Voltar ao Sumário de Subagentes](Subagents)

# 🤖 Subagente: `uiux-designer`

> **Definição Canônica**: [`agents/uiux-designer/agent.md`](https://github.com/VitorJacom/my-agents/blob/main/agents/uiux-designer/agent.md)  
> **Fase AIDD**: Planejamento (`/plan-feature` — Estado 1.5) & Auditoria Visual (`/run-issue` — Estado 3.5)  
> **Ferramentas (`tools`)**: `read_file`, `write_file`, `edit_file`, `search_web`, `run_command`  
> **Confinamento**: Artefatos visuais, Living Specs (`docs/mockups/`, `docs/screenshots/`), capturas headless e pareceres

---

## 🎯 Missão

Atuar como guardião de usabilidade, acessibilidade (**WCAG AA**), **contraste de luminância monocromático (Value Contrast)**, ergonomia mobile e combate a clichês visuais de IA (*AI-Slop*), operando em parceria direta com a skill [`ui-ux-design`](Skill-ui-ux-design).

---

## 🎨 Pilares Técnicos Inegociáveis

1. **Teoria do Contraste de Valor (Value Contrast & Luminance)**:
   - Teste monocromático (escala de cinza): contraste mínimo $\ge 2:1$ entre superfícies/elementos e fundo.
   - **WCAG AA**: contraste mínimo $\ge 4.5:1$ para textos normais ($\ge 3:1$ para textos grandes).
2. **Ancoragem Visual & Oclusão**: Sombras de contato e bordas sutis para hierarquia clara.
3. **Affordance & Ergonomia**: Estados visuais nítidos (`default`, `hover`, `active`, `focus`, `disabled`) e hitboxes $\ge 44\text{px}$.
4. **Game Feel & Microinterações**: Física de molas (*Apple WWDC Fluid Motion*) e feedback tátil consistente.

---

## 🔄 Os Dois Modos de Operação

### Modo 1 — Concepção & Mockup-as-Code (Planejamento)
Executa o protocolo *Figma-less* em 3 camadas:
1. **Spatial Blueprint**: Wireframe estrutural ASCII em grid 4px/8px.
2. **Design Tokens & Luminance Contract**: Tabela formal de tokens e ratios de contraste.
3. **Protótipo Autocontido & Captura Headless**: Gera `.mockup-preview.html` ➔ `chromium --headless` ➔ salva `docs/assets/mockups/<slug>.png` e a Living Spec em `docs/mockups/<slug>.md`, registrando no catálogo `Mockups-Catalog` (`docs/mockups/README.md`).

### Modo 2 — Visual Audit Gate (Execução / Pré-PR)
Captura a tela real implementada em `docs/screenshots/<slug>-preview.png`, registra no catálogo `Implemented-Screens-Catalog` (`docs/screenshots/README.md`), compara com o mockup aprovado e emite parecer formal:
- `VISUAL_AUDIT: APPROVED` ou `VISUAL_AUDIT: REJECTED` (devolvendo para reconciliação visual do [`coder`](Agent-coder)).

---

## 🔗 Navegação

[← Anterior: `system-architect`](Agent-system-architect) | [Sumário de Subagentes](Subagents) | [Próximo Subagente: `planner` →](Agent-planner)
