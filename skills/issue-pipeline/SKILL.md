---
name: issue-pipeline
description: >-
  Orquestra o ciclo completo e determinístico de desenvolvimento de uma ou múltiplas Issues do GitHub:
  Modo Unitário e Modo Maestro Multi-Issue (Pre-flight, Execution Waves, Merge Queue e Auto-Reconciliação).
---

# Issue Pipeline Orchestrator (`/run-issue`)

Esta Skill gerencia a execução da máquina de estados do pipeline determinístico multiagente para implementar requisitos e Issues do GitHub com garantia estrita de integridade, TDD e arquitetura limpa.

Suporta operação em dois modos de trabalho:
1. **Modo Unitário**: Processamento focado e atômico de 1 única Issue com branch de feature direta para a branch principal.
2. **Modo Maestro**: Orquestração multi-issue concorrente com particionamento em ondas de execução (Execution Waves), branch intermediária de integração, isolamento em Git worktrees, Merge Queue sequencial e Auto-Reconciliação.

---

## 🚀 Como Invocar

### 1. Modo Unitário (1 Issue)
O usuário dispara o comando informando o número ou URL de uma única Issue:
```text
/run-issue #12
# ou
/run-issue 12
# ou
/run-issue https://github.com/org/repo/issues/12
```

### 2. Modo Maestro (Multi-Issue & Épicos)
O usuário dispara a esteira informando múltiplas issues ou a flag de épico:
```text
# Multi-issue explícito com múltiplos identificadores:
/run-issue #12 #13 #14
# ou múltiplos números:
/run-issue 12 13 14

# Modo Maestro via Épico:
/run-issue --epic #10
# ou
/run-issue --epic 10
```

---

## 🔄 Visão Geral dos Estados (Modo Unitário e Modo Maestro)

```mermaid
flowchart TD %% Orquestrador: Modo Unitário e Modo Maestro com Merge Queue e Ondas (Waves)
    Start["[Entrada: /run-issue]"] --> CheckMode{"Modo de Execução?"}
    
    %% Modo Unitário
    CheckMode -- "Modo Unitário (1 Issue)" --> E1["1. PLANNING<br/>(planner: implementation_plan.md & task.md)"]
    E1 --> CheckContract{"Interface Visual?<br/>(UI_UX_REQUIRED: true) e<br/>sem Contrato Prévio?"}
    CheckContract -- "Sim" --> E1Fallback["1.1 Fallback UI/UX<br/>(uiux-designer: Modo 1 Mockup-as-Code)"]
    CheckContract -- "Não" --> E2["2. TEST DESIGN (RED)<br/>(qa-engineer: tests/features/)"]
    E1Fallback --> E2
    E2 --> E3["3. CODING LOOP (GREEN)<br/>(coder: implementação src/)"]
    E3 --> CheckVisualGate{"Interface Visual?<br/>(UI_UX_REQUIRED)"}
    CheckVisualGate -- "true" --> E35["3.5. UI/UX VISUAL AUDIT GATE<br/>(uiux-designer: Modo 2 Inspeção Headless)"]
    CheckVisualGate -- "false (Bypass)" --> E4["4. GATEKEEPING & HANDOFF<br/>(gatekeeper: Golden Rule, walkthrough & PR)"]
    E35 --> VisualVerdict{"Veredito Visual?"}
    VisualVerdict -- "VISUAL_AUDIT: REJECTED" --> E3
    VisualVerdict -- "VISUAL_AUDIT: APPROVED" --> E4
    E4 --> EndUnit["[ Pull Request Criado & Handoff ]"]

    %% Modo Maestro
    CheckMode -- "Modo Maestro (Multi-Issue / --epic)" --> MPre["M1. Pre-flight & Wave Partitioning<br/>(Análise de Target Files & Precedências)"]
    MPre --> MBranch["M2. Criação da Branch Intermediária<br/>(integration/batch-* ou epic/*)"]
    MBranch --> MWave["M3. Despacho Concorrente da Onda (Wave)<br/>(invoke_subagent 'self' em worktrees isoladas)"]
    MWave --> MMQ["M4. Merge Queue Sequencial<br/>(worktree-manager.sh rebase-sync --base)"]
    MMQ --> MCheckSync{"Rebase & Suíte Acumulada GREEN?"}
    MCheckSync -- "Sim" --> MAutoMerge["M5. Auto-Merge na Branch Intermediária<br/>& Cleanup da Worktree"]
    MCheckSync -- "Não (RED / Conflito)" --> MReconcile["M6. Auto-Reconciliação<br/>(Até 2 tentativas com coder em worktree)"]
    MReconcile --> MReconcileVerdict{"Sucesso na Reconciliação?"}
    MReconcileVerdict -- "GREEN" --> MAutoMerge
    MReconcileVerdict -- "Esgotou 2 tentativas" --> MFailSafe["M7. Fail-Safe: Marca FAILED_RECONCILIATION<br/>(Preserva branch intermediária e avança fila)"]
    MAutoMerge --> MMoreWaves{"Mais Ondas / Issues?"}
    MFailSafe --> MMoreWaves
    MMoreWaves -- "Sim" --> MWave
    MMoreWaves -- "Não" --> MPR["M8. Gatekeeper Final & PR Consolidado<br/>(PR consolidado para main)"]
    MPR --> EndMaestro["[ Pull Request Consolidado Criado ]"]
```

