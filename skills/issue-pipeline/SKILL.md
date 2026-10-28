---
name: issue-pipeline
description: >-
  Orquestra o ciclo completo e determinístico de desenvolvimento de uma Issue do GitHub:
  Planner ➔ QA Engineer (RED) ➔ Coder (GREEN) ➔ Gatekeeper (Auditoria & PR).
---

# Issue Pipeline Orchestrator (`/run-issue`)

Esta Skill gerencia a execução da máquina de estados do pipeline determinístico multiagente para implementar requisitos e Issues do GitHub com garantia estrita de integridade e TDD.

## 🚀 Como Invocar
O usuário dispara o comando informando o número ou URL da Issue:
```text
/run-issue #12
# ou
/run-issue 12
# ou
/run-issue https://github.com/org/repo/issues/12
```

---

## 🔄 Máquina de Estados e Protocolo de Orquestração

> [!IMPORTANT]
> **Execução Concorrente e Isolada:**
> Cada estado do pipeline DEVE invocar o subagente correspondente usando `invoke_subagent`. O orquestrador nunca executa o código ou os testes diretamente; ele delega, aguarda a mensagem com o resultado e audita a transição.

O agente orquestrador deve guiar a execução estado por estado, chamando os subagentes dedicados via `invoke_subagent` e validando os critérios de transição:

### 📍 ESTADO 1: PLANNING
1. Identifique o número da Issue e seu contexto.
2. Invoque o subagente `planner`:
   - Envie a tarefa para ler a Issue e inspecionar a arquitetura existente.
   - Solicite a geração de `implementation_plan.md` e `task.md`.
3. **Validação do Portão de Planejamento**:
   - O plano possui mais de 3 passos ou atinge domínios desconexos?
   - **Se NÃO (Aprovado)**: Avance para o **ESTADO 2**.
   - **Se SIM (Rejeitado)**: Pare a execução imediatamente. Informe ao usuário os motivos do arquiteto e solicite o fatiamento da Issue.

---

### 📍 ESTADO 2: TEST DESIGN (TDD RED)
1. Crie uma branch de trabalho dedicada seguindo o padrão de branches:
   ```bash
   git checkout -b feature/issue-<numero>-<slug>
   ```
2. Invoque o subagente `qa-engineer`:
   - Instrua-o a ler `implementation_plan.md` e criar os testes de aceite estritamente em `tests/features/`.
   - Instrua-o a rodar o test runner e capturar a prova de falha (**RED**).
3. **Validação do Portão de QA**:
   - Os testes novos falharam conforme esperado e cobrem regras reais?
   - **Se SIM (Aprovado)**: Registre a prova do RED e avance para o **ESTADO 3**.
   - **Se NÃO (Falso Positivo ou Teste Trivial)**: Interrompa a esteira e exija correção dos testes.

---

### 📍 ESTADO 3: CODING LOOP (TDD GREEN)
1. Invoque o subagente `coder`:
   - Instrua-o a implementar a solução estritamente dentro da pasta `src/`.
   - Lembre-o da **Trava Anti-Fraude**: é proibido tocar em arquivos da pasta `tests/`.
   - Execute o loop de até 3 iterações (editar código ➔ rodar testes).
2. **Validação do Portão de Implementação**:
   - Todos os testes passaram (**GREEN**)?
   - **Se SIM (Sucesso)**: Avance para o **ESTADO 4**.
   - **Se NÃO (Estourou 3 tentativas sem passar)**: Interrompa a esteira imediatamente com status de falha e apresente o log de erro ao usuário.

---

### 📍 ESTADO 4: GATEKEEPING & HANDOFF
1. Invoque o subagente `gatekeeper`:
   - Executar auditoria de integridade com `git diff --stat origin/main` (ou branch base).
   - Validar que nenhum teste fora da nova feature foi modificado ou relaxado.
   - Gerar o artefato consolidado `walkthrough.md`.
   - Comitar as alterações e abrir o Pull Request no GitHub (via MCP ou `gh pr create`) vinculando a Issue (`Fixes #<numero>`).
2. **Conclusão & Handoff**:
   - Apresente ao usuário o link do Pull Request aberto, o resumo das validações e a documentação gerada em `walkthrough.md`.
