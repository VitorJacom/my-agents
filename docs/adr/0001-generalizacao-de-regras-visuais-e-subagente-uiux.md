# 1. Generalização de Regras Visuais, Subagente UI/UX e Desacoplamento de Domínio (Game Dev)

* Status: Aceita
* Data: 2026-11-04
* Decisores: Vitor Jacom, Antigravity (System Architect)

## Contexto

As Issues [#1](https://github.com/VitorJacom/my-agents/issues/1) e [#2](https://github.com/VitorJacom/my-agents/issues/2) foram abertas a partir de aprendizados práticos ocorridos no projeto `mels-game` (um jogo 2D em Phaser 3 + TypeScript). As dores enfrentadas envolveram:
1. **Cegueira Visual por Testes Unitários Falsamente Confortáveis**: Testes unitários com 100% de cobertura passando verde enquanto a tela real apresentava sérios problemas de contraste, proporção de sprites espremidos e poluição estética.
2. **Falha de Contraste de Valor**: Elementos de fundo e primeiro plano com luminância idêntica em escala de cinza (~82% de brilho), impossibilitando distinção na visão periférica.
3. **Ausência de Papel Especialista de UI/UX**: Falta de um agente focado em hierarquia visual, affordance e microinterações táteis (*game feel / juiciness*).
4. **Armadilhas Cinemáticas e de Física**: Variação de velocidade por taxa de atualização (Hz), duplicidade de colisões contínuas e deformação dimensional de texturas em tweens.

As propostas originais das issues sugeriam criar arquivos de regras globais (`rules/GAME_DEV_PATTERNS.md`) e um subagente de UI/UX estritamente voltado a "jogos 2D casuais/mobile".

### O Problema do Viés de Domínio (Domain Bias)
O repositório `my-agents` é um plugin global utilizado de forma transversal em múltiplos tipos de projetos: APIs REST, microsserviços em Go/Node/Python, ferramentas CLI, aplicações web corporativas, apps mobile e jogos. 

Se implementarmos convenções específicas de Phaser 3, física de plataformas e regras de pulo procedural diretamente em `rules/`:
- **Poluição de Contexto**: Todos os projetos (inclusive APIs backend sem interface) carregarão regras de física de jogos, consumindo a cota de 20.000 tokens de regras globais do Antigravity.
- **Inaplicabilidade de Guardrails**: Exigir "Auditoria Visual Headless Obrigatória" quebraria ou confundiria esteiras de projetos headless (ex: backends, microsserviços, CLIs).
- **Subutilização de Recursos**: Confinar o subagente `uiux-designer` apenas a jogos 2D impediria seu uso para criar Design Systems, telas React, mobile e acessibilidade web.

## Decisão

Optou-se por uma arquitetura **desacoplada, agnóstica e orientada a Progressive Disclosure**, dividindo as contribuições em três camadas arquiteturais:

### 1. Governança Global no Manifesto AIDD (`rules/AGENTS.md`)
- **Regra Condicional de Prova Visual (`walkthrough.md`)**:
  Adicionar à Seção 1.3 do Manifesto AIDD uma exigência clara e condicional: *Sempre que uma issue tocar camadas visuais (Front-end Web, Mobile ou Games), o `walkthrough.md` é obrigado a conter evidências de renderização visual real (captura headless, screenshot ou prova gráfica), impedindo entregas cegas baseadas exclusivamente em testes unitários lógicos*.
- Projetos puramente backend ou CLI permanecem isentos dessa evidência gráfica.

### 2. Subagente Especializado Transversal (`agents/uiux-designer/agent.md`)
- Criar o subagente `uiux-designer` como uma autoridade holística de design de interface e experiência do usuário, cobrindo:
  - **Acessibilidade e Contraste**: Princípio de Contraste de Valor monocromático (relação de contraste >= 2:1 ou WCAG AA/AAA).
  - **Hierarquia Visual e Ergonomia**: Tipografia, espaçamento, consistência de Design System e affordance.
  - **Microinterações e Sensibilidade Tátil**: Microinterações para Web/Mobile e *Game Feel / Juiciness* (squash & stretch, física elástica, recuo de botão) quando em ambiente lúdico/interativo.

### 3. Padrões de Física e Jogos 2D como Skill Sob Demanda (`skills/game-dev-patterns/`)
- Mover as regras de *Fixed Timestep*, *FPS Independence*, *Debounce Imediato de Coletáveis*, *Preservação Dimensional em Tweens* e *Garantia Cinemática de Alcance* para uma **Skill dedicada**: `skills/game-dev-patterns/SKILL.md`.
- **Benefício**: Pelo mecanismo de *Progressive Disclosure* do Antigravity, a skill só injeta seu conteúdo completo quando o agente ou o desenvolvedor estiver trabalhando em um projeto de jogos ou simulação física, garantindo zero desperdício de tokens em projetos não-jogos.

---

## Alternativas Consideradas

### Alternativa A: Regras Globais Estáticas em `rules/GAME_DEV_PATTERNS.md` (Proposta Original das Issues)
- **Motivo da Rejeição**: Introduz acoplamento excessivo e viés de domínio no plugin global. Gasta orçamento de contexto global em projetos que nunca rodarão um jogo.

### Alternativa B: Isolar Tudo Exclusivamente no Repositório `mels-game`
- **Motivo da Rejeição**: Desperdiça aprendizados riquíssimos. O conceito de *Value Contrast*, a necessidade de *Visual Proofing* em UIs e o papel de um `uiux-designer` são universais e elevam o nível de maturidade do ecossistema `my-agents`.

### Alternativa C: Criar um Plugin Separado (`my-agents-gamedev`)
- **Motivo da Rejeição**: Complexidade prematura de governança e publicação de múltiplos pacotes. O uso de **Skills** sob demanda dentro do próprio `my-agents` já resolve o isolamento de contexto sem o overhead de gerenciar dois repositórios.

---

## Consequências

### Positivas
- **Zero Token Waste**: Projetos backend e CLI não sofrem impacto de tokens com conceitos de física de jogos.
- **Eliminação da "Cegueira de Código"**: Formaliza a exigência de provas visuais em interfaces dentro do Manifesto AIDD de maneira condicional e justa.
- **Subagente UI/UX Reutilizável**: O `uiux-designer` passa a atender tanto aplicações web corporativas (Tailwind, React, Design Systems) quanto jogos casuais (Phaser, Canvas, Game Feel).
- **Atendimento Integral das Issues #1 e #2**: Ambas as demandas são incorporadas respeitando a taxonomia e as boas práticas de arquitetura do Antigravity.

### Negativas / Riscos (Trade-offs)
- **Disciplinamento na Ativação**: O agente deve reconhecer o contexto de jogos para invocar a skill `game-dev-patterns` quando relevante, o que exige descrição semântica precisa no cabeçalho YAML da skill.
