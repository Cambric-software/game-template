import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../game/input/input_action.dart';
import '../../game/scenes/cambric_scene.dart';

/// Minimal gameplay scene — the template starting point.
///
/// Demonstrates scene lifecycle, an entity, and rendering.
/// Replace with your actual game scene.
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
        style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
      ),
    );
    add(_hint);
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
    final fill = Paint()..color = const Color(0xFF4CAF50);
    final outline = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), fill);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), outline);
  }
}
