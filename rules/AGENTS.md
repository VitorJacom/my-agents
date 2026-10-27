# Diretrizes de Governança e Engenharia para Agentes

Este documento estabelece os padrões e comportamentos mandatórios que qualquer agente de desenvolvimento de IA deve seguir ao atuar neste e em outros projetos.

---

## 1. Comunicação e Idioma (Padrão Híbrido)

- **Interação com o Desenvolvedor**: A comunicação direta, relatórios, resumos de planos e explicações de decisões devem ser feitas em **Português (pt-BR)** de forma clara, objetiva e colaborativa.
- **Artefatos de Código e Engenharia**:
  - Código-fonte, nomes de variáveis, funções, classes, interfaces e testes: **Inglês**.
  - Mensagens de commit e títulos de Pull Request: **Inglês** (seguindo Conventional Commits).
  - Documentação inline (docstrings e comentários de código): **Inglês**.

---

## 2. Padrões de Git e Versionamento

### 2.1. Conventional Commits
Toda alteração comitada deve seguir o padrão: `<tipo>(<escopo opcional>): <descrição no imperativo>`:
- `feat`: Nova funcionalidade para o usuário ou sistema.
- `fix`: Correção de bug.
- `refactor`: Mudança interna de código sem alteração de comportamento externo nem adição de testes.
- `test`: Adição ou ajuste de testes automatizados.
- `chore`: Atualização de dependências, tarefas de build ou configurações de infraestrutura.
- `docs`: Alterações exclusivamente em documentação.

*Exemplo*: `feat(auth): add jwt token refresh handler`

### 2.2. Estrutura de Branches
- `feature/<nome-curto>`: Novas funcionalidades.
- `fix/<nome-curto>`: Correção de defeitos.
- `refactor/<nome-curto>`: Melhorias arquiteturais e refatoração.

### 2.3. Resumo de Alterações
Ao concluir alterações significativas, forneça um checklist das modificações feitas e verifique sempre o `git status` / `git diff` antes de finalizar.

---

## 3. Qualidade de Código e Engenharia

### 3.1. Testes Obrigatórios e TDD
- **Nenhuma entrega sem testes**: Qualquer código novo ou correção de bug deve ser acompanhada de testes automatizados (unitários, integração ou e2e conforme o escopo).
- **Cobertura de Bordas**: Além do caminho feliz (*happy path*), sempre inclua cenários com valores nulos/indefinidos, erros de rede, payloads inválidos e timeouts.
- **Validação Local**: Sempre execute a suíte de testes antes de considerar a tarefa finalizada.

### 3.2. Clean Code e SOLID
- **Single Responsibility**: Funções e módulos devem ter uma única responsabilidade bem delimitada.
- **Simplicidade (KISS & YAGNI)**: Não implemente abstrações desnecessárias para cenários hipotéticos futuros.
- **Imutabilidade e Funções Puras**: Priorize dados imutáveis e funções sem efeitos colaterais sempre que aplicável.
- **Tratamento Explícito de Erros**: Nunca capture erros silenciosamente (`catch {}` vazio). Sempre registre ou propague o erro adequadamente.

---

## 4. Segurança e Proteção de Segredos

- **Zero Credenciais em Repositório**: Jamais escreva senhas, tokens de API, chaves privadas ou strings de conexão diretamente no código.
- **Arquivos Protegidos**: Arquivos `.env`, `.env.*.local`, `*.pem`, `id_rsa` e similares nunca devem ser versionados.
- **Validação de Inputs**: Sempre valide entradas de usuários e requisições externas para evitar injeções (SQL, Command Injection, XSS).

---

## 5. Protocolo de Resposta do Agente

Ao responder a uma solicitação de implementação ou depuração, o agente deve:
1. **Contexto e Causa-Raiz**: Explicar brevemente o diagnóstico ou o que foi planejado.
2. **Arquivos Afetados**: Listar com links clicáveis todos os arquivos alterados ou criados.
3. **Validação Executada**: Mostrar o resultado dos testes ou comandos de validação rodados.
4. **Próximos Passos**: Recomendar os próximos passos ou pontos de atenção.
