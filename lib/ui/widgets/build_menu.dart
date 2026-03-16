import 'package:flutter/material.dart';

import '../../models/tower.dart';
import '../../providers/game_providers.dart';

/// Tower build popup shown when tapping an empty placement slot.
class BuildMenu extends StatelessWidget {
  final GameController controller;
  final String slotId;
  final void Function(String towerDefId) onBuild;
  final VoidCallback onClose;

  const BuildMenu({
    super.key,
    required this.controller,
    required this.slotId,
    required this.onBuild,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final towers = controller.era.towers;
    final gold = controller.resources.gold;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xDD1A2410),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A5D23), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'BUILD TOWER',
                style: TextStyle(
                  color: Color(0xFFD4C5A9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF8B7355)),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...towers.map((towerDef) => _TowerOption(
                towerDef: towerDef,
                canAfford: gold >= towerDef.cost,
                onTap: () => onBuild(towerDef.id),
              )),
        ],
      ),
    );
  }
}

class _TowerOption extends StatelessWidget {
  final TowerDefinition towerDef;
  final bool canAfford;
  final VoidCallback onTap;

  const _TowerOption({
    required this.towerDef,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = _getCategoryColor(towerDef.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: canAfford ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: canAfford
                ? const Color(0xFF2A3520)
                : const Color(0xFF1E2618),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: canAfford
                  ? const Color(0xFF4A5D23)
                  : const Color(0xFF333D25),
            ),
          ),
          child: Row(
            children: [
              // Tower icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: canAfford
                      ? iconColor.withValues(alpha: 0.2)
                      : const Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: canAfford
                        ? iconColor
                        : const Color(0xFF444444),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: _getCategoryIcon(towerDef.category, canAfford),
                ),
              ),
              const SizedBox(width: 12),
              // Name and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      towerDef.name,
                      style: TextStyle(
                        color: canAfford
                            ? const Color(0xFFD4C5A9)
                            : const Color(0xFF555E48),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      towerDef.description,
                      style: TextStyle(
                        color: canAfford
                            ? const Color(0xFF8B7355)
                            : const Color(0xFF444D38),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Cost
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: canAfford
                      ? const Color(0xFF3A4D28)
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.paid,
                      size: 14,
                      color: canAfford
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF666666),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${towerDef.cost}',
                      style: TextStyle(
                        color: canAfford
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF666666),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(TowerCategory category) {
    switch (category) {
      case TowerCategory.damage:
        return const Color(0xFF5A9ED5);
      case TowerCategory.area:
        return const Color(0xFFD55A5A);
      case TowerCategory.slow:
        return const Color(0xFF888888);
    }
  }

  Widget _getCategoryIcon(TowerCategory category, bool enabled) {
    final color = enabled ? _getCategoryColor(category) : const Color(0xFF666666);
    switch (category) {
      case TowerCategory.damage:
        return Icon(Icons.gps_fixed, size: 18, color: color);
      case TowerCategory.area:
        return Icon(Icons.blur_on, size: 18, color: color);
      case TowerCategory.slow:
        return Icon(Icons.fence, size: 18, color: color);
    }
  }
}
