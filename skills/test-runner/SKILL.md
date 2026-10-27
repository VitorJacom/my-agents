---
name: test-runner
description: >-
  Execução inteligente de testes automatizados, diagnóstico de falhas e reparo cirúrgico
  de suítes quebradas em múltiplos ecossistemas (Node/TS, Python, Go, etc.).
---

# Test Runner & Diagnostic Workflow

Esta Skill orienta a execução eficiente de testes, diagnóstico de erros e garantia de regressão zero.

## 1. Deteção do Ecossistema de Testes

Antes de rodar a suíte inteira, inspecione a raiz do projeto para identificar o test runner:

- **Node.js / TypeScript**:
  - `vitest`: `npx vitest run <caminho-do-teste>`
  - `jest`: `npx jest <caminho-do-teste>`
  - `npm test` / `pnpm test` / `yarn test`
- **Python**:
  - `pytest`: `pytest <caminho_do_teste> -v`
  - `unittest`: `python -m unittest <arquivo>`
- **Go**:
  - `go test -v ./...` ou `go test -v ./pkg/subfolder`

---

## 2. Estratégia de Execução Cirúrgica

1. **Foco Imediato**: Rode primeiro **apenas o arquivo de teste** diretamente relacionado ao código que você alterou. Isso economiza tempo e provê feedback instantâneo.
2. **Validação Geral**: Após o teste focado passar, execute a suíte completa ou os testes do módulo para verificar se não houve efeito colateral ou regressão.

---

## 3. Diagnóstico e Reparo de Falhas

Se um teste quebrar, siga a seguinte ordem:

1. **Analise o Diff do Teste**:
   - `Expected` vs `Received`: O resultado esperado mudou intencionalmente por uma nova regra de negócio, ou a implementação gerou uma regressão?
2. **Não altere o teste levianamente**:
   - Nunca altere a asserção do teste apenas para fazê-lo "ficar verde", a menos que a regra de negócio tenha sido explicitamente modificada.
3. **Corrija a Implementação**:
   - Faça ajustes pontuais na função ou classe sob teste.
4. **Adicione Testes de Regressão**:
   - Se a falha foi causada por um bug recém-descoberto, crie um caso de teste específico que reproduzia a quebra antes da correção.
