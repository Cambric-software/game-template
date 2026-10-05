# Cambric Game Template — Architecture

> Version: 0.1.0
> Framework: Flutter 3.47.2 + Flame 1.x
> Platforms: Android, Windows, Linux

---

## 1. Layer Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Game Content Layer                   │
│         (scenes, entities, gameplay logic)              │
├─────────────────────────────────────────────────────────┤
│                   Game Systems Layer                    │
│   (input, assets, animation, physics, audio, camera)   │
├─────────────────────────────────────────────────────────┤
│                  Game Runtime Layer                     │
│       (game loop, state machine, scene manager)        │
├──────────────────────┬──────────────────────────────────┤
│   Cambric Core       │   Flame Engine Boundary          │
│   (config, logging,  │   (rendering, input raw,         │
│    storage, updates, │    audio raw, physics raw)       │
│    security, i18n)   │                                  │
├──────────────────────┴──────────────────────────────────┤
│              Flutter Platform Layer                     │
│        (Android, Windows, Linux, platform APIs)        │
└─────────────────────────────────────────────────────────┘
```

The critical rule: **each layer only depends on layers below it**. Game content never imports directly from Flame. Flame never imports Cambric infrastructure. Cambric infrastructure never imports game content.

---

## 2. Framework Boundary

Flame is used **behind explicit Cambric wrappers**. The boundary is enforced by:

- `lib/game/runtime/` — wraps Flame's `FlameGame` and `Component` APIs
- `lib/game/input/` — wraps Flame's `KeyboardHandler`, `TapCallbacks`, `DragCallbacks`
- `lib/game/audio/` — wraps `FlameAudio`
- `lib/game/physics/` — wraps Flame's built-in collision and (optionally) `flame_forge2d`

If the game framework is ever replaced, only these wrapper files change. All game content and Cambric infrastructure remain untouched.

---

## 3. Directory Structure

```
game-template/
│
├── .github/
│   └── workflows/
│       ├── analyze.yml
│       ├── test.yml
│       ├── build.yml
│       ├── security.yml
│       └── release.yml
│
├── docs/
│   ├── ENVIRONMENT_AUDIT.md
│   ├── TECHNOLOGY_DECISION.md
│   ├── ARCHITECTURE.md          ← this file
│   ├── GETTING_STARTED.md
│   ├── DEVELOPMENT.md
│   ├── GAMEPLAY.md
│   ├── ASSETS.md
│   ├── INPUT.md
│   ├── AUDIO.md
│   ├── SAVES.md
│   ├── LOCALIZATION.md
│   ├── CONFIGURATION.md
│   ├── TESTING.md
│   ├── DEBUGGING.md
│   ├── PERFORMANCE.md
│   ├── BUILDING.md
│   ├── RELEASING.md
│   ├── UPDATES.md
│   ├── TROUBLESHOOTING.md
│   ├── SECURITY.md
│   └── ECOSYSTEM.md
│
├── .template/
│   ├── setup/                   ← wizard templates
│   └── config/                  ← wizard defaults
│
├── game/                        ← Flutter + Flame project root
│   ├── android/
│   ├── linux/
│   ├── windows/
│   │
│   ├── assets/
│   │   ├── audio/
│   │   │   ├── music/
│   │   │   └── sfx/
│   │   ├── images/
│   │   ├── sprites/
│   │   ├── fonts/
│   │   └── i18n/
│   │       ├── en.json
│   │       └── ar.json
│   │
│   ├── lib/
│   │   ├── main.dart            ← entry point
│   │   │
│   │   ├── core/                ← CAMBRIC INFRASTRUCTURE
│   │   │   ├── config/
│   │   │   ├── identity/
│   │   │   ├── lifecycle/
│   │   │   ├── platform/
│   │   │   ├── storage/
│   │   │   ├── cache/
│   │   │   ├── security/
│   │   │   ├── logging/
│   │   │   ├── diagnostics/
│   │   │   ├── localization/
│   │   │   ├── updates/
│   │   │   ├── backup/
│   │   │   ├── ecosystem/
│   │   │   └── features/
│   │   │
│   │   ├── game/                ← GAME RUNTIME (wraps Flame)
│   │   │   ├── runtime/
│   │   │   ├── loop/
│   │   │   ├── state/
│   │   │   ├── scenes/
│   │   │   ├── entities/
│   │   │   ├── components/
│   │   │   ├── systems/
│   │   │   ├── input/
│   │   │   ├── assets/
│   │   │   ├── animation/
│   │   │   ├── physics/
│   │   │   ├── collision/
│   │   │   ├── camera/
│   │   │   ├── audio/
│   │   │   ├── particles/
│   │   │   └── debug/
│   │   │
│   │   ├── gameplay/            ← GAME CONTENT (replaceable)
│   │   │   ├── scenes/
│   │   │   ├── entities/
│   │   │   └── systems/
│   │   │
│   │   ├── ui/                  ← GAME UI
│   │   │   ├── menus/
│   │   │   ├── hud/
│   │   │   └── overlays/
│   │   │
│   │   ├── save/                ← SAVE SYSTEM
│   │   ├── settings/            ← SETTINGS
│   │   ├── localization/        ← LOCALIZATION RUNTIME
│   │   └── bootstrap/           ← STARTUP SEQUENCE
│   │
│   ├── test/
│   │   ├── core/
│   │   ├── game/
│   │   ├── save/
│   │   ├── input/
│   │   └── fixtures/
│   │
│   └── pubspec.yaml
│
├── scripts/
│   └── cambric.dart             ← Developer CLI
│
├── cambric.manifest.json        ← Game identity manifest
├── .gitignore
├── README.md
├── LICENSE
└── SECURITY.md
```

---

## 4. Game Loop Architecture

The game loop is owned by Flame's `FlameGame`. Cambric wraps it in `CambricGame`:

```
Platform event → FlameGame.update(dt)
                      ↓
              CambricGame.onUpdate(dt)
                      ↓
         ┌────────────┴────────────┐
         ↓                         ↓
  SceneManager.update(dt)    SystemsManager.update(dt)
         ↓                         ↓
  ActiveScene.update(dt)     [InputSystem, PhysicsSystem,
         ↓                    AnimationSystem, AudioSystem,
  Entity.update(dt) ×N        CameraSystem, ParticleSystem]
