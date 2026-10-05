import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey, KeyEvent,
    KeyDownEvent, KeyUpEvent;
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../../core/features/feature_flags.dart';
import '../../core/logging/logging_service.dart';
import '../../game/audio/audio_system.dart';
import '../../game/debug/debug_overlay.dart';
import '../../game/input/input_action.dart';
import '../../game/input/input_mapper.dart';
import '../../game/loop/game_clock.dart';
import '../../game/scenes/scene_manager.dart';
import '../../game/state/game_state_manager.dart';

final _log = gameLogger('CambricGame');

/// The central game class — Cambric's wrapper around Flame's FlameGame.
///
/// Uses [HasKeyboardHandlerComponents] for keyboard input routing.
/// Game content is registered externally via BootstrapService.
class CambricGame extends FlameGame with HasKeyboardHandlerComponents {
  CambricGame({GameClock? clock}) : _clock = clock ?? RealGameClock();

  final GameClock _clock;
  final GameStateManager stateManager = GameStateManager();
  final InputMapper inputMapper = InputMapper();
  final InputState inputState = InputState();
  late final SceneManager sceneManager;
  late final AudioSystem audioSystem;
  DebugOverlay? _debugOverlay;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sceneManager = SceneManager(game: this);
    audioSystem = AudioSystem();
    await audioSystem.initialize();

    if (FeatureFlags.debugOverlay) {
      _debugOverlay = DebugOverlay(
        gameRef: this,
        stateManager: stateManager,
        sceneManager: sceneManager,
        inputState: inputState,
      );
      add(_debugOverlay!);
    }

    _log.info('CambricGame loaded');
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final actions = inputMapper.actionsForKey(event.logicalKey);

    for (final action in actions) {
      if (event is KeyDownEvent) {
        inputState.press(action);
        _handleJustPressed(action);
      } else if (event is KeyUpEvent) {
        inputState.release(action);
      }
    }

    final superResult = super.onKeyEvent(event, keysPressed);
    return actions.isNotEmpty ? KeyEventResult.handled : superResult;
  }

  void _handleJustPressed(InputAction action) {
    switch (action) {
      case InputAction.pause:
        _togglePause();
      case InputAction.debugToggleOverlay:
        if (FeatureFlags.debugOverlay) {
          _debugOverlay?.toggle();
        }
      default:
        sceneManager.activeScene?.onInputAction(action);
    }
  }

  void _togglePause() {
    if (stateManager.isPlaying) {
      stateManager.transition(GameState.paused);
      _clock.pause();
      audioSystem.onGamePaused();
      overlays.add('pause_menu');
    } else if (stateManager.isPaused) {
      stateManager.transition(GameState.playing);
      _clock.resume();
      audioSystem.onGameResumed();
      overlays.remove('pause_menu');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _clock.tick(dt);

    if (stateManager.isPaused) {
      _debugOverlay?.update(dt);
      inputState.endFrame();
      return;
    }

    sceneManager.update(dt);
    inputState.endFrame();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    sceneManager.onResize(size);
  }

  GameClock get clock => _clock;
}
