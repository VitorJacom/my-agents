# Identidade Visual Distinta & Princípios Anti-Template para Frontend

Este documento estabelece o guia de ateliê para agentes de IA atuarem como **Design Leads**, criando interfaces com identidade autoral inconfundível, repudiando ativamente os vícios visuais e clichês pré-fabricados comumente gerados por inteligências artificiais.

---

## 1. O Vício do "Design Pré-Fabricado" por IA (Os 5 Clichês Críticos)

Sistemas de IA tendem a convergir para padrões estatísticos seguros, resultando em interfaces que parecem cópias idênticas umas das outras. O agente deve **identificar e banir ativamente** os seguintes 5 arquétipos genéricos, a menos que o briefing exija explicitamente essa linguagem:

| # | Clichê / Vício de IA | Descrição do Padrão | Por Que Evitar / O Que Fazer |
|---|---|---|---|
| **1** | **O "Editorial Terracota"** | Fundo bege/creme quente (`#F4F1EA`), títulos serifados de alto contraste e acentos em terracota/argila (`#D97757`). | É a assinatura visual padrão de chatbots e geradores. Construa paletas derivadas do ecossistema do cliente (materiais, indústria, iluminação real). |
| **2** | **O "Cyber Dark Neon"** | Fundo quase preto com um único acento em verde-ácido fosforescente ou vermelhão elétrico. | Torna o produto genérico e cansativo. Use pretos com matizes reais e sistemas de cor cromáticos ricos e funcionais. |
| **3** | **O "Broadsheet Jornalístico Forçado"** | Linhas divisórias ultrafinas (*hairline rules*), cantos totalmente retos (`border-radius: 0`) e colunas densas em estilo jornal do século XIX. | Só faz sentido para publicações literárias reais. Não force esse estilo para dashboards, produtos digitais ou e-commerces. |
| **4** | **O "SaaS-Card Kit Monótono"** | Toda a informação fatiada em cards retangulares idênticos, com o mesmo raio de curvatura em tudo, sombra cinza suave difusa (`rgba(0,0,0,0.1)`) e manchas de gradiente decorativas no fundo. | Elimine cards desnecessários. Use agrupamento por proximidade, tipografia, contraste e espaços em branco (*negative space*) para separar conteúdo. |
| **5** | **"Template Chrome" Decorativo** | Rótulos em caixa-alta espaçada (`ALL-CAPS`) acima de qualquer título; metadados separados por pontos centrais (`A · B · C`); separadores com travessão (`TERMO — detalhe`); fontes monospace em badges banais; e setas `→` coladas em todos os botões. | Elimine a maquiagem tipográfica. Use estrutura de dados semântica real; nunca adicione numeração (ex: 01, 02, 03) a menos que seja uma sequência estrita passo-a-passo. |

---

## 2. Ancoragem no Objeto Real (Subject-Matter Grounding)

Toda escolha visual distinta deve nascer do **universo material, vernacular e cultural** do produto:

1. **Investigação do Contexto:** Se o briefing não explicitar a indústria ou público, defina o tema concreto, o usuário primário e o trabalho central da interface antes de escrever uma única linha de CSS.
2. **Divergência Estética:**
   - Um aplicativo de logística industrial portuária deve expressar robustez, alta densidade de dados, contraste solar e leitura a distância.
   - Uma ferramenta de meditação clínica deve trabalhar com ritmos de respiração visual, suavidade e ausência de estímulos abruptos.
   - Nunca aplique o mesmo "tema escuro minimalista moderno" para ambos.
3. **Hero Customizado:** O topo da página (*Hero*) deve exibir o objeto mais característico daquele domínio (uma demonstração interativa ao vivo, um canvas funcional, uma simulação ou um dado-chave real), e **não** a fórmula batida: *"Título grande + Subtítulo genérico + Número com label + Gradiente roxo/laranja"*.

---

## 3. Tipografia com Ponto de Vista

1. **Máximo de 1 a 2 Famílias:**
   - Não misture três ou quatro fontes. Uma única família bem trabalhada em pesos, larguras e tamanhos expressa mais autoridade e consistência. Se usar duas, garanta contraste nítido de função (ex: uma fonte técnica para dados/tabelas e uma geométrica para displays).