```

**Delta time** is passed from Flame directly. Frame-independent movement uses `dt` everywhere.

**Fixed timestep** for physics: Flame supports `FixedTimestepGame`. Physics accumulator pattern used inside `PhysicsSystem`.

**Pause**: `CambricGame` maintains a `GameState`. When `GameState.paused`, `update()` is skipped for gameplay systems but UI systems remain active.

---

## 5. Game State Machine

```dart
enum GameState {
  boot,        // initial startup, platform init
  loading,     // asset loading, configuration
  mainMenu,    // main menu active
  playing,     // gameplay active
  paused,      // gameplay paused, UI active
  gameOver,    // game over state
  victory,     // victory/level complete state
  settings,    // settings overlay
  credits,     // credits screen
  exiting,     // clean shutdown sequence
}
```

State transitions are managed by `GameStateManager`. Game content can define additional states by extending with custom scene routing — the state machine is not sealed.

**Transitions**:
```
boot → loading → mainMenu → playing ⇄ paused
                                  ↓
                              gameOver / victory → mainMenu
```

---

## 6. Scene Architecture

A scene owns a logical game area. Scenes correspond to Flame `World` instances, each with their own component tree.

**Scene lifecycle**:
```
SceneManager.load(SceneId)
      ↓
Scene.onLoad()          ← load assets, initialize systems
      ↓
Scene.onMount()         ← add to game world
      ↓
Scene.onActivate()      ← begin updates
      ↓
[running: update() every frame]
      ↓
Scene.onDeactivate()    ← stop updates
      ↓
Scene.onUnmount()       ← remove from world
      ↓
Scene.onDispose()       ← release all resources
```

**Built-in scenes** (template starting point):
- `BootScene` — splash/initialization
- `MainMenuScene` — main menu
- `GameplayScene` — placeholder gameplay area
- `PauseOverlay` — rendered on top of GameplayScene
- `SettingsScene` — settings screen
- `LoadingScene` — asset loading progress

**Custom scenes** (added by game developers) live in `lib/gameplay/scenes/`.

---

## 7. Entity Architecture

Entities are Flame `Component` subclasses that carry named component data.

```
GameEntity (extends PositionComponent)
 ├── TransformComponent   (position, rotation, scale)
 ├── SpriteComponent      (sprite/spritesheet reference)
 ├── AnimationComponent   (animation state machine)
 ├── ColliderComponent    (hitbox shape + layer mask)
 ├── PhysicsBodyComponent (velocity, mass, gravity flag)
 ├── AudioEmitterComponent (positional audio)
 └── [custom components]
