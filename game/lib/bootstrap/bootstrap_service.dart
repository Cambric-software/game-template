import 'package:flutter/services.dart';

import '../core/config/configuration_service.dart';
import '../core/features/feature_flags.dart';
import '../core/identity/game_identity.dart';
import '../core/localization/localization_service.dart';
import '../core/logging/logging_service.dart';
import '../game/runtime/cambric_game.dart';
import '../game/state/game_state_manager.dart';
import '../gameplay/scenes/gameplay_scene.dart';
import '../gameplay/scenes/main_menu_scene.dart';
import '../save/autosave_service.dart';
import '../save/save_data.dart';
import '../save/save_service.dart';
import '../settings/settings_service.dart';

final _log = gameLogger('Bootstrap');

/// Orchestrates the complete startup sequence.
///
/// Startup order:
///   1. Feature flags
///   2. Logging
///   3. Configuration (manifest)
///   4. Game identity
///   5. Settings
///   6. Localization
///   7. SaveService   ← initialized here so saves work from first frame
///   8. AutosaveService
///   9. Game + scene registration
class BootstrapService {
  static bool _initialized = false;

  // Exposed so the Flutter shell and gameplay loop share one instance.
  static late final SaveService saveService;
  static late final AutosaveService autosaveService;
  static late final SettingsService settings;
  static late final LocalizationService localization;

  /// The slot used by autosave and "Save & quit". Set when a session starts.
  static SaveSlot activeSlot = SaveSlot.autosave;

  /// The save that was loaded for this session, if any. The template does not
  /// apply it to the demo scene; games can read it to restore world state.
  static SaveData? loadedSave;

  static Future<CambricGame> initialize() async {
    if (_initialized) {
      throw StateError('BootstrapService.initialize() called more than once.');
    }
    _initialized = true;

    // 1. Feature flags — must be first
    FeatureFlags.initializeDefaults();

    // 2. Logging
    LoggingService().initialize(verbose: FeatureFlags.verboseLogging);
    _log.info('=== Cambric Game starting ===');

    // 3. Configuration from bundled manifest asset
    final config = ConfigurationService();
    try {
      final manifestJson = await rootBundle.loadString(
        'assets/cambric.manifest.json',
      );
      await config.loadFromManifest(manifestJson);
    } catch (e) {
      _log.warning('Could not load manifest asset, using defaults: $e');
    }

    // 4. Game identity
    GameIdentity.initialize(
      name: config.gameName,
      id: config.gameId,
      packageId: config.gameId.replaceAll('-', '.'),
      publisher: 'Cambric',
      developer: 'Cambric',
      website: 'https://cambric.dev',
      repository: config.repository,
      version: config.gameVersion,
      buildNumber: 1,
      releaseChannel: config.releaseChannel,
    );
    _log.info('Identity: ${GameIdentity.name} v${GameIdentity.version}');

    // 5. Settings
    settings = SettingsService();
    await settings.initialize();

    // 6. Localization
    localization = LocalizationService();
    await localization.load(settings.language);
    _log.info(
      'Locale: ${localization.currentLocale} '
      '(RTL: ${localization.isRtl})',
    );

    // 7. Save system — must be initialized before any game scene starts
    saveService = SaveService();
    await saveService.initialize(config.gameId);
    _log.info('Save system initialized');

    // 8. Autosave service
    autosaveService = AutosaveService();
    autosaveService.initialize(saveService, settings);
    _log.info('Autosave service initialized');

    // 9. Create game. SceneManager exists from the constructor, so scenes
    // can be registered before the GameWidget mounts.
    final game = CambricGame();

    // 10. Register scenes
    game.sceneManager.register('mainMenu', () {
      final scene = MainMenuScene();
      scene.onNavigate = (name) async {
        if (name == 'gameplay') await startGameplay(game);
      };
      return scene;
    });
    game.sceneManager.register('gameplay', () => GameplayScene());

    // 11. Stop autosave when a session ends.
    game.stateManager.addListener((from, to) {
      if (to == GameState.mainMenu || to == GameState.exiting) {
        autosaveService.stopSession();
      }
    });

    _log.info(
      'Bootstrap complete. Scenes: ${game.sceneManager.registeredScenes}',
    );

    return game;
  }

  /// Put the shell in its menu state. The Flutter menu is the visible surface,
  /// so no Flame scene is loaded until a session starts.
  static void showMainMenu(CambricGame game) {
    game.onPlayingTick = null;
    if (!game.stateManager.isInMenu) {
      game.stateManager.transition(GameState.mainMenu);
    }
  }

  /// Start a session in [slot], loading it when [loadExisting] is true.
  static Future<void> startGameplay(
    CambricGame game, {
    SaveSlot? slot,
    bool loadExisting = true,
  }) async {
    await game.whenLoaded;

    activeSlot = slot ?? SaveSlot.autosave;

    SaveData? data;
    if (loadExisting) {
      final (loaded, result) = await saveService.load(activeSlot);
      data = loaded;
      _log.info('Start from ${activeSlot.id}: ${result.name}');
    }

    loadedSave = data;

    autosaveService.startSession(
      initialPlaytimeSeconds: data?.playtimeSeconds ?? 0,
    );

    game.onPlayingTick = (dt) {
      autosaveService.onUpdate(
        dt,
        {'scene': game.sceneManager.activeSceneName},
        slotId: activeSlot.id,
      );
    };

    game.stateManager.transition(GameState.playing);
    await game.sceneManager.transitionTo('gameplay');
  }

  /// Persist the current session to [activeSlot].
  ///
  /// The demo game has no world state to serialise, so it records the active
  /// scene and the real playtime. Replace `gameData` with your own fields.
  static Future<bool> saveCurrentSession() async {
    final (existing, _) = await saveService.load(activeSlot);
    final base = existing ?? SaveData.fresh(activeSlot.id);
    final data = base.copyWith(
      updatedAt: DateTime.now(),
      playtimeSeconds: autosaveService.playtimeSeconds,
      gameData: {
        ...base.gameData,
        'scene': 'gameplay',
      },
    );

    final result = await saveService.save(activeSlot, data);
    final ok = result == SaveResult.success || result == SaveResult.migrated;
    _log.info('Session save to ${activeSlot.id}: ${result.name}');
    return ok;
  }

  /// Leave gameplay and restore the Flame menu scene behind the Flutter menu.
  static Future<void> returnToMenu(CambricGame game) async {
    game.onPlayingTick = null;
    game.leavePause();

    if (!game.stateManager.isInMenu) {
      game.stateManager.transition(GameState.mainMenu);
    }

    await game.sceneManager.transitionTo('mainMenu');
  }
}