2. **Comprimento de Linha (Measure):**
   - Mantenha linhas de leitura abaixo de **75 a 80 caracteres** para corpo de texto. Linhas infinitas cansam o olho; linhas curtas demais quebram o ritmo.
3. **Técnicas Tipográficas Banidas:**
   - **Nunca destaque apenas uma única palavra** dentro de um título com cor diferente ou itálico isolado (marca registrada de landing pages genéricas de IA).
   - Não use `uppercase` para labels longos.

---

## 4. Orquestração de Movimento e a "Regra de Chanel"

> *"Antes de sair de casa, olhe-se no espelho e tire um acessório." — Coco Chanel*

- **Gaste sua ousadia em um único lugar:** Deixe um elemento memorável brilhar (o Hero, uma transição de estado expressiva, um seletor interativo físico). Todo o restante da tela deve ser disciplinado, calmo e silencioso.
- **Chega de Fade-In Cascata em Tudo:** Animar cada card, linha e seção com `opacity: 0; transform: translateY(20px)` conforme o usuário rola a página é cansativo e denuncia um template automatizado.
- **Movimento que Responde vs. Movimento Decorativo:**
  - *Permitido:* Animações que respondem a uma ação deliberada do usuário (expandir, confirmar, arrastar, alternar).
  - *Proibido:* Micro-animações contínuas sem sentido, carrosséis automáticos e balanços de botões chamando atenção artificialmente.

---

## 5. UX Writing: O Texto como Arquitetura da Interface

Palavras são matéria-prima de design funcional, não decoração ou preenchimento de espaço (*lorem ipsum*):

### Diretrizes de Microcopy:
1. **Perspectiva do Usuário:** Nomeie os controles pelo que o usuário deseja alcançar em linguagem cotidiana, nunca pela arquitetura técnica do backend.
   - *Errado:* "Configurar Webhooks de Disparo de Evento"
   - *Certo:* "Notificações e Alertas"
2. **Voz Ativa e CTAs Precisos:** O botão deve descrever exatamente o que acontece quando pressionado.
   - *Errado:* "Enviar", "OK", "Submeter", "Prosseguir"
   - *Certo:* "Salvar alterações", "Criar conta", "Publicar anúncio", "Baixar relatório"
3. **Consistência Vocabular de Ponta a Ponta:**
   - Se o botão se chama "Publicar", o diálogo deve dizer "Publicar este rascunho?", e o toast subsequente deve dizer "Rascunho publicado". Nunca alterne para "Salvar", "Concluir" ou "Processado" no mesmo fluxo.
4. **Erros e Telas Vazias Orientadas à Resolução:**
   - Telas vazias não lamentam: elas mostram o primeiro passo acionável com um CTA evidente.
   - Erros de validação não pedem desculpas ("Oops, algo deu errado"): explicam o motivo objetivo e oferecem a saída imediata.
5. **Sentence Case como Padrão:** Use capitalização de frase normal ("Configurações de privacidade"), nunca Title Case artificial em cada palavra ("Configurações De Privacidade").

---

## 6. O Fluxo de Trabalho em Dois Passos (Two-Pass Process)

Para garantir que o código gerado pelo agente não caia no piloto automático:

```
+-------------------------------------------------------+
|  PASSO 1: O Plano de Design Inicial (Design Tokens)    |
|  - 4 a 6 valores hexadecimais nomeados com propósito   |
|  - Famílias tipográficas e papéis hierárquicos        |
|  - Wireframe ASCII de layout e alinhamento visual      |
+-------------------------------------------------------+
                           |
                           v
+-------------------------------------------------------+
|  PASSO 2: A Crítica de Restrição (O "Espelho")         |
|  "Existe algum clichê de IA aqui? A paleta é óbvia?   |
|   Há cards demais? A redação soa burocrática?"         |
|  -> Eliminar um acessório supérfluo                   |
|  -> Refinar tokens antes de codificar                 |
+-------------------------------------------------------+
                           |
                           v
+-------------------------------------------------------+
|  EXECUÇÃO: Codificação Limpa (Sem Conflitos de CSS)   |
|  - Especificidade controlada (evitar .section vs .cta) |
|  - Fallbacks nativos (semântica HTML5 e a11y)         |
+-------------------------------------------------------+
```
