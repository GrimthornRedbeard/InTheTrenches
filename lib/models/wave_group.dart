import 'package:equatable/equatable.dart';

/// A group of enemies within a wave.
///
/// Defines a batch of identical enemies that spawn with a delay between each.
class WaveGroup extends Equatable {
  final String enemyId;
  final int count;
  final double delayBetween;

  const WaveGroup({
    required this.enemyId,
    required this.count,
    required this.delayBetween,
  });

  WaveGroup copyWith({
    String? enemyId,
    int? count,
    double? delayBetween,
  }) {
    return WaveGroup(
      enemyId: enemyId ?? this.enemyId,
      count: count ?? this.count,
      delayBetween: delayBetween ?? this.delayBetween,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enemyId': enemyId,
      'count': count,
      'delayBetween': delayBetween,
    };
  }

  factory WaveGroup.fromJson(Map<String, dynamic> json) {
    return WaveGroup(
      enemyId: json['enemyId'] as String,
      count: json['count'] as int,
      delayBetween: (json['delayBetween'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [enemyId, count, delayBetween];
}
