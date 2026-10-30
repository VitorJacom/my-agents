# Relatório de Provas Determinísticas (Walkthrough) - Protocolo Clean Room Testing

**Ciclo:** `/learn` (Sandbox Clean Room Protocol)  
**Data:** 2026-10-30  
**Status:** 100% GREEN (Aprovado e Validado)

---

## 1. Contexto e Motivação
Para evitar contaminação de contexto e garantir testes com fidelidade de produção em repositórios consumidores simulados (`sandbox/`), estabelecemos o **Protocolo de Validação Isolada em Sandbox (Clean Room Testing)**:
- Obrigatoriedade de navegação com `cd` para dentro do diretório do sandbox antes de executar o Antigravity CLI.
- Execução desacoplada via nova instância do `agy` (`agy --dangerously-skip-permissions -p "..."`).
- Validação autêntica da estrutura local `.agents/` sem resíduos de memória do chat pai.

---

## 2. Alterações Realizadas

| Arquivo | Ação | Descrição |
| :--- | :--- | :--- |
| `rules/AGENTS.md` | Modificado | Adicionada Seção 8: Protocolo de Validação Isolada em Sandbox (Clean Room Testing). |
| `skills/test-runner/SKILL.md` | Modificado | Adicionada Seção 4: Procedimento de execução de testes em Clean Room. |
| `~/.gemini/config/plugins/my-agents` | Atualizado | Reinstalado e sincronizado com `agy plugin install .`. |

---

## 3. Evidências de Execução Determinística

### 3.1. Validação do Plugin
```bash
agy plugin validate .
```
**Saída:**
```text
Validating my-agents (plugin.json)
  skills 8 · agents 6 · rules 1 · hooks 2 · mcpServers 0 · sidecars 0
✔ Validation passed
```

### 3.2. Teste Isolado em Clean Room (Nova Instância `agy` após `cd sandbox`)
```bash
cd /home/vitor/Projetos/03-pessoal/my-agents/sandbox && agy --dangerously-skip-permissions -p "Qual é o nome do projeto atual e qual o status dos testes? Execute npx vitest run e reporte resumidamente."
```
**Saída da Nova Instância Desacoplada:**
```text
O nome do projeto atual é sandbox-app (definido em package.json).

Status dos Testes (npx vitest run):
A suíte de testes está 100% verde (passando sem falhas):
* Arquivos de teste: 3 aprovados (3 no total)
  - tests/core/sanity.test.ts (1 teste)
  - tests/features/string-utils.spec.ts (4 testes)
  - tests/features/url-validator.spec.ts (6 testes)
* Total de testes: 11 aprovados (0 falhas)
* Duração: 435ms
```

---

## 4. Auditoria Git (`git status --short`)

```text
 M rules/AGENTS.md
 M skills/test-runner/SKILL.md
?? implementation_plan.md
?? task.md
?? walkthrough.md
```
