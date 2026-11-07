# Guia de Troubleshooting & Resolução de Problemas

Este guia consolida a matriz diagnóstica, as causas-raiz e as soluções determinísticas para incidentes comuns encontrados durante a execução de agentes, pipelines de CI/CD e rotinas operacionais no ecossistema `my-agents`.

---

## 🧭 Matriz Diagnóstica Rápida

| Sintoma / Mensagem de Erro | Componente Impactado | Causa-Raiz Provável | Procedimento |
| :--- | :--- | :--- | :--- |
| `Lock file .worktrees/.lock-<id> already exists` | Worktree Manager | Processo anterior abortado sem cleanup ou concorrência indevida | [Seção 1](#1-conflitos-de-lock-e-gerenciamento-de-worktrees) |
| `Resource not accessible by integration (gh project)` | GitHub CLI / Actions | Falta do escopo `project` no token de autenticação | [Seção 2](#2-permissões-de-token-no-github-actions-e-github-cli) |
| `ALERTA DE FRAUDE: O agente modificou arquivos protegidos em tests/core/!` | Trava Anti-Fraude | Subagente tentou editar ou deletar testes históricos fundamentais | [Seção 3](#3-falhas-na-trava-anti-fraude-e-circuit-breakers) |
| `Circuit-Breaker: Code Coverage < 85%` | Gatekeeper / CI | Suíte de testes não atinge o limiar mínimo de 85% de cobertura | [Seção 3.2](#32-cobertura-de-código-inferior-a-85) |
| `Statusline latency exceeded: > 50ms` | Statusline Quota | Chamadas externas síncronas ou ausência do utilitário `jq` | [Seção 4](#4-latência-cache-e-falhas-na-statusline) |
| Conflito de tipagem / assinaturas no Join Point | QA & Coder Fork/Join | Divergência em relação ao `Interface Contract` congelado | [Seção 5](#5-divergências-no-interface-contract-forkjoin) |
| `remote: GitHub Wiki is not initialized` | Wiki Sync Workflow | A aba Wiki do GitHub nunca foi criada na interface web | [Seção 6](#6-sincronização-da-github-wiki-wiki-syncyml) |
| Colisão de arquivos na mesma Execution Wave | Maestro Orchestrator | Duas issues simultâneas compartilham `Target Files` | [Seção 7](#7-concorrência-do-maestro-e-colisão-de-target-files) |

---

## 🔧 1. Conflitos de Lock e Gerenciamento de Worktrees

### Sintoma
Ao iniciar a execução de uma issue via `/run-issue` ou `./scripts/pipeline/worktree-manager.sh create <id>`, o comando falha reportando que o lock atômico já existe:
```text
[ERROR] Worktree issue-26 already locked by .worktrees/.lock-26
```

### Causa-Raiz
1. Um agente anterior foi interrompido abruptamente (ex: cancelamento da sessão ou reinício da IDE) antes de invocar o comando de cleanup.
2. Dois workers tentaram inicializar o mesmo identificador de issue concomitantemente.

### Solução Determinística
1. Inspecione as worktrees ativas e verifique se há processos pendentes:
   ```bash
   ./scripts/pipeline/worktree-manager.sh list
   git worktree list
   ```
2. Caso a sessão anterior tenha sido finalizada e o lock esteja órfão (stale), execute a remoção forçada:
   ```bash
   ./scripts/pipeline/worktree-manager.sh remove <id>
   ```
3. Se restarem referências pendentes no Git interno, execute o prune:
   ```bash
   git worktree prune
   ```

---

## 🔑 2. Permissões de Token no GitHub Actions e GitHub CLI

### Sintoma
Durante a criação de issues no `/plan-feature` ou transição de status no `/run-issue`, surgem erros como:
```text
GraphQL: Resource not accessible by integration (addProjectV2ItemById)
```

### Causa-Raiz
O token do GitHub CLI (`GITHUB_TOKEN` padrão no Actions ou token pessoal `gh auth login`) carece de permissão de escrita no GitHub Projects v2 (escopos `project` ou `write:org`).

### Solução Determinística
1. **Degradação Graciosa (Princípio Não-Bloqueante)**:
   - Os scripts do `my-agents` são projetados com fallback defensivo. Falhas na API do GitHub Projects v2 emitem avisos informativos (`[WARN]`), mas **não abortam** a entrega de código ou abertura de Pull Requests.
2. **Correção do Personal Access Token (Desenvolvimento Local)**:
   ```bash
   gh auth refresh -s project,repo,read:org
   ```
3. **Correção no GitHub Actions Workflows**:
   No arquivo `.github/workflows/*.yml`, declare os blocos explícitos de permissões mínimas:
   ```yaml
   permissions:
     contents: write
     pull-requests: write
     issues: write
     repository-projects: write
   ```

---

## 🛡️ 3. Falhas na Trava Anti-Fraude e Circuit-Breakers

### 3.1. Violação da Zona Intocável (`tests/core/`)
- **Sintoma**:
  ```text
  ALERTA DE FRAUDE: O agente modificou arquivos protegidos em tests/core/!
  tests/core/test_business_invariants.sh
  ```
- **Causa-Raiz**: O subagente modificou testes legados para forçar a suíte a passar em vez de ajustar a implementação em `src/`.
- **Solução Determinística**:
  1. Reverter imediatamente quaisquer mudanças em `tests/core/`:
     ```bash
     git checkout origin/main -- tests/core/
     ```
  2. Ajustar o código em `src/` para honrar os contratos históricos.
  3. Novos testes devem residir estritamente em `tests/features/`.

### 3.2. Cobertura de Código Inferior a 85%
- **Sintoma**: O Gatekeeper ou CI rejeita o commit com erro de cobertura insuficiente:
  ```text
  [FAIL] Cobertura aferida: 78.4% (mínimo obrigatório: 85.0%)
  ```
- **Solução Determinística**:
  1. Identificar funções, statements ou branches não exercitadas via relatório de cobertura (ex: `coverage report -m` ou `nyc report`).
  2. Adicionar testes de aceitação em `tests/features/` cobrindo os caminhos não testados.
  3. Revalidar antes da submissão:
     ```bash
     pytest --cov=src --cov-fail-under=85
     ```

### 3.3. Ausência de Casos de Borda (Edge Cases / Failure Modes)
- **Sintoma**: O Gatekeeper bloqueia o PR por conter apenas asserções de Happy Path.
- **Solução Determinística**: Estruture a suíte em `tests/features/` com seções e asserções explícitas cobrindo entradas inválidas, limites de dados, timeouts e recuperação graciosa.

---

## ⚡ 4. Latência, Cache e Falhas na Statusline

### Sintoma
A statusline personalizada (`scripts/statusline/statusline-quota.sh`) demora para responder, causa lentidão visível no terminal ou o benchmark automatizado falha:
```text
[FAIL] Benchmark: 82ms (teto máximo permitido: 50ms)
```

### Causa-Raiz
1. Inclusão de chamadas externas de rede (`curl`, `git fetch`) de forma síncrona a cada renderização da statusline.
2. Subprocessos repetidos ou ausência de cache local para dados estáticos.
3. Utilitário `jq` ausente no ambiente hospedeiro.

### Solução Determinística
1. **Executar o Benchmark Automatizado**:
   ```bash
   ./scripts/statusline/test-statusline.sh
   ```
2. **Garantir Utilitários de Alta Performance**:
   Certifique-se de que `jq` está instalado (`sudo apt-get install jq`).
3. **Respeitar o Padrão Zero-Network**: A statusline deve apenas processar o payload JSON injetado via STDIN pelo Antigravity CLI e inspecionar o Git local de forma ultrarrápida (`git rev-parse --abbrev-ref HEAD`).

---

## 🔄 5. Divergências no Interface Contract (Fork/Join)

### Sintoma
Durante a etapa de Join Point do `/run-issue`, a suíte quebra com erros de assinaturas de função ou argumentos incompatíveis entre `tests/features/` e `src/`.

### Causa-Raiz
O QA Engineer e o Coder divergiram na interpretação das tipagens durante a implementação concorrente.

### Solução Determinística
1. O contrato de autoridade absoluta é a seção `## Interface Contract` do `implementation_plan.md`.
2. O orquestrador aciona um ciclo curto de alinhamento (máximo de 2 iterações):
   - Se o teste desviou do contrato: o teste em `tests/features/` é corrigido para o contrato.
   - Se a implementação desviou do contrato: o código em `src/` é corrigido para o contrato.
3. O contrato nunca é flexibilizado no meio da etapa GREEN sem atualização formal prévia no plano.

---

## 📚 6. Sincronização da GitHub Wiki (`wiki-sync.yml`)

### Sintoma
O workflow de sincronização da Wiki falha no GitHub Actions com erro de permissão ou repositório não encontrado:
```text
fatal: remote error: upload-pack: not permitted
fatal: repository 'https://github.com/owner/repo.wiki.git' not found
```

### Causa-Raiz
1. A aba Wiki nunca foi inicializada no repositório GitHub. O Git não cria o repositório remoto `.wiki.git` até que a primeira página seja salva na interface web.
2. O token do Actions não possui permissão de escrita em repositórios de documentação.

### Solução Determinística
1. **Inicialização Manual Inicial da Wiki**:
   - Acesse a aba **Settings** do repositório no GitHub.
   - Na seção **Features**, certifique-se de que a opção **Wikis** está marcada.
   - Acesse a aba **Wiki** e clique em **Create the first page** (pode ser salva com conteúdo provisório).
   - Uma vez criada a primeira página, o repositório remoto `https://github.com/<owner>/<repo>.wiki.git` passa a existir.
2. **Re-disparar o Workflow**:
   - Qualquer push subsequente na branch `main` executará a sincronização com sucesso.

---

## 🌊 7. Concorrência do Maestro e Colisão de Target Files

### Sintoma
Ao planejar ou executar um lote de issues concorrentes, o Maestro emite aviso de sobreposição e reordena a execução:
```text
[WARN] Colisão detectada: Issue #24 e Issue #27 tocam em 'src/core/router.py'.
```

### Causa-Raiz
Duas issues foram agrupadas na mesma onda de execução (*Execution Wave*), violando a regra de arquivos-alvo 100% disjuntos.

### Solução Determinística
1. No arquivo de planejamento (`planning_proposal.md`), declare explicitamente a matriz de dependências e arquivos-alvo:
   ```markdown
   - Issue #27:
     - Target Files: [src/core/router.py]
     - Depends On: [#24]
   ```
2. O Maestro escalonará automaticamente a Issue #27 para a **Wave 2**, garantindo execução sequencial sem conflito de merge.
