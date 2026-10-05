import '../../core/logging/logging_service.dart';

final _log = gameLogger('GameStateManager');

/// All top-level game states.
///
/// Add game-specific states between [playing] and [exiting] as needed.
/// The state machine does not lock you into these exact states.
enum GameState {
  boot,
  loading,
  mainMenu,
  playing,
  paused,
  gameOver,
  victory,
  settings,
  credits,
  exiting,
}

/// Manages transitions between [GameState] values.
///
/// Callers listen to [onStateChanged] to react to transitions.
/// The machine validates transitions and logs invalid ones rather
/// than crashing, because a game must continue running even when
/// code has a bug.
class GameStateManager {
  GameState _current = GameState.boot;
  final List<void Function(GameState, GameState)> _listeners = [];

  GameState get current => _current;
  bool get isPlaying => _current == GameState.playing;
  bool get isPaused => _current == GameState.paused;
  bool get isInMenu =>
      _current == GameState.mainMenu ||
      _current == GameState.settings ||
      _current == GameState.credits;

  /// Register a callback for state changes.
  void addListener(void Function(GameState from, GameState to) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(GameState from, GameState to) listener) {
    _listeners.remove(listener);
  }

  /// Transition to [next]. Logs a warning for unexpected transitions
  /// but does not crash — the game loop continues.
  void transition(GameState next) {
    if (next == _current) return;

    if (!_isAllowed(_current, next)) {
      _log.warning(
        'Unexpected state transition: $_current → $next. Allowing anyway.',
      );
    }

    final previous = _current;
    _current = next;
    _log.info('State: $previous → $next');

    for (final listener in List.of(_listeners)) {
      listener(previous, next);
    }
  }

  bool _isAllowed(GameState from, GameState to) {
    // Define the allowed transitions. This is documentation, not enforcement.
    const allowed = {
      GameState.boot: {GameState.loading},
      GameState.loading: {
        GameState.mainMenu,
        GameState.playing,
      },
      GameState.mainMenu: {
        GameState.playing,
        GameState.settings,
        GameState.credits,
        GameState.exiting,
      },
      GameState.playing: {
        GameState.paused,
        GameState.gameOver,
        GameState.victory,
        GameState.loading, // scene transition via loading
        GameState.exiting,
      },
      GameState.paused: {
        GameState.playing,
        GameState.settings,
        GameState.mainMenu,
        GameState.exiting,
      },
      GameState.gameOver: {
        GameState.mainMenu,
        GameState.playing, // retry
        GameState.exiting,
      },
      GameState.victory: {
        GameState.mainMenu,
        GameState.playing, // next level
        GameState.exiting,
      },
      GameState.settings: {
        GameState.mainMenu,
        GameState.paused,
      },
      GameState.credits: {
        GameState.mainMenu,
      },
      GameState.exiting: <GameState>{},
    };
    return allowed[from]?.contains(to) ?? false;
  }
}
