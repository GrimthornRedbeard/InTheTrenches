/// Difficulty levels available to the player.
enum Difficulty { normal, hard, nightmare }

/// Pure scoring functions for the end-of-map star rating and XP multipliers.
class Scoring {
  Scoring._();

  // ---------------------------------------------------------------------------
  // Star calculation
  // ---------------------------------------------------------------------------

  /// Calculates the star rating (0–3) based on base HP at the end of the map.
  ///
  /// - 3 stars: no damage taken ([baseHpEnd] == [baseHpStart])
  /// - 2 stars: more than 50% HP remaining ([baseHpEnd] > [baseHpStart] / 2)
  /// - 1 star: survived but at 50% or below
  /// - 0 stars: base destroyed (should not reach win evaluation in practice)
  static int calculateStars({
    required int baseHpStart,
    required int baseHpEnd,
  }) {
    if (baseHpEnd <= 0) return 0;
    if (baseHpEnd == baseHpStart) return 3;
    if (baseHpEnd > baseHpStart / 2) return 2;
    return 1;
  }

  // ---------------------------------------------------------------------------
  // XP multiplier by difficulty
  // ---------------------------------------------------------------------------

  /// Returns the XP multiplier for stars earned at the given [difficulty].
  ///
  /// Affects XP gain only — does not change gameplay balance.
  static double starXpMultiplier(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.normal:
        return 1.0;
      case Difficulty.hard:
        return 1.5;
      case Difficulty.nightmare:
        return 2.0;
    }
  }
}
