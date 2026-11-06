# Arquitetura de Conversão Mobile & E-Commerce UX

Este documento detalha os padrões avançados de design de interface e experiência para **Páginas de Detalhes de Produto (PDP)**, fluxos transacionais e catálogos em e-commerce mobile. O objetivo central é eliminar pontos de atrito cognitivo, proteger o contraste visual sobre mídias dinâmicas e acelerar a tomada de decisão do usuário.

---

## 1. Anatomia de uma PDP Mobile de Alta Conversão

O diagrama abaixo sintetiza a integração sinérgica das 7 técnicas em uma experiência fluida:

```
+-------------------------------------------------------------+
|  [ < ] Encapsulated Dock             [ (heart) ] [ (share) ]| <- 1. Contrast-Safe Dock
|-------------------------------------------------------------|
|                                                             |
|                       [ PRODUTO RECORTADO ]                 | <- 2. Systemic Isolation
|                      (Fundo limpo + sombra)                 |
|                                                             |
+-------------------------------------------------------------+
| / \  CABEÇALHO BOTTOM SHEET (Sobe sobre a imagem no scroll)  | <- 6. Persistent Sheet
|-------------------------------------------------------------|
|  Tomates Italianos Orgânicos                                | <- 4. Decoupled Title
|  [ * * * * * ] 4.9 (328 avaliações)                         | <- 3. Title-Rating-Price
|  R$ 14,90 / kg                                              |
|-------------------------------------------------------------|
|  Selecione a porção desejada:                               |
|  ( 500g )  [ 1kg - Mais vendido ]  ( 2kg )                  | <- 5. Behavioral Presets
|-------------------------------------------------------------|
|  Descrição sensorial, colheita, certificação e frescor...   |
|  Especificações técnicas, tabela nutricional e origem...    |
+-------------------------------------------------------------+
|  [ -  1 kg  + ]  |  [ Adicionar ao Carrinho • R$ 14,90 ]    | <- 7. Pre-Committed CTA
+-------------------------------------------------------------+
```

---

## 2. Detalhamento das 7 Técnicas de Conversão

### 1. Encapsulamento de Navegação Multifundo (`Contrast-Safe Navigation Dock`)
- **Problema:** Imagens de catálogo variam infinitamente (fotos com céu branco, fundos pretos ou padrões complexos). Ícones soltos sobre a foto sofrem perda fatal de contraste WCAG.
- **Implementação Técnica:**
  - Envolva cada botão de navegação (Voltar, Favoritar, Compartilhar) em um contêiner circular translúcido.
  - Combine `backdrop-filter: blur(12px)`, cor de preenchimento neutra semi-transparente e uma borda milimétrica de 1px com contraste dinâmico.

```css
.nav-dock-button {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.72);
  backdrop-filter: blur(12px) saturate(160%);
  border: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  color: #111827;
  transition: transform 100ms ease;
}

.nav-dock-button:active {
  transform: scale(0.92);
}

@media (prefers-color-scheme: dark) {
  .nav-dock-button {
    background: rgba(30, 30, 30, 0.75);
    border-color: rgba(255, 255, 255, 0.12);
    color: #f9fafb;
  }
}
```

---

### 2. Produto em Isolamento Sistêmico (`Catalog-Aware Product Isolation`)
- **Problema:** Fotos de produtos tiradas com cenários ruidosos, mãos segurando objetos ou fundos coloridos saturados competem entre si em listagens e destroem a identidade da grade.
- **Diretriz Técnica:**
  - Imagens de produto devem ser isoladas (recortadas em PNG/WebP transparente ou fundo neutro unificado `#FAFAFA` / `#121212`).
  - Mantenha sombras naturais de contato (*drop shadows*) calculadas para assentar o produto fisicamente no espaço.
  - **Enquadramento Proporcional:** Para vendas por peso/granel, fotografe a porção típica consumida, não apenas uma unidade isolada minúscula.

---

### 3. Tríade de Confiança Imediata (`Title-Rating-Price Triad`)
- **Problema:** A mente do comprador processa a decisão em 3 perguntas imediatas: *"O que é?", "É confiável?" e "Quanto custa?"*. Espalhar essas respostas pela página cria sobrecarga de escaneamento.
- **Diretriz Técnica:**
  - Agrupe Título, Avaliação Social e Preço em um bloco vertical compacto no topo do conteúdo.
  - Elimine o rótulo inútil `"Preço:"` — o símbolo monetário (`R$`, `$`, `€`) já informa semanticamente o tipo de dado.
  - Avaliações devem exibir tanto a nota quantitativa (ex: 4.8) quanto o volume total de compradores (ex: `(1.2k)`), clicáveis para âncora direta na seção de reviews.

---

### 4. Sintaxe de Embalagem e Quantidade Autônoma (`Decoupled Spec Title`)
- **Problema:** Incluir o peso fixo no título (ex: *"Café Gourmet Especial Moído 500g"*) quebra a lógica de interface quando o usuário escolhe a opção de 1kg no seletor de porções.
- **Diretriz Técnica:**
  - **Título Limpo:** `"Café Gourmet Especial Moído"`
  - **Especificação Dinâmica:** O volume/peso fica confinado ao seletor de variantes e reflete no cálculo do valor total. Isso melhora a busca interna, evita títulos inflados e elimina devoluções por divergência de embalagem.

---

### 5. Microchips de Preset Comportamental (`Data-Backed Quantity Presets`)
- **Problema:** Steppers convencionais de quantidade exigem 10 toques no botão `+` para atingir quantidades comerciais padrão, gerando fadiga física no usuário móvel.
- **Diretriz Técnica:**
  - Identifique nos logs de transação os volumes mais frequentes de compra (ex: 500g, 1kg, 2kg).
  - Exiba esses atalhos como chips horizontais (*pills*) interativos com feedback de seleção imediato.
  - Destaque discretamente o preset de maior valor ou melhor custo-benefício (ex: badge *"Mais vendido"* ou *"Melhor valor"*).

---

### 6. Cabeçalho com Ancoragem Contextual (`Persistent Context Bottom Sheet`)
- **Problema:** Ao rolar a tela para ler descrições densas, ingredientes ou frete, o usuário perde o contexto do que está avaliando e perde o acesso ao botão de compra.
- **Diretriz Técnica:**
  - O conteúdo informativo sobe em uma lâmina (*sheet*) com cantos superiores arredondados sobrepondo a mídia do produto.
  - **Header Compacto Reativo:** Ao rolar e o título principal sair da viewport, a barra superior de navegação substitui seu estado transparente por um header sólido compacto com o nome do produto e mini-thumbnail.
  - A barra inferior com o CTA permanece fixa (*sticky*) em qualquer altura da página.

---

### 7. Botão de Conversão Transparente e Integrado (`Pre-Committed CTA`)
- **Problema:** Botões de compra isolados com textos genéricos em caixa alta (`COMPRAR AGORA`) intimidam e deixam dúvida sobre o valor final resultante das seleções anteriores.
- **Diretriz Técnica:**
  - Unifique o stepper de quantidade e o botão de ação principal em uma barra de ferramentas no rodapé.
  - Calcule o preço total reativamente e imprima-o dentro do botão:
    `"Adicionar à sacola • R$ 29,80"`
  - Isso remove qualquer ambiguidade de cálculo mental e transmite segurança absoluta ao toque.
