import 'dart:ui' show Offset;
import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/engine/breach_engine.dart';
import 'package:trench_defense/models/models.dart';

EnemyInstance _breaching({String id = 'e0', double hp = 50}) => EnemyInstance(
      id: id, definitionId: 'inf', currentHp: hp,
      speed: 8, armor: 0, alive: true,
      position: const Offset(150, 300),
      movementState: EnemyMovementState.breaching,
      targetSegmentIndex: 0,
    );

const _seg = TrenchSegment(index: 0, worldX: 150, worldY: 300, breachHp: 100);

void main() {
  group('BreachEngine', () {
    test('breaching enemy drains segment breach HP each tick', () {
      final result = BreachEngine.tick(
        dt: 1.0,
        enemies: [_breaching()],
        segments: [_seg],
        drainPerSecond: 20,
      );
      expect(result.updatedSegments[0].breachHp, closeTo(80, 0.1));
    });

    test('enemy transitions to inTrench when breach HP hits zero', () {
      final result = BreachEngine.tick(
        dt: 10.0,
        enemies: [_breaching()],
        segments: [_seg],
        drainPerSecond: 20, // 200 drain > 100 HP
      );
      expect(result.updatedSegments[0].breachHp, 0);
      expect(result.updatedEnemies[0].movementState, EnemyMovementState.inTrench);
    });

    test('inTrench enemy killed by melee tick transitions to dead', () {
      final inTrench = _breaching().copyWith(
        movementState: EnemyMovementState.inTrench,
        currentHp: 10,
      );
      final result = BreachEngine.tick(
        dt: 0.016,
        enemies: [inTrench],
        segments: [_seg],
        drainPerSecond: 20,
        meleeDamagePerSecond: 800,
      );
      expect(result.updatedEnemies[0].alive, false);
    });
  });
}
