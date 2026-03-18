// lib/models/trench_segment.dart
import 'package:equatable/equatable.dart';

enum TrenchSegmentState { held, contested, breached, collapsed }

class TrenchSegment extends Equatable {
  final int index;
  final double worldX;
  final double worldY;
  final double breachHp;
  final TrenchSegmentState state;

  const TrenchSegment({
    required this.index,
    required this.worldX,
    required this.worldY,
    required this.breachHp,
    this.state = TrenchSegmentState.held,
  });

  bool get isBreached =>
      state == TrenchSegmentState.breached ||
      state == TrenchSegmentState.collapsed;

  TrenchSegment copyWith({
    int? index,
    double? worldX,
    double? worldY,
    double? breachHp,
    TrenchSegmentState? state,
  }) => TrenchSegment(
        index: index ?? this.index,
        worldX: worldX ?? this.worldX,
        worldY: worldY ?? this.worldY,
        breachHp: breachHp ?? this.breachHp,
        state: state ?? this.state,
      );

  @override
  List<Object?> get props => [index, worldX, worldY, breachHp, state];
}
