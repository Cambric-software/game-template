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
import '../settings/settings_service.dart';

final _log = gameLogger('Bootstrap');

/// Orchestrates the complete startup sequence.
///
/// Called once from main(). Initializes all services in dependency order,
/// registers scenes, and returns a fully configured [CambricGame].
///
/// Startup order:
///   1. Feature flags
///   2. Logging
///   3. Configuration (manifest)
///   4. Game identity (from manifest)
///   5. Settings (player preferences)
///   6. Localization
///   7. Game + scene registration
class BootstrapService {
  static bool _initialized = false;

  /// Initialize all services and return a ready-to-run [CambricGame].
  /// Must be called only once.
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

    // 7. Create game
    final game = CambricGame();

    // 8. Register scenes
    game.sceneManager.register('mainMenu', () {
      final scene = MainMenuScene();
      scene.onNavigate = (name) async {
        game.stateManager.transition(GameState.playing);
        await game.sceneManager.transitionTo(name);
      };
      return scene;
    });
    game.sceneManager.register('gameplay', () => GameplayScene());

    // 9. State-change listener — sync state machine with scenes
    game.stateManager.addListener((from, to) async {
      switch (to) {
        case GameState.mainMenu:
          await game.sceneManager.transitionTo('mainMenu');
        default:
          break;
      }
    });

    _log.info(
      'Bootstrap complete. '
      'Scenes: ${game.sceneManager.registeredScenes}',
    );

    // Start in main menu
    await game.sceneManager.transitionTo('mainMenu');
    game.stateManager.transition(GameState.mainMenu);

    return game;
  }
}
