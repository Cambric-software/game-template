import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bootstrap/bootstrap_service.dart';
import '../core/identity/game_identity.dart';
import '../core/localization/localization_service.dart';
import '../game/runtime/cambric_game.dart';
import '../save/save_data.dart';
import '../settings/settings_service.dart';
import '../ui/screens/main_menu_screen.dart';
import '../ui/screens/pause_overlay.dart';
import '../ui/screens/save_slots_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/theme/game_palette.dart';
import '../ui/theme/game_theme.dart';
import '../ui/widgets/game_dialogs.dart';
import '../ui/widgets/game_surfaces.dart';

/// Root Flutter widget for the Cambric game.
///
/// The Flame canvas stays mounted behind every screen so scene state and
/// loaded assets survive a trip through the menu. Screens above it are opaque
/// and own focus, which keeps keyboard navigation out of the hidden canvas.
class CambricApp extends StatefulWidget {
  const CambricApp({required this.game, super.key});

  final CambricGame game;

  @override
  State<CambricApp> createState() => _CambricAppState();
}

enum _AppScreen { menu, saves, settings, game }

class _CambricAppState extends State<CambricApp> with WidgetsBindingObserver {
  final LocalizationService _l10n = BootstrapService.localization;
  final SettingsService _settings = BootstrapService.settings;

  late ThemeMode _themeMode;
  _AppScreen _screen = _AppScreen.menu;
  bool _hasSaves = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeMode = _settings.uiTheme == 'light' ? ThemeMode.light : ThemeMode.dark;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    BootstrapService.showMainMenu(widget.game);
    _refreshSaves();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // No-op unless a session is actually playing.
      widget.game.pause();
    }
  }

  Future<void> _refreshSaves() async {
    try {
      final slots = await BootstrapService.saveService.listSlots();
      if (!mounted) return;
      setState(() => _hasSaves = slots.any((slot) => !slot.isEmpty));
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasSaves = false);
    }
  }

  Future<void> _startGameplay({SaveSlot? slot, bool loadExisting = true}) async {
    setState(() {
      _screen = _AppScreen.game;
      _starting = true;
    });

    try {
      await BootstrapService.startGameplay(
        widget.game,
        slot: slot,
        loadExisting: loadExisting,
      );
      if (mounted) setState(() => _starting = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _screen = _AppScreen.menu;
        _starting = false;
      });
      await showGameMessage(
        context,
        title: _l10n.t('error_generic'),
        message: error.toString(),
      );
    }
  }

  Future<void> _showMenu() async {
    setState(() => _screen = _AppScreen.menu);
    await _refreshSaves();
  }

  void _changeTheme(String value) {
    _settings.uiTheme = value;
    setState(() {
      _themeMode = value == 'light' ? ThemeMode.light : ThemeMode.dark;
    });
  }

  Future<void> _changeLanguage(String value) async {
    await _l10n.load(value);
    _settings.language = value;
    if (mounted) setState(() {});
  }

  Future<void> _quit() async {
    final confirmed = await showGameConfirm(
      context,
      title: _l10n.t('menu_quit_confirm_title'),
      message: _l10n.t('menu_quit_confirm_body'),
      confirmLabel: _l10n.t('menu_exit'),
      danger: true,
    );
    if (!confirmed) return;

    if (Platform.isAndroid || Platform.isIOS) {
      await SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: GameIdentity.name,
      debugShowCheckedModeBanner: false,
      theme: GameTheme.light,
      darkTheme: GameTheme.dark,
      themeMode: _themeMode,
      builder: (context, child) => Directionality(
        textDirection: _l10n.textDirection,
        child: child ?? const SizedBox.shrink(),
      ),
      home: Builder(
        builder: (context) {
          final palette = context.palette;

          return Scaffold(
            backgroundColor: palette.bg,
            body: Stack(
              fit: StackFit.expand,
              children: [
                TickerMode(
                  enabled: _screen == _AppScreen.game,
                  child: GameWidget<CambricGame>(
                    game: widget.game,
                    loadingBuilder: (context) => GameBackdrop(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              _l10n.t('loading_please_wait'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    errorBuilder: (context, error) => GameBackdrop(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: GamePanel(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: context.palette.danger,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _l10n.t('error_generic'),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$error',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    overlayBuilderMap: {
                      'pause_menu': (context, game) => GamePauseOverlay(
                            game: game,
                            onExitToMenu: _showMenu,
                            onThemeChanged: _changeTheme,
                            onLanguageChanged: _changeLanguage,
                          ),
                    },
                  ),
                ),
                if (_screen == _AppScreen.menu)
                  MainMenuScreen(
                    hasSaves: _hasSaves,
                    onNewGame: () => _startGameplay(loadExisting: false),
                    onContinue: () => setState(() => _screen = _AppScreen.saves),
                    onSaveFiles: () => setState(() => _screen = _AppScreen.saves),
                    onSettings: () =>
                        setState(() => _screen = _AppScreen.settings),
                    onQuit: _quit,
                  ),
                if (_screen == _AppScreen.saves)
                  SaveSlotsScreen(
                    onPlay: (slot) => _startGameplay(slot: slot),
                    onBack: () => setState(() => _screen = _AppScreen.menu),
                  ),
                if (_screen == _AppScreen.settings)
                  SettingsScreen(
                    settings: _settings,
                    l10n: _l10n,
                    audio: widget.game.audioSystem,
                    onThemeChanged: _changeTheme,
                    onLanguageChanged: _changeLanguage,
                    onBack: () => setState(() => _screen = _AppScreen.menu),
                  ),
                if (_starting)
                  ColoredBox(
                    color: palette.bg.withValues(alpha: 0.92),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            _l10n.t('loading_please_wait'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
