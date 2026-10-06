import 'dart:io';

import 'package:test/test.dart';

import 'package:cambric_game/save/autosave_service.dart';
import 'package:cambric_game/save/save_data.dart';
import 'package:cambric_game/save/save_service.dart';

void main() {
  late Directory tempDir;
  late SaveService saveService;
  late AutosaveService autosave;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cambric_autosave_test_');
    saveService = SaveService.testInstance(tempDir.path);
    autosave = AutosaveService(
      autosaveInterval: const Duration(seconds: 2),
    );
  });

  tearDown(() async {
    autosave.stopSession();
    await tempDir.delete(recursive: true);
  });

  group('AutosaveService', () {
    test('starts inactive before startSession()', () {
      expect(autosave.isSessionActive, isFalse);
    });

    test('becomes active after startSession()', () {
      autosave.startSession();
      expect(autosave.isSessionActive, isTrue);
    });

    test('becomes inactive after stopSession()', () {
      autosave.startSession();
      autosave.stopSession();
      expect(autosave.isSessionActive, isFalse);
    });

    test('does not crash when not initialized — just skips', () async {
      autosave.startSession();
      await expectLater(
        autosave.onUpdate(0.016, {}),
        completes,
      );
    });

    test('does not autosave when session not active', () async {
      // Session never started — onUpdate should be a no-op
      await autosave.onUpdate(999.0, {'data': 'test'});
      expect(await saveService.hasSave(SaveSlot.autosave), isFalse);
    });

    test('playtimeSeconds is 0 before any ticks', () {
      expect(autosave.playtimeSeconds, equals(0));
    });
  });
}