> [!IMPORTANT]
> **Execução Concorrente e Isolada:**
> Cada estado do pipeline DEVE invocar o subagente correspondente usando `invoke_subagent`. O orquestrador nunca executa o código ou os testes diretamente; ele delega, aguarda a mensagem com o resultado e audita a transição.

---

## 🏛️ Fluxo 1: Modo Unitário (1 Issue)

O agente orquestrador guia a execução estado por estado, chamando os subagentes dedicados via `invoke_subagent` e validando os critérios de transição:

### 📍 ESTADO 1: PLANNING
1. Identifique o número da Issue e seu contexto.
2. Atualize o status da Issue no GitHub Projects v2 para 'In Progress' via script utilitário desacoplado:
   ```bash
   ./scripts/project-status-sync.sh "<numero_ou_url>" "In Progress"
   ```
3. Invoque o subagente `planner`:
   - Envie a tarefa para ler a Issue e inspecionar a arquitetura existente.
   - Solicite a classificação explícita de impacto visual (`UI_UX_REQUIRED: true` ou `UI_UX_REQUIRED: false`).
   - Solicite a geração de `implementation_plan.md` e `task.md`.
3. **Validação do Portão de Planejamento**:
   - O plano possui mais de 3 passos ou atinge domínios desconexos?
   - **Se SIM (Rejeitado)**: Pare a execução imediatamente. Informe ao usuário os motivos do arquiteto e solicite o fatiamento da Issue.
   - **Se NÃO (Aprovado)**: Verifique se a demanda possui impacto visual (`UI_UX_REQUIRED: true`).
4. **Resolução de Contrato Visual e Living Spec UI/UX**:
   - Se `UI_UX_REQUIRED: true`:
     - **Carregamento de Living Spec Pré-existente**: Verifique se já existe a especificação viva em `docs/mockups/<slug>.md`. Caso exista, instrua o subagente a carregar a living spec em `docs/mockups/<slug>.md` e seu asset de mockup em `docs/assets/mockups/<slug>.png`, integrando os Design Tokens e o Spatial Blueprint aprovados diretamente no `implementation_plan.md`.
     - **Fallback Condicional de Concepção UI/UX (Modo 1)**: Se a Issue ainda **não possuir** um `## Visual & UI/UX Contract` consolidado e a living spec em `docs/mockups/<slug>.md` não existir:
       - Invoque o subagente `uiux-designer` em **Modo 1 (Concepção & Mockup-as-Code)**.
       - O designer gera o Spatial Blueprint (Wireframe ASCII), Design Tokens e protótipo efêmero com captura `.mockup-preview.png`, persistindo a especificação em `docs/mockups/<slug>.md` e o asset em `docs/assets/mockups/<slug>.png`.
       - Injeta a seção `## Visual & UI/UX Contract` no `implementation_plan.md`.
   - Se `UI_UX_REQUIRED: false` ou se o contrato visual já estiver presente: avance diretamente para o **ESTADO 2**.

