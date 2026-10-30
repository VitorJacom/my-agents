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
   ```

3. **Criação da Issue no GitHub via `gh CLI`**:
   Execute o comando determinístico:
   ```bash
   gh issue create \
     --repo VitorJacom/my-agents \
     --title "feat(rules): <título conciso no imperativo em inglês>" \
     --label "enhancement" \
     --body "<corpo_markdown_formatado>"
   ```

4. **Retorno ao Desenvolvedor**:
   - Apresente o link da Issue criada no GitHub.
   - Destaque que a Issue já está pronta para ser executada na esteira `/run-issue` quando o repositório central for aberto.
