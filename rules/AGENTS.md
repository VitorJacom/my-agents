# Diretrizes de Governança e Engenharia para Agentes (Manifesto AIDD)

Este documento estabelece os padrões e comportamentos mandatórios que qualquer agente de desenvolvimento de IA deve seguir ao atuar neste e em outros projetos.

---

## 🏛️ Os 4 Valores do Manifesto AIDD (AI-Driven Development)

1. **Método sobre o Modelo (Method over Model)**: O processo, o sandboxing, as travas de Git e a máquina de estados determinística importam mais do que qual LLM está sendo executado.
2. **Responsabilidade sobre Delegação (Ownership over Delegation)**: A IA acelera e gera, mas os contratos determinísticos e você garantem as regras inegociáveis.
3. **Compreensão sobre Aceitação (Understanding over Acceptance)**: Não se aceita código por presunção; aceita-se por testes determinísticos executados com evidências irrefutáveis no `walkthrough.md`.
4. **Resultado sobre Volume (Outcome over Output)**: Gerar 10.000 linhas ou queimar milhões de tokens é desperdício; o que vale é a issue atômica resolvida com CI verde.

---

## 🔺 1. O Triângulo de Arquivos de Ciclo de Vida Efêmero (Raiz do Projeto)

O agente **não conversa em texto corrido para gerenciar estado**; ele é obrigado a persistir e transitar estado por meio de três arquivos padronizados.
> [!IMPORTANT]
> **Natureza Efêmera e Publicação no PR**: `task.md`, `implementation_plan.md` e `walkthrough.md` são ferramentas de trabalho locais e **devem estar no `.gitignore`**. Eles não poluem a branch `main`. A persistência histórica do `walkthrough.md` é feita pelo `gatekeeper` diretamente no corpo oficial do Pull Request no GitHub (`gh pr create --body-file walkthrough.md`).

### 1.1. `task.md` (A Memória e Semáforo da Tarefa Ativa)
- O estado de execução vive exclusivamente aqui, com marcações rígidas:
  - `[ ]`: Tarefa pendente.
  - `[/]`: Tarefa em progresso.
  - `[x]`: Tarefa concluída com testes verdes.
- **Regra de Semáforo Inviolável**: **Apenas UMA tarefa pode estar em `[/]` por vez**. O agente é estritamente proibido de iniciar a tarefa seguinte enquanto a atual não estiver com testes passando e carimbada com `[x]`.

### 1.2. `implementation_plan.md` (O Contrato Técnico Preliminar)
- Especifica com precisão cirúrgica quais arquivos serão tocados em `src/`, quais funções/interfaces serão criadas e quais testes serão exigidos em `tests/features/`.
- **Interface Contract Padronizado Obrigatório**: Deve conter obrigatoriamente a seção `## Interface Contract` congelada (Signatures, Types & Interfaces, Inputs, Outputs, Errors) com assinaturas tipadas. Planos sem essa seção ou com interfaces técnicas ambíguas são sumariamente rejeitados na etapa de Planning.
- **Nenhum código de produção em `src/` pode ser gerado antes de esse plano existir e ser aprovado.**

