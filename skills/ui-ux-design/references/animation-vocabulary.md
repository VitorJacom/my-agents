# Vocabulário & Glossário Reverso de Animação

Este documento serve como índice reverso de consulta para transformar descrições visuais vagas ("o efeito elástico quando puxa demais", "o popover crescendo do botão") no termo técnico exato de engenharia e UI design.

---

## Instruções de Uso para Agentes

1. **Leia pela intenção visual, não por palavras-chave:** O usuário descreve a sensação física ("parece chiclete", "desliza suave", "vai revelando"). Mapeie essa percepção para o termo correspondente no glossário abaixo.
2. **Defina termos próximos com precisão:**
   - *Clip-path* vs *Mask:* Clip-path tem corte vetorial nítido; máscara permite bordas esfumadas e degradês.
   - *Pop-in* vs *Bounce:* Pop-in tem overshoot suave uma única vez na entrada; Bounce tem oscilações repetidas.
   - *Morph* vs *Shared Element Transition:* Morph altera a geometria do elemento no mesmo local; Shared Element desloca o elemento de um container A para um container B.
3. **Formato Canônico de Resposta:**
   `**[Termo Exato]** — [Definição concisa e aplicação técnica]`

---

## Glossário Categorizado

### 1. Entradas & Saídas (Entrances & Exits)
- **Fade in / Fade out:** Elemento surge ou desaparece alterando sua opacidade de forma contínua.
- **Slide in:** Elemento entra deslizando a partir de fora da tela (esquerda, direita, topo ou base).
- **Scale in:** Elemento cresce a partir de uma escala ligeiramente menor (ex: 0.95) até o tamanho real, quase sempre acompanhado de opacidade.
- **Pop in:** Elemento surge com um leve *overshoot* (ultrapassa 1.02 e acomoda em 1.0), dando sensação de quique elástico sutil.
- **Reveal:** O conteúdo é destampado progressivamente através da animação de uma máscara ou `clip-path`.
- **Enter / Exit:** As animações de montagem e desmontagem executadas no ciclo de vida do componente.

### 2. Sequenciamento & Temporização (Sequencing & Timing)
- **Keyframes:** Marcos de tempo explícitos (0%, 50%, 100%) calculados pelo navegador.
- **Interpolation / Tween:** Geração de quadros intermediários contínuos entre o estado inicial e final.
- **Stagger:** Atraso cascata incremental (ex: 30–50ms) entre múltiplos itens de uma lista ou grade.
- **Orchestration:** Coordenação cronometrada de múltiplos elementos simultâneos para que pareçam uma única coreografia coesa.
- **Delay:** Intervalo de espera antes do disparo da animação.
- **Duration:** Tempo total que a animação leva para ser executada.
- **Fill mode:** Define se os estilos do primeiro ou último frame persistem antes ou após a execução (`forwards`, `backwards`, `both`).
- **Stepped animation:** Movimento que salta em etapas discretas sem interpolação fluida (ex: ponteiro de relógio analógico).

### 3. Movimento & Transformações (Movement & Transforms)
- **Translate:** Deslocamento linear do elemento nos eixos X, Y ou Z.
- **Scale:** Redimensionamento proporcional ou direcional sem afetar o layout dos nós vizinhos.
- **Rotate:** Rotação angular em torno de um ponto fixo.
- **Skew:** Distorção angular inclinando o elemento em paralelogramo.
- **3D Tilt / Flip:** Rotação nos eixos tridimensionais (rotateX/rotateY) gerando profundidade tátil.
- **Perspective:** Intensidade da profundidade tridimensional percebida.
- **Transform origin:** O ponto âncora a partir do qual as transformações escalam ou giram.
- **Origin-aware animation:** O elemento surge e expande a partir do botão ou ponto exato onde o usuário clicou (usando `transform-origin` dinâmico).

