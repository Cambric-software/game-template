import 'package:flame/components.dart';
import 'package:uuid/uuid.dart';

import '../../core/logging/logging_service.dart';

final _log = gameLogger('GameEntity');

const _uuid = Uuid();

/// Base class for all Cambric game entities.
///
/// Extends Flame's [PositionComponent] and adds:
/// - Unique entity ID
/// - Tag-based filtering
/// - Active/inactive state
/// - Optional named component data map
///
/// Usage:
/// ```dart
/// class PlayerEntity extends GameEntity {
///   PlayerEntity() : super(tags: {'player', 'controllable'});
/// }
/// ```
abstract class GameEntity extends PositionComponent {
  GameEntity({
    String? id,
    Set<String>? tags,
    super.position,
    super.size,
    super.anchor,
    super.priority,
  })  : entityId = id ?? _uuid.v4(),
        _tags = tags ?? {};

  /// Unique identifier for this entity instance.
  final String entityId;

  final Set<String> _tags;
  final Map<String, dynamic> _components = {};
  bool _active = true;

  bool get isActive => _active;
  Set<String> get tags => Set.unmodifiable(_tags);

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await onEntityLoad();
  }

  @override
  void onMount() {
    super.onMount();
    if (_active) onEntityActivate();
  }

  @override
  void onRemove() {
    onEntityDeactivate();
    onEntityDispose();
    super.onRemove();
  }

  /// Override to initialize entity resources.
  Future<void> onEntityLoad() async {}

  /// Called when entity becomes active. Override to start timers/effects.
  void onEntityActivate() {}

  /// Called when entity becomes inactive. Override to pause timers/effects.
  void onEntityDeactivate() {}

  /// Called when entity is permanently removed. Override to release resources.
  void onEntityDispose() {}

  // ── Active state ───────────────────────────────────────────────────────

  void activate() {
    if (_active) return;
    _active = true;
    onEntityActivate();
    _log.fine('Entity activated: $entityId');
  }

  void deactivate() {
    if (!_active) return;
    _active = false;
    onEntityDeactivate();
    _log.fine('Entity deactivated: $entityId');
  }

  // ── Tags ───────────────────────────────────────────────────────────────

  bool hasTag(String tag) => _tags.contains(tag);
  void addTag(String tag) => _tags.add(tag);
  void removeTag(String tag) => _tags.remove(tag);

  // ── Component data ─────────────────────────────────────────────────────

  /// Attach named component data to this entity.
  void setComponent<T>(String key, T value) => _components[key] = value;

  /// Retrieve named component data. Returns null if not attached.
  T? getComponent<T>(String key) {
    final v = _components[key];
    return v is T ? v : null;
  }

  bool hasComponent(String key) => _components.containsKey(key);

  void removeComponent(String key) => _components.remove(key);

  @override
  String toString() => 'GameEntity($entityId, tags=$_tags)';
}
