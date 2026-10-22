# PC Games 1.1.0

Solitaire, Snake and Tetris in a **GAMES** submenu on every in-game PC. Supports Red, Blue, Yellow, Gold, Silver, Crystal, FireRed, LeafGreen, Ruby, Sapphire and Emerald with Mod API v2 (Gen1Recomp >=0.3.54 <0.4.0).

Install: extract `pc_solitaire` into `mods`, replacing the previous folder, enable **PC Games**, and restart the game. The folder, internal mod ID and GitHub repository remain unchanged so this upgrades PC Solitaire. Choose **GAMES** at any PC, including bedroom PCs. In Gen 3 bedrooms, choose GAMES alongside PLAYER PC.

## Menu and return

Up/down chooses Solitaire, Snake, Tetris or Back to PC. A opens the highlighted game; B returns to the PC. Each game has a pause menu that returns to Games. The PC session and submenu selection stay in place. All game progress is temporary; Pokemon save data is untouched.

## Solitaire

- D-pad: left/right changes piles; down enters a tableau or steps down its face-up cards; up steps toward its first face-up card, then the top row.
- A: draw/recycle stock, pick a card or valid substack, then place it. Double-tap A within 0.35 seconds on a top face-up card for auto-foundation.
- B: cancel a selection, or prompt to quit to Games. A confirms, B resumes.
- Start/Select: Resume, New Deal, Draw 1/3 Toggle, Quit to Games.

Alternating-color descending tableau, Kings on empty columns, same-suit ascending foundations from Ace to King, unlimited stock recycling. Changing draw mode keeps the current deal. Exposed cards flip automatically. Foundation cards may return to the tableau. Complete all foundations to win. The yellow selector surrounds the whole card.

## Snake

D-pad changes direction. Eat red food to grow and score 10 points; speed increases with score. Avoid walls and your own body. Reversing into your neck is prevented. Filling the board wins. A retries after game over.

B, Start or Select pauses. Choose Resume, New Game or Back to Games.

## Tetris

- Left/right: move; hold to repeat.
- Down: soft drop; hold to repeat.
- A: rotate clockwise, with horizontal wall kicks.
- Up: hard drop and lock.
- B/Start/Select: pause with Resume, New Game or Back to Games.
- A after game over: retry.

Seven shuffled pieces per bag, next-piece preview, landing outline, row clearing and increasing gravity every ten lines. Clear 1/2/3/4 rows for 100/300/500/800 points times the current level; soft/hard drop adds 1/2 points per cell. Stack above the board or block the spawn to end the game. Uses immediate locking on contact and simple wall kicks.

## Display and engine adapters

Native 160x144 and 240x160 layouts. Card images use nearest filtering; missing sprites use procedural pixel cards. The mod allocates no canvases. Controls only use abstract input actions (`wasPressed` and `isDown`).

The public `ui.pc.items` hook covers Gen 1/2 direct PCs. Engine adapters cover the Gen 1 bedroom constructor, Gen 2 hub/item dispatch, and Gen 3 root and bedroom menus/modal stack. Built-in Gen 3 script result indexes stay unchanged. `engine_internals` permission is required for menus without a public hub hook.

## Validation

Run with Python and `lupa` installed:

    python tests/run.py /path/to/gen1recomp-0.3.54

Tests cover Klondike rules and controls; Snake growth, collisions, turns and victory; Tetris bags, rotation, clears, levels and top-out; game timers, pause, retry and submenu navigation. The native-menu integration suite tours all three games and returns to the same PC across all eleven game IDs. ROM text/font/chrome and graphics/audio are fixture substitutes, not eleven ROM-backed playthroughs.

Real LOVE renders at both native resolutions cover the submenu, Snake, Tetris, pause and game-over states. Screenshots are in `docs/`.

Card faces are extracted from the user-provided `Poker cards 1.3.zip`. No author/license document accompanied it. The patterned back and procedural fallback are original. See `ASSET_CREDITS.md`.
