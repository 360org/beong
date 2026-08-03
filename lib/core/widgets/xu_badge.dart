import 'package:beong/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class XuBadge extends StatelessWidget {
  const XuBadge({required this.amount, super.key, this.large = false});

  final int amount;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final fontSize = large ? 24.0 : 16.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: large ? 28 : 20,
          height: large ? 28 : 20,
          decoration: BoxDecoration(
            color: context.semantic.xu,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.semantic.xu.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'X',
              style: TextStyle(
                fontSize: large ? 14 : 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$amount',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: context.colors.onSurface,
          ),
        ),
      ],
    );
  }
}
