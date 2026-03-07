import 'dart:math' as math;

import '../models/enemy_instance.dart';
import '../models/game_map.dart';
import '../models/placed_tower.dart';
import '../models/tower.dart';

/// How the tower selects its target from enemies in range.
enum TargetPriority {
  /// Target the enemy closest to the base (highest pathProgress).
  first,

  /// Target the nearest enemy by Euclidean distance.
  nearest,

  /// Target the enemy with the most remaining HP.
  strongest,
}

/// A record of a single tower firing at an enemy.
class FireEvent {
  /// The ID of the tower that fired.
  final String towerId;

  /// The ID of the enemy that was hit.
  final String enemyId;

  /// The effective damage dealt (after armor reduction).
  final double damage;

  const FireEvent({
    required this.towerId,
    required this.enemyId,
    required this.damage,
  });
}

/// Result of a combat tick.
class CombatResult {
  /// All enemies after combat damage has been applied.
  final List<EnemyInstance> updatedEnemies;

  /// Every shot fired this tick.
  final List<FireEvent> fireEvents;

  /// Total gold earned from kills this tick.
  final int goldAwarded;

  const CombatResult({
    required this.updatedEnemies,
    required this.fireEvents,
    required this.goldAwarded,
  });
}

/// Stateful engine that resolves tower-vs-enemy combat each tick.
///
/// Tracks per-tower attack cooldowns across ticks. Each tick:
/// 1. All cooldowns are reduced by deltaTime.
/// 2. Each tower that is off cooldown attempts to find and fire at an enemy
///    in range, selected by [TargetPriority].
/// 3. Damage is applied immediately so subsequent towers see updated HP.
/// 4. Kills award gold from [enemyRewards].
class CombatEngine {
  /// Remaining cooldown (in seconds) for each tower, keyed by tower ID.
  final Map<String, double> _cooldowns = {};

  /// Process one combat tick.
  ///
  /// [deltaTime] — seconds since the last tick.
  /// [towers] — all placed towers on the map.
  /// [enemies] — current enemy instances (may include dead ones).
  /// [map] — the game map, used to convert pathProgress to world position.
  /// [towerLookup] — maps tower definitionId to its [TowerDefinition].
  /// [enemyRewards] — maps enemy definitionId to gold reward on kill.
  /// [priority] — targeting strategy (defaults to [TargetPriority.first]).
  CombatResult tick({
    required double deltaTime,
    required List<PlacedTower> towers,
    required List<EnemyInstance> enemies,
    required GameMap map,
    required Map<String, TowerDefinition> towerLookup,
    required Map<String, int> enemyRewards,
    TargetPriority priority = TargetPriority.first,
  }) {
    // 1. Reduce all cooldowns by deltaTime.
    for (final key in _cooldowns.keys.toList()) {
      _cooldowns[key] = _cooldowns[key]! - deltaTime;
    }

    // Work on a mutable copy so tower B sees damage from tower A.
    final mutableEnemies = enemies.map((e) => e).toList();
    final fireEvents = <FireEvent>[];
    int goldAwarded = 0;

    // 2. For each tower, attempt to fire.
    for (final tower in towers) {
      final towerDef = towerLookup[tower.definitionId];
      if (towerDef == null) continue;

      // Check cooldown.
      final cooldown = _cooldowns[tower.id] ?? 0.0;
      if (cooldown > 0) continue;

      // Find alive enemies in range.
      final inRange = <int>[];
      for (int i = 0; i < mutableEnemies.length; i++) {
        final enemy = mutableEnemies[i];
        if (!enemy.alive) continue;

        final enemyPos = map.positionAtProgress(enemy.pathProgress);
        final dx = tower.x - enemyPos.x;
        final dy = tower.y - enemyPos.y;
        final dist = math.sqrt(dx * dx + dy * dy);

        if (dist <= towerDef.range) {
          inRange.add(i);
        }
      }

      if (inRange.isEmpty) continue;

      // Select target by priority.
      final targetIndex = _selectTarget(
        priority,
        inRange,
        mutableEnemies,
        tower,
        map,
      );

      final target = mutableEnemies[targetIndex];

      // Calculate effective damage.
      final effectiveDamage = math.max(0.0, towerDef.damage - target.armor);

      // Apply damage.
      final newHp = math.max(0.0, target.currentHp - effectiveDamage);
      final killed = newHp <= 0;

      mutableEnemies[targetIndex] = target.copyWith(
        currentHp: newHp,
        alive: !killed,
      );

      // Record fire event.
      fireEvents.add(
        FireEvent(
          towerId: tower.id,
          enemyId: target.id,
          damage: effectiveDamage,
        ),
      );

      // Award gold on kill.
      if (killed) {
        goldAwarded += enemyRewards[target.definitionId] ?? 0;
      }

      // Set cooldown.
      _cooldowns[tower.id] = 1.0 / towerDef.attackSpeed;
    }

    return CombatResult(
      updatedEnemies: mutableEnemies,
      fireEvents: fireEvents,
      goldAwarded: goldAwarded,
    );
  }

  /// Clear all tower cooldowns.
  void resetCooldowns() => _cooldowns.clear();

  /// Select the best target index from [candidates] based on [priority].
  int _selectTarget(
    TargetPriority priority,
    List<int> candidates,
    List<EnemyInstance> enemies,
    PlacedTower tower,
    GameMap map,
  ) {
    switch (priority) {
      case TargetPriority.first:
        // Highest pathProgress = closest to base.
        int best = candidates.first;
        for (final idx in candidates) {
          if (enemies[idx].pathProgress > enemies[best].pathProgress) {
            best = idx;
          }
        }
        return best;

      case TargetPriority.nearest:
        // Smallest Euclidean distance to tower.
        int best = candidates.first;
        double bestDist = double.infinity;
        for (final idx in candidates) {
          final pos = map.positionAtProgress(enemies[idx].pathProgress);
          final dx = tower.x - pos.x;
          final dy = tower.y - pos.y;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist < bestDist) {
            bestDist = dist;
            best = idx;
          }
        }
        return best;

      case TargetPriority.strongest:
        // Highest current HP.
        int best = candidates.first;
        for (final idx in candidates) {
          if (enemies[idx].currentHp > enemies[best].currentHp) {
            best = idx;
          }
        }
        return best;
    }
  }
}
