# Implementation Plan - Generalização Sem Viés: Regras Visuais, Subagente UI/UX e Skill de Game Dev

## Contexto & Decisão Arquitetural (ADR-0001)
Atendendo às demandas das Issues #1 e #2 sem introduzir viés de domínio no plugin global `my-agents`, decompomos a implementação em:
1. Cláusula de Prova Visual Condicional no Manifesto AIDD (`rules/AGENTS.md`).
2. Subagente Transversal de UI/UX (`agents/uiux-designer/agent.md`).
3. Skill Especializada sob demanda de Game Dev (`skills/game-dev-patterns/SKILL.md`) com *Progressive Disclosure*.
4. Atualização de documentação em `README.md`.

## Arquivos Impactados
- `docs/adr/0001-generalizacao-de-regras-visuais-e-subagente-uiux.md`: Registro da decisão arquitetural (status: Aceita).
- `rules/AGENTS.md`: Atualização da Seção 1.3 (`walkthrough.md`) com diretrizes de inspeção visual condicional para camadas com UI/Frontend/Games.
- `agents/uiux-designer/agent.md`: Novo subagente especialista em hierarquia visual, contraste de valor, acessibilidade e microinterações táteis/game feel.
- `skills/game-dev-patterns/SKILL.md`: Nova skill contendo os padrões de física 2D, FPS independence, debounce de colisões e cinemática procedural.
- `README.md`: Documentação das novas capacidades do plugin.

## Passos de Verificação Determinística
1. Executar `agy plugin validate .` na raiz para assegurar que agentes, skills e regras estão perfeitamente registrados e válidos.
2. Atualizar a instalação global do plugin com `agy plugin install .`.
3. Executar Clean Room test no sandbox com uma nova instância isolada de `agy`.
4. Registrar saída e evidências no `walkthrough.md`.
