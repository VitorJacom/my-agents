# Contexto Canônico do Projeto (`PROJECT_CONTEXT.md`)

## 🛠️ Stack Tecnológica & Dependências
- Definida no manifesto do projeto (consulte `package.json` / `pyproject.toml`).
- **Invariante**: Proibido adicionar ou supor dependências externas sem aprovação explícita.

## 📂 Estrutura Canônica de Diretórios
- `src/`: Código-fonte de produção.
- `scripts/`: Automação modular categorizada em `hooks/`, `pipeline/`, `statusline/` e `migrations/`.
- `tests/`: Suíte executada via `tests/run.sh` (`tests/core/` para base imutável e `tests/features/` organizada em `pipeline/`, `governance/`, `ui-ux/`, `wiki/` e `statusline/`).
- `docs/`: Documentação técnica viva e topologia modular da GitHub Wiki sincronizada via `.github/workflows/wiki-sync.yml`:
  - `Home.md`: Hub de navegação e landing page principal da Wiki.
  - `_Sidebar.md`: Barra lateral de navegação hierárquica.
  - `_Footer.md`: Rodapé padrão institucional e metadados de governança.
  - `Getting-Started.md`: Guia de introdução, onboarding e ciclo AIDD.
  - `Subagents.md`: Sumário executivo dos 7 subagentes especializados e matriz de permissões (com páginas dedicadas em `docs/agents/Agent-*.md`).
  - `agents/`: Páginas dedicadas de cada um dos 7 subagentes (`Agent-<nome>.md`).
  - `Skills-Catalog.md`: Sumário executivo das 11 skills ativadas por Progressive Disclosure (com páginas dedicadas em `docs/skills/Skill-*.md`).
  - `skills/`: Páginas dedicadas de cada uma das 11 skills (`Skill-<nome>.md`).
  - `Scripts-Catalog.md`: Sumário executivo dos 21 scripts de automação (com páginas dedicadas por categoria em `docs/scripts/Script-*.md`).
  - `scripts/`: Páginas dedicadas de cada categoria de scripts (`Script-<categoria>.md`).
  - `Tests-Catalog.md`: Sumário executivo das 51 suítes de testes (com páginas dedicadas por categoria em `docs/tests/Test-*.md`).
  - `tests/`: Páginas dedicadas de cada categoria da suíte de testes (`Test-<categoria>.md`).
  - `AIDD-Manifesto.md`: Manifesto AI-Driven Development e 4 valores fundamentais.
  - `System-Architecture.md`: Visão arquitetural em 5 camadas concêntricas e índice de ADRs.
  - `Troubleshooting.md`: Diagnóstico de problemas, locks, tokens e circuit breakers.
  - `ARCHITECTURE.md`: Especificação técnica canônica viva e decisões consolidadas.
  - *Validação de Integridade*: Suíte determinística em `tests/features/wiki/test_wiki_structure_and_links.sh`.

## 🛑 Regras e Invariantes Estritas (Anti-Alucinação)
1. **Grounding Mandatório**: Não invente diretórios ou convenções de nomenclatura fora do padrão declarado acima.
2. **Duplo Gate**: Nenhuma alteração é comitada sem passar pela auditoria de conformidade do Gatekeeper.

## 🎯 Rastreamento & GitHub Governance
- **Active Epic (Milestone)**: "Epic: AIDD Core & Engineering Governance" # Active Milestone / Épico padrão ou 'None'
- **GitHub Project v2**:
  - **Owner**: "VitorJacom"
  - **Project Number**: 1 # Defina o número do projeto ou 'None'
  - **Status Field**: "Status"
  - **Release Field**: "Release" # Campo customizado de versão (v1.0.0, v1.1.0, v1.2.0, Backlog / Future)
  - **Default Release**: "v1.1.0"


