import 'dart:ui' show Offset;
import 'package:equatable/equatable.dart';
import 'obstacle.dart';
import 'trench_segment.dart';

/// A position where a tower can be placed, tagged with its zone.
class PlacementPosition extends Equatable {
  final String id;
  final double x;
  final double y;
  final PlacementZone zone;

  const PlacementPosition({
    required this.id,
    required this.x,
    required this.y,
    this.zone = PlacementZone.behindTrench,
  });

  @override
  List<Object?> get props => [id, x, y, zone];
}

enum PlacementZone { noMansLand, trench, behindTrench }

/// Zone-based game map with trench segments, obstacles, and placement slots.
class GameMap extends Equatable {
  final String id;
  final String name;
  final String eraId;
  final int waveCount;
  final double width;
  final double height;

  // Vertical zone boundaries
  final double spawnZoneY;        // enemies spawn at this Y (top)
  final List<TrenchSegment> trenchSegments;
  final double commandPostY;      // lose if enemy reaches this Y (bottom)

  // Placement slots and obstacles
  final List<PlacementPosition> placements;
  final List<Obstacle> obstacles;

  const GameMap({
    required this.id,
    required this.name,
    required this.eraId,
    required this.waveCount,
    required this.width,
    required this.height,
    required this.spawnZoneY,
    required this.trenchSegments,
    required this.commandPostY,
    required this.placements,
    required this.obstacles,
  });

  int get segmentCount => trenchSegments.length;

  double get segmentWidth => width / segmentCount;

  double get averageTrenchY {
    if (trenchSegments.isEmpty) return height / 2;
    return trenchSegments.map((s) => s.worldY).reduce((a, b) => a + b) /
        segmentCount;
  }

  int get weakestSegmentIndex {
    int idx = 0;
    double min = double.infinity;
    for (int i = 0; i < trenchSegments.length; i++) {
      if (trenchSegments[i].breachHp < min) {
        min = trenchSegments[i].breachHp;
        idx = i;
      }
    }
    return idx;
  }

  /// X spawn position for a given fractional offset (0.0–1.0 across width).
  double spawnX(double fraction) => fraction * width;

  GameMap copyWith({
    List<TrenchSegment>? trenchSegments,
    List<PlacementPosition>? placements,
    List<Obstacle>? obstacles,
  }) => GameMap(
        id: id, name: name, eraId: eraId, waveCount: waveCount,
        width: width, height: height, spawnZoneY: spawnZoneY,
        trenchSegments: trenchSegments ?? this.trenchSegments,
        commandPostY: commandPostY,
        placements: placements ?? this.placements,
        obstacles: obstacles ?? this.obstacles,
      );

  @override
  List<Object?> get props => [
        id, name, eraId, waveCount, width, height,
        spawnZoneY, trenchSegments, commandPostY, placements, obstacles,
      ];
}
