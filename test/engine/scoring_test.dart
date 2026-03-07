import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/engine/scoring.dart';

void main() {
  // ---------------------------------------------------------------------------
  // calculateStars
  // ---------------------------------------------------------------------------

  group('Scoring — calculateStars', () {
    test('3 stars when 0 damage taken (baseHpEnd == baseHpStart)', () {
      expect(Scoring.calculateStars(baseHpStart: 100, baseHpEnd: 100), 3);
    });

    test('2 stars when base HP > 50% remaining', () {
      // 51 > 50% of 100
      expect(Scoring.calculateStars(baseHpStart: 100, baseHpEnd: 51), 2);
    });

    test('2 stars when base HP is exactly 50% + 1', () {
      expect(Scoring.calculateStars(baseHpStart: 100, baseHpEnd: 51), 2);
    });

    test('1 star when base HP between 1 and 50% (inclusive of 50)', () {
      expect(Scoring.calculateStars(baseHpStart: 100, baseHpEnd: 50), 1);
    });

    test('1 star when minimal HP remaining', () {
      expect(Scoring.calculateStars(baseHpStart: 100, baseHpEnd: 1), 1);
    });

    test(
      '0 stars when base HP is 0 (game over — should not reach win eval)',
      () {
        expect(Scoring.calculateStars(baseHpStart: 100, baseHpEnd: 0), 0);
      },
    );

    test('3 stars with non-standard starting HP', () {
      expect(Scoring.calculateStars(baseHpStart: 50, baseHpEnd: 50), 3);
    });

    test('2 stars with non-standard starting HP', () {
      // >50% of 50 = >25. 26 qualifies.
      expect(Scoring.calculateStars(baseHpStart: 50, baseHpEnd: 26), 2);
    });

    test('1 star with non-standard starting HP', () {
      // 25 = exactly 50% of 50, so 1 star
      expect(Scoring.calculateStars(baseHpStart: 50, baseHpEnd: 25), 1);
    });
  });

  // ---------------------------------------------------------------------------
  // applyDifficultyStarMultiplier
  // ---------------------------------------------------------------------------

  group('Scoring — star XP multiplier', () {
    test('Normal difficulty multiplier is 1.0x', () {
      expect(Scoring.starXpMultiplier(Difficulty.normal), closeTo(1.0, 1e-10));
    });

    test('Hard difficulty multiplier is 1.5x', () {
      expect(Scoring.starXpMultiplier(Difficulty.hard), closeTo(1.5, 1e-10));
    });

    test('Nightmare difficulty multiplier is 2.0x', () {
      expect(
        Scoring.starXpMultiplier(Difficulty.nightmare),
        closeTo(2.0, 1e-10),
      );
    });
  });
}
