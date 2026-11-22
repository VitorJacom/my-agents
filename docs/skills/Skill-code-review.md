[← Voltar ao Sumário de Skills](Skills-Catalog)

> **Auditoria de Qualidade e Segurança**  
> **Definição Canônica**: [`skills/code-review/SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/code-review/SKILL.md)  
> **Categoria**: Qualidade, Testes & Revisão  
> **Comando de Invocação**: `/code-review` ou solicitação direta de revisão local

---

## 🎯 Objetivo

A skill **`code-review`** orienta auditorias rigorosas de código-fonte local ou em branch antes de commits e merges, identificando vulnerabilidades de segurança, violações de arquitetura, falhas silenciosas e lacunas de testabilidade.

---

## ⚡ Quando Acionar (*Progressive Disclosure*)

- Antes de abrir um Pull Request ou realizar merge de uma branch local (complementando o [`git-workflow`](Skill-git-workflow) e a auditoria final do [`gatekeeper`](Agent-gatekeeper)).
- Ao solicitar revisão crítica de arquivos específicos, módulos ou diffs da working tree.
- Como base heurística da Fase 3 da esteira automatizada [`review-pr`](Skill-review-pr).

---

## 🚀 Exemplos de Invocação

```text
/code-review
Revise as alterações da branch atual contra vulnerabilidades OWASP
Audite o módulo src/auth/ quanto a SOLID e tratamento de erros
```

---

## 🔍 As 4 Dimensões de Avaliação

| Dimensão | O que é Auditado |
| :--- | :--- |
| **1. Segurança (OWASP)** | SQL/Shell Injection, exposição de tokens/senhas/PII em logs, ausência de validação de inputs e schemas em APIs. |
| **2. Arquitetura & Clean Code** | Violações de SOLID (SRP), acoplamento forte sem interfaces/injeção de dependências, complexidade ciclomática excessiva (preferir *early return*). |
| **3. Robustez & Erros** | Blocos `try/catch` vazios ou que mascaram exceções, falta de timeouts em chamadas de rede/IO, riscos de `null`/`undefined`. |
| **4. Testabilidade** | Dependências estáticas/globais que impedem isolamento unitário, efeitos colaterais ocultos em cálculos ou getters. |

---

## 📋 Formato Padrão do Relatório

O feedback é sempre estruturado em 3 níveis objetivos de severidade:

- **🚨 Crítico (Bloqueia Merge)**: Vulnerabilidades de segurança, bugs graves de lógica, quebra de contrato de API ou vazamento de dados (com `[Arquivo:Linha]` e sugestão concreta de correção).
- **⚠️ Importante (Refatoração Recomendada)**: Violações de boas práticas, ausência de testes em fluxos relevantes ou complexidade excessiva.
- **💡 Sugestão (Melhoria Opcional)**: Ajustes de clareza, nomenclatura ou pequenas otimizações de sintaxe.

> [!TIP]
> Para revisões formais de Pull Requests abertas no GitHub com submissão de parecer e abertura automática de issues no backlog, utilize a skill complementar [`review-pr`](Skill-review-pr).

---

## 🔗 Navegação

[← Anterior: `review-pr`](Skill-review-pr) | [Sumário de Skills](Skills-Catalog) | [Próxima Skill: `test-runner` →](Skill-test-runner)
