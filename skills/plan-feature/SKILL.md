---
name: plan-feature
description: >-
  Orquestra o ciclo completo de planejamento e design de software via GitHub (AIDD) com o Modelo Elephant-Goldfish:
  Product Owner (The Elephant: Requisitos & Valor Socrático) ➔ [UI/UX Designer (Mockup-as-Code, se UI)] ➔ System Architect (Impacto Técnico, ADR & Atomicidade) ➔ Gatekeeper (The Goldfish: Cold Audit & Auto-Healing <= 2 iterações) ➔ Gate de Aprovação Humana ➔ Criação das Issues no GitHub.
---

# Feature Planning Pipeline (`/plan-feature`)

Esta Skill gerencia a esteira de planejamento e design de software no GitHub, decompondo ideias, refinando issues existentes, estruturando contratos visuais e decisões de arquitetura sob o modelo **Elephant-Goldfish** antes de qualquer linha de código ser escrita.

## 🚀 Como Invocar
```text
/plan-feature <ideia, descrição de funcionalidade, issue existente #XX ou decisão técnica>
```

---

## 🔄 Máquina de Estados de Planejamento (Ciclo Elephant-Goldfish)

```mermaid
flowchart TD %% Ciclo Elephant-Goldfish com Decisão Condicional por Interface Visual (UI_UX_REQUIRED)
    Start["[Entrada: Ideia / Épico / Issue #XX]"] --> PO["1. Product Owner (The Elephant)<br/>(Contexto Cumulativo, Postura Socrática & Living Specs)"]
    PO --> Decision{"Interface Visual?<br/>(UI_UX_REQUIRED)"}
    Decision -- YES --> UIUX["1.5. UI/UX Designer<br/>(Modo 1: Mockup-as-Code & Visual Contract)"]
    Decision -- NO --> Arch["2. System Architect<br/>(Design Técnico, <= 3 passos, Interface Contract & Waves)"]
    UIUX --> Arch
    Arch --> Goldfish["2.5. Gatekeeper (The Goldfish Reviewer)<br/>(Cold Audit Stateless, Anti-Premissas & Interface Contract Gate)"]
    Goldfish -- "SPEC_AUDIT: REJECTED" --> Healing{"Loop de Auto-Healing<br/>(Teto: 2 iterações)"}
    Healing -- "Iteração <= 2" --> Arch
    Healing -- "Excedeu 2 iterações" --> CircuitBreaker["🚨 Circuit Breaker<br/>(Interrupção Determinística)"]
    Goldfish -- "SPEC_AUDIT: APPROVED" --> Gate["3. Gate de Aprovação Humana<br/>(Validação Desenvolvedor + .mockup-preview.png)"]
    Gate --> GH["4. Criação no GitHub<br/>(gh issue create + Interface Contract & Visual Spec)"]
    GH --> Reconcile["5. Reconciliação de Governança<br/>(reconcile-github-governance.sh)"]
    Reconcile --> Done["[ Handoff Final ]"]
```

---

## 📋 Protocolo de Execução por Estado

