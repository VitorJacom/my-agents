# Conjunto Canônico de Regras de UI/UX (10 Categorias Completas)

Este documento compila as diretrizes e regras exaustivas para auditorias e revisões de qualidade de interface. Cada regra possui um identificador unívoco para facilitar citações e testes automatizados.

---

## 1. Acessibilidade (CRÍTICA)

- `color-contrast`: Razão mínima de contraste de 4.5:1 para texto normal e 3:1 para texto grande (WCAG AA, Material Design).
- `focus-states`: Anéis de foco visíveis de 2px a 4px em elementos interativos acessados por teclado.
- `alt-text`: Texto alternativo descritivo para imagens funcionais e informativas.
- `aria-labels`: Atributo `aria-label` para botões com ícones isolados; `accessibilityLabel` em plataformas nativas (Apple HIG).
- `icon-context`: Semântica baseada no uso: ícones decorativos ao lado de texto visível devem ser ocultados da árvore de acessibilidade (`aria-hidden="true"`); ícones com significado exigem alternativa textual; controles de ícone exigem rótulo acessível e estado de seleção.
- `keyboard-nav`: Ordem do Tab coincidente com a ordem visual da tela; suporte total a teclado em modais e fluxos interativos.
- `form-labels`: Associação estrita de `<label>` via atributo `for` / `htmlFor` ao campo correspondente.
- `skip-links`: Link para "Pular para o conteúdo principal" no topo da página para usuários de leitores de tela e teclado.
- `heading-hierarchy`: Hierarquia sequencial estrita de títulos (h1 $\to$ h2 $\to$ h3), sem pular níveis hierárquicos.
- `color-not-only`: Nunca transmita informações exclusivamente através de cor (sempre adicione texto de apoio ou ícone).
- `dynamic-type`: Suporte a escalonamento de texto do sistema operacional sem quebras ou truncamentos indesejados.
- `reduced-motion`: Respeito rigoroso a `prefers-reduced-motion`; redução ou remoção de transições espaciais amplas.
- `voiceover-sr`: Ordem lógica e rótulos acessíveis significativos para VoiceOver e leitores de tela.
- `escape-routes`: Oferecer tecla Escape e botão visível de voltar/cancelar em modais e fluxos de múltiplos passos.
- `keyboard-shortcuts`: Preservar atalhos globais do sistema e oferecer alternativas por teclado para ações de drag-and-drop.
- `focus-not-obscured`: Barras fixas, cabeçalhos e banners nunca devem cobrir o elemento que detém o foco de teclado (WCAG 2.2 AA).
- `focus-not-obscured-enhanced`: Manter o componente em foco integralmente visível sem qualquer sobreposição parcial (WCAG 2.2 AAA).
- `focus-appearance`: Indicador de foco com área suficiente e contraste de estado mínimo de 3:1 contra o plano adjacente.
- `dragging-alternative`: Toda ação de arraste controlada pela aplicação exige alternativa via clique único e atalho de teclado.
- `web-target-size`: Alvos de toque na web necessitam de no mínimo 24x24 pixels CSS contíguos ou exceção documentada.
- `consistent-help`: Mecanismos de suporte e ajuda repetidos devem manter a mesma ordem relativa em todas as páginas.
- `redundant-entry`: Reutilizar dados já informados pelo usuário no mesmo fluxo sem forçar redigitação redundante.
- `accessible-authentication`: Permitir preenchimento por gerenciadores de senhas e atalhos de colar; fornecer via não-cognitiva de autenticação.
- `auto-rotation-controls`: Carrosséis automáticos e mídias móveis exigem botões explícitos de pausar/parar e devem parar ao receber foco.
- `contextual-live-badge-updates`: Anunciar mudanças de contadores ou status como frase contextualizada sem mover o foco do usuário.

---

## 2. Toque & Interação Móvel (CRÍTICA)