```

Components are optional and added at construction time. The entity system avoids requiring every entity to carry every component.

**Entity lifecycle**: `create → initialize → activate → update → deactivate → destroy → dispose`

---

## 8. Systems Architecture

Systems operate on all entities that possess a required component set:

| System | Required Components | Responsibility |
|---|---|---|
| `InputSystem` | — | Translates raw input → `InputAction` events |
| `MovementSystem` | Transform, PhysicsBody | Applies velocity to position |
| `AnimationSystem` | Sprite, Animation | Advances animation frames |
| `CollisionSystem` | Collider | Detects and dispatches collision events |
| `CameraSystem` | — | Manages camera follow, bounds, shake |
| `AudioSystem` | — | Manages music, SFX, volume, pause |
| `ParticleSystem` | — | Manages particle emitters |
| `TimerSystem` | — | Manages game-time and real-time timers |

---

## 9. Input Pipeline

```
Physical device event (key/mouse/touch/gamepad)
              ↓
    Flame input handler (KeyboardHandler etc.)
              ↓
      InputSystem.processRaw(event)
              ↓
    InputMapper.toAction(event) → InputAction
              ↓
       event bus → game logic consumers
```

**Input actions** are defined by the game, not the framework:
```dart
enum InputAction {
  moveLeft, moveRight, moveUp, moveDown,
  jump, attack, interact, pause,
  confirm, cancel,
  // ... game-specific
}
```

**Input mappings** are stored in `InputBindings` and persisted locally. Players can remap controls.

---

## 10. Asset Pipeline

```
Asset file on disk / bundled
          ↓
   AssetLoader.load(AssetId)
          ↓
   CacheLayer (memory cache)
          ↓
   Asset returned to consumer
```

Asset types: images, sprites, sprite sheets, audio, fonts, JSON data, localization strings, tile maps.

**Lifecycle**: Assets are loaded per-scene. When a scene unloads, its assets are released unless flagged as shared/persistent.

**Bundled vs downloaded**: Bundled assets live in `assets/`. Downloaded optional content lives in the Cambric data directory and is never mixed with bundled assets.

---

## 11. Rendering Boundary

Rendering is handled entirely by Flame's `FlameGame` rendering pipeline via Flutter's `Canvas`. Cambric does not directly call `Canvas` methods. The rendering boundary is:

- **Cambric side**: tells scene/entity components what to show (sprite ID, animation frame, visibility)
- **Flame side**: renders it

HUD and menus use Flutter widget overlays on top of the Flame canvas where complex layout is needed.

---

## 12. Physics Boundary

Cambric provides `PhysicsSystem` which uses Flame's built-in collision detection for simple cases. For complex physics, `flame_forge2d` (Box2D wrapper) can be enabled per-scene via configuration.

The physics boundary:
- Game entities do not call Box2D APIs directly
- `PhysicsBodyComponent` exposes velocity, mass, gravity
- `PhysicsSystem` translates these to the underlying engine

---

## 13. Audio Boundary

All audio goes through `AudioSystem` → `FlameAudio` → `audioplayers`. Game code calls:
```dart
audioSystem.playMusic('theme.mp3');
audioSystem.playSfx('jump.wav');
```

Volume, mute, and pause-awareness are handled by `AudioSystem`. Direct `FlameAudio` calls are forbidden outside `AudioSystem`.

---

## 14. Storage Architecture

```
Cambric Data Root (platform-specific path via path_provider)
  └── Games/
       └── <gameId>/
            ├── saves/
            │   ├── slot_1.sav
            │   ├── slot_1.sav.bak
            │   ├── slot_2.sav
            │   └── autosave.sav
            ├── settings/
            │   └── settings.json
            ├── cache/
            ├── logs/
            ├── backups/
            └── updates/
```

Paths are resolved by `PathService`. Nothing outside `PathService` hardcodes filesystem paths.

---

## 15. Save System

Atomic write pattern:
```
SaveGame data
      ↓
Serialize to JSON
      ↓
Write to .tmp file
      ↓
Checksum verify
      ↓
Rename .tmp → .sav  (atomic on supported FSes)
      ↓
Copy .sav → .bak
```

On load:
```
Read .sav
      ↓
Checksum verify
      ↓
If corrupt → try .bak
      ↓
If still corrupt → report error, do NOT silently discard
```

Save format includes `saveVersion`. Migrations run automatically on load when `saveVersion < currentVersion`.

---

## 16. Update System

```
UpdateCheckService.checkForUpdate()
      ↓
GitHub Releases API (with local cache fallback)
      ↓
VersionComparator.compare(current, latest)
      ↓
