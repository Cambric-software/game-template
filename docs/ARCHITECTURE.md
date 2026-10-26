# Architecture

The template separates reusable Cambric infrastructure, a small Flame runtime,
replaceable gameplay content, and a Flutter interface. The split exists so a
game developer can replace `lib/gameplay/` without touching services, and so
services can be tested without a renderer.

---

## 1. Layers

```
┌────────────────────────────────────────────────────────┐
│ Flutter interface (lib/ui/)                            │
│ menus, settings, saves, pause, theme, dialogs          │
├────────────────────────────────────────────────────────┤
│ Bootstrap + game content (lib/bootstrap/, lib/gameplay/)│
│ startup order, scenes, entities, sessions              │
├────────────────────────────────────────────────────────┤
│ Cambric runtime (lib/game/)                            │
│ Flame wrappers, scenes, input, audio, debug            │
├───────────────────────┬────────────────────────────────┤
│ Cambric core          │ Flame                          │
│ config, storage,      │ rendering, components,         │
│ logging, security,    │ raw input, audio               │
│ localization, updates │                                │
├───────────────────────┴────────────────────────────────┤
│ Flutter platform layer                                 │
│ Android, Windows, Linux                                │
└────────────────────────────────────────────────────────┘
```

Rules:

- `lib/core/` does not import Flame or game content.
- `lib/game/` may import Flame and Cambric core, never a concrete scene.
- `lib/gameplay/` may import Cambric runtime, core services, and theme tokens.
- `lib/ui/` talks to the runtime through `CambricGame` and to services through
  `BootstrapService`.
- Gameplay never calls a platform file API directly; it goes through
  `StorageService` / `SaveService`.

The boundaries are enforced by review, not by a build plugin. `flutter analyze`
catches unused and missing imports, not a wrong-direction dependency.

---

## 2. Boot Sequence

`main.dart` only calls `WidgetsFlutterBinding.ensureInitialized()`, awaits
`BootstrapService.initialize()`, and runs `CambricApp`.

`BootstrapService.initialize()` runs once, in this order:

1. Feature flags
2. Logging
3. Configuration from `assets/cambric.manifest.json`
4. `GameIdentity`
5. `SettingsService` (SharedPreferences)
6. `LocalizationService` (English or Arabic)
7. `SaveService` (data directory, checksum, migration)
8. `AutosaveService`
9. `CambricGame` constructor
10. Scene registration: `mainMenu`, `gameplay`
11. Autosave shutdown listener for menu and exit states

Two ordering details matter:

- `SceneManager` is created in the `CambricGame` constructor. Scenes can be
  registered before the `GameWidget` mounts.
- `BootstrapService.startGameplay()` awaits `CambricGame.whenLoaded` before it
  transitions scenes, so a fast tap cannot race Flame's first frame.

Calling `initialize()` twice throws. Tests instantiate the pieces they need
instead of booting the whole application.

---

## 3. Runtime Flow

`CambricApp` builds one persistent `GameWidget<CambricGame>` and layers Flutter
screens above it.

```
Scaffold
 ├─ GameWidget (mounted for the app lifetime, never rebuilt)
 │   └─ Flame canvas + pause overlay
 ├─ MainMenuScreen      when screen == menu
 ├─ SaveSlotsScreen     when screen == saves
 ├─ SettingsScreen      when screen == settings
 └─ loading cover       while a session starts
```

`TickerMode` disables the game ticker while the menu or settings are visible,
so a hidden canvas does not burn frames. Returning to gameplay does not reload
scenes or assets.

The Flame canvas is not used for menu text. Menus are Flutter because they need
focus, semantics, text scaling, and RTL layout.

---

## 4. State Machine

`GameStateManager` validates transitions but logs unexpected ones instead of
crashing.

```
boot -> loading -> mainMenu -> playing <-> paused
                                  |
                                  +-> gameOver / victory -> mainMenu
```

Also allowed: `mainMenu -> settings/credits/exiting`, `paused -> mainMenu`,
and `playing -> loading` for scene transitions.

`CambricGame.pause()` only acts while `playing`. It transitions to `paused`,
pauses the game clock, pauses audio, and adds the `pause_menu` overlay.
`resume()` returns to `playing`; `leavePause()` releases the overlay without
changing state, which is used when leaving a paused session for the menu.

`update()` skips scene updates and the autosave tick while paused. The debug
overlay and input frame reset still run.

---

## 5. Scenes

A scene is a Flame `World` with its own component tree. `SceneManager` owns one
active scene and one transition at a time.

Lifecycle:

```
load -> activate -> [update while active] -> deactivate -> dispose
```

`CambricScene` exposes `onSceneLoad`, `onSceneActivate`,
`onSceneDeactivate`, `onSceneDispose`, `onInputAction`, and `onSceneResize`.
Game content overrides these, not Flame's raw hooks, so scene cleanup is
consistent.

Template scenes:

- `MainMenuScene` - minimal canvas background and the optional Enter/Space
  shortcut. The real menu is Flutter.
- `GameplayScene` - player square, movement, collision layer, HUD hint.

The demo's save records the active scene and playtime only. It does not
serialise the square's position. `BootstrapService.loadedSave` is exposed so a
real game can restore world state after `GameplayScene` loads.

---

## 6. Entities and Components

`GameEntity` extends Flame's `PositionComponent` and adds:

- a UUID `entityId`
- tags for filtering
- active/inactive state
- a typed named-component map

Lifecycle hooks are `onEntityLoad`, `onEntityActivate`, `onEntityDeactivate`,
and `onEntityDispose`.

