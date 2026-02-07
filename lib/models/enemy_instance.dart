import 'package:equatable/equatable.dart';

import 'enemy.dart';

/// A spawned, live enemy on the battlefield.
///
/// Unlike [EnemyDefinition] which is a blueprint, an [EnemyInstance] represents
/// an actual enemy that has been spawned into the game world. It tracks mutable
/// state such as current HP, path progress, and whether the enemy is alive.
class EnemyInstance extends Equatable {
  /// Unique identifier for this spawned enemy (e.g., "enemy_0").
  final String id;

  /// Links back to the [EnemyDefinition] this instance was created from.
  final String definitionId;

  /// Current hit points remaining. Starts at the definition's hp value.
  final double currentHp;

  /// Movement speed along the path.
  final double speed;

  /// Damage reduction from armor.
  final double armor;

  /// Progress along the enemy path: 0.0 = start, 1.0 = reached base.
  final double pathProgress;

  /// Whether this enemy is still alive.
  final bool alive;

  const EnemyInstance({
    required this.id,
    required this.definitionId,
    required this.currentHp,
    required this.speed,
    required this.armor,
    required this.pathProgress,
    required this.alive,
  });

  /// Creates an [EnemyInstance] from an [EnemyDefinition], copying its stats.
  ///
  /// The instance starts at the beginning of the path (pathProgress = 0.0)
  /// and is alive.
  factory EnemyInstance.fromDefinition({
    required String id,
    required EnemyDefinition definition,
  }) =>
      EnemyInstance(
        id: id,
        definitionId: definition.id,
        currentHp: definition.hp,
        speed: definition.speed,
        armor: definition.armor,
        pathProgress: 0.0,
        alive: true,
      );

  EnemyInstance copyWith({
    String? id,
    String? definitionId,
    double? currentHp,
    double? speed,
    double? armor,
    double? pathProgress,
    bool? alive,
  }) {
    return EnemyInstance(
      id: id ?? this.id,
      definitionId: definitionId ?? this.definitionId,
      currentHp: currentHp ?? this.currentHp,
      speed: speed ?? this.speed,
      armor: armor ?? this.armor,
      pathProgress: pathProgress ?? this.pathProgress,
      alive: alive ?? this.alive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        definitionId,
        currentHp,
        speed,
        armor,
        pathProgress,
        alive,
      ];
}
