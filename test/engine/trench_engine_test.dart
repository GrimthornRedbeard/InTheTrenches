import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/engine/trench_engine.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  group('TrenchEngine — segment state transitions', () {
    test('segment transitions held → contested when breach HP drops below 80', () {
      final seg = const TrenchSegment(index: 0, worldX: 0, worldY: 300, breachHp: 79);
      final result = TrenchEngine.updateSegmentStates([seg]);
      expect(result[0].state, TrenchSegmentState.contested);
    });

    test('segment transitions contested → breached when breach HP hits 0', () {
      final seg = const TrenchSegment(
        index: 0, worldX: 0, worldY: 300, breachHp: 0,
        state: TrenchSegmentState.contested,
      );
      final result = TrenchEngine.updateSegmentStates([seg]);
      expect(result[0].state, TrenchSegmentState.breached);
    });

    test('breached segment collapses (worldY advances) after collapse delay', () {
      final seg = const TrenchSegment(
        index: 0, worldX: 0, worldY: 300, breachHp: 0,
        state: TrenchSegmentState.breached,
      );
      final result = TrenchEngine.collapseSegment(seg, pushDistance: 60);
      expect(result.state, TrenchSegmentState.collapsed);
      expect(result.worldY, 360);
    });

    test('segment repairs breach HP when melee defender present', () {
      final seg = const TrenchSegment(
        index: 0, worldX: 0, worldY: 300, breachHp: 40,
        state: TrenchSegmentState.contested,
      );
      final result = TrenchEngine.repairSegment(seg, repairPerSecond: 10, dt: 1.0);
      expect(result.breachHp, closeTo(50, 0.1));
    });

    test('repair does not exceed 100', () {
      final seg = const TrenchSegment(index: 0, worldX: 0, worldY: 300, breachHp: 95);
      final result = TrenchEngine.repairSegment(seg, repairPerSecond: 20, dt: 1.0);
      expect(result.breachHp, 100);
    });
  });
}
