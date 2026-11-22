[← Voltar ao Sumário de Skills](Skills-Catalog)

# Skill: `game-dev-patterns` (Engenharia & Física para Jogos 2D)

> **Definição Canônica**: [`skills/game-dev-patterns/SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/game-dev-patterns/SKILL.md)  
> **Categoria**: Domínios Especializados  
> **Comando de Invocação**: Invocação contextual em projetos de jogos 2D (Phaser, PixiJS, Canvas)

---

## 🎯 Objetivo

A skill **`game-dev-patterns`** encapsula padrões mandatórios de engenharia e física cinemática para jogos 2D na web, eliminando bugs clássicos de taxa de quadros, colisões duplicadas, distorção de sprites e fases procedurais impossíveis — permanecendo 100% adormecida em projetos fora do domínio de jogos (*Zero Token Waste*).

---

## ⚡ Quando Acionar (*Progressive Disclosure*)

- Desenvolvimento ou refatoração de jogos 2D em HTML5 Canvas, Phaser 3 ou PixiJS.
- Bugs de física que mudam entre monitores de 30Hz, 60Hz e 120Hz/144Hz.
- Duplicação de pontos/sons em colisões, sprites que explodem de escala em tweens ou plataformas procedurais inalcançáveis.

---

## 🚀 Exemplos de Invocação

```text
O personagem pula mais alto em monitores de 144Hz, ajuste para delta time
Aplique debounce no som de impacto da colisão entre o projétil e o inimigo
Garanta alcance cinemático na geração procedural de plataformas
```

---

## ⚙️ Os 4 Padrões Mandatórios

| Padrão | Problema Evitado | Solução Canônica |
| :--- | :--- | :--- |
| **1. Independência de FPS** | Jogo 2x mais rápido em 120Hz ou em câmera lenta a 30Hz | `fixedStep: true` (`fps: 60`) no motor de física e movimentos manuais normalizados por `delta` (`(pixelsPerSecond * delta) / 1000`). |
| **2. Debounce em Colisões** | Pontuação duplicada e áudio estridente durante `overlap` contínuo | Desativar `sprite.body.enable = false` no primeiríssimo frame de contato antes de tocar som ou iniciar tween. |
| **3. Preservação Dimensional** | `setScale(1)` explodindo sprites redimensionados via `setDisplaySize` | Animar `displayWidth`/`displayHeight` diretamente ou multiplicar pela escala base (`initialScaleX`/`initialScaleY`). |
| **4. Alcance Cinemático Procedural** | Abismos impossíveis em telas largas/ultrawide | Restringir `nextX` ao envelope balístico (`airTime = 2 * |jumpVelocity| / gravity`, margem de 85% via `Clamp`). |

---

## ✅ Checklist de Validação

- [ ] Simulação validada a 30Hz e 120Hz sem desvios de física.
- [ ] Sem som ou pontuação duplicada ao tocar coletáveis.
- [ ] Tweens preservam proporções e dimensões reais de tela.
- [ ] Todas as plataformas procedurais são fisicamente alcançáveis.

---

## 🔗 Navegação

[← Anterior: `docker-dev`](Skill-docker-dev) | [Sumário de Skills](Skills-Catalog) | [Próxima Skill: `publish-rule-issue` →](Skill-publish-rule-issue)
