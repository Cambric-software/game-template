import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/game_palette.dart';

enum GameButtonVariant { primary, secondary, ghost, danger }

/// Shared menu button. Every variant is at least 48 px tall so touch and
/// mouse targets stay usable on a phone and a desktop.
class GameButton extends StatelessWidget {
  const GameButton({
    required this.label,
    required this.onPressed,
    this.variant = GameButtonVariant.secondary,
    this.icon,
    this.expand = true,
    this.helper,
    this.autofocus = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final GameButtonVariant variant;
  final IconData? icon;
  final bool expand;

  /// Optional line under the button, used to explain a disabled action.
  final String? helper;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GameRadii.button),
    );

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: GameSpacing.sm),
        ],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    Widget button;
    switch (variant) {
      case GameButtonVariant.primary:
        button = FilledButton(
          onPressed: onPressed,
          autofocus: autofocus,
          child: child,
        );
      case GameButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: onPressed,
          autofocus: autofocus,
          style: OutlinedButton.styleFrom(
            backgroundColor: p.raised,
            foregroundColor: p.text,
            disabledBackgroundColor: p.raised,
            disabledForegroundColor: p.muted,
            side: BorderSide(color: p.border),
            shape: shape,
          ),
          child: child,
        );
      case GameButtonVariant.ghost:
        button = TextButton(
          onPressed: onPressed,
          autofocus: autofocus,
          style: TextButton.styleFrom(
            foregroundColor: p.secondary,
            disabledForegroundColor: p.muted,
            shape: shape,
          ),
          child: child,
        );
      case GameButtonVariant.danger:
        button = FilledButton(
          onPressed: onPressed,
          autofocus: autofocus,
          style: FilledButton.styleFrom(
            backgroundColor: p.danger,
            foregroundColor: Colors.white,
            disabledBackgroundColor: p.raised,
            disabledForegroundColor: p.muted,
            shape: shape,
          ),
          child: child,
        );
    }

    if (expand) {
      button = SizedBox(
        width: double.infinity,
        height: GameSizes.buttonHeight,
        child: button,
      );
    }

    if (helper == null) return button;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GameSpacing.xs),
          child: Text(
            helper!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: p.muted,
                  fontSize: 12,
                ),
          ),
        ),
      ],
    );
  }
}

class GameIconButton extends StatelessWidget {
  const GameIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
    );
  }
}

class GameChoice<T> {
  const GameChoice({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// Segmented choice group. Used for theme and language in Settings.
class GameChoiceGroup<T> extends StatelessWidget {
  const GameChoiceGroup({
    required this.choices,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<GameChoice<T>> choices;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Wrap(
      spacing: GameSpacing.sm,
      runSpacing: GameSpacing.sm,
      children: [
        for (final choice in choices)
          _Choice(
            label: choice.label,
            icon: choice.icon,
            selected: choice.value == selected,
            onTap: () => onSelected(choice.value),
            palette: p,
          ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.palette,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final GamePalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GameRadii.button),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.symmetric(
              horizontal: GameSpacing.lg,
              vertical: GameSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: selected ? p.primary : p.raised,
              borderRadius: BorderRadius.circular(GameRadii.button),
              border: Border.all(color: selected ? p.primary : p.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? p.onPrimary : p.secondary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? p.onPrimary : p.text,
                        fontSize: 13.5,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GameSettingSlider extends StatelessWidget {
  const GameSettingSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    super.key,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              '${(value.clamp(0, 1) * 100).round()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: p.secondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0, 1),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
          divisions: 20,
          label: '${(value.clamp(0, 1) * 100).round()}%',
        ),
      ],
    );
  }
}

class GameToggleRow extends StatelessWidget {
  const GameToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    super.key,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(GameRadii.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GameSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: p.text,
                        ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: GameSpacing.lg),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
