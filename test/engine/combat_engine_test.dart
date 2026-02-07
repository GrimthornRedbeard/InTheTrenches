import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/engine/combat_engine.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Test map — straight horizontal path from (0,0) to (100,0)
  // totalPathLength = 100.0
  // positionAtProgress(0.5) = PathPoint(50, 0)
  // ---------------------------------------------------------------------------
  const testMap = GameMap(
    id: 'test_map',
    name: 'Test Map',
    eraId: 'test',
    path: [
      PathPoint(x: 0, y: 0),
      PathPoint(x: 100, y: 0),
    ],
    placements: [],
    waveCount: 1,
  );

  // ---------------------------------------------------------------------------
  // Test tower definition: range=60, damage=25, attackSpeed=1.0 (1 shot/sec)
  // ---------------------------------------------------------------------------
  const testTowerDef = TowerDefinition(
    id: 'tower_rifle',
    name: 'Rifle Tower',
    eraId: 'test',
    tier: 1,
    cost: 50,
    range: 60.0,
    damage: 25.0,
    attackSpeed: 1.0,
    description: 'Basic tower',
    category: TowerCategory.damage,
  );

  // Fast-firing tower: attackSpeed=2.0 (0.5s cooldown)
  const fastTowerDef = TowerDefinition(
    id: 'tower_mg',
    name: 'MG Tower',
    eraId: 'test',
    tier: 1,
    cost: 80,
    range: 50.0,
    damage: 10.0,
    attackSpeed: 2.0,
    description: 'Fast tower',
    category: TowerCategory.damage,
  );

  final towerLookup = <String, TowerDefinition>{
    testTowerDef.id: testTowerDef,
    fastTowerDef.id: fastTowerDef,
  };

  // Enemy rewards lookup
  final enemyRewards = <String, int>{
    'test_infantry': 10,
    'test_heavy': 35,
  };

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  EnemyInstance makeEnemy({
    String id = 'enemy_0',
    String definitionId = 'test_infantry',
    double currentHp = 100.0,
    double speed = 10.0,
    double armor = 0.0,
    double pathProgress = 0.5,
    bool alive = true,
  }) {
    return EnemyInstance(
      id: id,
      definitionId: definitionId,
      currentHp: currentHp,
      speed: speed,
      armor: armor,
      pathProgress: pathProgress,
      alive: alive,
    );
  }

  PlacedTower makeTower({
    String id = 'tower_0',
    String definitionId = 'tower_rifle',
    double x = 50.0,
    double y = 0.0,
  }) {
    return PlacedTower(
      id: id,
      definitionId: definitionId,
      x: x,
      y: y,
      currentTier: 1,
    );
  }

  late CombatEngine engine;

  setUp(() {
    engine = CombatEngine();
  });

  group('CombatEngine — basic targeting and firing', () {
    test('tower targets enemy in range and fires', () {
      // Tower at (50,0), enemy at progress 0.5 => world pos (50,0)
      // distance = 0 which is <= range 60
      final enemies = [makeEnemy(pathProgress: 0.5)];
      final towers = [makeTower()];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.fireEvents, hasLength(1));
      expect(result.fireEvents[0].towerId, 'tower_0');
      expect(result.fireEvents[0].enemyId, 'enemy_0');
      expect(result.fireEvents[0].damage, 25.0);
    });

    test('tower ignores out-of-range enemies', () {
      // Tower at (50,0) with range=60
      // Enemy at progress 0.0 => world pos (0,0), distance = 50
      // Wait, that's in range. Let's put enemy far away.
      // Enemy at progress 0.0 => world pos (0,0), tower at (50,30)
      // distance = sqrt(50^2 + 30^2) = sqrt(2500+900) = sqrt(3400) ~ 58.3
      // Still in range. Let's use a tower far from the path.
      // Tower at (50,70), enemy at progress 0.5 => world pos (50,0)
      // distance = 70 > range 60
      final enemies = [makeEnemy(pathProgress: 0.5)];
      final towers = [makeTower(x: 50.0, y: 70.0)]; // distance 70 > range 60

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.fireEvents, isEmpty);
    });
  });

  group('CombatEngine — cooldown', () {
    test('cooldown prevents firing too fast', () {
      // attackSpeed=1.0 => cooldown = 1.0s
      // Fire on first tick, then cooldown prevents second fire
      final enemies = [makeEnemy(currentHp: 200.0, pathProgress: 0.5)];
      final towers = [makeTower()];

      // First tick: fires
      engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      // Second tick with only 0.5s elapsed: should NOT fire
      final result2 = engine.tick(
        deltaTime: 0.5,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result2.fireEvents, isEmpty);
    });

    test('tower fires again after cooldown expires', () {
      final enemies = [makeEnemy(currentHp: 200.0, pathProgress: 0.5)];
      final towers = [makeTower()];

      // First tick: fires, sets cooldown to 1.0
      engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      // Second tick: 1.0s passes, cooldown expires, fires again
      final result2 = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result2.fireEvents, hasLength(1));
    });

    test('resetCooldowns allows immediate firing', () {
      final enemies = [makeEnemy(currentHp: 200.0, pathProgress: 0.5)];
      final towers = [makeTower()];

      // First tick: fires
      engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      // Reset cooldowns
      engine.resetCooldowns();

      // Next tick with 0 delta should fire since cooldown was cleared
      final result = engine.tick(
        deltaTime: 0.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.fireEvents, hasLength(1));
    });
  });

  group('CombatEngine — armor and damage', () {
    test('damage reduced by armor (max 0)', () {
      // tower damage=25, enemy armor=10 => effective = 15
      final enemies = [
        makeEnemy(currentHp: 100.0, armor: 10.0, pathProgress: 0.5),
      ];
      final towers = [makeTower()];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.fireEvents[0].damage, 15.0);
      expect(result.updatedEnemies[0].currentHp, closeTo(85.0, 1e-10));
    });

    test('armor greater than damage results in 0 effective damage', () {
      // tower damage=25, enemy armor=30 => effective = max(0, 25-30) = 0
      final enemies = [
        makeEnemy(currentHp: 100.0, armor: 30.0, pathProgress: 0.5),
      ];
      final towers = [makeTower()];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.fireEvents[0].damage, 0.0);
      expect(result.updatedEnemies[0].currentHp, closeTo(100.0, 1e-10));
    });
  });

  group('CombatEngine — kills and gold', () {
    test('enemy dies at 0 HP', () {
      // tower damage=25, enemy hp=25, armor=0 => one-shot kill
      final enemies = [
        makeEnemy(currentHp: 25.0, armor: 0.0, pathProgress: 0.5),
      ];
      final towers = [makeTower()];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.updatedEnemies[0].alive, isFalse);
      expect(result.updatedEnemies[0].currentHp, closeTo(0.0, 1e-10));
    });

    test('gold awarded on kill', () {
      // Kill a test_infantry (reward=10)
      final enemies = [
        makeEnemy(
          currentHp: 25.0,
          armor: 0.0,
          pathProgress: 0.5,
          definitionId: 'test_infantry',
        ),
      ];
      final towers = [makeTower()];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.goldAwarded, 10);
    });

    test('no gold awarded when enemy survives', () {
      final enemies = [
        makeEnemy(currentHp: 200.0, armor: 0.0, pathProgress: 0.5),
      ];
      final towers = [makeTower()];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.goldAwarded, 0);
    });

    test('gold awarded for heavy enemy kill', () {
      // Kill a test_heavy (reward=35), damage=25, armor=0, hp=25
      final enemies = [
        makeEnemy(
          currentHp: 25.0,
          armor: 0.0,
          pathProgress: 0.5,
          definitionId: 'test_heavy',
        ),
      ];
      final towers = [makeTower()];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.goldAwarded, 35);
    });
  });

  group('CombatEngine — multiple towers', () {
    test('multiple towers targeting different enemies', () {
      // Tower A at (10, 0), Tower B at (90, 0)
      // Enemy A at progress 0.1 => world pos (10,0), distance to A = 0 (in range)
      //   distance to B = 80 (out of range 60)
      // Enemy B at progress 0.9 => world pos (90,0), distance to B = 0 (in range)
      //   distance to A = 80 (out of range 60)
      final enemies = [
        makeEnemy(id: 'enemy_a', currentHp: 100.0, pathProgress: 0.1),
        makeEnemy(id: 'enemy_b', currentHp: 100.0, pathProgress: 0.9),
      ];
      final towers = [
        makeTower(id: 'tower_a', x: 10.0, y: 0.0),
        makeTower(id: 'tower_b', x: 90.0, y: 0.0),
      ];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.fireEvents, hasLength(2));
      // Tower A should fire at enemy_a (only one in range),
      // tower B at enemy_b (only one in range)
      final eventA =
          result.fireEvents.firstWhere((e) => e.towerId == 'tower_a');
      final eventB =
          result.fireEvents.firstWhere((e) => e.towerId == 'tower_b');
      expect(eventA.enemyId, 'enemy_a');
      expect(eventB.enemyId, 'enemy_b');
    });

    test('two towers can damage the same enemy in one tick', () {
      // Both towers at (50,0), enemy at progress 0.5 => (50,0)
      // Each does 25 damage, starting from 100 hp => 50 hp left
      final enemies = [makeEnemy(currentHp: 100.0, pathProgress: 0.5)];
      final towers = [
        makeTower(id: 'tower_a'),
        makeTower(id: 'tower_b'),
      ];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.fireEvents, hasLength(2));
      expect(result.updatedEnemies[0].currentHp, closeTo(50.0, 1e-10));
    });

    test('second tower sees damage from first tower (mutable list)', () {
      // Enemy has 30 hp. Tower A does 25 damage => 5 hp left.
      // Tower B should see 5 hp, fire, do 25 damage => dead.
      final enemies = [makeEnemy(currentHp: 30.0, pathProgress: 0.5)];
      final towers = [
        makeTower(id: 'tower_a'),
        makeTower(id: 'tower_b'),
      ];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      // Tower A fires (25 damage), then tower B fires (25 damage, but enemy
      // only has 5 hp left after tower A). Enemy dies.
      expect(result.fireEvents, hasLength(2));
      expect(result.updatedEnemies[0].alive, isFalse);
      expect(result.updatedEnemies[0].currentHp, closeTo(0.0, 1e-10));
    });
  });

  group('CombatEngine — target priority: first', () {
    test('"first" priority targets highest pathProgress (closest to base)',
        () {
      // Tower at (50, 0) with range 60
      // Enemy A at progress 0.3 => world pos (30,0), distance = 20 (in range)
      // Enemy B at progress 0.7 => world pos (70,0), distance = 20 (in range)
      // "first" priority should target B (highest pathProgress)
      final enemies = [
        makeEnemy(id: 'enemy_a', currentHp: 100.0, pathProgress: 0.3),
        makeEnemy(id: 'enemy_b', currentHp: 100.0, pathProgress: 0.7),
      ];
      final towers = [makeTower()];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
        priority: TargetPriority.first,
      );

      expect(result.fireEvents, hasLength(1));
      expect(result.fireEvents[0].enemyId, 'enemy_b');
    });
  });

  group('CombatEngine — no targets', () {
    test('tower with 0 enemies in range does not fire', () {
      // Tower at (50, 100) — far from path
      final enemies = [makeEnemy(pathProgress: 0.5)];
      final towers = [makeTower(x: 50.0, y: 100.0)]; // distance = 100 > 60

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.fireEvents, isEmpty);
    });

    test('no fire events with empty enemy list', () {
      final towers = [makeTower()];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: [],
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.fireEvents, isEmpty);
      expect(result.goldAwarded, 0);
    });

    test('no fire events with empty tower list', () {
      final enemies = [makeEnemy(pathProgress: 0.5)];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: [],
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.fireEvents, isEmpty);
    });
  });

  group('CombatEngine — dead enemies are not targeted', () {
    test('tower does not fire at dead enemies', () {
      final enemies = [
        makeEnemy(currentHp: 0.0, pathProgress: 0.5, alive: false),
      ];
      final towers = [makeTower()];

      final result = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );

      expect(result.fireEvents, isEmpty);
    });
  });

  group('CombatEngine — fast tower cooldown', () {
    test('fast tower (attackSpeed=2.0) has 0.5s cooldown', () {
      final enemies = [makeEnemy(currentHp: 200.0, pathProgress: 0.5)];
      final towers = [
        makeTower(id: 'fast_tower', definitionId: 'tower_mg', x: 50.0, y: 0.0),
      ];

      // First tick fires
      final r1 = engine.tick(
        deltaTime: 1.0,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );
      expect(r1.fireEvents, hasLength(1));

      // After 0.3s — too soon
      final r2 = engine.tick(
        deltaTime: 0.3,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );
      expect(r2.fireEvents, isEmpty);

      // After another 0.2s (total 0.5s from last fire) — should fire
      final r3 = engine.tick(
        deltaTime: 0.2,
        towers: towers,
        enemies: enemies,
        map: testMap,
        towerLookup: towerLookup,
        enemyRewards: enemyRewards,
      );
      expect(r3.fireEvents, hasLength(1));
    });
  });
}