Available building blocks include `TransformComponent`,
`PhysicsBodyComponent`, `CollisionComponent`, `HealthComponent`, animation state
machines, particle emitters, and the movement/spawn/timer systems. They are
optional; an entity does not need every component.

---

## 7. Input

```
physical event
  -> CambricGame.onKeyEvent / TouchInputHandler / GamepadState
  -> InputMapper.actionsForKey
  -> InputState (pressed / just pressed / just released)
  -> active scene.onInputAction
```

`InputAction` is game-owned. Default bindings live in `kDefaultKeyBindings`;
`InputMapper.applyCustomBindings` merges player overrides.
`SettingsService.getInputBindings` and `saveInputBindings` persist a map, but
the template does not include a remapping screen.

Touch input maps taps and drags to actions through `TouchInputHandler`.
Gamepad state is exposed as an abstraction; the template does not ship a
platform gamepad driver.

---

## 8. Audio

All audio goes through `AudioSystem` (Flame Audio / audioplayers). Game code
calls `playMusic`, `playSfx`, volume, and mute methods on that wrapper. Pause
and resume are handled by the runtime. Direct plugin calls outside
`AudioSystem` are a boundary violation.

`GameSettingsContent` applies volume changes on slider release so dragging does
not restart the current track on every pixel.

---

## 9. Assets

Bundled assets are declared in `game/pubspec.yaml`. The template ships:

```
assets/cambric.manifest.json
assets/i18n/en.json
assets/i18n/ar.json
```

Images, sprites, music, sound effects, and fonts are added by the game. The
`assets validate` CLI command reports files declared in `pubspec.yaml` that do
not exist. Scene loaders should unload scene-specific assets in
`onSceneDispose`; shared UI assets stay loaded.

Downloaded content is not part of the template. If added, keep it under the
Cambric data directory and never mix it with bundled assets.

---

## 10. Storage and Saves

```
Cambric data root (path_provider, app documents)
 └── Games/<gameId>/
      └── saves/<slot>.sav (+ .bak)
```

`PlatformService` also exposes helpers for `settings/`, `cache/`, `logs/`,
`backups/`, and `updates/`; the template only creates `saves/` by default.
Settings use SharedPreferences, not a file in the data directory.

`StorageService` owns atomic file primitives. `SecurityService` verifies
checksums and rejects traversal paths. `SaveService` writes to a temporary
file, reads it back, renames it over the slot, and keeps the previous file as
`.bak`. Loading verifies the SHA-256 checksum, falls back to the backup, then
runs migrations.

`AutosaveService` saves every five minutes during a session when enabled. It
tracks playtime and exposes it to the pause menu's Save & Quit action.

See [SAVES.md](SAVES.md) for the format and migration steps.

---

## 11. Localization

`LocalizationService` loads one locale at a time and caches parsed maps. The
first load reads the asset; switching back is immediate.

```
assets/i18n/en.json  ─┐
assets/i18n/ar.json  ─┴─> LocalizationService -> t(key)
                                        -> textDirection -> Directionality
```

Every visible string goes through `t()`. Arabic sets `TextDirection.rtl` at the
`MaterialApp` builder, and layouts use directional spacing and alignment.
Numbers remain LTR.

The locale files are also the source for widget-test strings; tests load a
locale before pumping a screen.

---

## 12. UI Architecture

The UI is a small state machine in `CambricApp` (`menu`, `saves`, `settings`,
`game`). It is deliberately not a router: the game has one back stack depth and
explicit transitions.

- Theme mode comes from `SettingsService.uiTheme` and is applied to
  `MaterialApp` immediately.
- Language changes reload `LocalizationService`, save the choice, and rebuild.
- Save availability is refreshed when returning to the menu, so a newly
  created save enables Continue.
- A start failure returns to the menu and shows a message dialog.

Theme values and component rules are documented in [DESIGN.md](DESIGN.md).

---

## 13. Debug and Release

`FeatureFlags.debugOverlay` is only enabled in debug builds. The overlay
renders FPS, active scene, entity count, and pressed actions, and cycles with
F1. Hitbox visualisation is a separate debug component.

Release builds compile without the overlay path being reachable. No analytics,
ads, telemetry, or hidden network calls are included.

---

## 14. Testing

| Area | Tests |
|---|---|
| Core config, security, version | Unit |
| Clock, events, input, state machine | Unit |
| Save data, service, autosave | Unit with temp directories |
| Runtime construction | Unit |
| Main menu, saves, settings | Widget tests |
| Theme and Arabic/RTL | Widget tests |

Widget tests use `test/helpers/ui_harness.dart` for a fixed surface size and a
locale. Screens that need persistence accept injectable loaders, or use
`SharedPreferences.setMockInitialValues`.

Tests run with `flutter test`; CI runs analyze, tests, and all three platform
builds.

---

## 15. Design Decisions

**Flutter menus over a persistent Flame canvas.** Menus need semantics, focus,
text scaling, and RTL. Recreating those on a canvas wastes time and excludes
screen readers. The canvas stays mounted so returning to a session is instant.

**A single active scene.** The template is not an open-world streaming engine.
One active world keeps lifecycle and asset ownership unambiguous. Games that
need additive scenes can compose worlds inside `GameplayScene`.

**JSON saves.** Saves are small structured documents. JSON is debuggable,
versionable, and needs no database dependency. Checksums and backups provide
corruption protection.

**One palette for app, web, and games.** A player should see the same Cambric
family across products. Token changes are made in all templates in the same
pass, not patched per product.

**Linux builds in CI.** The development host is Windows. Building Linux on
`ubuntu-latest` avoids requiring WSL2 and gives a clean, reproducible result.
