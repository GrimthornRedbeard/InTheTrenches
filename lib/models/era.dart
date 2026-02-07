import 'package:equatable/equatable.dart';

import 'enemy.dart';
import 'tower.dart';

/// Represents a historical era in the game.
///
/// Each era contains its own set of towers, enemies, and maps. The game
/// launches with WWI and Medieval eras.
class Era extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<TowerDefinition> towers;
  final List<EnemyDefinition> enemies;
  final int mapCount;

  const Era({
    required this.id,
    required this.name,
    required this.description,
    required this.towers,
    required this.enemies,
    required this.mapCount,
  });

  Era copyWith({
    String? id,
    String? name,
    String? description,
    List<TowerDefinition>? towers,
    List<EnemyDefinition>? enemies,
    int? mapCount,
  }) {
    return Era(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      towers: towers ?? this.towers,
      enemies: enemies ?? this.enemies,
      mapCount: mapCount ?? this.mapCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'towers': towers.map((t) => t.toJson()).toList(),
      'enemies': enemies.map((e) => e.toJson()).toList(),
      'mapCount': mapCount,
    };
  }

  factory Era.fromJson(Map<String, dynamic> json) {
    return Era(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      towers: (json['towers'] as List<dynamic>)
          .map((t) => TowerDefinition.fromJson(t as Map<String, dynamic>))
          .toList(),
      enemies: (json['enemies'] as List<dynamic>)
          .map((e) => EnemyDefinition.fromJson(e as Map<String, dynamic>))
          .toList(),
      mapCount: json['mapCount'] as int,
    );
  }

  @override
  List<Object?> get props => [id, name, description, towers, enemies, mapCount];
}
