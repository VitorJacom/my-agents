# Implementation Plan - Protocolo de Validação Isolada em Sandbox (Clean Room Testing)

## Contexto & Motivação
Para evitar contaminação cognitiva e vazamento de contexto entre o desenvolvimento do plugin e os testes automatizados simulados no `sandbox/`, formalizamos o protocolo Clean Room. O agente é estritamente orientado a executar `cd` dentro da pasta do sandbox antes de inicializar qualquer novo processo do Antigravity CLI (`agy`), garantindo que o workspace seja descoberto isoladamente e que as configurações de `.agents/` do projeto consumidor sejam validadas de forma autêntica.

## Arquivos Impactados
- `rules/AGENTS.md`: Adição da Seção 8 contendo o protocolo Clean Room, a obrigatoriedade de navegar com `cd <sandbox>` antes do comando `agy` e as regras de simulação fiel de repositório consumidor.
- `skills/test-runner/SKILL.md`: Adição de diretrizes para testes de caixa-preta e regressão em repositórios sandbox via CLI desacoplada.
- `~/.gemini/config/plugins/my-agents`: Atualização da instalação global do plugin com `agy plugin install .`.

## Passos de Verificação Determinística
1. Executar `agy plugin validate .` na raiz para garantir conformidade do manifesto e dos componentes.
2. Executar `cd sandbox && agy --dangerously-skip-permissions -p "npx vitest run"` para comprovar o funcionamento de uma nova instância em ambiente estéril.
3. Gerar o relatório irrefutável de provas em `walkthrough.md`.
