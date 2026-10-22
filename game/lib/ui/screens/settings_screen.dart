import 'package:flutter/material.dart';

import '../../core/identity/game_identity.dart';
import '../../core/localization/localization_service.dart';
import '../../game/audio/audio_system.dart';
import '../../settings/settings_service.dart';
import '../theme/design_tokens.dart';
import '../theme/game_palette.dart';
import '../widgets/game_controls.dart';
import '../widgets/game_surfaces.dart';
import '../widgets/settings_content.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.settings,
    required this.l10n,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onBack,
    this.audio,
    super.key,
  });

  final SettingsService settings;
  final LocalizationService l10n;
  final AudioSystem? audio;
  final ValueChanged<String> onThemeChanged;
  final AsyncStringCallback onLanguageChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return GamePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameIconButton(
                icon: rtl ? Icons.arrow_forward : Icons.arrow_back,
                tooltip: l10n.t('settings_back'),
                onPressed: onBack,
              ),
              const SizedBox(width: GameSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('settings_title'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: GameSpacing.xs),
                    Text(
                      l10n.t('settings_subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GameSpacing.md),
              GameChip(
                GameIdentity.displayVersion,
                icon: Icons.tag,
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.xl),
          GameSettingsContent(
            settings: settings,
            l10n: l10n,
            audio: audio,
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
          ),
        ],
      ),
    );
  }
}

/// Settings shown on top of the pause menu. The game stays paused while the
/// dialog is open; closing it returns to the pause panel, not to the menu.
class GameSettingsDialog extends StatelessWidget {
  const GameSettingsDialog({
    required this.settings,
    required this.l10n,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    this.audio,
    super.key,
  });

  final SettingsService settings;
  final LocalizationService l10n;
  final AudioSystem? audio;
  final ValueChanged<String> onThemeChanged;
  final AsyncStringCallback onLanguageChanged;

  static Future<void> show(
    BuildContext context, {
    required SettingsService settings,
    required LocalizationService l10n,
    required ValueChanged<String> onThemeChanged,
    required AsyncStringCallback onLanguageChanged,
    AudioSystem? audio,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => GameSettingsDialog(
        settings: settings,
        l10n: l10n,
        audio: audio,
        onThemeChanged: onThemeChanged,
        onLanguageChanged: onLanguageChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(GameSpacing.xl),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: maxHeight,
        ),
        child: GamePanel(
          clip: true,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  GameSpacing.xl,
                  GameSpacing.lg,
                  GameSpacing.md,
                  GameSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.t('settings_title'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    GameIconButton(
                      icon: Icons.close,
                      tooltip: l10n.t('confirm_cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(color: context.palette.border),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(GameSpacing.xl),
                  child: GameSettingsContent(
                    settings: settings,
                    l10n: l10n,
                    audio: audio,
                    onThemeChanged: onThemeChanged,
                    onLanguageChanged: onLanguageChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
