# Kanto Gear support (PC Games 1.5.0)

Enable PC Games and Kanto Gear, then restart Recomp. In Kanto Gear's Silph
Store, enable **PC GAMES** and place that one tile on Home. PokePet is the
seventh game inside PC Games; it does not add a separate Store/Home tile.

Kanto Gear must provide `exports.modules.api == 1` (tested with 4.4.1).
That Gear release requires Recomp 0.3.93 or newer. PC Games' ordinary PC
menus continue to support Recomp 0.3.54 and newer without Gear installed.

## Playing below the main game

Opening the Gear tile creates an independent, touch-controlled screen. It
does not push anything onto Pokemon's menu stack or replace its input object.
The physical D-pad, A/B and Start/Select remain available for Pokemon above,
including menus and battles. Only touches inside the lower panel belong to
PC Games. The native touch overlay is fenced out of that panel.

Only tappable labels use larger text: library choices, menu entries, actions,
and the two arcade games' controls. Titles, scores, pet stats and Solitaire's
informational text retain their original size and do not overlap the cards.

- Tap a game in the library to open it, including PokePet.
- Only Snake and Tetris have a touch directional pad and action buttons.
- Solitaire uses taps on stock/cards/destinations, Blackjack uses taps on its
  actions, and Collapse uses taps on groups (tap its footer to raise a row).
- PokePet's Feed, Play, Rest/Wake and Clean actions can also be tapped directly.
- Minesweeper cells can be tapped to reveal; hold a cell for 0.45 seconds and
  release to flag it without revealing it.
- Tap **MENU** in the header and tap a pause-menu entry to select it.
- **X CLOSE** or **BACK TO GEAR** closes the app and returns display ownership.
  Closing, opening the ordinary PC version, or changing games flushes PokePet's
  latest care progress to the same per-playthrough storage used at the PC.

## Displays

In-window Gear modes temporarily use a stacked layout: Pokemon above and
PC Games below. Gear's saved screen size and bottom safe area are respected.
Closing the app restores Gear's original layout and Home screen.

Gear's native separate/secondary output is supported through Recomp's
SecondScreen bridge, including its own touch events. Readback is asynchronous
when the host supports it and otherwise limited to 30 frames per second.
A missing/disconnected secondary display or failed presentation falls back
to the in-window lower panel without discarding the active minigame.

Phone streaming is owned privately by Gear and is not exported by modules API 1.
Phone mode and a handheld-target configuration therefore use the in-window
lower panel while PC Games is open; the original Gear mode resumes afterward.
No custom launcher or changes to Kanto Gear are required.

## Validation

The integration fixtures exercise the unmodified Gear 4.4.1 Store registry,
all eleven edition IDs, all seven games, touch/physical-input separation,
multitouch release/cancellation, pet persistence, display detachment and async
readback. The LOVE GPU fixture installs Gear's actual runtime hook chain with
the native GameViewport, checking 72 moving upper-screen frames while rendering
the library and seven games at landscape, portrait and ultrawide window sizes.
Artwork/audio providers and game scenes in these fixtures are constructed;
this is not a full ROM playthrough or a physical Android display test.

Run the regular tests with `python tests/run.py ENGINE`. For Gear integration,
run `python tests/run_kanto_gear.py ENGINE KANTO_GEAR_REPOSITORY`.
The LOVE fixture in `tests/kanto_gear_gpu` reads `PC_GAMES_SOURCE`,
`PC_GAMES_GEAR`, `PC_GAMES_ENGINE` and `PC_GAMES_OUTPUT` from the environment.

Registration contract: https://github.com/AverageConsumer/kanto-gear/blob/main/DEVELOPMENT.md#third-party-store-modules
