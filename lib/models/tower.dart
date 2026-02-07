import 'package:equatable/equatable.dart';

/// Category of tower determining its behavior archetype.
enum TowerCategory {
  damage,
  area,
  slow;

  String toJson() => name;

  static TowerCategory fromJson(String json) =>
      TowerCategory.values.firstWhere((e) => e.name == json);
}

/// Definition of a tower type available in the game.
///
/// Represents a tower blueprint (not a placed instance). Each tower belongs
/// to an era, has a tier (1-3), stats, and optional upgrade paths.
class TowerDefinition extends Equatable {
  final String id;
  final String name;
  final String eraId;
  final int tier;
  final int cost;
  final double range;
  final double damage;
  final double attackSpeed;
  final String description;
  final String? upgradesFromId;
  final List<String> upgradesTo;
  final TowerCategory category;

  const TowerDefinition({
    required this.id,
    required this.name,
    required this.eraId,
    required this.tier,
    required this.cost,
    required this.range,
    required this.damage,
    required this.attackSpeed,
    required this.description,
    this.upgradesFromId,
    this.upgradesTo = const [],
    required this.category,
  });

  TowerDefinition copyWith({
    String? id,
    String? name,
    String? eraId,
    int? tier,
    int? cost,
    double? range,
    double? damage,
    double? attackSpeed,
    String? description,
    String? upgradesFromId,
    List<String>? upgradesTo,
    TowerCategory? category,
  }) {
    return TowerDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      eraId: eraId ?? this.eraId,
      tier: tier ?? this.tier,
      cost: cost ?? this.cost,
      range: range ?? this.range,
      damage: damage ?? this.damage,
      attackSpeed: attackSpeed ?? this.attackSpeed,
      description: description ?? this.description,
      upgradesFromId: upgradesFromId ?? this.upgradesFromId,
      upgradesTo: upgradesTo ?? this.upgradesTo,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'eraId': eraId,
      'tier': tier,
      'cost': cost,
      'range': range,
      'damage': damage,
      'attackSpeed': attackSpeed,
      'description': description,
      'upgradesFromId': upgradesFromId,
      'upgradesTo': upgradesTo,
      'category': category.toJson(),
    };
  }

  factory TowerDefinition.fromJson(Map<String, dynamic> json) {
    return TowerDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      eraId: json['eraId'] as String,
      tier: json['tier'] as int,
      cost: json['cost'] as int,
      range: (json['range'] as num).toDouble(),
      damage: (json['damage'] as num).toDouble(),
      attackSpeed: (json['attackSpeed'] as num).toDouble(),
      description: json['description'] as String,
      upgradesFromId: json['upgradesFromId'] as String?,
      upgradesTo: (json['upgradesTo'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      category: TowerCategory.fromJson(json['category'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        eraId,
        tier,
        cost,
        range,
        damage,
        attackSpeed,
        description,
        upgradesFromId,
        upgradesTo,
        category,
      ];
}
