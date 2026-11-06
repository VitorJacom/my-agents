# Módulo 03: Navegação Mobile, Ergonomia & Bottom Tab Bars

Este módulo estabelece os padrões ergonômicos para dispositivos móveis, respeito à Safe Area de gestos do sistema operacional e arquitetura de barras de navegação inferiores de alto desempenho.

---

## Técnica 14: Encapsulamento de Navegação Multifundo (`Contrast-Safe Navigation Dock`)
- **Problema:** Imagens de catálogo dinâmicas (claras, escuras, ruidosas) quebram o contraste de ícones de ação flutuantes soltos.
- **Implementação:**
  - Envolva cada ícone em um dock circular ou pílula neutra com `backdrop-filter: blur(12px)`.
  - Adicione uma borda sutil de 1px com contraste dinâmico (`rgba(0,0,0,0.08)` no light / `rgba(255,255,255,0.15)` no dark mode) para isolar o botão de fundos de mesma tonalidade.

---

## Técnica 19: Cabeçalho com Ancoragem Contextual (`Persistent Context Bottom Sheet`)
- **Problema:** Rolar a tela para ver especificações longas faz o usuário perder a visão da foto/título e o acesso ao botão de compra.
- **Implementação:**
  - O conteúdo informativo sobe em uma lâmina (*sheet*) com cantos superiores arredondados sobrepondo a imagem de fundo.
  - Ao rolar e o título sair de cena, a barra superior exibe um mini-header sólido fixo com o nome e o preço do item.
  - A barra inferior com o botão de compra permanece fixa (*sticky*) no rodapé.

---

## Técnica 24: Hierarquia de Navegação Canônica (`Core-Routing Filter`)
- **Problema:** Sobrecarregar a barra inferior com links raros ou botões de topo (voltar, logo) desorienta o usuário.
- **Implementação:**
  - Limite a barra a **3 até 5 destinos essenciais** (máximo 6): Início, Busca, Criar/Adicionar, Mensagens e Perfil.
  - Mova configurações profundas, FAQ, botão de logout e políticas legais para o perfil ou menu lateral (*drawer*).
  - Destaque uma Call-to-Action centralizada caso o aplicativo possua uma ação frequente definidora (ex: pedir, postar).

---

## Técnica 25: Ancoragem Ergonômica e Isolamento de Gesto (`Safe-Zone Thumb Anchoring`)
- **Problema:** Colar a barra no rodapé sem respeitar a área segura causa disparos acidentais do Home Indicator do sistema.
- **Especificações de Precisão:**
  - Respeite rigorosamente a **Safe Area inferior** (`padding-bottom: env(safe-area-inset-bottom, 34px)`).
  - Tamanho visual do ícone: **24x24 pixels**.
  - Texto do rótulo: **10 a 12 pixels** em linha única.
  - **Hitbox Mínima Invisível:** Área de toque de **no mínimo 44x44 pixels** para cada aba.

---

## Técnica 26: Contraste de Duplo Estado (`Dual-State Affordance`)
- **Problema:** Mudar apenas a cor da fonte torna a identificação do estado ativo lenta sob luz solar direta ou para deficientes visuais (ferindo WCAG).
- **Dupla Diferenciação Mandatória:**
  1. **Glifo Preenchido (*Filled*):** O ícone passa de traço vazado para preenchido.
  2. **Reforço Tipográfico & Cor Primária:** O rótulo ganha peso *semibold/bold* e adota a cor primária da marca.

---

## Técnica 27: Separação Estrutural de Plano (`Background Depth Delimitation`)
- **Problema:** A barra se funde com o fundo, e itens roláveis passam por baixo dos botões sem transição visual.
- **Implementação (Escolha ao menos uma):**
  1. Linha divisória superior de 1px: `border-top: 1px solid rgba(0, 0, 0, 0.08)`.
  2. Diferenciação tonal: fundo ligeiramente contrastante na barra.
  3. Elevação por sombra invertida suave: `box-shadow: 0 -4px 16px rgba(0, 0, 0, 0.04)`.

---

## Técnica 28: Microinteração Tátil de Transição (`Fluid Tab Transition`)
- **Problema:** Trocas de tela secas e mecânicas parecem rígidas.
- **Implementação:**
  - **Tap Feedback:** Microescala no ícone ao pressionar (`transform: scale(0.92)`).
  - **Indicador Deslizante:** Marcador inferior ou pílula que desliza entre abas com mola responsiva (`layoutId` no Framer Motion).
  - **Transição de Tela Suave:** Cross-fades suaves de opacidade entre telas primárias.
