---
name: publish-rule-issue
description: >-
  Publica uma Issue estruturada no repositório central VitorJacom/my-agents contendo o contexto,
  causa-raiz e proposta de regra aprendida via /learn em qualquer projeto.
---

# Publish Rule Issue (`/publish-rule-issue`)

Esta Skill permite registrar um aprendizado, regra comportamental ou melhoria de esteira diretamente no repositório canônico central `VitorJacom/my-agents` a partir de qualquer workspace em que você estiver trabalhando.

---

## 🎯 Quando Acionar
- **Pós-Learn**: Logo após concluir um ciclo de `/learn` no projeto atual, quando o usuário confirmar o desejo de globalizar a regra no repositório central.
- **Sob Demanda**: Quando o usuário solicitar expressamente (ex.: *"cria uma issue de regra no my-agents sobre isso"* ou `/publish-rule-issue`).

---

## 🔄 Procedimento de Execução

1. **Coleta de Evidências da Sessão Atual**:
   - Inspecione a última proposta de aprendizado gerada (verifique se existe `learning_proposal.md` no diretório de artefatos da conversa ou nos passos recentes).
   - Identifique:
     - **Projeto de Origem**: Nome da pasta do workspace atual (ex.: `znapzap-backend`, `jax`, etc.).
     - **Problema / Gatilho**: Qual ação do agente ou do usuário motivou a regra.
     - **Causa-Raiz**: Por que o comportamento inadequado ocorreu.
     - **Regra Proposta / Diff**: O texto exato da regra ou instrução aprovada.

2. **Formatação do Corpo da Issue**:
   Crie o conteúdo markdown estruturado no seguinte padrão:

   ```markdown
   ## 📌 Contexto de Origem
   - **Projeto de Origem**: `<nome_do_projeto>`
   - **Gatilho / Situação**: <descrição concisa do que ocorreu>

   ## 🔍 Causa-Raiz & Racional Técnico
   <explicação fundamentada do porquê a regra é necessária>

   ## 📝 Regra Proposta / Aprendizado
   ```markdown
   <texto ou diff da regra>
   ```

   ## 🎯 Escopo Recomendado no my-agents
   - [x] Regra Comportamental (`rules/AGENTS.md`)
   - [ ] Nova Skill especializada (`skills/`)
   - [ ] Validação / Hook de integridade (`hooks.json`)

   ## Target Files & Dependencies
   - Target Files: <caminho_dos_arquivos_afetados_no_my_agents>
   - Depends On: None

   ## Passos de Implementação (<= 3 passos)
   1. Criar suíte de testes TDD em `tests/features/` cobrindo o novo comportamento ou regra.
   2. Implementar a regra ou skill em `rules/AGENTS.md` ou `skills/`.
   3. Executar os testes automatizados para garantir estado GREEN e comitar via conventional commits.
   ```

3. **Criação da Issue no GitHub via `gh CLI`**:
   - Inspecione a seção `## 🎯 Rastreamento & GitHub Governance` em `PROJECT_CONTEXT.md`:
     - Se `Active Milestone` estiver configurada e for diferente de `None` (ex.: `"v1.1.0"`), anexe `--milestone "<milestone>"` dinamicamente ao comando `gh issue create`.
     - Se `Active Milestone` estiver ausente, vazia ou definida como `None`, omita a flag `--milestone`.
   - Execute o comando determinístico:
   ```bash
   gh issue create \
     --repo VitorJacom/my-agents \
     --title "feat(rules): <título conciso no imperativo em inglês>" \
     --label "enhancement,planned" \
     [--milestone "<milestone>"] \
     --body "<corpo_markdown_formatado>"
   ```

4. **Vinculação a GitHub Project v2 (Fallback Resiliente)**:
   - Se `GitHub Project v2` estiver configurado em `PROJECT_CONTEXT.md` com `Owner` e `Project Number` válidos (diferentes de `None`), vincule a issue criada ao quadro do projeto utilizando fallback resiliente não-bloqueante:
   ```bash
   gh project item-add "<project_number>" --owner "<owner>" --url "<issue_url>" || echo "⚠️ [WARN] Falha não-bloqueante ao adicionar issue ao GitHub Project v2 (<project_number>). Prosseguindo esteira."
   ```

5. **Retorno ao Desenvolvedor**:
   - Apresente o link da Issue criada no GitHub.
   - Destaque que a Issue já está formatada com contratos atômicos (`Target Files & Dependencies` e `Passos de Implementação`) e pronta para ser executada na esteira `/run-issue` quando o repositório central for aberto.
