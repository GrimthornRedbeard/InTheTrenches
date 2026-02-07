import 'package:equatable/equatable.dart';

import 'wave_group.dart';

/// Represents a single wave of enemies in a game level.
///
/// Each wave consists of one or more groups of enemies and an optional
/// bonus reward for completing the wave.
class Wave extends Equatable {
  final int number;
  final List<WaveGroup> groups;
  final int bonusReward;

  const Wave({
    required this.number,
    required this.groups,
    required this.bonusReward,
  });

  Wave copyWith({
    int? number,
    List<WaveGroup>? groups,
    int? bonusReward,
  }) {
    return Wave(
      number: number ?? this.number,
      groups: groups ?? this.groups,
      bonusReward: bonusReward ?? this.bonusReward,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'groups': groups.map((g) => g.toJson()).toList(),
      'bonusReward': bonusReward,
    };
  }

  factory Wave.fromJson(Map<String, dynamic> json) {
    return Wave(
      number: json['number'] as int,
      groups: (json['groups'] as List<dynamic>)
          .map((g) => WaveGroup.fromJson(g as Map<String, dynamic>))
          .toList(),
      bonusReward: json['bonusReward'] as int,
    );
  }

  @override
  List<Object?> get props => [number, groups, bonusReward];
}
