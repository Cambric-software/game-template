import 'package:flame/components.dart';

import '../../core/logging/logging_service.dart';

final _log = gameLogger('TransformComponent');

/// A pure-data transform: position, rotation, and scale.
///
/// This is intentionally **separate from rendering**. Store it in an
/// entity's [attachedData] map or as a direct field when you need a
/// canonical transform that is independent of Flame's
/// [PositionComponent] render state.
///
/// Useful for server-authoritative physics, ghost-position interpolation,
/// or any system that needs to track spatial state without owning a
/// rendered component.
///
/// Example usage:
/// ```dart
/// entity.attachedData['transform'] = TransformComponent(
///   position: Vector2(100, 200),
/// );
/// ```
class TransformComponent {
  TransformComponent({
    Vector2? position,
    this.rotation = 0.0,
    Vector2? scale,
  })  : position = position ?? Vector2.zero(),
        scale = scale ?? Vector2.all(1.0);

  /// World-space position in logical pixels (or game units).
  Vector2 position;

  /// Rotation in radians, measured clockwise from the positive-X axis.
  double rotation;

  /// Non-uniform scale factor. (1, 1) means no scaling.
  Vector2 scale;

  // ── Derived helpers ──────────────────────────────────────────────────────

  /// Returns true if the scale is uniform (x == y).
  bool get isUniformScale => scale.x == scale.y;

  /// Resets position to origin, rotation to 0, scale to (1, 1).
  void reset() {
    position.setZero();
    rotation = 0.0;
    scale.setAll(1.0);
  }

  /// Copy-in from a Flame [PositionComponent]'s current transform.
  void copyFromPositionComponent(PositionComponent component) {
    position.setFrom(component.position);
    rotation = component.angle;
    scale.setFrom(component.scale);
  }

  /// Apply this transform to a Flame [PositionComponent].
  void applyToPositionComponent(PositionComponent component) {
    component.position.setFrom(position);
    component.angle = rotation;
    component.scale.setFrom(scale);
    _log.finer(
      'Applied transform to ${component.runtimeType}: '
      'pos=$position rot=${rotation.toStringAsFixed(3)} scale=$scale',
    );
  }

  /// Returns a new [TransformComponent] linearly interpolated between
  /// [from] and [to] by factor [t] ∈ [0, 1].
  static TransformComponent lerp(
    TransformComponent from,
    TransformComponent to,
    double t,
  ) {
    return TransformComponent(
      position: from.position + (to.position - from.position) * t,
      rotation: _lerpAngle(from.rotation, to.rotation, t),
      scale: from.scale + (to.scale - from.scale) * t,
    );
  }

  /// Angle lerp that always takes the shortest arc.
  static double _lerpAngle(double a, double b, double t) {
    var diff = (b - a) % (2 * 3.141592653589793);
    if (diff > 3.141592653589793) diff -= 2 * 3.141592653589793;
    if (diff < -3.141592653589793) diff += 2 * 3.141592653589793;
    return a + diff * t;
  }

  /// Returns a shallow copy.
  TransformComponent copy() => TransformComponent(
        position: position.clone(),
        rotation: rotation,
        scale: scale.clone(),
      );

  @override
  String toString() =>
      'TransformComponent(pos=$position, rot=${rotation.toStringAsFixed(3)}, scale=$scale)';
}
