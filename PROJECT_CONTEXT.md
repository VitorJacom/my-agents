# Contexto Canônico do Projeto (`PROJECT_CONTEXT.md`)

## 🛠️ Stack Tecnológica & Dependências
- Definida no manifesto do projeto (consulte `package.json` / `pyproject.toml`).
- **Invariante**: Proibido adicionar ou supor dependências externas sem aprovação explícita.

## 📂 Estrutura Canônica de Diretórios
- `src/`: Código-fonte de produção.
- `tests/`: Suíte de testes automatizados (`tests/core/` para testes de base e `tests/features/` para novas features TDD).
- `docs/`: Documentação técnica e ADRs (`docs/adr/`).

## 📍 Estado Atual da Arquitetura & Entregas (Auto-Sync)
- **Última Atualização**: 2026-11-04 15:33
- **Branch Ativa**: `feature/uiux-and-gamedev-patterns`
- **Último Commit**: `9c1c85a - feat(statusline): add custom statusline renderer for Antigravity CLI with quota display (vitor jacom)`
- **Resumo de Alterações Recentes**:
```text
rules/AGENTS.md             | 19 +++++++++++--
 scripts/statusline-quota.sh | 68 +++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 85 insertions(+), 2 deletions(-)
```

## 🛑 Regras e Invariantes Estritas (Anti-Alucinação)
1. **Grounding Mandatório**: Não invente diretórios ou convenções de nomenclatura fora do padrão declarado acima.
2. **Duplo Gate**: Nenhuma alteração é comitada sem passar pela auditoria de conformidade do Gatekeeper.