- `touch-target-size`: Área de toque de no mínimo 44x44pt no iOS e 48x48dp no Android; expanda a hitbox invisível se o ícone for menor.
- `touch-spacing`: Espaçamento mínimo de 8px / 8dp entre controles adjacentes para evitar toques acidentais.
- `hover-vs-tap`: Utilize clique/toque para ações primárias; nunca condicione funcionalidades essenciais ao hover de mouse.
- `loading-buttons`: Desabilite o botão durante operações assíncronas e exiba indicador visual de progresso.
- `error-feedback`: Exiba mensagens de erro diretamente adjacentes ao campo com falha.
- `cursor-pointer`: Adicione `cursor: pointer` a elementos interativos na web desktop.
- `gesture-conflicts`: Evite gestos de deslize horizontal sobre o conteúdo principal se ele conflitar com o scroll da página.
- `tap-delay`: Aplique `touch-action: manipulation` para remover o atraso de 300ms do duplo toque na web móvel.
- `standard-gestures`: Utilize gestos padronizados da plataforma (swipe-back, pinch-to-zoom) sem reinventar convenções consolidadas.
- `system-gestures`: Nunca bloqueie gestos nativos do sistema operacional (Central de Controle, barra de gestos inferior).
- `press-feedback`: Forneça resposta visual imediata no toque (`active` com leve escala ou highlight) em menos de 100ms.
- `haptic-feedback`: Empregue vibração tátil para confirmações críticas e sucessos, evitando uso banalizado.
- `gesture-alternative`: Ações críticas acionadas por gesto devem sempre possuir um botão visível alternativo.
- `safe-area-awareness`: Mantenha controles primários afastados do notch, Dynamic Island, barra de gestos e cantos arredondados.
- `no-precision-required`: Evite exigir toques com precisão cirúrgica em ícones minúsculos ou arestas finas.
- `swipe-clarity`: Ações acionadas por swipe devem exibir dicas visuais claras (setas, chevron ou revelação parcial).
- `drag-threshold`: Defina um limiar mínimo de deslocamento antes de iniciar o arraste para prevenir disparos acidentais ao rolar a tela.

---

## 3. Performance & Eficiência de Renderização (ALTA)

- `image-optimization`: Utilize formatos modernos (WebP, AVIF), dimensionamento responsivo (`srcset`) e lazy loading para mídias secundárias.
- `image-dimension`: Declare largura e altura explícitas ou use `aspect-ratio` para evitar deslocamento de layout (Cumulative Layout Shift - CLS).
- `font-loading`: Aplique `font-display: swap` ou `optional` para mitigar texto invisível (FOIT) e reserve espaço tipográfico.
- `font-preload`: Faça pré-carregamento exclusivamente das fontes críticas do primeiro frame (*above-the-fold*).
- `critical-css`: Priorize o CSS crítico das primeiras dobras para renderização sem bloqueio de rede.
- `lazy-loading`: Carregue componentes fora do primeiro frame sob demanda via `dynamic import` / `Suspense`.
- `bundle-splitting`: Divida os pacotes JS por rota e funcionalidade para diminuir o Time to Interactive (TTI).
- `third-party-scripts`: Scripts de terceiros devem carregar com `async` ou `defer`.
- `reduce-reflows`: Evite leituras seguidas de escrita no DOM que disparam layout thrashing.
- `content-jumping`: Reserve espaços para banners e conteúdos dinâmicos para prevenir saltos de tela durante o carregamento.
- `lazy-load-below-fold`: Atribua `loading="lazy"` a imagens localizadas abaixo da dobra inicial.
- `virtualize-lists`: Virtualize listas com mais de 50 elementos para manter o consumo de memória baixo e a rolagem suave.
- `main-thread-budget`: Mantenha o trabalho de execução por quadro abaixo de 16ms (60fps) e mova cálculos pesados para Web Workers.
- `progressive-loading`: Utilize telas de esqueleto (*skeletons/shimmer*) em vez de spinners bloqueantes para esperas superiores a 1 segundo.
- `input-latency`: Mantenha a latência de resposta ao toque e clique abaixo de 100ms.
- `tap-feedback-speed`: O feedback visual de clique deve ocorrer em até 100ms da soltura do ponteiro.
- `debounce-throttle`: Aplique debounce ou throttle a eventos de alta frequência (scroll, resize, digitação).
- `offline-support`: Forneça mensagens informativas de estado offline e cache básico de leitura.
- `network-fallback`: Proporcione modos degradados e mídias de menor resolução em conexões lentas.

