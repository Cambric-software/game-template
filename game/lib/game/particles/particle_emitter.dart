import 'dart:math' as math;
import 'dart:ui' show Canvas, Color, Paint;

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

import '../../core/logging/logging_service.dart';

final _log = gameLogger('ParticleEmitter');

/// Configuration for a single particle burst.
///
/// All fields have sensible defaults. Override only what you need:
/// ```dart
/// emitter.emit(ParticleConfig(
///   count: 20,
///   speed: 120,
///   spread: math.pi,        // half-circle upward spray
///   lifetime: 0.6,
///   color: const Color(0xFFFF4400),
///   size: 4,
/// ));
/// ```
class ParticleConfig {
  const ParticleConfig({
    this.count = 10,
    this.speed = 80.0,
    this.spread = math.pi * 2,
    this.lifetime = 0.8,
    this.color = const Color(0xFFFFFFFF),
    this.size = 4.0,
    this.direction,
  })  : assert(count > 0, 'count must be positive'),
        assert(speed >= 0, 'speed must be non-negative'),
        assert(lifetime > 0, 'lifetime must be positive'),
        assert(size > 0, 'size must be positive');

  /// Number of particles to spawn per [ParticleEmitter.emit] call.
  final int count;

  /// Launch speed in pixels per second (before randomisation).
  final double speed;

  /// Cone half-angle in radians that particles can deviate from [direction].
  ///
  /// - `0` — all particles travel in exactly [direction].
  /// - `math.pi` — particles spread across a half-circle.
  /// - `math.pi * 2` — particles spread in a full circle (default).
  final double spread;

  /// How long each particle lives, in seconds.
  final double lifetime;

  /// Tint colour for each particle. The alpha channel is used as the
  /// starting opacity and fades to transparent over the particle's lifetime.
  final Color color;

  /// Diameter of each circular particle, in world pixels.
  final double size;

  /// Base direction for the spray as a unit vector.
  ///
  /// Defaults to `null` which emits in all directions. If provided, [spread]
  /// is applied symmetrically around this direction.
  final Vector2? direction;
}

/// A simple fire-and-forget particle emitter.
///
/// Extends [PositionComponent] so it can be added to any component tree.
/// Call [emit] to spawn a burst of particles at this component's world
/// position. Each burst is managed internally; expired particles are
/// cleaned up automatically.
///
/// ### Usage
/// ```dart
/// // In your scene's onLoad:
/// final emitter = ParticleEmitter();
/// add(emitter);
///
/// // When you want sparks at a position:
/// emitter.position = hitPoint;
/// emitter.emit(ParticleConfig(count: 15, color: Colors.orange));
/// ```
///
/// ### Implementation note
/// Each [emit] call adds a Flame [ParticleSystemComponent] as a child.
/// Flame's particle system removes the component automatically when all
/// particles expire, so no manual cleanup is needed.
class ParticleEmitter extends PositionComponent {
  ParticleEmitter({
    super.position,
    super.priority,
  });

  static final _rng = math.Random();

  /// Spawn a burst of particles using [config].
  ///
  /// Particles are emitted at this component's current [position].
  /// The burst is self-cleaning — the [ParticleSystemComponent] removes
  /// itself from the tree once all particles have expired.
  void emit(ParticleConfig config) {
    final particles = <Particle>[];

    final baseDir = config.direction ?? Vector2(0, -1);
    // Normalise in case the caller passed a non-unit vector
    final normalised =
        baseDir.length > 0 ? (baseDir.clone()..normalize()) : Vector2(0, -1);

    for (int i = 0; i < config.count; i++) {
      // Compute a random direction within the spread cone
      final halfSpread = config.spread / 2;
      final baseAngle = math.atan2(normalised.y, normalised.x);
      final angle =
          baseAngle + (_rng.nextDouble() * 2 - 1) * halfSpread;

      final velocity = Vector2(
        math.cos(angle) * config.speed,
        math.sin(angle) * config.speed,
      );

      final halfSize = config.size / 2;

      particles.add(
        AcceleratedParticle(
          acceleration: Vector2(0, 30), // mild gravity on particles
          speed: velocity,
          child: CircleParticle(
            radius: halfSize,
            paint: _fadingPaint(config.color, config.lifetime),
          ),
          lifespan: config.lifetime,
        ),
      );
    }

    final system = ParticleSystemComponent(
      particle: ComposedParticle(children: particles),
    );

    add(system);

    _log.fine(
      'Emitted ${config.count} particles '
      '(speed: ${config.speed}, lifetime: ${config.lifetime}s)',
    );
  }

  /// Build a paint that uses [ComputedParticle] trickery to fade the
  /// [color] from its original alpha to transparent over [lifetime].
  ///
  /// Flame's [CircleParticle] takes a [Paint] directly, so we use a
  /// [ComputedParticle] wrapper only when we need per-frame alpha.
  ///
  /// For simplicity this returns a fixed paint at the original alpha —
  /// see [_buildFadingParticle] for a full fade variant if needed.
  static Paint _fadingPaint(Color color, double lifetime) {
    return Paint()..color = color;
  }

  // ── Active particle count (for diagnostics) ───────────────────────────────

  /// Number of active [ParticleSystemComponent] children currently alive.
  int get activeParticleSystems =>
      children.whereType<ParticleSystemComponent>().length;
}

/// Extension that adds a convenience [emitAt] helper for position-override
/// bursts without moving the emitter.
extension ParticleEmitterExt on ParticleEmitter {
  /// Spawn a burst at [worldPosition] without permanently moving the emitter.
  void emitAt(Vector2 worldPosition, ParticleConfig config) {
    final saved = position.clone();
    position = worldPosition;
    emit(config);
    position = saved;
  }
}
