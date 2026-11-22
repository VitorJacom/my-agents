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

## 3. Padrão de Diagramas Mermaid (Wiki & Terminal)

Todo diagrama Mermaid em documentação da Wiki ou exibido no chat do terminal DEVE seguir estas convenções:

1. **Invocação Explícita de Subagentes (Sem Subtítulos)**:
   - Sempre que um passo acionar um subagente, o nó DEVE declarar explicitamente a ferramenta nativa do Antigravity e apenas o nome canônico do agente, sem subtítulos ou descrições extras:
     ```text
     <passo>. invoke_subagent: <nome-do-subagente>
     ```
   - Exemplo: `PO["1. invoke_subagent: product-owner"]`, `Arch["2. invoke_subagent: system-architect"]`.
   - O detalhamento de responsabilidades de cada agente pertence à tabela textual abaixo do diagrama, nunca ao rótulo do nó.

2. **Linguagem de Processo nos Demais Nós**:
   - Evitar flags de CLI (`--parent`, `--milestone`) ou nomes crus de scripts no diagrama; descrever de forma objetiva **o que a etapa realiza**.

3. **Largura Compacta na Wiki & Preview em Texto Simples no Chat**:
   - Nos arquivos `.md` da Wiki, manter blocos `mermaid` em orientação vertical (`flowchart TD`), quebrando linhas com `<br/>` (~35 caracteres por linha), arestas curtas (`"YES"`, `"NO"`, `"APPROVED"`, `"REJECTED"`, `"<= 2"`, `"> 2"`) e consolidando classificações em um único nó vertical (sem múltiplas arestas paralelas longas entre o mesmo par de nós).
   - **No chat do terminal (CLI)**: ao apresentar ou revisar fluxos com o usuário, **não** usar blocos ` ```mermaid ` (que frequentemente excedem a largura do terminal). Exibir o fluxo em **texto simples (ASCII compacto em bloco ` ```text `)**.
