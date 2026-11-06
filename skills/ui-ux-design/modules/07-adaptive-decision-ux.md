# Módulo 07: Arquitetura Adaptativa, UX Writing & Heurísticas Cognitivas

Este módulo reúne os princípios de adaptação ao ciclo de vida do usuário, estados vazios ativos, seleção situacional de inputs, redação funcional ativa e densidade consciente.

---

## Técnica 01: Arquitetura de Maturidade do Usuário (`User-Stage Adaptive UI`)
- **Problema:** Apresentar a mesma tela genérica para um novato e para um power user sobrecarrega o iniciante e desacelera o experiente.
- **Estágios de Adaptação:**
  - **Novo Usuário (Onboarding):** Acolhimento, metas básicas, checklists simples e time-to-value acelerado.
  - **Usuário Recorrente (Operacional):** Foco imediato na rotina do dia, tarefas pendentes e ações em 1 clique.
  - **Super Usuário (Power User):** Densidade de informação, tabelas completas, filtros multicritério, atalhos de teclado e exportações.

---

## Técnica 02: Busca Ativa Antecipatória (`Proactive Empty Search`)
- **Problema:** Exibir uma tela em branco ao tocar na barra de busca transfere todo o esforço mental para o usuário.
- **Camadas do Estado Vazio Ativo:**
  1. Histórico de buscas recentes (com atalho para limpar).
  2. Tendências e itens populares da comunidade.
  3. Sugestões e recomendações contextuais personalizadas.
  - *Regra:* Os blocos desaparecem suavemente assim que a digitação começa.

---

## Técnica 05: Seleção Situacional de Input (`Context-Driven Input Mapping`)
- **Problema:** Escolher controles inadequados (ex: slider para dados exatos ou texto livre para números).
- **Matriz de Decisão:**
  - **Casual / Onboarding:** Sliders ou seletores deslizantes para faixas conhecidas (idade, altura aproximada).
  - **Frequente / Alta Precisão:** Campo de texto numérico com keypad dedicado (`inputmode="numeric"`) ou stepper (+ / -).
  - **2 a 4 Opções:** Segmented control ou botões de alternância.
  - **Muitas Opções (> 7):** Combobox com busca integrada.

---

## Técnica 12: Arquitetura de Microcopy e Redação Ativa de UX (`UX Writing & Action-Oriented Microcopy`)
- **Princípio:** Palavras são material de design funcional.
- **Diretrizes de Microcopy:**
  1. **Perspectiva do Usuário:** Nomeie ações pelo que o usuário faz (*"Notificações"*, não *"Webhook Listeners"*).
  2. **CTAs em Voz Ativa e Específicos:** *"Salvar alterações"*, *"Criar conta"* (evite *"Enviar"*, *"OK"*).
  3. **Coesão Vocabular Estrita:** Botão *"Publicar"* $\rightarrow$ Diálogo *"Publicar este artigo?"* $\rightarrow$ Toast *"Artigo publicado"*.
  4. **Erros e Telas Vazias Orientados à Ação:** Declare o problema e ofereça a saída imediata, sem desculpas vagas.
  5. **Sentence Case Universal:** Prefira capitalização normal de frase.

---

## Técnica 33: Anatomia de Navegação Proporcional (`In-Context Tab Switching`)
- **Regra:** Reserve as abas embutidas arredondadas (*inset tabs*) para alternâncias contextuais locais dentro do mesmo bloco (ex: toggle `Prévia / Código` ou `Mês / Ano`).
- Para rotas mestras da aplicação, adote abas planas com sublinhado (*underline tabs*) ou menus laterais.

---

## Técnica 35: Prototipagem de Forma Antes do Esquema (`Interface-First Experimentation`)
- Iniciar o produto modelando esquemas de banco de dados trava o raciocínio em tabelas rígidas.
- Rascunhe primeiro a tela e a interação visual no frontend (mesmo em mock estático rápido). Descubra o fluxo ergonômico ideal antes de modelar endpoints e bancos de dados.

---

## Técnica 36: Convergência por Divergência Multimodelo (`Multi-Model Synthesis`)
- Não confie na primeira resposta de um único prompt em uma única ferramenta.
- Submeta o desafio em paralelo a diferentes ferramentas/modelos (v0, Cursor, Lovable) e garimpe os melhores microdetalhes de cada um para compor a versão final.

---

## Técnica 40: Funil de Refinamento Trifásico (`The 80/20 Refinement Cycle`)
- Separe o processo criativo em 3 fases:
  1. Geração Funcional dos 80% brutos sem bloqueio criativo de microdesign.
  2. Injeção de skills modulares de fundamentos (tipografia e grid).
  3. Ajuste fino humano dos 20% decisivos com comparação V1 vs. V2 lado a lado.

---

## Técnica 42: Calibração de Densidade Situacional (`Context-Tuned Density`)
- Ajuste a proporção visual conforme o propósito da página:
  - Telas de dados/tabelas/diretórios: tipografia compacta (`13px`/`14px`), entrelinha compacta (`leading-snug`), ícones alinhados à esquerda e rótulos em Sentence Case.
  - Landing pages: tipografia ampla e espaçamento expandido.

---

## Técnica 43: Grade Compacta de Preenchimento Contínuo (`Auto-Flow Masonry`)
- Utilize layout em alvenaria via `column-count` no CSS com `break-inside: avoid` em cada item.
- Permite que listas menores subam imediatamente para preencher o vácuo de listas vizinhas mais longas, eliminando buracos assimétricos na tela.
