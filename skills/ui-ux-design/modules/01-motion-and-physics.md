# Módulo 01: Física de Movimento, Molas & Interação Fluida (Apple Standards)

Este módulo estabelece os padrões matemáticos, cinemáticos e de materiais para interfaces que respondem às leis do mundo físico, tornando o software uma extensão natural do usuário.

---

## Técnica 06: Engenharia de Interfaces Fluidas e Física de Molas (`Apple Fluid Motion & Spring Physics`)

### Visão Geral & O Princípio Central
Uma interface torna-se fluida e humana quando:
1. Começa no valor de apresentação atual da tela.
2. Herda a velocidade vetorial exata do usuário no momento da soltura.
3. Projeta a inércia e momento para a frente.
4. Pode ser interrompida e revertida a qualquer milissegundo.

### Parâmetros de Molas (Apple WWDC) vs. CSS Fixo
Substitua durações estáticas (`transition: 300ms ease`) por molas interativas:
- **Damping Ratio (Amortecimento):**
  - `1.0` = **Criticamente amortecido** (sem quique, para suavemente no alvo). **Padrão para 90% da UI.**
  - `< 1.0` (ex: `0.8`) = **Sub-amortecido** (leve quique físico). **Usar apenas quando o gesto prévio carregava momento real (flick, throw).**
- **Response (Resposta, em segundos):** Tempo característico para atingir o alvo (`0.3s` a `0.4s`).

| Interação | Damping | Response | Mapeamento Motion / Framer Motion |
|---|---|---|---|
| Reposicionamento / Modais / PiP | `1.0` | `0.4s` | `{ type: "spring", bounce: 0, duration: 0.4 }` |
| Rotação de Elementos | `0.8` | `0.4s` | `{ type: "spring", bounce: 0.2, duration: 0.4 }` |
| Bottom Sheets / Drawers | `0.8` | `0.3s` | `{ type: "spring", bounce: 0.2, duration: 0.3 }` |

### Fórmulas Matemáticas da Apple
- **Projeção de Inércia (Decaimento Exponencial):**
  ```javascript
  function project(initialVelocity /* px/s */, decelerationRate = 0.998) {
    return (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate);
  }
  const projectedStop = currentY + project(releaseVelocityY);
  const targetSnap = findNearestSnapPoint(projectedStop);
  animateSpring(targetSnap, { velocity: releaseVelocityY });
  ```
- **Resistência Elástica em Bordas (Rubber-Banding):**
  ```javascript
  function rubberband(overshoot, dimension, constant = 0.55) {
    return (overshoot * dimension * constant) / (dimension + constant * Math.abs(overshoot));
  }
  ```

---

## Técnica 07: Manipulação Direta e Interrompibilidade Absoluta (`Direct Manipulation & Interruptibility`)

### O Princípio Central
> *"O pensamento e o gesto acontecem em paralelo."*

O usuário nunca deve ser bloqueado enquanto uma animação ocorre. Uma gaveta fechando deve poder ser agarrada no ar e puxada de volta sem sobressaltos.

### Regras de Ouro para Agentes
1. **Nunca use `pointer-events: none` durante transições de interface.**
2. **Sempre anime a partir do Valor de Apresentação (Live Value):** Leia o `transform` computado na tela e inicie o novo movimento a partir dessa posição exata para evitar teleporting.
3. **Blend de Velocidade:** Em reversões bruscas de direção, suavize e preserve o vetor de velocidade da mola anterior em vez de colidir com uma "parede de tijolos" (brick wall).
4. **Decomposição em 2D:** Use molas independentes para X e Y. Um cálculo único de distância desincroniza trajetórias diagonais.
5. **Rastreamento 1:1 e Grab Offset:** Use Pointer Events com `setPointerCapture` e preserve a distância exata onde o usuário tocou (`e.clientY - rect.top`).

---

## Técnica 08: Materiais, Profundidade e Translucidez Funcional (`Functional Materials, Vibrancy & Depth`)

### A Função dos Materiais Translúcidos
A translucidez não é cosmética; ela é uma camada funcional flutuante que estabelece hierarquia e continuidade contextual.

### Diretrizes de Implementação
- **Barra de Navegação Flutuante:** `backdrop-filter: blur(20px) saturate(180%)` com fundo semi-transparente (`rgba(255, 255, 255, 0.6)` ou `rgba(20, 20, 20, 0.7)`).
- **Borda de Luz Superior (Edge Light):** Adicione `border-top: 1px solid rgba(255, 255, 255, 0.4)` simulando luz incidindo na aresta superior do vidro.
- **Proibição de Empilhamento Translúcido:** **Nunca empilhe uma superfície translúcida clara sobre outra superfície translúcida clara.** A legibilidade tipográfica colapsa imediatamente.
- **Vibrancy Tipográfica:** Textos sobre materiais translúcidos requerem maior contraste, peso ligeiramente reforçado (`font-weight: 500+`) e letter-spacing calibrado.
- **Materialização Simultânea:** Ao exibir um modal ou sheet translúcido, anime a escala e o raio de desfoque (`blur`) juntos.

---

