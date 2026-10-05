import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../logging/logging_service.dart';

final _log = gameLogger('SecurityService');

/// Security utilities for the Cambric game template.
///
/// Provides checksum generation/verification for save files and
/// update artifacts, safe path validation, and input sanitization.
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  // ── Checksums ──────────────────────────────────────────────────────────

  /// Compute SHA-256 checksum of bytes.
  String computeChecksum(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Compute SHA-256 checksum of a string (e.g. JSON save).
  String computeStringChecksum(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Compute SHA-256 checksum of a file.
  Future<String?> computeFileChecksum(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return computeChecksum(bytes);
    } catch (e, st) {
      _log.severe('Failed to compute checksum for $path', e, st);
      return null;
    }
  }

  /// Verify a file's checksum against an expected value.
  Future<bool> verifyFileChecksum(String path, String expected) async {
    final actual = await computeFileChecksum(path);
    if (actual == null) return false;
    final matches = actual == expected;
    if (!matches) {
      _log.warning(
        'Checksum mismatch for $path: expected=$expected, actual=$actual',
      );
    }
    return matches;
  }

  // ── Path safety ────────────────────────────────────────────────────────

  /// Returns true if [path] is safe — no directory traversal sequences.
  bool isPathSafe(String path) {
    if (path.contains('..')) return false;
    if (path.contains('\x00')) return false; // null byte injection
    // Reject absolute paths that could escape the game data root
    if (path.startsWith('/') || (path.length > 1 && path[1] == ':')) {
      return false;
    }
    return true;
  }

  /// Sanitize a filename — strip illegal characters.
  String sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
  }

  // ── Input sanitization ─────────────────────────────────────────────────

  /// Sanitize a player-provided string for safe storage (no control chars).
  String sanitizeString(String input, {int maxLength = 256}) {
    final cleaned = input.replaceAll(RegExp(r'[\x00-\x08\x0E-\x1F\x7F]'), '');
    return cleaned.length > maxLength
        ? cleaned.substring(0, maxLength)
        : cleaned;
  }

  // ── Secret redaction ───────────────────────────────────────────────────

  /// Redact known sensitive keys from a map before logging.
  Map<String, dynamic> redactSecrets(Map<String, dynamic> data) {
    const sensitiveKeys = {
      'password', 'token', 'secret', 'key', 'apiKey', 'api_key',
      'credential', 'auth', 'signature',
    };
    return data.map((k, v) {
      final lower = k.toLowerCase();
      if (sensitiveKeys.any((s) => lower.contains(s))) {
        return MapEntry(k, '[REDACTED]');
      }
      return MapEntry(k, v);
    });
  }
}
