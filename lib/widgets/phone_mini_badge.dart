import 'package:flutter/material.dart';

class PhoneMiniBadge extends StatelessWidget {
  final bool wsOk;
  final int rttMs;

  const PhoneMiniBadge({
    super.key,
    required this.wsOk,
    required this.rttMs,
  });

  @override
  Widget build(BuildContext context) {
    final rttText = rttMs < 0 ? "--" : "${rttMs}ms";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.12),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.smartphone_rounded, size: 18),
          const SizedBox(width: 8),

          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: wsOk ? Colors.green : Colors.red,
            ),
          ),

          const SizedBox(width: 8),

          Text(
            wsOk ? "WS已连接" : "WS未连接",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(width: 8),

          Text(
            rttText,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