## Técnica 09: Tipografia Óptica e Escala Proporcional (`Optical Typography & Dynamic Tracking`)

### Regras Ópticas da WWDC
- **Tracking (Letter-Spacing) Dinâmico por Tamanho:**
  - **Títulos Grandes / Display (> 28px):** Exigem **tracking negativo** (`-0.015em` a `-0.025em`) para evitar que as letras pareçam desmembradas.
  - **Corpo de Texto (14px - 18px):** Tracking neutro (`0em` a `-0.005em`).
  - **Legendas / Small Caps (< 13px):** Tracking **positivo** (`+0.01em` a `+0.02em`).
- **Leading (Line-Height) Inverso:**
  - Títulos grandes: Leading apertado (`1.05` a `1.15`).
  - Corpo de texto denso: Leading expandido (`1.45` a `1.6`).
- **Hierarquia por Peso:** Diferencie elementos pelo peso tipográfico antes de aumentar o tamanho da fonte.
- **System Fonts First:** Priorize `system-ui, -apple-system, BlinkMacSystemFont` aproveitando tabelas ópticas nativas.

---

## Técnica 10: Fundamentos de Excelência em Design Apple (`Apple 8 Core Design Foundations`)

### Os Oito Pilares
1. **Propósito (Purpose):** Cada elemento justifica sua existência; elimine ruídos.
2. **Agência (Agency):** Mantenha o usuário no controle com Undo fácil; modais de confirmação apenas para atos destrutivos irreversíveis.
3. **Responsabilidade (Responsibility):** Transparência em privacidade e salvaguardas em sistemas inteligentes.
4. **Familiaridade (Familiarity):** Metáforas consistentes com a física real e convenções estabelecidas.
5. **Flexibilidade (Flexibility):** Adaptação ergonômica entre toque móvel e cursor desktop de precisão.
6. **Simplicidade (Simplicity != Minimalismo Vazio):** Clareza de fluxo e redução de etapas, mantendo informações cruciais visíveis.
7. **Artesanato (Craft):** Alinhamentos estritos em múltiplos de 4px/8px, curvas imperceptíveis e ausência de jittering.
8. **Encantamento (Delight):** Consequência de um sistema rápido, previsível, fluido e sem engasgos.

### Acessibilidade Fisiológica Mandatória
- `@media (prefers-reduced-motion: reduce)`: Cross-fades suaves de opacidade (150-200ms); zero molas ou translações espaciais amplas.
- `@media (prefers-reduced-transparency: reduce)`: Remova blur; fundo sólido (`0.95` a `1.0`).
- `@media (prefers-contrast: more)`: Bordas nítidas de 2px e contraste WCAG AAA.

---

## Engenharia de Construção de Animações & Filosofia Emil Kowalski

Esta seção define o processo em 7 etapas para construir qualquer animação web garantindo que ela sobreviva a uma revisão estrita de design engineering.

### 1. Tokens Canônicos de Curvas (CSS Easing)
```css
:root {
  --ease-out: cubic-bezier(0.23, 1, 0.32, 1);        /* Forte ease-out para entrada de UI */
  --ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);    /* Forte ease-in-out para reposicionamento em tela */
  --ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);     /* Curva de gaveta estilo iOS (Ionic) */
}
```

### 2. Gating de Frequência (Isso deve mesmo ser animado?)
- **100+ vezes/dia** (atalhos de teclado, command palette, toggles rápidos): **Zero animação. Nunca.**
- **Dezenas de vezes/dia** (hover em botões, abas): Apenas quase-imperceptível (80–150ms) ou nada.
- **Ocasional** (modais, drawers, toasts): Animação padrão (150–250ms).
- **Raro / Primeira vez** (onboarding, celebração): Orçamento de delight liberado.

### 3. Tabela "Never Ship" (Reprovação Automática em Revisão)

| O que NUNCA Enviar | O que Usar em Substituição |
|---|---|
| `transition: all` | Especifique as propriedades exatas (`transform, opacity`) |
| `scale(0)` em entradas | `scale(0.95)` combinado com `opacity: 0` |
| `ease-in` em componentes de UI | `ease-out` ou curva forte (`cubic-bezier(0.23, 1, 0.32, 1)`) |
| `ease-out` nativo fraco do browser | `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)` |
| Animação em atalho de teclado | Transição instantânea sem animação |
| Duração de UI acima de 300ms | Entre `150ms` e `250ms` |
| `transform-origin: center` em popover | `var(--transform-origin)` ancorado ao gatilho |
| Keyframes em toasts e toggles | CSS transitions retargetáveis |
| Animar `width`, `height`, `top`, `left` | Animar `transform` e `opacity` acelerados por GPU |
| Hover sem proteção de ponteiro | Envolver em `@media (hover: hover) and (pointer: fine)` |
| Omitir redução de movimento | Fornecer variante atenuada (`prefers-reduced-motion`) |

*Para os 14 modelos de código prontos (button, popover, modal, drawer, toast, accordion, drag-to-dismiss, WAAPI), consulte [references/animation-recipes.md](../references/animation-recipes.md).*
*Para o glossário reverso de termos de animação, consulte [references/animation-vocabulary.md](../references/animation-vocabulary.md).*

