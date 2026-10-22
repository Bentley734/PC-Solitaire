# PC Games 1.3.2

Solitaire, Snake, Tetris, Blackjack and Collapse in a **GAMES** submenu on every in-game PC. Supports Red, Blue, Yellow, Gold, Silver, Crystal, FireRed, LeafGreen, Ruby, Sapphire and Emerald with Mod API v2 (Gen1Recomp >=0.3.54 <0.4.0).

Install: extract `pc_solitaire` into `mods`, replacing the previous folder, enable **PC Games**, and restart the game. The folder, internal mod ID and GitHub repository remain unchanged so this upgrades PC Solitaire. Choose **GAMES** at any PC, including bedroom PCs. In Gen 3 player/bedroom PCs, GAMES is part of the native options list immediately before Turn Off; there is no extra Player PC / Games chooser.

## Menu and return

Up/down chooses one of five games or Back to PC. A opens the highlighted game; B returns to the PC. Each game has a pause menu that returns to Games. The PC session and submenu selection stay in place. All game progress is temporary; Pokemon save data is untouched.

## Solitaire

- D-pad: left/right changes piles; down enters a tableau or steps down its face-up cards; up steps toward its first face-up card, then the top row.
- A: draw/recycle stock, pick a card or valid substack, then place it. Double-tap A within 0.35 seconds on a top face-up card for auto-foundation.
- B: cancel a selection, or prompt to quit to Games. A confirms, B resumes.
- Start/Select: Resume, New Deal, Draw 1/3 Toggle, Quit to Games.

Alternating-color descending tableau, Kings on empty columns, same-suit ascending foundations from Ace to King, unlimited stock recycling. Changing draw mode keeps the current deal. Exposed cards flip automatically. Foundation cards may return to the tableau. Complete all foundations to win. The yellow selector surrounds the whole card. Cards slide between piles, and newly revealed cards flip with a brief edge-on transition. Animations pause with the game and allow responsive follow-up moves.

## Snake

D-pad changes direction. Eat red food to grow and score 10 points; speed increases with score. Avoid walls and your own body. Reversing into your neck is prevented. Filling the board wins. Eating triggers a golden burst, floating score, and a growth pulse along the body. A retries after game over.

B, Start or Select pauses. Choose Resume, New Game or Back to Games.

## Tetris

- Left/right: move; hold to repeat.
- Down: soft drop; hold to repeat.
- A: rotate clockwise, with horizontal wall kicks.
- Up: hard drop and lock.
- B/Start/Select: pause with Resume, New Game or Back to Games.
- A after game over: retry.

Seven shuffled pieces per bag, next-piece preview, landing outline, row clearing and increasing gravity every ten lines. Clear 1/2/3/4 rows for 100/300/500/800 points times the current level; soft/hard drop adds 1/2 points per cell. Stack above the board or block the spawn to end the game. Uses immediate locking on contact and simple wall kicks. Cleared rows flash and shrink, then the blocks above settle downward. Gravity and piece controls wait for the 0.48-second clear animation; pausing freezes it.

## Blackjack

A 52-card deck is shuffled for each hand. Choose Hit, Stand or Double with the D-pad and A. Dealer stands on all 17s, including soft 17. Aces count as 1 or 11, faces as 10. Double is available only on the initial two cards and takes exactly one card. No splitting, insurance or surrender. A after the result deals again. Session points: win +10, loss -10, natural blackjack +15, push 0; double changes the win/loss to 20 points. These are temporary score points. B/Start/Select opens pause; New Game deals a hand, Back to Games exits.

## Collapse

An original rising-block puzzle inspired by Collapse: move the cursor with the D-pad, press A on an orthogonally connected group of at least three identical blocks. Blocks fall down within their own columns after a clear. Blocks use solid colors without number labels. Press Down while already on the bottom row to bring up the next row immediately; the cursor follows the existing blocks upward and the automatic-row timer resets. A row rises every eight seconds initially, speeding up as the score grows; reaching the top ends the game. Groups score `n*(n-1)*5`. B/Start/Select pauses; A retries after game over. No copyrighted Collapse assets are used.

## Display and engine adapters

Native 160x144 and 240x160 layouts. Card sprites are drawn at uniform integer factors: 1x (16x24) on Gen 1/2, 2x (32x48) on Gen 3. All textures and the presentation canvas use nearest filtering. Flips crop a central sprite strip instead of stretching it; moving cards, particles, tiles and falling blocks snap to integer coordinates. Missing sprites use procedural pixel cards. The games use a native-size canvas and whole physical-pixel window scaling, with black letterboxing, independent of the engine fill setting. High-DPI origins are pixel-aligned; a window smaller than the native game surface crops rather than fractional-scales it. Controls only use abstract input actions (`wasPressed` and `isDown`).

The public `ui.pc.items` hook covers Gen 1/2 direct PCs. Engine adapters cover the Gen 1 bedroom constructor, Gen 2 hub/item dispatch, and Gen 3 root and bedroom menus/modal stack. Built-in Gen 3 script result indexes stay unchanged. `engine_internals` permission is required for menus without a public hub hook.

## Validation

Run with Python and `lupa` installed:

    python tests/run.py /path/to/gen1recomp-0.3.54

Tests run against engines 0.3.54 and 0.3.58, plus manifest validation including the exact GitHub update source. The additional rules suite covers 100 shuffled Blackjack decks, Collapse clearing/gravity, and all extra-game pause/exit controls. Pixel checks exercise 132 frames, 884 sprite draws, and eight window/DPI layouts. Tests cover animation timing, rule-state isolation, pause/resume, direct native PC integration, Klondike rules and controls; Snake growth, collisions, turns and victory; Tetris bags, rotation, clears, levels and top-out; game timers, pause, retry and submenu navigation. The native-menu integration suite tours all five games and returns to the same PC across all eleven game IDs. ROM text/font/chrome and graphics/audio are fixture substitutes, not eleven ROM-backed playthroughs.

Real LOVE renders at both native resolutions cover the submenu, Snake, Tetris, pause and game-over states, plus animation frame sequences. Animated previews are in `docs/effects-160.gif` and `docs/effects-240.gif`.

Card faces are extracted from the user-provided `Poker cards 1.3.zip`. No author/license document accompanied it. The patterned back and procedural fallback are original. See `ASSET_CREDITS.md`.

The update source in `manifest.json` is `"github": "Bentley734/PC-Solitaire"`.
