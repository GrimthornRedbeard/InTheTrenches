import 'package:equatable/equatable.dart';

/// Special ability that an enemy may possess.
enum EnemyAbility {
  heal,
  buff,
  shield,
  sap,
  siege;

  String toJson() => name;

  static EnemyAbility fromJson(String json) =>
      EnemyAbility.values.firstWhere((e) => e.name == json);
}

/// Definition of an enemy type available in the game.
///
/// Represents an enemy blueprint (not a spawned instance). Each enemy belongs
/// to an era, has stats, and an optional special ability.
class EnemyDefinition extends Equatable {
  final String id;
  final String name;
  final String eraId;
  final double hp;
  final double speed;
  final double armor;
  final int reward;
  final EnemyAbility? ability;
  final String description;

  const EnemyDefinition({
    required this.id,
    required this.name,
    required this.eraId,
    required this.hp,
    required this.speed,
    required this.armor,
    required this.reward,
    this.ability,
    required this.description,
  });

  EnemyDefinition copyWith({
    String? id,
    String? name,
    String? eraId,
    double? hp,
    double? speed,
    double? armor,
    int? reward,
    EnemyAbility? ability,
    String? description,
  }) {
    return EnemyDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      eraId: eraId ?? this.eraId,
      hp: hp ?? this.hp,
      speed: speed ?? this.speed,
      armor: armor ?? this.armor,
      reward: reward ?? this.reward,
      ability: ability ?? this.ability,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'eraId': eraId,
      'hp': hp,
      'speed': speed,
      'armor': armor,
      'reward': reward,
      'ability': ability?.toJson(),
      'description': description,
    };
  }

  factory EnemyDefinition.fromJson(Map<String, dynamic> json) {
    return EnemyDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      eraId: json['eraId'] as String,
      hp: (json['hp'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      armor: (json['armor'] as num).toDouble(),
      reward: json['reward'] as int,
      ability: json['ability'] != null
          ? EnemyAbility.fromJson(json['ability'] as String)
          : null,
      description: json['description'] as String,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        eraId,
        hp,
        speed,
        armor,
        reward,
        ability,
        description,
      ];
}
