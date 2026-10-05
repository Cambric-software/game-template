import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/identity/game_identity.dart';
import '../../game/input/input_action.dart';
import '../../game/scenes/cambric_scene.dart';

/// Template main menu scene.
///
/// Replace the visuals with your game's actual main menu.
/// The scene lifecycle pattern (register → transitionTo) should be kept.
class MainMenuScene extends CambricScene {
  @override
  String get sceneName => 'MainMenu';

  late final TextComponent _title;
  late final TextComponent _startPrompt;
  late final TextComponent _version;

  /// Called by bootstrap to wire navigation without coupling this scene
  /// to the game runtime.
  void Function(String)? onNavigate;

  @override
  Future<void> onSceneLoad() async {
    _title = TextComponent(
      text: GameIdentity.name,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 36,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFF000000), blurRadius: 4)],
        ),
      ),
      anchor: Anchor.center,
    );

    _startPrompt = TextComponent(
      text: 'Press ENTER or SPACE to Start',
      textRenderer: TextPaint(
        style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 18),
      ),
      anchor: Anchor.center,
    );

    _version = TextComponent(
      text: GameIdentity.displayVersion,
      textRenderer: TextPaint(
        style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
      ),
    );

    add(_title);
    add(_startPrompt);
    add(_version);
  }

  @override
  void onSceneResize(Vector2 size) {
    _title.position = Vector2(size.x / 2, size.y * 0.35);
    _startPrompt.position = Vector2(size.x / 2, size.y * 0.55);
    _version.position = Vector2(8, size.y - 20);
  }

  @override
  void onInputAction(InputAction action) {
    if (action == InputAction.confirm || action == InputAction.jump) {
      onNavigate?.call('gameplay');
    }
  }
}