---

### 📍 ESTADO 2: TEST DESIGN (TDD RED)
1. Crie uma branch de trabalho dedicada seguindo o padrão de branches:
   ```bash
   git checkout -b feature/issue-<numero>-<slug>
   ```
2. Invoque o subagente `qa-engineer`:
   - Instrua-o a ler `implementation_plan.md` e criar os testes de aceite estritamente em `tests/features/`.
   - Instrua-o a categorizar e cobrir explicitamente cenários de **Happy Path** e cenários de **Edge Cases** / borda e falha.
   - Instrua-o a rodar o test runner e capturar a prova de falha (**RED**).
3. **Validação do Portão de QA**:
   - Os testes novos falharam conforme esperado e cobrem regras reais e cenários de borda?
   - **Se SIM (Aprovado)**: Registre a prova do RED e avance para o **ESTADO 3**.
   - **Se NÃO (Falso Positivo, Teste Trivial ou Ausência de Casos de Borda)**: Interrompa a esteira e exija correção dos testes.

---

### 📍 ESTADO 3: CODING LOOP (TDD GREEN)
1. Invoque o subagente `coder`:
   - Instrua-o a implementar a solução estritamente dentro da pasta `src/`.
   - Para tarefas visuais, obrigue o consumo rigoroso dos Design Tokens e Wireframe ASCII da seção `## Visual & UI/UX Contract`.
   - Instrua-o a garantir e comprovar cobertura mínima de código $\ge 85\%$. Se a cobertura for inferior a 85% (< 85%), interrompa e bloqueie a esteira exigindo complementação.
   - Lembre-o da **Trava Anti-Fraude**: é proibido tocar em arquivos da pasta `tests/`.
   - Execute o loop de até 3 iterações (editar código ➔ rodar testes).
2. **Validação do Portão de Implementação**:
   - Todos os testes passaram (**GREEN**) e a cobertura é $\ge 85\%$?
   - **Se NÃO (Estourou 3 tentativas sem passar ou cobertura < 85%)**: Interrompa a esteira imediatamente com status de falha e apresente o log de erro ao usuário.
   - **Se SIM (Sucesso)**:
     - Se `UI_UX_REQUIRED: true`: avance para o **ESTADO 3.5**.
     - Se `UI_UX_REQUIRED: false`: faça bypass direto para o **ESTADO 4** (Zero Token Waste).

---

### 📍 ESTADO 3.5: UI/UX VISUAL AUDIT GATE (Condicional)
> [!NOTE]
> Este portão condicional só é ativado quando `UI_UX_REQUIRED: true`. Demandas puramente lógicas ou backend realizam bypass automático direto para o ESTADO 4.

1. Invoque o subagente `uiux-designer` operando em **Modo 2 (Auditoria Visual Headless)**:
   - Instrua o subagente a capturar a tela renderizada da UI/componente implementado via navegador headless (`chromium --headless` ou canvas/headless).
   - O designer audita o resultado confrontando a imagem da implementação contra o mockup aprovado em `docs/assets/mockups/<slug>.png` e com o Spatial Blueprint e os Design Tokens acordados no `implementation_plan.md` (hierarquia tipográfica, contraste de luminância, affordance e espaçamentos).
2. **Avaliação do Veredito Visual**:
   - Se o parecer for `VISUAL_AUDIT: REJECTED`:
     - Retorne imediatamente ao **ESTADO 3 (Coder)** fornecendo o relatório detalhado de desvios visuais para correção no código em `src/`.
   - Se o parecer for `VISUAL_AUDIT: APPROVED`:
     - Armazene o parecer aprovado e a evidência visual (screenshot) para o relatório final.
     - Avance para o **ESTADO 4**.

---

