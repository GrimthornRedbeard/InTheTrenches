// lib/models/enemy_instance.dart
import 'dart:ui' show Offset;
import 'package:equatable/equatable.dart';
import 'enemy.dart';
import 'enemy_state.dart';

class EnemyInstance extends Equatable {
  final String id;
  final String definitionId;
  final double currentHp;
  final double speed;
  final double armor;
  final bool alive;

  // New 2D movement fields (replaces pathProgress)
  final Offset position;
  final Offset velocity;
  final EnemyMovementState movementState;
  final int targetSegmentIndex;

  const EnemyInstance({
    required this.id,
    required this.definitionId,
    required this.currentHp,
    required this.speed,
    required this.armor,
    required this.alive,
    this.position = Offset.zero,
    this.velocity = Offset.zero,
    this.movementState = EnemyMovementState.advancing,
    this.targetSegmentIndex = 0,
  });

  factory EnemyInstance.fromDefinition({
    required String id,
    required EnemyDefinition definition,
    Offset spawnPosition = Offset.zero,
    int targetSegment = 0,
  }) => EnemyInstance(
        id: id,
        definitionId: definition.id,
        currentHp: definition.hp,
        speed: definition.speed,
        armor: definition.armor,
        alive: true,
        position: spawnPosition,
        targetSegmentIndex: targetSegment,
      );

  EnemyInstance copyWith({
    String? id,
    String? definitionId,
    double? currentHp,
    double? speed,
    double? armor,
    bool? alive,
    Offset? position,
    Offset? velocity,
    EnemyMovementState? movementState,
    int? targetSegmentIndex,
  }) => EnemyInstance(
        id: id ?? this.id,
        definitionId: definitionId ?? this.definitionId,
        currentHp: currentHp ?? this.currentHp,
        speed: speed ?? this.speed,
        armor: armor ?? this.armor,
        alive: alive ?? this.alive,
        position: position ?? this.position,
        velocity: velocity ?? this.velocity,
        movementState: movementState ?? this.movementState,
        targetSegmentIndex: targetSegmentIndex ?? this.targetSegmentIndex,
      );

  @override
  List<Object?> get props => [
        id, definitionId, currentHp, speed, armor, alive,
        position, velocity, movementState, targetSegmentIndex,
      ];
}
