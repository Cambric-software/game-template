import 'package:flame/components.dart';

import '../../core/logging/logging_service.dart';

final _log = gameLogger('AnimationStateMachine');

/// Built-in animation states.
/// Add custom states by extending with additional values or using [custom].
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
  // Use this for game-specific states not in the base enum
  custom,
}

/// Drives a sprite animation based on the current [AnimationState].
///
/// Usage:
/// ```dart
/// final anim = AnimationStateMachine();
/// anim.addAnimation(AnimationState.idle, idleSpriteAnim);
/// anim.addAnimation(AnimationState.walk, walkSpriteAnim);
/// anim.transition(AnimationState.walk);
/// ```
class AnimationStateMachine {
  AnimationStateMachine({this.onStateChanged});

  final Map<AnimationState, SpriteAnimation> _animations = {};
  AnimationState _current = AnimationState.idle;
  SpriteAnimation? _currentAnimation;
  double _elapsed = 0;

  /// Called when state changes. Receives (previous, next).
  void Function(AnimationState, AnimationState)? onStateChanged;

  AnimationState get currentState => _current;
  SpriteAnimation? get currentAnimation => _currentAnimation;

  // ── Configuration ──────────────────────────────────────────────────────

  void addAnimation(AnimationState state, SpriteAnimation animation) {
    _animations[state] = animation;
    // Auto-select first added animation if none set
    _currentAnimation ??= animation;
  }

  bool hasAnimation(AnimationState state) => _animations.containsKey(state);

  // ── Transitions ────────────────────────────────────────────────────────

  /// Transition to [next] state. Does nothing if already in [next].
  void transition(AnimationState next) {
    if (_current == next) return;

    if (!_animations.containsKey(next)) {
      _log.fine(
        'No animation for state $next — staying in $_current',
      );
      return;
    }

    final previous = _current;
    _current = next;
    _currentAnimation = _animations[next];
    _elapsed = 0;
    _currentAnimation?.reset();

    onStateChanged?.call(previous, next);
    _log.fine('Animation: $previous → $next');
  }

  // ── Update ────────────────────────────────────────────────────────────

  void update(double dt) {
    _currentAnimation?.update(dt);
    _elapsed += dt;
  }

  /// Get the current sprite frame for rendering.
  Sprite? get currentSprite => _currentAnimation?.getSprite();

  // ── Reset ─────────────────────────────────────────────────────────────

  void reset() {
    _current = AnimationState.idle;
    _currentAnimation = _animations[AnimationState.idle];
    _elapsed = 0;
    _currentAnimation?.reset();
  }
}
