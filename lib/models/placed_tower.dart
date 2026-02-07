import 'package:equatable/equatable.dart';

/// A tower instance placed on the game map.
///
/// Links to its [TowerDefinition] via [definitionId] and tracks its position
/// and current upgrade tier.
class PlacedTower extends Equatable {
  final String id;
  final String definitionId;
  final double x;
  final double y;
  final int currentTier;

  const PlacedTower({
    required this.id,
    required this.definitionId,
    required this.x,
    required this.y,
    required this.currentTier,
  });

  PlacedTower copyWith({
    String? id,
    String? definitionId,
    double? x,
    double? y,
    int? currentTier,
  }) {
    return PlacedTower(
      id: id ?? this.id,
      definitionId: definitionId ?? this.definitionId,
      x: x ?? this.x,
      y: y ?? this.y,
      currentTier: currentTier ?? this.currentTier,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'definitionId': definitionId,
      'x': x,
      'y': y,
      'currentTier': currentTier,
    };
  }

  factory PlacedTower.fromJson(Map<String, dynamic> json) {
    return PlacedTower(
      id: json['id'] as String,
      definitionId: json['definitionId'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      currentTier: json['currentTier'] as int,
    );
  }

  @override
  List<Object?> get props => [id, definitionId, x, y, currentTier];
}