### 1.3. `walkthrough.md` (O Relatório de Provas Determinísticas)
- É a substituição da inspeção manual no VS Code e a descrição oficial do Pull Request.
- Contém a prova irrefutável de cumprimento da tarefa: comando exato executado (ex.: `pytest`, `npx vitest run`), logs de 100% de sucesso, saída de `git status --short` e diff dos arquivos modificados. Se o relatório estiver verde e sem desvios, o merge pode ser feito com segurança.
- **Vinculação e Auto-Close de Issues (Closing Keywords em Texto Puro)**: O relatório DEVE referenciar explicitamente a Issue resolvida utilizando palavras-chave de fechamento suportadas pelo GitHub (`Fixes #<id>`, `Closes #<id>` ou `Resolves #<id>`) estritamente em **texto puro (plain text)**. É expressamente proibido envolver a closing keyword em crases inline (como `` `Fixes #123` ``) ou em blocos de código, pois o parser nativo do GitHub desativa o fechamento automático (auto-close) quando a keyword está formatada como código.
- **Provas Demonstrativas Universais Mandatórias**: Nenhuma entrega é isenta de comprovação comprobatória real. O relatório DEVE conter evidências demonstrativas adequadas à natureza da tarefa:
  - **UIs e Front-end (Web, Mobile, Jogos 2D/3D ou UIs ricas de terminal)**: Testes unitários lógicos 100% verdes NÃO são suficientes. O relatório DEVE conter evidências visuais irrefutáveis (screenshot gerado via navegador headless como `chromium --headless`, logs de renderização do canvas ou prova gráfica visual), prevenindo interfaces quebradas, textos ilegíveis ou paletas sem contraste de luminância.
  - **Backend, CLI, Scripts e Infraestrutura**: Tarefas puramente backend, CLI ou de infraestrutura NÃO são isentas de provas demonstrativas; o relatório DEVE conter evidências demonstrativas reais de execução (saída CLI formatada, snapshots de terminal ou logs estruturados), comprovando a integridade dos fluxos e discriminando cenários de Happy Path e Edge Cases / Failure Modes.

### 1.4. Tolerância Zero a Falsos Positivos em Automações (Fail-Fast Mandatório)
- Scripts de automação, workflows de CI/CD, hooks e steps em bash NUNCA devem mascarar falhas de operações dependentes com `exit 0` (ex.: capturar erro de clone, push ou rede e sair com sucesso informativo).
- Todo script de automação deve iniciar com `set -euo pipefail`.
- Se uma dependência externa falhar (ex: clone da Wiki, API fora do ar, build ausente), o script DEVE emitir erro explícito e encerrar com `exit 1` (usando anotações `::error::` no GitHub Actions), garantindo que o pipeline fique vermelho (RED) imediatamente.

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

### 2.4. Cobertura Mínima Mandatória (Code Coverage >= 85%)
- O Code Coverage da aplicação e dos módulos sob teste deve ser estritamente superior ou igual a **85%** (linhas, statements, funções e branches).
- A suíte de testes deve emitir relatório determinístico de cobertura aferida.
- **Fail-Fast / Circuit-Breaker**: Se a cobertura for inferior a 85% (cobertura < 85%), a esteira falha imediatamente; o Gatekeeper e a automação de CI bloqueiam e rejeitam a entrega sem prosseguir para merge ou release.

### 2.5. Discriminação Mandatória de Casos de Teste (Happy Path e Edge Cases / Failure Modes)
- As suítes de testes em `tests/features/` devem categorizar e estruturar explicitamente seus testes em:
  - **Happy Path**: Fluxos principais de sucesso e atendimento aos requisitos funcionais.
  - **Edge Cases & Failure Modes**: Casos de borda, entradas inválidas, limites numéricos, timeouts, falhas de infraestrutura e comportamento resiliente do sistema.
- Entregas desprovidas de cobertura de cenários de borda ou com testes exclusivamente tautológicos são sumariamente rejeitadas.

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

### 5.1. Princípio da Neutralidade de Domínio em Plugins Globais
- Em plugins globais (como `my-agents`), é estritamente proibido criar regras globais em `rules/` contendo convenções específicas de um único nicho (ex: física de jogos 2D, frameworks específicos de frontend ou ORMs particulares).
- **Regras de Nicho pertencem a Skills (`skills/`)**: Devem ser modularizadas como Skills acionadas por *Progressive Disclosure*, garantindo Zero Token Waste em projetos que operam em outros domínios.

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

