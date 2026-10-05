import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/identity/game_identity.dart';
import '../core/localization/localization_service.dart';
import '../game/runtime/cambric_game.dart';
import '../game/state/game_state_manager.dart';

/// Root Flutter widget for the Cambric game.
///
/// Wraps the Flame GameWidget with Directionality for RTL support.
/// App lifecycle events (background/foreground) are handled here.
class CambricApp extends StatefulWidget {
  const CambricApp({required this.game, super.key});

  final CambricGame game;

  @override
  State<CambricApp> createState() => _CambricAppState();
}

class _CambricAppState extends State<CambricApp> with WidgetsBindingObserver {
  final LocalizationService _l10n = LocalizationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (widget.game.stateManager.isPlaying) {
          widget.game.stateManager.transition(GameState.paused);
          widget.game.audioSystem.onGamePaused();
        }
      case AppLifecycleState.resumed:
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _l10n.textDirection,
      child: MaterialApp(
        title: GameIdentity.name,
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          backgroundColor: Colors.black,
          body: GameWidget(
            game: widget.game,
            loadingBuilder: (context) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorBuilder: (context, error) => Center(
              child: Text(
                'Failed to start game:\n$error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            overlayBuilderMap: {
              'pause_menu': (context, game) => _PauseOverlay(
                    game: game as CambricGame,
                  ),
            },
          ),
        ),
      ),
    );
  }
}

/// Pause menu overlay — rendered by Flutter on top of the Flame canvas.
class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.game});

  final CambricGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xAA000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _MenuButton(
              label: 'Resume',
              onPressed: () {
                game.stateManager.transition(GameState.playing);
                game.audioSystem.onGameResumed();
                game.overlays.remove('pause_menu');
              },
            ),
            const SizedBox(height: 12),
            _MenuButton(
              label: 'Main Menu',
              onPressed: () {
                game.overlays.remove('pause_menu');
                game.stateManager.transition(GameState.mainMenu);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 48),
      ),
      child: Text(label),
    );
  }
}
