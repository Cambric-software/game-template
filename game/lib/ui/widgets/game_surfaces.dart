import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/game_palette.dart';

/// Full-screen background used by menu, settings and save screens.
///
/// A flat dark colour reads as a dead canvas on large displays, so the
/// backdrop adds a low-contrast grid and a single accent glow. Both are
/// painted, not images, and both follow the active palette.
class GameBackdrop extends StatelessWidget {
  const GameBackdrop({
    required this.child,
    this.showGrid = true,
    super.key,
  });

  final Widget child;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ColoredBox(
      color: p.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  p.bg,
                  Color.alphaBlend(p.primary.withValues(alpha: 0.045), p.bg),
                  p.bg,
                ],
              ),
            ),
          ),
          if (showGrid)
            IgnorePointer(
              child: CustomPaint(
                painter: _GridPainter(
                  color: p.border.withValues(alpha: p.isDark ? 0.55 : 0.75),
                ),
              ),
            ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, -0.9),
                  radius: 1.15,
                  colors: [
                    p.primary.withValues(alpha: p.isDark ? 0.14 : 0.09),
                    p.primary.withValues(alpha: 0),
                  ],
                  stops: const [0, 1],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color});

  final Color color;

  static const double _step = 56;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (var x = 0.0; x <= size.width; x += _step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += _step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.color != color;
}

/// Centred, width-limited page body with optional scrolling.
class GamePage extends StatelessWidget {
  const GamePage({
    required this.child,
    this.maxWidth = GameSizes.reading,
    this.padding = const EdgeInsets.all(GameSpacing.xl),
    this.scrollable = true,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return GameBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(padding: padding, child: child),
            );

            if (!scrollable) {
              return Center(child: content);
            }

            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: maxWidth,
                  ),
                  child: Padding(padding: padding, child: child),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Opaque surface card. Card radius is 14, border is a hairline.
class GamePanel extends StatelessWidget {
  const GamePanel({
    required this.child,
    this.padding = const EdgeInsets.all(GameSpacing.xl),
    this.width,
    this.clip = false,
    this.elevated = true,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? width;
  final bool clip;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget content = Padding(padding: padding, child: child);
    if (clip) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(GameRadii.card),
        child: content,
      );
    }

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(GameRadii.card),
        border: Border.all(color: p.border),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: p.isDark ? 0.28 : 0.06,
                  ),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: content,
    );
  }
}

class GameSectionLabel extends StatelessWidget {
  const GameSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GameSpacing.md),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.palette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

/// Compact neutral label, used for versions and engine names.
class GameChip extends StatelessWidget {
  const GameChip(this.label, {this.icon, super.key});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.raised,
        borderRadius: BorderRadius.circular(GameRadii.chip),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: p.secondary),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: p.secondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

enum GameTone { neutral, primary, success, warning, danger }

/// Status pill with a dot, for save state and capability labels.
class GameStatusChip extends StatelessWidget {
  const GameStatusChip({
    required this.label,
    this.tone = GameTone.neutral,
    super.key,
  });

  final String label;
  final GameTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final colour = switch (tone) {
      GameTone.neutral => p.secondary,
      GameTone.primary => p.primary,
      GameTone.success => p.success,
      GameTone.warning => p.warning,
      GameTone.danger => p.danger,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(GameRadii.chip),
        border: Border.all(color: colour.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colour,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