### 7.4. Mandato de Delegação no Modo Maestro (Batch Execution)
- **Segregação Estrita de Planos (Control Plane vs Execution Plane)**: No processamento concorrente ou em lote de múltiplas issues (`/run-issue #A #B ...` ou `--epic`), a sessão principal opera estritamente como Maestro / Control Plane.
- **Delegação Mandatória via `invoke_subagent`**: Todas as issues pertencentes a uma onda de execução (Execution Wave / batch) DEVEM ser despachadas para instâncias desacopladas de subagentes workers via `invoke_subagent`.
- **Isolamento Físico e Confinamento em Worktree**: Cada worker opera confinado exclusivamente no diretório estéril de sua worktree `.worktrees/issue-<id>`, garantindo isolamento estrito sem interferir no workspace raiz ou em outras worktrees simultâneas.
- **Proibição Expressa de Execução Inline**: É expressamente proibido ao Maestro codificar ou executar TDD diretamente, rodar testes diretamente, inspecionar árvores de código detalhadas ou editar arquivos na raiz durante execuções em lote.
- **Circunscrição de Responsabilidades do Maestro**: A atuação do Maestro no Control Plane resume-se a: (a) Análise pre-flight e partição de ondas; (b) Criação da branch intermediária e provisionamento de worktrees; (c) Despacho dos subagentes workers; (d) Gestão da Merge Queue sequencial e auto-reconciliação; (e) Acionamento do Gatekeeper final para PR consolidado.

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

---

## 9. Governança do Ciclo de Vida de Issues e Rastreamento no GitHub

Para repositórios governados pelo ecossistema AIDD e integrados ao GitHub Projects v2:

### 9.1. Épicos Temáticos via Milestones
- **Épicos (Epics) representados por Milestone**: Milestones não representam sprints temporais com datas de encerramento rígidas, mas sim grandes temas/épicos canônicos (ex.: `"Epic: AIDD Core & Engineering Governance"`, `"Epic: UI/UX Design System & Living Mockups"`). Toda issue criada ou refinada deve ser associada ao seu Épico (Milestone) correspondente.

### 9.2. Gestão de Versões e Entregas via Campo Release no GitHub Project v2
- **Campo Release no GitHub Project / Project v2**: O ciclo de versão e entrega é desacoplado do Épico e gerenciado pelo campo Single Select `Release` no GitHub Project v2 (valores típicos: `v1.0.0`, `v1.1.0`, `v1.2.0`, `Backlog / Future`). Ao adicionar ou triar itens no projeto, o campo `Release` deve ser preenchido via CLI ou automação de reconciliação.

### 9.3. Sub-issues Nativas e Fatiamento Hierárquico
- **Vinculação Hierárquica com `--parent`**: Quando uma issue for desdobrada em sub-tarefas atômicas ou vinculada a uma issue mãe/épico, deve ser utilizada a flag nativa do GitHub CLI `--parent <id>` (`gh issue create --parent <id>`).

### 9.4. Refinamento In-place e Reorganização de Backlog
- **Atualização sem Duplicação**: Durante o planejamento ou reavaliação de prioridades, deve-se priorizar o refinamento in-place e reorganização de issues já existentes no backlog via `gh issue edit` (ajustando títulos, corpos, milestones ou campos de projeto), evitando a criação de issues redundantes ou duplicadas.

### 9.5. Vinculação e Auto-Close de Issues em Pull Requests (Plain-Text Closing Keywords)
- **Palavras-Chave Canônicas em Texto Puro**: Toda entrega que encerra uma issue deve declarar no corpo do PR (`walkthrough.md`) a diretiva de fechamento oficial do GitHub (`Fixes #<id>`, `Closes #<id>` ou `Resolves #<id>`) estritamente em texto puro (plain text).
- **Proibição de Crases / Blocos de Código em Keywords**: O parser do GitHub desativa o fechamento automático (auto-close) se a diretiva estiver contida entre crases inline (como `` `Fixes #123` ``) ou dentro de blocos de código. A declaração da palavra-chave de fechamento sem crases em texto puro é mandatória para garantir que o fechamento ocorra automaticamente no merge para a branch padrão.


