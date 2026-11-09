# 🎨 Catálogo de Telas (Mockup Living Specs)

Bem-vindo ao catálogo central de especificações vivas de telas (**Living Specs**) do projeto `my-agents`.

Este catálogo centraliza o design de interfaces segundo o protocolo determinístico **Figma-less Mockup-as-Code**, garantindo que todas as telas, componentes e fluxos visuais sejam especificados, versionados e auditados diretamente no Git antes e depois da codificação.

---

## 📑 Índice de Especificações Vivas

A tabela abaixo lista todas as telas cadastradas no sistema, seu identificador (`slug`), viewport de referência e status de aprovação visual:

| Slug | Nome da Tela | Viewport | Status | Origem | Spec |
| :--- | :--- | :--- | :--- | :--- | :--- |
| *template* | Template Canônico de Living Spec | 1280x720 / 375x812 | `Approved` | Issue #31 | [TEMPLATE.md](TEMPLATE.md) |
| `statusline-update-notification` | Statusline Update Notification | 1280x720 / TUI | `Approved` | Update Check Feature | [statusline-update-notification.md](statusline-update-notification.md) |

*(Novas telas desenvolvidas nas issues do projeto serão adicionadas aqui)*

---

## 🚀 Como Criar e Versionar um Novo Mockup (Workflow)

Quando uma funcionalidade demandar alterações visuais ou novas interfaces, o subagente `uiux-designer` ou o desenvolvedor deve seguir o seguinte fluxo:

1. **Copiar o Template Canônico**:
   Duplique o arquivo base [TEMPLATE.md](TEMPLATE.md) criando o documento da tela em `docs/mockups/<slug>.md`:
   ```bash
   cp docs/mockups/TEMPLATE.md docs/mockups/<minha-tela>.md
   ```

2. **Preencher os Metadados & Camadas**:
   - **Metadados**: Preencha o `slug`, `status` (`Draft`), `origem` (Issue correspondente) e `viewport`.
   - **Camada 1 (Spatial Blueprint ASCII)**: Desenhe a estrutura espacial em wireframe box-drawing.
   - **Camada 2 (Design Tokens & Luminance Contract)**: Especifique a tabela de tokens garantindo:
     - **Value Contrast >= 2:1** em escala de cinza entre superfícies e elementos interativos.
     - **WCAG AA >= 4.5:1** para textos e contrastes cromáticos.
   - **Estados Interativos & Acessibilidade**: Mapeie os estados (Default, Hover, Active, Focus, Disabled) e checklist ARIA.

3. **Gerar a Captura Visual (Asset)**:
   - Para protótipos HTML estáticos ou telas reais implementadas, gere a captura gráfica headless via Chromium:
     ```bash
     chromium --headless --screenshot=docs/assets/mockups/<slug>.png --window-size=1280,720 .mockup-preview.html
     ```
   - O arquivo de imagem correspondente deve residir em `docs/assets/mockups/<slug>.png`.

4. **Registrar no Catálogo**:
   - Adicione uma nova linha na tabela do índice acima neste arquivo (`docs/mockups/README.md`).

---

## 🏛️ Princípios do Protocolo Mockup-as-Code

O protocolo Mockup-as-Code elimina a dependência de plataformas proprietárias e silos de design, unificando a especificação visual sob os 4 valores do Manifesto AIDD:

1. **Figma-less e Versionado**: O código e o documento Markdown são a única fonte da verdade arquitetural.
2. **Defesa em Camadas**:
   - **Camada 1**: Blueprint estrutural independente de estilo gráfico.
   - **Camada 2**: Contrato matemático de luminância e design tokens.
   - **Camada 3**: Prova estática autocontida e captura determinística.
3. **Visual Gate Rigoroso**: Nenhum componente com interface gráfica é aceito em produção sem auditoria visual aprovada (`VISUAL_AUDIT: APPROVED`) pelo subagente `uiux-designer`.

---

## 🔗 Navegação da Wiki

- [📖 Visão Geral da Wiki (Home)](../Home.md)
- [🤖 Catálogo de Subagentes](../Subagents.md)
- [🛠️ Catálogo de Skills](../Skills-Catalog.md)
