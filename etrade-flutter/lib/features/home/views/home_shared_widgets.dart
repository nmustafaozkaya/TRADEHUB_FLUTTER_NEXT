import 'package:flutter/material.dart';

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    required this.label,
    required this.value,
    this.note,
    this.isBold = false,
    super.key,
  });

  final String label;
  final double value;
  final String? note;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.65);
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
      fontSize: isBold ? 16 : 14,
      color: onSurface,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(label, style: style),
                if (note != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    note!,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Text('TRY ${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
