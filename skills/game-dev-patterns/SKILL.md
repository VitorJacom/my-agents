---
name: game-dev-patterns
description: >-
  Padrões mandatórios de engenharia e física para desenvolvimento de jogos 2D (Phaser, Canvas, motores web).
  Garante independência de FPS, debounce de colisões contínuas, preservação dimensional de texturas em animações e alcance cinemático procedural.
---

# Padrões de Engenharia e Física para Jogos 2D (`game-dev-patterns`)

Esta Skill orienta o desenvolvimento e refatoração de jogos 2D (HTML5, Phaser 3, Canvas API e motores TypeScript/JavaScript), eliminando armadilhas clássicas de renderização, física cinemática e geração procedural.

---

## 🎯 Quando Acionar
- Desenvolvimento ou correção de jogos 2D, motores web (ex.: Phaser, PixiJS) e simulações com loop de física.
- Diagnóstico de bugs de física que só ocorrem em monitores de alta taxa de atualização (120Hz/144Hz) ou em telas móveis/tablets.
- Problemas com duplicação de áudio em colisões, sprites que explodem de tamanho em animações ou pulos impossíveis em fases procedurais.

---

## ⚙️ 1. Independência de Taxa de Quadros (FPS Independence & Timestep)

### Causa do Problema
Calcular movimentos somando deslocamentos fixos a cada frame (`sprite.x += speed`) faz com que a simulação corra 2x mais rápido em telas de 120Hz e em câmera lenta a 30Hz.

### Padrão Mandatório
1. **Configuração de Fixed Timestep**:
   No motor de física (ex.: Phaser Arcade Physics), configure taxa fixa e passo estável:
   ```typescript
   physics: {
     default: 'arcade',
     arcade: {
       fps: 60,
       fixedStep: true
     }
   }
   ```
2. **Normalização por Delta Time em Movimentos Manuais**:
   Sempre que movimentar posições via script no `update(time, delta)`:
   ```typescript
   // dt normalizado com base em 60 FPS (16.666ms por frame)
   const dt = delta / 16.666;
   sprite.x += horizontalSpeed * dt;
   ```
   Ou expressando velocidade explicitamente em pixels por segundo:
   ```typescript
   sprite.x += (pixelsPerSecond * delta) / 1000;
   ```

---

## 💥 2. Debounce Imediato em Coletáveis e Gatilhos de Colisão

### Causa do Problema
Callbacks contínuos (`overlap` ou `collider`) são executados a cada frame de sobreposição enquanto o sprite anima ou fadeia. Isso causa contagem duplicada/triplicada de pontos e sobreposição estridente de efeitos sonoros.

### Padrão Mandatório
Desative o corpo físico no **primeiríssimo frame de contato**, antes de disparar efeitos sonoros ou animações de coleta:
```typescript
this.physics.add.overlap(player, coin, (playerObj, coinObj) => {
  const coinSprite = coinObj as Phaser.Physics.Arcade.Sprite;

  // 1. DESATIVAÇÃO IMEDIATA DO CORPO FÍSICO
  if (!coinSprite.body || !coinSprite.body.enable) return;
  coinSprite.body.enable = false;

  // 2. DISPARO DE ÁUDIO E ANIMAÇÃO SEGURA
  this.sound.play('coin_collect');
  this.tweens.add({
    targets: coinSprite,
    alpha: 0,
    y: coinSprite.y - 30,
    duration: 250,
    onComplete: () => coinSprite.destroy()
  });
});
```

---

## 📐 3. Preservação Dimensional em Tweens e Animações

### Causa do Problema
Quando uma imagem de alta resolução (ex: 1024x1024) é ajustada via `setDisplaySize(64, 64)`, seu `scale` interno é recalculado (ex: `0.0625`). Chamar `setScale(1)` em tweens de pulo ou esmagamento (*squash & stretch*) explode a textura de volta para 1024px na tela.

### Padrão Mandatório
1. **Animar em Pixels de Display (`displayHeight` / `displayWidth`)**:
   ```typescript
   // Squash ao aterrissar preservando escala real
   const baseWidth = sprite.displayWidth;
   const baseHeight = sprite.displayHeight;

   this.tweens.add({
     targets: sprite,
     displayWidth: baseWidth * 1.25,
     displayHeight: baseHeight * 0.75,
     yoyo: true,
     duration: 120,
     onComplete: () => {
       sprite.setDisplaySize(baseWidth, baseHeight);
     }
   });
   ```
2. **Ou Preservar Escala Base Relativa**:
   Se animar via `scaleX`/`scaleY`, armazene a escala base do sprite e use-a como multiplicador:
   ```typescript
   const initialScaleX = sprite.scaleX;
   const initialScaleY = sprite.scaleY;

   this.tweens.add({
     targets: sprite,
     scaleX: initialScaleX * 1.2,
     scaleY: initialScaleY * 0.8,
     yoyo: true,
     duration: 100
   });
   ```

---

## 🦘 4. Garantia Cinemática de Alcance em Geração Procedural

### Causa do Problema
Sortear plataformas aleatoriamente com `Math.random() * screenWidth` cria abismos intransponíveis quando executado em telas largas (tablets, monitores ultrawide), quebrando a jogabilidade.

### Padrão Mandatório
Toda plataforma gerada proceduralmente deve estar restrita ao **envelope cinemático** de alcance do jogador:
```typescript
// Cálculo cinemático do tempo de voo e alcance horizontal máximo
const airTime = (2 * Math.abs(jumpVelocity)) / gravity;
const maxHorizontalReach = horizontalSpeed * airTime * 0.85; // 15% de margem de segurança

// Sorteio horizontal vinculado à posição da plataforma anterior
const offset = (Math.random() * 2 - 1) * maxHorizontalReach;
const nextX = Phaser.Math.Clamp(
  lastPlatform.x + offset,
  marginPadding,
  this.cameras.main.width - marginPadding
);
```

---

## 📋 Checklist de Validação para Jogos 2D
- [ ] Jogo testado com simulação de 30Hz e 120Hz sem desvios de física.
- [ ] Nenhum som de coleta ou pontuação sobreposta ao tocar coletáveis.
- [ ] Tweens de animação preservam dimensões e proporções reais da tela.
- [ ] Todas as plataformas procedurais são fisicamente alcançáveis a partir da anterior.
