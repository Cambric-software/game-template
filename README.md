# Cambric Game Template

[![CI](https://github.com/Cambric-software/game-template/actions/workflows/ci.yml/badge.svg)](https://github.com/Cambric-software/game-template/actions/workflows/ci.yml)

A genre-agnostic 2D game foundation for Android, Windows, and Linux. Flutter
owns menus, settings, saves, and accessibility; Flame owns the game canvas.
Maintained by [Cambric](https://cambric.dev).

The template is a complete starting product, not a folder of helpers. Launch it
and you get a main menu, save browser, settings screen, pause menu, dark and
light themes, and English/Arabic layout with RTL support.

---

## Quick Start

**Requirements:** Flutter 3.47.2+, Dart 3.13.2+, Git

```bash
git clone https://github.com/Cambric-software/game-template my-game
cd my-game

dart run scripts/cambric_setup.dart
dart run scripts/cambric.dart doctor
dart run scripts/cambric.dart run
```

The setup wizard records your game identity and chosen features in
`cambric.manifest.json`. It does not rewrite gameplay code or delete files.

---

## What You Get

| Area | Included |
|---|---|
| UI shell | Main menu, save browser, settings, pause overlay, quit confirmation |
| Theme | One dark/light palette, shared tokens, dark by default, persisted choice |
| Localization | English and Arabic strings, RTL layout, persisted language |
| Game loop | Flame `FlameGame`, fixed update flow, pause/resume, lifecycle handling |
| Scenes | Named scene manager with load/activate/deactivate/dispose hooks |
| Entities | `GameEntity` with IDs, tags, component data, and lifecycle hooks |
| Input | Keyboard, mouse, touch, gamepad abstraction, persisted bindings |
| Audio | Music and SFX through one wrapper, volume/mute, pause-aware |
| Saves | Four slots, autosave, atomic writes, checksum, backup, migration |
| Settings | Volume, mute, reduced motion, theme, language, reset |
| Debug | FPS/scene/input overlay and hitbox visualiser in debug builds only |
| Release | CI for analyze, test, Android, Linux, Windows, security, tagged releases |

The demo scene is intentionally small. Replace `lib/gameplay/` with your game
and keep the shell.

---

## Project Layout

```
game-template/
├── .github/workflows/   CI, release, and security
├── docs/                Architecture, design, development, builds, saves
├── game/
│   ├── lib/core/        Cambric infrastructure (no Flame dependency)
│   ├── lib/game/        Game runtime and Flame wrappers
│   ├── lib/gameplay/    Demo scenes and entities - replace this
│   ├── lib/ui/          Menu, settings, saves, pause, theme, widgets
│   ├── lib/save/        Save format, storage, autosave, migration
│   ├── test/            Unit and widget tests
│   ├── assets/          Manifest and English/Arabic strings
│   └── tools/           Platform install helpers
├── scripts/             Setup, install, and developer CLI
└── cambric.manifest.json
```

---

## UI Kit

Every game uses the same interface as the rest of Cambric:

- Opaque surface cards, hairline borders, accent used sparingly.
- Card radius 14, button 11, chip 6, input 8.
- 48 px minimum touch targets.
- One palette file; no one-off colours in screens.
- Flutter menus above a persistent Flame canvas, never canvas-drawn text.

Read [docs/DESIGN.md](docs/DESIGN.md) before adding a screen. It documents the
tokens, components, layout rules, and accessibility requirements.

---

## Developer CLI

```bash
dart run scripts/cambric.dart doctor           # environment check
dart run scripts/cambric.dart setup            # setup wizard
dart run scripts/cambric.dart run              # run on Windows
dart run scripts/cambric.dart run android      # run on a device
dart run scripts/cambric.dart test             # unit and widget tests
dart run scripts/cambric.dart build windows    # release build
dart run scripts/cambric.dart install windows  # install wizard
dart run scripts/cambric.dart diagnose         # diagnostic report
dart run scripts/cambric.dart release 1.0.0    # bump version
dart run scripts/cambric.dart update check     # check GitHub releases
```

The CLI has 17 commands covering setup, install, build, assets, saves, scenes,
entities, changelog, and updates. Run `dart run scripts/cambric.dart --help`.

---

## Testing

```bash
cd game
flutter analyze lib test
flutter test
```

Widget tests cover the menu, save browser, settings, theme, and Arabic layout.
Save tests use a temporary directory so they never touch player data.

---

## Documentation

| Document | Description |
|---|---|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Runtime layers, boot order, scenes, saves |
| [DESIGN.md](docs/DESIGN.md) | Palette, tokens, components, screen rules |
| [DEVELOPMENT.md](docs/DEVELOPMENT.md) | Everyday workflow and extension points |
| [SAVES.md](docs/SAVES.md) | Save format, slots, migration, corruption handling |
| [BUILDING.md](docs/BUILDING.md) | Windows, Android, Linux, and release builds |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Known failures and fixes |
| [SECURITY.md](SECURITY.md) | Security policy and data handling |

---

## Requirements

- Flutter 3.47.2+ (stable channel)
- Dart 3.13.2+
- Windows: Visual Studio 2022 with the C++ desktop workload
- Android: Android SDK 36+ and Java 17+
- Linux: a Linux host or the `ubuntu-latest` CI runner

## License

MIT - see [LICENSE](LICENSE). Copyright 2026 Cambric.
