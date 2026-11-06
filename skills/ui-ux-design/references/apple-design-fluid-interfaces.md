# Apple Design & Fluid Interfaces — Guia de Engenharia de Movimento e UX

Este documento detalha a engenharia de interfaces fluidas da Apple (baseada nas palestras da WWDC, especialmente *Designing Fluid Interfaces* da WWDC 2018, *The Details of UI Typography* da WWDC 2020 e *Principles of Great Design* da WWDC 2026), traduzida para a plataforma web moderna (CSS, Pointer Events, `requestAnimationFrame` e bibliotecas de física como Motion / Framer Motion).

---

## 1. Princípio Fundamental: O que torna uma interface fluida?

> *"Quando alinhamos a interface à maneira como pensamos e nos movemos, ela deixa de parecer um computador e passa a parecer uma extensão transparente de nós."*

Uma interface é considerada fluida quando emula o comportamento do mundo físico:
1. **Responde instantaneamente** ao menor contato físico.
2. **Move-se continuamente** acompanhando o ponteiro (1:1).
3. **Carrega momento linear e velocidade** ao ser solta.
4. **Resiste suavemente** em limites rígidos (rubber-banding).
5. **Permite interrupção e redirecionamento** a qualquer momento do voo.

Toda decisão serve a quatro necessidades humanas universais: **Previsibilidade/Segurança, Compreensão, Conquista e Encantamento (Joy).**

---

## 2. As Quatro Regras de Ouro da Física de Movimento

### Regra 1: Resposta Instantânea (Matar a Latência)
- **Feedback no Pointer-Down:** O elemento deve reagir visualmente no evento `pointerdown`, nunca no `click` ou no `touchup`. Aguardar a liberação do dedo gera sensação de lentidão.
- **Feedback Contínuo:** Durante um arrasto ou abertura de gaveta (drawer), a interface deve atualizar a posição em tempo real (1:1) com o ponteiro, nunca animar apenas ao término do gesto.
- **Eliminação de Delays:** Remova atrasos artificiais de toque (~300ms tap delay), debounces desnecessários e transições com atraso (`transition-delay`).

```css
/* Feedback instantâneo no toque/press */
.interactive-card:active {
  transform: scale(0.97);
  transition: transform 100ms ease-out;
}
```

### Regra 2: Manipulação Direta (Direct Manipulation)
- **Respeito ao Grab Offset:** Quando o usuário segura um card, o elemento não deve centralizar no cursor. Deve respeitar a distância exata entre o ponto de toque e a borda do elemento (`grabOffset`).
- **Pointer Capture:** Use `setPointerCapture(pointerId)` para que o rastreamento continue fluido mesmo se o cursor sair dos limites do elemento durante movimentos rápidos.
- **Histórico de Velocidade:** Guarde um histórico das últimas amostras de posição e timestamp para calcular com precisão a velocidade vetorial no momento da liberação (`releaseVelocity`).

```javascript
el.addEventListener('pointerdown', (e) => {
  el.setPointerCapture(e.pointerId);
  const grabOffsetY = e.clientY - el.getBoundingClientRect().top;
  // registrar timestamp e posição para vetor de velocidade
});
```

### Regra 3: Interrompibilidade Absoluta (Interruptibility)
> **O princípio mais importante de toda a engenharia de movimento da Apple.**

Um usuário deve poder agarrar um elemento em pleno movimento e revertê-lo sem qualquer engasgo. Se um modal está fechando e o usuário o puxa de volta, ele deve seguir o dedo instantaneamente, sem esperar terminar a animação de fechamento para só então reabrir.

- **Nunca bloqueie inputs (`pointer-events: none`) durante animações.**
- **Anime a partir do Valor de Apresentação (Live Value):** Ao interromper, leia o `transform` computado real da tela naquele milissegundo (`getComputedStyle` ou matrix transform) e inicie o novo movimento a partir dessa posição. Iniciar do valor alvo pretendido gera saltos visuais grosseiros (*teleporting*).
- **Evite CSS Transitions / `@keyframes` para gestos:** Transições CSS interpolam valores estáticos com duração fixa e não conseguem herdar momento nem reverter sem salto de velocidade ("brick wall"). Use **molas (springs)**.
- **Decomposição em 2D:** Isole molas em X e Y independentes. Um único cálculo escalar de distância dessincroniza movimentos curvos onde as velocidades nos eixos horizontal e vertical diferem.

