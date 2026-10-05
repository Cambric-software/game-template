# Technology Decision

> Decision date: 2026-10-04
> Template: Cambric Game Template

---

## Decision

**Flutter 3.47.2 + Flame 1.x**

---

## Candidates Evaluated

| Framework | Android | Windows | Linux | 2D | Notes |
|---|---|---|---|---|---|
| Flutter + Flame | ✅ | ✅ | ✅ | ✅ | Single codebase, Dart, pub.dev ecosystem |
| Godot (GDScript/C#) | ✅ | ✅ | ✅ | ✅ | Excellent 2D, but separate language/toolchain from Cambric app stack |
| Unity | ✅ | ✅ | ✅ | ✅ | Heavy, licensing concerns, not local-first-friendly, C# diverges from Dart stack |
| Bevy (Rust) | ⚠️ | ✅ | ✅ | ✅ | Rust not installed; steep learning curve; Android support less mature |
| Pygame (Python) | ❌ | ✅ | ✅ | ✅ | No Android; Python available but not suitable for mobile |
| Love2D (Lua) | ❌ | ✅ | ✅ | ✅ | No Android |
| LibGDX (Java/Kotlin) | ✅ | ✅ | ✅ | ✅ | Java/Kotlin; no Dart; extra toolchain; Kotlin not installed |

---

## Why Flutter + Flame

### 1. Single language and toolchain
Dart 3.13.2 and Flutter 3.47.2 are already installed and fully operational. No additional SDK installation is required. All Cambric infrastructure (config, logging, storage, updates, localization) is already written in Dart.

### 2. Genuine Android + Windows + Linux support
Flutter targets Android, Windows, and Linux from a single codebase. This exactly matches Cambric's requirements. Linux builds are produced via CI even when the local machine is Windows-only.

### 3. Flame is purpose-built for 2D games on Flutter
Flame provides:
- Game loop with delta time
- Scene/component architecture
- Input handling (keyboard, mouse, touch, gamepad)
- Sprite and sprite sheet support
- Frame animation
- Physics (via flame_forge2d)
- Collision detection (built-in)
- Camera system
- Particles
- Audio (via flame_audio / audioplayers)
- Tiled map support (via flame_tiled)

### 4. Resource-conscious
Flame is lightweight. It runs the game loop inside a Flutter widget, meaning game and UI share the same rendering pipeline. No duplicate native runtimes.

### 5. Testable
Flame components are Dart classes. Unit tests do not require a running engine. Deterministic game logic can be tested via plain Dart tests.

### 6. Cambric ecosystem alignment
All existing Cambric infrastructure (services, configuration, diagnostics, storage, updates) is Dart/Flutter. Reusing the same language and pub.dev packages avoids maintaining two separate technology stacks.

### 7. Community and ecosystem
Flame has an active community, regular releases, and good documentation. It is the de facto standard 2D game framework for Flutter.

---

## What Flame Does NOT Provide (and how we handle it)

| Gap | Approach |
|---|---|
| 3D rendering | Out of scope for this template. Document as extension point. |
| Multiplayer networking | Optional module. Template remains offline-capable. |
| Cloud saves | Optional module. Template is local-first. |
| Advanced shader effects | Flutter's own shader pipeline can be used; documented as extension point. |
| Console platforms | Not a Cambric target. |

---

## Dependency Strategy

| Package | Purpose | Justification |
|---|---|---|
| `flame` | Game engine | Core decision |
| `flame_audio` | Audio via audioplayers | Avoids duplicating audio abstraction |
| `path_provider` | Platform-correct file paths | Already in pub cache; standard |
| `shared_preferences` | Settings persistence | Already in pub cache; standard |
| `crypto` | Checksums for saves/updates | Already in pub cache; standard |
| `logging` | Structured logging | Already in pub cache; standard Dart package |
| `intl` | Localization + RTL | Already in pub cache; standard |
| `args` | CLI tool argument parsing | Already in pub cache; standard |
| `uuid` | Save slot and entity IDs | Already in pub cache |
| `http` | Update check / release discovery | Already in pub cache; standard |
| `archive` | Update package extraction | Already in pub cache |
| `flutter_lints` | Analysis rules | Standard Flutter linting |

Packages that will NOT be added unless genuinely needed:
- Firebase (no mandatory cloud backend)
- Any analytics SDK
- Any advertising SDK
- Any AI SDK
- Any remote telemetry package

---

## Architecture Boundary

Flame is used **behind a clean Cambric abstraction**. Game code never calls raw Flame APIs where a Cambric wrapper exists. This means:

- Replacing the rendering engine later requires only changing the wrappers, not all game code
- Cambric infrastructure (config, storage, logging) has no dependency on Flame at all
- Flame has no dependency on Cambric infrastructure

This is enforced by the layer structure defined in ARCHITECTURE.md.
