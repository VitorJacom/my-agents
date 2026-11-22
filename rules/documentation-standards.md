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
