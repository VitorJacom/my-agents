# Módulo 04: E-Commerce, Catálogos & Conversão Mobile (PDP)

Este módulo reúne as regras de usabilidade, psicologia de catálogo e engenharia de páginas de produto para acelerar a tomada de decisão do usuário e eliminar pontos de atrito cognitivo.

---

## Técnica 03: Rastreio Tranquilizador Pós-Conversão (`Reassurance Timeline UX`)
- **Problema:** A fase pós-compra gera estresse e ansiedade cognitiva; listar apenas códigos e textos corridos sobrecarrega o suporte.
- **Implementação:**
  - Mensagem de confiança destacada no topo (ex: *"Seu pedido está a caminho"*).
  - Humanização: foto e nome do entregador ou responsável com atalhos de chamada e mensagem em 1 toque.
  - Linha do tempo visual horizontal/vertical com etapas claras (Confirmado $\rightarrow$ Em preparação $\rightarrow$ Em trânsito $\rightarrow$ Entregue).

---

## Técnica 04: Grade Semântica Harmonizada (`Cohesive Taxonomy Grid`)
- **Problema:** Listas em texto simples são monótonas; cartões com fotos aleatórias de banco de imagens criam conflito de contraste e poluição cromática.
- **Implementação:**
  - Fundo sólido ou tom pastel suave padronizado pelo Design System.
  - Imagens de produtos isoladas (recortadas/sem fundo) com estilo e iluminação equivalentes.
  - Rótulos tipográficos consistentes com contraste WCAG AA validado sobre a cor do card.

---

## Técnica 15: Produto em Isolamento Sistêmico (`Catalog-Aware Product Isolation`)
- **Problema:** Fotos com cenários ruidosos ou fundos saturados competem entre si e arruínam a grade do e-commerce.
- **Implementação:**
  - Isole o produto em fundo neutro (#FAFAFA / #121212) ou formato transparente com sombra natural de contato.
  - **Enquadramento Proporcional:** Para vendas por peso/lote, retrate a porção típica consumida (e não uma unidade solitária minúscula).

---

## Técnica 16: Tríade de Confiança Imediata (`Title-Rating-Price Triad`)
- **Problema:** A mente do comprador processa a decisão em 3 perguntas: *"O que é?", "É confiável?" e "Quanto custa?"*. Espalhar esses dados cria fadiga ocular.
- **Implementação:**
  - Posicione Título, Classificação por estrelas + volume de reviews (`★ 4.9 (420)`) e Preço de forma contígua no topo.
  - **Elimine Rótulos Redundantes:** Nunca escreva `"Preço: R$ 49,90"`. O símbolo de moeda já informa a função.

---

## Técnica 17: Sintaxe de Embalagem e Quantidade Autônoma (`Decoupled Spec Title`)
- **Problema:** Incluir peso fixo no título (ex: *"Café 500g"*) quebra a lógica quando o cliente seleciona a opção de 1kg no seletor de variantes.
- **Implementação:**
  - O título do item contém apenas a nomenclatura e variante qualitativa (ex: *"Café Gourmet Especial Moído"*).
  - A métrica de peso/volume (kg, g, L, un) reside unicamente dentro do componente seletor de porções e no cálculo de valor total.

---

## Técnica 18: Microchips de Preset Comportamental (`Data-Backed Quantity Presets`)
- **Problema:** Tocar 10 vezes no botão `+` de um contador numérico gera cansaço motor em compras frequentes ou por volume.
- **Implementação:**
  - Mapeie os volumes padrão mais comprados (ex: `500g`, `1kg`, `2kg`).
  - Apresente chips/pills interativos de seleção rápida logo acima do botão de compra.
  - Destaque o preset mais vendido ou de melhor custo-benefício, mantendo o controle stepper para quantidades atípicas.

---

## Técnica 20: Botão de Conversão Transparente e Integrado (`Pre-Committed CTA`)
- **Problema:** Botões agressivos e isolados geram dúvida sobre o valor total final debitado.
- **Implementação:**
  - Una o stepper de quantidade e o botão de conversão na mesma barra de ação inferior.
  - Calcule o total reativamente e imprima-o dentro do botão em Sentence Case:
    `"Adicionar à sacola • R$ 38,50"`
