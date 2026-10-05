/// Abstract clock used by game systems.
///
/// Allows real-time behavior in production and deterministic
/// time control in tests. Inject via constructor, not via
/// static calls to DateTime.now().
abstract class GameClock {
  /// Current real-world time.
  DateTime get now;

  /// Total game time elapsed (excluding paused time).
  Duration get gameTime;

  /// Advance the game clock by [dt] seconds (called by the game loop).
  void tick(double dt);

  /// Pause the game clock (game time stops advancing).
  void pause();

  /// Resume the game clock.
  void resume();

  bool get isPaused;
}

/// Production clock backed by real system time.
class RealGameClock implements GameClock {
  RealGameClock();

  Duration _gameTime = Duration.zero;
  bool _paused = false;

  @override
  DateTime get now => DateTime.now();

  @override
  Duration get gameTime => _gameTime;

  @override
  bool get isPaused => _paused;

  @override
  void tick(double dt) {
    if (!_paused) {
      _gameTime += Duration(microseconds: (dt * 1e6).round());
    }
  }

  @override
  void pause() => _paused = true;

  @override
  void resume() => _paused = false;
}

/// Deterministic clock for testing.
///
/// Time only advances when [advance] is called explicitly,
/// making tests independent of wall-clock timing.
class FakeClock implements GameClock {
  FakeClock({DateTime? initialNow})
      : _now = initialNow ?? DateTime(2026, 1, 1);

  DateTime _now;
  Duration _gameTime = Duration.zero;
  bool _paused = false;

  @override
  DateTime get now => _now;

  @override
  Duration get gameTime => _gameTime;

  @override
  bool get isPaused => _paused;

  @override
  void tick(double dt) {
    if (!_paused) {
      _gameTime += Duration(microseconds: (dt * 1e6).round());
      _now = _now.add(Duration(microseconds: (dt * 1e6).round()));
    }
  }

  /// Advance time by a fixed amount (test helper).
  void advance(Duration duration) {
    _gameTime += duration;
    _now = _now.add(duration);
  }

  @override
  void pause() => _paused = true;

  @override
  void resume() => _paused = false;
}
