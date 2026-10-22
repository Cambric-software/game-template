# Design System

The game interface is the same Cambric surface language used by the app and web
templates. A player should recognise a Cambric product before reading its name.

All values live in three files:

- `game/lib/ui/theme/game_palette.dart` - colours
- `game/lib/ui/theme/design_tokens.dart` - spacing, radii, sizes
- `game/lib/ui/theme/game_theme.dart` - Material theme built from both

Never hardcode a colour, radius, or spacing value in a screen. If a value is
missing, add a token in the same pass and use it everywhere.

---

## Palette

Dark is the default. Light is a persisted player choice, not a developer flag.

| Token | Dark | Light |
|---|---|---|
| `bg` | `#0E1116` | `#F6F8FC` |
| `surface` | `#161B23` | `#FFFFFF` |
| `raised` | `#1D232D` | `#FAFBFE` |
| `border` | `#262E3A` | `#E2E6EF` |
| `text` | `#EDF0F6` | `#101828` |
| `secondary` | `#A8B2C6` | `#5A6478` |
| `muted` | `#737E92` | `#8A94A6` |
| `primary` | `#7FA8FF` | `#3B6FE0` |
| `onPrimary` | `#071226` | `#FFFFFF` |
| `accent` | `#35D0BC` | `#12A594` |
| `success` | `#43C79A` | `#12855F` |
| `warning` | `#E8A33C` | `#B26A00` |
| `danger` | `#F0736B` | `#C63A34` |

Rules:

- Use `context.palette` to read the active palette.
- Accent is for one emphasis per screen, not decoration.
- `danger` is only for destructive actions and errors.
- Text on a coloured surface uses `onPrimary` (or white on `danger`).
- Do not use opacity to create a new colour unless it is a hover, border, or
  disabled state. Change the token instead.

Readable contrast is required in both themes. `flutter analyze` does not catch
contrast; check the actual screen.

---

## Tokens

Spacing: `2, 4, 8, 12, 16, 24, 32, 48`.

Radii:

| Element | Radius |
|---|---|
| Chip | 6 |
| Input | 8 |
| Button | 11 |
| Card | 14 |
| Panel | 20 |
| Dialog / sheet | 28 |

Sizes:

- Minimum touch target: 48 px.
- Standard button height: 48 px.
- Icon button: 44 px.
- Menu panel: 360 px.
- Reading column: 760 px.
- Content width: 1080 px.
- Dialog width: 460 px.

Breakpoints: compact below 620 px, wide from 940 px.

---

## Surfaces

`GameBackdrop` paints the background, a low-contrast grid, and one accent glow.
It is painted, not an image, so it scales without assets and follows the theme.
Disable the grid with `showGrid: false` for a scene that has its own art.

`GamePage` is the standard page body: safe area, centred, optional scrolling,
and a maximum reading width. Use it for menu, settings, and save screens.

`GamePanel` is an opaque surface card: `surface`, hairline `border`, card radius
14, and a soft shadow. It is never translucent over gameplay.

`GameChip` is a neutral label for versions and engine names. `GameStatusChip`
is a coloured status pill with a dot for save state and capability labels.

---

## Controls

`GameButton` has four variants:

| Variant | Use |
|---|---|
| `primary` | The one forward action on a screen |
| `secondary` | Alternative actions |
| `ghost` | Low-priority or back actions |
| `danger` | Destructive actions only |

Every button is at least 48 px tall. A disabled button must explain why through
the `helper` line; never leave a dead control unexplained.

`GameChoiceGroup` is a segmented choice used for theme and language. Selection
is exposed to screen readers through `Semantics(selected: true)`.

`GameSettingSlider` shows the percentage next to the label and applies audio
changes on release, not on every pixel.

`GameToggleRow` makes the whole row tappable and keeps the switch as a visual
affordance, not the only hit target.

---

## Screens

### Main menu

One panel, one primary action. New Game is primary; Continue is disabled with a
helper when no save exists. Save Files, Settings, and Quit are secondary. The
version and engine are neutral chips, not buttons.

### Save files

Four slots: autosave plus three manual slots. Filled slots show playtime and
updated time, with Continue and Delete. Empty slots show New Game. Delete asks
for confirmation and refreshes the list only after the delete succeeds.

The template does not restore world state. `BootstrapService.loadedSave` is
available so a real game can apply it after the scene loads.

### Settings

Three panels: Audio, Interface, About. Changes save immediately; there is no
Save button. Reset asks for confirmation and restores every value.

### Pause overlay

Pause is a Flutter overlay above the live canvas. Resume, Settings, Save & Quit,
and Quit to Menu are explicit. Save & Quit writes to the active slot. The game
stays paused while settings are open.

### Dialogs

Confirmation dialogs use the panel surface, title 20, body 14, and two actions.
Destructive confirmation puts the dangerous action on the right in LTR and
mirrors under RTL.

---

## Layout and RTL

- Everything is laid out with `start`/`end`, not `left`/`right`.
- Icons that imply direction (back, arrows) mirror in Arabic.
- Text input and mixed English/Arabic content keep the paragraph direction of
  the surrounding locale.
- Numbers and playtime stay LTR even inside an RTL layout.
- The main menu must fit a 390 x 844 phone without overflow and a 1280 x 720
  desktop without stretching. Short screens scroll rather than clip.

## Motion and accessibility

- Transitions are 150-250 ms and never block input.
- `SettingsService.reducedMotion` is available to shorten or skip decorative
  motion. Do not animate the only signal that an action succeeded.
- Every icon-only control has a tooltip.
- Focus order follows visual order. The hidden Flame canvas must not receive
  focus while a Flutter screen is open.
- Text scales with the system setting; panels grow instead of clipping.

---

## Adding a screen

1. Build with `GamePage` or `GameBackdrop` and `GamePanel`.
2. Read colours through `context.palette` and sizes through `GameSpacing`,
   `GameRadii`, and `GameSizes`.
3. Put every visible string in `assets/i18n/en.json` and `ar.json`.
4. Add it to the screen switch in `lib/ui/cambric_app.dart`.
5. Add a widget test for the default, phone width, and Arabic/RTL.
6. Run `flutter analyze lib test` and `flutter test`.

A screen that needs a new token is a design change, not a local exception.
