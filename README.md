# PC Games 1.4.1

Solitaire, Snake, Tetris, Blackjack, Collapse, Minesweeper and PokePet in a **GAMES** submenu on every in-game PC. Supports Red, Blue, Yellow, Gold, Silver, Crystal, FireRed, LeafGreen, Ruby, Sapphire and Emerald with Mod API v2 (Gen1Recomp >=0.3.54 <0.4.0).

Install: extract `pc_solitaire` into `mods`, replacing the previous folder, enable **PC Games**, and restart the game. The folder, internal mod ID and GitHub repository remain unchanged so this upgrades PC Solitaire. Choose **GAMES** at any PC, including bedroom PCs. In Gen 3 player/bedroom PCs, GAMES is part of the native options list immediately before Turn Off; there is no extra Player PC / Games chooser.

## Menu and return

Up/down chooses one of seven games or Back to PC. A opens the highlighted game; B returns to the PC. Each game has a pause menu that returns to Games. The PC session and submenu selection stay in place. Arcade progress is temporary; PokePet saves separately through the mod storage API for each playthrough. Playing the games does not change your party, inventory or money.

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

## Minesweeper

A 9x9 field with ten mines. D-pad moves the cursor, A digs and Select toggles a flag (up to ten flags). Your first dig and its surrounding eight squares are safe. Empty spaces open their neighbors automatically. Press A on an already revealed number with the matching count of neighboring flags to reveal its remaining neighbors; incorrect flags can expose a mine. Reveal every safe square to win. B/Start opens Resume, New Game and Back to Games. A after winning or losing starts a fresh field. The timer starts with the first dig and pauses in the menu.

## PokePet

Adopts a random Pokemon from the active game's loaded species roster, including the extended roster when 1025Dex is enabled. The pet uses the live front/menu sprite provider, so your current native or modded art and 1025Dex animated/static/G9 Gen3 choices apply. Species and care progress persist between PC visits and restarts, separately for each playthrough. The species stays the same when you switch sprite styles. No Pokemon art is bundled or downloaded by this game.

D-pad selects Feed, Play, Rest/Wake or Clean. A cares for the pet; short reactions accompany each action. Successful feeding and play also trigger the adopted Pokemon's cry through the active game provider, including 1025Dex's selected cry style. Full, tired or sleeping pets do not cry for rejected care, and the reaction cooldown prevents rapid repeats. Food, happiness, energy and hygiene decrease while visiting; sleep restores energy. Play uses energy, and a sleeping pet must be woken before other care. Age tracks time spent visiting and bond counts successful care. Needs freeze when paused, outside the pet screen and while the game is closed; pets never die from offline neglect.

The pet now has a bounded picture box, with reserved space for its name, stats, reactions and controls. Complete incoming sprite frames fit inside the box, including their one-pixel movement. Small frames enlarge only by whole-number factors. Oversized frames sample the source with a uniform whole-number stride (every second/third/etc. pixel) and then draw at 1x, so they fit without fractional stretching or uneven scaling between axes. A scissor boundary protects the surrounding UI. Shared animated images stay live, and nearest filtering applies throughout.

B/Start/Select opens Resume, New Pet or Back to Games. New Pet requires A confirmation (B keeps your current pet), then replaces the saved pet with a new random adoption. If its species is removed by a mod change, a new supported species is adopted on the next visit. Care saves immediately, every fifteen active seconds and when pausing/exiting. A visible `SAVE FAILED - SESSION ONLY` notice appears if durable storage is unavailable. No generic pet replaces Pokemon art; pending sprite loads show a loading label.

## Display and engine adapters

Native 160x144 and 240x160 layouts. Card sprites are drawn at uniform integer factors: 1x (16x24) on Gen 1/2, 2x (32x48) on Gen 3. All textures and the presentation canvas use nearest filtering. Flips crop a central sprite strip instead of stretching it; moving cards, particles, tiles and falling blocks snap to integer coordinates. Missing sprites use procedural pixel cards. The games use a native-size canvas and whole physical-pixel window scaling, with black letterboxing, independent of the engine fill setting. High-DPI origins are pixel-aligned; a window smaller than the native game surface crops rather than fractional-scales it. Controls only use abstract input actions (`wasPressed` and `isDown`).

The public `ui.pc.items` hook covers Gen 1/2 direct PCs. Engine adapters cover the Gen 1 bedroom constructor, Gen 2 hub/item dispatch, and Gen 3 root and bedroom menus/modal stack. Built-in Gen 3 script result indexes stay unchanged. `engine_internals` permission is required for menus without a public hub hook.

## Validation

Run with Python and `lupa` installed:

    python tests/run.py /path/to/gen1recomp-0.3.54

Tests run against engines 0.3.54 and 0.3.58, plus manifest validation including the exact GitHub update source. The additional rules suite covers 100 shuffled Blackjack decks, Collapse clearing/gravity, 100 Minesweeper fields with adjacent counts and safe first neighborhoods, chord wins/losses, pet need changes, save/reopen and adoption confirmation. Sprite/cry-provider fixtures verify live style changes and extended species in all three generations; care controls verify successful and rejected actions and graceful audio failure. Pet viewport checks cover wide/tall frames through 513x511, whole-number geometry, motion bounds, cached sampling meshes and scissor restoration. Pixel checks also exercise 184 full-game frames, 910 sprite draws, and eight window/DPI layouts. Tests cover the existing game rules, animations, pause/resume, retry and submenu navigation. The native-menu integration suite tours all seven games and returns to the same PC across all eleven game IDs. ROM text/font/chrome, species rosters and graphics/audio are fixture substitutes, not eleven ROM-backed playthroughs.

Real LOVE renders at both native resolutions cover the updated submenu, Minesweeper and PokePet (using a G9 Gen3 sprite supplied by 1025Dex), alongside the existing game and animation previews. A GPU containment probe compares 289,080 pixels outside the pet box with and without standard/oversized moving artwork to ensure surrounding UI remains untouched. Animated previews are in `docs/effects-160.gif` and `docs/effects-240.gif`. The full game surface retains whole physical-pixel window scaling.

Card faces are extracted from the user-provided `Poker cards 1.3.zip`. No author/license document accompanied it. The patterned back and procedural fallback are original. See `ASSET_CREDITS.md`.

The update source in `manifest.json` is `"github": "Bentley734/PC-Solitaire"`.

Games appears directly above Log Off in PC hubs; native script Log Off results are preserved.
