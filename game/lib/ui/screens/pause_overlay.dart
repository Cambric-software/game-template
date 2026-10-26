import 'package:flutter/material.dart';

import '../../bootstrap/bootstrap_service.dart';
import '../../core/localization/localization_service.dart';
import '../../game/runtime/cambric_game.dart';
import '../../settings/settings_service.dart';
import '../theme/design_tokens.dart';
import '../theme/game_palette.dart';
import '../widgets/game_controls.dart';
import '../widgets/game_dialogs.dart';
import '../widgets/game_surfaces.dart';
import '../widgets/settings_content.dart';
import 'settings_screen.dart';

/// Flutter pause menu rendered by Flame over the game canvas.
///
/// The clock and music are already paused by [CambricGame.pause]. This widget
/// only presents choices; it never mutates game state directly except through
/// the public pause/resume/exit methods.
class GamePauseOverlay extends StatefulWidget {
  const GamePauseOverlay({
    required this.game,
    required this.onExitToMenu,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    super.key,
  });

  final CambricGame game;
  final VoidCallback onExitToMenu;
  final ValueChanged<String> onThemeChanged;
  final AsyncStringCallback onLanguageChanged;

  @override
  State<GamePauseOverlay> createState() => _GamePauseOverlayState();
}

class _GamePauseOverlayState extends State<GamePauseOverlay> {
  final LocalizationService _l10n = LocalizationService();
  final SettingsService _settings = BootstrapService.settings;
  bool _busy = false;

  Future<void> _saveAndExit() async {
    setState(() => _busy = true);
    final saved = await BootstrapService.saveCurrentSession();
    if (!mounted) return;

    if (!saved) {
      setState(() => _busy = false);
      await showGameMessage(
        context,
        title: _l10n.t('save_failed'),
        message: _l10n.t('save_failed_body'),
      );
      return;
    }

    await BootstrapService.returnToMenu(widget.game);
    if (!mounted) return;
    widget.onExitToMenu();
  }

  Future<void> _quitToMenu() async {
    final confirmed = await showGameConfirm(
      context,
      title: _l10n.t('pause_quit_title'),
      message: _l10n.t('pause_quit_body'),
      confirmLabel: _l10n.t('menu_quit_to_menu'),
      danger: true,
    );
    if (!confirmed) return;

    await BootstrapService.returnToMenu(widget.game);
    if (!mounted) return;
    widget.onExitToMenu();
  }

  Future<void> _openSettings() async {
    await GameSettingsDialog.show(
      context,
      settings: _settings,
      l10n: _l10n,
      audio: widget.game.audioSystem,
      onThemeChanged: widget.onThemeChanged,
      onLanguageChanged: widget.onLanguageChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ColoredBox(
      color: p.bg.withValues(alpha: 0.86),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GameSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: GamePanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _l10n.t('menu_paused'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      GameStatusChip(
                        label: _l10n.t('menu_paused'),
                        tone: GameTone.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: GameSpacing.xl),
                  GameButton(
                    label: _l10n.t('menu_resume'),
                    icon: Icons.play_arrow_rounded,
                    variant: GameButtonVariant.primary,
                    autofocus: true,
                    onPressed: _busy ? null : widget.game.resume,
                  ),
                  const SizedBox(height: GameSpacing.sm),
                  GameButton(
                    label: _l10n.t('menu_settings'),
                    icon: Icons.tune,
                    onPressed: _busy ? null : _openSettings,
                  ),
                  const SizedBox(height: GameSpacing.sm),
                  GameButton(
                    label: _busy
                        ? _l10n.t('save_saving')
                        : _l10n.t('pause_save_quit'),
                    icon: Icons.save_outlined,
                    onPressed: _busy ? null : _saveAndExit,
                  ),
                  const SizedBox(height: GameSpacing.sm),
                  Divider(color: p.border),
                  const SizedBox(height: GameSpacing.sm),
                  GameButton(
                    label: _l10n.t('menu_quit_to_menu'),
                    icon: Icons.logout,
                    variant: GameButtonVariant.ghost,
                    onPressed: _busy ? null : _quitToMenu,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
