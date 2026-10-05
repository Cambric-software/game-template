import 'package:flame/components.dart';

import '../input/input_action.dart';

/// Base class for all Cambric game scenes.
///
/// A scene is a Flame [World] that owns its own component tree,
/// systems, and resources. When a scene is not active its update
/// loop is stopped.
///
/// Override [onSceneLoad], [onSceneActivate], [onSceneDeactivate],
/// and [onSceneDispose] rather than Flame's equivalent hooks,
/// so that Cambric scene lifecycle is clearly separate from
/// raw Flame component lifecycle.
abstract class CambricScene extends World {
  /// The human-readable name of this scene (used in debug overlay).
  String get sceneName;

  bool _active = false;
  bool get isActive => _active;

  // ── Scene lifecycle callbacks ──────────────────────────────────────────

  /// Called when the scene's assets and state should be loaded.
  /// Runs before the scene is added to the game world.
  Future<void> onSceneLoad() async {}

  /// Called when the scene becomes the active scene.
  Future<void> onSceneActivate() async {
    _active = true;
  }

  /// Called when the scene is deactivated (another scene takes over).
  Future<void> onSceneDeactivate() async {
    _active = false;
  }

  /// Called when the scene is permanently removed and resources should
  /// be released.
  Future<void> onSceneDispose() async {}

  /// Receive an input action from CambricGame.
  /// Override to handle gameplay input in this scene.
  void onInputAction(InputAction action) {}

  /// Called when the game window is resized.
  void onSceneResize(Vector2 size) {}
}
