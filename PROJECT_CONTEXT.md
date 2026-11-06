# Contexto Canônico do Projeto (`PROJECT_CONTEXT.md`)

## 🛠️ Stack Tecnológica & Dependências
- Definida no manifesto do projeto (consulte `package.json` / `pyproject.toml`).
- **Invariante**: Proibido adicionar ou supor dependências externas sem aprovação explícita.

## 📂 Estrutura Canônica de Diretórios
- `src/`: Código-fonte de produção.
- `tests/`: Suíte de testes automatizados (`tests/core/` para testes de base e `tests/features/` para novas features TDD).
- `docs/`: Documentação técnica viva e decisões consolidadas (`docs/ARCHITECTURE.md`).

## 🛑 Regras e Invariantes Estritas (Anti-Alucinação)
1. **Grounding Mandatório**: Não invente diretórios ou convenções de nomenclatura fora do padrão declarado acima.
2. **Duplo Gate**: Nenhuma alteração é comitada sem passar pela auditoria de conformidade do Gatekeeper.
