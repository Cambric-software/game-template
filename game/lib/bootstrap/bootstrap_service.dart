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

  // Exposed so the gameplay loop can call autosave.onUpdate(dt, data)
  static late final SaveService saveService;
  static late final AutosaveService autosaveService;

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
    final settings = SettingsService();
    await settings.initialize();

    // 6. Localization
    final l10n = LocalizationService();
    await l10n.load(settings.language);
    _log.info('Locale: ${l10n.currentLocale} (RTL: ${l10n.isRtl})');

    // 7. Save system — must be initialized before any game scene starts
    saveService = SaveService();
    await saveService.initialize(config.gameId);
    _log.info('Save system initialized');

    // 8. Autosave service
    autosaveService = AutosaveService();
    autosaveService.initialize(saveService, settings);
    _log.info('Autosave service initialized');

    // 9. Create game
    final game = CambricGame();

    // 10. Register scenes
    game.sceneManager.register('mainMenu', () {
      final scene = MainMenuScene();
      scene.onNavigate = (name) async {
        game.stateManager.transition(GameState.playing);
        // Start autosave session when gameplay begins
        autosaveService.startSession();
        await game.sceneManager.transitionTo(name);
      };
      return scene;
    });
    game.sceneManager.register('gameplay', () => GameplayScene());

    // 11. State-change listener
    game.stateManager.addListener((from, to) async {
      switch (to) {
        case GameState.mainMenu:
          // Stop autosave when returning to menu
          autosaveService.stopSession();
          await game.sceneManager.transitionTo('mainMenu');
        case GameState.exiting:
          autosaveService.stopSession();
        default:
          break;
      }
    });

    _log.info(
      'Bootstrap complete. Scenes: ${game.sceneManager.registeredScenes}',
    );

    // Start in main menu
    await game.sceneManager.transitionTo('mainMenu');
    game.stateManager.transition(GameState.mainMenu);

    return game;
  }
}
