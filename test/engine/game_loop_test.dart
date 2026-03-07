import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/engine/game_loop.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  EnemyInstance makeEnemy({
    String id = 'enemy_0',
    double pathProgress = 0.5,
    bool alive = true,
    double currentHp = 50.0,
    int damage = 10,
  }) {
    return EnemyInstance(
      id: id,
      definitionId: 'infantry',
      currentHp: currentHp,
      speed: 10.0,
      armor: 0.0,
      pathProgress: pathProgress,
      alive: alive,
    );
  }

  // ---------------------------------------------------------------------------
  // BaseHP — damage and game over
  // ---------------------------------------------------------------------------

  group('GameLoop — base HP and game over', () {
    test('enemy reaching end reduces base HP', () {
      var state = const GameLoopState(baseHp: 100, maxBaseHp: 100);
      // Enemy with damage=10 reaches the base
      state = GameLoop.applyBaseHpDamage(state: state, damage: 10);
      expect(state.baseHp, 90);
    });

    test('base HP cannot go below 0', () {
      var state = const GameLoopState(baseHp: 5, maxBaseHp: 100);
      state = GameLoop.applyBaseHpDamage(state: state, damage: 20);
      expect(state.baseHp, 0);
    });

    test('game over fires when base HP reaches 0', () {
      var state = const GameLoopState(baseHp: 10, maxBaseHp: 100);
      state = GameLoop.applyBaseHpDamage(state: state, damage: 10);
      expect(state.isGameOver, isTrue);
    });

    test('game is not over when HP still positive', () {
      const state = GameLoopState(baseHp: 1, maxBaseHp: 100);
      expect(state.isGameOver, isFalse);
    });

    test('multiple enemies reaching end each reduce HP', () {
      var state = const GameLoopState(baseHp: 100, maxBaseHp: 100);
      state = GameLoop.applyBaseHpDamage(state: state, damage: 10);
      state = GameLoop.applyBaseHpDamage(state: state, damage: 15);
      expect(state.baseHp, 75);
    });
  });

  // ---------------------------------------------------------------------------
  // Wave completion detection
  // ---------------------------------------------------------------------------

  group('GameLoop — wave completion', () {
    test('wave is complete when all enemies are dead', () {
      final enemies = [
        makeEnemy(id: 'a', alive: false),
        makeEnemy(id: 'b', alive: false),
      ];

      expect(
        GameLoop.isWaveComplete(enemies: enemies, allSpawned: true),
        isTrue,
      );
    });

    test('wave not complete if any enemy is alive', () {
      final enemies = [
        makeEnemy(id: 'a', alive: false),
        makeEnemy(id: 'b', alive: true),
      ];

      expect(
        GameLoop.isWaveComplete(enemies: enemies, allSpawned: true),
        isFalse,
      );
    });

    test('wave not complete if not all enemies have been spawned yet', () {
      final enemies = <EnemyInstance>[];

      // allSpawned = false means more enemies are coming
      expect(
        GameLoop.isWaveComplete(enemies: enemies, allSpawned: false),
        isFalse,
      );
    });

    test('wave complete with empty enemy list when all spawned', () {
      // All enemies spawned and all dead (empty list = no active enemies)
      expect(GameLoop.isWaveComplete(enemies: [], allSpawned: true), isTrue);
    });

    test('wave completion detected when all enemies dead', () {
      final enemies = [
        makeEnemy(id: 'e1', alive: false, currentHp: 0),
        makeEnemy(id: 'e2', alive: false, currentHp: 0),
        makeEnemy(id: 'e3', alive: false, currentHp: 0),
      ];
      expect(
        GameLoop.isWaveComplete(enemies: enemies, allSpawned: true),
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Win evaluation
  // ---------------------------------------------------------------------------

  group('GameLoop — win evaluation', () {
    test('win triggers after last wave is cleared', () {
      const state = GameLoopState(baseHp: 80, maxBaseHp: 100);
      final result = GameLoop.evaluateWin(
        state: state,
        currentWave: 3,
        totalWaves: 3,
        waveComplete: true,
      );

      expect(result.isVictory, isTrue);
    });

    test('no win if more waves remain', () {
      const state = GameLoopState(baseHp: 80, maxBaseHp: 100);
      final result = GameLoop.evaluateWin(
        state: state,
        currentWave: 2,
        totalWaves: 3,
        waveComplete: true,
      );

      expect(result.isVictory, isFalse);
    });

    test('no win if game is over (HP = 0)', () {
      const state = GameLoopState(baseHp: 0, maxBaseHp: 100);
      final result = GameLoop.evaluateWin(
        state: state,
        currentWave: 3,
        totalWaves: 3,
        waveComplete: true,
      );

      expect(result.isVictory, isFalse);
      expect(result.isGameOver, isTrue);
    });

    test('no win if wave not complete yet', () {
      const state = GameLoopState(baseHp: 80, maxBaseHp: 100);
      final result = GameLoop.evaluateWin(
        state: state,
        currentWave: 3,
        totalWaves: 3,
        waveComplete: false,
      );

      expect(result.isVictory, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // GameLoopState immutability
  // ---------------------------------------------------------------------------

  group('GameLoopState', () {
    test('copyWith updates baseHp', () {
      const state = GameLoopState(baseHp: 100, maxBaseHp: 100);
      final updated = state.copyWith(baseHp: 75);
      expect(updated.baseHp, 75);
      expect(updated.maxBaseHp, 100);
    });

    test('isGameOver is false for positive HP', () {
      const state = GameLoopState(baseHp: 1, maxBaseHp: 100);
      expect(state.isGameOver, isFalse);
    });

    test('isGameOver is true at 0 HP', () {
      const state = GameLoopState(baseHp: 0, maxBaseHp: 100);
      expect(state.isGameOver, isTrue);
    });
  });
}
