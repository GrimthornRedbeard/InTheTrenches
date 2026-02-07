/// Global game constants for Trench Defense.
///
/// Centralizes balance values so they can be tuned without hunting
/// through code. All values are compile-time constants.
class GameConstants {
  GameConstants._();

  // ---------------------------------------------------------------------------
  // Starting Resources
  // ---------------------------------------------------------------------------

  /// Gold the player begins each map with.
  static const int startingGold = 200;

  /// Lives the player begins each map with.
  static const int startingLives = 20;

  // ---------------------------------------------------------------------------
  // Map Configuration
  // ---------------------------------------------------------------------------

  /// Number of maps available per era.
  static const int mapsPerEra = 5;

  // ---------------------------------------------------------------------------
  // Difficulty Multipliers
  // ---------------------------------------------------------------------------

  /// HP multiplier for Normal difficulty.
  static const double normalHpMultiplier = 1.0;

  /// HP multiplier for Hard difficulty.
  static const double hardHpMultiplier = 1.5;

  /// HP multiplier for Nightmare difficulty.
  static const double nightmareHpMultiplier = 2.0;
}