---

## 4. Estilo & Consistência de Design System (ALTA)

- `style-match`: Harmonize o estilo visual com o segmento do produto (evite layouts lúdicos em ambientes bancários e vice-versa).
- `consistency`: Mantenha a mesma linguagem visual em todas as rotas e sub-telas do sistema.
- `no-emoji-icons`: Proibição absoluta de emojis como ícones de navegação ou controles de sistema; use SVGs vetorizados.
- `color-palette-from-product`: Selecione a paleta com base nas convenções e vocabulário do setor atendido.
- `effects-match-style`: Sombras, raios de arredondamento e níveis de desfoque consistentes com a escala do design system.
- `platform-adaptive`: Respeite as convenções nativas de cada plataforma (iOS HIG vs Material Design).
- `state-clarity`: Estados de foco, clique, hover e desabilitação devem ser visualmente distinguíveis entre si.
- `elevation-consistent`: Utilize uma escala padronizada de elevação e sombras para cards, modais e lâminas.
- `dark-mode-pairing`: Desenvolva simultaneamente as variantes clara e escura para assegurar equivalência de contraste e marca.
- `icon-style-consistent`: Utilize uma única biblioteca e espessura de traço (ex: Lucide com stroke de 1.5px ou 2px).
- `system-controls`: Prefira controles nativos do sistema operacional, personalizando apenas quando indispensável à identidade.
- `blur-purpose`: Empregue desfoque gaussiano exclusivamente para isolamento funcional de planos (modais, sheets), nunca como adorno.
- `primary-action`: Cada visão deve conter apenas uma Call to Action primária; os demais botões devem ser visualmente subordinados.

---

## 5. Layout & Responsividade (ALTA)

- `viewport-meta`: Metatag `width=device-width, initial-scale=1` obrigatória; nunca bloqueie zoom do usuário.
- `mobile-first`: Projete primeiro para dispositivos móveis e expanda progressivamente para tablets e desktops.
- `breakpoint-consistency`: Utilize pontos de quebra padronizados (ex: 375px, 768px, 1024px, 1440px).
- `readable-font-size`: Tamanho mínimo de 16px para texto de corpo em mobile para prevenir zoom automático no iOS Safari.
- `line-length-control`: Entre 35 e 60 caracteres por linha em telas móveis; entre 60 e 75 caracteres em desktops.
- `horizontal-scroll`: Proibição estrita de rolagem horizontal não intencional na viewport móvel.
- `spacing-scale`: Adote o sistema métrico de espaçamento modular em incrementos de 4px / 8px.
- `touch-density`: Garanta espaçamento confortável entre elementos interativos para prevenir erros de digitação e toque.
- `container-width`: Largura máxima previsível em telas amplas (ex: `max-w-6xl` ou `max-w-7xl`).
- `z-index-management`: Escale as camadas de profundidade em valores semânticos previsíveis (ex: 0, 10, 20, 40, 100, 1000).
- `fixed-element-offset`: Barras fixas no topo ou rodapé devem reservar preenchimento correspondente no container de rolagem.
- `scroll-behavior`: Evite containers com rolagens aninhadas concorrentes que quebrem o scroll do documento.
- `viewport-units`: Prefira `min-h-dvh` a `100vh` em mobile para evitar saltos provocados pelas barras dinâmicas do navegador.
- `orientation-support`: O layout deve permanecer legível e operável em modo paisagem.
- `content-priority`: Priorize o conteúdo central em dispositivos móveis, recolhendo informações acessórias em gavetas.
- `visual-hierarchy`: Estabeleça hierarquia através de tamanho, contraste e espaço negativo, não apenas por variação de cor.
- `compact-label-overflow`: Trate o truncamento de chips e tags sem perder a legibilidade, oferecendo tooltip ou expansão.
- `chip-collection-reflow`: Permita que coleções de chips quebrem linha antes de comprimir seus textos a ponto de ficarem ilegíveis.

