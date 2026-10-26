import 'package:flutter/material.dart';

import '../../core/identity/game_identity.dart';
import '../../core/localization/localization_service.dart';
import '../../game/audio/audio_system.dart';
import '../../settings/settings_service.dart';
import '../theme/design_tokens.dart';
import '../theme/game_palette.dart';
import 'game_controls.dart';
import 'game_dialogs.dart';
import 'game_surfaces.dart';

typedef AsyncStringCallback = Future<void> Function(String value);

/// Player settings shared by the Settings screen and the pause menu.
///
/// Values are written to [SettingsService] immediately; there is no Save
/// button to forget. Audio changes are applied to [AudioSystem] on release
/// so dragging a slider does not restart the music on every pixel.
class GameSettingsContent extends StatefulWidget {
  const GameSettingsContent({
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

  @override
  State<GameSettingsContent> createState() => _GameSettingsContentState();
}

class _GameSettingsContentState extends State<GameSettingsContent> {
  late double _master;
  late double _music;
  late double _sfx;
  late bool _muted;
  late bool _reducedMotion;
  late String _theme;
  late String _language;

  @override
  void initState() {
    super.initState();
    _readFromSettings();
  }

  void _readFromSettings() {
    _master = widget.settings.masterVolume;
    _music = widget.settings.musicVolume;
    _sfx = widget.settings.sfxVolume;
    _muted = widget.settings.audioMuted;
    _reducedMotion = widget.settings.reducedMotion;
    _theme = widget.settings.uiTheme;
    _language = widget.settings.language;
  }

  void _applyAudio() {
    widget.audio?.applyVolumeSettings();
  }

  Future<void> _changeLanguage(String value) async {
    if (value == _language) return;
    setState(() => _language = value);
    widget.settings.language = value;
    await widget.onLanguageChanged(value);
    if (mounted) setState(() {});
  }

  void _changeTheme(String value) {
    if (value == _theme) return;
    setState(() => _theme = value);
    widget.settings.uiTheme = value;
    widget.onThemeChanged(value);
  }

  Future<void> _reset() async {
    final l10n = widget.l10n;
    final confirmed = await showGameConfirm(
      context,
      title: l10n.t('settings_reset'),
      message: l10n.t('settings_reset_confirm'),
      confirmLabel: l10n.t('settings_reset'),
      danger: true,
    );
    if (!confirmed || !mounted) return;

    await widget.settings.resetToDefaults();
    if (!mounted) return;

    setState(_readFromSettings);
    _applyAudio();
    widget.onThemeChanged(widget.settings.uiTheme);
    await widget.onLanguageChanged(widget.settings.language);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          title: l10n.t('settings_audio'),
          child: Column(
            children: [
              GameSettingSlider(
                label: l10n.t('settings_master_volume'),
                value: _master,
                onChanged: (value) {
                  setState(() => _master = value);
                  widget.settings.masterVolume = value;
                },
                onChangeEnd: (_) => _applyAudio(),
              ),
              GameSettingSlider(
                label: l10n.t('settings_music_volume'),
                value: _music,
                onChanged: (value) {
                  setState(() => _music = value);
                  widget.settings.musicVolume = value;
                },
                onChangeEnd: (_) => _applyAudio(),
              ),
              GameSettingSlider(
                label: l10n.t('settings_sfx_volume'),
                value: _sfx,
                onChanged: (value) {
                  setState(() => _sfx = value);
                  widget.settings.sfxVolume = value;
                },
                onChangeEnd: (_) => _applyAudio(),
              ),
              const SizedBox(height: GameSpacing.xs),
              Divider(color: p.border),
              GameToggleRow(
                label: l10n.t('settings_mute'),
                value: _muted,
                onChanged: (value) {
                  setState(() => _muted = value);
                  widget.settings.audioMuted = value;
                  _applyAudio();
                },
              ),
              Text(
                l10n.t('settings_audio_hint'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: GameSpacing.lg),
        _Section(
          title: l10n.t('settings_interface'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(l10n.t('settings_theme')),
              GameChoiceGroup<String>(
                selected: _theme,
                onSelected: _changeTheme,
                choices: [
                  GameChoice(
                    value: 'dark',
                    label: l10n.t('settings_theme_dark'),
                    icon: Icons.dark_mode_outlined,
                  ),
                  GameChoice(
                    value: 'light',
                    label: l10n.t('settings_theme_light'),
                    icon: Icons.light_mode_outlined,
                  ),
                ],
              ),
              const SizedBox(height: GameSpacing.lg),
              _FieldLabel(l10n.t('settings_language')),
              GameChoiceGroup<String>(
                selected: _language,
                onSelected: _changeLanguage,
                choices: [
                  const GameChoice(value: 'en', label: 'English'),
                  const GameChoice(value: 'ar', label: 'العربية'),
                ],
              ),
              const SizedBox(height: GameSpacing.sm),
              Divider(color: p.border),
              GameToggleRow(
                label: l10n.t('settings_reduced_motion'),
                description: l10n.t('settings_reduced_motion_desc'),
                value: _reducedMotion,
                onChanged: (value) {
                  setState(() => _reducedMotion = value);
                  widget.settings.reducedMotion = value;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: GameSpacing.lg),
        _Section(
          title: l10n.t('settings_about'),
          child: Column(
            children: [
              _InfoRow(
                label: l10n.t('settings_version'),
                value: GameIdentity.displayVersion,
              ),
              _InfoRow(
                label: l10n.t('settings_engine'),
                value: l10n.t('settings_engine_value'),
              ),
              _InfoRow(
                label: l10n.t('settings_license'),
                value: 'MIT',
              ),
            ],
          ),
        ),
        const SizedBox(height: GameSpacing.lg),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: GameButton(
            label: l10n.t('settings_reset'),
            icon: Icons.restore,
            variant: GameButtonVariant.ghost,
            expand: false,
            onPressed: _reset,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameSectionLabel(title),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GameSpacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.palette.text,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: GameSpacing.lg),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: p.text,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
