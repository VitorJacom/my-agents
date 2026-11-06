# Contexto Canônico do Projeto (`PROJECT_CONTEXT.md`)

## 🛠️ Stack Tecnológica & Dependências
- Definida no manifesto do projeto (consulte `package.json` / `pyproject.toml`).
- **Invariante**: Proibido adicionar ou supor dependências externas sem aprovação explícita.

## 📂 Estrutura Canônica de Diretórios
- `src/`: Código-fonte de produção.
- `tests/`: Suíte de testes automatizados (`tests/core/` para testes de base e `tests/features/` para novas features TDD).
- `docs/`: Documentação técnica viva e decisões consolidadas (`docs/ARCHITECTURE.md`).

## 📍 Estado Atual da Arquitetura & Entregas (Auto-Sync)
- **Última Atualização**: 2026-11-06 01:52
- **Branch Ativa**: `feature/issue-12-coverage-happy-edge-and-ui-proof`
- **Último Commit**: `26f6394 - feat(issue-pipeline): enforce uiux-designer visual contract and audit gate in /run-issue (#23) (Vítor Jacom)`
- **Resumo de Alterações Recentes**:
```text
PROJECT_CONTEXT.md                              | 17 +++---
 agents/coder/agent.md                           |  9 +++-
 agents/gatekeeper/agent.md                      | 13 +++--
 agents/planner/agent.md                         | 11 +++-
 docs/ARCHITECTURE.md                            | 49 ++++++++++++++++-
 skills/issue-pipeline/SKILL.md                  | 54 +++++++++++++++++--
 tests/features/
```

## 🛑 Regras e Invariantes Estritas (Anti-Alucinação)
1. **Grounding Mandatório**: Não invente diretórios ou convenções de nomenclatura fora do padrão declarado acima.
2. **Duplo Gate**: Nenhuma alteração é comitada sem passar pela auditoria de conformidade do Gatekeeper.