---

## 6. Tipografia & Cores (MÉDIA)

- `line-height`: Entrelinha de 1.5 a 1.75 para textos de leitura contínua.
- `line-length`: Limite a largura de colunas de texto entre 65 e 75 caracteres por linha para conforto visual.
- `font-pairing`: Combine no máximo duas famílias tipográficas complementares (uma para display/títulos e uma neutra para corpo).
- `font-scale`: Utilize uma escala tipográfica harmônica (ex: 12px, 14px, 16px, 18px, 24px, 32px, 48px).
- `contrast-readability`: Textos de alto contraste sobre fundos claros (ex: `slate-900` sobre branco).
- `text-styles-system`: Adote papéis tipográficos semânticos (display, headline, title, body, label).
- `weight-hierarchy`: Diferencie níveis de importância por peso antes de recorrer a aumentos drásticos de tamanho.
- `color-semantic`: Defina tokens semânticos (`color-primary`, `color-surface`, `color-danger`) em vez de códigos hexadecimais brutos.
- `color-dark-mode`: O modo escuro exige variantes tonais desaturadas e superfícies cinzas com profundidade, não inversão direta de cores.
- `color-accessible-pairs`: Pares de texto e plano de fundo devem alcançar conformidade mínima WCAG AA (4.5:1).
- `color-not-decorative-only`: Cores funcionais (verde para sucesso, vermelho para perigo) devem ser acompanhadas de texto ou ícone.
- `truncation-strategy`: Prefira quebra de linha à reticências abruptas; se truncar, garanta acesso ao texto integral via tooltip ou toque.
- `letter-spacing`: Respeite as tabelas ópticas: tracking negativo em títulos grandes e neutro/positivo em corpos e legendas.
- `number-tabular`: Aplique números monoespaçados (`tabular-nums`) em tabelas financeiras, cronômetros e preços.
- `whitespace-balance`: Utilize espaço em branco deliberadamente para agrupar tópicos correlatos pela Lei da Proximidade.
- `heading-line-balance`: Use `text-wrap: balance` em títulos curtos para evitar palavras órfãs na última linha.
- `long-token-wrapping`: Permita que identificadores longos e URLs quebrem linha com `overflow-wrap: anywhere`.

---

## 7. Animação & Movimento (MÉDIA)

- `duration-timing`: Escolha durações proporcionais à distância e contexto, mantendo respostas de UI abaixo de 300ms.
- `transform-performance`: Anime exclusivamente `transform` e `opacity` para acelerar na GPU.
- `loading-states`: Evite flashes de indicadores de carregamento para ações que duram menos de 200ms.
- `excessive-motion`: Limite o movimento simultâneo a no máximo 1 ou 2 elementos chave por visão.
- `easing`: Desaceleração na chegada (`ease-out`), aceleração na saída, e movimento linear apenas para rotações contínuas.
- `motion-meaning`: Cada animação deve expressar relação funcional de causa e efeito, nunca servindo apenas como adorno.
- `state-transition`: Mudanças de estado devem transicionar de forma fluida, sem saltos abruptos.
- `continuity`: Telas subsequentes devem manter continuidade espacial (elementos compartilhados ou deslizamento direcional).
- `parallax-subtle`: Efeitos de paralaxe devem ser contidos e respeitar configurações de redução de movimento.
- `spring-physics`: Prefira molas físicas a tempos fixos quando houver gestos com momento e velocidade inicial.
- `exit-faster-than-enter`: Transições de saída devem ser de 30% a 40% mais rápidas que as de entrada.
- `stagger-sequence`: Em listas e grades, aplique atraso cascata curto entre 30ms e 50ms por item.
- `shared-element-transition`: Transições de elemento compartilhado mantêm a orientação do usuário entre visões.
- `interruptible`: Animações devem ser interrompíveis no ar ao toque do usuário sem engasgos.
- `no-blocking-animation`: A interface nunca deve bloquear a entrada do usuário enquanto uma animação ocorre.
- `fade-crossfade`: Use crossfade para substituição de conteúdo dentro do mesmo container visual.
- `scale-feedback`: Contração sutil em escala (`scale(0.97)`) ao pressionar cards e botões.
- `gesture-feedback`: Arraste e pinça devem fornecer retorno visual instantâneo 1:1 acompanhando o dedo.
- `hierarchy-motion`: Entradas a partir da base indicam profundidade; saídas para baixo indicam retorno ao nível superior.
- `motion-consistency`: Mantenha tokens globais de curvas e durações compartilhados por toda a aplicação.
- `opacity-threshold`: Elementos em esmaecimento não devem permanecer abaixo de 0.2 de opacidade; finalize a transição de forma limpa.
- `modal-motion`: Modais e popovers devem surgir ancorados ao seu gatilho com `transform-origin` dinâmico.
- `navigation-direction`: Navegação para a frente desliza para a esquerda; voltar desliza para a direita.
- `layout-shift-avoid`: Animações nunca devem provocar saltos estruturais nos elementos adjacentes.
- `cancellable-state-transitions`: Disparos rápidos devem cancelar a microinteração anterior e definir o estado final com segurança.

