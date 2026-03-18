import '../models/enemy_instance.dart';
import '../models/enemy_state.dart';
import '../models/trench_segment.dart';

class BreachResult {
  final List<EnemyInstance> updatedEnemies;
  final List<TrenchSegment> updatedSegments;
  final int goldAwarded;

  const BreachResult({
    required this.updatedEnemies,
    required this.updatedSegments,
    required this.goldAwarded,
  });
}

class BreachEngine {
  static BreachResult tick({
    required double dt,
    required List<EnemyInstance> enemies,
    required List<TrenchSegment> segments,
    double drainPerSecond = 15,
    double meleeDamagePerSecond = 50,
    Map<String, int> enemyRewards = const {},
  }) {
    final updatedSegs = segments.map((s) => s).toList();
    final updatedEnemies = <EnemyInstance>[];
    int gold = 0;

    for (final enemy in enemies) {
      if (!enemy.alive) { updatedEnemies.add(enemy); continue; }

      if (enemy.movementState == EnemyMovementState.breaching) {
        // Drain segment breach HP
        final seg = updatedSegs[enemy.targetSegmentIndex];
        final newHp = (seg.breachHp - drainPerSecond * dt).clamp(0.0, 100.0);
        updatedSegs[enemy.targetSegmentIndex] = seg.copyWith(breachHp: newHp);

        if (newHp <= 0) {
          // Transition to inTrench
          updatedEnemies.add(enemy.copyWith(movementState: EnemyMovementState.inTrench));
        } else {
          updatedEnemies.add(enemy);
        }
        continue;
      }

      if (enemy.movementState == EnemyMovementState.inTrench) {
        // Melee damage
        final dmg = meleeDamagePerSecond * dt;
        final newHp = enemy.currentHp - dmg;
        if (newHp <= 0) {
          gold += enemyRewards[enemy.definitionId] ?? 0;
          updatedEnemies.add(enemy.copyWith(currentHp: 0, alive: false));
        } else {
          updatedEnemies.add(enemy.copyWith(currentHp: newHp));
        }
        continue;
      }

      updatedEnemies.add(enemy);
    }

    return BreachResult(
      updatedEnemies: updatedEnemies,
      updatedSegments: updatedSegs,
      goldAwarded: gold,
    );
  }
}
