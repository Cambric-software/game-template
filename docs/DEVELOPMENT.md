# Development Guide

## Workflow

```
setup → configure → run → develop → test → build → release
```

## Running the game

```bash
dart run scripts/cambric.dart run          # Windows (default)
dart run scripts/cambric.dart run android  # Android device
```

## Adding a scene

1. Create a class extending `CambricScene` in `lib/gameplay/scenes/`
2. Override `sceneName`, `onSceneLoad()`, `onSceneResize()`, `onInputAction()`
3. Register in `bootstrap_service.dart`: `game.sceneManager.register('name', () => MyScene())`
4. Navigate: `await game.sceneManager.transitionTo('name')`

Scene lifecycle order: `onSceneLoad → onSceneActivate → [update frames] → onSceneDeactivate → onSceneDispose`

## Adding an entity

Extend `GameEntity` (for physics/components) or plain `PositionComponent`:

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

In `lib/game/input/input_action.dart`, add your action:

```dart
enum InputAction {
  // ... existing ...
  shoot,
  reload,
}
```

Add bindings in `kDefaultKeyBindings`:

```dart
InputAction.shoot: [KeyBinding(LogicalKeyboardKey.keyX)],
```

## Adding audio

```dart
// In a scene or entity:
final audio = AudioSystem();
await audio.playMusic('theme.mp3');
await audio.playSfx('jump.wav');
```

Audio files go in `game/assets/audio/music/` and `game/assets/audio/sfx/`. Declare them in `pubspec.yaml` under `flutter.assets`.

## Responding to game state

```dart
game.stateManager.addListener((from, to) {
  if (to == GameState.paused) {
    // pause your animations
  }
});
```

## Using the timer system

```dart
final timers = TimerSystem();

// One-shot
timers.after(3.0, () => spawnEnemy());

// Repeating
timers.every(0.5, () => spawnParticle());

// In update():
timers.update(dt);
```

## Using the event bus

```dart
// Subscribe
EventBus().subscribe<EntityDiedEvent>((e) {
  print('Entity died: ${e.entityId}');
});

// Publish
EventBus().publish(EntityDiedEvent('player-123'));
```

## Debug overlay

Press **F1** during a development build to cycle: hidden → minimal (FPS) → full (FPS + scene + input).

The overlay is only added in debug builds (`kDebugMode = true`). It cannot appear in release builds.

## Running tests

```bash
dart run scripts/cambric.dart test
# or
cd game && flutter test
```

## Asset validation

```bash
dart run scripts/cambric.dart assets validate
```

Reports any assets declared in `pubspec.yaml` that are missing on disk.