### 📍 ESTADO 4: GATEKEEPING & HANDOFF
1. Invoque o subagente `gatekeeper`:
   - Envie os IDs de conversa de todos os subagentes que participaram da rodada (`planner`, `qa-engineer`, `coder` e, quando aplicável, `uiux-designer`).
   - Executar auditoria de integridade com `git diff --stat origin/main` (ou branch base).
   - Validar que nenhum teste fora da nova feature foi modificado ou relaxado (Golden Rule).
   - **Auditoria do Duplo Gate**: Comprovar conformidade estrutural contra o `PROJECT_CONTEXT.md` (zero alucinação de padrões).
   - **Auditoria de Cobertura e Casos**: Auditar que a cobertura de código é $\ge 85\%$ e que a suíte contempla separadamente cenários de Happy Path e Edge Cases / cenários de borda. Se a cobertura for inferior a 85% (< 85%), aborte e bloqueie a finalização.
   - **Auditoria Visual Mandatória**: Para issues com `UI_UX_REQUIRED: true`, exigir obrigatoriamente a auditoria visual aprovada com `VISUAL_AUDIT: APPROVED` e anexar a prova visual irrefutável (screenshot headless) no `walkthrough.md`.
   - **Auditoria Visual Comparativa (Living Mockup Side-by-Side)**: Para issues com `UI_UX_REQUIRED: true`, embutir obrigatoriamente a seção `## 👁️ Visual Comparison Audit` no `walkthrough.md` e corpo do PR contendo a tabela comparativa:
     ```markdown
     ## 👁️ Visual Comparison Audit
     | Mockup Original Aprovado | Implementação Renderizada |
     | :---: | :---: |
     | ![Mockup Original](docs/assets/mockups/<slug>.png) | ![Implementação Renderizada](<caminho_ou_screenshot>) |
     ```
   - **Provas Demonstrativas Universais**: Exigir provas demonstrativas no `walkthrough.md` para todos os domínios (screenshots para UI; saídas reais formatadas de terminal, logs estruturados ou CLI para backend/infra).
   - Executar `./scripts/sync-project-context.py .` para validar e manter o contexto arquitetural estável em `PROJECT_CONTEXT.md` (sem estado Git volátil, que é injetado dinamicamente pelo `session-start-context.sh`).
   - Executar `./scripts/metrics-collector.py` para calcular o consumo de tokens da esteira.
   - Gerar o artefato consolidado `walkthrough.md`.
   - Comitar as alterações e abrir o Pull Request no GitHub (via MCP ou `gh pr create`) vinculando a Issue (`Fixes #<numero>`).
2. **Conclusão & Handoff**:
   - Apresente ao usuário o link do Pull Request aberto, a tabela de telemetria de consumo/cota e a documentação gerada em `walkthrough.md`.

---

## 🚀 Fluxo 2: Modo Maestro (Multi-Issue Orchestration)

> [!IMPORTANT]
> **Governança Multiagente e Segregação de Planos (Manifesto AIDD - Seção 7.4)**:
> No Modo Maestro, a sessão principal atua estritamente como **Control Plane**. É expressamente proibido ao Maestro executar ciclos TDD, codificar na raiz ou editar arquivos na raiz. Todo o trabalho de código deve ser delegado a subagentes workers via `invoke_subagent` com isolamento estrito.

O **Modo Maestro** coordena o ciclo de vida completo de batches de issues ou épicos inteiros, eliminando gargalos de concorrência e garantindo integridade estrita por isolamento físico de workspaces.

### 📍 M1. Pre-flight & Wave Partitioning
Antes de qualquer despacho de código, o Maestro realiza a etapa de **Pre-flight** de `Target Files` e análise de precedências (`depends_on`):
1. **Mapeamento de Blast Radius**: Para cada issue do lote, inspeciona o escopo pretendido e extrai a lista de `Target Files`.
2. **Partição em Ondas (Execution Waves)**:
   - **Regra de Capacidade Máxima**: Cada onda possui teto de no máximo 3 workers simultâneos (concurrency cap <= 3 workers por onda).
   - **Regra de Arquivos Disjuntos**: É obrigatório que haja arquivos disjuntos (`Target Files` com interseção nula / sem sobreposição) entre todas as issues de uma mesma onda.
   - Se `TargetFiles(Issue_A) ∩ TargetFiles(Issue_B) != ∅`, a Issue B é obrigatoriamente alocada em uma onda subsequente (`Wave(B) > Wave(A)`).

