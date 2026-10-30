# Diretrizes de Governança e Engenharia para Agentes (Manifesto AIDD)

Este documento estabelece os padrões e comportamentos mandatórios que qualquer agente de desenvolvimento de IA deve seguir ao atuar neste e em outros projetos.

---

## 🏛️ Os 4 Valores do Manifesto AIDD (AI-Driven Development)

1. **Método sobre o Modelo (Method over Model)**: O processo, o sandboxing, as travas de Git e a máquina de estados determinística importam mais do que qual LLM está sendo executado.
2. **Responsabilidade sobre Delegação (Ownership over Delegation)**: A IA acelera e gera, mas os contratos determinísticos e você garantem as regras inegociáveis.
3. **Compreensão sobre Aceitação (Understanding over Acceptance)**: Não se aceita código por presunção; aceita-se por testes determinísticos executados com evidências irrefutáveis no `walkthrough.md`.
4. **Resultado sobre Volume (Outcome over Output)**: Gerar 10.000 linhas ou queimar milhões de tokens é desperdício; o que vale é a issue atômica resolvida com CI verde.

---

## 🔺 1. O Triângulo de Arquivos de Ciclo de Vida (Raiz do Projeto)

O agente **não conversa em texto corrido para gerenciar estado**; ele é obrigado a persistir e transitar estado por meio de três arquivos padronizados:

### 1.1. `task.md` (A Memória e Semáforo da Tarefa Ativa)
- O estado de execução vive exclusivamente aqui, com marcações rígidas:
  - `[ ]`: Tarefa pendente.
  - `[/]`: Tarefa em progresso.
  - `[x]`: Tarefa concluída com testes verdes.
- **Regra de Semáforo Inviolável**: **Apenas UMA tarefa pode estar em `[/]` por vez**. O agente é estritamente proibido de iniciar a tarefa seguinte enquanto a atual não estiver com testes passando e carimbada com `[x]`.

### 1.2. `implementation_plan.md` (O Contrato Técnico Preliminar)
- Especifica com precisão cirúrgica quais arquivos serão tocados em `src/`, quais funções/interfaces serão criadas e quais testes serão exigidos em `tests/features/`.
- **Nenhum código de produção em `src/` pode ser gerado antes de esse plano existir e ser aprovado.**

### 1.3. `walkthrough.md` (O Relatório de Provas Determinísticas)
- É a substituição da inspeção manual no VS Code.
- Contém a prova irrefutável de cumprimento da tarefa: comando exato executado (ex.: `pytest`, `npx vitest run`), logs de 100% de sucesso, saída de `git status --short` e diff dos arquivos modificados. Se o relatório estiver verde e sem desvios, o merge pode ser feito com segurança.

---

## 🛡️ 2. A Trava Dupla Anti-Fraude (Defesa em Profundidade)

Para impedir o "golpe do estagiário" (quando o modelo tenta alterar, comentar ou apagar testes antigos para forçar a suíte a passar):

### 2.1. Separação Canônica de Pastas de Teste
- `tests/core/`: Guarda as regras de negócio históricas e fundamentais. **Zona intocável.**
- `tests/features/`: Onde o QA cria novos testes de aceitação da issue ativa.

### 2.2. A "Golden Rule" via Bash (Gatekeeper & CI)
Antes de comitar ou abrir PR, o Gatekeeper e o CI executam a checagem determinística do Git:
```bash
MODIFIED=$(git diff --name-only origin/main...HEAD 2>/dev/null | grep -E '^tests/core/' || true)
if [ -n "$MODIFIED" ]; then
  echo "ALERTA DE FRAUDE: O agente modificou arquivos protegidos em tests/core/!"
  exit 1
fi
```
Se houver **1 caractere alterado** em `tests/core/`, a esteira é abortada imediatamente (Circuit-Breaker).

### 2.3. Anti-Triviality & Mutation Testing (Exterminador de Testes Falsos)
- Proibido testes vazios ou tautológicos (ex.: `expect(true).toBe(true)` ou `assert True`).
- O teste deve conter asserções de negócio e falhar comprovadamente no estado inicial (**RED**).
- Em auditorias estritas, ferramentas de mutação (ex: Stryker para JS/TS ou Mutmut para Python) invertem operadores; se o teste continuar passando com código mutado, o teste é considerado falso e rejeitado.

---

## 3. Comunicação e Idioma (Padrão Híbrido)

- **Interação com o Desenvolvedor**: A comunicação direta, relatórios, resumos de planos e explicações de decisões devem ser feitas em **Português (pt-BR)** de forma clara, objetiva e colaborativa.
- **Artefatos de Código e Engenharia**:
  - Código-fonte, nomes de variáveis, funções, classes, interfaces e testes: **Inglês**.
  - Mensagens de commit e títulos de Pull Request: **Inglês** (seguindo Conventional Commits).
  - Documentação inline (docstrings e comentários de código): **Inglês**.

---

## 4. Padrões de Git e Versionamento

