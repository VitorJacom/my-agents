# Padrões de Documentação, Relatórios e GitHub Wiki

Diretrizes complementares a `rules/AGENTS.md` para garantir hierarquia visual, legibilidade analítica e navegabilidade em relatórios, catálogos e Wikis mantidas como *Docs-as-Code*.

---

## 1. Projeto de Relatórios e Documentos de Saída (Pressman / Sommerville)

Todo relatório estruturado, catálogo documental, sumário executivo ou `walkthrough.md` produzido por agentes DEVE priorizar a **hierarquia da informação** em quatro camadas obrigatórias:

1. **Título Principal**: Identificação inequívoca do documento e de seu escopo.
2. **Cabeçalho de Controle**: Bloco logo abaixo do título contendo:
   - **Escopo / Filtros Aplicados** (ex.: diretórios, status, ordenação).
   - **Data/Hora de Emissão** (timestamp ou referência de sincronização).
   - **Fonte Canônica** (caminho ou diretório de origem dos dados).
3. **Corpo Tabular Padronizado**:
   - **Textos** sempre alinhados à **esquerda** (`:---`).
   - **Valores numéricos, contagens, índices (`#`) e percentuais** sempre alinhados à **direita** (`---:`).
   - **Linha de Totalizador** ao final da tabela quando houver agregação ou contagem de itens.
4. **Rodapé de Controle**:
   - **Totalizadores** sumarizados (quantidade de registros, categorias, páginas ou cobertura).
   - **Paginação / Navegação**: Indicação de posição (`Catálogo X de N` ou `Anterior | Índice | Próximo`) quando o documento fizer parte de uma série.

---

## 2. Arquitetura Modular de GitHub Wiki (Gollum / GFM)

Para manter Wikis escaláveis e de fácil navegação:

1. **Topologia Sumário + Páginas Dedicadas**:
   - Tópicos com múltiplos itens (ex.: Subagentes, Skills, Scripts, Testes) DEVEM possuir um **Sumário Executivo** (tabela resumo seguindo o padrão Pressman/Sommerville) linkando para **páginas dedicadas** individuais.
   - Utilizar prefixos semânticos nos arquivos em subdiretórios (ex.: `docs/skills/Skill-<nome>.md`, `docs/agents/Agent-<nome>.md`, `docs/scripts/Script-<cat>.md`, `docs/tests/Test-<cat>.md`) para evitar colisões no namespace plano do motor Gollum.

2. **Sidebar Colapsável com Títulos Clicáveis (`docs/_Sidebar.md`)**:
   - Agrupar tópicos extensos em blocos `<details>` / `<summary>` (recolhidos por padrão) para manter a barra lateral compacta.
   - O texto do `<summary>` DEVE atuar como hyperlink direto para a página de Sumário daquele tópico (eliminando subitens redundantes de "Sumário").
   - **Invariante GFM/Gollum**: Dentro de `<summary>`, usar estritamente HTML `<a href="<slug>"><strong>...</strong></a>` (links Markdown `[texto](slug)` dentro de tags `<summary>` não são renderizados pelo parser `cmark-gfm` do GitHub), deixando uma linha em branco após `</summary>` antes da lista Markdown.

```html
<details>
<summary><a href="Skills-Catalog"><strong>🧰 Skills (11)</strong></a></summary>

- [`plan-feature`](Skill-plan-feature)
- [`issue-pipeline`](Skill-issue-pipeline)

</details>
```

---

## 3. Padrão de Diagramas Mermaid (Wiki)

Todo diagrama Mermaid em documentação da Wiki DEVE seguir estas convenções:

1. **Invocação Explícita de Subagentes (Sem Subtítulos)**:
   - Sempre que um passo acionar um subagente, o nó DEVE declarar explicitamente a ferramenta nativa do Antigravity e apenas o nome canônico do agente, sem subtítulos ou descrições extras:
     ```text
     <passo>. invoke_subagent: <nome-do-subagente>
     ```
   - Exemplo: `PO["1. invoke_subagent: product-owner"]`, `Arch["2. invoke_subagent: system-architect"]`.
   - O detalhamento de responsabilidades pertence à tabela textual abaixo do diagrama, nunca ao rótulo do nó.

2. **Linguagem de Processo e Decisões Explícitas**:
   - Evitar flags de CLI (`--parent`, `--milestone`) ou nomes crus de scripts no diagrama; descrever de forma objetiva **o que a etapa realiza**.
   - Quando o fluxo variar conforme o tipo de entrada ou triagem (ex.: Nova Issue vs. Issue Existente vs. Épico), explicitar no diagrama **quem** classifica e **quais** critérios distinguem cada caminho.

