import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/engine/wave_spawner.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  // -------------------------------------------------------------------------
  // Test enemy definitions — no dependency on EraRegistry
  // -------------------------------------------------------------------------
  const testInfantry = EnemyDefinition(
    id: 'test_infantry',
    name: 'Test Infantry',
    eraId: 'test',
    hp: 100,
    speed: 1.0,
    armor: 0,
    reward: 10,
    description: 'Test enemy',
  );

  const testHeavy = EnemyDefinition(
    id: 'test_heavy',
    name: 'Test Heavy',
    eraId: 'test',
    hp: 250,
    speed: 0.6,
    armor: 8,
    reward: 35,
    description: 'Heavy test enemy',
  );

  const testRunner = EnemyDefinition(
    id: 'test_runner',
    name: 'Test Runner',
    eraId: 'test',
    hp: 60,
    speed: 2.0,
    armor: 0,
    reward: 15,
    description: 'Fast test enemy',
  );

  final enemyLookup = <String, EnemyDefinition>{
    testInfantry.id: testInfantry,
    testHeavy.id: testHeavy,
    testRunner.id: testRunner,
  };

  // -------------------------------------------------------------------------
  // Helper to build common waves
  // -------------------------------------------------------------------------
  Wave singleGroupWave({
    String enemyId = 'test_infantry',
    int count = 3,
    double delayBetween = 1.0,
  }) {
    return Wave(
      number: 1,
      groups: [
        WaveGroup(enemyId: enemyId, count: count, delayBetween: delayBetween),
      ],
      bonusReward: 50,
    );
  }

  Wave multiGroupWave() {
    return const Wave(
      number: 1,
      groups: [
        WaveGroup(enemyId: 'test_infantry', count: 2, delayBetween: 1.0),
        WaveGroup(enemyId: 'test_heavy', count: 2, delayBetween: 2.0),
      ],
      bonusReward: 100,
    );
  }

  group('WaveSpawner initialization', () {
    test('state is pending after construction', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(),
        enemyLookup: enemyLookup,
      );
      expect(spawner.state, WaveState.pending);
    });

    test('totalEnemies equals sum of all group counts', () {
      final spawner = WaveSpawner(
        wave: multiGroupWave(),
        enemyLookup: enemyLookup,
      );
      // 2 infantry + 2 heavy = 4
      expect(spawner.totalEnemies, 4);
    });

    test('killedCount starts at 0', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(),
        enemyLookup: enemyLookup,
      );
      expect(spawner.killedCount, 0);
    });

    test('remainingEnemies starts at 0 (nothing spawned yet)', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(),
        enemyLookup: enemyLookup,
      );
      expect(spawner.remainingEnemies, 0);
    });

    test('allSpawned is false initially', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(),
        enemyLookup: enemyLookup,
      );
      expect(spawner.allSpawned, isFalse);
    });
  });

  group('WaveSpawner start', () {
    test('start transitions state from pending to active', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      expect(spawner.state, WaveState.active);
    });

    test('start throws if called when not pending', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      expect(() => spawner.start(), throwsStateError);
    });
  });

  group('WaveSpawner tick — basic spawning', () {
    test('tick returns empty list when state is pending', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(),
        enemyLookup: enemyLookup,
      );
      final result = spawner.tick(1.0);
      expect(result, isEmpty);
    });

    test('first tick spawns first enemy immediately', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      final result = spawner.tick(0.0);
      expect(result, hasLength(1));
      expect(result[0].id, 'enemy_0');
      expect(result[0].definitionId, 'test_infantry');
    });

    test('first spawned enemy has correct stats from definition', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      final result = spawner.tick(0.0);
      final enemy = result[0];
      expect(enemy.currentHp, testInfantry.hp);
      expect(enemy.speed, testInfantry.speed);
      expect(enemy.armor, testInfantry.armor);
      expect(enemy.position.dx, 0.0);
      expect(enemy.position.dy, 0.0);
      expect(enemy.alive, isTrue);
    });

    test('tick with 0 deltaTime after first spawn returns no new enemies', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(delayBetween: 1.0),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      spawner.tick(0.0); // first enemy spawns immediately
      final result = spawner.tick(0.0); // no time passed
      expect(result, isEmpty);
    });

    test('tick at exact delayBetween spawns next enemy', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 3, delayBetween: 1.0),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      spawner.tick(0.0); // enemy_0

      final result = spawner.tick(1.0); // enemy_1 at exactly 1.0s
      expect(result, hasLength(1));
      expect(result[0].id, 'enemy_1');
    });

    test('tick with partial time accumulates correctly', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 3, delayBetween: 1.0),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      spawner.tick(0.0); // enemy_0

      var result = spawner.tick(0.5); // 0.5s accumulated, not enough
      expect(result, isEmpty);

      result = spawner.tick(0.5); // 1.0s total, enough for enemy_1
      expect(result, hasLength(1));
      expect(result[0].id, 'enemy_1');
    });

    test('enemy IDs increment globally', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 3, delayBetween: 0.5),
        enemyLookup: enemyLookup,
      );
      spawner.start();

      final e0 = spawner.tick(0.0); // enemy_0
      final e1 = spawner.tick(0.5); // enemy_1
      final e2 = spawner.tick(0.5); // enemy_2

      expect(e0[0].id, 'enemy_0');
      expect(e1[0].id, 'enemy_1');
      expect(e2[0].id, 'enemy_2');
    });
  });

  group('WaveSpawner tick — large deltaTime', () {
    test('large deltaTime spawns multiple enemies at once', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 5, delayBetween: 1.0),
        enemyLookup: enemyLookup,
      );
      spawner.start();

      // A 10-second tick should spawn all 5 enemies:
      // enemy_0 immediately, then enemy_1..4 at 1s intervals
      final result = spawner.tick(10.0);
      expect(result, hasLength(5));
      expect(result[0].id, 'enemy_0');
      expect(result[1].id, 'enemy_1');
      expect(result[2].id, 'enemy_2');
      expect(result[3].id, 'enemy_3');
      expect(result[4].id, 'enemy_4');
    });

    test('large deltaTime does not spawn more than total', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 2, delayBetween: 0.5),
        enemyLookup: enemyLookup,
      );
      spawner.start();

      final result = spawner.tick(100.0);
      expect(result, hasLength(2));
    });
  });

  group('WaveSpawner — allSpawned', () {
    test('allSpawned is false until all enemies are created', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 2, delayBetween: 1.0),
        enemyLookup: enemyLookup,
      );
      spawner.start();

      spawner.tick(0.0); // enemy_0
      expect(spawner.allSpawned, isFalse);

      spawner.tick(1.0); // enemy_1
      expect(spawner.allSpawned, isTrue);
    });

    test('tick returns empty list after all spawned', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 1, delayBetween: 1.0),
        enemyLookup: enemyLookup,
      );
      spawner.start();

      spawner.tick(0.0); // enemy_0
      expect(spawner.allSpawned, isTrue);

      final result = spawner.tick(5.0);
      expect(result, isEmpty);
    });
  });

  group('WaveSpawner — markEnemyKilled', () {
    test('markEnemyKilled increases killedCount', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 3, delayBetween: 1.0),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      spawner.tick(0.0); // enemy_0

      expect(spawner.killedCount, 0);
      spawner.markEnemyKilled('enemy_0');
      expect(spawner.killedCount, 1);
    });

    test('markEnemyKilled decreases remainingEnemies', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 3, delayBetween: 1.0),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      spawner.tick(0.0); // enemy_0 spawned, remaining = 1

      expect(spawner.remainingEnemies, 1);
      spawner.markEnemyKilled('enemy_0');
      expect(spawner.remainingEnemies, 0);
    });

    test('remainingEnemies only counts spawned enemies', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 3, delayBetween: 1.0),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      spawner.tick(0.0); // 1 spawned

      // remaining = 1 (spawned) - 0 (killed) = 1
      // even though 2 more enemies haven't spawned yet
      expect(spawner.remainingEnemies, 1);
    });
  });

  group('WaveSpawner — waveComplete', () {
    test('waveComplete is false when not all spawned', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 2, delayBetween: 1.0),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      spawner.tick(0.0); // 1 of 2 spawned
      spawner.markEnemyKilled('enemy_0');
      expect(spawner.waveComplete, isFalse);
    });

    test('waveComplete is false when enemies remain', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 2, delayBetween: 0.5),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      spawner.tick(10.0); // both spawned
      expect(spawner.allSpawned, isTrue);

      spawner.markEnemyKilled('enemy_0');
      expect(spawner.waveComplete, isFalse);
    });

    test('waveComplete is true when all spawned and all killed', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 2, delayBetween: 0.5),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      spawner.tick(10.0); // both spawned

      spawner.markEnemyKilled('enemy_0');
      spawner.markEnemyKilled('enemy_1');
      expect(spawner.waveComplete, isTrue);
    });

    test('state transitions to complete when wave is complete', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 1, delayBetween: 1.0),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      spawner.tick(0.0);
      spawner.markEnemyKilled('enemy_0');
      expect(spawner.state, WaveState.complete);
    });
  });

  group('WaveSpawner — multi-group sequential spawning', () {
    test('groups spawn sequentially', () {
      final spawner = WaveSpawner(
        wave: multiGroupWave(),
        enemyLookup: enemyLookup,
      );
      spawner.start();

      // Group 1: 2 infantry with 1.0s delay
      final g1e0 = spawner.tick(0.0); // first infantry immediately
      expect(g1e0, hasLength(1));
      expect(g1e0[0].definitionId, 'test_infantry');

      // tick(1.0): spawns 2nd infantry (last in group 1), which triggers
      // group 2 to start, so the 1st heavy also spawns immediately.
      final g1e1 = spawner.tick(1.0);
      expect(g1e1, hasLength(2));
      expect(g1e1[0].definitionId, 'test_infantry');
      expect(g1e1[1].definitionId, 'test_heavy');
    });

    test('multi-group: all enemies spawn with sufficient time', () {
      final spawner = WaveSpawner(
        wave: multiGroupWave(),
        enemyLookup: enemyLookup,
      );
      spawner.start();

      // Large delta to spawn everything
      final result = spawner.tick(100.0);

      // 2 infantry + 2 heavy = 4 total
      expect(result, hasLength(4));
      expect(spawner.allSpawned, isTrue);
      expect(spawner.totalEnemies, 4);
    });

    test('multi-group: enemy IDs are globally sequential', () {
      final spawner = WaveSpawner(
        wave: multiGroupWave(),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      final result = spawner.tick(100.0);

      expect(result[0].id, 'enemy_0');
      expect(result[1].id, 'enemy_1');
      expect(result[2].id, 'enemy_2');
      expect(result[3].id, 'enemy_3');
    });

    test('multi-group: first group uses infantry, second uses heavy', () {
      final spawner = WaveSpawner(
        wave: multiGroupWave(),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      final result = spawner.tick(100.0);

      // First 2 are infantry
      expect(result[0].definitionId, 'test_infantry');
      expect(result[1].definitionId, 'test_infantry');
      // Last 2 are heavy
      expect(result[2].definitionId, 'test_heavy');
      expect(result[3].definitionId, 'test_heavy');
    });

    test('multi-group: heavy enemies have correct stats', () {
      final spawner = WaveSpawner(
        wave: multiGroupWave(),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      final result = spawner.tick(100.0);

      final heavy = result[2];
      expect(heavy.currentHp, testHeavy.hp);
      expect(heavy.speed, testHeavy.speed);
      expect(heavy.armor, testHeavy.armor);
    });

    test('multi-group: group 2 first enemy spawns after group 1 finishes', () {
      final spawner = WaveSpawner(
        wave: const Wave(
          number: 1,
          groups: [
            WaveGroup(enemyId: 'test_infantry', count: 2, delayBetween: 1.0),
            WaveGroup(enemyId: 'test_heavy', count: 1, delayBetween: 1.0),
          ],
          bonusReward: 50,
        ),
        enemyLookup: enemyLookup,
      );
      spawner.start();

      // First tick: enemy_0 (infantry) immediately
      final t0 = spawner.tick(0.0);
      expect(t0, hasLength(1));
      expect(t0[0].definitionId, 'test_infantry');

      // Second tick at 1.0s: enemy_1 (infantry, last in group 1)
      // + enemy_2 (heavy, first in group 2, spawns immediately)
      final t1 = spawner.tick(1.0);
      expect(t1, hasLength(2));
      expect(t1[0].definitionId, 'test_infantry');
      expect(t1[1].definitionId, 'test_heavy');

      expect(spawner.allSpawned, isTrue);
    });

    test('multi-group: waveComplete after killing all enemies', () {
      final spawner = WaveSpawner(
        wave: multiGroupWave(),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      final result = spawner.tick(100.0);

      for (final enemy in result) {
        spawner.markEnemyKilled(enemy.id);
      }

      expect(spawner.waveComplete, isTrue);
      expect(spawner.state, WaveState.complete);
    });
  });

  group('WaveSpawner — single enemy wave', () {
    test('single group with single enemy', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 1),
        enemyLookup: enemyLookup,
      );
      spawner.start();

      final result = spawner.tick(0.0);
      expect(result, hasLength(1));
      expect(result[0].id, 'enemy_0');
      expect(spawner.allSpawned, isTrue);
      expect(spawner.totalEnemies, 1);
    });

    test('single enemy: kill to complete wave', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 1),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      spawner.tick(0.0);

      expect(spawner.waveComplete, isFalse);
      spawner.markEnemyKilled('enemy_0');
      expect(spawner.waveComplete, isTrue);
    });
  });

  group('WaveSpawner — three groups', () {
    test('three groups spawn in order', () {
      final wave = const Wave(
        number: 1,
        groups: [
          WaveGroup(enemyId: 'test_infantry', count: 1, delayBetween: 1.0),
          WaveGroup(enemyId: 'test_heavy', count: 1, delayBetween: 1.0),
          WaveGroup(enemyId: 'test_runner', count: 1, delayBetween: 1.0),
        ],
        bonusReward: 100,
      );

      final spawner = WaveSpawner(wave: wave, enemyLookup: enemyLookup);
      spawner.start();

      // With a large tick, all 3 spawn at once (each group has 1 enemy,
      // and each group's first enemy spawns immediately after the previous
      // group finishes).
      final result = spawner.tick(100.0);
      expect(result, hasLength(3));
      expect(result[0].definitionId, 'test_infantry');
      expect(result[1].definitionId, 'test_heavy');
      expect(result[2].definitionId, 'test_runner');
      expect(spawner.allSpawned, isTrue);
      expect(spawner.totalEnemies, 3);
    });
  });

  group('WaveSpawner — edge cases', () {
    test('tick with exactly 0 deltaTime after first spawns nothing', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 3, delayBetween: 1.0),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      spawner.tick(0.0); // first enemy

      // Multiple zero-time ticks should not spawn anything
      expect(spawner.tick(0.0), isEmpty);
      expect(spawner.tick(0.0), isEmpty);
      expect(spawner.tick(0.0), isEmpty);
    });

    test('tick accumulates fractional time correctly', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 3, delayBetween: 1.0),
        enemyLookup: enemyLookup,
      );
      spawner.start();
      spawner.tick(0.0); // enemy_0

      // Accumulate 0.25 * 3 = 0.75 — not enough
      expect(spawner.tick(0.25), isEmpty);
      expect(spawner.tick(0.25), isEmpty);
      expect(spawner.tick(0.25), isEmpty);

      // 0.75 + 0.25 = 1.0 — exactly enough
      final result = spawner.tick(0.25);
      expect(result, hasLength(1));
      expect(result[0].id, 'enemy_1');
    });

    test('large delta spawns correct number with overflow', () {
      // 3 enemies with 0.5s delay: first at 0, second at 0.5, third at 1.0
      // A delta of 1.5 should spawn all three
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 3, delayBetween: 0.5),
        enemyLookup: enemyLookup,
      );
      spawner.start();

      final result = spawner.tick(1.5);
      expect(result, hasLength(3));
    });

    test('remainingEnemies tracks correctly through spawn and kill', () {
      final spawner = WaveSpawner(
        wave: singleGroupWave(count: 3, delayBetween: 0.5),
        enemyLookup: enemyLookup,
      );
      spawner.start();

      spawner.tick(0.0); // 1 spawned
      expect(spawner.remainingEnemies, 1);

      spawner.markEnemyKilled('enemy_0');
      expect(spawner.remainingEnemies, 0);

      spawner.tick(0.5); // 2 spawned total
      expect(spawner.remainingEnemies, 1);

      spawner.tick(0.5); // 3 spawned total
      expect(spawner.remainingEnemies, 2);

      spawner.markEnemyKilled('enemy_1');
      expect(spawner.remainingEnemies, 1);

      spawner.markEnemyKilled('enemy_2');
      expect(spawner.remainingEnemies, 0);
      expect(spawner.waveComplete, isTrue);
    });
  });
}
