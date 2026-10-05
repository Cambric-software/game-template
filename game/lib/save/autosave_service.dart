import '../core/features/feature_flags.dart';
import '../core/logging/logging_service.dart';
import '../settings/settings_service.dart';
import 'save_data.dart';
import 'save_service.dart';

final _log = gameLogger('AutosaveService');

/// Manages automatic saving at regular intervals.
///
/// Tracks playtime and triggers autosaves while gameplay is active.
/// Autosaves go to [SaveSlot.autosave] by default.
///
/// Usage:
/// ```dart
/// autosave.startSession();
/// // In game update loop:
/// autosave.onUpdate(dt, myGameData);
/// // On pause / game over:
/// autosave.stopSession();
/// ```
class AutosaveService {
  AutosaveService({
    this.autosaveInterval = const Duration(minutes: 5),
  });

  final Duration autosaveInterval;

  SaveService? _saveService;
  SettingsService? _settings;
  bool _sessionActive = false;
  int _playtimeSeconds = 0;
  double _secondsSinceLastSave = 0;
  DateTime? _sessionStarted;

  void initialize(SaveService saveService, SettingsService settings) {
    _saveService = saveService;
    _settings = settings;
    _log.info(
      'AutosaveService initialized '
      '(interval: ${autosaveInterval.inMinutes}m)',
    );
  }

  void startSession() {
    _sessionActive = true;
    _sessionStarted = DateTime.now();
    _secondsSinceLastSave = 0;
    _log.info('Autosave session started');
  }

  void stopSession() {
    _sessionActive = false;
    _log.info(
      'Autosave session stopped '
      '(playtime: ${_playtimeSeconds}s)',
    );
  }

  /// Call from the game update loop with current game state data.
  Future<void> onUpdate(
    double dt,
    Map<String, dynamic> gameData, {
    String slotId = 'autosave',
  }) async {
    if (!_sessionActive) return;
    if (!FeatureFlags.autosaveEnabled) return;
    if (!(_settings?.autosaveEnabled ?? true)) return;
    if (_saveService == null) return;

    _playtimeSeconds += dt.round();
    _secondsSinceLastSave += dt;

    if (_secondsSinceLastSave >= autosaveInterval.inSeconds) {
      _secondsSinceLastSave = 0;
      await _doAutosave(gameData, slotId);
    }
  }

  Future<void> _doAutosave(
    Map<String, dynamic> gameData,
    String slotId,
  ) async {
    try {
      _log.info('Autosaving to slot: $slotId');
      final data = SaveData(
        saveVersion: kCurrentSaveVersion,
        slotId: slotId,
        createdAt: _sessionStarted ?? DateTime.now(),
        updatedAt: DateTime.now(),
        playtimeSeconds: _playtimeSeconds,
        gameData: gameData,
      );
      final result = await _saveService!.save(
        SaveSlot.defaultSlots.firstWhere(
          (s) => s.id == slotId,
          orElse: () => SaveSlot.autosave,
        ),
        data,
      );
      if (result == SaveResult.success) {
        _log.info('Autosave completed');
      } else {
        _log.warning('Autosave failed: $result');
      }
    } catch (e, st) {
      // Autosave failure must NEVER crash the game
      _log.warning('Autosave threw unexpectedly', e, st);
    }
  }

  int get playtimeSeconds => _playtimeSeconds;
  bool get isSessionActive => _sessionActive;
}
