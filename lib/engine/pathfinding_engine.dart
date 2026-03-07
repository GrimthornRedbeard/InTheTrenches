import '../models/enemy_instance.dart';
import '../models/game_map.dart';

/// Result of a pathfinding tick, containing updated enemy positions and
/// enemies that reached the player's base.
class PathfindingResult {
  /// All enemies after movement has been applied (including dead ones and
  /// those that reached the base).
  final List<EnemyInstance> updatedEnemies;

  /// Enemies that reached the base this tick (pathProgress >= 1.0).
  /// These enemies are also present in [updatedEnemies] with alive = false.
  final List<EnemyInstance> reachedBase;

  const PathfindingResult({
    required this.updatedEnemies,
    required this.reachedBase,
  });
}

/// Pure-logic engine that moves enemies along the map path each tick.
///
/// Each alive enemy advances along the path based on its speed and the
/// elapsed time. Enemies that reach the end of the path (pathProgress >= 1.0)
/// are marked as no longer alive and collected in [PathfindingResult.reachedBase].
///
/// Dead enemies are kept in the list but are not moved.
class PathfindingEngine {
  /// Advance all alive enemies along the path by [deltaTime] seconds.
  ///
  /// Returns a [PathfindingResult] containing the updated enemy list and
  /// any enemies that reached the base this tick.
  PathfindingResult tick(
    double deltaTime,
    List<EnemyInstance> enemies,
    GameMap map,
  ) {
    final totalPathLength = map.totalPathLength;
    final updated = <EnemyInstance>[];
    final reached = <EnemyInstance>[];

    for (final enemy in enemies) {
      if (!enemy.alive) {
        // Dead enemies don't move — keep them as-is.
        updated.add(enemy);
        continue;
      }

      final progressDelta = (enemy.speed * deltaTime) / totalPathLength;
      final newProgress = enemy.pathProgress + progressDelta;

      if (newProgress >= 1.0) {
        // Enemy reached the base.
        final reachedEnemy = enemy.copyWith(pathProgress: 1.0, alive: false);
        updated.add(reachedEnemy);
        reached.add(reachedEnemy);
      } else {
        updated.add(enemy.copyWith(pathProgress: newProgress));
      }
    }

    return PathfindingResult(updatedEnemies: updated, reachedBase: reached);
  }
}
