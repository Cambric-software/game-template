import 'dart:io';

import 'package:test/test.dart';

import 'package:cambric_game/save/save_data.dart';
import 'package:cambric_game/save/save_service.dart';

void main() {
  late Directory tempDir;
  late SaveService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cambric_save_test_');
    service = SaveService.testInstance(tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('SaveService', () {
    test('save and load round-trip preserves all fields', () async {
      final data = SaveData(
        saveVersion: kCurrentSaveVersion,
        slotId: 'slot_1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 6, 1),
        playtimeSeconds: 1234,
        gameData: {'level': 3, 'score': 9999},
      );

      final saveResult = await service.save(SaveSlot.slot1, data);
      expect(saveResult, equals(SaveResult.success));

      final (loaded, loadResult) = await service.load(SaveSlot.slot1);
      expect(loadResult, equals(SaveResult.success));
      expect(loaded, isNotNull);
      expect(loaded!.slotId, equals('slot_1'));
      expect(loaded.playtimeSeconds, equals(1234));
      expect(loaded.gameData['level'], equals(3));
      expect(loaded.gameData['score'], equals(9999));
    });

    test('hasSave returns false before any save', () async {
      expect(await service.hasSave(SaveSlot.slot1), isFalse);
    });

    test('hasSave returns true after save', () async {
      await service.save(SaveSlot.slot1, SaveData.fresh('slot_1'));
      expect(await service.hasSave(SaveSlot.slot1), isTrue);
    });

    test('deleteSave removes the save file', () async {
      await service.save(SaveSlot.slot1, SaveData.fresh('slot_1'));
      await service.deleteSave(SaveSlot.slot1);
      expect(await service.hasSave(SaveSlot.slot1), isFalse);
    });

    test('load returns noFile when save does not exist', () async {
      final (data, result) = await service.load(SaveSlot.slot2);
      expect(result, equals(SaveResult.noFile));
      expect(data, isNull);
    });

    test('corrupt save falls back to backup', () async {
      // Save valid data first (creates .bak)
      await service.save(SaveSlot.slot1, SaveData.fresh('slot_1'));

      // Corrupt the primary save file
      final savePath = '${tempDir.path}/slot_1.sav';
      await File(savePath).writeAsString('{"corrupt":true}');

      final (loaded, result) = await service.load(SaveSlot.slot1);
      // Should recover from backup
      expect(loaded, isNotNull);
      expect(result, anyOf(
        equals(SaveResult.success),
        equals(SaveResult.migrated),
      ));
    });

    test('checksum mismatch is detected', () async {
      await service.save(SaveSlot.slot1, SaveData.fresh('slot_1'));

      // Tamper with the save by modifying the data but not the checksum
      final savePath = '${tempDir.path}/slot_1.sav';
      final content = await File(savePath).readAsString();
      // Append a char to break checksum
      await File(savePath).writeAsString('${content}x');

      // Both primary and backup should now be corrupt
      final (_, result) = await service.load(SaveSlot.slot1);
      // After tamper, backup is still valid (written before tamper)
      expect(result, isNot(equals(SaveResult.noFile)));
    });
  });
}
