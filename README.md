# Cambric Game Template

[![CI](https://github.com/Cambric-software/game-template/actions/workflows/ci.yml/badge.svg)](https://github.com/Cambric-software/game-template/actions/workflows/ci.yml)

A reusable game foundation for Android, Windows, and Linux.  
Built with Flutter and Flame. Maintained by [Cambric](https://cambric.dev).

Supports any game genre: 2D platformer, 3D, top-down, puzzle, RPG, arcade, strategy, racing, horror, shooter, simulation, card/board, and custom.

---

## Platforms

| Platform | Build | Notes |
|---|---|---|
| Windows x64 | ✅ | Visual Studio 2022 required |
| Android APK/AAB | ✅ | Android SDK + Java 17 required |
| Linux x64 | ✅ CI | No local Linux toolchain needed — builds in GitHub Actions |

---

## Quick Start

**Requirements:** Flutter 3.47+, Dart 3.13+, Git

```bash
git clone https://github.com/Cambric-software/game-template my-game
cd my-game

# Configure your game — genre, platforms, input, physics, multiplayer, DLC, monetization
dart run scripts/cambric_setup.dart

# Verify your environment
dart run scripts/cambric.dart doctor

# Run the game
dart run scripts/cambric.dart run
```

After building a release, use the install wizard:

```bash
# Windows
dart run scripts/cambric.dart install windows

# Android (requires connected device)
dart run scripts/cambric.dart install android

# Linux — shows CI download + install instructions
dart run scripts/cambric.dart install linux
```

---

## What You Get

| Feature | Status |
|---|---|
| Game loop (Flame, delta time, pause) | ✅ |
| Scene system (load, transition, dispose) | ✅ |
| Entity system (tags, components, lifecycle) | ✅ |
| MovementSystem (auto-integrates PhysicsBodyComponent) | ✅ |
| SpawnSystem / DespawnSystem | ✅ |
| Input (keyboard, mouse, touch, gamepad abstraction) | ✅ |
| Touch input wiring (tap/drag → InputAction, Android) | ✅ |
| Audio (music, SFX, volume, mute, pause-aware) | ✅ |
| Save system (slots, autosave, atomic writes, migration) | ✅ |
| Settings (persisted player preferences) | ✅ |
| Localization (English + Arabic, RTL) | ✅ |
| Debug overlay (FPS, scene, entities, input — dev only) | ✅ |
| Update system (GitHub Release discovery, verify) | ✅ |
| Setup wizard (genre, physics, multiplayer, DLC, monetization) | ✅ |
| Install wizard (Windows, Android, Linux) | ✅ |
| Developer CLI (13 commands) | ✅ |
| CI/CD (analyze, test, build, security, release) | ✅ |
| Documentation | ✅ |

---

## Architecture

```
Game Content   (lib/gameplay/)   ← your game — replaceable
Game Runtime   (lib/game/)       ← Flame wrappers
Cambric Core   (lib/core/)       ← infrastructure, no Flame dependency
Flutter/Flame                    ← platform
```

Game code never calls operating-system APIs directly.  
Cambric infrastructure never depends on Flame.  
See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full design.

---

## Developer CLI

```bash
dart run scripts/cambric.dart doctor           # environment check
dart run scripts/cambric.dart setup            # run the setup wizard
dart run scripts/cambric.dart install windows  # install wizard
dart run scripts/cambric.dart build windows    # Windows release build
dart run scripts/cambric.dart build android    # Android APK
dart run scripts/cambric.dart test             # run all tests
dart run scripts/cambric.dart diagnose         # diagnostic report
dart run scripts/cambric.dart release 1.0.0    # bump version
dart run scripts/cambric.dart update check     # check for updates
```

See [scripts/README.md](scripts/README.md) for all commands.

---

## Project Structure

```
game-template/
├── .github/workflows/    CI/CD pipelines
├── docs/                 Full documentation
├── scripts/              Developer CLI + setup wizard + install wizard
├── .template/            Wizard defaults, distribution guides
├── game/                 Flutter + Flame project
│   ├── lib/core/         Cambric infrastructure
│   ├── lib/game/         Game runtime (wraps Flame)
│   ├── lib/gameplay/     Template content — replace this
│   ├── lib/save/         Save system
│   ├── lib/settings/     Player settings
│   ├── lib/ui/           Flutter app widget
│   ├── test/             89 passing unit tests
│   ├── tools/            Platform install helpers
│   └── assets/           i18n, images, sprites, audio, fonts
└── cambric.manifest.json Game identity
```

---

## Documentation

| Document | Description |
|---|---|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design and layer boundaries |
| [GETTING_STARTED.md](docs/GETTING_STARTED.md) | Setup and first steps |
| [DEVELOPMENT.md](docs/DEVELOPMENT.md) | Development workflow |
| [SAVES.md](docs/SAVES.md) | Save system internals |
| [BUILDING.md](docs/BUILDING.md) | Platform build instructions |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Known issues and fixes |
| [SECURITY.md](SECURITY.md) | Security policy |

---

## Requirements

- Flutter 3.47.2+ (stable channel)
- Dart 3.13.2+
- Windows builds: Visual Studio 2022 with C++ workload
- Android builds: Android SDK 36+, Java 17+
- Linux builds: GitHub Actions `ubuntu-latest` (or WSL2)

---

## License

MIT — see [LICENSE](LICENSE).  
Copyright © 2026 Cambric.
