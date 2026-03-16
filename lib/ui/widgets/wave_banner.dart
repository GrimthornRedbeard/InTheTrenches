import 'package:flutter/material.dart';

/// Animated wave announcement banner overlay.
class WaveBanner extends StatelessWidget {
  final String text;

  const WaveBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isVictory = text.contains('VICTORY');
    final isDefeat = text.contains('DEFEAT');
    final isEndGame = isVictory || isDefeat;

    final bgColor = isVictory
        ? const Color(0x80305020)
        : isDefeat
            ? const Color(0x80502020)
            : const Color(0x60000000);

    final textColor = isVictory
        ? const Color(0xFFFFD700)
        : isDefeat
            ? const Color(0xFFF44336)
            : const Color(0xFFD4C5A9);

    return IgnorePointer(
      ignoring: !isEndGame,
      child: Container(
        color: bgColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isEndGame ? 48 : 32,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 4,
                  shadows: const [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 10,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
              if (isEndGame) ...[
                const SizedBox(height: 16),
                Text(
                  isVictory
                      ? 'All waves cleared!'
                      : 'Your base was overrun.',
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
