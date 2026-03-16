import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/game_state.dart';
import '../../providers/game_providers.dart';
import '../widgets/build_menu.dart';
import '../widgets/game_map_widget.dart';
import '../widgets/hud_widget.dart';
import '../widgets/wave_banner.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  String? _selectedSlotId;
  String? _selectedTowerId;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(gameControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF2D3A1E),
      body: Stack(
        children: [
          // Map canvas with InteractiveViewer
          Positioned.fill(
            child: GameMapWidget(
              controller: controller,
              selectedSlotId: _selectedSlotId,
              onSlotTapped: (slotId) {
                setState(() {
                  if (controller.isSlotOccupied(slotId)) {
                    _selectedTowerId = controller.getTowerAtSlot(slotId)?.id;
                    _selectedSlotId = null;
                  } else {
                    _selectedSlotId = slotId;
                    _selectedTowerId = null;
                  }
                });
              },
              onBackgroundTapped: () {
                setState(() {
                  _selectedSlotId = null;
                  _selectedTowerId = null;
                });
              },
            ),
          ),

          // HUD overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HudWidget(controller: controller),
          ),

          // Wave send button at bottom
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: _buildBottomControls(controller),
            ),
          ),

          // Build menu popup
          if (_selectedSlotId != null)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: BuildMenu(
                controller: controller,
                slotId: _selectedSlotId!,
                onBuild: (towerDefId) {
                  controller.buildTower(_selectedSlotId!, towerDefId);
                  setState(() => _selectedSlotId = null);
                },
                onClose: () => setState(() => _selectedSlotId = null),
              ),
            ),

          // Tower info popup
          if (_selectedTowerId != null)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: _buildTowerInfoPanel(controller, _selectedTowerId!),
            ),

          // Wave banner overlay
          if (controller.shouldShowBanner)
            Positioned.fill(
              child: WaveBanner(text: controller.waveBannerText ?? ''),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(GameController controller) {
    final canSendWave = controller.state.phase == GamePhase.building ||
        controller.state.phase == GamePhase.waveComplete;
    final isGameOver = controller.state.phase == GamePhase.victory ||
        controller.state.phase == GamePhase.defeat;

    if (isGameOver) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A7C3F),
          foregroundColor: const Color(0xFFD4C5A9),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text(
          'RETURN TO MENU',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (canSendWave &&
        controller.state.currentWave < controller.gameMap.waveCount) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B2020),
          foregroundColor: const Color(0xFFD4C5A9),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFAA3030), width: 2),
          ),
        ),
        onPressed: controller.sendWave,
        child: Text(
          'SEND WAVE ${controller.state.currentWave + 1}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTowerInfoPanel(
      GameController controller, String towerId) {
    final tower = controller.state.towers.firstWhere(
      (t) => t.id == towerId,
      orElse: () {
        // Tower was sold, close panel
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => _selectedTowerId = null);
        });
        return controller.state.towers.first;
      },
    );

    final def = controller.towerLookup[tower.definitionId];
    if (def == null) return const SizedBox.shrink();

    final sellRefund =
        (controller.resources.totalInvested(towerId) * 0.6).floor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xDD1A2410),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A5D23), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                def.name,
                style: const TextStyle(
                  color: Color(0xFFD4C5A9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tier ${tower.currentTier}',
                style: const TextStyle(
                  color: Color(0xFF8B7355),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF8B7355)),
                onPressed: () => setState(() => _selectedTowerId = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatChip('DMG', '${def.damage.toInt()}', Colors.redAccent),
              const SizedBox(width: 8),
              _StatChip('RNG', '${def.range}', Colors.blueAccent),
              const SizedBox(width: 8),
              _StatChip('SPD', '${def.attackSpeed}', Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4020),
                foregroundColor: const Color(0xFFD4C5A9),
              ),
              onPressed: () {
                controller.sellTower(towerId);
                setState(() => _selectedTowerId = null);
              },
              child: Text('SELL (+$sellRefund gold)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
