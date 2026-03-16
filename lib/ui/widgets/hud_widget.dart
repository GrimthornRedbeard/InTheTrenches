import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../providers/game_providers.dart';

/// Top HUD bar showing gold, lives, wave info, and speed controls.
class HudWidget extends StatelessWidget {
  final GameController controller;

  const HudWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final state = controller.state;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xDD1A2410),
            Color(0x001A2410),
          ],
        ),
      ),
      child: Row(
        children: [
          // Gold
          _HudItem(
            icon: Icons.paid,
            iconColor: const Color(0xFFFFD700),
            value: '${state.gold}',
          ),
          const SizedBox(width: 20),

          // Lives
          _HudItem(
            icon: Icons.favorite,
            iconColor: const Color(0xFFE53935),
            value: '${state.lives}',
          ),
          const SizedBox(width: 20),

          // Wave
          _HudItem(
            icon: Icons.waves,
            iconColor: const Color(0xFF64B5F6),
            value: '${state.currentWave}/${controller.gameMap.waveCount}',
          ),

          const Spacer(),

          // Phase indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getPhaseColor(state.phase).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _getPhaseColor(state.phase).withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              _getPhaseName(state.phase),
              style: TextStyle(
                color: _getPhaseColor(state.phase),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Speed controls
          _SpeedButton(
            icon: Icons.pause,
            isActive: controller.speed == GameSpeed.paused,
            onTap: () => controller.speed = GameSpeed.paused,
          ),
          const SizedBox(width: 4),
          _SpeedButton(
            icon: Icons.play_arrow,
            isActive: controller.speed == GameSpeed.normal,
            onTap: () => controller.speed = GameSpeed.normal,
          ),
          const SizedBox(width: 4),
          _SpeedButton(
            icon: Icons.fast_forward,
            isActive: controller.speed == GameSpeed.fast,
            onTap: () => controller.speed = GameSpeed.fast,
          ),
        ],
      ),
    );
  }

  Color _getPhaseColor(GamePhase phase) {
    switch (phase) {
      case GamePhase.building:
        return const Color(0xFF4CAF50);
      case GamePhase.waveActive:
        return const Color(0xFFF44336);
      case GamePhase.waveComplete:
        return const Color(0xFF2196F3);
      case GamePhase.victory:
        return const Color(0xFFFFD700);
      case GamePhase.defeat:
        return const Color(0xFF8B2020);
    }
  }

  String _getPhaseName(GamePhase phase) {
    switch (phase) {
      case GamePhase.building:
        return 'BUILDING';
      case GamePhase.waveActive:
        return 'COMBAT';
      case GamePhase.waveComplete:
        return 'CLEAR';
      case GamePhase.victory:
        return 'VICTORY';
      case GamePhase.defeat:
        return 'DEFEAT';
    }
  }
}

class _HudItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;

  const _HudItem({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFD4C5A9),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _SpeedButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4A7C3F)
              : const Color(0xFF2A3520),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive
                ? const Color(0xFF6B9B5E)
                : const Color(0xFF4A5D23),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive
              ? const Color(0xFFD4C5A9)
              : const Color(0xFF6B8040),
        ),
      ),
    );
  }
}
