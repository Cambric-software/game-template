import 'package:flutter/material.dart';

import '../../core/identity/game_identity.dart';
import '../../core/localization/localization_service.dart';
import '../theme/design_tokens.dart';
import '../theme/game_palette.dart';
import '../widgets/game_controls.dart';
import '../widgets/game_surfaces.dart';

/// The Flutter main menu. The Flame scene behind it is only a background;
/// all input, labels and focus live here so the menu is accessible and can
/// be translated without drawing text on the canvas.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    required this.hasSaves,
    required this.onNewGame,
    required this.onContinue,
    required this.onSaveFiles,
    required this.onSettings,
    required this.onQuit,
    super.key,
  });

  final bool hasSaves;
  final VoidCallback onNewGame;
  final VoidCallback onContinue;
  final VoidCallback onSaveFiles;
  final VoidCallback onSettings;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return GameBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= GameBreakpoints.wide;
            final hero = _Hero(wide: wide);
            final menu = _MenuPanel(
              hasSaves: hasSaves,
              onNewGame: onNewGame,
              onContinue: onContinue,
              onSaveFiles: onSaveFiles,
              onSettings: onSettings,
              onQuit: onQuit,
            );

            if (wide) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: GameSizes.content),
                  child: Padding(
                    padding: const EdgeInsets.all(GameSpacing.xxl),
                    child: Row(
                      children: [
                        Expanded(child: hero),
                        const SizedBox(width: GameSpacing.xxxl),
                        SizedBox(width: GameSizes.menuPanel, child: menu),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(GameSpacing.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - GameSpacing.xxxl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        hero,
                        const SizedBox(height: GameSpacing.xl),
                        menu,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final p = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [p.primary, p.accent],
                ),
                borderRadius: BorderRadius.circular(GameRadii.button),
              ),
              child: Icon(
                Icons.sports_esports,
                size: 19,
                color: p.onPrimary,
              ),
            ),
            const SizedBox(width: GameSpacing.md),
            Text(
              'CAMBRIC',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: p.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.2,
                  ),
            ),
          ],
        ),
        const SizedBox(height: GameSpacing.xl),
        Text(
          GameIdentity.name,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: wide ? 60 : 42,
              ),
        ),
        const SizedBox(height: GameSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            l10n.t('menu_subtitle'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: p.secondary,
                  fontSize: wide ? 17 : 15.5,
                ),
          ),
        ),
        const SizedBox(height: GameSpacing.xl),
        Wrap(
          spacing: GameSpacing.sm,
          runSpacing: GameSpacing.sm,
          children: [
            GameChip(
              l10n.t(
                'version_label',
                params: {'version': GameIdentity.displayVersion},
              ),
              icon: Icons.tag,
            ),
            const GameChip('Flutter + Flame', icon: Icons.bolt_outlined),
            GameStatusChip(
              label: l10n.t('menu_offline'),
              tone: GameTone.success,
            ),
          ],
        ),
        const SizedBox(height: GameSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.keyboard_outlined, size: 16, color: p.muted),
            const SizedBox(width: GameSpacing.sm),
            Expanded(
              child: Text(
                l10n.t('menu_controls_hint'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.hasSaves,
    required this.onNewGame,
    required this.onContinue,
    required this.onSaveFiles,
    required this.onSettings,
    required this.onQuit,
  });

  final bool hasSaves;
  final VoidCallback onNewGame;
  final VoidCallback onContinue;
  final VoidCallback onSaveFiles;
  final VoidCallback onSettings;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final p = context.palette;

    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameSectionLabel(l10n.t('menu_play')),
          GameButton(
            label: l10n.t('menu_new_game'),
            icon: Icons.play_arrow_rounded,
            variant: GameButtonVariant.primary,
            autofocus: true,
            onPressed: onNewGame,
          ),
          const SizedBox(height: GameSpacing.sm),
          GameButton(
            label: l10n.t('menu_continue'),
            icon: Icons.history,
            onPressed: hasSaves ? onContinue : null,
            helper: hasSaves ? null : l10n.t('menu_no_saves'),
          ),
          const SizedBox(height: GameSpacing.sm),
          Divider(color: p.border),
          const SizedBox(height: GameSpacing.sm),
          GameButton(
            label: l10n.t('menu_save_files'),
            icon: Icons.folder_open_outlined,
            variant: GameButtonVariant.ghost,
            onPressed: onSaveFiles,
          ),
          GameButton(
            label: l10n.t('menu_settings'),
            icon: Icons.tune,
            variant: GameButtonVariant.ghost,
            onPressed: onSettings,
          ),
          const SizedBox(height: GameSpacing.sm),
          Divider(color: p.border),
          const SizedBox(height: GameSpacing.sm),
          GameButton(
            label: l10n.t('menu_exit'),
            icon: Icons.power_settings_new,
            variant: GameButtonVariant.ghost,
            onPressed: onQuit,
          ),
        ],
      ),
    );
  }
}
