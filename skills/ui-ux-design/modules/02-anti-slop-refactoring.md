# Módulo 02: Anti-Slop, Refatoração de IA & Design System Canônico

Este módulo reúne as heurísticas de sanitização, erradicação de vícios de IA, hierarquia por espaçamento plano e contenção canônica para produzir código frontend autoral de nível Linear, Stripe e Notion.

---

## Técnica 11: Identidade Visual Autoral & Neutralização dos 5 Clichês de IA (`Distinct Visual Identity & Anti-Templates`)

### Os 5 Clichês Críticos para Banir:
1. **O "Editorial Terracota":** Fundo bege quente (`#F4F1EA`) + serif display + acento terracota (`#D97757`).
2. **O "Cyber Dark Neon":** Fundo quase preto + verde-ácido fosforescente ou vermelhão elétrico aleatório.
3. **O "Broadsheet Forçado":** Hairline rules ultrafinas, cantos 100% retos (`border-radius: 0`) e colunas de jornal do século XIX em softwares comuns.
4. **O "SaaS-Card Kit Monótono":** Todo conteúdo dividido em caixas idênticas com o mesmo `border-radius`, sombra suave `rgba(0,0,0,0.1)` e manchas de gradiente decorativas no fundo.
5. **"Template Chrome" Artificial:** Eyebrows em `ALL-CAPS` espaçadas acima de cada título; strings com pontos centrais (`A · B · C`); travessões forçados (`PALAVRA — detalhe`); fontes monospace em tags triviais; e `→` em todos os botões.

### Diretriz de Autenticidade
- Derive a paleta (4 a 6 cores) da substância material real da indústria do cliente.
- O Hero deve conter a coisa mais característica do assunto (demo ao vivo, canvas interativo), nunca o combo clichê *"Título + Subtítulo + Número"*.
- Nunca destaque uma única palavra no meio do título com cor ou itálico isolado.

---

## Técnica 13: O Processo em Dois Passos & A "Regra de Chanel" (`Two-Pass Planning & Restraint Critique`)

### O Fluxo de Concepção em Dois Passos
1. **Passo 1 (Tokens & Wireframe):** 4 a 6 hexadecimais semânticos, famílias tipográficas delimitadas e wireframe ASCII de alinhamento.
2. **Passo 2 (A Crítica de Restrição):** Inspecione a proposta: *"Existe algum vício de IA aqui?"*.
   - **Regra de Chanel:** *"Antes de sair de casa, olhe-se no espelho e tire um acessório."* Remova um card, uma borda ou uma sombra desnecessária.
   - Gaste a ousadia visual em um **único elemento memorável**; mantenha todo o entorno funcional e silencioso.

---

## Técnica 29: Hierarquia por Espaçamento Plano (`Flat-Canvas Proximity`)
- **Problema:** A "cardite aguda" de IA coloca tudo em caixas fechadas com borda de 1px.
- **Solução:** Remova caixas elevadas e disponha os elementos diretamente sobre a cor base de fundo.
- **Lei da Proximidade:** Use espaçamento inteligente (`48px` a `64px` entre seções distintas; `12px` a `16px` entre itens relacionados) e peso tipográfico para conduzir o olho.

---

## Técnica 30: Encapsulamento de Ação Progressiva (`Progressive Action Compaction`)
- **Problema:** Despejar botões utilitários explícitos (Copiar, Ver, Deletar) em cada linha de tabelas gera poluição cognitiva.
- **Solução:**
  - Torne o identificador ou token clicável para copiar automaticamente com microfeedback de toast.
  - Agrupe ações raras em um menu contextual compacto (`...`).
  - Limite tabelas a 3 ou 4 colunas essenciais, movendo telemetria e métricas secundárias para abas analíticas dedicadas.

---

## Técnica 31: Contenção Estrutural Invisível (`Borderless Division`)
- **Problema:** Excesso de divisores (`<hr>`, `border-b`) retalha o layout em grades duras.
- **Solução:** Elimine divisores de linha entre cabeçalhos, cartões e listas. Preserve bordas de 1px exclusivamente nas fronteiras funcionais mestras (ex: separação entre a sidebar e o painel de conteúdo). Use espaço negativo e variações tonais milimétricas.

---

## Técnica 32: Afinação Cromática Direcionada (`Color Anchoring Focus`)
- **Problema:** IAs espalham cores vibrantes simultaneamente em badges, tags e botões sem critério semântico.
- **Solução:** Defina uma única meta primária por tela. Mantenha 95% da base em tons neutros sofisticados e reserve a cor de destaque saturada exclusivamente para o botão de ação principal (CTA) ou status críticos de erro.

---

## Técnica 34: Concisão de Cabeçalho Contextual (`Zero-Redundancy Subheadings`)
- **Problema:** IAs inserem subtítulos papagaio que repetem o título (ex: *"Chaves de API — Gerencie suas chaves de API"*).
- **Solução:** Se o usuário já sabe o que a tela faz pelo contexto de navegação, corte o subtítulo e vá direto aos dados. Mantenha subtítulos apenas para avisos de segurança, limitações técnicas ou instruções operacionais críticas.

---

## Técnica 37: Descaracterização de Template Padrão (`Un-Defaulting the System`)
- **Problema:** Usar Shadcn UI ou Material com configurações de fábrica resulta em clones idênticos.
- **Solução:** Reconfigure previamente a camada de design tokens:
  - Altere a escala de `border-radius` (ex: `--radius: 0px` para estilo editorial/suíço ou `12px` para apps amigáveis).
  - Recalibre a tipografia e as paletas de cores primárias e de fundo.
  - Ajuste os modos claro e escuro para fugir dos tons cinza-esverdeados pré-fabricados.

---

## Técnica 38: Calibração Fundamental de Design (`Fundamentals-Backed Refinement`)
- Aplique ativamente os princípios clássicos de design de interface (*Refactoring UI*):
  - Diferencie elementos com peso tipográfico e cor antes de aumentar o tamanho da fonte.
  - Alinhe dimensões estritamente a múltiplos de 4px / 8px.
  - Use rótulos em *Sentence Case* e mantenha contraste mínimo validado.

---

## Técnica 39: Contenção Canônica de Design System (`Strict Canonical UI Enforcement`)
- **Problema:** A IA tende a improvisar criando blocos com divs soltas de Tailwind ou botões inventados do zero sem foco ou ARIA acessível ("AI Slop").
- **As 3 Regras de Contenção:**
  1. **Proibição de Improvisação:** Proibido criar tags manuais quando já houver componente canônico na biblioteca (ex: `<Button>`, `<Card>`, `<Dialog>`, `<Table>`).
  2. **Anatomia Oficial Mandatória:** Respeitar a hierarquia de composição canônica da biblioteca.
  3. **Bloqueio de Overrides Arbitrários:** Manter as classes de fábrica intactas, permitindo apenas a configuração de 1 cor de acento no tema raiz.

---

## Técnica 41: Sanitização de Vícios de Slop (`AI Cliché Purge`)
- **Checklist de Purga Imediata:**
  - [ ] **Zero Emojis:** Remover todos os emojis de menus, cabeçalhos e badges; usar tipografia pura ou SVGs monocromáticos funcionais.
  - [ ] **Sem Bordas Genéricas:** Eliminar bordas cinzas repetitivas em cartões e botões secundários.
  - [ ] **Erradicação do Roxo Genérico:** Substituir gradientes violeta/índigo por escalas neutras e a cor oficial da marca.
  - [ ] **Corte de Ornamentos:** Remover faíscas (*sparkles*), diamantes ou decorações sem valor funcional.
