import 'package:flutter/material.dart';

import '../../core/localization/localization_service.dart';
import '../../save/save_data.dart';
import '../../save/save_service.dart';
import '../theme/design_tokens.dart';
import '../theme/game_palette.dart';
import '../widgets/game_controls.dart';
import '../widgets/game_dialogs.dart';
import '../widgets/game_surfaces.dart';

/// Lists the default save slots and starts the game in the chosen slot.
///
/// Selecting an occupied slot loads it. Selecting an empty slot starts a new
/// session there. Deletion asks first and removes both the save and backup.
class SaveSlotsScreen extends StatefulWidget {
  const SaveSlotsScreen({
    required this.onPlay,
    required this.onBack,
    this.loadSlots,
    this.deleteSlot,
    super.key,
  });

  final void Function(SaveSlot slot) onPlay;
  final VoidCallback onBack;

  /// Override in tests. Production reads from [SaveService].
  final Future<List<SaveSlotInfo>> Function()? loadSlots;
  final Future<bool> Function(SaveSlot slot)? deleteSlot;

  @override
  State<SaveSlotsScreen> createState() => _SaveSlotsScreenState();
}

class _SaveSlotsScreenState extends State<SaveSlotsScreen> {
  final SaveService _saves = SaveService();
  final LocalizationService _l10n = LocalizationService();

  List<SaveSlotInfo>? _slots;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final slots = await (widget.loadSlots?.call() ?? _saves.listSlots());
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete(SaveSlotInfo info) async {
    final confirmed = await showGameConfirm(
      context,
      title: _l10n.t('save_slot_delete_title'),
      message: _l10n.t(
        'save_slot_delete_body',
        params: {'slot': _slotName(info.slot)},
      ),
      confirmLabel: _l10n.t('save_slot_delete'),
      danger: true,
    );
    if (!confirmed) return;

    final removed = await (widget.deleteSlot?.call(info.slot) ??
        _saves.deleteSave(info.slot));
    if (!mounted) return;
    if (!removed) {
      setState(() => _error = _l10n.t('save_failed'));
      return;
    }
    await _load();
  }

  String _slotName(SaveSlot slot) {
    if (slot.isAutoSave) return _l10n.t('save_slot_autosave');
    final match = RegExp(r'slot_(\d+)').firstMatch(slot.id);
    if (match != null) {
      return _l10n.t(
        'save_slot_name',
        params: {'n': match.group(1)!},
      );
    }
    return slot.displayName;
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return GamePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            title: _l10n.t('save_files_title'),
            subtitle: _l10n.t('save_files_body'),
            onBack: widget.onBack,
          ),
          const SizedBox(height: GameSpacing.xl),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: GameSpacing.xxxl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _ErrorPanel(message: _error!, onRetry: _load)
          else
            for (final info in _slots!)
              Padding(
                padding: const EdgeInsets.only(bottom: GameSpacing.md),
                child: _SaveSlotCard(
                  name: _slotName(info.slot),
                  info: info,
                  date: info.data == null
                      ? null
                      : _date(info.data!.updatedAt),
                  onPlay: () => widget.onPlay(info.slot),
                  onDelete: info.isEmpty ? null : () => _delete(info),
                ),
              ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Row(
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
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: GameSpacing.xs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SaveSlotCard extends StatelessWidget {
  const _SaveSlotCard({
    required this.name,
    required this.info,
    required this.onPlay,
    this.date,
    this.onDelete,
  });

  final String name;
  final SaveSlotInfo info;
  final String? date;
  final VoidCallback onPlay;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final p = context.palette;
    final data = info.data;

    return GamePanel(
      padding: const EdgeInsets.all(GameSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: data == null
                      ? p.raised
                      : p.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(GameRadii.button),
                  border: Border.all(
                    color: data == null ? p.border : p.primary,
                  ),
                ),
                child: Icon(
                  data == null ? Icons.add : Icons.save_outlined,
                  size: 20,
                  color: data == null ? p.muted : p.primary,
                ),
              ),
              const SizedBox(width: GameSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: GameSpacing.sm,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        GameStatusChip(
                          label: data == null
                              ? l10n.t('save_slot_empty')
                              : data.playtimeDisplay,
                          tone: data == null
                              ? GameTone.neutral
                              : GameTone.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: GameSpacing.xs),
                    Text(
                      data == null
                          ? l10n.t('save_slot_empty_hint')
                          : l10n.t(
                              'save_slot_updated',
                              params: {'date': date!},
                            ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: GameSpacing.sm),
                GameIconButton(
                  icon: Icons.delete_outline,
                  tooltip: l10n.t('save_slot_delete'),
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
          const SizedBox(height: GameSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: GameButton(
              label: data == null
                  ? l10n.t('save_slot_new')
                  : l10n.t('save_slot_load'),
              icon: data == null
                  ? Icons.play_arrow_rounded
                  : Icons.play_circle_outline,
              variant: data == null
                  ? GameButtonVariant.secondary
                  : GameButtonVariant.primary,
              expand: false,
              onPressed: onPlay,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final p = context.palette;

    return GamePanel(
      child: Column(
        children: [
          Icon(Icons.folder_off_outlined, color: p.danger, size: 24),
          const SizedBox(height: GameSpacing.md),
          Text(
            l10n.t('save_failed'),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GameSpacing.xs),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GameSpacing.lg),
          GameButton(
            label: l10n.t('common_retry'),
            icon: Icons.refresh,
            variant: GameButtonVariant.secondary,
            expand: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
