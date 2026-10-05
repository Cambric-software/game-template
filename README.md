# Cambric Game Template

A reusable 2D game foundation for Android, Windows, and Linux. Built with Flutter and Flame.

This is not a finished game. It is the infrastructure layer that future Cambric games are built on.

---

## Supported Platforms

| Platform | Build | Test | Notes |
|---|---|---|---|
| Windows x64 | ✅ Local | ✅ Local | VS 2022 required |
| Android APK/AAB | ✅ Local | ⚠️ Needs device | Android SDK required |
| Linux x64 | ✅ CI only | ✅ CI | No local Linux toolchain needed |

---

## What You Get

- **Game loop** — Flame-powered with delta time, fixed timestep, pause support
- **Scene system** — Load, activate, transition, dispose with full lifecycle
- **Entity system** — Tag-based entities with optional component data
- **Input** — Keyboard, mouse, touch, gamepad abstraction with configurable mappings
- **Audio** — Music, SFX, volume, mute, pause-aware
- **Save system** — Slots, autosave, atomic writes, corruption protection, migration
- **Settings** — Persisted player preferences, reset to defaults
- **Localization** — English + Arabic with RTL layout support
- **Debug overlay** — FPS, frame time, scene, entities, input state (dev-only)
- **Update system** — GitHub Release discovery, download, checksum verify
- **CLI tools** — `doctor`, `build`, `run`, `test`, `diagnose`, `release`
- **Setup wizard** — Interactive game configuration
- **CI/CD** — GitHub Actions for analyze, test, build (Windows/Android/Linux), release
- **Documentation** — Full docs/ directory

---

## Quick Start

**Requirements:** Flutter 3.47+, Dart 3.13+, Git

```bash
# Clone the template
git clone https://github.com/Cambric-software/game-template my-game
cd my-game

# Configure your game
dart run scripts/cambric_setup.dart

# Check your environment
dart run scripts/cambric.dart doctor

# Run the game
dart run scripts/cambric.dart run
```

---

## Architecture

The project is organized in four clean layers:

```
Game Content (lib/gameplay/)       ← your game — replaceable
Game Runtime (lib/game/)           ← Flame wrappers — game-aware
Cambric Core (lib/core/)           ← infrastructure — Flame-independent
Flutter / Flame                    ← platform
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full detail.

---

## Directory Structure

```
game-template/
├── .github/workflows/    CI/CD (analyze, test, build, security, release)
├── docs/                 Full documentation
├── scripts/              Developer CLI (cambric.dart) + setup wizard
├── .template/            Distribution guides, release config
├── game/                 Flutter + Flame project
│   ├── lib/
│   │   ├── core/         Cambric infrastructure (no Flame dependency)
│   │   ├── game/         Game runtime (Flame wrappers)
│   │   ├── gameplay/     Template content (scenes, entities)
│   │   ├── save/         Save system
│   │   ├── settings/     Player settings
│   │   └── ui/           Flutter UI layer
│   ├── test/             Unit and widget tests
│   └── assets/           i18n, images, sprites, audio, fonts
└── cambric.manifest.json Game identity manifest
```

---

## Developer CLI

```bash
dart run scripts/cambric.dart doctor          # Environment check
dart run scripts/cambric.dart build windows   # Windows release build
dart run scripts/cambric.dart build android   # Android APK
dart run scripts/cambric.dart test            # Run all tests
dart run scripts/cambric.dart diagnose        # Full diagnostic report
dart run scripts/cambric.dart release 1.0.0   # Bump version
dart run scripts/cambric.dart update check    # Check for updates
```

---

## Documentation

| Document | Description |
|---|---|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design, layers, boundaries |
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
- For Windows builds: Visual Studio 2022 with C++ workload
- For Android builds: Android SDK + Java 17
- For Linux builds: Use GitHub Actions (ubuntu-latest runner)

---

## License

MIT License — see [LICENSE](LICENSE)

Copyright (c) 2026 Cambric
