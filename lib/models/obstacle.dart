import 'dart:ui' show Offset;
import 'package:equatable/equatable.dart';

enum ObstacleType { barbedWire, shellCrater }

class Obstacle extends Equatable {
  final String id;
  final ObstacleType type;
  final Offset position;
  final double radius; // repulsion/collision radius

  const Obstacle({
    required this.id,
    required this.type,
    required this.position,
    required this.radius,
  });

  @override
  List<Object?> get props => [id, type, position, radius];
}
