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

## 5. Eficiência de Contexto e Busca Cirúrgica (Anti-Token Waste)

- **Princípio Search-First (CodeSearch)**:
  - **Proibido varrer o repositório cegamente**: Jamais execute comandos recursivos de dump (`find .`, `ls -R`, ou leitura sequencial de pastas inteiras) no início de uma sessão ou novo chat.
  - O agente deve se orientar primariamente pelo arquivo canônico `PROJECT_CONTEXT.md` presente na raiz do projeto, que resume a arquitetura, stack e o estado atual.
  - Para localizar trechos de código, definições de tipos, rotas ou funções, realize **buscas cirúrgicas** direcionadas por termos/símbolos em vez de ler arquivos inteiros.
- **Leitura Delimitada e Paginada**:
  - Ao inspecionar arquivos grandes, restrinja o escopo utilizando intervalos específicos de linhas (`StartLine` e `EndLine`), evitando carregar blocos desnecessários na janela de contexto.
- **Delegação para Subagente de Pesquisa (`research`)**:
  - Quando a tarefa exigir uma investigação profunda ou leitura extensiva de múltiplos módulos para entender a arquitetura, delegue a exploração ao subagente `research` para isolar a contaminação da janela de contexto principal e retornar apenas uma síntese objetiva.

---

## 6. Blindagem Contra Alucinação e Grounding Mandatório (Duplo Gate)

### 6.1. Gate 1: Princípio da Verificação Antes da Suposição
- **Zero Alucinação de Padrões e Regras**: É expressamente PROIBIDO ao agente assumir ou inventar:
  - Estruturas de pastas que divirjam das convenções canônicas declaradas no `PROJECT_CONTEXT.md`.
  - Bibliotecas, frameworks ou dependências que não constem no manifesto do projeto (`package.json`, `pyproject.toml`, etc.).
  - Esquemas de arquivos (Markdown, JSON, YAML) inventados ad-hoc. Toda documentação ou artefato deve seguir a estrutura canônica existente no projeto.
- **Regra de Parada e Confirmação**: Se um padrão arquitetural, esquema de dados ou convenção de arquivo não estiver explicitamente evidente no `PROJECT_CONTEXT.md` ou na base de código, o agente DEVE verificar os arquivos de especificação ou solicitar clarificação ao desenvolvedor antes de criar artefatos.

### 6.2. Gate 2: Auditoria de Conformidade no Gatekeeper
- Antes de qualquer entrega, Pull Request ou commit ser finalizado, o subagente `gatekeeper` deve auditar o `git diff` contra os padrões canônicos estabelecidos em `PROJECT_CONTEXT.md`. Qualquer desvio estrutural ou arquivo criado fora de padrão resultará no bloqueio imediato da entrega.

---

## 6. Protocolo de Resposta do Agente

Ao responder a uma solicitação de implementação ou depuração, o agente deve:
1. **Contexto e Causa-Raiz**: Explicar brevemente o diagnóstico ou o que foi planejado.
2. **Arquivos Afetados**: Listar com links clicáveis todos os arquivos alterados ou criados.
3. **Validação Executada**: Mostrar o resultado dos testes ou comandos de validação rodados.
4. **Próximos Passos**: Recomendar os próximos passos ou pontos de atenção.

### 6.1. Protocolo Pós-Learn (Globalização de Regras)
- Sempre que um ciclo de comando `/learn` for concluído com sucesso em qualquer projeto:
  - O agente deve **obrigatoriamente perguntar** ao desenvolvedor ao final da resposta:
    > *"Deseja abrir uma task de melhoria no repositório central `VitorJacom/my-agents` para persistir e padronizar essa regra globalmente?"*
  - Se o usuário confirmar ("sim", "pode criar", etc.), o agente deve acionar a skill [`publish-rule-issue`](file:///home/vitor/Projetos/03-pessoal/my-agents/skills/publish-rule-issue/SKILL.md) e registrar a Issue estruturada no GitHub via `gh issue create`.

---

## 7. Diretrizes de Execução Multiagente

### 6.1. Proibição de Emulação Monolítica
- Quando um fluxo ou tarefa exigir o envolvimento de múltiplos papéis especializados (ex: Arquiteto, QA, Coder, Auditor):
  - **NUNCA** simule o diálogo ou as ações das personas dentro de uma única sessão principal monolítica.
  - **SEMPRE** instancie os subagentes correspondentes usando a ferramenta `invoke_subagent` com seu respectivo `Role` e `Prompt` específico.
  - O agente pai atua exclusivamente como **orquestrador**, aguardando as respostas e validando os critérios de transição de estado antes de disparar o próximo subagente.

### 6.2. Confinamento de Permissões em Agentes
- Para criar subagentes restritos (somente-leitura ou restritos de escrita):
  - Declare explicitamente apenas as tools necessárias na chave `tools:` do frontmatter (ex.: `[read_file, search_web]` para agentes somente-leitura).
  - Nunca declare ferramentas de execução (`run_command`, `write_file`) em agentes que devem ser estritamente passivos ou de auditoria.
