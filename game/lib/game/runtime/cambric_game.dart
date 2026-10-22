import 'dart:async';
import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart'
    show LogicalKeyboardKey, KeyEvent, KeyDownEvent, KeyUpEvent;
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
  CambricGame({GameClock? clock}) : _clock = clock ?? RealGameClock() {
    // Scenes are registered by BootstrapService before the widget mounts,
    // so the manager must exist before onLoad, not inside it.
    sceneManager = SceneManager(game: this);
    audioSystem = AudioSystem();
  }

  final GameClock _clock;
  final GameStateManager stateManager = GameStateManager();
  final InputMapper inputMapper = InputMapper();
  final InputState inputState = InputState();
  late final SceneManager sceneManager;
  late final AudioSystem audioSystem;
  DebugOverlay? _debugOverlay;

  final Completer<void> _ready = Completer<void>();

  /// Completes after Flame finishes loading the game. Bootstrap waits for
  /// this before adding a scene, so a fast tap on "New game" cannot race
  /// the first frame.
  Future<void> get whenLoaded => _ready.future;

  /// Called once per frame while a session is playing. Bootstrap wires this
  /// to autosave so save timing lives in one place.
  void Function(double dt)? onPlayingTick;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

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

    if (!_ready.isCompleted) _ready.complete();
    _log.info('CambricGame loaded');
  }

  @override
  Color backgroundColor() => const Color(0xFF0E1116);

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
      pause();
    } else if (stateManager.isPaused) {
      resume();
    }
  }

  /// Pause a live session and show the pause menu. Safe to call twice.
  void pause() {
    if (!stateManager.isPlaying) return;
    stateManager.transition(GameState.paused);
    _clock.pause();
    audioSystem.onGamePaused();
    overlays.add('pause_menu');
  }

  /// Resume a paused session. Safe to call twice.
  void resume() {
    if (!stateManager.isPaused) return;
    stateManager.transition(GameState.playing);
    leavePause();
  }

  /// Release pause presentation without changing the state.
  ///
  /// Used when leaving a paused session for the main menu, where the next
  /// state is [GameState.mainMenu] rather than [GameState.playing].
  void leavePause() {
    _clock.resume();
    audioSystem.onGameResumed();
    overlays.remove('pause_menu');
  }

  @override
  void update(double dt) {
    if (stateManager.isPaused) {
      // The world must not advance while the pause menu is open. Overlays are
      // Flutter widgets, but the debug overlay is a Flame component, so give
      // it a tick and clear input edges.
      _debugOverlay?.update(dt);
      inputState.endFrame();
      return;
    }

    _clock.tick(dt);
    super.update(dt);

    if (stateManager.isPlaying) {
      onPlayingTick?.call(dt);
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
