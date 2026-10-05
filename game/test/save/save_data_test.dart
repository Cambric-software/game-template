import 'package:test/test.dart';

import 'package:cambric_game/save/save_data.dart';
import 'package:cambric_game/save/save_migration.dart';

void main() {
  group('SaveData', () {
    test('fresh() creates valid save with correct defaults', () {
      final save = SaveData.fresh('slot_1');
      expect(save.slotId, equals('slot_1'));
      expect(save.saveVersion, equals(kCurrentSaveVersion));
      expect(save.playtimeSeconds, equals(0));
      expect(save.gameData, isEmpty);
    });

    test('toJson / fromJson round-trip preserves fields', () {
      final original = SaveData(
        saveVersion: 1,
        slotId: 'slot_2',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 6, 15),
        playtimeSeconds: 3600,
        gameData: {'score': 500, 'level': 3},
      );

      final json = original.toJson();
      final restored = SaveData.fromJson(json);

      expect(restored.slotId, equals('slot_2'));
      expect(restored.saveVersion, equals(1));
      expect(restored.playtimeSeconds, equals(3600));
      expect(restored.gameData['score'], equals(500));
      expect(restored.gameData['level'], equals(3));
    });

    test('copyWith updates only specified fields', () {
      final original = SaveData.fresh('slot_1');
      final updated = original.copyWith(playtimeSeconds: 999);
      expect(updated.playtimeSeconds, equals(999));
      expect(updated.slotId, equals(original.slotId));
      expect(updated.saveVersion, equals(original.saveVersion));
    });

    group('playtimeDisplay', () {
      test('0 seconds shows 0m', () {
        final save = SaveData.fresh('slot_1');
        expect(save.playtimeDisplay, equals('0m'));
      });

      test('65 seconds shows 1m', () {
        final save = SaveData.fresh('slot_1').copyWith(playtimeSeconds: 65);
        expect(save.playtimeDisplay, equals('1m'));
      });

      test('3665 seconds shows 1h 1m', () {
        final save =
            SaveData.fresh('slot_1').copyWith(playtimeSeconds: 3665);
        expect(save.playtimeDisplay, equals('1h 1m'));
      });

      test('7200 seconds shows 2h 0m', () {
        final save =
            SaveData.fresh('slot_1').copyWith(playtimeSeconds: 7200);
        expect(save.playtimeDisplay, equals('2h 0m'));
      });
    });
  });

  group('SaveMigration', () {
    test('needsMigration returns false at current version', () {
      final save = SaveData.fresh('slot_1');
      expect(SaveMigration.needsMigration(save), isFalse);
    });

    test('needsMigration returns true for older version', () {
      final old = SaveData(
        saveVersion: 0,
        slotId: 'slot_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        playtimeSeconds: 0,
        gameData: const {},
      );
      // Only meaningful if kCurrentSaveVersion > 0
      if (kCurrentSaveVersion > 0) {
        expect(SaveMigration.needsMigration(old), isTrue);
      }
    });

    test('migrate: save already at current version is returned unchanged', () {
      final save = SaveData.fresh('slot_1');
      final migrated = SaveMigration.migrate(save);
      expect(migrated.saveVersion, equals(save.saveVersion));
      expect(migrated.slotId, equals(save.slotId));
    });

    test('migrate: no step available — returns original data', () {
      // Create a save with a version we don't have a step for
      final oddVersion = SaveData(
        saveVersion: kCurrentSaveVersion + 10, // future version
        slotId: 'slot_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        playtimeSeconds: 100,
        gameData: const {},
      );
      final result = SaveMigration.migrate(oddVersion);
      // Should return unchanged since no migration step exists upward
      expect(result.playtimeSeconds, equals(100));
    });
  });
}
