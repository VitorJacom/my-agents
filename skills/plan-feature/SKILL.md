---
name: plan-feature
description: >-
  Orquestra o ciclo completo de planejamento e design de software via GitHub (AIDD):
  Product Owner (Requisitos & Valor) ➔ [UI/UX Designer (Mockup-as-Code, se UI)] ➔ System Architect (Impacto Técnico, ADR & Atomicidade) ➔ Gate de Aprovação ➔ Criação das Issues no GitHub.
---

# Feature Planning Pipeline (`/plan-feature`)

Esta Skill gerencia a esteira de planejamento e design de software no GitHub, decompondo ideias, refinando issues existentes, estruturando contratos visuais e decisões de arquitetura antes de qualquer linha de código ser escrita.

## 🚀 Como Invocar
```text
/plan-feature <ideia, descrição de funcionalidade, issue existente #XX ou decisão técnica>
```

---

## 🔄 Máquina de Estados de Planejamento

```mermaid
flowchart TD %% Decisão condicional por interface visual (UI_UX_REQUIRED)
    Start["[Entrada: Ideia / Épico / Issue #XX]"] --> PO["1. Product Owner<br/>(Especificação Funcional & UI_UX_REQUIRED)"]
    PO --> Decision{"Interface Visual?<br/>(UI_UX_REQUIRED)"}
    Decision -- YES --> UIUX["1.5. UI/UX Designer<br/>(Modo 1: Mockup-as-Code & Visual Contract)"]
    Decision -- NO --> Arch["2. System Architect<br/>(Impacto src/, docs/ARCHITECTURE.md, <= 3 passos)"]
    UIUX --> Arch
    Arch --> Gate["3. Gate de Aprovação<br/>(Validação Humana + .mockup-preview.png)"]
    Gate --> GH["4. Criação no GitHub<br/>(gh issue create + Visual & UI/UX Contract)"]
    GH --> Done["[ Handoff Final ]"]
```

---

## 📋 Protocolo de Execução por Estado

