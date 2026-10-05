import 'package:flame/components.dart';

/// Collision shape types supported by CollisionComponent.
enum CollisionShape { rectangle, circle }

/// Collision component — data layer for hitbox definitions.
///
/// Uses a layer/mask bitmask system so entities only collide
/// with entities on their mask layers.
///
/// Example:
/// ```dart
/// // Player on layer 1, collides with enemies (layer 2) and world (layer 4)
/// CollisionComponent(shape: CollisionShape.rectangle, size: Vector2(32, 48),
///   layer: 1, mask: 2 | 4)
/// ```
class CollisionComponent {
  CollisionComponent.rectangle({
    required Vector2 size,
    this.layer = 1,
    this.mask = 0xFFFF,
    this.isTrigger = false,
    this.offset,
    this.onCollision,
  })  : shape = CollisionShape.rectangle,
        size = size,
        radius = size.x / 2;

  CollisionComponent.circle({
    required double radius,
    this.layer = 1,
    this.mask = 0xFFFF,
    this.isTrigger = false,
    this.offset,
    this.onCollision,
  })  : shape = CollisionShape.circle,
        this.radius = radius,
        size = Vector2.all(radius * 2);

  final CollisionShape shape;

  /// Size of rectangle hitbox (or bounding box of circle).
  final Vector2 size;

  /// Radius for circle hitbox.
  final double radius;

  /// Offset from entity position. Null means centered.
  final Vector2? offset;

  /// This entity's collision layer (bitmask).
  final int layer;

  /// Which layers this entity can collide with (bitmask).
  final int mask;

  /// If true: detects overlap but doesn't cause physical response.
  final bool isTrigger;

  /// Called when a collision is detected.
  void Function(CollisionComponent other)? onCollision;

  /// Returns true if this component can collide with [other].
  bool canCollideWith(CollisionComponent other) =>
      (mask & other.layer) != 0 || (other.mask & layer) != 0;

  /// Simple AABB test (rectangle vs rectangle).
  bool overlapsRect(Vector2 posA, Vector2 posB, CollisionComponent other) {
    final ax = posA.x + (offset?.x ?? 0);
    final ay = posA.y + (offset?.y ?? 0);
    final bx = posB.x + (other.offset?.x ?? 0);
    final by = posB.y + (other.offset?.y ?? 0);

    return ax < bx + other.size.x &&
        ax + size.x > bx &&
        ay < by + other.size.y &&
        ay + size.y > by;
  }

  /// Circle vs circle distance test.
  bool overlapsCircle(Vector2 posA, Vector2 posB, CollisionComponent other) {
    final dx = posA.x - posB.x;
    final dy = posA.y - posB.y;
    final dist = dx * dx + dy * dy;
    final rSum = radius + other.radius;
    return dist < rSum * rSum;
  }
}
