import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../providers/game_providers.dart';

/// The core map rendering widget using CustomPainter.
///
/// Renders three tinted zone bands (no man's land, trench, behind trench),
/// the segmented trench line, placement slots, towers, and enemies on a canvas.
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

    // Map size in world coordinates
    final mapSize = Size(controller.gameMap.width, controller.gameMap.height);

    // Draw in back-to-front order so enemies appear above zone tints
    _drawZones(canvas, mapSize);
    _drawTrench(canvas);
    _drawObstacles(canvas);
    _drawPlacementSlots(canvas);
    _drawTowers(canvas);
    _drawEnemies(canvas);
    _drawFireEvents(canvas);

    // Spawn and command post markers drawn last (on top of everything)
    _drawMarkers(canvas, mapSize);

    canvas.restore();
  }

  /// Draws tinted colour bands for the three map zones:
  /// - No man's land (top, above trench)
  /// - Trench area (thin band around the trench line)
  /// - Behind trench (below trench to command post)
  void _drawZones(Canvas canvas, Size size) {
    final trenchY = controller.trenchSegments.isEmpty
        ? size.height / 2
        : controller.trenchSegments
                .map((s) => s.worldY)
                .reduce((a, b) => a + b) /
            controller.trenchSegments.length;

    // No man's land — top of map to trench line
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, trenchY),
      Paint()..color = const Color(0xFF3D4A1E).withValues(alpha: 0.4),
    );

    // Behind trench — trench line to bottom of map
    canvas.drawRect(
      Rect.fromLTWH(0, trenchY, size.width, size.height - trenchY),
      Paint()..color = const Color(0xFF2A3010).withValues(alpha: 0.5),
    );
  }

  /// Draws each trench segment as a coloured rectangle, with a breach HP bar.
  void _drawTrench(Canvas canvas) {
    final segW = controller.gameMap.segmentWidth;

    for (final seg in controller.trenchSegments) {
      final color = switch (seg.state) {
        TrenchSegmentState.held => const Color(0xFF5C4A32),
        TrenchSegmentState.contested => const Color(0xFFAA5500),
        TrenchSegmentState.breached => const Color(0xFFCC2200),
        TrenchSegmentState.collapsed => const Color(0xFF880000),
      };

      final rect = Rect.fromCenter(
        center: Offset(seg.worldX, seg.worldY),
        width: segW - 4,
        height: 28,
      );
      canvas.drawRect(rect, Paint()..color = color);

      // Breach HP bar (not shown for fully collapsed segments)
      if (seg.state != TrenchSegmentState.collapsed) {
        final barW = (segW - 8) * (seg.breachHp / 100).clamp(0.0, 1.0);

        // Bar background
        canvas.drawRect(
          Rect.fromLTWH(
            seg.worldX - segW / 2 + 4,
            seg.worldY + 16,
            segW - 8,
            4,
          ),
          Paint()..color = const Color(0xFF333333),
        );

        // Bar fill
        canvas.drawRect(
          Rect.fromLTWH(
            seg.worldX - segW / 2 + 4,
            seg.worldY + 16,
            barW,
            4,
          ),
          Paint()..color = const Color(0xFF00FF88),
        );
      }
    }
  }

  /// Draws environmental obstacles (barbed wire and shell craters).
  void _drawObstacles(Canvas canvas) {
    for (final obs in controller.gameMap.obstacles) {
      final paint = Paint()
        ..color = obs.type == ObstacleType.barbedWire
            ? const Color(0xFF888866)
            : const Color(0xFF554433);
      canvas.drawCircle(obs.position, obs.radius, paint);
    }
  }

  void _drawPlacementSlots(Canvas canvas) {
    for (final slot in controller.gameMap.placements) {
      final isOccupied = controller.isSlotOccupied(slot.id);
      final isSelected = slot.id == selectedSlotId;

      if (!isOccupied) {
        // Zone-tinted fill colour
        final fillColor = switch (slot.zone) {
          PlacementZone.noMansLand => isSelected
              ? const Color(0xFF9B7E3E)
              : const Color(0xFF6B5523),
          PlacementZone.trench => isSelected
              ? const Color(0xFF8B7E5E)
              : const Color(0xFF5A4A33),
          PlacementZone.behindTrench => isSelected
              ? const Color(0xFF6B9B5E)
              : const Color(0xFF4A5D23),
        };

        final borderColor = switch (slot.zone) {
          PlacementZone.noMansLand => isSelected
              ? const Color(0xFFCBA85E)
              : const Color(0xFF8B7040),
          PlacementZone.trench => isSelected
              ? const Color(0xFFBBAA8E)
              : const Color(0xFF7A6A53),
          PlacementZone.behindTrench => isSelected
              ? const Color(0xFF8BC87E)
              : const Color(0xFF6B8040),
        };

        // Draw empty slot
        canvas.drawCircle(
          Offset(slot.x, slot.y),
          18,
          Paint()..color = fillColor,
        );

        canvas.drawCircle(
          Offset(slot.x, slot.y),
          18,
          Paint()
            ..color = borderColor
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
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

  /// Draws enemies as free-positioned circles, coloured by movement state.
  void _drawEnemies(Canvas canvas) {
    for (final enemy in controller.enemies) {
      if (!enemy.alive) continue;

      final pos = enemy.position;
      final isDamaged = controller.recentlyDamagedEnemies.contains(enemy.id);

      // Colour encodes current movement phase
      final baseColor = switch (enemy.movementState) {
        EnemyMovementState.advancing => const Color(0xFFCC3333),
        EnemyMovementState.breaching => const Color(0xFFFF6600),
        EnemyMovementState.inTrench => const Color(0xFFFF0000),
        EnemyMovementState.crossed => const Color(0xFF990000),
      };

      final bodyColor = isDamaged
          ? Color.lerp(baseColor, Colors.red, 0.6)!
          : baseColor;

      // Enemy body
      canvas.drawCircle(pos, 8, Paint()..color = bodyColor);

      // Border
      canvas.drawCircle(
        pos,
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
        const barWidth = 16.0;
        const barHeight = 3.0;
        final barX = pos.dx - barWidth / 2;
        final barY = pos.dy - 14;

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

      // Use the enemy's 2D position directly
      final enemyPos = enemy.position;

      // Draw fire line
      final linePaint = Paint()
        ..color = const Color(0x80FFAA00)
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(tower.x, tower.y),
        enemyPos,
        linePaint,
      );
    }
  }

  /// Draws spawn and command post markers.
  void _drawMarkers(Canvas canvas, Size mapSize) {
    final gameMap = controller.gameMap;
    final midX = gameMap.width / 2;

    // Spawn marker (top)
    canvas.drawCircle(
      Offset(midX, gameMap.spawnZoneY),
      14,
      Paint()..color = const Color(0xFF8B2020),
    );
    _drawText(
      canvas,
      'SPAWN',
      midX,
      gameMap.spawnZoneY - 22,
      10,
      const Color(0xFFD44040),
    );

    // Base / command post marker (bottom)
    canvas.drawCircle(
      Offset(midX, gameMap.commandPostY),
      14,
      Paint()..color = const Color(0xFF4A7C3F),
    );
    _drawText(
      canvas,
      'BASE',
      midX,
      gameMap.commandPostY - 22,
      10,
      const Color(0xFF6B9B5E),
    );
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
