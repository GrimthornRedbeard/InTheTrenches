import '../models/trench_segment.dart';

class TrenchEngine {
  static const double _contestedThreshold = 80.0;
  static const double _maxBreachHp = 100.0;

  /// Update segment states based on current breach HP values.
  static List<TrenchSegment> updateSegmentStates(List<TrenchSegment> segments) {
    return segments.map((seg) {
      if (seg.state == TrenchSegmentState.collapsed) return seg;

      if (seg.breachHp <= 0 &&
          seg.state != TrenchSegmentState.breached) {
        return seg.copyWith(state: TrenchSegmentState.breached);
      }
      if (seg.breachHp < _contestedThreshold &&
          seg.state == TrenchSegmentState.held) {
        return seg.copyWith(state: TrenchSegmentState.contested);
      }
      if (seg.breachHp >= _contestedThreshold &&
          seg.state == TrenchSegmentState.contested) {
        return seg.copyWith(state: TrenchSegmentState.held);
      }
      return seg;
    }).toList();
  }

  /// Push a breached segment back toward the command post.
  static TrenchSegment collapseSegment(
    TrenchSegment seg, {
    double pushDistance = 60,
  }) => seg.copyWith(
        state: TrenchSegmentState.collapsed,
        worldY: seg.worldY + pushDistance,
        breachHp: 0,
      );

  /// Repair a segment's breach HP (from melee defenders).
  static TrenchSegment repairSegment(
    TrenchSegment seg, {
    required double repairPerSecond,
    required double dt,
  }) {
    final newHp = (seg.breachHp + repairPerSecond * dt).clamp(0.0, _maxBreachHp);
    return seg.copyWith(breachHp: newHp);
  }
}
