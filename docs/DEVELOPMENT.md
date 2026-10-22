# Development Guide

## Workflow

```
setup -> configure -> run -> develop -> test -> build -> release
```

## Commands

```bash
dart run scripts/cambric.dart doctor           # check the toolchain
dart run scripts/cambric.dart setup            # identity and feature wizard
dart run scripts/cambric.dart run              # run on Windows
dart run scripts/cambric.dart run android      # run on a connected device
dart run scripts/cambric.dart test             # unit and widget tests
dart run scripts/cambric.dart build windows    # release build
dart run scripts/cambric.dart install windows  # install wizard
dart run scripts/cambric.dart assets validate  # declared vs existing assets
dart run scripts/cambric.dart diagnose         # write a diagnostic report
dart run scripts/cambric.dart clean            # remove build output
dart run scripts/cambric.dart scene LevelOne   # generate a scene
dart run scripts/cambric.dart entity Player    # generate an entity
dart run scripts/cambric.dart release 1.2.0    # bump manifest and pubspec
dart run scripts/cambric.dart update check     # check GitHub releases
```

Run `dart run scripts/cambric.dart --help` for the full command list, including
scene, entity, changelog, and save inspection commands.

## Running the game

```bash
dart run scripts/cambric.dart run          # Windows (default)
dart run scripts/cambric.dart run android  # Android device
```

Or use Flutter directly:

```bash
cd game
flutter run -d windows
```

## Adding a scene

1. Create a class extending `CambricScene` in `lib/gameplay/scenes/`.
2. Override `sceneName`, `onSceneLoad`, `onSceneResize`, `onInputAction`.
3. Register it in `bootstrap_service.dart`:
   `game.sceneManager.register('name', () => MyScene())`.
4. Navigate with `await game.sceneManager.transitionTo('name')`.

Lifecycle order:
`onSceneLoad -> onSceneActivate -> [update frames] -> onSceneDeactivate -> onSceneDispose`

The template registers `mainMenu` and `gameplay`. The Flutter menu is visible
without loading `mainMenu`; `returnToMenu` loads it behind the menu on exit.

## Adding an entity

Extend `GameEntity` for IDs, tags, and component data:

```dart
class PlayerEntity extends GameEntity {
  PlayerEntity() : super(tags: {'player'}, size: Vector2(32, 48));

  @override
  Future<void> onEntityLoad() async {
    setComponent('health', HealthComponent(maxHp: 100));
  }

  @override
  void update(double dt) {
    super.update(dt);
    final body = getComponent<PhysicsBodyComponent>('body');
    body?.integrate(position, dt);
  }
}
```

## Adding input bindings

Add an action in `lib/game/input/input_action.dart`:

```dart
enum InputAction {
  // ... existing values ...
  shoot,
  reload,
}
```

Then add it to `kDefaultKeyBindings`:

```dart
InputAction.shoot: [KeyBinding(LogicalKeyboardKey.keyX)],
```

`CambricGame.onKeyEvent` maps keys to actions, updates `InputState`, and sends
the action to the active scene. Player overrides can be applied with
`InputMapper.applyCustomBindings`; `SettingsService.saveInputBindings` persists
a string map. A remapping screen is not included.

## Adding audio

```dart
final audio = AudioSystem();
await audio.playMusic('theme.mp3');
await audio.playSfx('jump.wav');
```

Audio files are not created by the template. Add the folders you need under
`game/assets/` (for example `audio/music/` and `audio/sfx/`) and declare them in
`pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/cambric.manifest.json
    - assets/i18n/en.json
    - assets/i18n/ar.json
    - assets/audio/music/
    - assets/audio/sfx/
```

Run `dart run scripts/cambric.dart assets validate` after changing the list.
The audio slider applies volume on release, so it does not restart a track while
the player drags.

## Adding a UI screen

Read [DESIGN.md](DESIGN.md) first. In short:

1. Use `GamePage` or `GameBackdrop` for the surface.
2. Read colours with `context.palette` and sizes with `GameSpacing`,
   `GameRadii`, and `GameSizes`. Do not hardcode values.
3. Add every string to `assets/i18n/en.json` and `assets/i18n/ar.json`.
4. Add the route to the `_AppScreen` switch in `lib/ui/cambric_app.dart`.
5. Add a widget test at desktop and phone width, plus Arabic/RTL.

An app-level screen is a Flutter widget above the persistent `GameWidget`.
Gameplay HUD elements that need game state can use Flame components instead.

## Changing theme or language at runtime

`CambricApp` owns the current `ThemeMode` and passes callbacks to screens:

```dart
_settings.uiTheme = 'light';           // persists
setState(() => _themeMode = ThemeMode.light);

await _l10n.load('ar');                // cached after the first load
_settings.language = 'ar';
setState(() {});
```

`MaterialApp.builder` applies `Directionality` from
`LocalizationService.textDirection`, so RTL is not a per-screen decision.

## Responding to game state

```dart
game.stateManager.addListener((from, to) {
  if (to == GameState.paused) {
    // pause your animations
  }
});
```

Listeners are called synchronously. Keep them short and do not start async work
without a guard.

## Timers

```dart
final timers = TimerSystem();

timers.after(3.0, () => spawnEnemy());
timers.every(0.5, () => spawnParticle());

// In update():
timers.update(dt);
```

## Event bus

```dart
EventBus().subscribe<EntityDiedEvent>((event) {
  print('Entity died: ${event.entityId}');
});

EventBus().publish(EntityDiedEvent('player-123'));
```

## Debug overlay

Press **F1** in a debug build to cycle: hidden -> minimal (FPS) -> full (FPS,
scene, entity count, pressed input). It is compiled out of release builds.

`FeatureFlags.debugOverlay` must be true; this is set by build mode.

## Running tests

```bash
cd game
flutter analyze lib test
flutter test
```

Useful forms while iterating:

```bash
flutter test test/ui/main_menu_test.dart
flutter test test/ui/settings_test.dart --plain-name "persist theme"
```

Widget tests use fake async. Do real file or plugin I/O outside a
`testWidgets` body, or inject a loader. Tests that do pump a screen should use
`test/helpers/ui_harness.dart` for a fixed surface and loaded locale.

If `flutter test` fails while deleting `build/unit_test_assets`, another
Flutter process is holding the folder. Close it, wait, delete `build/`, retry.

## Save changes

See [SAVES.md](SAVES.md) before changing `SaveData`. Every format change needs a
migration and a test that loads the previous version.

## Build and release

See [BUILDING.md](BUILDING.md). A release tag (`v1.2.3`) runs analyze and tests,
builds all three platforms, writes SHA-256 files, and publishes the GitHub
Release.
