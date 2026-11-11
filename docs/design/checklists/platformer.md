<!-- Origem: Claude-Code-Game-Studios (MIT, (c) 2026 Donchitos), seção "Aplicação no João" adicionada. Ver docs/third-party/claude-code-game-studios-LICENSE.md -->

# Chipset: platformer

**Camera:** `follow2d`; `orbit` in 3D.

## Card defaults

- **instant-retry**: A fall or a hit puts you back at the last checkpoint at once: no lives, no
  game-over screen. Why: failing costs seconds, so the hard jump gets tried again. Break it when:
  arcade stakes are the point, lives and a game over.

## Feel

- **forgiving-jump**: Late jumps off a ledge, early presses just before landing and clipped corners
  still count. Why: a miss is the player's mistake, never the game's. Break it when: the person
  wants exact, unforgiving jumps as the challenge.
- **jump-control**: Hold the button to jump higher, tap it for a hop, and fall faster than you rise.
  Why: the player shapes every arc and lands soon enough to act again. Break it when: every jump is
  meant to be the same arc, as in a one-button game.
- **jump-land-juice**: Every jump and landing has its own sound and a quick squash of the body, with
  a puff of dust on a hard landing. Why: the body feels its weight without a word on screen. Break
  it when: the look is still and abstract on purpose, shapes that never bend.
- **look-ahead**: The camera shows more of where you are heading and holds still through ordinary
  jumps. Why: the next hazard is seen in time, and the screen does not bob. Break it when: each
  level is one room that fits the window.
- **fair-hurtbox**: Only your body takes hits, never your hair or cape: the hit box sits inside the
  sprite. Why: a near miss looks like one. Break it when: the part that can be hit is the hook, a
  flame or a shadow.

## Feel variants

- **precise**: Tight and arcade: quick to start and stop, short committed hops, fast falls.
- **flowing**: Flowing: speed builds on slopes and carries through slides and wall runs.
- **heavy**: Heavy and grounded: slow to turn, jumps with weight that land with a thud.

## Choices that shape the pitch

- **Failure:** instant retry at checkpoints (default) · lives and a game over, arcade stakes · none,
  exploring at your own pace.
- **Progression:** hand-made screens in order (default) · one connected map opened by new moves, a
  metroidvania · an endless run.
- **What the player sees:** side view, `follow2d` (default) · 3D behind the avatar, `orbit`.
- **Feeling:** the player feels precise mastery by clearing a jump they missed a moment ago, because
  the miss was their own and the retry is instant.

## Later, never in a one-shot

- New moves over time → grow it
- Bosses → change it after play
- Collectible hunts and completion → change it after play
- Checkpoints traded for rewards → change it after play
- A speedrun timer and ghosts → change it after play
- Two-player co-op on one screen → change it after play
- A level editor → not tested yet: ask for it after play and the AI will try it untested

## In a mashup

The platformer leads movement and camera. Puzzle leads rules, undo and level teaching, and movement
forgiveness never lets a jump bypass the puzzle. A metroidvania leads the map and its ability gates.
A roguelite leads the run and what carries over. A management half leads money and building between
levels.

---

## Aplicação no João (escalada do pé de cannabis)

Status em relação a `src/scripts/player.gd` e `src/scripts/orbital_camera.gd`:

| Item | Status | Onde / o que falta |
|------|--------|--------------------|
| forgiving-jump | ✅ feito | `coyote_time` 0.12 s e `jump_buffer_time` 0.12 s. Falta corner correction (empurrar para cima da borda da folha ao bater de raspão). |
| jump-control | ✅ feito | `jump_cut_multiplier` 0.45 ao soltar, `fall_gravity_multiplier` 1.8, `max_fall_speed`. |
| instant-retry | ⬜ falta | Checkpoints nas folhas grandes; queda = volta ao último checkpoint em < 1 s, sem tela de game over. Na escalada de 40 m, cair até o chão seria punitivo demais. |
| jump-land-juice | ⬜ falta | Squash no `visual` ao aterrissar, poeira/esporos em queda alta, som por tipo de superfície (folha, tronco). |
| look-ahead | 🟨 parcial | Câmera orbital com colisão existe. Falta viés para cima na escalada (mostrar a próxima folha) e tratar o tronco ocluindo o João na espiral. |
| fair-hurtbox | ⬜ falta | Quando houver perigos, a hurtbox do João menor que a malha. |

**Feel escolhido:** entre *precise* e *heavy*: saltos com peso cômico, mas com controle de arco.

**Específico do jogo:**
- Na Zona de Névoa (0.4x), o input continua responsivo; considere manter a câmera em tempo real para o
  jogador "ler" o perigo com calma.
- Progressão: espiral feita à mão em ordem (default do chipset), não metroidvania.
- "Bosses" e "fuga cronometrada" (Ato IV) ficam para depois da escalada funcionar bem.
