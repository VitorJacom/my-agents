[← Voltar ao Sumário de Skills](Skills-Catalog)

# Skill: `git-workflow` (Branches Semânticas, Commits & PRs)

> **Definição Canônica**: [`skills/git-workflow/SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/git-workflow/SKILL.md)  
> **Categoria**: Engenharia, Arquitetura & Infra  
> **Comando de Invocação**: Invocação contextual ao criar branches, commits ou PRs

---

## 🎯 Objetivo

A skill **`git-workflow`** padroniza todo o ciclo de versionamento no Git: criação de branches semânticas, commits atômicos no formato **Conventional Commits** em inglês, checklist rigoroso de pré-commit e formatação de Pull Requests com fechamento automático (*auto-close*) de issues no GitHub.

---

## ⚡ Quando Acionar (*Progressive Disclosure*)

- Ao criar uma nova branch de feature, bugfix ou refatoração.
- Ao preparar commits atômicos com mensagens padronizadas.
- Ao redigir a descrição de um Pull Request (`walkthrough.md`) vinculando issues.

---

## 🚀 Exemplos de Invocação

```text
Crie a branch de trabalho para a issue #20
Prepare o commit das mudanças de documentação seguindo Conventional Commits
Gere a descrição do PR vinculando a issue #42
```

---

## 🌿 1. Convenção de Branches

Sempre em `kebab-case` conciso e descritivo:
- `feature/<nome-da-funcionalidade>` — Novas funcionalidades
- `fix/<nome-do-bug>` — Correções de defeitos
- `refactor/<nome-do-modulo>` — Refatorações internas

---

## 📝 2. Conventional Commits (em Inglês)

Formato: `<type>(<scope>): <subject>`

| Tipo | Uso Canônico |
| :--- | :--- |
| `feat` | Nova funcionalidade ou recurso |
| `fix` | Correção de bug ou comportamento incorreto |
| `refactor` | Mudança interna sem alterar comportamento nem adicionar testes |
| `test` | Adição ou ajuste de testes automatizados |
| `docs` | Alterações exclusivas em documentação |
| `chore` | Tooling, dependências, build ou CI/CD |
| `perf` | Otimização explícita de performance |

---

## ✅ 3. Checklist de Pré-Commit & Auto-Close de PRs

- **Inspeção obrigatória**: Verificar `git status` e `git diff` antes do commit.
- **Staging seletivo**: Usar `git add <caminhos-especificos>` (nunca `git add .` às cegas) e garantir ausência de `.env`, chaves ou artefatos temporários.
- **Closing Keywords em Texto Puro**: No corpo do PR, usar `Fixes #<id>`, `Closes #<id>` ou `Resolves #<id>` **sempre em texto puro** — nunca entre crases inline ou blocos de código, pois isso desativa o *auto-close* nativo do GitHub.

---

## 🔗 Navegação

[← Anterior: `test-runner`](Skill-test-runner) | [Sumário de Skills](Skills-Catalog) | [Próxima Skill: `architecture-decision` →](Skill-architecture-decision)
