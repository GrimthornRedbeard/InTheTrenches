// test/models/trench_segment_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/models/trench_segment.dart';

void main() {
  group('TrenchSegment', () {
    test('starts as held with full breach HP', () {
      final seg = TrenchSegment(
        index: 0,
        worldX: 100,
        worldY: 300,
        breachHp: 100,
      );
      expect(seg.state, TrenchSegmentState.held);
      expect(seg.breachHp, 100);
    });

    test('copyWith updates fields', () {
      final seg = TrenchSegment(index: 0, worldX: 100, worldY: 300, breachHp: 100);
      final updated = seg.copyWith(breachHp: 50, state: TrenchSegmentState.contested);
      expect(updated.breachHp, 50);
      expect(updated.state, TrenchSegmentState.contested);
      expect(updated.worldX, 100); // unchanged
    });

    test('isBreached true when state is breached or collapsed', () {
      final breached = TrenchSegment(index: 0, worldX: 0, worldY: 0, breachHp: 0,
          state: TrenchSegmentState.breached);
      final collapsed = TrenchSegment(index: 0, worldX: 0, worldY: 0, breachHp: 0,
          state: TrenchSegmentState.collapsed);
      final held = TrenchSegment(index: 0, worldX: 0, worldY: 0, breachHp: 100);
      expect(breached.isBreached, true);
      expect(collapsed.isBreached, true);
      expect(held.isBreached, false);
    });
  });
}
