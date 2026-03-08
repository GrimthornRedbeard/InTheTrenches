import 'dart:math' as math;

import '../models/enemy_instance.dart';
import '../models/game_map.dart';
import '../models/placed_tower.dart';
import '../models/tower.dart';
import 'targeting_engine.dart';

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
///    in range, selected by [TargetingMode].
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
  /// [mode] — targeting strategy (defaults to [TargetingMode.first]).
  CombatResult tick({
    required double deltaTime,
    required List<PlacedTower> towers,
    required List<EnemyInstance> enemies,
    required GameMap map,
    required Map<String, TowerDefinition> towerLookup,
    required Map<String, int> enemyRewards,
    TargetingMode mode = TargetingMode.first,
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

      // Find alive enemies in range using TargetingEngine.
      final inRange = TargetingEngine.enemiesInRange(
        tower: tower,
        towerRange: towerDef.range,
        enemies: mutableEnemies,
        map: map,
      );

      if (inRange.isEmpty) continue;

      // Select target using TargetingEngine.
      final target = TargetingEngine.selectTarget(
        mode: mode,
        tower: tower,
        enemies: inRange,
        map: map,
      );

      if (target == null) continue;

      // Find the index of the selected target in the mutable list.
      final targetIndex = mutableEnemies.indexWhere((e) => e.id == target.id);
      if (targetIndex == -1) continue;

      final mutableTarget = mutableEnemies[targetIndex];

      // Calculate effective damage.
      final effectiveDamage = math.max(
        0.0,
        towerDef.damage - mutableTarget.armor,
      );

      // Apply damage.
      final newHp = math.max(0.0, mutableTarget.currentHp - effectiveDamage);
      final killed = newHp <= 0;

      mutableEnemies[targetIndex] = mutableTarget.copyWith(
        currentHp: newHp,
        alive: !killed,
      );

      // Record fire event.
      fireEvents.add(
        FireEvent(
          towerId: tower.id,
          enemyId: mutableTarget.id,
          damage: effectiveDamage,
        ),
      );

      // Award gold on kill.
      if (killed) {
        goldAwarded += enemyRewards[mutableTarget.definitionId] ?? 0;
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
}
