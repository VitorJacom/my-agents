# Construção de Animações: Princípios & Filosofia Emil Kowalski

Este documento estabelece o padrão rigoroso de engenharia de movimento (*senior design engineer bar*). O objetivo é transformar qualquer demanda de animação em uma implementação que passe na primeira revisão técnica sem concessões a clichês ou lentidão.

---

## 1. Postura Operacional & Os Dois Modos de Falha

Existem dois modos clássicos de falha ao animar interfaces:
1. **Animar algo que NÃO deveria se mover (O Pior Erro):** A interface tenta parecer "legal" ou "moderna", mas desacelera quem usa o produto dezenas de vezes por dia. Produzir **zero linhas de código de animação** é frequentemente a decisão mais profissional.
2. **Animar a coisa certa com os ingredientes errados:** Usar `ease-in` em entrada, `scale(0)` do nada, keyframes em componentes que disparam repetidamente (como toasts), ou durações que tornam menus suspensos lentos.

> [!IMPORTANT]
> **Nunca apresente opções de animação como um menu aberto.** Tome a decisão técnica, declare a justificativa em uma linha e escreva o código ideal.

---

## 2. As Regras Rígidas (Hard Rules)

1. **Execute a sequência de construção na ordem estrita (Etapas 1 a 7):** As Etapas 1 e 2 barram tudo antes de você escolher curvas ou durações.
2. **Valores aproximados são proibidos:** Toda curva, duração e configuração de mola deve vir das tabelas canônicas. Nunca invente `cubic-bezier(0.4, 0, 0.2, 1)` "porque soa familiar".
3. **Estenda os tokens existentes, não crie sistemas paralelos:** Se `--ease-out` ou uma escala de duração já existir no projeto, use-a.
4. **`prefers-reduced-motion` e gating de hover acompanham o código desde o primeiro envio:** Nunca deixe acessibilidade ou suporte a touch como débito técnico posterior.
5. **A ferramenta mais barata que funciona:** Não instale bibliotecas pesadas de animação (`framer-motion`, `motion`) para um simples fade de opacidade.

---

## 3. A Sequência de Construção em 7 Etapas

### Etapa 1: Isso deve mesmo ser animado?

| Frequência de Uso | Decisão Técnica |
|---|---|
| **100+ vezes/dia** (atalhos de teclado, command palette, toggles) | **Zero animação. Nunca.** Transição instantânea de estado. |
| **Dezenas de vezes/dia** (hover em botões, navegação de listas) | Apenas quase-imperceptível: ultrarrápido (80–150ms) ou nada. |
| **Ocasional** (modais, drawers, toasts, selects) | Animação padrão (150–250ms). |
| **Raro / Primeira vez** (onboarding, sucesso de pagamento, celebração) | O orçamento de "delight" (encantamento) pertence exclusivamente aqui. |

> [!CAUTION]
> **Ações iniciadas por teclado são um desqualificador imediato:** O Raycast não tem animação de abertura/fechamento. Para algo acionado centenas de vezes ao dia, o atraso de 200ms é um defeito, não uma virtude.

### Etapa 2: Qual é o propósito da animação?
Selecione exatamente **uma** destas palavras funcionais:
- **Feedback:** Confirmar imediatamente que a interface ouviu a ação do usuário.
- **Consistência Espacial:** Demonstrar de onde um elemento veio ou para onde foi.
- **Indicação de Estado:** Tornar uma mudança funcional legível.
- **Prevenção de Mudança Abrupta:** Criar ponte sobre conteúdo que, sem ela, se teletransportaria.
- **Explicação:** Demonstrar a mecânica de algo (apenas em marketing ou primeiro onboarding).
- **Delight:** Permitido *apenas* na faixa rara/primeira vez.

*Não conseguiu nomear uma das funções acima? Não construa a animação.* Dados que o usuário precisa ler ou manipular nunca devem se mover por estética.

### Etapa 3: Escolha a Ferramenta (A Mais Barata que Funciona)
1. **CSS Transition:** Hover, clique/press, cor, mudança de estado controlada por classe/atributo.
2. **CSS `@starting-style`:** Animação de entrada no momento de montagem sem dependência de estado JS.
3. **CSS Keyframes/Animation:** Movimento pré-determinado que precisa permanecer fluido fora da main thread enquanto a página carrega dados pesados.
4. **WAAPI (`element.animate()`):** Controle programático com performance nativa de CSS e sem bibliotecas externas.
5. **Motion (`motion.dev`):** Física de molas, animações de layout contínuo, saídas animadas e gestos direcionados por ponteiro.

### Etapa 4: Escolha as Propriedades
- **Apenas `transform` e `opacity`:** Elas ignoram layout e pintura (*paint*), rodando diretamente na GPU. `width`, `height`, `margin`, `padding`, `top` e `left` forçam recalculo completo de layout (*layout thrashing*).
  - *Exceções toleradas:* `clip-path` (para revelações) e `height` (exclusivo para accordions com medição via JS).
