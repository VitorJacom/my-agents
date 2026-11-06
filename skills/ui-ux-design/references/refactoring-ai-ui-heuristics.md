# Heurísticas de Refatoração e Descaracterização de Interfaces Geradas por IA

Este documento reúne o catálogo definitivo de inspeção, auditoria e refatoração para erradicar o aspecto amador, clichê e padronizado de interfaces geradas por modelos de linguagem e ferramentas como v0, Lovable, Bolt e Cursor.

---

## 1. O Diagnóstico Clínico da Interface "Feita por IA"

Quando uma IA gera uma tela sem supervisão de fundamentos de design, ela tipicamente apresenta 6 patologias visuais imediatas:

```
+---------------------------------------------------------------------------------+
|  [LOGO] [Dashboard] [Projetos] [Configurações]                 [Usuário]        |
+---------------------------------------------------------------------------------+
|                                                                                 |
|  Chaves de API                                                                  |
|  Gerencie suas chaves de API nesta tela abaixo  <-- [Subtítulo Redundante]     |
|                                                                                 |
|  +---------------------------------------------------------------------------+  |
|  | [ GERAL ] [ ANALYTICS ] [ SEGURANÇA ]  <-- [Inset-Tabs usadas em rota mestra]|
|  +---------------------------------------------------------------------------+  |
|                                                                                 |
|  +-----------------------+ +-----------------------+ +-----------------------+  |
|  | Card com Borda 1px    | | Card com Borda 1px    | | Card com Borda 1px    |  |
|  | Badge Amarela         | | Badge Roxa            | | Badge Verde           |  | <- [Cardite Aguda
|  | Botão Copiar | Ver    | | Botão Copiar | Ver    | | Botão Copiar | Ver    |  |  + Arco-Íris
|  | [Excluir em Vermelho] | | [Excluir em Vermelho] | | [Excluir em Vermelho] |  |  desgovernado]
|  +-----------------------+ +-----------------------+ +-----------------------+  |
+---------------------------------------------------------------------------------+
```

---

## 2. As 10 Heurísticas de Refatoração Estilo Linear / Stripe / Notion

### 1. Hierarquia por Espaçamento Plano (`Flat-Canvas Proximity`)
- **Regra:** Remova os cartões elevados e bordas de contorno. Disponha os elementos diretamente sobre a cor de fundo primária.
- **Mecanismo:** Use a **Lei da Proximidade de Gestalt**. A distância entre seções diferentes deve ser de `48px` a `64px`, enquanto a distância entre elementos do mesmo grupo deve ser de `8px` a `16px`. O peso tipográfico guia a leitura, não caixas de papelão flutuantes.

---

### 2. Encapsulamento de Ação Progressiva (`Progressive Action Compaction`)
- **Regra:** Elimine a proliferação de botões secundários dispersos em cada linha de tabela.
- **Implementação:**
  - Torne o token ou identificador clicável para copiar diretamente com microfeedback (toast ou ícone de check temporário).
  - Agrupe ações destrutivas ou raras em um menu contextual compacto (`...`).
  - Mantenha tabelas operacionais em **3 a 4 colunas estritas**. Mova logs históricos e telemetria para abas analíticas separadas.

---

### 3. Contenção Estrutural Invisível (`Borderless Division`)
- **Regra:** Substitua divisores de linha (`<hr>`, `border-b`) por **espaço negativo (*whitespace*)** ou variações tonais milimétricas de fundo.
- **Fronteiras Mestras Apenas:** Preserve bordas de 1px exclusivamente na separação arquitetural primária (ex: divisória da sidebar mestra ou barra de ferramentas fixa). Todo o miolo do conteúdo deve respirar sem grades duras.

---

### 4. Afinação Cromática Direcionada (`Color Anchoring Focus`)
- **Regra:** Uma tela = Um único ponto de atração cromática.
- **Implementação:**
  - Fundo e elementos utilitários devem habitar uma escala neutra sofisticada (tons de ardósia, zinco ou grafite).
  - A cor de acento vibrante (azul elétrico, esmeralda, violeta) é de uso estrito e exclusivo do botão de ação primária (CTA) ou de alertas críticos de sistema.
  - Elimine badges coloridas decorativas que não representem estados semânticos reais do sistema.

---

### 5. Anatomia de Navegação Proporcional (`In-Context Tab Switching`)
- **Regra de Ouro:** Não use `Inset Tabs` (abas embutidas arredondadas estilo Shadcn) para rotas principais de navegação.
- **Hierarquia:**
  - **Rotas de Página Inteira:** Abas planas com sublinhado sutil (`underline tabs`), links de cabeçalho ou menu lateral.
  - **Inset Tabs (Pill Tabs):** Exclusivas para alternâncias de estado no mesmo bloco (ex: toggle `Preview / Code`, ou `Mês / Ano` dentro de um card).

---

### 6. Concisão de Cabeçalho Contextual (`Zero-Redundancy Subheadings`)
- **Regra do Papagaio:** Se o título diz `"Webhooks"`, é proibido adicionar o subtítulo `"Aqui você gerencia seus webhooks"`.
- Se o usuário já sabe o que a tela faz pelo contexto de onde clicou, elimine o subtítulo. Deixe o topo da tela limpo e exiba os dados imediatamente. Preserve subtítulos apenas quando houver orientações de segurança ou instruções técnicas indispensáveis.

---

### 7. Prototipagem de Forma Antes do Esquema (`Interface-First Experimentation`)
- Iniciar um recurso modelando tabelas de banco de dados (`Prisma`, `PostgreSQL`) amarra o pensamento criativo à lógica mecânica do backend.
- Crie primeiro a tela estática em Figma ou HTML/CSS simples (sem se preocupar com arquitetura de código). Descubra como a experiência humana deve fluir. Somente após validar a ergonomia da tela instrua a IA a criar endpoints, migrations e controllers.

---

### 8. Convergência por Divergência Multimodelo (`Multi-Model Synthesis`)
- Não confie na primeira resposta de um único prompt em uma única ferramenta.
- Submeta o mesmo briefing de interface em paralelo a ferramentas distintas.
- Extraia cirurgicamente o que cada modelo fez de melhor:
  - Modelo A gerou uma microinteração de accordion perfeita.
  - Modelo B formatou a tabela com melhor densidade e tipografia.
  - Modelo C pensou em um empty state inteligente.
- Sintetize a versão de produção unificando as melhores partes.

---

### 9. Descaracterização de Template Padrão (`Un-Defaulting the System`)
- Se você usar Shadcn UI ou Material com suas classes e tokens de fábrica (`rounded-md`, `bg-background`, paleta slate comum), sua aplicação parecerá mais um clone genérico.
- **Procedimento Obrigatório:**
  1. Redefina a escala de curvatura (`--radius: 0px` para estilo suíço/técnico ou `--radius: 12px` para apps de consumo).
  2. Altere os valores de HSL/HEX das cores primárias e de fundo para refletirem a marca do cliente.
  3. Calibre o dark mode para evitar pretos lavados e cinzas esverdeados genéricos.

---

### 10. Calibração Fundamental de Design (`Fundamentals-Backed Refinement`)
- Ferramentas de IA têm velocidade infinita, mas discernimento estético zero.
- Utilize as heurísticas clássicas de design (baseadas no repertório de *Refactoring UI* e tipografia moderna):
  - Hierarquia por peso em vez de tamanho.
  - Alinhamentos ópticos em múltiplos de 4px / 8px.
  - Rótulos curtos em Sentence Case.
  - Proximidade relacional e contraste validado.
