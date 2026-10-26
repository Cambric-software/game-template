import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../game/input/input_action.dart';
import '../../game/runtime/cambric_game.dart';
import '../../game/scenes/cambric_scene.dart';
import '../../ui/theme/game_palette.dart';

/// Minimal gameplay scene — the template starting point.
///
/// Demonstrates scene lifecycle, an entity, input-driven movement, and
/// rendering. Replace with your actual game scene.
class GameplayScene extends CambricScene {
  @override
  String get sceneName => 'Gameplay';

  late final _PlayerEntity _player;
  late final TextComponent _hint;

  @override
  Future<void> onSceneLoad() async {
    _player = _PlayerEntity();
    add(_player);

    _hint = TextComponent(
      text: 'WASD / Arrows to move • ESC to pause',
      textRenderer: TextPaint(
        style: TextStyle(
          color: GamePalette.dark.secondary,
          fontSize: 13,
        ),
      ),
    );
    add(_hint);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final game = findGame();
    if (game is! CambricGame) return;
    final input = game.inputState;

    final dx = (input.isPressed(InputAction.moveRight) ? 1 : 0) -
        (input.isPressed(InputAction.moveLeft) ? 1 : 0);
    final dy = (input.isPressed(InputAction.moveDown) ? 1 : 0) -
        (input.isPressed(InputAction.moveUp) ? 1 : 0);
    if (dx == 0 && dy == 0) return;

    final direction = Vector2(dx.toDouble(), dy.toDouble())..normalize();
    final next = _player.position + direction * (220 * dt);
    final half = _player.size / 2;
    _player.position = Vector2(
      next.x.clamp(half.x, game.size.x - half.x),
      next.y.clamp(half.y, game.size.y - half.y),
    );
  }

  @override
  void onSceneResize(Vector2 size) {
    _player.position = Vector2(size.x / 2, size.y / 2);
    _hint.position = Vector2(8, size.y - 20);
  }
}

/// Minimal player entity rendered as a colored square.
/// Replace with your actual player entity.
class _PlayerEntity extends PositionComponent {
  _PlayerEntity()
      : super(
          size: Vector2(32, 32),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    final fill = Paint()..color = GamePalette.dark.primary;
    final outline = Paint()
      ..color = GamePalette.dark.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), fill);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), outline);
  }
}