---

## 8. Formulários & Feedback de Ação (MÉDIA)

- `input-labels`: Rótulos sempre visíveis acima do campo, nunca utilizando apenas placeholders textuais.
- `error-placement`: Mensagem de erro explícita logo abaixo do campo afetado, conectada por `aria-describedby`.
- `submit-feedback`: Exibir estado de carregamento no botão de envio seguido de retorno de sucesso ou erro.
- `required-indicators`: Marcar claramente os campos obrigatórios.
- `empty-states`: Fornecer estado vazio instrutivo com explicação e ação principal quando não houver dados.
- `toast-dismiss`: Fechamento automático de toasts entre 3 e 5 segundos, com opção de descarte manual.
- `confirmation-dialogs`: Exigir confirmação explícita antes de ações destrutivas irreversíveis.
- `input-helper-text`: Oferecer texto auxiliar permanente abaixo de campos com regras complexas.
- `disabled-states`: Elementos desabilitados devem exibir opacidade reduzida (0.4–0.5) e atributo semântico correspondente.
- `progressive-disclosure`: Revelar parâmetros avançados de forma gradual para não sobrecarregar o usuário inicial.
- `inline-validation`: Validar entradas ao sair do campo (`onBlur`), nunca a cada tecla digitada antes do usuário terminar.
- `input-type-keyboard`: Utilizar os tipos semânticos (`email`, `tel`, `numeric`) para invocar o teclado móvel correto.
- `password-toggle`: Disponibilizar botão para alternar a visibilidade de caracteres em campos de senha.
- `autofill-support`: Incluir atributos `autocomplete` para permitir preenchimento automatizado pelo navegador e SO.
- `undo-support`: Oferecer opção de "Desfazer" para exclusões e arquivamentos em vez de modais intrusivos a cada ação.
- `success-feedback`: Confirmar conclusões com feedback visual breve (toast, alteração de ícone ou banner temporário).
- `error-recovery`: A mensagem de erro deve esclarecer exatamente a causa e apontar a rota clara de correção.
- `multi-step-progress`: Fluxos em múltiplas etapas devem exibir barra ou indicadores de progresso com opção de retrocesso.
- `form-autosave`: Formulários longos devem salvar rascunhos automaticamente para evitar perda de dados.
- `sheet-dismiss-confirm`: Confirmar com o usuário antes de fechar lâminas ou modais contendo alterações não salvas.
- `error-clarity`: Textos de erro específicos e humanos (evite "Entrada inválida" genérica).
- `field-grouping`: Agrupar campos correlatos em blocos lógicos (`<fieldset>` ou separação visual).
- `read-only-distinction`: O estado somente leitura deve ser visualmente distinto do estado desabilitado.
- `focus-management`: Ao submeter com falha, mover o foco do teclado para o sumário de erros ou para o primeiro campo inválido.
- `error-summary`: Exibir painel com lista de pendências no topo de formulários longos após tentativa de envio com erros.
- `touch-friendly-input`: Altura mínima de 44px para campos de digitação em dispositivos móveis.
- `destructive-emphasis`: Ações perigosas devem utilizar cor semântica de alerta e separação espacial de botões comuns.
- `toast-accessibility`: Toasts não devem capturar o foco do teclado; use `aria-live="polite"` para anúncio por leitor de tela.
- `aria-live-errors`: Erros em tempo de execução devem ser anunciados em regiões `aria-live="assertive"`.
- `contrast-feedback`: As cores de alerta e sucesso devem cumprir razão de contraste mínima de 4.5:1.
- `timeout-feedback`: Excesso de tempo em requisições de rede deve apresentar mensagem de timeout com botão de nova tentativa.