### Regra 4: Molas (Springs) em vez de Durações Fixas
A física tradicional de molas utiliza o trio massa, rigidez e amortecimento (*mass, stiffness, damping*). A Apple simplificou para dois parâmetros intuitivos:
- **Damping Ratio (Amortecimento):** Controla o overshoot (quique).
  - `1.0` = **Criticamente amortecido** (sem quique, desaceleração pura e suave). *Padrão para 90% da UI*.
  - `< 1.0` = **Sub-amortecido** (passa do alvo e oscila suavemente). *Usado apenas quando há momento físico prévio*.
- **Response (Resposta):** O tempo aproximado (em segundos) que a mola leva para atingir o alvo. Controla a agilidade do movimento. **Não é duração fixa**; a duração real emerge da física.

#### Parâmetros de Produção Utilizados pela Apple:

| Tipo de Interação | Damping Ratio | Response (s) | Sensação |
|---|---|---|---|
| **Movimento / Reposicionamento (ex: PiP, Modais)** | `1.0` | `0.4` | Firme, preciso, sem oscilação |
| **Rotação de Elementos** | `0.8` | `0.4` | Leve elasticidade nos extremos |
| **Gavetas / Bottom Sheets** | `0.8` | `0.3` | Ágil e responsivo ao gesto |

```javascript
import { animate } from 'motion';

// Padrão criticamente amortecido (sem bounce)
animate(element, { y: 0 }, { type: 'spring', bounce: 0, duration: 0.4 });

// Gesto com momentum (flick/arremesso com leve quique)
animate(element, { y: targetPosition }, { type: 'spring', bounce: 0.2, duration: 0.4 });
```

---

## 3. Fórmulas Matemáticas de Alta Precisão da Apple

### 1. Handoff de Velocidade (Velocity Handoff)
Ao soltar o dedo, a velocidade do gesto deve ser injetada como a velocidade inicial da mola. Se a API de molas exigir velocidade relativa:

$$\text{Velocidade Relativa} = \frac{\text{Velocidade do Gesto}}{\text{Valor Alvo} - \text{Valor Atual}}$$

### 2. Projeção de Momento (Momentum Projection)
Ao soltar um elemento em movimento (ex: flick em um carrossel ou sheet), não verifique apenas qual ponto de parada está mais perto da posição atual. Calcule onde o elemento **iria parar** se desacelerasse livremente (exatamente como a rolagem nativa do iOS).

A fórmula proprietária da Apple revelada na WWDC 2018 utiliza decaimento exponencial:

```javascript
/**
 * Projeta a posição final com base na velocidade de lançamento e taxa de desaceleração.
 * @param {number} initialVelocity - Velocidade do ponteiro em px/s
 * @param {number} decelerationRate - Taxa de desaceleração (padrão iOS: 0.998; mais ágil: 0.99)
 * @returns {number} Distância projetada em pixels
 */
function project(initialVelocity, decelerationRate = 0.998) {
  return (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate);
}

// Exemplo de aplicação prática:
const projectedStop = currentY + project(releaseVelocityY);
const finalSnapPoint = findNearestSnapPoint(projectedStop);
animateSpringTo(finalSnapPoint, { velocity: releaseVelocityY });
```

> **Atenção:** Nunca use a fórmula de física estática clássica ($v^2 / 2a$). Ela não condiz com a cinemática perceptiva do iOS/macOS.

### 3. Resistência Progressiva em Bordas (Rubber-Banding)
Quando o usuário arrasta um elemento além do seu limite natural, o elemento não deve travar secamente (o que parece tela congelada), nem seguir 1:1 (o que dá a falsa ilusão de conteúdo infinito). Deve oferecer resistência progressiva elástica:

