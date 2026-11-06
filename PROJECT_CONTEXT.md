# Contexto Canônico do Projeto (`PROJECT_CONTEXT.md`)

## 🛠️ Stack Tecnológica & Dependências
- Definida no manifesto do projeto (consulte `package.json` / `pyproject.toml`).
- **Invariante**: Proibido adicionar ou supor dependências externas sem aprovação explícita.

## 📂 Estrutura Canônica de Diretórios
- `src/`: Código-fonte de produção.
- `tests/`: Suíte de testes automatizados (`tests/core/` para testes de base e `tests/features/` para novas features TDD).
- `docs/`: Documentação técnica viva e decisões consolidadas (`docs/ARCHITECTURE.md`).

## 📍 Estado Atual da Arquitetura & Entregas (Auto-Sync)
- **Última Atualização**: 2026-11-06 01:10
- **Branch Ativa**: `feature/issue-14-plan-feature-uiux-state`
- **Último Commit**: `0ac35ef - feat(uiux): upgrade uiux-designer agent with Figma-less mockup-as-code protocol (#16) (Vítor Jacom)`
- **Resumo de Alterações Recentes**:
```text
.gitignore                                  |  2 +
 PROJECT_CONTEXT.md                          | 11 +++--
 agents/uiux-designer/agent.md               | 62 ++++++++++++++++++++++++-----
 docs/ARCHITECTURE.md                        | 15 +++++++
 tests/features/test_uiux_mockup_protocol.sh | 61 ++++++++++++++++++++++++++++
 5 files changed, 136 insertions(+), 15 deletions(-)
```

## 🛑 Regras e Invariantes Estritas (Anti-Alucinação)
1. **Grounding Mandatório**: Não invente diretórios ou convenções de nomenclatura fora do padrão declarado acima.
2. **Duplo Gate**: Nenhuma alteração é comitada sem passar pela auditoria de conformidade do Gatekeeper.
