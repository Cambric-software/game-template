# Cambric Developer CLI

Run all commands from the **repository root** (where `cambric.manifest.json` lives).

```
game-template/
├── cambric.manifest.json   ← project root
├── scripts/
│   ├── cambric.dart        ← main CLI
│   └── cambric_setup.dart  ← game setup wizard
└── game/                   ← Flutter project
```

---

## Setup

```bash
dart run scripts/cambric_setup.dart
```

Interactive wizard — configures game identity, platforms, input, languages.  
Safe to run again: warns before overwriting an existing configuration.

---

## Commands

| Command | Description |
|---|---|
| `doctor` | Check Flutter, Dart, Android SDK, Git, manifest |
| `version` | Print current game version from manifest |
| `setup` | Launch the setup wizard |
| `clean` | Run `flutter clean` in `game/` |
| `build <platform>` | Build release: `windows`, `android`, `linux` |
| `run [platform]` | Run in debug mode (default: `windows`) |
| `test` | Run all tests |
| `assets validate` | Check all declared assets exist on disk |
| `save validate <file>` | Inspect and verify a `.sav` file |
| `diagnose` | Generate a full diagnostic report |
| `release <version>` | Bump version in manifest + pubspec (e.g. `1.2.0`) |
| `update check` | Check GitHub Releases for a newer version |

---

## Examples

```bash
# Check environment
dart run scripts/cambric.dart doctor

# Build for Android
dart run scripts/cambric.dart build android

# Bump version and build release
dart run scripts/cambric.dart release 1.0.0
dart run scripts/cambric.dart build windows

# Validate assets after adding new files
dart run scripts/cambric.dart assets validate

# Check a save file for corruption
dart run scripts/cambric.dart save validate path/to/slot_1.sav
```

---

## Requirements

- Dart SDK 3.13.2+ (bundled with Flutter)
- Run from the repository root — NOT from inside `game/`