### 4.1. Conventional Commits
Toda alteração comitada deve seguir o padrão: `<tipo>(<escopo opcional>): <descrição no imperativo>`:
- `feat`: Nova funcionalidade para o usuário ou sistema.
- `fix`: Correção de bug.
- `refactor`: Mudança interna de código sem alteração de comportamento externo nem adição de testes.
- `test`: Adição ou ajuste de testes automatizados.
- `chore`: Atualização de dependências, tarefas de build ou configurações de infraestrutura.
- `docs`: Alterações exclusivamente em documentação.

### 4.2. Estrutura de Branches
- `feature/<nome-curto>`: Novas funcionalidades.
- `fix/<nome-curto>`: Correção de defeitos.
- `refactor/<nome-curto>`: Melhorias arquiteturais e refatoração.

---

## 5. Eficiência de Contexto e Busca Cirúrgica (Anti-Token Waste)

- **Princípio Search-First**: Proibido varrer o repositório cegamente (`find .`, `ls -R`). O agente orienta-se primariamente pelo `PROJECT_CONTEXT.md` na raiz e realiza buscas cirúrgicas por símbolos.
- **Leitura Delimitada**: Utilize paginação com `StartLine` e `EndLine` para inspecionar apenas trechos necessários.
- **Delegação para `research`**: Para investigações extensivas, delegue ao subagente de pesquisa isolando a janela de contexto.

---

## 6. Blindagem Contra Alucinação e Grounding Mandatório (Duplo Gate)

### 6.1. Gate 1: Princípio da Verificação Antes da Suposição
- Proibido supor bibliotecas inexistentes no manifesto (`package.json`, etc.), inventar pastas ou desviar de `PROJECT_CONTEXT.md`.
- Na dúvida, verifique a especificação ou pare e solicite confirmação ao desenvolvedor.

### 6.2. Gate 2: Auditoria de Conformidade no Gatekeeper
- Antes de qualquer entrega, o Gatekeeper audita o `git diff` contra os padrões canônicos estabelecidos em `PROJECT_CONTEXT.md`.

---

## 7. Diretrizes de Execução Multiagente

### 7.1. Proibição de Emulação Monolítica
- Quando um fluxo exigir múltiplos papéis especializados (ex: PO, Arquiteto, QA, Coder, Gatekeeper), **NUNCA** simule o diálogo dentro de uma única sessão principal monolítica. Instancie os subagentes via `invoke_subagent`.

### 7.2. Confinamento de Permissões
- Declare apenas as tools estritamente necessárias na chave `tools:` do `agent.md`. Agentes passivos/somente-leitura nunca devem ter ferramentas de escrita ou terminal aberto.

### 7.3. Protocolo Pós-Learn (Globalização de Regras)
- Ao concluir um ciclo de `/learn`, o agente deve perguntar se deseja registrar a melhoria no repositório central `VitorJacom/my-agents` via skill `publish-rule-issue`.

---

## 8. Protocolo de Validação Isolada em Sandbox (Clean Room Testing)

Para certificar que novos plugins, esteiras, skills e regras funcionem de forma idêntica à experiência de um usuário real em um repositório externo consumidor:

### 8.1. O Princípio do Clean Room (Ambiente Estéril)
- **Proibição de Herança de Contexto**: Nunca execute testes de esteiras ou validações no sandbox dependendo do histórico acumulado na conversa principal de desenvolvimento. O agente que atua no sandbox deve operar com contexto 100% limpo.
- **Simulação Fiel de Repositório de "Verdade"**: O diretório `sandbox/` deve possuir sua própria infraestrutura de repositório consumidor: seu próprio `.git`, seu `PROJECT_CONTEXT.md` e sua pasta local `.agents/` (contendo `.agents/plugins.json` e/ou os plugins baixados em `.agents/plugins/<nome>`).

### 8.2. Isolamento de Workspace Obrigatório (`cd` no Sandbox + Nova Instância `agy`)
- Para garantir que **NENHUM** contexto, regra ou arquivo residual do projeto raiz contamine o teste:
  1. O agente é **estritamente obrigado a navegar via `cd` para dentro do diretório do sandbox** antes de disparar o comando do Antigravity CLI.
  2. Disparar uma **nova instância desacoplada do CLI** (`agy`) em modo de execução pontual:
  ```bash
  cd /caminho/do/sandbox && agy --dangerously-skip-permissions -p "<comando ou instrução a ser testada>"
  ```
- **Por que esta regra é inviolável**:
  - O Antigravity CLI descobre o workspace e a árvore de configurações a partir do diretório de trabalho atual (CWD). Ao dar `cd sandbox`, o `agy` descobre exclusivamente o `.agents/` e o `PROJECT_CONTEXT.md` do sandbox, impedindo que qualquer contexto do repositório pai vaze para a sessão.
  - A execução desacoplada via `-p` garante uma sessão efêmera e estéril, comprovando que qualquer desenvolvedor externo que clonar o projeto consumidor terá o mesmo comportamento determinístico.

