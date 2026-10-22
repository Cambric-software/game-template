import 'package:flutter/material.dart';

import '../../core/localization/localization_service.dart';
import '../theme/design_tokens.dart';
import '../theme/game_palette.dart';
import 'game_controls.dart';
import 'game_surfaces.dart';

/// Styled confirmation dialog. Returns false when dismissed.
Future<bool> showGameConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  final l10n = LocalizationService();
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(GameSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: GameSizes.dialog),
        child: GamePanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(dialogContext).textTheme.titleLarge,
              ),
              const SizedBox(height: GameSpacing.sm),
              Text(
                message,
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: GameSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GameButton(
                    label: l10n.t('confirm_cancel'),
                    variant: GameButtonVariant.ghost,
                    expand: false,
                    onPressed: () => Navigator.pop(dialogContext, false),
                  ),
                  const SizedBox(width: GameSpacing.sm),
                  GameButton(
                    label: confirmLabel,
                    variant: danger
                        ? GameButtonVariant.danger
                        : GameButtonVariant.primary,
                    expand: false,
                    onPressed: () => Navigator.pop(dialogContext, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  return result ?? false;
}

/// Styled message dialog with a single close action.
Future<void> showGameMessage(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final l10n = LocalizationService();
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(GameSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: GameSizes.dialog),
        child: GamePanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: dialogContext.palette.danger,
                    size: 20,
                  ),
                  const SizedBox(width: GameSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(dialogContext).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GameSpacing.md),
              Text(
                message,
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: GameSpacing.xl),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: GameButton(
                  label: l10n.t('confirm_ok'),
                  expand: false,
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