If update available → notify user
      ↓
User confirms → UpdateDownloadService.download(artifact)
      ↓
ChecksumService.verify(artifact)
      ↓
UpdateInstallerService.install(artifact)
      ↓
On failure → rollback to previous installation
```

Release metadata is cached locally. If the network is unavailable, the last known metadata is used.

---

## 17. Platform Abstraction

`PlatformService` abstracts OS differences:

| Capability | Windows | Android | Linux |
|---|---|---|---|
| App data path | `%APPDATA%` | Internal storage | `~/.local/share` |
| Temp path | `%TEMP%` | Cache dir | `/tmp` |
| Fullscreen | Window maximize/exclusive | System-managed | Window manager |
| Gamepad | XInput/DirectInput | Android gamepad | evdev |
| Clipboard | win32 | Android clipboard | XClip/Wayland |

Platform-specific code lives only in `lib/core/platform/`. Game logic never calls `Platform.isAndroid` directly.

---

## 18. Localization Architecture

```
LocalizationService.initialize(['en', 'ar'])
      ↓
Loads assets/i18n/en.json, assets/i18n/ar.json
      ↓
L10n.of(context).translate('key')
      ↓
RTL layout automatically applied when locale is Arabic
```

Arabic RTL is handled at the Flutter widget level via `Directionality`. Hardcoded strings in game UI are forbidden — all user-facing text goes through `L10n`.

---

## 19. Cambric Infrastructure vs Game Code

### Cambric Infrastructure (reusable — `lib/core/`)
- ConfigurationService
- VersionService
- LoggingService
- DiagnosticsService
- PathService
- StorageService
- CacheService
- SecurityService
- LocalizationService
- UpdateService
- BackupService
- FeatureFlagService
- EcosystemService

**These have zero dependency on Flame or on any specific game.**

### Game Runtime (game-aware but not game-specific — `lib/game/`)
- CambricGame
- SceneManager
- EntityManager
- InputSystem + InputMapper
- AssetLoader
- AudioSystem
- PhysicsSystem
- CameraSystem
- DebugOverlay

**These depend on Flame but not on specific game content.**

### Game Content (game-specific — `lib/gameplay/`)
- Concrete scenes
- Concrete entities
- Game-specific systems

**These are the parts a game developer replaces.**

---

## 20. Testing Architecture

| Layer | Test type | Runner |
|---|---|---|
| `lib/core/` | Unit tests | `dart test` |
| `lib/game/` | Unit + component tests | `flutter test` |
| `lib/gameplay/` | Unit + widget tests | `flutter test` |
| `lib/save/` | Unit tests (with deterministic clock) | `dart test` |
| Integration | Scene lifecycle, save/load | `flutter test` integration |

Deterministic testing uses:
- `FakeClock` — injectable `DateTime` source
- `FakeRandom` — seeded random number generator
- `FakeInputSource` — programmatic input injection
- In-memory storage replacing real filesystem

---

## 21. Debug vs Production

Feature flags control debug tooling:

```dart
// In development:
FeatureFlags.debugOverlay = true;
FeatureFlags.showHitboxes = true;
FeatureFlags.verboseLogging = true;

// In production (automatically set by build mode):
FeatureFlags.debugOverlay = false;
FeatureFlags.showHitboxes = false;
FeatureFlags.verboseLogging = false;
```

The debug overlay is a Flame component that is only added to the component tree when `FeatureFlags.debugOverlay` is true. It cannot accidentally ship enabled.

---

## 22. Key Design Decisions and Rationale

**Why Flame scenes map to Cambric scenes, not Flutter routes**: Games do not navigate like apps. Scene transitions involve asset loading, entity cleanup, and physics reset. Flutter's `Navigator` is inappropriate here.

**Why saves use JSON not SQLite**: Game saves are small structured documents. JSON is human-readable for debugging, easy to version, and requires no additional dependency. SQLite would add complexity with no benefit at this scale.

**Why audio goes through a wrapper**: `FlameAudio` / `audioplayers` APIs change between versions. One wrapper centralizes all audio behavior including pause-awareness, volume, and cleanup.

**Why the debug overlay is a Flame component, not a Flutter widget**: It needs access to game-internal state (entity count, physics state) that is inside the Flame component tree. A Flutter widget overlay would need to cross the boundary to fetch that data.

**Why Linux builds are CI-only**: The development host is Windows. Rather than require WSL2, Linux builds run on GitHub Actions `ubuntu-latest` which is a clean, reproducible environment.
