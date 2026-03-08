import 'dart:math' as math;

import '../models/enemy_instance.dart';
import '../models/game_map.dart';
import '../models/placed_tower.dart';

/// How a tower selects its target from enemies in range.
enum TargetingMode {
  /// Target the enemy furthest along the path (closest to the base).
  first,

  /// Target the enemy closest to the tower by Euclidean distance.
  nearest,

  /// Target the enemy with the highest current HP.
  strongest,
}

/// Pure-static helpers for tower targeting and fire rate logic.
///
/// All methods are stateless — callers (the game loop / CombatEngine) own
/// any per-tower mutable state such as `timeSinceLastShot`.
class TargetingEngine {
  TargetingEngine._();

  // ---------------------------------------------------------------------------
  // Target selection
  // ---------------------------------------------------------------------------

  /// Returns the best alive target for [tower] from [enemies] using [mode].
  ///
  /// Returns `null` if no alive enemies are available.
  static EnemyInstance? selectTarget({
    required TargetingMode mode,
    required PlacedTower tower,
    required List<EnemyInstance> enemies,
    required GameMap map,
  }) {
    final candidates = enemies.where((e) => e.alive).toList();
    if (candidates.isEmpty) return null;

    switch (mode) {
      case TargetingMode.first:
        return candidates.reduce(
          (best, e) => e.pathProgress > best.pathProgress ? e : best,
        );

      case TargetingMode.nearest:
        EnemyInstance? best;
        double bestDist = double.infinity;
        for (final enemy in candidates) {
          final pos = map.positionAtProgress(enemy.pathProgress);
          final dx = tower.x - pos.x;
          final dy = tower.y - pos.y;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist < bestDist) {
            bestDist = dist;
            best = enemy;
          }
        }
        return best;

      case TargetingMode.strongest:
        return candidates.reduce(
          (best, e) => e.currentHp > best.currentHp ? e : best,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Range filtering
  // ---------------------------------------------------------------------------

  /// Returns all alive enemies within [towerRange] of [tower].
  static List<EnemyInstance> enemiesInRange({
    required PlacedTower tower,
    required double towerRange,
    required List<EnemyInstance> enemies,
    required GameMap map,
  }) {
    final result = <EnemyInstance>[];
    for (final enemy in enemies) {
      if (!enemy.alive) continue;
      final pos = map.positionAtProgress(enemy.pathProgress);
      final dx = tower.x - pos.x;
      final dy = tower.y - pos.y;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist <= towerRange) {
        result.add(enemy);
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Fire rate timer
  // ---------------------------------------------------------------------------

  /// Returns `true` when [timeSinceLastShot] has accumulated enough time
  /// to fire again.
  ///
  /// The fire interval is `1.0 / fireRate` seconds.
  static bool canFire({
    required double timeSinceLastShot,
    required double fireRate,
  }) {
    return timeSinceLastShot >= 1.0 / fireRate;
  }

  /// Computes the new `timeSinceLastShot` value.
  ///
  /// If [fired] is `true`, subtracts one fire interval from [timeSinceLastShot]
  /// (preserving any remainder for the next tick). [deltaTime] is not used
  /// in this branch.
  /// If [fired] is `false`, adds [deltaTime] to [timeSinceLastShot].
  /// [deltaTime] is required because omitting it when `fired=false` would
  /// silently freeze the timer.
  static double nextTimeSinceLastShot({
    required double timeSinceLastShot,
    required double fireRate,
    required bool fired,
    required double deltaTime,
  }) {
    if (fired) {
      // Subtract the interval to preserve the remainder for the next shot.
      return timeSinceLastShot - (1.0 / fireRate);
    }
    return timeSinceLastShot + deltaTime;
  }
}
