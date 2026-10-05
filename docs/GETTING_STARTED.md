# Getting Started

## Prerequisites

| Tool | Version | Required for |
|---|---|---|
| Flutter | 3.47.2+ stable | All |
| Dart | 3.13.2+ | All |
| Git | Any | All |
| Visual Studio 2022 | C++ workload | Windows builds |
| Android SDK | 36+ | Android builds |
| Java | 17+ | Android builds |

Check your environment:

```bash
dart run scripts/cambric.dart doctor
```

---

## Step 1: Clone

```bash
git clone https://github.com/Cambric-software/game-template my-game
cd my-game
```

---

## Step 2: Run the Setup Wizard

```bash
dart run scripts/cambric_setup.dart
```

The wizard asks: game name, ID, package ID, game type, platforms, input methods, languages, save config, dev/prod mode. It writes `cambric.manifest.json` and updates `game/pubspec.yaml`.

---

## Step 3: Install Dependencies

```bash
cd game && flutter pub get
```

---

## Step 4: Run the Game

```bash
dart run scripts/cambric.dart run
# or directly:
cd game && flutter run -d windows
```

You should see the main menu with your game name and "Press ENTER or SPACE to Start".

---

## First Customizations

### Add a scene

Create `game/lib/gameplay/scenes/level_one_scene.dart`:

```dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/scenes/cambric_scene.dart';

class LevelOneScene extends CambricScene {
  @override
  String get sceneName => 'LevelOne';

  @override
  Future<void> onSceneLoad() async {
    add(TextComponent(
      text: 'Level 1',
      textRenderer: TextPaint(
        style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 24),
      ),
      anchor: Anchor.center,
    ));
  }

  @override
  void onSceneResize(Vector2 size) {
    children.query<TextComponent>().firstOrNull?.position =
        Vector2(size.x / 2, size.y / 2);
  }
}
```

Register in `game/lib/bootstrap/bootstrap_service.dart`:

```dart
game.sceneManager.register('level1', () => LevelOneScene());
```

### Add an entity

```dart
class EnemyEntity extends GameEntity {
  EnemyEntity() : super(tags: {'enemy'}, size: Vector2(32, 32));

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFFFF0000),
    );
  }
}
```

Add it to a scene: `scene.add(EnemyEntity()..position = Vector2(200, 150));`

---

## Next Steps

- [DEVELOPMENT.md](DEVELOPMENT.md) — full workflow
- [SAVES.md](SAVES.md) — save system
- [BUILDING.md](BUILDING.md) — all platforms
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — known issues
