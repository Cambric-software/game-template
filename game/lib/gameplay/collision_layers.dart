/// Collision layer bitmask constants.
///
/// Used with [CollisionComponent.layer] and [CollisionComponent.mask].
///
/// Each layer is a power of 2 so layers can be combined with bitwise OR.
///
/// Example:
/// ```dart
/// // Player collides with world and enemies
/// CollisionComponent.rectangle(
///   size: Vector2(32, 48),
///   layer: CollisionLayers.player,
///   mask:  CollisionLayers.world | CollisionLayers.enemy,
/// )
/// ```
///
/// Add game-specific layers below — keep values as powers of 2.
class CollisionLayers {
  CollisionLayers._();

  /// No collision.
  static const int none = 0x0000;

  /// Player character.
  static const int player = 0x0001;

  /// Enemy characters.
  static const int enemy = 0x0002;

  /// Static world geometry (floors, walls, platforms).
  static const int world = 0x0004;

  /// Projectiles (bullets, arrows, etc.).
  static const int projectile = 0x0008;

  /// Collectible items (coins, power-ups, etc.).
  static const int item = 0x0010;

  /// Trigger zones (checkpoints, doors, dialogue triggers).
  static const int trigger = 0x0020;

  /// Destructible objects.
  static const int destructible = 0x0040;

  /// NPC characters.
  static const int npc = 0x0080;

  // ── Reserved for game-specific use ──────────────────────────────────────
  // Add your own layers here as needed:
  // static const int myLayer = 0x0100;
  // static const int myOtherLayer = 0x0200;

  /// Collides with everything.
  static const int all = 0xFFFF;

  // ── Common mask presets ───────────────────────────────────────────────────

  /// Player collides with: world, enemies, items, triggers, NPCs.
  static const int playerMask = world | enemy | item | trigger | npc;

  /// Enemy collides with: world, player, projectiles.
  static const int enemyMask = world | player | projectile;

  /// Projectile collides with: world, enemies (not friendly fire by default).
  static const int projectileMask = world | enemy | destructible;

  /// Item collides with: player only.
  static const int itemMask = player;

  /// Trigger collides with: player only.
  static const int triggerMask = player;
}
