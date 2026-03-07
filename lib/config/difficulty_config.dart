import '../models/enemy.dart';

/// Difficulty modifiers that scale enemy stats and starting resources.
///
/// Applied at map-load time when building wave enemy instances.
class DifficultyConfig {
  /// Enemy HP multiplier (e.g., 2.0 = double HP).
  final double hpMultiplier;

  /// Enemy count multiplier applied when building wave groups.
  final double enemyCountMultiplier;

  /// Enemy speed multiplier (currently 1.0 across all difficulties).
  final double speedMultiplier;

  /// Fraction of base starting gold the player receives.
  final double startingResourceMultiplier;

  const DifficultyConfig({
    required this.hpMultiplier,
    required this.enemyCountMultiplier,
    required this.speedMultiplier,
    required this.startingResourceMultiplier,
  });

  // ---------------------------------------------------------------------------
  // Named constructors
  // ---------------------------------------------------------------------------

  /// Normal difficulty: 1× everything.
  factory DifficultyConfig.normal() => const DifficultyConfig(
    hpMultiplier: 1.0,
    enemyCountMultiplier: 1.0,
    speedMultiplier: 1.0,
    startingResourceMultiplier: 1.0,
  );

  /// Hard difficulty: 1.5× HP, 1.25× count, 80% starting gold.
  factory DifficultyConfig.hard() => const DifficultyConfig(
    hpMultiplier: 1.5,
    enemyCountMultiplier: 1.25,
    speedMultiplier: 1.0,
    startingResourceMultiplier: 0.8,
  );

  /// Nightmare difficulty: 2× HP, 1.5× count, 60% starting gold.
  factory DifficultyConfig.nightmare() => const DifficultyConfig(
    hpMultiplier: 2.0,
    enemyCountMultiplier: 1.5,
    speedMultiplier: 1.0,
    startingResourceMultiplier: 0.6,
  );

  // ---------------------------------------------------------------------------
  // Application helpers
  // ---------------------------------------------------------------------------

  /// Returns a modified copy of [enemy] with HP (and speed) scaled by this
  /// difficulty's multipliers.
  EnemyDefinition applyToEnemy(EnemyDefinition enemy) {
    return enemy.copyWith(
      hp: enemy.hp * hpMultiplier,
      speed: enemy.speed * speedMultiplier,
    );
  }

  /// Returns the adjusted enemy count for a wave group, floored to an integer.
  int adjustedEnemyCount(int baseCount) {
    return (baseCount * enemyCountMultiplier).floor();
  }

  /// Returns starting gold adjusted by [startingResourceMultiplier], floored.
  int adjustedStartingGold(int baseGold) {
    return (baseGold * startingResourceMultiplier).floor();
  }
}
