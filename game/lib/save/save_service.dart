import 'dart:convert';

import '../core/logging/logging_service.dart';
import '../core/platform/platform_service.dart';
import '../core/security/security_service.dart';
import '../core/storage/storage_service.dart';
import 'save_data.dart';
import 'save_migration.dart';

final _log = gameLogger('SaveService');

/// Result type for save operations.
enum SaveResult { success, failed, corrupt, noFile, migrated }

/// Complete save-game system.
///
/// Implements atomic writes, backup creation, corruption detection,
/// backup recovery, and automatic migration.
///
/// Write flow:
///   serialize → write .tmp → verify → rename → copy .bak
///
/// Read flow:
///   read .sav → verify checksum → if corrupt try .bak → report
///
/// The player's last valid save is NEVER overwritten until the
/// new save has been fully verified.
class SaveService {
  static final SaveService _instance = SaveService._internal();
  factory SaveService() => _instance;
  SaveService._internal();

  final PlatformService _platform = PlatformService();
  final StorageService _storage = StorageService();
  final SecurityService _security = SecurityService();

  bool _initialized = false;
  String? _savesPath;

  Future<void> initialize(String gameId) async {
    if (_initialized) return;
    final dir = await _platform.getSavesDirectory(gameId);
    _savesPath = dir.path;
    _initialized = true;
    _log.info('Save service initialized at $_savesPath');
  }

  void _assertInitialized() {
    if (!_initialized || _savesPath == null) {
      throw StateError('SaveService not initialized. Call initialize() first.');
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────

  /// Save [data] to [slot].
  ///
  /// Returns [SaveResult.success] on success.
  /// Returns [SaveResult.failed] if the write could not be completed.
  Future<SaveResult> save(SaveSlot slot, SaveData data) async {
    _assertInitialized();

    final savePath = _pathFor(slot.id);
    final backupPath = _backupPathFor(slot.id);

    try {
      // Serialize
      final json = jsonEncode(data.toJson());
      final checksum = _security.computeStringChecksum(json);

      // Write the envelope: JSON + checksum
      final envelope = jsonEncode({'data': json, 'checksum': checksum});

      // Atomic write
      final success = await _storage.writeAtomic(savePath, envelope);
      if (!success) {
        _log.severe('Atomic write failed for slot ${slot.id}');
        return SaveResult.failed;
      }

      // Create backup of the newly verified save
      await _storage.copyFile(savePath, backupPath);

      _log.info('Saved slot ${slot.id} (v${data.saveVersion})');
      return SaveResult.success;
    } catch (e, st) {
      _log.severe('Save failed for slot ${slot.id}', e, st);
      return SaveResult.failed;
    }
  }

  // ── Load ───────────────────────────────────────────────────────────────

  /// Load save data from [slot].
  ///
  /// Returns the data and a result code.
  /// If the primary save is corrupt, attempts recovery from backup.
  /// If both are unreadable, returns null with [SaveResult.corrupt].
  Future<(SaveData?, SaveResult)> load(SaveSlot slot) async {
    _assertInitialized();

    final savePath = _pathFor(slot.id);
    final backupPath = _backupPathFor(slot.id);

    // Try primary
    final primary = await _readAndVerify(savePath);
    if (primary != null) {
      final migrated = SaveMigration.migrate(primary);
      final result = primary.saveVersion < migrated.saveVersion
          ? SaveResult.migrated
          : SaveResult.success;
      return (migrated, result);
    }

    // Primary failed — try backup
    _log.warning('Primary save corrupt or missing for ${slot.id}. Trying backup.');
    final backup = await _readAndVerify(backupPath);
    if (backup != null) {
      _log.info('Recovered from backup for slot ${slot.id}');
      final migrated = SaveMigration.migrate(backup);
      // Restore the backup as the primary
      await save(slot, migrated);
      return (migrated, SaveResult.migrated);
    }

    // Check if file simply doesn't exist
    final exists = await _storage.exists(savePath);
    if (!exists) return (null, SaveResult.noFile);

    _log.severe('Both primary and backup corrupt for slot ${slot.id}');
    return (null, SaveResult.corrupt);
  }

  // ── Exists ─────────────────────────────────────────────────────────────

  Future<bool> hasSave(SaveSlot slot) async {
    _assertInitialized();
    return _storage.exists(_pathFor(slot.id));
  }

  // ── Delete ─────────────────────────────────────────────────────────────

  Future<bool> deleteSave(SaveSlot slot) async {
    _assertInitialized();
    final a = await _storage.delete(_pathFor(slot.id));
    final b = await _storage.delete(_backupPathFor(slot.id));
    return a && b;
  }

  // ── List slots ─────────────────────────────────────────────────────────

  /// Returns metadata for all default slots that have saves.
  Future<List<SaveSlotInfo>> listSlots() async {
    _assertInitialized();
    final results = <SaveSlotInfo>[];
    for (final slot in SaveSlot.defaultSlots) {
      final path = _pathFor(slot.id);
      final exists = await _storage.exists(path);
      if (exists) {
        final (data, _) = await load(slot);
        results.add(SaveSlotInfo(slot: slot, data: data));
      } else {
        results.add(SaveSlotInfo(slot: slot, data: null));
      }
    }
    return results;
  }

  // ── Internal ───────────────────────────────────────────────────────────

  Future<SaveData?> _readAndVerify(String path) async {
    final content = await _storage.readSafe(path);
    if (content == null) return null;

    try {
      final envelope = jsonDecode(content) as Map<String, dynamic>;
      final dataJson = envelope['data'] as String?;
      final storedChecksum = envelope['checksum'] as String?;

      if (dataJson == null || storedChecksum == null) return null;

      // Verify checksum
      final actualChecksum = _security.computeStringChecksum(dataJson);
      if (actualChecksum != storedChecksum) {
        _log.warning('Checksum mismatch reading $path');
        return null;
      }

      final dataMap = jsonDecode(dataJson) as Map<String, dynamic>;
      return SaveData.fromJson(dataMap);
    } catch (e, st) {
      _log.warning('Failed to parse save at $path', e, st);
      return null;
    }
  }

  String _pathFor(String slotId) => '$_savesPath/$slotId.sav';
  String _backupPathFor(String slotId) => '$_savesPath/$slotId.sav.bak';
}

/// Slot info including optional save data for the slot list UI.
class SaveSlotInfo {
  const SaveSlotInfo({required this.slot, required this.data});

  final SaveSlot slot;
  final SaveData? data;

  bool get isEmpty => data == null;
}