### 4. Transições de Estado (Transitions Between States)
- **Crossfade:** Um elemento diminui a opacidade no mesmo lugar em que outro aumenta, substituindo o conteúdo.
- **Continuity transition:** Preservação de marcos visuais para que o cérebro entenda que o objeto A e o objeto B são a mesma entidade.
- **Morph:** Um formato geométrico transmuta suavemente em outro (ex: Dynamic Island do iOS).
- **Shared element transition:** O elemento viaja no espaço transformando-se de miniatura para modal ou página inteira.
- **Layout animation:** Reposicionamento suave automático quando a lista é reordenada ou o tamanho do container muda.
- **Accordion / Collapse:** Expansão ou recolhimento vertical suave de conteúdo com medição precisa de altura.
- **Direction-aware transition:** Conteúdo desliza em uma direção ao avançar e na direção contrária ao voltar no fluxo de navegação.

### 5. Rolagem (Scroll)
- **Scroll reveal:** Elementos surgem e ganham opacidade conforme entram na área visível da janela (*viewport*).
- **Scroll-driven animation:** Progresso da animação atrelado matematicamente à barra de rolagem.
- **Parallax:** Camadas de fundo e primeiro plano rolam em velocidades distintas, gerando relevo óptico.
- **Page transition:** Animação que suaviza a troca entre duas rotas ou telas.
- **View transition:** API nativa do navegador que cria transições suaves entre diferentes estados de DOM ou páginas inteiras.

### 6. Feedback & Interação (Feedback & Interaction)
- **Hover effect:** Resposta visual sutil ao posicionar o cursor sobre um controle interativo.
- **Press / Tap feedback:** Contração sutil em escala (`scale(0.97)`) indicando que o clique/toque foi registrado.
- **Hold to confirm:** Preenchimento linear contínuo enquanto o botão é pressionado para evitar exclusões acidentais.
- **Drag:** Arraste de elemento diretamente com o dedo ou mouse com retenção de captura de ponteiro.
- **Drag to reorder:** Arraste para reordenar listas enquanto os demais itens abrem espaço dinamicamente.
- **Swipe to dismiss:** Deslizar um elemento para fora da tela (gaveta, toast ou notificação) com descarte definitivo.
- **Rubber-banding:** Resistência elástica crescente ao puxar além dos limites físicos, seguida de retorno (*overscroll* do iOS).
- **Shake / Wiggle:** Vibração horizontal rápida indicando erro de validação ou recusa de comando.
- **Ripple:** Onda circular que se propaga a partir do ponto exato de toque (Material Design).

### 7. Aceleração & Curvas (Easing)
- **Easing:** Taxa matemática de aceleração ou desaceleração de um movimento.
- **Ease-out:** Início rápido e desaceleração gradual no final. Padrão obrigatório para 90% da interface e respostas ao usuário.
- **Ease-in:** Início lento e término rápido. Geralmente proibido em UI por transmitir sensação de lentidão.
- **Ease-in-out:** Lento no início, rápido no meio e lento no final. Adequado para elementos já visíveis trocando de posição em tela.
- **Linear:** Velocidade perfeitamente constante. Proibido em UI geral; reservado para rotações contínuas (*spinners*) ou barras de progresso.
- **Cubic-bezier:** Definição matemática de curvas através de 4 pontos de controle vetorial.
- **Asymmetric easing:** Curvas com taxas distintas de aceleração e desaceleração que conferem aspecto orgânico vivo.

### 8. Animações de Mola (Spring Animations)
- **Spring:** Movimento regido por leis da física mecânica (massa, tensão, amortecimento) em vez de tempo fixo.
- **Stiffness / Tension:** Força de tração com que a mola puxa o elemento até o alvo. Quanto maior, mais rígida e rápida.
- **Damping:** Resistência que freia a oscilação. Menor amortecimento gera quique prolongado.
- **Mass:** Inércia do elemento. Maior massa cria aceleração pesada e desaceleração lenta.
- **Bounce:** Percentual de ultrapassagem do alvo (*overshoot*) antes de repousar.
- **Perceptual duration:** O instante em que a mola parece visualmente assentada aos olhos humanos, embora microoscilações físicas continuem ocorrendo.
- **Momentum:** Energia cinética herdada pelo elemento após ser lançado pelo usuário em um gesto (*flick*).
- **Velocity:** Vetor de velocidade instantânea transmitido pelo dedo no momento exato em que ele deixa o vidro.
- **Interruptible animation:** Movimento que pode ser agarrado e redirecionado a qualquer milissegundo sem solavancos.

