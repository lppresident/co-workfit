import 'package:flutter/material.dart';

/// 통나무 보유량 표시 위젯
class WoodDisplayWidget extends StatelessWidget {
  final int amount;
  final bool showLabel;
  final double fontSize;

  const WoodDisplayWidget({
    super.key,
    required this.amount,
    this.showLabel = true,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.brown[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🪵',
            style: TextStyle(fontSize: fontSize),
          ),
          const SizedBox(width: 6),
          Text(
            '$amount',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.brown[700],
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              '통나무',
              style: TextStyle(
                fontSize: fontSize * 0.75,
                color: Colors.brown[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

