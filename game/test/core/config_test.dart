import 'package:test/test.dart';

import 'package:cambric_game/core/config/configuration_service.dart';

void main() {
  group('ConfigurationService', () {
    late ConfigurationService config;

    setUp(() {
      // Create a fresh instance for each test via the singleton
      config = ConfigurationService();
    });

    test('loadFromManifest populates game name and version', () async {
      const manifest = '''
{
  "product": {
    "name": "My Test Game",
    "id": "my-test-game",
    "version": "2.3.4",
    "releaseChannel": "stable",
    "repository": "org/repo"
  },
  "platforms": ["windows", "android"],
  "locales": ["en", "ar"],
  "gameType": "2d",
  "orientation": "landscape"
}
''';
      await config.loadFromManifest(manifest);
      expect(config.gameName, equals('My Test Game'));
      expect(config.gameId, equals('my-test-game'));
      expect(config.gameVersion, equals('2.3.4'));
      expect(config.supportedPlatforms, containsAll(['windows', 'android']));
      expect(config.supportedLocales, containsAll(['en', 'ar']));
      expect(config.isLoaded, isTrue);
    });

    test('loadFromManifest: missing fields use defaults', () async {
      await config.loadFromManifest('{}');
      expect(config.gameName, equals('Cambric Game'));
      expect(config.gameId, equals('cambric-game'));
      expect(config.gameVersion, equals('0.1.0'));
    });

    test('loadFromManifest: invalid JSON does not throw', () async {
      await expectLater(
        config.loadFromManifest('{invalid json'),
        completes,
      );
    });

    test('capabilities return correct defaults when absent', () async {
      await config.loadFromManifest('{}');
      expect(config.offlineCapable, isTrue);
      expect(config.keyboardCapable, isTrue);
    });

    test('capabilities read from manifest', () async {
      const manifest = '''
{
  "capabilities": {
    "touch": false,
    "keyboard": true,
    "mouse": false,
    "gamepad": true,
    "offline": true
  }
}
''';
      await config.loadFromManifest(manifest);
      expect(config.touchCapable, isFalse);
      expect(config.keyboardCapable, isTrue);
      expect(config.mouseCapable, isFalse);
      expect(config.gamepadCapable, isTrue);
    });
  });
}
