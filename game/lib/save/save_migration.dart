import '../core/logging/logging_service.dart';
import 'save_data.dart';

final _log = gameLogger('SaveMigration');

/// Migrates save data from older format versions to the current version.
///
/// Add a new [_MigrationStep] for every breaking change to the save format.
/// Steps run in order, chaining from the save's current version up to
/// [kCurrentSaveVersion].
///
/// Rules:
/// - Never delete a migration step once it has been released.
/// - A migration must never throw — return the original data on failure.
/// - A migration must never reduce the save version number.
class SaveMigration {
  const SaveMigration._();

  /// List of migration steps. Add new ones here when the save format changes.
  static final List<_MigrationStep> _steps = [
    // Example:
    // _MigrationStep(fromVersion: 1, toVersion: 2, migrate: _v1ToV2),
    // _MigrationStep(fromVersion: 2, toVersion: 3, migrate: _v2ToV3),
  ];

  /// Run all required migrations on [data] until it reaches
  /// [kCurrentSaveVersion]. Returns the migrated data (or original
  /// if no migration was needed or all migrations succeeded).
  static SaveData migrate(SaveData data) {
    var current = data;

    while (current.saveVersion < kCurrentSaveVersion) {
      final step = _steps.where(
        (s) => s.fromVersion == current.saveVersion,
      ).firstOrNull;

      if (step == null) {
        _log.warning(
          'No migration step from v${current.saveVersion} → '
          'v$kCurrentSaveVersion. Save may be incompatible.',
        );
        break;
      }

      _log.info(
        'Migrating save ${data.slotId}: '
        'v${step.fromVersion} → v${step.toVersion}',
      );

      try {
        current = step.migrate(current);
      } catch (e, st) {
        _log.severe(
          'Migration v${step.fromVersion}→v${step.toVersion} failed',
          e,
          st,
        );
        // Return the pre-migration data rather than corrupted data
        return data;
      }
    }

    return current;
  }

  /// Whether [data] needs migration.
  static bool needsMigration(SaveData data) =>
      data.saveVersion < kCurrentSaveVersion;

  // ── Migration implementations ──────────────────────────────────────────
  // Add private static methods here when the save format changes.
  // Example:
  // static SaveData _v1ToV2(SaveData data) {
  //   final newGameData = Map<String, dynamic>.from(data.gameData);
  //   newGameData['health'] = newGameData['hp'] ?? 100;
  //   newGameData.remove('hp');
  //   return data.copyWith(saveVersion: 2, gameData: newGameData);
  // }
}

class _MigrationStep {
  const _MigrationStep({
    required this.fromVersion,
    required this.toVersion,
    required this.migrate,
  });

  final int fromVersion;
  final int toVersion;
  final SaveData Function(SaveData) migrate;
}
