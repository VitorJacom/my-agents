# Regras Comuns para UI Profissional & Checklist Canônico Pré-Entrega

Este documento estabelece os padrões e o checklist canônico obrigatório para entrega final de interfaces de aplicativos móveis nativos e híbridos (iOS, Android, React Native, Flutter) e interfaces web responsivas de alta fidelidade.

---

## 1. Ícones & Elementos Visuais

| Regra | Padrão Obrigatório | O Que Evitar | Por Que Importa |
|---|---|---|---|
| **Sem Emojis como Ícones Estruturais** | Use ícones vetoriais padronizados (Lucide, Heroicons, react-native-vector-icons). | Usar emojis (🎨, 🚀, ⚙️) para navegação, configurações ou ações do sistema. | Emojis variam por sistema operacional e versão de fonte, quebram consistência e não aceitam tokens de design. |
| **Apenas Ativos Vetoriais** | Utilize SVGs ou ícones vetoriais escaláveis que suportem temas. | Imagens rasterizadas PNG/JPG que pixelam ou perdem nitidez em alta densidade. | Assegura nitidez impecável em telas Retina e adaptação automática entre light e dark mode. |
| **Semântica Contextual de Ícone** | Decida a semântica pelo uso: ícone ao lado de texto visível é decorativo (`aria-hidden="true"`); ícone isolado exige texto alternativo e estado. | Tratar um mesmo glifo sempre como decorativo ou sempre como interativo. | O mesmo glifo cumpre funções distintas em componentes diferentes. |
| **Estados de Interação Estáveis** | Transicione apenas cor, opacidade ou elevação no toque, sem alterar as dimensões da caixa. | Usar transformações que desloquem o layout vizinho ou causem trepidação (*jittering*). | Mantém a estabilidade da tela e transmite acabamento de alta qualidade no toque móvel. |
| **Logos Oficiais de Marcas** | Aplique os ativos oficiais respeitando proporções e área de respiro recomendadas. | Recortar logotipos de prints, adivinhar cores de marca ou distorcer proporções. | Preserva a integridade visual da marca e evita infrações visuais. |
| **Dimensionamento Padronizado** | Defina tamanhos de ícones por tokens (`icon-sm` = 16px, `icon-md` = 24px, `icon-lg` = 32px). | Misturar tamanhos arbitrários (20px, 23px, 27px) na mesma tela sem motivo. | Mantém o ritmo óptico e a hierarquia visual consistente. |
| **Consistência de Traço (Stroke)** | Mantenha a mesma espessura de traço na mesma camada da tela (ex: 1.5px ou 2px). | Mesclar ícones com traços grossos de 2.5px com outros de 1px na mesma barra. | Traços discrepantes transmitem sensação imediata de montagem amadora. |
| **Disciplina de Filled vs. Outline** | Utilize um único estilo por nível hierárquico, reservando filled para o estado selecionado. | Misturar aleatoriamente ícones preenchidos e vazados na mesma lista inativa. | Garante clareza semântica e reforça a percepção do estado ativo. |
| **Hitbox Mínima de Toque** | No mínimo **44x44pt no iOS** e **48x48dp no Android**; expanda a hitbox invisível se o ícone for menor. | Ícones com área clicável restrita ao tamanho visual do desenho (ex: 16x16px). | Atende à ergonomia fisiológica da ponta do dedo humano. |
| **Alinhamento Óptico** | Alinhe os ícones à linha de base (*baseline*) do texto e mantenha margem interna uniforme. | Ícones ligeiramente deslocados para cima ou colados na tipografia. | Elimina desequilíbrios ópticos sutis que incomodam a leitura. |
| **Contraste de Ícones** | Ícones com significado ou bordas de controles devem ter no mínimo **3:1** contra o fundo. | Ícones em tons cinza quase invisíveis que carregam informação de status. | Garante acessibilidade visual mesmo sob reflexo de luz solar direta. |