3. **Layout Compacto na Wiki e Proibição de Diagramas no Chat**:
   - Nos arquivos `.md` da Wiki, manter blocos `mermaid` em orientação vertical (`flowchart TD`), quebrando linhas com `<br/>` (~35 caracteres por linha), usando arestas curtas (`"YES"`, `"NO"`, `"APPROVED"`, `"REJECTED"`) e consolidando classificações em um único nó vertical.
   - **No chat do terminal (CLI)**: **não** renderizar blocos `mermaid` nem desenhos ASCII para revisar fluxos com o usuário (quebram facilmente na largura do terminal). Apresentar revisões de fluxo no chat usando **lista numerada simples**.

4. **Cobertura Completa para Fluxos Multi-Modo**:
   - Sempre que uma skill ou componente operar em **múltiplos modos** (ex.: Modo Unitário vs. Modo Maestro), a página dedicada DEVE incluir:
     - Um **diagrama de Roteamento de Modo (Triagem de Entrada)** explicitando qual critério direciona a execução para cada fluxo.
     - Um **diagrama Mermaid dedicado (`flowchart TD`) para CADA modo de operação**, sem resumir modos secundários apenas em texto corrido.

---

## 4. Redação de Páginas Dedicadas (Alto Nível & Cross-Linking)

Ao redigir ou refatorar páginas dedicadas da Wiki (`docs/skills/`, `docs/agents/`, `docs/scripts/`, `docs/tests/`):

1. **Comunicação em Alto Nível (Sem Jargão Fora do Foco)**:
   - Explicar claramente **o que acontece** em cada etapa em linguagem direta e acessível.
   - Não vazar detalhes técnicos profundos ou métricas de nicho de outros componentes quando o foco da página for orquestração/visão geral (ex.: na página de uma skill, não detalhar regras internas de contraste WCAG ou algoritmos específicos de um subagente — esses detalhes pertencem à página dedicada do próprio subagente).

2. **Cross-Linking Obrigatório na Wiki**:
   - Sempre que uma página mencionar outro componente que já possua página dedicada na Wiki — subagentes (`Agent-<nome>`), skills (`Skill-<nome>`), scripts (`Script-<categoria>`), testes (`Test-<categoria>`) ou documentos estruturais (`ARCHITECTURE`, `System-Architecture`, `AIDD-Manifesto`) — DEVE incluir hyperlink clicável usando o slug plano do Gollum.
   - Validar obrigatoriamente a integridade dos links com `./tests/run.sh --category wiki`.

3. **Paridade de `Responsabilidades por Estado` em Múltiplos Modos**:
   - Toda máquina de estados ou modo de operação documentado com diagrama DEVE possuir sua própria tabela `Responsabilidades por Estado` (`Estado | Responsável | O que acontece nesta etapa`) em linguagem de alto nível e com cross-linking.

4. **Comandos Canônicos de Invocação de Skills (`/<skill-name>`)**:
   - Ao documentar o comando de invocação ou exemplos de uso de qualquer skill na Wiki, utilizar **estritamente o nome canônico da skill** (`/<name>`, conforme o campo `name:` do `SKILL.md` e o diretório `skills/<name>/` no Antigravity CLI — ex.: `/issue-pipeline`, `/plan-feature`, `/pr`).
   - É proibido inventar ou propagar aliases legados/fictícios (como `/run-issue`) que não correspondam ao padrão real de invocação do Antigravity CLI.

5. **Sem Título `# H1` Redundante nas Páginas Dedicadas da GitHub Wiki**:
   - O motor Gollum da GitHub Wiki já renderiza automaticamente o slug do arquivo como título `<h1>` no topo da página (ex.: `Skill-issue-pipeline.md` ➔ `Skill issue pipeline`).
   - Por isso, páginas dedicadas (`docs/skills/`, `docs/agents/`, `docs/scripts/`, `docs/tests/`) **NÃO devem repetir um `# H1`** no corpo do Markdown. Iniciar diretamente com o breadcrumb `[← Voltar ao Sumário...]` seguido pelo bloco de metadados (`> **<Subtítulo Descritivo>**` + `Definição Canônica`, `Categoria`, `Comando de Invocação`) e partir para seções `##`.
   - *(Exceção: `Home.md`, cujo título nativo é apenas "Home", pode manter o H1 de boas-vindas).*