```javascript
/**
 * Aplica a fórmula de rubber-banding da Apple.
 * @param {number} overshoot - Distância percorrida além da borda (px)
 * @param {number} dimension - Altura ou largura total da área (px)
 * @param {number} constant - Coeficiente elástico (padrão: 0.55)
 * @returns {number} Deslocamento visual amortecido
 */
function rubberband(overshoot, dimension, constant = 0.55) {
  return (overshoot * dimension * constant) / (dimension + constant * Math.abs(overshoot));
}
```

---

## 4. Consistência Espacial e Roteamento Visual

1. **Caminhos Simétricos:** Elementos devem entrar e sair pelo mesmo caminho. Se um painel desliza da direita para a esquerda, ele deve ser dispensado da esquerda para a direita. Deslizar da direita e fechar caindo para baixo desconecta o mapa mental do usuário.
2. **Origem Ancorada (Anchored Origin):** Menus suspensos, popovers e modais expansíveis devem nascer do elemento que os disparou. Defina `transform-origin` nas coordenadas do botão gatilho.
3. **Curvas de Retorno Espelhadas:** Em transições reversíveis, use curvas cúbicas inversas para que a trajetória de volta seja uma reflexão natural da trajetória de ida.
4. **Indicação de Direção (Hinting):** Acelere a escala e a forma na direção em que o gesto está apontando (ex: módulos da Central de Controle que se expandem em direção ao dedo antes de preencher a tela).

---

## 5. Materiais, Profundidade e Hierarquia Visual

A Apple utiliza materiais translúcidos não por estética decorativa, mas como um **sistema de sinalização de profundidade funcional**:

- **Barra de Navegação e Ferramentas Flutuantes:** Construídas com `backdrop-filter: blur(20px) saturate(180%)` e fundo semitransparente, permitindo que o conteúdo passe por baixo.
- **Borda de Luz Superior:** Borda de 1px com transparência clara (`border-top: 1px solid rgba(255,255,255,0.4)`) simulando luz incidindo na aresta superior do vidro físico.
- **Hierarquia por Peso de Material:**
  - Superfícies estruturais de fundo (sidebars): mais densas, maior opacidade, menor saturação.
  - Elementos interativos superiores (botões, painéis flutuantes): mais translúcidos, maior saturação de cor.
  - **Regra:** Nunca sobreponha uma superfície translúcida clara sobre outra superfície translúcida clara; o contraste e a legibilidade são destruídos.
- **Vibrancy Tipográfica:** Sobre materiais translúcidos, não utilize texto cinza chapado. Aumente o contraste, aplique peso ligeiramente mais encorpado e use sombra de contexto sutil.
- **Transição de Material:** Ao animar a entrada de vidro/blur, anime simultaneamente o raio do blur e a escala para que pareça um material se solidificando no espaço físico.

---

## 6. Acessibilidade Sensorial e Fisiológica

A sensibilidade vestibular do usuário deve ser protegida de forma ativa:

| Mídia / Preferência | Diretriz Técnica Apple / Web |
|---|---|
| `@media (prefers-reduced-motion: reduce)` | Substitua deslocamentos de molas e deslocamentos espaciais amplos por **cross-fades suaves de opacidade** (150-200ms). Elimine elasticidade/quique. |
| `@media (prefers-reduced-transparency: reduce)` | Remova o `backdrop-filter` e aumente a opacidade do fundo para `0.95` ou `1.0` sólido. |
| `@media (prefers-contrast: more)` | Superfícies com alto contraste, fundos sólidos e bordas contrastantes nítidas (ex: 2px com cor explícita). |

---

## 7. Tipografia Óptica e Escala

- **Tracking (Letter-Spacing) Dinâmico:**
  - Títulos e tamanhos de exibição grandes requerem **tracking negativo** (`-0.015em` a `-0.025em`) para evitar que as letras pareçam desmembradas.
  - Textos de leitura longos e tamanhos pequenos requerem tracking neutro ou ligeiramente positivo (`+0.01em`).
- **Leading (Line-Height) Inverso:**
  - Títulos grandes: leading apertado (`1.05` a `1.15`).
  - Corpo de texto: leading confortável (`1.4` a `1.6`).
- **System Fonts First:** Priorize `system-ui, -apple-system, BlinkMacSystemFont` como base nativa antes de fontes customizadas pesadas, aproveitando o ajuste óptico nativo do sistema operacional.
