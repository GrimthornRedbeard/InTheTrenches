import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../providers/game_providers.dart';

/// The core map rendering widget using CustomPainter.
///
/// Renders the path, placement slots, towers, and enemies on a canvas.
/// Wrapped in an InteractiveViewer for zoom/pan support.
class GameMapWidget extends StatelessWidget {
  final GameController controller;
  final String? selectedSlotId;
  final void Function(String slotId) onSlotTapped;
  final VoidCallback onBackgroundTapped;

  const GameMapWidget({
    super.key,
    required this.controller,
    required this.selectedSlotId,
    required this.onSlotTapped,
    required this.onBackgroundTapped,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate scale to fit map into available space
        // Map coordinates range roughly 0-600 x 0-500
        final mapWidth = 650.0;
        final mapHeight = 500.0;
        final scaleX = constraints.maxWidth / mapWidth;
        final scaleY = constraints.maxHeight / mapHeight;
        final scale = math.min(scaleX, scaleY);

        return GestureDetector(
          onTapUp: (details) {
            final localPos = details.localPosition;
            final mapX = localPos.dx / scale;
            final mapY = localPos.dy / scale;

            // Check if tapped on a placement slot
            for (final slot in controller.gameMap.placements) {
              final dx = mapX - slot.x;
              final dy = mapY - slot.y;
              if (math.sqrt(dx * dx + dy * dy) < 25) {
                onSlotTapped(slot.id);
                return;
              }
            }
            onBackgroundTapped();
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _MapPainter(
              controller: controller,
              scale: scale,
              selectedSlotId: selectedSlotId,
            ),
          ),
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  final GameController controller;
  final double scale;
  final String? selectedSlotId;

  _MapPainter({
    required this.controller,
    required this.scale,
    required this.selectedSlotId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF2D3A1E),
    );

    canvas.save();
    canvas.scale(scale);

    _drawPath(canvas);
    _drawPlacementSlots(canvas);
    _drawTowers(canvas);
    _drawEnemies(canvas);
    _drawFireEvents(canvas);

    canvas.restore();
  }

  void _drawPath(Canvas canvas) {
    final path = controller.gameMap.path;
    if (path.length < 2) return;

    // Draw wide trench background
    final trenchPaint = Paint()
      ..color = const Color(0xFF5C4A32)
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final trenchPath = Path();
    trenchPath.moveTo(path[0].x, path[0].y);
    for (int i = 1; i < path.length; i++) {
      trenchPath.lineTo(path[i].x, path[i].y);
    }
    canvas.drawPath(trenchPath, trenchPaint);

    // Draw inner dirt path
    final pathPaint = Paint()
      ..color = const Color(0xFF8B7355)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(trenchPath, pathPaint);

    // Draw dotted center line
    final centerPaint = Paint()
      ..color = const Color(0xFF6B5A3E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(trenchPath, centerPaint);

    // Draw spawn and end markers
    // Spawn (start)
    canvas.drawCircle(
      Offset(path.first.x, path.first.y),
      14,
      Paint()..color = const Color(0xFF8B2020),
    );
    _drawText(canvas, 'SPAWN', path.first.x, path.first.y - 22, 10,
        const Color(0xFFD44040));

    // Base (end)
    canvas.drawCircle(
      Offset(path.last.x, path.last.y),
      14,
      Paint()..color = const Color(0xFF4A7C3F),
    );
    _drawText(canvas, 'BASE', path.last.x, path.last.y - 22, 10,
        const Color(0xFF6B9B5E));
  }

  void _drawPlacementSlots(Canvas canvas) {
    for (final slot in controller.gameMap.placements) {
      final isOccupied = controller.isSlotOccupied(slot.id);
      final isSelected = slot.id == selectedSlotId;

      if (!isOccupied) {
        // Draw empty slot
        final slotPaint = Paint()
          ..color = isSelected
              ? const Color(0xFF6B9B5E)
              : const Color(0xFF4A5D23)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(slot.x, slot.y),
          18,
          slotPaint,
        );

        // Dashed border
        final borderPaint = Paint()
          ..color = isSelected
              ? const Color(0xFF8BC87E)
              : const Color(0xFF6B8040)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(
          Offset(slot.x, slot.y),
          18,
          borderPaint,
        );

        // Plus sign
        final plusPaint = Paint()
          ..color = const Color(0xFF8B9B70)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(
          Offset(slot.x - 6, slot.y),
          Offset(slot.x + 6, slot.y),
          plusPaint,
        );
        canvas.drawLine(
          Offset(slot.x, slot.y - 6),
          Offset(slot.x, slot.y + 6),
          plusPaint,
        );
      }
    }
  }

  void _drawTowers(Canvas canvas) {
    for (final tower in controller.state.towers) {
      final def = controller.towerLookup[tower.definitionId];
      if (def == null) continue;

      final x = tower.x;
      final y = tower.y;

      // Draw range circle (subtle)
      final rangePaint = Paint()
        ..color = const Color(0x15FFFFFF)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x, y),
        def.range * 30, // Scale range to pixels
        rangePaint,
      );

      final rangeBorderPaint = Paint()
        ..color = const Color(0x30FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(
        Offset(x, y),
        def.range * 30,
        rangeBorderPaint,
      );

      // Draw tower based on category
      switch (def.category) {
        case TowerCategory.damage:
          // Rifleman: blue circle
          canvas.drawCircle(
            Offset(x, y),
            14,
            Paint()..color = const Color(0xFF3A6EA5),
          );
          canvas.drawCircle(
            Offset(x, y),
            14,
            Paint()
              ..color = const Color(0xFF5A9ED5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
          break;

        case TowerCategory.area:
          // Mortar: red triangle
          final triPath = Path();
          triPath.moveTo(x, y - 16);
          triPath.lineTo(x - 14, y + 10);
          triPath.lineTo(x + 14, y + 10);
          triPath.close();
          canvas.drawPath(
            triPath,
            Paint()..color = const Color(0xFFA53A3A),
          );
          canvas.drawPath(
            triPath,
            Paint()
              ..color = const Color(0xFFD55A5A)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
          break;

        case TowerCategory.slow:
          // Barbed Wire: grey X
          final xPaint = Paint()
            ..color = const Color(0xFF888888)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            Offset(x - 10, y - 10),
            Offset(x + 10, y + 10),
            xPaint,
          );
          canvas.drawLine(
            Offset(x + 10, y - 10),
            Offset(x - 10, y + 10),
            xPaint,
          );
          // Small circle center
          canvas.drawCircle(
            Offset(x, y),
            5,
            Paint()..color = const Color(0xFFAAAAAA),
          );
          break;
      }

      // Tier indicator
      if (tower.currentTier > 1) {
        _drawText(
          canvas,
          '*' * tower.currentTier,
          x,
          y + 20,
          9,
          const Color(0xFFFFD700),
        );
      }
    }
  }

  void _drawEnemies(Canvas canvas) {
    for (final enemy in controller.enemies) {
      if (!enemy.alive) continue;

      final pos = controller.gameMap.positionAtProgress(enemy.pathProgress);
      final x = pos.x;
      final y = pos.y;

      // Color by enemy type
      final color = _getEnemyColor(enemy.definitionId);
      final isDamaged =
          controller.recentlyDamagedEnemies.contains(enemy.id);

      // Enemy body
      final bodyPaint = Paint()
        ..color = isDamaged
            ? Color.lerp(color, Colors.red, 0.6)!
            : color;

      canvas.drawCircle(Offset(x, y), 8, bodyPaint);

      // Border
      canvas.drawCircle(
        Offset(x, y),
        8,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Health bar
      final def = controller.enemyLookup[enemy.definitionId];
      if (def != null) {
        final maxHp = def.hp;
        final hpRatio = (enemy.currentHp / maxHp).clamp(0.0, 1.0);
        final barWidth = 16.0;
        final barHeight = 3.0;
        final barX = x - barWidth / 2;
        final barY = y - 14;

        // Background
        canvas.drawRect(
          Rect.fromLTWH(barX, barY, barWidth, barHeight),
          Paint()..color = const Color(0xFF333333),
        );

        // HP fill
        final hpColor = hpRatio > 0.6
            ? const Color(0xFF4CAF50)
            : hpRatio > 0.3
                ? const Color(0xFFFF9800)
                : const Color(0xFFF44336);
        canvas.drawRect(
          Rect.fromLTWH(barX, barY, barWidth * hpRatio, barHeight),
          Paint()..color = hpColor,
        );
      }
    }
  }

  void _drawFireEvents(Canvas canvas) {
    for (final event in controller.lastFireEvents) {
      // Find tower and enemy positions
      PlacedTower? tower;
      try {
        tower = controller.state.towers.firstWhere(
          (t) => t.id == event.towerId,
        );
      } catch (_) {
        continue;
      }

      EnemyInstance? enemy;
      try {
        enemy = controller.enemies.firstWhere(
          (e) => e.id == event.enemyId,
        );
      } catch (_) {
        continue;
      }

      final enemyPos =
          controller.gameMap.positionAtProgress(enemy.pathProgress);

      // Draw fire line
      final linePaint = Paint()
        ..color = const Color(0x80FFAA00)
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(tower.x, tower.y),
        Offset(enemyPos.x, enemyPos.y),
        linePaint,
      );
    }
  }

  Color _getEnemyColor(String definitionId) {
    switch (definitionId) {
      case 'wwi_infantry':
        return const Color(0xFF4CAF50); // green
      case 'wwi_runner':
        return const Color(0xFFFFEB3B); // yellow
      case 'wwi_shield_bearer':
        return const Color(0xFF607D8B); // blue-grey
      case 'wwi_officer':
        return const Color(0xFF9C27B0); // purple
      case 'wwi_medic':
        return const Color(0xFFFFFFFF); // white
      case 'wwi_sapper':
        return const Color(0xFFFF9800); // orange
      case 'wwi_heavy':
        return const Color(0xFFF44336); // red
      case 'wwi_elite':
        return const Color(0xFFFFD700); // gold
      default:
        return const Color(0xFF4CAF50);
    }
  }

  void _drawText(Canvas canvas, String text, double x, double y,
      double fontSize, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => true;
}
