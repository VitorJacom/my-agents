# Arquitetura de Navegação Mobile & Bottom Bar UX

Este documento estabelece os padrões ergonômicos, estruturais e de microinteração para barras de navegação inferiores (*Bottom Navigation Bars* / *Tab Bars*) em aplicativos móveis iOS e Android.

---

## 1. Anatomia Ergonômica da Barra de Navegação

A barra inferior é o componente mais acessado da aplicação e deve ser projetada para a zona natural de alcance do polegar (*Thumb Zone*), respeitando estritamente a barra de gestos do sistema operacional (*Home Indicator*).

```
+-------------------------------------------------------------+
|                                                             |
|                   CONTEÚDO ROLÁVEL DA TELA                  |
|                                                             |
+=============================================================+ <- Borda superior 1px (rgba(0,0,0,0.06))
|                                                             | <- Altura da Barra (56px a 64px)
|   [ Início ]    [ Busca ]     ( + )     [ Chat ]  [ Perfil ]|
|    (outline)    (outline)   (Hero CTA)  (outline)  (filled) | <- Ícone 24px + Texto 11px
|     Cinza        Cinza       Destaque     Cinza     Primária|
|                                                             |
|     |<- - - - - Hitbox invisível de 44x44px - - - - ->|     |
|                                                             |
|=============================================================|
|             ====== BARRA DE HOME (34px) ======              | <- SAFE AREA INFERIOR
+-------------------------------------------------------------+
```

---

## 2. As 5 Regras de Ouro de Navegação Mobile

### 1. Hierarquia Canônica (3 a 5 Destinos Essenciais)
- **Destinos Permitidos:** Limite a barra a 3 até 5 itens primários de uso contínuo (ex: Início, Busca, Criar/Adicionar, Mensagens, Perfil). Máximo absoluto de 6 itens em cenários complexos.
- **Anti-Padrão (Poluição de Jakob):** Nunca coloque na barra inferior links para Termos de Uso, FAQs, Logout, logos corporativos ou botão de voltar do histórico. Esses itens pertencem ao perfil, menu lateral (*drawer*) ou cabeçalho superior.
- **Hero CTA Central:** Caso o app possua uma ação frequente definidora de negócio (ex: publicar foto, pedir comida, nova transação), posicione-a no centro com elevação ou contraste visual destacado.

---

### 2. Ergonomia da Safe Area e Hitbox (44x44px)
- **Isolamento de Gesto do Sistema:** Dispositivos modernos utilizam a base da tela para gestos de sistema (fechar app / multitarefa). É obrigatório respeitar a `safe-area-inset-bottom` (34px no iOS). Não posicionar ícones ou textos colados na aresta física inferior.
- **Especificações de Tamanho e Escala:**
  - Ícone visual: **24x24 pixels**.
  - Rótulo de texto: **10 a 12 pixels** (sem quebra de linha).
  - Hitbox (área de toque invisível): **mínimo de 44x44 pixels**, evitando toques acidentais ou perda de clique por desvio motor.

```css
.bottom-tab-bar {
  display: flex;
  justify-content: space-around;
  align-items: center;
  height: 56px;
  padding-bottom: env(safe-area-inset-bottom, 34px);
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: blur(20px) saturate(180%);
  border-top: 1px solid rgba(0, 0, 0, 0.08);
}

.tab-item {
  min-width: 44px;
  min-height: 44px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  -webkit-tap-highlight-color: transparent;
}
```

---

### 3. Contraste de Duplo Estado (`Dual-State Affordance`)
Para assegurar compreensão instantânea sob luz solar direta e atender a pessoas com baixa visão (WCAG 3:1):
- **Abas Inativas:** Ícones desenhados em estilo contorno (*outline*), traço uniforme e tom neutro com contraste calibrado (evite cinzas claros demais que desapareçam da tela).
- **Aba Ativa:** Aplique simultaneamente duas mudanças perceptivas:
  1. **Glifo Preenchido (*Filled*):** O ícone passa de contorno para formato sólido.
  2. **Reforço Tipográfico & Cor:** O rótulo ganha peso *semibold* / *bold* e recebe a cor primária da marca.

---

### 4. Delimitação Estrutural de Profundidade
Ao rolar a página, o conteúdo dinâmico nunca deve passar por baixo dos ícones sem demarcação. Utilize uma ou a combinação de:
1. **Borda Divisória Sutil:** `border-top: 1px solid rgba(0, 0, 0, 0.08)` (ou `rgba(255, 255, 255, 0.12)` no dark mode).
2. **Diferenciação Tonal de Fundo:** Fundo da barra com leve saturação ou contraste em relação ao fundo geral da aplicação.
3. **Elevação por Sombra Suave (*Drop Shadow* Invertido):** `box-shadow: 0 -4px 16px rgba(0, 0, 0, 0.04)`.

---

### 5. Microinterações e Indicador Deslizante
Evite trocas de tela secas e mecânicas:
- **Tap Feedback:** Ao pressionar uma aba, aplique microescala de compressão tátil (`transform: scale(0.92)` com mola de resposta rápida).
- **Indicador Deslizante (Pill ou Traço Inferior):** Um marcador visual sutil (em Framer Motion utilizando `layoutId="activeTabPill"`) que corre de uma aba para outra, transmitindo continuidade espacial e elegância operacional.
