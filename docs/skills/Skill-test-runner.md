[← Voltar ao Sumário de Skills](Skills-Catalog)

> **Diagnóstico e Reparo Cirúrgico de Testes**  
> **Definição Canônica**: [`skills/test-runner/SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/test-runner/SKILL.md)  
> **Categoria**: Qualidade, Testes & Revisão  
> **Comando de Invocação**: `/test-runner` ou solicitação de execução/diagnóstico de testes

---

## 🎯 Objetivo

A skill **`test-runner`** orienta a execução inteligente de suítes de testes automatizados em múltiplos ecossistemas (Node/TS, Python, Go), o diagnóstico cirúrgico de falhas e o reparo seguro com garantia de **regressão zero** — sem nunca adulterar asserções legítimas em [`tests/core/`](Test-core) para forçar testes verdes, conforme o [`AIDD-Manifesto`](AIDD-Manifesto).

---

## ⚡ Quando Acionar (*Progressive Disclosure*)

- Quando uma suíte de testes falha ou o pipeline de CI fica vermelho (consulte também [`Tests-Catalog`](Tests-Catalog) e [`Troubleshooting`](Troubleshooting)).
- Ao validar mudanças pontuais de forma rápida antes de rodar a suíte completa, especialmente em ciclos do [`qa-engineer`](Agent-qa-engineer) e do [`coder`](Agent-coder).
- Ao executar validações isoladas em ambiente *Clean Room* (`sandbox/`).

---

## 🚀 Exemplos de Invocação

```text
/test-runner
Execute apenas os testes de autenticação e diagnostique as falhas
Valide o plugin no sandbox em modo Clean Room
```

---

## 🛠️ Fluxo de Execução Cirúrgica

### 1. Detecção Automática do Ecossistema
- **Node.js / TypeScript**: `npx vitest run <arquivo>`, `npx jest <arquivo>`, `npm test` / `pnpm test` / `yarn test`.
- **Python**: `pytest <arquivo> -v`, `python -m unittest <arquivo>`.
- **Go**: `go test -v ./...` ou `go test -v ./pkg/<subpasta>`.

### 2. Estratégia em 2 Passos
1. **Foco Imediato**: Executa primeiro apenas o arquivo de teste relacionado à alteração para feedback instantâneo.
2. **Validação Geral**: Após o teste focado passar, executa a suíte do módulo ou a suíte completa para certificar zero regressão.

### 3. Protocolo de Diagnóstico e Reparo
1. Analise o diff (`Expected` vs `Received`) para distinguir mudança intencional de regra de negócio vs. regressão.
2. **Nunca altere o teste levianamente** para fazê-lo passar.
3. Corrija pontualmente a implementação sob teste.
4. Adicione um teste de regressão dedicado caso a falha tenha revelado um novo bug.

### 4. Validação em *Clean Room* (Sandbox)
Ao validar plugins, hooks ou esteiras em diretórios `sandbox/`:
```bash
cd sandbox && agy --dangerously-skip-permissions -p "npx vitest run"
```
Navegar explicitamente para dentro do `sandbox` e disparar uma nova instância desacoplada do CLI (`agy`) garante zero vazamento de contexto do repositório pai.

---

## 📦 Artefatos Produzidos

- Diagnóstico claro da causa-raiz das falhas.
- Correção cirúrgica na implementação e eventuais testes de regressão.
- Evidência de execução 100% verde (**GREEN**).

---

## 🔗 Navegação

[← Anterior: `code-review`](Skill-code-review) | [Sumário de Skills](Skills-Catalog) | [Próxima Skill: `git-workflow` →](Skill-git-workflow)
