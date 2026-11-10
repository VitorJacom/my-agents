---
name: code-review
description: >-
  Auditoria rigorosa de código-fonte, identificando vulnerabilidades de segurança,
  oportunidades de refatoração, conformidade com SOLID e Clean Code.
---

# Code Review & Quality Audit

Esta Skill orienta o agente a realizar revisões de código aprofundadas antes de finalizar merges ou entregas de código.

## 1. Critérios de Avaliação

A revisão deve focar em 4 dimensões essenciais:

### 1.1. Segurança (Security & OWASP)
- **Injection**: Consultas SQL dinâmicas não sanitizadas, comandos de shell interpolados.
- **Exposição de Dados**: Logs contendo tokens, senhas, CPFs ou dados pessoais sensíveis.
- **Validação de Inputs**: Ausência de schemas ou validações de payloads em endpoints de API.

### 1.2. Arquitetura e Clean Code
- **SOLID**: Violação de responsabilidade única (funções/classes inchadas com muitas obrigações).
- **Acoplamento**: Dependências fortes e diretas em vez de interfaces ou injeção de dependências.
- **Complexidade Ciclomática**: Loops e condicionais aninhados excessivos (recomenda-se early return).

### 1.3. Robustez e Tratamento de Erros
- Blocos `try/catch` vazios ou que apenas suprimem exceções sem log nem rethrow.
- Ausência de tratamento para timeouts e falhas em chamadas de rede ou IO.
- Riscos de Null Pointer / `undefined` sem checagem adequada.

### 1.4. Testabilidade
- Código difícil de isolar para teste unitário devido a dependências estáticas ou globais.
- Efeitos colaterais ocultos dentro de funções de cálculo ou getters.

---

## 2. Formato do Relatório de Review

Organize o feedback em três níveis de severidade:

```markdown
### 🚨 Crítico (Bloqueia Merge)
Problemas de segurança, falhas de lógica graves, quebra de contratos de API ou vazamento de dados.
- **[Arquivo:Linha]**: Descrição objetiva da vulnerabilidade ou defeito crítico.
  - *Sugestão de correção*: Código ou abordagem recomendada.

### ⚠️ Importante (Refatoração Recomendada)
Violações de boas práticas, ausência de testes em fluxos relevantes, complexidade excessiva.
- **[Arquivo:Linha]**: Descrição da melhoria técnica.

### 💡 Sugestão (Melhoria Opcional)
Ajustes estéticos, clareza em nomes de variáveis ou pequenas otimizações de sintaxe.
- **[Arquivo:Linha]**: Sugestão.
```

---

## 3. Integração com a Esteira de Pull Requests (`/review-pr`)

Para auditorias automatizadas e revisões formais de Pull Requests abertas no GitHub com submissão de pareceres oficiais e geração de issues rastreadas no backlog, utilize a esteira complementar de PR:

- **Skill Especializada**: [skills/review-pr/SKILL.md](../review-pr/SKILL.md)
- **Comando de Invocação**: `/review-pr <#PR | URL>`

A esteira `/review-pr` implementa uma máquina de estados de 5 fases (Inspeção & Diff, Auditoria de Integridade & Golden Rule, Revisão Heurística em 4 Dimensões, Gate de Validação Humana Mandatório e Despacho & Rastreabilidade via `scripts/pr-reviewer.sh`).
