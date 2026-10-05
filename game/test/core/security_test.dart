import 'package:test/test.dart';

import 'package:cambric_game/core/security/security_service.dart';

void main() {
  late SecurityService security;

  setUp(() => security = SecurityService());

  group('SecurityService.computeStringChecksum', () {
    test('returns consistent SHA-256 for same input', () {
      const input = 'hello world';
      final a = security.computeStringChecksum(input);
      final b = security.computeStringChecksum(input);
      expect(a, equals(b));
    });

    test('different strings produce different checksums', () {
      final a = security.computeStringChecksum('hello');
      final b = security.computeStringChecksum('world');
      expect(a, isNot(equals(b)));
    });

    test('returns 64-character hex string (SHA-256)', () {
      final result = security.computeStringChecksum('test');
      expect(result.length, equals(64));
      expect(result, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('empty string has a valid checksum', () {
      final result = security.computeStringChecksum('');
      expect(result.length, equals(64));
    });
  });

  group('SecurityService.isPathSafe', () {
    test('normal relative path is safe', () {
      expect(security.isPathSafe('saves/slot_1'), isTrue);
      expect(security.isPathSafe('cache/data.json'), isTrue);
    });

    test('directory traversal is rejected', () {
      expect(security.isPathSafe('../etc/passwd'), isFalse);
      expect(security.isPathSafe('saves/../../secret'), isFalse);
    });

    test('null byte injection is rejected', () {
      expect(security.isPathSafe('saves/\x00hack'), isFalse);
    });

    test('absolute Windows path is rejected', () {
      expect(security.isPathSafe('C:/Windows/system32'), isFalse);
    });

    test('absolute Unix path is rejected', () {
      expect(security.isPathSafe('/etc/passwd'), isFalse);
    });
  });

  group('SecurityService.sanitizeFilename', () {
    test('strips illegal characters', () {
      final result = security.sanitizeFilename('my<file>name.txt');
      expect(result, equals('my_file_name.txt'));
    });

    test('strips path separators', () {
      final result = security.sanitizeFilename('path/to\\file');
      expect(result, equals('path_to_file'));
    });

    test('allows valid filename characters', () {
      final result = security.sanitizeFilename('save_01_v2.json');
      expect(result, equals('save_01_v2.json'));
    });
  });
}
