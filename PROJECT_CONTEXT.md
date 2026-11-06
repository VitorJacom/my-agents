# Contexto Canônico do Projeto (`PROJECT_CONTEXT.md`)

## 🛠️ Stack Tecnológica & Dependências
- Definida no manifesto do projeto (consulte `package.json` / `pyproject.toml`).
- **Invariante**: Proibido adicionar ou supor dependências externas sem aprovação explícita.

## 📂 Estrutura Canônica de Diretórios
- `src/`: Código-fonte de produção.
- `tests/`: Suíte de testes automatizados (`tests/core/` para testes de base e `tests/features/` para novas features TDD).
- `docs/`: Documentação técnica viva e topologia modular da GitHub Wiki sincronizada via `.github/workflows/wiki-sync.yml`:
  - `Home.md`: Hub de navegação e landing page principal da Wiki.
  - `_Sidebar.md`: Barra lateral de navegação hierárquica.
  - `_Footer.md`: Rodapé padrão institucional e metadados de governança.
  - `Getting-Started.md`: Guia de introdução, onboarding e ciclo AIDD.
  - `Subagents.md`: Catálogo dos 7 subagentes especializados e matriz RACI.
  - `Skills-Catalog.md`: Catálogo das 9 skills ativadas por Progressive Disclosure.
  - `AIDD-Manifesto.md`: Manifesto AI-Driven Development e 4 valores fundamentais.
  - `Architecture.md`: Visão arquitetural em 5 camadas concêntricas e índice de ADRs.
  - `Troubleshooting.md`: Diagnóstico de problemas, locks, tokens e circuit breakers.
  - `ARCHITECTURE.md`: Especificação técnica canônica viva e decisões consolidadas.
  - *Validação de Integridade*: Suíte determinística em `tests/features/test_wiki_structure_and_links.sh`.

## 🛑 Regras e Invariantes Estritas (Anti-Alucinação)
1. **Grounding Mandatório**: Não invente diretórios ou convenções de nomenclatura fora do padrão declarado acima.
2. **Duplo Gate**: Nenhuma alteração é comitada sem passar pela auditoria de conformidade do Gatekeeper.

## 🎯 Rastreamento & GitHub Governance
- **Active Milestone**: "v1.1.0" # Defina o nome da Milestone ativa no repositório ou 'None'
- **GitHub Project v2**:
  - **Owner**: "VitorJacom"
  - **Project Number**: 1 # Defina o número do projeto ou 'None'
  - **Status Field**: "Status"