### 📍 ESTADO 1: DESCOBERTA FUNCIONAL (Product Owner)
1. Invoque o subagente `product-owner` via `invoke_subagent`:
   - Envie a descrição do requisito ou o número da Issue (#XX).
   - O PO analisa a dor do negócio, define personas e redige os critérios de aceite em formato Gherkin (`Dado / Quando / Então`) ou checklist verificável.
   - **Classificação Obrigatória de Impacto Visual**: O PO classifica explicitamente a demanda:
     - `UI_UX_REQUIRED: YES` (quando a funcionalidade envolver interface visual, tela gráfica, Web App, componente UI, HUD de jogo ou terminal interativo).
     - `UI_UX_REQUIRED: NO` (quando for puramente backend, CLI estrutural, script de infraestrutura ou automação de dados sem interface visual).
2. Aguarde a conclusão da especificação funcional com a classificação definida.

### 📍 ESTADO 1.5: UI/UX & MOCKUP DESIGN (uiux-designer — Condicional)
> [!NOTE]
> Esta etapa condicional é executada exclusivamente se o PO definir `UI_UX_REQUIRED: YES`. Caso contrário (`UI_UX_REQUIRED: NO`), avança diretamente para o **ESTADO 2** (Zero Token Waste).

1. Invoque o subagente `uiux-designer` via `invoke_subagent` operando em **Modo 1 (Concepção & Mockup-as-Code)**:
   - Envie os requisitos funcionais e critérios de aceite gerados pelo PO.
   - O `uiux-designer` executa o protocolo Figma-less Mockup-as-Code estruturado em 3 camadas:
     1. **Camada 1: Spatial Blueprint (Wireframe Estrutural ASCII)**: Diagrama Box-drawing Unicode (`┌`, `─`, `┐`, etc.) no grid de 4px/8px definindo hierarquia, proporções e estados interativos.
     2. **Camada 2: Design Tokens & Luminance Contract**: Tabela formal de cores hexadecimais, conversão em escala de cinza demonstrando Value Contrast $\ge$ 2:1 para superfícies/elementos e WCAG AA $\ge$ 4.5:1 para textos, escalas tipográficas e sombras de oclusão.
     3. **Camada 3: Protótipo Estático Autocontido & Captura Headless**: Cria o arquivo efêmero `.mockup-preview.html` e renderiza `.mockup-preview.png` via comando headless:
        ```bash
        chromium --headless --screenshot=.mockup-preview.png --window-size=1280,720 .mockup-preview.html
        ```
   - O subagente consolida e entrega o bloco formal `## Visual & UI/UX Contract` (Camadas 1 e 2) e o link para visualização da captura `.mockup-preview.png`.
2. Encaminhe o `## Visual & UI/UX Contract` para o Arquiteto no ESTADO 2.

### 📍 ESTADO 2: DESIGN TÉCNICO & ATOMICIDADE (System Architect)
1. Invoque o subagente `system-architect` via `invoke_subagent`:
   - Envie a especificação funcional do PO, o contexto do repositório (`PROJECT_CONTEXT.md`) e o `## Visual & UI/UX Contract` (quando aplicável).
   - O Arquiteto mapeia quais módulos em `src/` serão alterados ou criados.
   - Caso haja escolha de design ou arquitetura, registra as decisões em `docs/ARCHITECTURE.md`.
   - **Regra de Atomicidade AIDD**: Cada issue gerada DEVE ter no máximo **3 passos concretos** para execução posterior em TDD.
   - **Mapeamento de Blast Radius & Precedências**: Cada issue fatiada deve conter explicitamente a seção `## Target Files & Dependencies` com os campos `Target Files:` e `Depends On:`.
   - **Heurística de Execution Waves**: O Arquiteto organiza as issues fatiadas em ondas sequenciais (`## Execution Waves`) para viabilizar execução concorrente em Git Worktrees. Cada onda suporta até no máximo 3 issues simultâneas por wave, com a garantia mandatória de conjuntos de arquivos 100% disjuntos (interseção nula) entre as issues da mesma onda. Issues com colisão em `Target Files` ou com relações de dependência são alocadas em ondas subsequentes.
   - Acolhe e embute a seção `## Visual & UI/UX Contract` no `planning_proposal.md` e nas issues fatiadas correspondentes.
2. Aguarde o retorno com o plano consolidado.

### 📍 ESTADO 3: GATE DE REVISÃO & APROVAÇÃO HUMANA
1. Apresente o `planning_proposal.md` ao desenvolvedor utilizando `write_file` com `RequestFeedback: true`.
2. Para propostas com interface visual (`UI_UX_REQUIRED: YES`), instrua o desenvolvedor a realizar a validação visual inspecionando o arquivo de preview gerado `.mockup-preview.png` antes da aprovação.
3. O desenvolvedor revisa:
   - Se solicitar ajustes visuais ou de arquitetura: reinvoque o subagente correspondente (`uiux-designer` ou `system-architect`).
   - Se aprovar: avance para o **ESTADO 4**.

### 📍 ESTADO 4: CRIAÇÃO DETERMINÍSTICA NO GITHUB
1. Verifique a configuração de **Active Milestone** em `PROJECT_CONTEXT.md` (sob `## 🎯 Rastreamento & GitHub Governance`):
   - Se definida e diferente de `None` (ex.: `"v1.1.0"`), anexe `--milestone "<milestone>"` ao comando `gh issue create`.
   - Se ausente ou `None`, omita a flag `--milestone`.
2. Para cada issue fatiada no plano aprovado, execute o comando CLI do GitHub utilizando a taxonomia oficial de labels (`type:*`, `status:planned`, e opcionalmente `aidd:wave-*`), incluindo a seção `## Target Files & Dependencies` e a flag `--milestone` (quando ativa):
   ```bash
   gh issue create \
     --title "feat(<escopo>): <título da task atômica>" \
     --label "type:feat,status:planned" \
     [--milestone "<milestone>"] \
     --body "<descrição_completa_com_critérios_de_aceite_e_referência_ao_triângulo_AIDD>

   ## Target Files & Dependencies
   - Target Files: <caminhos_dos_arquivos>
   - Depends On: <dependencias_ou_none>"
   ```
   > [!NOTE]
   > Adapte a label `type:*` para a natureza da issue fatiada (`type:feat`, `type:fix`, `type:docs`, `type:refactor`, `type:chore`, `type:test`).
3. **Vinculação a GitHub Projects v2 (Degradação Graciosa)**:
   - Se `GitHub Project v2` estiver configurado em `PROJECT_CONTEXT.md` com `Owner` e `Project Number` válidos (diferentes de `None`), adicione cada issue criada ao quadro do projeto:
     ```bash
     gh project item-add "<project_number>" --owner "<owner>" --url "<issue_url>" || echo "⚠️ [WARN] Falha não-bloqueante ao adicionar issue ao GitHub Project v2 (<project_number>). Prosseguindo esteira."
     ```
   - Em caso de erro (ex.: 403, permissões insuficientes ou projeto inexistente), o pipeline emite a mensagem `⚠️ [WARN]` e conclui sem bloquear a esteira (Princípio da Degradação Graciosa).
4. **Inclusão Obrigatória de UI/UX Contract**: Para tarefas com interface visual, inclua obrigatoriamente a seção `## Visual & UI/UX Contract` (Spatial Blueprint ASCII, Design Tokens & Luminance Contract) diretamente no corpo (`--body`) do comando `gh issue create`.
5. Caso seja um Épico, vincule as sub-issues criadas à issue principal utilizando a flag `--parent <numero_do_epico>` (se suportado pelo repositório) ou adicione a checklist de links na descrição do Épico.
6. Apresente ao desenvolvedor o sumário com os links de todas as Issues criadas no GitHub e a matriz consolidada de **Execution Waves**, prontas para serem executadas com `/run-issue #<numero>`.
