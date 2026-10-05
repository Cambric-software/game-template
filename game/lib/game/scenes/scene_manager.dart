import 'package:flame/components.dart';

import '../../core/logging/logging_service.dart';
import 'cambric_scene.dart';

final _log = gameLogger('SceneManager');

/// Manages scene loading, transitions, and lifecycle.
///
/// Scenes are registered by name. Transitioning to a scene:
///   1. Deactivates and removes the current scene
///   2. Loads the new scene if not already loaded
///   3. Activates the new scene
///
/// Only one scene is active at a time. Overlay scenes (pause, HUD)
/// are managed separately as Flame components rather than CambricScenes.
class SceneManager {
  SceneManager({required this.game});

  final dynamic game; // FlameGame — typed loosely to avoid circular import

  CambricScene? _activeScene;
  final Map<String, CambricScene Function()> _registry = {};

  CambricScene? get activeScene => _activeScene;
  String get activeSceneName => _activeScene?.sceneName ?? 'none';
  int get activeEntityCount => _activeScene?.children.length ?? 0;

  /// Register a scene factory by name.
  ///
  /// Example:
  /// ```dart
  /// sceneManager.register('mainMenu', () => MainMenuScene());
  /// sceneManager.register('gameplay', () => GameplayScene());
  /// ```
  void register(String name, CambricScene Function() factory) {
    _registry[name] = factory;
    _log.fine('Scene registered: $name');
  }

  /// Transition to the scene with the given [name].
  Future<void> transitionTo(String name) async {
    if (!_registry.containsKey(name)) {
      _log.severe('Scene not registered: $name');
      return;
    }

    _log.info('Transitioning to scene: $name');

    // Deactivate and remove current
    if (_activeScene != null) {
      await _activeScene!.onSceneDeactivate();
      game.remove(_activeScene!);
      await _activeScene!.onSceneDispose();
      _activeScene = null;
    }

    // Create and load new scene
    final scene = _registry[name]!();
    await scene.onSceneLoad();

    // Add to game and activate
    game.add(scene);
    await scene.onSceneActivate();
    _activeScene = scene;

    _log.info('Scene active: $name');
  }

  void update(double dt) {
    // Scene update is handled by Flame's component tree automatically.
    // This hook is available for cross-scene system coordination.
  }

  void onResize(Vector2 size) {
    _activeScene?.onSceneResize(size);
  }

  /// Returns registered scene names for diagnostics.
  List<String> get registeredScenes => _registry.keys.toList();
}