### 📍 ESTADO 1: DESCOBERTA FUNCIONAL (Product Owner — The Elephant)
1. Invoque o subagente `product-owner` (atuando como **The Elephant**) via `invoke_subagent`:
   - Envie a descrição do requisito ou o número da Issue (#XX).
   - **Postura Socrática de Engenharia de Requisitos**: O PO adota postura socrática ativa. Faz perguntas desafiadoras, investiga motivações de negócio e cenários de borda antes de consolidar.
   - **Retenção de Contexto de Longo Alcance**: O PO opera como guardião da visão global e histórico, assegurando especificações autocontidas que passem no teste do olhar frio sem assumir conhecimento tácito.
   - Define personas e redige os critérios de aceite em formato Gherkin (`Dado / Quando / Então`) ou checklist verificável.
   - **Refinamento In-Place ou Criação Nova**: Se a demanda referir-se a uma issue preexistente no backlog, o PO estrutura o refinamento in-place (preparando alterações para `gh issue edit`), evitando duplicação.
   - **Enquadramento em Épico & Release**: Identifica o Épico temático correspondente (`Active Epic (Milestone)`) e a release prevista no GitHub Project v2 (`Release Field`, ex.: `v1.1.0`, `v1.2.0`, `Backlog / Future`).
   - **Classificação Obrigatória de Impacto Visual**: O PO classifica explicitamente a demanda:
     - `UI_UX_REQUIRED: YES` (quando a funcionalidade envolver interface visual, tela gráfica, Web App, componente UI, HUD de jogo ou terminal interativo).
     - `UI_UX_REQUIRED: NO` (quando for puramente backend, CLI estrutural, script de infraestrutura ou automação de dados sem interface visual).
2. Aguarde a conclusão da especificação funcional com a classificação definida.

### 📍 ESTADO 1.5: UI/UX & MOCKUP DESIGN (uiux-designer — Condicional)
> [!NOTE]
> Esta etapa condicional é executada exclusivamente se o PO definir `UI_UX_REQUIRED: YES`. Caso contrário (`UI_UX_REQUIRED: NO`), avança diretamente para o **ESTADO 2** (Zero Token Waste).

1. Invoque o subagente `uiux-designer` via `invoke_subagent` operando em **Modo 1 (Concepção & Mockup-as-Code)**:
   - Envie os requisitos funcionais e critérios de aceite gerados pelo PO.
   - O `uiux-designer` define o identificador kebab-case único da tela/funcionalidade (`<slug>`) e executa o protocolo Figma-less Mockup-as-Code estruturado em 3 camadas:
     1. **Camada 1: Spatial Blueprint (Wireframe Estrutural ASCII)**: Diagrama Box-drawing Unicode (`┌`, `─`, `┐`, etc.) no grid de 4px/8px definindo hierarquia, proporções e estados interativos.
     2. **Camada 2: Design Tokens & Luminance Contract**: Tabela formal de cores hexadecimais, conversão em escala de cinza demonstrando Value Contrast $\ge$ 2:1 para superfícies/elementos e WCAG AA $\ge$ 4.5:1 para textos, escalas tipográficas e sombras de oclusão.
     3. **Camada 3: Protótipo Estático Autocontido & Captura Headless**: Cria o arquivo efêmero `.mockup-preview.html` e renderiza `.mockup-preview.png` via comando headless, salvando a imagem persistente em `docs/assets/mockups/<slug>.png`:
        ```bash
        chromium --headless --screenshot=docs/assets/mockups/<slug>.png --window-size=1280,720 .mockup-preview.html
        ```
   - **Persistência da Living Spec**: O subagente cria a especificação viva em `docs/mockups/<slug>.md` baseada no template canônico [docs/mockups/TEMPLATE.md](docs/mockups/TEMPLATE.md), salvando o screenshot em `docs/assets/mockups/<slug>.png` e registrando a nova tela no catálogo `docs/mockups/README.md`.
   - O subagente consolida e entrega o bloco formal `## Visual & UI/UX Contract` (Camadas 1 e 2), a referência à especificação viva em `docs/mockups/<slug>.md` e o link/asset para visualização da captura em `docs/assets/mockups/<slug>.png` (ou `.mockup-preview.png`).
2. Encaminhe o `## Visual & UI/UX Contract` e os artefatos de mockup (`docs/mockups/<slug>.md` e `docs/assets/mockups/<slug>.png`) para o Arquiteto no ESTADO 2.

### 📍 ESTADO 2: DESIGN TÉCNICO & ATOMICIDADE (System Architect)
1. Invoque o subagente `system-architect` via `invoke_subagent`:
   - Envie a especificação funcional do PO, o contexto do repositório (`PROJECT_CONTEXT.md`) e o `## Visual & UI/UX Contract` (quando aplicável).
   - O Arquiteto mapeia quais módulos em `src/` serão alterados ou criados.
   - Caso haja escolha de design ou arquitetura, registra as decisões em `docs/ARCHITECTURE.md`.
   - **Regra de Atomicidade AIDD**: Cada issue gerada DEVE ter no máximo **3 passos concretos** para execução posterior em TDD.
   - **Padronização Mandatória de Interface Contract**: O Arquiteto é estritamente obrigado a definir no `planning_proposal.md` e nas especificações das issues a seção formal `## Interface Contract` com:
     - **Signatures**: Assinaturas completas tipadas de funções, métodos ou comandos.
     - **Types & Interfaces**: Definições formais de tipos, structs, schemas ou contratos de dados.
     - **Inputs**: Parâmetros de entrada tipados e regras de validação.
     - **Outputs**: Retornos tipados e estruturas de dados esperadas.
     - **Errors**: Erros tipados, exceções e tratamento de failure modes.
     Esta seção fornece todos os símbolos e tipos necessários para que QA (`tests/features/`) e Coder (`src/`) operem simultaneamente em paralelo (ADR-0005).
   - **Refinamento e Reorganização de Backlog**: Para issues já abertas no backlog que estão sendo reestruturadas ou refinadas, documenta as atualizações de corpo, critérios e labels a serem aplicadas com `gh issue edit`.
   - **Mapeamento de Blast Radius & Precedências**: Cada issue fatiada deve conter explicitamente a seção `## Target Files & Dependencies` com os campos `Target Files:` e `Depends On:`.
   - **Heurística de Execution Waves**: O Arquiteto organiza as issues fatiadas em ondas sequenciais (`## Execution Waves`) para viabilizar execução concorrente em Git Worktrees. Cada onda suporta até no máximo 3 issues simultâneas por wave, com a garantia mandatória de conjuntos de arquivos 100% disjuntos (interseção nula) entre as issues da mesma onda. Issues com colisão em `Target Files` ou com relações de dependência são alocadas em ondas subsequentes.
   - Acolhe e embute a seção `## Visual & UI/UX Contract` e os links para a living spec `docs/mockups/<slug>.md` e asset `docs/assets/mockups/<slug>.png` no `planning_proposal.md` e nas issues fatiadas correspondentes.
2. Aguarde o retorno com o plano consolidado.

### 📍 ESTADO 2.5: AUDITORIA GOLDFISH & AUTO-HEALING (The Goldfish Reviewer)
1. Invoque o subagente `gatekeeper` operando em **Modo 1 (The Goldfish Reviewer / Auditoria de Especificação)** via `invoke_subagent`:
   - Envie a especificação técnica consolidada contida em `planning_proposal.md`.
   - O Gatekeeper executa a auditoria fria (**Cold Audit**) com olhar estéril e sem estado prévio:
     - **Interface Contract Gate (Validação Estrita de Contrato)**: Bloqueio determinístico e rejeição imediata (`SPEC_AUDIT: REJECTED`) caso a seção `## Interface Contract` esteja ausente, ambígua, desprovida de tipagem explícita ou contendo termos especulativos/placeholders. O contrato deve garantir símbolos inequívocos para QA e Coder operarem simultaneamente.
     - Validação de Atomicidade: cada issue não pode ter mais de 3 passos (> 3 passos é bloqueado).
     - Validação Anti-Premissas: bloqueio determinístico de premissas implícitas não testadas, ambiguidades e termos especulativos ("supõe-se", "obviamente", "deve funcionar").
     - Autocontenção e verificabilidade dos critérios de aceite.
2. **Loop de Auto-Healing de Especificação**:
   - Se o Gatekeeper aprovar (`SPEC_AUDIT: APPROVED`), avance imediatamente para o **ESTADO 3**.
   - Se o Gatekeeper rejeitar (`SPEC_AUDIT: REJECTED`), inicia-se o **loop de auto-healing de especificação**:
     - O Arquiteto e o PO ajustam a proposta sanando pontualmente os apontamentos da auditoria fria.
     - **Teto Determinístico**: O loop de auto-healing possui um **limite máximo de 2 iterações** (teto determinístico de 2 iterações).
     - Se após a segunda iteração a especificação ainda não obtiver aprovação do Goldfish, o pipeline ativa o **Circuit Breaker** e interrompe a esteira com erro explícito, prevenindo context collapse, conversational slop e deriva de especificação.

### 📍 ESTADO 3: GATE DE REVISÃO & APROVAÇÃO HUMANA
1. Apresente o `planning_proposal.md` já auditado pelo Goldfish ao desenvolvedor utilizando `write_file` com `RequestFeedback: true`.
2. Para propostas com interface visual (`UI_UX_REQUIRED: YES`), instrua o desenvolvedor a realizar a validação visual inspecionando a especificação viva em `docs/mockups/<slug>.md`, o asset em `docs/assets/mockups/<slug>.png` e o arquivo de preview gerado `.mockup-preview.png` antes da aprovação.
3. O desenvolvedor revisa:
   - Se solicitar ajustes visuais ou de arquitetura: reinvoque o subagente correspondente (`uiux-designer` ou `system-architect`).
   - Se aprovar: avance para o **ESTADO 4**.

### 📍 ESTADO 4: CRIAÇÃO DETERMINÍSTICA NO GITHUB
1. Verifique a configuração de **Active Epic (Milestone)** ou **Active Milestone** em `PROJECT_CONTEXT.md` (sob `## 🎯 Rastreamento & GitHub Governance`):
   - Se definida e diferente de `None` (ex.: `"Epic: AIDD Core & Engineering Governance"` ou `"v1.1.0"`), anexe `--milestone "<milestone>"` ao comando `gh issue create` ou `gh issue edit`.
   - Se ausente ou `None`, omita a flag `--milestone`.
2. Para cada issue fatiada no plano aprovado, execute o comando CLI do GitHub utilizando a taxonomia oficial de labels (`type:*`, `status:planned`, e opcionalmente `aidd:wave-*`), incluindo a seção `## Target Files & Dependencies`, a seção `## 🎨 Mockup & Living Visual Spec` (para issues com interface visual) e a flag `--milestone` (quando ativa):
   - **Criação de Sub-issues Nativas com `--parent`**:
     Para vincular a sub-issue diretamente à issue mãe ou Épico, anexe a flag `--parent "<parent_id>"`:
     ```bash
     gh issue create \
       --title "feat(<escopo>): <título da task atômica>" \
       --label "type:feat,status:planned" \
       [--milestone "<milestone>"] \
       [--parent "<parent_issue_id>"] \
       --body "<descrição_completa_com_critérios_de_aceite_e_referência_ao_triângulo_AIDD>

     ## Interface Contract
     - **Signatures**: <assinaturas_completas_tipadas>
     - **Types & Interfaces**: <estruturas_de_dados_e_tipagens>
     - **Inputs**: <parametros_tipados_e_validacoes>
     - **Outputs**: <retornos_esperados_tipados>
     - **Errors**: <excecoes_tipadas_e_cenarios_de_falha>

     ## 🎨 Mockup & Living Visual Spec
     ![Mockup Preview](docs/assets/mockups/<slug>.png)

     - **Living Spec**: [docs/mockups/<slug>.md](docs/mockups/<slug>.md)

     ## Target Files & Dependencies
     - Target Files: <caminhos_dos_arquivos>
     - Depends On: <dependencias_ou_none>"
     ```
   - **Tratamento de Fallback para Parent**: Caso a issue mãe informada não exista (--parent inexistente ou falha na API), realize o fallback gracioso registrando uma checklist de links para as sub-issues (checklist com sub-issues) no corpo da issue pai assim que disponível.
   - **Refinamento In-Place de Issues Existentes (`gh issue edit`)**:
     Para tarefas que refinam ou reorganizam issues preexistentes no backlog, utilize `gh issue edit` em vez de criar duplicatas:
     ```bash
     gh issue edit "<issue_number>" \
       --title "<novo_titulo>" \
       --body "<novo_corpo_com_contratos_atomicos>" \
       [--milestone "<milestone>"]
     ```
   > [!NOTE]
   > Adapte a label `type:*` para a natureza da issue fatiada (`type:feat`, `type:fix`, `type:docs`, `type:refactor`, `type:chore`, `type:test`).
3. **Vinculação a GitHub Projects v2 e Atribuição de Release (Degradação Graciosa)**:
   - Se `GitHub Project v2` estiver configurado em `PROJECT_CONTEXT.md` com `Owner` e `Project Number` válidos (diferentes de `None`), adicione cada issue criada ao quadro do projeto:
     ```bash
     gh project item-add "<project_number>" --owner "<owner>" --url "<issue_url>" || echo "⚠️ [WARN] Falha não-bloqueante ao adicionar issue ao GitHub Project v2 (<project_number>). Prosseguindo esteira."
     ```
   - **Atribuição do Campo Release no GitHub Project v2**: Se `Release Field` estiver configurado em `PROJECT_CONTEXT.md` (ex.: `"Release"`), atribua a versão planejada utilizando `gh project item-edit`:
     ```bash
     gh project item-edit "<project_number>" --owner "<owner>" --url "<issue_url>" --field "Release" --value "<release>" || echo "⚠️ [WARN] Falha não-bloqueante ao atualizar campo Release no GitHub Project v2. Prosseguindo esteira."
     ```
   - Em caso de erro (ex.: 403, permissões insuficientes ou projeto inexistente), o pipeline emite a mensagem `⚠️ [WARN]` e conclui sem bloquear a esteira (Princípio da Degradação Graciosa).
4. **Inclusão Obrigatória de Interface Contract e UI/UX Contract**: Todas as issues fatiadas devem conter obrigatoriamente a seção `## Interface Contract` (Signatures, Types & Interfaces, Inputs, Outputs, Errors) devidamente tipada, permitindo que QA e Coder atuem em paralelo. Para tarefas com interface visual, inclua adicionalmente a seção `## Visual & UI/UX Contract` (Spatial Blueprint ASCII, Design Tokens & Luminance Contract) e a seção `## 🎨 Mockup & Living Visual Spec` (contendo o preview visual embedado `![Mockup Preview](docs/assets/mockups/<slug>.png)` e o link para a especificação viva `[docs/mockups/<slug>.md](docs/mockups/<slug>.md)`) diretamente no corpo (`--body`) do comando `gh issue create`.
5. Caso seja um Épico, vincule as sub-issues criadas à issue principal utilizando a flag `--parent <numero_do_epico>` (se suportado pelo repositório) ou adicione a checklist de links na descrição do Épico.
6. Apresente ao desenvolvedor o sumário com os links de todas as Issues criadas no GitHub e a matriz consolidada de **Execution Waves**, prontas para serem executadas com `/run-issue #<numero>`.
7. **Reconciliação e Auditoria de Backlog**: Execute o utilitário determinístico `scripts/pipeline/reconcile-github-governance.sh` para reconciliar as issues recém-criadas com a Milestone ativa e o GitHub Project v2, garantindo que o fatiamento reflita nas Views Kanban e de Roadmap sem deriva de governança:
   ```bash
   ./scripts/pipeline/reconcile-github-governance.sh
   ```

---

## 🛠️ Procedimento Operacional: Reconciliação de Backlog e Governança

Para manter o backlog do repositório e o GitHub Projects v2 íntegros, organizados e sem deriva de governança, o ecossistema AIDD disponibiliza o utilitário determinístico `scripts/pipeline/reconcile-github-governance.sh`.

### 🎯 Casos de Uso
1. **Pós-Planejamento em Lote**: Após o fatiamento de épicos ou criação de múltiplas issues via `/plan-feature`, garantindo que todas as sub-issues do breakdown sejam inseridas no Project v2 e na Active Milestone.
2. **Backfill de Backlog Legado**: Inclusão retroativa de issues preexistentes criadas antes da configuração de Milestones ou Projects v2 em `PROJECT_CONTEXT.md`.
3. **Auditoria e Sincronização Periódica**: Execução idempotente para certificar que nenhuma issue aberta esteja desalinhada das políticas do repositório, mantendo views, labels e status sincronizados.

### ⚙️ Execução do Utilitário

- **Simulação Prévia (Dry-Run)**:
  Inspeciona as issues abertas e imprime as mutações que seriam realizadas sem executar chamadas destrutivas ou de escrita na API:
  ```bash
  ./scripts/pipeline/reconcile-github-governance.sh --dry-run
  ```

- **Reconciliação Efetiva (Idempotente)**:
  Lê a `Active Milestone` e os metadados do `GitHub Project v2` em `PROJECT_CONTEXT.md` e aplica as atualizações necessárias:
  ```bash
  ./scripts/pipeline/reconcile-github-governance.sh
  ```

- **Execução com Repositório Remoto Específico**:
  ```bash
  ./scripts/pipeline/reconcile-github-governance.sh --repo "owner/repo"
  ```

- **Uso de Arquivo de Contexto Alternativo**:
  ```bash
  ./scripts/pipeline/reconcile-github-governance.sh --context-file /caminho/para/PROJECT_CONTEXT.md
  ```

### 🛡️ Princípios Operacionais e Garantias

1. **Idempotência Estrita**:
   - Issues que já possuem a milestone ativa correspondente não sofrem alterações nem geram chamadas desnecessárias à API.
   - Issues com outras milestones explicitamente definidas são respeitadas e mantidas.
2. **Degradação Graciosa (Non-Blocking)**:
   - Caso a vinculação ao GitHub Projects v2 falhe (por exemplo, ausência de escopo `project` no `GITHUB_TOKEN` ou projeto inacessível), o utilitário emite um aviso (`⚠️ [WARN]`) e conclui com status `0`, prevenindo que bloqueios de infraestrutura quebrem o pipeline do desenvolvedor.
3. **Consistência de Views & Taxonomia**:
   - Assegura visibilidade instantânea nas 3 Views essenciais do GitHub Projects v2 (Kanban Board, Milestone Roadmap e Backlog Table) e consistência com a taxonomia oficial de labels (`type:*`, `status:planned`, `aidd:wave-*`).
