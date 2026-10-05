import 'package:flame/components.dart';

/// Physics body component — data layer for movement and forces.
///
/// Attach to any entity that needs physics-driven movement.
/// The actual position update is performed by the movement system
/// or directly in the entity's update() method.
///
/// This is intentionally simple — for complex physics use
/// flame_forge2d behind a dedicated PhysicsSystem.
class PhysicsBodyComponent {
  PhysicsBodyComponent({
    Vector2? velocity,
    this.mass = 1.0,
    this.gravityScale = 1.0,
    this.isStatic = false,
    this.maxSpeed = 600,
    this.friction = 0.0,
  }) : velocity = velocity ?? Vector2.zero();

  /// Current velocity in pixels/second.
  Vector2 velocity;

  /// Mass in arbitrary units. Affects force application.
  double mass;

  /// 0 = no gravity, 1 = full gravity, negative = anti-gravity.
  double gravityScale;

  /// Static bodies don't move but can still participate in collisions.
  bool isStatic;

  /// Maximum speed cap in pixels/second.
  double maxSpeed;

  /// Velocity damping per second (0 = no friction, 1 = instant stop).
  double friction;

  // ── Forces ────────────────────────────────────────────────────────────

  /// Apply a continuous force (affected by mass).
  void applyForce(Vector2 force) {
    if (isStatic) return;
    velocity += force / mass;
  }

  /// Apply an instant impulse (affected by mass).
  void applyImpulse(Vector2 impulse) {
    if (isStatic) return;
    velocity += impulse / mass;
  }

  /// Set velocity directly (ignores mass).
  void setVelocity(double x, double y) {
    velocity.setValues(x, y);
  }

  void stop() => velocity.setZero();

  /// Clamp velocity to maxSpeed.
  void clampSpeed() {
    if (velocity.length > maxSpeed) {
      velocity.scaleTo(maxSpeed);
    }
  }

  /// Apply friction damping for [dt] seconds.
  void applyFriction(double dt) {
    if (friction <= 0) return;
    final dampening = (1.0 - friction * dt).clamp(0.0, 1.0);
    velocity.scale(dampening);
  }

  // ── Integration ───────────────────────────────────────────────────────

  /// Move [position] by velocity × dt. Call from entity's update().
  void integrate(Vector2 position, double dt) {
    if (isStatic) return;
    applyFriction(dt);
    clampSpeed();
    position.addScaled(velocity, dt);
  }

  // ── Serialization ─────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'velocityX': velocity.x,
    'velocityY': velocity.y,
    'mass': mass,
    'gravityScale': gravityScale,
    'isStatic': isStatic,
  };

  factory PhysicsBodyComponent.fromJson(Map<String, dynamic> json) {
    return PhysicsBodyComponent(
      velocity: Vector2(
        json['velocityX'] as double? ?? 0,
        json['velocityY'] as double? ?? 0,
      ),
      mass: json['mass'] as double? ?? 1.0,
      gravityScale: json['gravityScale'] as double? ?? 1.0,
      isStatic: json['isStatic'] as bool? ?? false,
    );
  }
}
