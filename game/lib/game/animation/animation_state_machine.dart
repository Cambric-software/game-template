import 'package:flame/components.dart';

import '../../core/logging/logging_service.dart';

final _log = gameLogger('AnimationStateMachine');

/// Built-in animation state identifiers.
enum AnimationState {
  idle,
  walk,
  run,
  jump,
  fall,
  attack,
  hurt,
  die,
  interact,
  custom,
}

/// Drives sprite animation based on a current [AnimationState].
///
/// Each state maps to a [SpriteAnimation]. When transitioning,
/// the new animation's ticker is reset to frame 0.
///
/// Usage:
/// ```dart
/// final machine = AnimationStateMachine();
/// machine.addAnimation(AnimationState.idle, idleAnim);
/// machine.addAnimation(AnimationState.walk, walkAnim);
///
/// // In entity update():
/// machine.update(dt);
///
/// // To read the current sprite:
/// final sprite = machine.currentSprite;
/// ```
class AnimationStateMachine {
  AnimationStateMachine({this.onStateChanged});

  final Map<AnimationState, SpriteAnimation> _animations = {};

  // SpriteAnimationTicker is not exported from any top-level Flame barrel —
  // we store tickers as dynamic and access via createTicker() return type.
  final Map<AnimationState, dynamic> _tickers = {};

  AnimationState _current = AnimationState.idle;

  /// Called when state changes. Receives (previous, next).
  void Function(AnimationState, AnimationState)? onStateChanged;

  AnimationState get currentState => _current;
  SpriteAnimation? get currentAnimation => _animations[_current];

  // ── Configuration ──────────────────────────────────────────────────────

  void addAnimation(AnimationState state, SpriteAnimation animation) {
    _animations[state] = animation;
    _tickers[state] = animation.createTicker();
  }

  bool hasAnimation(AnimationState state) => _animations.containsKey(state);

  // ── Transitions ────────────────────────────────────────────────────────

  /// Transition to [next]. Does nothing if already in [next].
  void transition(AnimationState next) {
    if (_current == next) return;

    if (!_animations.containsKey(next)) {
      _log.fine('No animation for state $next — staying in $_current');
      return;
    }

    final previous = _current;
    _current = next;
    _tickers[next]?.reset();

    onStateChanged?.call(previous, next);
    _log.fine('Animation: $previous → $next');
  }

  // ── Update ────────────────────────────────────────────────────────────

  /// Advance the current animation ticker. Call from entity's update().
  void update(double dt) {
    _tickers[_current]?.update(dt);
  }

  /// Current sprite frame for rendering. Returns null if no animation set.
  Sprite? get currentSprite {
    try {
      return _tickers[_current]?.getSprite() as Sprite?;
    } catch (_) {
      return null;
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────

  void reset() {
    _current = AnimationState.idle;
    _tickers[AnimationState.idle]?.reset();
  }
}