---

## 9. Padrões de Navegação & Roteamento (ALTA)

- `bottom-nav-limit`: Barras de navegação inferiores devem conter de 3 a no máximo 5 destinos essenciais com ícone e texto.
- `drawer-usage`: Utilize menus laterais (*drawers*) para navegação secundária, preferências e configurações profundas.
- `back-behavior`: O botão de retorno deve ser determinístico, preservando a posição de rolagem e os filtros previamente ativos.
- `deep-linking`: Todas as telas e abas principais devem ser acessíveis via link direto para compartilhamento.
- `tab-bar-ios`: No iOS, adote a Tab Bar inferior para navegação de nível superior.
- `top-app-bar-android`: No Android, utilize a Top App Bar acompanhada de ícone de navegação padronizado.
- `nav-label-icon`: Itens de navegação devem conter rótulo textual legível; ícones isolados prejudicam a descoberta.
- `nav-state-active`: O destino atualmente selecionado deve apresentar duplo estado (glifo preenchido e cor primária).
- `nav-hierarchy`: Separe claramente a navegação principal (abas de tarefas nucleares) da secundária (menu do usuário).
- `modal-escape`: Modais e lâminas devem permitir descarte por gesto de deslizar para baixo ou botão de fechar.
- `search-accessible`: A barra de busca deve ser de fácil alcance e oferecer consultas recentes e populares.
- `breadcrumb-web`: Em portais web com hierarquia superior a 3 níveis, ofereça trilha de navegação (*breadcrumbs*).
- `state-preservation`: Retornar em um fluxo não deve resetar o formulário ou zerar a rolagem da lista de produtos.
- `gesture-nav-support`: Respeite a navegação por gestos do sistema (swipe-back lateral) sem conflitos com elementos da tela.
- `tab-badge`: Badges numéricos devem ser usados com moderação e limpos imediatamente após a visualização da tela correspondente.
- `overflow-menu`: Quando os comandos excederem o espaço útil, utilize menu de transbordo (três pontos) ordenado.
- `bottom-nav-top-level`: A barra inferior pertence ao nível raiz da aplicação; nunca aninhe sub-barras de navegação dentro dela.
- `adaptive-navigation`: Telas amplas ($\ge$ 1024px) devem preferir barra lateral (*sidebar*); telas móveis adotam navegação inferior.
- `back-stack-integrity`: Nunca resete silenciosamente a pilha de telas do usuário nem pule para a home sem aviso.
- `navigation-consistency`: A posição dos controles de navegação deve ser consistente em todas as rotas do produto.
- `avoid-mixed-patterns`: Não misture abas superiores, barra inferior e menu lateral no mesmo nível de profundidade hierárquica.
- `modal-vs-navigation`: Modais não devem ser empregados como substitutos para fluxos principais de navegação.
- `focus-on-route-change`: Ao trocar de rota, transfira o foco do leitor de tela para o título da nova página carregada.
- `persistent-nav`: A navegação estrutural do sistema deve permanecer acessível mesmo em páginas profundas.
- `destructive-nav-separation`: Ações irreversíveis (excluir conta, sair) devem ficar segregadas no fim do perfil.
- `empty-nav-state`: Quando uma rota ou destino estiver indisponível, explique o motivo ao usuário em vez de ocultar silenciosamente o botão.

