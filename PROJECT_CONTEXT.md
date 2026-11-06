# Contexto Canônico do Projeto (`PROJECT_CONTEXT.md`)

## 🛠️ Stack Tecnológica & Dependências
- Definida no manifesto do projeto (consulte `package.json` / `pyproject.toml`).
- **Invariante**: Proibido adicionar ou supor dependências externas sem aprovação explícita.

## 📂 Estrutura Canônica de Diretórios
- `src/`: Código-fonte de produção.
- `tests/`: Suíte de testes automatizados (`tests/core/` para testes de base e `tests/features/` para novas features TDD).
- `docs/`: Documentação técnica viva e decisões consolidadas (`docs/ARCHITECTURE.md`).

## 📍 Estado Atual da Arquitetura & Entregas (Auto-Sync)
- **Última Atualização**: 2026-11-06 01:22
- **Branch Ativa**: `feature/issue-15-issue-pipeline-uiux-gate`
- **Último Commit**: `a2ab8df - feat(plan-feature): integrate uiux-designer and mockup stage into planning state machine (#18) (Vítor Jacom)`
- **Resumo de Alterações Recentes**:
```text
PROJECT_CONTEXT.md                             | 14 +++--
 agents/system-architect/agent.md               | 14 +++--
 skills/plan-feature/SKILL.md                   | 76 ++++++++++++++------------
 tests/features/test_plan_feature_uiux_state.sh | 59 ++++++++++++++++++++
 4 files changed, 117 insertions(+), 46 deletions(-)
```

## 🛑 Regras e Invariantes Estritas (Anti-Alucinação)
1. **Grounding Mandatório**: Não invente diretórios ou convenções de nomenclatura fora do padrão declarado acima.
2. **Duplo Gate**: Nenhuma alteração é comitada sem passar pela auditoria de conformidade do Gatekeeper.
