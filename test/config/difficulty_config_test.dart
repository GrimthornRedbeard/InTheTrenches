import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/config/difficulty_config.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  // Base enemy definition for tests
  const baseEnemy = EnemyDefinition(
    id: 'infantry',
    name: 'Infantry',
    eraId: 'ww1',
    hp: 100.0,
    speed: 10.0,
    armor: 0.0,
    reward: 10,
    description: 'Basic enemy',
  );

  // ---------------------------------------------------------------------------
  // DifficultyConfig — modifiers
  // ---------------------------------------------------------------------------

  group('DifficultyConfig — Normal', () {
    test('Normal: enemy HP multiplier is 1.0x', () {
      final config = DifficultyConfig.normal();
      expect(config.hpMultiplier, closeTo(1.0, 1e-10));
    });

    test('Normal: enemy count multiplier is 1.0x', () {
      final config = DifficultyConfig.normal();
      expect(config.enemyCountMultiplier, closeTo(1.0, 1e-10));
    });

    test('Normal: enemy speed multiplier is 1.0x', () {
      final config = DifficultyConfig.normal();
      expect(config.speedMultiplier, closeTo(1.0, 1e-10));
    });

    test('Normal: starting resources at 100%', () {
      final config = DifficultyConfig.normal();
      expect(config.startingResourceMultiplier, closeTo(1.0, 1e-10));
    });
  });

  group('DifficultyConfig — Hard', () {
    test('Hard: enemy HP multiplier is 1.5x', () {
      final config = DifficultyConfig.hard();
      expect(config.hpMultiplier, closeTo(1.5, 1e-10));
    });

    test('Hard: enemy count multiplier is 1.25x', () {
      final config = DifficultyConfig.hard();
      expect(config.enemyCountMultiplier, closeTo(1.25, 1e-10));
    });

    test('Hard: enemy speed multiplier is 1.0x', () {
      final config = DifficultyConfig.hard();
      expect(config.speedMultiplier, closeTo(1.0, 1e-10));
    });

    test('Hard: starting resources at 80%', () {
      final config = DifficultyConfig.hard();
      expect(config.startingResourceMultiplier, closeTo(0.8, 1e-10));
    });

    test('hard mode reduces starting resources to 80%', () {
      final config = DifficultyConfig.hard();
      const baseGold = 200;
      final adjusted = config.adjustedStartingGold(baseGold);
      expect(adjusted, 160); // 200 * 0.8
    });
  });

  group('DifficultyConfig — Nightmare', () {
    test('nightmare mode doubles enemy HP', () {
      final config = DifficultyConfig.nightmare();
      expect(config.hpMultiplier, closeTo(2.0, 1e-10));
    });

    test('Nightmare: enemy count multiplier is 1.5x', () {
      final config = DifficultyConfig.nightmare();
      expect(config.enemyCountMultiplier, closeTo(1.5, 1e-10));
    });

    test('Nightmare: enemy speed multiplier is 1.0x', () {
      final config = DifficultyConfig.nightmare();
      expect(config.speedMultiplier, closeTo(1.0, 1e-10));
    });

    test('Nightmare: starting resources at 60%', () {
      final config = DifficultyConfig.nightmare();
      expect(config.startingResourceMultiplier, closeTo(0.6, 1e-10));
    });
  });

  // ---------------------------------------------------------------------------
  // applyToEnemy — HP scaling
  // ---------------------------------------------------------------------------

  group('DifficultyConfig — applyToEnemy', () {
    test('Normal leaves enemy HP unchanged', () {
      final config = DifficultyConfig.normal();
      final scaled = config.applyToEnemy(baseEnemy);
      expect(scaled.hp, closeTo(100.0, 1e-10));
    });

    test('Hard scales enemy HP by 1.5x', () {
      final config = DifficultyConfig.hard();
      final scaled = config.applyToEnemy(baseEnemy);
      expect(scaled.hp, closeTo(150.0, 1e-10));
    });

    test('Nightmare scales enemy HP by 2.0x', () {
      final config = DifficultyConfig.nightmare();
      final scaled = config.applyToEnemy(baseEnemy);
      expect(scaled.hp, closeTo(200.0, 1e-10));
    });

    test('Speed is unchanged across all difficulties', () {
      for (final config in [
        DifficultyConfig.normal(),
        DifficultyConfig.hard(),
        DifficultyConfig.nightmare(),
      ]) {
        final scaled = config.applyToEnemy(baseEnemy);
        expect(scaled.speed, closeTo(10.0, 1e-10));
      }
    });
  });

  // ---------------------------------------------------------------------------
  // adjustedEnemyCount
  // ---------------------------------------------------------------------------

  group('DifficultyConfig — adjustedEnemyCount', () {
    test('Normal count unchanged', () {
      final config = DifficultyConfig.normal();
      expect(config.adjustedEnemyCount(10), 10);
    });

    test('Hard count multiplied by 1.25 (rounded)', () {
      final config = DifficultyConfig.hard();
      // 10 * 1.25 = 12.5 => 12 (floor)
      expect(config.adjustedEnemyCount(10), 12);
    });

    test('Nightmare count multiplied by 1.5 (rounded)', () {
      final config = DifficultyConfig.nightmare();
      // 10 * 1.5 = 15
      expect(config.adjustedEnemyCount(10), 15);
    });
  });
}