---

## 2. Interação em Aplicativos Móveis

| Regra | O Que Fazer (Do) | O Que Evitar (Don't) |
|---|---|---|
| **Feedback de Toque Imediato** | Fornecer resposta visual de clique (contração de escala, ripple ou opacidade) em até **80–150ms**. | Nenhuma resposta visual após o toque na tela. |
| **Temporização Compartilhada** | Utilizar tokens globais de movimento parametrizados para distância e contexto. | Copiar uma duração estática arbitrária para todas as transições do app. |
| **Foco e Acessibilidade** | Garantir que a ordem de leitura do leitor de tela coincida rigorosamente com a ordem visual. | Controles sem rótulo textual ou travessia confusa de foco. |
| **Clareza de Estado Desabilitado** | Aplicar opacidade reduzida (0.38–0.5), atributo `disabled` e supressão total do evento de toque. | Controles que parecem clicáveis, mas não produzem efeito nenhum. |
| **Prevenção de Conflito de Gestos** | Manter apenas um gesto primário por região, evitando concorrer com a rolagem vertical. | Gestos sobrepostos que disparam ações acidentais enquanto o usuário rola a lista. |
| **Controles Nativos Semânticos** | Preferir componentes nativos (`Button`, `Pressable`, `<button>`) com papéis corretos. | `div` ou `View` genérica fingindo ser botão sem acessibilidade e sem foco. |

---

## 3. Contraste & Paridade Light / Dark Mode

| Regra | O Que Fazer (Do) | O Que Evitar (Don't) |
|---|---|---|
| **Legibilidade de Superfícies (Light)** | Separar cards e lâminas do fundo com opacidade suficiente ou borda de contenção sutil. | Superfícies translúcidas excessivas que borram o texto contra o fundo. |
| **Contraste de Texto (Light)** | Manter contraste de texto normal $\ge$ **4.5:1** contra superfícies claras. | Texto em cinza claro apagado sobre fundos brancos. |
| **Contraste de Texto (Dark)** | Manter texto normal $\ge$ **4.5:1** sobre superfícies escuras (3:1 é exclusivo para títulos display). | Textos cinzas secundários que caem abaixo da linha de legibilidade no dark mode. |
| **Visibilidade de Bordas** | Garantir que linhas divisórias e bordas permaneçam perceptíveis em ambos os modos. | Bordas que desaparecem completamente quando o tema escuro é ativado. |
| **Paridade de Estados** | Testar se estados de foco, hover e pressionado são igualmente distinguíveis em ambos os temas. | Ajustar estados de interação apenas para o tema claro. |
| **Temas Conduzidos por Tokens** | Utilizar tokens semânticos mapeados por tema (`bg-surface`, `text-primary`, `border-subtle`). | Hardcoded hexadecimais espalhados no código do componente. |
| **Legibilidade de Scrim e Modal** | Avaliar o scrim (fundo escurecido) sobreposto a fundos dinâmicos para isolar o modal. | Reutilizar uma opacidade genérica sem testar contra imagens claras ou ruidosas. |

---

## 4. Diagramação & Espaçamento Móvel

| Regra | O Que Fazer (Do) | O Que Evitar (Don't) |
|---|---|---|
| **Conformidade com Safe Area** | Respeitar as áreas seguras superiores e inferiores em todos os headers e bottom bars (`env(safe-area-inset-bottom)`). | Colar botões fixos sob o notch ou sobre a barra de gestos do sistema operacional. |
| **Espaçamento de Ritmo 8dp** | Utilizar sistema modular em incrementos de **4px / 8px** para paddings, gaps e margens. | Espaçamentos aleatórios e inconsistentes (11px, 17px, 23px). |
| **Comprimento de Linha de Leitura** | Manter textos longos contidos em larguras confortáveis (evitar parágrafos infinitos em tablets). | Texto esticado de ponta a ponta que esgota a visão do leitor. |
| **Hierarquia Vertical de Seções** | Definir escalas claras de separação vertical (ex: 16px intra-componente, 32px seções, 48px blocos). | Níveis distintos de conteúdo separados pela mesma margem indistinta. |
| **Coexistência de Scroll e Elementos Fixos** | Adicionar preenchimento compensatório no fim da lista rolável para que o último item não seja coberto pela barra fixa. | Último botão ou linha da tabela escondida sob a barra de navegação inferior. |

---

## 5. Checklist Canônico Pré-Entrega (Canonical Pre-Delivery Checklist)

Antes de finalizar qualquer entrega de código ou interface, verifique **todos os itens** desta lista:

### Processo & Validação de Ambiente
- [ ] O código foi testado em viewport de **375px** (smartphone padrão) e em orientação **paisagem**.
- [ ] O comportamento foi validado com **`prefers-reduced-motion`** ativado (sem saltos de tela).
- [ ] O layout suporta escalonamento de fontes do sistema (**Dynamic Type**) sem cortes ou truncamentos graves.
- [ ] O contraste do **Dark Mode** foi verificado de forma independente (não inferido a partir do light mode).
- [ ] Todos os alvos de toque têm área $\ge$ **44pt / 48dp** e nenhuma informação ficou sob a safe-area.

### Qualidade Visual & Ícones
- [ ] **Nenhum emoji** foi utilizado como ícone de navegação ou controle funcional (apenas SVGs vetorizados).
- [ ] Todos os ícones pertencem à mesma família e compartilham espessura de traço e raio consistentes.
- [ ] Logotipos de marcas oficiais utilizam proporções corretas e área de respiro adequada.
- [ ] Efeitos de clique/pressão não alteram dimensões de layout nem causam trepidação (*jittering*).
- [ ] Tokens semânticos são utilizados rigorosamente (zero cores hexadecimais arbitrariamente isoladas).

### Interação & Ergonomia
- [ ] Todo controle clicável oferece feedback visual perceptível em menos de **100ms** (`scale(0.97)` ou highlight).
- [ ] A temporização de microinterações utiliza tokens globais e respeita o teto de **300ms** para UI funcional.
- [ ] Estados desabilitados são visíveis, não-interativos e comunicados ao leitor de tela.
- [ ] A ordem de foco por teclado/leitor de tela coincide exatamente com a ordem visual da interface.
- [ ] Regiões de gestos não concorrem entre si (sem conflito de arraste com scroll da tela).

### Paridade de Contraste Light / Dark
- [ ] Contraste do texto principal $\ge$ **4.5:1** em ambos os modos (claro e escuro).
- [ ] Contraste do texto secundário $\ge$ **4.5:1** em ambos os modos.
- [ ] Divisores, separadores e bordas permanecem nítidos e distinguíveis em ambos os temas.
- [ ] O scrim de modais e gavetas foi medido contra o fundo real e garante isolamento seguro.

### Layout & Safe Area
- [ ] `padding-bottom: env(safe-area-inset-bottom, 34px)` presente em todas as barras fixas inferiores.
- [ ] As listas roláveis possuem preenchimento de rodapé compensatório para não serem cortadas pela barra fixa.
- [ ] O ritmo de espaçamento em incrementos de 4px / 8px é mantido em todos os níveis.
- [ ] Textos longos contêm quebra de linha confortável mesmo em telas de tablets.

### Acessibilidade (a11y)
- [ ] Ícones decorativos ao lado de texto possuem `aria-hidden="true"`.
- [ ] Ícones isolados possuem `aria-label` ou texto descritivo correspondente.
- [ ] Todos os campos de formulário possuem `<label>` visível e mensagens de erro conectadas via `aria-describedby`.
- [ ] Informações críticas nunca dependem exclusivamente de variação de cor.
- [ ] Ações perigosas ou exclusões exigem confirmação ou fornecem opção de desfazer (*undo*).
