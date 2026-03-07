import 'package:equatable/equatable.dart';

import 'placed_tower.dart';

/// The current phase of a game session.
enum GamePhase {
  building,
  waveActive,
  waveComplete,
  victory,
  defeat;

  String toJson() => name;

  static GamePhase fromJson(String json) =>
      GamePhase.values.firstWhere((e) => e.name == json);
}

/// The complete state of an active game session.
///
/// Tracks the player's resources, current wave progress, placed towers,
/// and overall game phase.
class GameState extends Equatable {
  final int gold;
  final int lives;
  final int currentWave;
  final String eraId;
  final String mapId;
  final GamePhase phase;
  final List<PlacedTower> towers;

  const GameState({
    required this.gold,
    required this.lives,
    required this.currentWave,
    required this.eraId,
    required this.mapId,
    required this.phase,
    required this.towers,
  });

  GameState copyWith({
    int? gold,
    int? lives,
    int? currentWave,
    String? eraId,
    String? mapId,
    GamePhase? phase,
    List<PlacedTower>? towers,
  }) {
    return GameState(
      gold: gold ?? this.gold,
      lives: lives ?? this.lives,
      currentWave: currentWave ?? this.currentWave,
      eraId: eraId ?? this.eraId,
      mapId: mapId ?? this.mapId,
      phase: phase ?? this.phase,
      towers: towers ?? this.towers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gold': gold,
      'lives': lives,
      'currentWave': currentWave,
      'eraId': eraId,
      'mapId': mapId,
      'phase': phase.toJson(),
      'towers': towers.map((t) => t.toJson()).toList(),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      gold: json['gold'] as int,
      lives: json['lives'] as int,
      currentWave: json['currentWave'] as int,
      eraId: json['eraId'] as String,
      mapId: json['mapId'] as String,
      phase: GamePhase.fromJson(json['phase'] as String),
      towers: (json['towers'] as List<dynamic>)
          .map((t) => PlacedTower.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    gold,
    lives,
    currentWave,
    eraId,
    mapId,
    phase,
    towers,
  ];
}