### 9. Movimentos Contínuos & Ambientes (Looping & Ambient)
- **Marquee:** Rolagem contínua horizontal de textos, logotipos ou cartões em repetição infinita.
- **Loop:** Repetição pré-programada finita ou infinita de uma animação.
- **Alternate (Yoyo):** Animação que vai do início ao fim e depois retorna do fim ao início em ciclo reversível.
- **Orbit:** Trajetória circular em torno de um centro gravitacional.
- **Pulse:** Variação cíclica suave de opacidade ou escala para sinalizar atenção.
- **Float:** Movimento sutil para cima e para baixo sugerindo gravidade zero e leveza.
- **Idle animation:** Animação discreta que ocorre enquanto o elemento aguarda interação do usuário.

### 10. Polimento & Efeitos Visuais (Polish & Effects)
- **Blur:** Desfoque gaussiano funcional usado para profundidade de campo ou para ocultar costuras em trocas de tela.
- **Clip-path:** Recorte geométrico do container com bordas vetoriais sólidas.
- **Mask:** Recorte com gradientes ou transparências para esmaecimento progressivo de arestas.
- **Before / After slider:** Barra divisória arrastável que revela duas imagens sobrepostas para comparação visual direta.
- **Line drawing:** Traçado automático de vetor SVG dando o efeito de desenho por caneta invisível.
- **Text morph:** Transição caractere a caractere quando valores alfanuméricos são atualizados.
- **Skeleton / Shimmer:** Efeito de brilho que percorre um bloco cinza indicando carregamento progressivo de conteúdo.
- **Number ticker:** Dígitos que rolam verticalmente como um odômetro até o número final.
- **Tabular numbers:** Algarismos monoespaçados (`font-variant-numeric: tabular-nums`) que impedem que a largura do texto balance durante contagens.
- **Typewriter:** Texto digitado letra por letra simulando digitação humana.

### 11. Performance de Renderização (Performance)
- **FPS (Frames Per Second):** Taxa de quadros por segundo (60fps padrão; 120fps em telas ProMotion).
- **Jank:** Engasgos visíveis e quebra de fluidez causados por perda de quadros.
- **Dropped Frame:** Quadro que perdeu a janela de sincronização vertical (*vsync*) de ~16.6ms.
- **Compositing:** Processo pelo qual a GPU junta camadas independentes sem forçar layout ou repaint.
- **will-change:** Instrução CSS que sugere ao navegador isolar o elemento em uma camada própria antes da animação.
- **Layout Thrashing:** Ciclo repetido de leitura e escrita forçada de propriedades do DOM que sobrecarrega a CPU.

### 12. Princípios Fisiológicos & Cognitivos (Principles)
- **Purposeful animation:** Movimento que cumpre função cognitiva e orienta o usuário, nunca servindo apenas como adorno vazio.
- **Anticipation:** Movimento preparatório curto no sentido oposto antes da ação principal acontecer.
- **Follow-through:** Continuidade do movimento de partes flexíveis após a estrutura principal ter parado.
- **Squash & stretch:** Deformação elástica para transmitir velocidade e flexibilidade física.
- **Perceived performance:** Interfaces que parecem muito mais rápidas devido a feedback visual instantâneo antes da resposta de rede.
- **Frequency of use:** Quanto mais frequente a ação, menor e mais sutil deve ser a animação (ou zero animação).
- **Spatial consistency:** Manutenção da posição e identidade de elementos para que o usuário nunca se sinta desorientado.
- **Hardware acceleration:** Otimização para GPU animando apenas `transform` e `opacity`.
- **Reduced motion:** Respeito absoluto às diretrizes de acessibilidade para usuários com distúrbios vestibulares.