- **Nunca use `scale(0)`:** Comece sempre a partir de `scale(0.95)` a `scale(0.97)` acompanhado de `opacity: 0`. No mundo real, nada surge de um ponto invisível no vácuo.
- **`transform-origin` ancorado ao gatilho:** Para popovers, menus suspensos e tooltips (`var(--transform-origin)`). Modais são a única exceção, mantendo `transform-origin: center`.
- **Porcentagens em `translate()`:** Prefira `translateY(100%)` a pixels estáticos; ele se adapta à altura dinâmica do conteúdo.
- **No Motion, use strings completas de transform:**
  ```jsx
  // Incorreto (perde aceleração sob carga intensa):
  <motion.div animate={{ x: 100 }} />
  // Correto (aceleração de hardware garantida):
  <motion.div animate={{ transform: "translateX(100px)" }} />
  ```
- **Nunca altere uma variável CSS no elemento pai para acionar transform em filhos:** Isso força o recálculo de estilo de todos os nós filhos. Aplique o `transform` diretamente no nó alvo.

### Etapa 5: Curva de Easing e Duração — ou Molas

#### Curvas Oficiais de Easing (CSS Variables):
```css
:root {
  --ease-out: cubic-bezier(0.23, 1, 0.32, 1);        /* Forte ease-out para entrada de UI */
  --ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);    /* Forte ease-in-out para reposicionamento em tela */
  --ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);     /* Curva de gaveta estilo iOS (Ionic) */
}
```

> [!WARNING]
> **Nunca use `ease-in` em elementos de UI:** O início lento retarda a percepção de resposta no momento exato em que o usuário está olhando. `ease-out` em 200ms parece substancialmente mais rápido que `ease-in` no mesmo tempo.

#### Tabela de Durações Canônicas:
- **Pressão de Botão (Feedback):** `100ms – 160ms`
- **Tooltips e pequenos popovers:** `125ms – 200ms`
- **Dropdowns, menus e selects:** `150ms – 250ms`
- **Modais e gavetas (drawers):** `200ms – 500ms`
- **Animações gerais de UI:** Devem permanecer **abaixo de 300ms**.

#### Quando Escolher Molas:
Use molas quando houver arraste com momento físico, gestos com possibilidade de reversão instantânea ou rastreamento interativo:
```js
// Configuração Apple (baseada em duração perceptível e quique):
{ type: "spring", duration: 0.5, bounce: 0.2 }

// Configuração Física Tradicional:
{ type: "spring", mass: 1, stiffness: 100, damping: 10 }
```

### Etapa 6: Interrompibilidade e Saída
- **CSS Transitions (não keyframes) para ações frequentes:** Toasts, toggles e botões rápidos se beneficiam de transições porque elas recalculam a trajetória a partir do valor atual na tela (`presentation value`). Keyframes reiniciam do zero gerando saltos (*teleporting*).
- **Saída Simétrica:** Se um toast entra subindo pelo rodapé, deve sair descendo pelo rodapé.
- **Temporização Assimétrica para Tomada de Decisão:** Lento na confirmação deliberada (ex: segurar botão para excluir: 2 segundos linear), e ultrarrápido na resposta do sistema (soltar: 200ms ease-out).

### Etapa 7: Acessibilidade & Gating de Ponteiro
Sempre embarque proteção para redução de movimento e controle de touch:
```css
/* Acessibilidade: remove transformações espaciais amplas, mantendo fade suave */
@media (prefers-reduced-motion: reduce) {
  .element {
    animation: fade 0.2s ease !important;
    transition: opacity 0.2s ease !important;
    transform: none !important;
  }
}

/* Gating de Hover: telas de toque disparam hover falso no toque */
@media (hover: hover) and (pointer: fine) {
  .element:hover {
    transform: scale(1.03);
  }
}
```

---

## 4. Tabela "Never Ship" (Reprovação Automática em Revisão)

| O que NUNCA Enviar | O que Usar em Substituição |
|---|---|
| `transition: all` | Especifique explicitamente as propriedades (`transform, opacity`) |
| `scale(0)` em entradas | `scale(0.95)` combinado com `opacity: 0` |
| `ease-in` em componentes de interface | `ease-out` ou curva forte (`cubic-bezier(0.23, 1, 0.32, 1)`) |
| `ease-out` nativo fraco do browser | `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)` |
| Animação em atalho de teclado ou ação 100+/dia | Sem animação (mudança instantânea) |
| Duração de UI acima de 300ms sem justificativa | Entre `150ms` e `250ms` |
| `transform-origin: center` em popovers ancorados | `var(--transform-origin)` ancorado ao botão (modais são isentos) |
| Keyframes em toasts, alertas ou componentes rápidos | CSS transitions retargetáveis |
| Animar `width`, `height`, `margin`, `padding`, `top`, `left` | Animar `transform` e `opacity` (GPU) |
| Shorthands `x`/`y`/`scale` no Motion sob carga | String explícita `transform: "translateY(...) scale(...)"` |
| Efeitos de `:hover` sem proteção de ponteiro | Envolver em `@media (hover: hover) and (pointer: fine)` |
| Omitir `@media (prefers-reduced-motion)` | Fornecer variante atenuada (apenas fade de opacidade) |
| Todos os elementos de uma lista entrando juntos | Stagger curto de 30ms a 50ms |
