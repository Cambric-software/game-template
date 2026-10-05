import 'dart:io';
import 'dart:typed_data';

import '../logging/logging_service.dart';
import '../security/security_service.dart';

final _log = gameLogger('StorageService');

/// Low-level storage primitives with atomic write support.
///
/// All game-data writes go through this service so a write failure
/// can never destroy the previous valid file.
class StorageService {
  factory StorageService() => _instance;
  StorageService._internal();

  static final StorageService _instance = StorageService._internal();
  final SecurityService _security = SecurityService();

  // ── Atomic write ───────────────────────────────────────────────────────

  /// Write [content] to [path] atomically.
  ///
  /// Steps:
  ///   1. Write to `<path>.tmp`
  ///   2. Read-back verify
  ///   3. Rename tmp → [path] (atomic on NTFS/ext4)
  ///
  /// On any failure the original file at [path] is untouched.
  Future<bool> writeAtomic(String path, String content) async {
    final tmpPath = '$path.tmp';
    try {
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsString(content, flush: true);

      final readBack = await tmpFile.readAsString();
      if (readBack != content) {
        _log.severe('Atomic write read-back mismatch for $path');
        await _silentDelete(tmpPath);
        return false;
      }

      await tmpFile.rename(path);
      return true;
    } catch (e, st) {
      _log.severe('Atomic write failed for $path', e, st);
      await _silentDelete(tmpPath);
      return false;
    }
  }

  /// Write [bytes] atomically, verifying [expectedChecksum] before commit.
  Future<bool> writeBytesAtomic(
    String path,
    Uint8List bytes,
    String expectedChecksum,
  ) async {
    final tmpPath = '$path.tmp';
    try {
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsBytes(bytes, flush: true);

      final actual = await _security.computeFileChecksum(tmpPath);
      if (actual != expectedChecksum) {
        _log.severe('Byte checksum mismatch writing $path');
        await _silentDelete(tmpPath);
        return false;
      }

      await tmpFile.rename(path);
      return true;
    } catch (e, st) {
      _log.severe('Atomic bytes write failed for $path', e, st);
      await _silentDelete(tmpPath);
      return false;
    }
  }

  // ── Safe read ──────────────────────────────────────────────────────────

  Future<String?> readSafe(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e, st) {
      _log.warning('Failed to read $path', e, st);
      return null;
    }
  }

  // ── Existence / delete ─────────────────────────────────────────────────

  Future<bool> exists(String path) async => File(path).exists();

  Future<bool> delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
      return true;
    } catch (e, st) {
      _log.warning('Failed to delete $path', e, st);
      return false;
    }
  }

  Future<void> _silentDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // ── Copy / directory ───────────────────────────────────────────────────

  Future<bool> copyFile(String src, String dest) async {
    try {
      await File(src).copy(dest);
      return true;
    } catch (e, st) {
      _log.warning('Failed to copy $src → $dest', e, st);
      return false;
    }
  }

  Future<void> ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) await dir.create(recursive: true);
  }
}
