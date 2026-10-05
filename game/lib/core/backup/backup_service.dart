import 'dart:io';

import 'package:archive/archive_io.dart';

import '../core/logging/logging_service.dart';
import '../core/platform/platform_service.dart';
import '../core/security/security_service.dart';

final _log = gameLogger('BackupService');

/// Information about a single backup archive.
class BackupInfo {
  const BackupInfo({
    required this.path,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String path;
  final DateTime createdAt;
  final int sizeBytes;

  @override
  String toString() => 'BackupInfo($path, $createdAt, ${sizeBytes}B)';
}

/// Creates and manages save backups.
///
/// Backups are ZIP archives of the saves directory. They are kept
/// locally and never uploaded automatically.
///
/// A safe cleaner ([cleanOldBackups]) removes old archives beyond
/// [keepCount], preserving the most recent backups.
///
/// Backup archives NEVER touch or modify save files.
class BackupService {
  BackupService();

  final PlatformService _platform = PlatformService();
  final SecurityService _security = SecurityService();

  /// Create a ZIP backup of all saves for [gameId].
  /// Returns the path of the created archive, or null on failure.
  Future<String?> backupSaves(String gameId) async {
    try {
      final savesDir = await _platform.getSavesDirectory(gameId);
      final backupsDir = await _platform.getBackupsDirectory(gameId);

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final archivePath = '${backupsDir.path}/saves_$timestamp.zip';

      final encoder = ZipFileEncoder();
      encoder.create(archivePath);

      final saveFiles = savesDir.listSync().whereType<File>();
      for (final file in saveFiles) {
        encoder.addFile(file);
      }
      encoder.close();

      _log.info('Backup created: $archivePath');
      return archivePath;
    } catch (e, st) {
      _log.severe('Failed to create backup for $gameId', e, st);
      return null;
    }
  }

  /// List all backups for [gameId], sorted newest first.
  Future<List<BackupInfo>> listBackups(String gameId) async {
    try {
      final backupsDir = await _platform.getBackupsDirectory(gameId);
      final files = backupsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList();

      final infos = <BackupInfo>[];
      for (final file in files) {
        final stat = await file.stat();
        infos.add(BackupInfo(
          path: file.path,
          createdAt: stat.modified,
          sizeBytes: stat.size,
        ));
      }

      infos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return infos;
    } catch (e, st) {
      _log.warning('Failed to list backups for $gameId', e, st);
      return [];
    }
  }

  /// Restore saves from a backup archive.
  /// Returns true on success.
  Future<bool> restoreBackup(String gameId, String backupPath) async {
    try {
      final savesDir = await _platform.getSavesDirectory(gameId);
      final bytes = await File(backupPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.isFile) {
          final outPath = '${savesDir.path}/${file.name}';
          await File(outPath).writeAsBytes(file.content as List<int>);
        }
      }

      _log.info('Backup restored from $backupPath');
      return true;
    } catch (e, st) {
      _log.severe('Failed to restore backup from $backupPath', e, st);
      return false;
    }
  }

  /// Delete old backups, keeping only the [keepCount] most recent.
  Future<void> cleanOldBackups(String gameId, {int keepCount = 3}) async {
    try {
      final backups = await listBackups(gameId);
      if (backups.length <= keepCount) return;

      final toDelete = backups.skip(keepCount);
      for (final backup in toDelete) {
        await File(backup.path).delete();
        _log.info('Deleted old backup: ${backup.path}');
      }
    } catch (e, st) {
      _log.warning('Failed to clean old backups for $gameId', e, st);
    }
  }
}
