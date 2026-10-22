# PC Solitaire 1.0.0

Klondike Solitaire for Gen1Recomp Mod API v2, targeting engine 0.3.54 through 0.3.x.

Install: extract the `pc_solitaire` folder into your game's `mods` directory, enable it in the mod manager, and choose SOLITAIRE at a PC. Supports Red, Blue, Yellow, Gold, Silver, Crystal, FireRed, LeafGreen, Ruby, Sapphire, and Emerald. Bedroom PCs are included; Gen 3 bedrooms offer PLAYER PC / SOLITAIRE before their usual menu.

- D-pad: left/right selects a column; down enters the tableau or steps down its face-up cards; up steps toward its first face-up card, then the top row.
- A: draw/recycle stock, pick a card or valid substack, then place it. Double-tap A within 0.35 seconds on a top face-up card to move it to an eligible foundation.
- B: cancel a selection, or open the pause menu with Quit to PC selected. A confirms; B returns to play.
- Start/Select: pause with Resume, New Deal, Draw 1/3 Toggle, Quit to PC.

Rules: alternating-color descending tableau, Kings on empty columns, same-suit ascending foundations from Ace to King, unlimited stock recycling. Changing draw mode keeps the current deal. Exposed cards flip automatically. Foundation cards may return to the tableau. Complete all four foundations to win.

At 160x144 and 240x160, overlap compresses to fit long columns; the footer always identifies the focused card. Sprites use nearest filtering. Missing or invalid sprites use procedural pixel cards. No canvases are allocated by the mod. PC sessions remain open underneath Solitaire; quitting pops only its screen. A deal is temporary and is discarded when you quit Solitaire or start a new deal. Pokemon save data is untouched.

## Validation

`tests/rules.lua`: 8,412 assertions across 100 seeded deals, stock recycling, legal and illegal transfers, flips, foundations and victory.

`tests/integration.lua`: runs against the actual Gen1Recomp 0.3.54 PC modules and both stack types for all eleven game IDs. ROM text/font/chrome and audio/graphics are fixture substitutes. This validates menu injection and return behavior; it is not eleven ROM-backed playthroughs.

`tests/controls.lua`: controller navigation, selection, double-tap, pause, mode toggle and exit.

The screen was also rendered in real LÖVE at both native sizes, with the supplied sprites and procedural fallback. Screenshots are in `docs/`.

Run all tests with Python and `lupa` installed:

    python tests/run.py /path/to/gen1recomp-0.3.54

## Implementation

`main.lua` uses the public `ui.pc.items` hook for Gen 1 and Gen 2 direct PCs. Small engine adapters cover the Gen 1 bedroom constructor, Gen 2 hub/item menu dispatch, and Gen 3 root list, bedroom entry and modal stack. Gen 3 script result indexes for built-in PC entries stay unchanged. Engine internals permission is declared because these menu surfaces do not all expose a public PC hub hook. Controls only read abstract `wasPressed` actions.

Card artwork was extracted from the user-supplied `Poker cards 1.3.zip`, `minicards.png`. No author or license document accompanied that archive. The patterned card back and procedural fallback are original to this mod. See `ASSET_CREDITS.md`.
