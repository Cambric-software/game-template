import 'package:test/test.dart';

import 'package:cambric_game/core/identity/game_identity.dart';

void main() {
  group('VersionComparator', () {
    test('older version is less than newer', () {
      expect(VersionComparator.compare('1.0.0', '1.0.1'), isNegative);
      expect(VersionComparator.compare('1.9.9', '2.0.0'), isNegative);
      expect(VersionComparator.compare('0.1.0', '1.0.0'), isNegative);
    });

    test('equal versions compare as zero', () {
      expect(VersionComparator.compare('1.0.0', '1.0.0'), equals(0));
      expect(VersionComparator.compare('2.5.3', '2.5.3'), equals(0));
    });

    test('newer version is greater', () {
      expect(VersionComparator.compare('1.0.1', '1.0.0'), isPositive);
      expect(VersionComparator.compare('2.0.0', '1.9.9'), isPositive);
    });

    test('handles v-prefixed strings', () {
      expect(VersionComparator.compare('v1.2.0', '1.2.0'), equals(0));
      expect(VersionComparator.compare('v2.0.0', 'v1.0.0'), isPositive);
    });

    test('isNewer: returns true when candidate is newer', () {
      expect(VersionComparator.isNewer('1.0.1', '1.0.0'), isTrue);
      expect(VersionComparator.isNewer('1.0.0', '1.0.0'), isFalse);
      expect(VersionComparator.isNewer('1.0.0', '1.0.1'), isFalse);
    });
  });

  group('GameIdentity', () {
    test('initialize sets values correctly', () {
      GameIdentity.initialize(
        name: 'Test Game',
        id: 'test-game',
        packageId: 'com.test.game',
        publisher: 'Test Publisher',
        developer: 'Test Dev',
        website: 'https://test.dev',
        repository: 'test-org/test-game',
        version: '1.2.3',
        buildNumber: 42,
        releaseChannel: 'stable',
      );

      expect(GameIdentity.name, equals('Test Game'));
      expect(GameIdentity.id, equals('test-game'));
      expect(GameIdentity.version, equals('1.2.3'));
      expect(GameIdentity.buildNumber, equals(42));
      expect(GameIdentity.releaseChannel, equals('stable'));
    });

    test('displayVersion combines version and build', () {
      GameIdentity.initialize(
        name: 'X',
        id: 'x',
        packageId: 'com.x',
        publisher: 'P',
        developer: 'D',
        website: '',
        repository: '',
        version: '0.5.0',
        buildNumber: 7,
        releaseChannel: 'stable',
      );
      expect(GameIdentity.displayVersion, equals('0.5.0 (7)'));
    });
  });
}