---

## 10. Gráficos, Dados & Visualização Quantitativa (BAIXA)

- `chart-type`: Combine o tipo de gráfico à natureza do dado (tendências $\to$ linhas; comparações $\to$ barras; proporções $\to$ rosca com até 5 fatias).
- `color-guidance`: Utilize paletas acessíveis a daltônicos; evite combinar apenas verde e vermelho para estados contrastantes.
- `data-table`: Disponibilize alternativa em tabela textual de dados para usuários de leitores de tela.
- `pattern-texture`: Suplemente variações cromáticas com texturas, traços pontilhados ou formas geométricas.
- `legend-visible`: Mantenha a legenda posicionada contiguamente ao gráfico, nunca separada abaixo de quebras de página.
- `tooltip-on-interact`: Apresente tooltips interativos ao passar o cursor ou tocar na série, exibindo os valores numéricos exatos.
- `axis-labels`: Identifique os eixos com unidades claras e escalas proporcionais; evite legendas truncadas ou inclinadas em mobile.
- `responsive-chart`: Gráficos devem simplificar marcadores e rótulos em telas estreitas para preservar a legibilidade.
- `empty-data-state`: Exiba estado vazio orientador quando não houver registros históricos ("Sem dados registrados neste ciclo").
- `loading-chart`: Utilize esqueletos de linha ou área sombreada durante o carregamento de dados analíticos.
- `animation-optional`: Animações de entrada de gráficos devem respeitar `prefers-reduced-motion` e nunca atrasar a leitura dos números.
- `large-dataset`: Para séries com mais de 1.000 pontos, aplique amostragem (*sampling*) e forneça visualização detalhada por zoom.
- `number-formatting`: Formatação monetária, de percentuais e datas estritamente ajustada ao locale do usuário.
- `touch-target-chart`: Pontos e barras interativas devem oferecer área de toque expandida de no mínimo 44pt.
- `no-pie-overuse`: Evite gráficos de pizza para mais de 5 categorias; migre para barras horizontais ordenadas.
- `contrast-data`: Linhas e barras com contraste mínimo de 3:1 contra o fundo; textos de legenda e eixos com contraste de 4.5:1.
- `legend-interactive`: Legendas com opção de clique para alternar a exibição da série correspondente.
- `direct-labeling`: Para conjuntos pequenos de dados, posicione os valores diretamente nas extremidades das barras ou linhas.
- `tooltip-keyboard`: O conteúdo do tooltip de dados deve ser acessível via navegação por teclado.
- `sortable-table`: Tabelas analíticas devem permitir ordenação de colunas com atributo `aria-sort` ativo.
- `axis-readability`: Mantenha espaçamento legível entre marcas nos eixos, aplicando salto automático (*auto-skip*) em telas compactas.
- `data-density`: Calibre a densidade de informação por painel para prevenir sobrecarga de decisão; separe em múltiplos gráficos.
- `trend-emphasis`: Destaque as tendências de dados prioritariamente, evitando gradientes e sombras que obscureçam a leitura analítica.
- `gridline-subtle`: Linhas de grade devem ser discretas e de baixo contraste (ex: `gray-200`) para não concorrer com os dados.
- `focusable-elements`: Segmentos, pontos e fatias interativas devem receber foco sequencial por teclado.
- `screen-reader-summary`: Forneça resumo textual conciso descrevendo a conclusão principal do gráfico em um atributo `aria-label`.
- `error-state-chart`: Falhas de carregamento de métricas devem exibir mensagem descritiva com botão para recarregar os dados.
- `export-option`: Em aplicações analíticas, ofereça exportação de tabelas e gráficos em CSV ou imagem.
- `drill-down-consistency`: Navegações em profundidade analítica devem manter trilha de retorno desobstruída.
- `time-scale-clarity`: Séries temporais devem declarar explicitamente a granularidade temporal (dia, semana, mês) e permitir alternância rápida.
