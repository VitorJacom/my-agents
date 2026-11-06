# Ciclo de Refinamento 80/20 & Protocolo de Sanitização de AI Slop

Este documento reúne a metodologia prática de trabalho com agentes de IA para transformar rascunhos funcionais médios em interfaces de nível de produção, eliminando vícios compulsivos de modelos de linguagem e ajustando a densidade de informação.

---

## 1. O Funil de Refinamento Trifásico (Ciclo 80/20)

Modelos de IA geram rapidamente os 80% funcionais da tela, mas operam na média estatística da internet. Exigir perfeição no primeiro prompt gera frustração. A engenharia eficiente de interface separa o processo em 3 fases:

```
+---------------------------------------------------------------------------------+
|  FASE 1: Geração Funcional Livre (Os 80% Rápidos)                               |
|  - Foco exclusivo em mecânica, componentes necessários e fluxo funcional.      |
|  - Sem bloqueio criativo com microdesign ou paleta de cores.                   |
+---------------------------------------------------------------------------------+
                                      |
                                      v
+---------------------------------------------------------------------------------+
|  FASE 2: Injeção de Skills Modulares de Fundamentos                              |
|  - Ciclo A: Aplicação de tipografia óptica, pesos e hierarquia.                 |
|  - Ciclo B: Ajuste de espaçamentos (8pt grid), alinhamentos e contraste.        |
+---------------------------------------------------------------------------------+
                                      |
                                      v
+---------------------------------------------------------------------------------+
|  FASE 3: O Ajuste Fino Humano (Os 20% Decisivos - Versão 2 Lado a Lado)          |
|  - Preservar a versão 1 intacta para comparação direta.                        |
|  - Microinterações táteis, calibração de densidade e refinamento estético.     |
+---------------------------------------------------------------------------------+
```

---

## 2. Protocolo de Sanitização de Vícios de Slop (Checklist Cirúrgico)

Antes de aprovar qualquer tela gerada por IA, execute este script de purga:

| Vício Comum de IA | Impacto Negativo | Ação Corretiva Mandatória |
|---|---|---|
| **Emojis em Menus e Títulos** (🚀, 💡, 🔥, ✨) | Aparência infantil, amadora e de template pré-fabricado. | **Remoção total.** Substitua por tipografia pura ou ícones vetoriais monocromáticos funcionais (SVG 16px/20px). |
| **Bordas Cinzas em Tudo** (`border border-gray-200`) | Corta o layout em retalhos duros; cria sensação de gaiola visual. | Elimine bordas de cards e linhas de tabelas. Use espaço em branco (*whitespace*) e variações tonais milimétricas. |
| **Paleta "Roxo/Gradiente de IA"** (`from-purple-600 to-indigo-600`) | Assinatura visual denunciadora de código gerado por IA. | Substitua por pretos profundos, ardósias neutras e a cor de destaque (*accent*) oficial da marca. |
| **Ícones de Diamante/Faíscas** (Sparkles/Stars soltos) | Poluição decorativa sem significado semântico. | Corte qualquer elemento ornamental que não responda a um status do sistema. |
| **Rótulos em Gritante Caixa Alta** (`ALL-CAPS`) | Cansaço ocular e perda de escaneabilidade. | Converta para **Sentence Case** com peso tipográfico moderado (*medium* ou *semibold*). |

---

## 3. Matriz de Densidade Situacional

A IA costuma tratar telas densas como se fossem landing pages institucionais gigantes. Ajuste os multiplicadores conforme a natureza do produto:

| Parâmetro | Landing Page / Onboarding | Dashboard Operacional / Diretório / Tabela |
|---|---|---|
| **Escala Tipográfica do Corpo** | `16px` a `18px` | `13px` a `14px` |
| **Espaçamento entre Linhas** | `leading-relaxed` (1.6 a 1.75) | `leading-snug` (1.35 a 1.4) |
| **Padding de Célula / Item** | `16px` a `24px` | `8px` a `12px` |
| **Disposição dos Ícones** | Centralizados acima do texto (grandes) | Alinhados horizontalmente à esquerda do texto (16px a 18px) |
| **Meta de Viewport** | 2 a 3 blocos visíveis sem scroll | 10 a 20 registros escaneáveis sem scroll |

---

## 4. Engenharia de Grade Masonry Contínua (`Auto-Flow Masonry`)

Para evitar vácuos verticais quando blocos ou listas possuem alturas desiguais, adote a técnica de fluxo contínuo via CSS:

```css
/* Abordagem CSS Column Masonry */
.masonry-grid {
  column-count: 1;
  column-gap: 1.5rem;
}

@media (min-width: 768px) {
  .masonry-grid {
    column-count: 2;
  }
}

@media (min-width: 1024px) {
  .masonry-grid {
    column-count: 3;
  }
}

.masonry-item {
  break-inside: avoid;
  margin-bottom: 1.5rem;
}
```

Essa estrutura permite que cards menores subam imediatamente para preencher o vácuo de cards vizinhos mais longos, eliminando buracos assimétricos no meio da tela.
