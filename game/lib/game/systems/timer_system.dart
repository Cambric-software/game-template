import '../../core/logging/logging_service.dart';

final _log = gameLogger('TimerSystem');

/// A single game-time timer.
///
/// Timers are pause-aware — they stop advancing when the
/// [isPausedCallback] returns true.
class CambricTimer {
  CambricTimer({
    required this.duration,
    required this.onComplete,
    this.isRepeating = false,
    this.isPausedCallback,
    String? id,
  }) : id = id ?? 'timer_${DateTime.now().microsecondsSinceEpoch}';

  final String id;
  final double duration;
  final void Function() onComplete;
  final bool isRepeating;

  /// Optional: return true to pause this timer.
  final bool Function()? isPausedCallback;

  double _elapsed = 0;
  bool _cancelled = false;
  bool _completed = false;

  bool get isCancelled => _cancelled;
  bool get isCompleted => _completed && !isRepeating;
  double get elapsed => _elapsed;
  double get remaining => (duration - _elapsed).clamp(0, duration);

  /// Advance the timer by [dt] seconds. Returns true if it fired.
  bool tick(double dt) {
    if (_cancelled || (isCompleted)) return false;
    if (isPausedCallback?.call() ?? false) return false;

    _elapsed += dt;
    if (_elapsed >= duration) {
      _elapsed = isRepeating ? _elapsed - duration : duration;
      if (!isRepeating) _completed = true;
      onComplete();
      return true;
    }
    return false;
  }

  void cancel() {
    _cancelled = true;
    _log.fine('Timer cancelled: $id');
  }

  void reset() {
    _elapsed = 0;
    _completed = false;
    _cancelled = false;
  }
}

/// Manages a collection of [CambricTimer]s.
///
/// Call [update(dt)] from the game loop.
/// Dead timers are automatically pruned each frame.
class TimerSystem {
  TimerSystem();

  final List<CambricTimer> _timers = [];

  /// Add a timer and return it so the caller can cancel it if needed.
  CambricTimer add(CambricTimer timer) {
    _timers.add(timer);
    return timer;
  }

  /// Convenience: create and add a one-shot timer.
  CambricTimer after(
    double seconds,
    void Function() onComplete, {
    bool Function()? isPausedCallback,
  }) {
    return add(CambricTimer(
      duration: seconds,
      onComplete: onComplete,
      isPausedCallback: isPausedCallback,
    ));
  }

  /// Convenience: create and add a repeating timer.
  CambricTimer every(
    double seconds,
    void Function() onComplete, {
    bool Function()? isPausedCallback,
  }) {
    return add(CambricTimer(
      duration: seconds,
      onComplete: onComplete,
      isRepeating: true,
      isPausedCallback: isPausedCallback,
    ));
  }

  void update(double dt) {
    for (final timer in _timers) {
      timer.tick(dt);
    }
    // Prune completed and cancelled timers
    _timers.removeWhere((t) => t.isCancelled || t.isCompleted);
  }

  void cancelAll() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  int get activeCount => _timers.length;
}
