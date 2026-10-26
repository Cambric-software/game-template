import 'package:flame/components.dart';

import '../../core/logging/logging_service.dart';
import '../entities/game_entity.dart';

final _log = gameLogger('SpawnSystem');

/// A named spawn point in a scene.
class SpawnPoint {
  SpawnPoint({
    required this.id,
    required this.position,
  });

  final String id;
  final Vector2 position;
}

/// Manages entity spawning at named spawn points.
///
/// Register spawn points in your scene, then call [spawn] to instantiate
/// an entity at a point by ID.
///
/// ```dart
/// final spawner = SpawnSystem();
/// spawner.addPoint(SpawnPoint(id: 'player_start', position: Vector2(100, 200)));
/// add(spawner);
///
/// // Spawn a player at the registered point:
/// spawner.spawn('player_start', () => PlayerEntity());
/// ```
class SpawnSystem extends Component {
  SpawnSystem() : super(priority: 5);

  final Map<String, SpawnPoint> _points = {};

  void addPoint(SpawnPoint point) {
    _points[point.id] = point;
    _log.fine('Spawn point registered: ${point.id}');
  }

  SpawnPoint? getPoint(String id) => _points[id];

  /// Spawn an entity at [pointId]. The entity is added to [parent].
  /// Returns null if the point ID is not registered.
  GameEntity? spawn(String pointId, GameEntity Function() factory) {
    final point = _points[pointId];
    if (point == null) {
      _log.warning('Unknown spawn point: $pointId');
      return null;
    }

    final entity = factory()..position = point.position.clone();
    parent?.add(entity);
    _log.fine('Spawned entity at $pointId (${point.position})');
    return entity;
  }

  List<String> get registeredPoints => _points.keys.toList();
}

// ── DespawnSystem ──────────────────────────────────────────────────────────

/// Conditions that trigger automatic despawning.
enum DespawnCondition {
  /// Remove the entity after [duration] seconds of game time.
  afterDuration,

  /// Remove the entity when it leaves the camera bounds.
  outOfBounds,

  /// Remove the entity when its [HealthComponent] reaches zero.
  /// (The entity's onEntityDispose is responsible for the signal.)
  onDeath,
}

class _DespawnEntry {
  _DespawnEntry({
    required this.entity,
    required this.condition,
    this.duration,
  });

  final GameEntity entity;
  final DespawnCondition condition;
  final double? duration;
  double elapsed = 0;
}

/// Monitors registered entities and removes them when their despawn
/// condition is satisfied.
///
/// ```dart
/// final despawner = DespawnSystem();
/// add(despawner);
///
/// // Remove a bullet 3 seconds after spawn:
/// despawner.register(bulletEntity,
///     condition: DespawnCondition.afterDuration, duration: 3.0);
/// ```
class DespawnSystem extends Component {
  DespawnSystem() : super(priority: 20);

  final List<_DespawnEntry> _entries = [];

  void register(
    GameEntity entity, {
    required DespawnCondition condition,
    double? duration,
  }) {
    _entries.add(_DespawnEntry(
      entity: entity,
      condition: condition,
      duration: duration,
    ));
  }

  void unregister(GameEntity entity) {
    _entries.removeWhere((e) => e.entity == entity);
  }

  @override
  void update(double dt) {
    final toRemove = <_DespawnEntry>[];

    for (final entry in _entries) {
      if (!entry.entity.isMounted) {
        toRemove.add(entry);
        continue;
      }

      switch (entry.condition) {
        case DespawnCondition.afterDuration:
          entry.elapsed += dt;
          if (entry.duration != null &&
              entry.elapsed >= entry.duration!) {
            _despawn(entry);
            toRemove.add(entry);
          }
        case DespawnCondition.onDeath:
          if (entry.entity.hasTag('dead')) {
            _despawn(entry);
            toRemove.add(entry);
          }
        case DespawnCondition.outOfBounds:
          // Extension point: compare entity position against camera bounds.
          // Requires camera reference — wire in from scene if needed.
          break;
      }
    }

    for (final e in toRemove) {
      _entries.remove(e);
    }
  }

  void _despawn(_DespawnEntry entry) {
    _log.fine('Despawning entity: ${entry.entity.entityId}');
    entry.entity.removeFromParent();
  }

  int get trackedCount => _entries.length;
}
