---
name: git-workflow
description: >-
  Guia o agente na criação de branches semânticas, commits padronizados (Conventional Commits)
  e preparação de Pull Requests com checklist de qualidade.
---

# Git Workflow & Conventional Commits

Esta Skill deve ser acionada sempre que o agente for preparar branches, criar commits ou estruturar mensagens de Pull Request.

## 1. Criação e Gestão de Branches

Antes de iniciar uma alteração significativa, crie ou verifique a branch de trabalho:

```bash
# Para novas funcionalidades
git checkout -b feature/<nome-da-funcionalidade>

# Para correções de bugs
git checkout -b fix/<nome-do-bug>

# Para refatorações internas
git checkout -b refactor/<nome-do-modulo>
```

- Utilize nomes em minúsculas com hífen (`kebab-case`).
- Seja conciso e descritivo (ex.: `feature/auth-refresh-token`).

---

## 2. Padrão de Commits (Conventional Commits)

Os commits devem ser atômicos e seguir estritamente o padrão em inglês:

```text
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### Tipos Permitidos:
- **`feat`**: Nova funcionalidade ou recurso para o sistema.
- **`fix`**: Correção de um bug ou comportamento incorreto.
- **`refactor`**: Refatoração interna que não altera funcionalidade nem adiciona testes.
- **`test`**: Adição, refatoração ou correção de testes automatizados.
- **`docs`**: Mudanças exclusivas em documentação (ex: README, ADRs, Swagger).
- **`chore`**: Ajustes de tooling, dependências, scripts de build ou CI/CD.
- **`perf`**: Alteração de código visando melhoria explícita de performance.

### Exemplo de Mensagens Válidas:
- `feat(api): add pagination support to list endpoint`
- `fix(auth): handle expired token error gracefully`
- `test(billing): add unit tests for discount calculation`

---

## 3. Checklist de Pré-Commit

Antes de gerar o commit:
1. Verifique arquivos alterados com `git status` e analise o diff com `git diff`.
2. Garanta que nenhum arquivo sensível (`.env`, certificados, chaves) está no staging.
3. Certifique-se de que testes relevantes foram executados e passaram com sucesso.
4. Adicione apenas os arquivos necessários (`git add <caminhos-especificos>`), evitando `git add .` às cegas.

---

## 4. Template de Pull Request & Auto-Close de Issues

Ao sugerir ou preparar a descrição de um Pull Request (`walkthrough.md` ou template de PR):

### 4.1. Vinculação com Issues (Closing Keywords em Texto Puro)
Para que o GitHub encerre automaticamente a Issue vinculada ao mergear o Pull Request, utilize as palavras-chave suportadas (`Fixes #<numero>`, `Closes #<numero>` ou `Resolves #<numero>`) estritamente em **texto puro (plain text)**.

> [!WARNING]
> **Atenção ao Parser do GitHub**: Palavras-chave formatadas com crases inline (como `` `Fixes #123` ``) ou dentro de code blocks desativam o mecanismo nativo do GitHub e **não disparam o fechamento automático da issue** no merge. Use sempre texto puro fora de blocos de código.

### 4.2. Estrutura do Template de PR

Fixes #<issue-number>

```markdown
## Descrição
Resumo sucinto das alterações e motivação técnica ou de negócio.

Fixes #<issue-number>

## Tipo de Mudança
- [ ] Nova feature (feat)
- [ ] Correção de bug (fix)
- [ ] Refatoração (refactor)
- [ ] Testes (test)
- [ ] Documentação ou tooling (docs/chore)

## Checklist de Qualidade
- [ ] Commits seguem o padrão Conventional Commits
- [ ] Testes automatizados foram adicionados/atualizados
- [ ] Sem dados sensíveis ou arquivos temporários incluídos
- [ ] Testado e validado localmente
```