### 📍 M2. Criação da Branch Intermediária
O Maestro cria e valida a branch intermediária de integração como base de todo o ciclo:
- Para batches de issues explícitas: `integration/batch-<timestamp_ou_hash>` (ex.: `integration/batch-20261106`).
- Para épicos: `epic/issue-<id>-<slug>` (ex.: `epic/issue-10-auth-system`).

### 📍 M3. Despacho Concorrente de Workers Isolados em Worktrees
Para cada issue pertencente à onda ativa:
1. O Maestro cria uma worktree estéril com lock exclusivo derivando da branch intermediária:
   ```bash
   ./scripts/worktree-manager.sh create <id> --base <branch_intermediaria>
   ```
2. O Maestro despacha workers isolados realizando delegação via `invoke_subagent 'self'` mandatória (cada issue da onda ativa deve ser despachada para um subagente worker desacoplado).
3. Cada worker opera com contexto limpo em isolamento estrito, confinado à sua worktree estéril `.worktrees/issue-<id>`, executando seu planejamento, testes (RED), codificação (GREEN) e auditoria local sem interferir na raiz ou em worktrees simultâneas.

### 📍 M4 & M5. Merge Queue Sequencial & Validação da Suíte Acumulada
À medida que os workers concluem suas tarefas, o Maestro gerencia a **Merge Queue** de forma estritamente sequencial:
1. **Rebase e Sincronização**:
   ```bash
   ./scripts/worktree-manager.sh rebase-sync <id> --base <branch_intermediaria>
   ```
2. **Validação da Suíte Acumulada**:
   - Dentro da worktree sincronizada, o Maestro executa toda a suíte de testes acumulada (`tests/core/` + `tests/features/`).
   - Todos os testes legados somados aos testes introduzidos pelas issues anteriores já mescladas devem passar (**GREEN**).
3. **Auto-Merge na Branch Intermediária**:
   - Com o teste acumulado verde, o Maestro executa o auto-merge na branch intermediária (`git checkout <branch_intermediaria> && git merge --ff-only feature/issue-<id>`).
   - Realiza a limpeza da worktree de forma idempotente via `./scripts/worktree-manager.sh remove <id>`.

### 📍 M6 & M7. Protocolo de Auto-Reconciliação e Travas Anti-Fraude
Se o comando de sincronização reportar conflito de rebase (Exit Code 4) ou se a suíte acumulada quebrar (RED):
1. **Loop de Auto-Reconciliação**:
   - O Maestro inicia a Auto-Reconciliação na worktree isolada `.worktrees/issue-<id>`.
   - Invoca o subagente `coder` concedendo um limite de **até 2 tentativas** (duas tentativas) para resolver os conflitos semânticos e fazer a suíte acumulada passar.
2. **Trava Anti-Fraude Inviolável**:
   - O subagente `coder` é proibido de alterar `tests/core/` e testes já integrados em `tests/features/` (testes pré-existentes na base branch intermediária).
   - O script `worktree-manager.sh rebase-sync` verifica a integridade desses arquivos e barra tentativas de fraude com Exit Code 3.
3. **Fail-Safe em Esgotamento**:
   - Se as 2 tentativas se esgotarem sem sucesso (ou em caso de fraude), a issue é marcada imediatamente com o status `FAILED_RECONCILIATION`.
   - O mecanismo de fail-safe isola a falha sem quebrar a branch intermediária, mantém a worktree correspondente intacta para auditoria humana e permite que a Merge Queue continue processando as demais issues da fila normalmente.

### 📍 M8. Gatekeeper Final & PR Consolidado
Ao finalizar todas as ondas de execução:
1. O Maestro aciona o subagente `gatekeeper` com `--base origin/main` na branch intermediária:
   - Valida a suíte global completa (`tests/core/` + `tests/features/`).
   - Audita a ausência de alterações em `tests/core/`.
   - Sincroniza o contexto estável via `./scripts/sync-project-context.py .`.
   - Coleta métricas consolidadas de tokens de todos os subagentes envolvidos.
2. Abre um **Pull Request consolidado** (PR consolidado / PR único) da branch intermediária diretamente para a branch `main`:
   ```bash
   gh pr create --base main --head <branch_intermediaria> \
     --title "feat(epic): batch integration of issues #A, #B, #C" \
     --body-file walkthrough.md
   ```
