import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// A point along the enemy path.
class PathPoint extends Equatable {
  final double x;
  final double y;

  const PathPoint({required this.x, required this.y});

  /// Distance to another point.
  double distanceTo(PathPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  List<Object?> get props => [x, y];
}

/// A position where a tower can be placed.
class PlacementPosition extends Equatable {
  final String id;
  final double x;
  final double y;

  const PlacementPosition({required this.id, required this.x, required this.y});

  @override
  List<Object?> get props => [id, x, y];
}

/// Definition of a game map with enemy path and tower placement spots.
class GameMap extends Equatable {
  final String id;
  final String name;
  final String eraId;
  final List<PathPoint> path; // ordered waypoints enemies follow
  final List<PlacementPosition> placements; // where towers can go
  final int waveCount; // number of waves on this map

  const GameMap({
    required this.id,
    required this.name,
    required this.eraId,
    required this.path,
    required this.placements,
    required this.waveCount,
  });

  /// Total path length (sum of distances between consecutive points).
  double get totalPathLength {
    double length = 0;
    for (int i = 1; i < path.length; i++) {
      length += path[i - 1].distanceTo(path[i]);
    }
    return length;
  }

  /// Convert a progress value (0.0-1.0) to a world position on the path.
  ///
  /// Progress 0.0 = path start, 1.0 = path end.
  /// Values outside [0, 1] are clamped.
  PathPoint positionAtProgress(double progress) {
    if (path.isEmpty) return const PathPoint(x: 0, y: 0);
    if (path.length == 1) return path.first;
    if (progress <= 0) return path.first;
    if (progress >= 1) return path.last;

    final targetDist = progress * totalPathLength;
    double accumulated = 0;

    for (int i = 1; i < path.length; i++) {
      final segmentLength = path[i - 1].distanceTo(path[i]);
      if (accumulated + segmentLength >= targetDist) {
        final t = (targetDist - accumulated) / segmentLength;
        return PathPoint(
          x: path[i - 1].x + (path[i].x - path[i - 1].x) * t,
          y: path[i - 1].y + (path[i].y - path[i - 1].y) * t,
        );
      }
      accumulated += segmentLength;
    }
    return path.last;
  }

  @override
  List<Object?> get props => [id, name, eraId, path, placements, waveCount];
}
