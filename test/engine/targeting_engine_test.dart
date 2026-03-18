import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/engine/targeting_engine.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared test fixtures
  // Straight horizontal path: (0,0) → (100,0)
  // Enemy positions are set directly as 2D Offsets (matching old progress math:
  //   pathProgress p => position (100*p, 0)).
  // ---------------------------------------------------------------------------

  const testMap = GameMap(
    id: 'test_map',
    name: 'Test Map',
    eraId: 'test',
    waveCount: 1,
    width: 100,
    height: 100,
    spawnZoneY: 0,
    commandPostY: 100,
    trenchSegments: [],
    placements: [],
    obstacles: [],
  );

  /// Helper: create an enemy at a world position equivalent to the old
  /// pathProgress value on a 0→100 horizontal path (x = progress * 100, y = 0).
  EnemyInstance makeEnemy({
    required String id,
    required double pathProgress,
    double currentHp = 100.0,
    double speed = 10.0,
    double armor = 0.0,
    bool alive = true,
  }) {
    return EnemyInstance(
      id: id,
      definitionId: 'test_infantry',
      currentHp: currentHp,
      speed: speed,
      armor: armor,
      alive: alive,
      position: Offset(pathProgress * 100, 0),
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

  // ---------------------------------------------------------------------------
  // selectTarget — TargetingMode.nearest
  // ---------------------------------------------------------------------------

  group('TargetingEngine — nearest targeting', () {
    test('nearest selects closest enemy to tower', () {
      // Tower at (50, 0)
      // Enemy A at progress 0.2 => world (20, 0) — distance = 30
      // Enemy B at progress 0.7 => world (70, 0) — distance = 20
      // Nearest = B
      final tower = makeTower(x: 50.0, y: 0.0);
      final enemies = [
        makeEnemy(id: 'a', pathProgress: 0.2),
        makeEnemy(id: 'b', pathProgress: 0.7),
      ];

      final target = TargetingEngine.selectTarget(
        mode: TargetingMode.nearest,
        tower: tower,
        enemies: enemies,
        map: testMap,
      );

      expect(target, isNotNull);
      expect(target!.id, 'b');
    });

    test('nearest ignores dead enemies', () {
      final tower = makeTower(x: 50.0, y: 0.0);
      final enemies = [
        makeEnemy(id: 'dead', pathProgress: 0.5, alive: false),
        makeEnemy(id: 'alive', pathProgress: 0.2),
      ];

      final target = TargetingEngine.selectTarget(
        mode: TargetingMode.nearest,
        tower: tower,
        enemies: enemies,
        map: testMap,
      );

      expect(target!.id, 'alive');
    });

    test('nearest returns null when no alive enemies', () {
      final tower = makeTower();
      final enemies = [makeEnemy(id: 'dead', pathProgress: 0.5, alive: false)];

      final target = TargetingEngine.selectTarget(
        mode: TargetingMode.nearest,
        tower: tower,
        enemies: enemies,
        map: testMap,
      );

      expect(target, isNull);
    });

    test('nearest returns null for empty list', () {
      final tower = makeTower();
      final target = TargetingEngine.selectTarget(
        mode: TargetingMode.nearest,
        tower: tower,
        enemies: [],
        map: testMap,
      );
      expect(target, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // selectTarget — TargetingMode.first
  // ---------------------------------------------------------------------------

  group('TargetingEngine — first targeting', () {
    test('first selects enemy furthest along path', () {
      // Enemy A at 0.3 (30% along), Enemy B at 0.8 (80% along)
      // "First" = furthest along = B
      final tower = makeTower();
      final enemies = [
        makeEnemy(id: 'a', pathProgress: 0.3),
        makeEnemy(id: 'b', pathProgress: 0.8),
      ];

      final target = TargetingEngine.selectTarget(
        mode: TargetingMode.first,
        tower: tower,
        enemies: enemies,
        map: testMap,
      );

      expect(target!.id, 'b');
    });

    test('first ignores dead enemies', () {
      final tower = makeTower();
      final enemies = [
        makeEnemy(id: 'dead', pathProgress: 0.9, alive: false),
        makeEnemy(id: 'alive', pathProgress: 0.4),
      ];

      final target = TargetingEngine.selectTarget(
        mode: TargetingMode.first,
        tower: tower,
        enemies: enemies,
        map: testMap,
      );

      expect(target!.id, 'alive');
    });

    test('first returns null for empty list', () {
      final target = TargetingEngine.selectTarget(
        mode: TargetingMode.first,
        tower: makeTower(),
        enemies: [],
        map: testMap,
      );
      expect(target, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // selectTarget — TargetingMode.strongest
  // ---------------------------------------------------------------------------

  group('TargetingEngine — strongest targeting', () {
    test('strongest selects enemy with highest current HP', () {
      final tower = makeTower();
      final enemies = [
        makeEnemy(id: 'weak', pathProgress: 0.5, currentHp: 30.0),
        makeEnemy(id: 'strong', pathProgress: 0.3, currentHp: 200.0),
        makeEnemy(id: 'medium', pathProgress: 0.7, currentHp: 100.0),
      ];

      final target = TargetingEngine.selectTarget(
        mode: TargetingMode.strongest,
        tower: tower,
        enemies: enemies,
        map: testMap,
      );

      expect(target!.id, 'strong');
    });

    test('strongest ignores dead enemies', () {
      final tower = makeTower();
      final enemies = [
        makeEnemy(
          id: 'dead',
          pathProgress: 0.5,
          currentHp: 999.0,
          alive: false,
        ),
        makeEnemy(id: 'alive', pathProgress: 0.3, currentHp: 50.0),
      ];

      final target = TargetingEngine.selectTarget(
        mode: TargetingMode.strongest,
        tower: tower,
        enemies: enemies,
        map: testMap,
      );

      expect(target!.id, 'alive');
    });
  });

  // ---------------------------------------------------------------------------
  // Fire rate timer
  // ---------------------------------------------------------------------------

  group('TargetingEngine — fire rate timer', () {
    test('canFire returns true when timeSinceLastShot >= 1/fireRate', () {
      // fireRate = 2.0 => fires every 0.5s
      expect(
        TargetingEngine.canFire(timeSinceLastShot: 0.5, fireRate: 2.0),
        isTrue,
      );
      expect(
        TargetingEngine.canFire(timeSinceLastShot: 0.6, fireRate: 2.0),
        isTrue,
      );
    });

    test('canFire returns false when timeSinceLastShot < 1/fireRate', () {
      // fireRate = 2.0 => interval = 0.5s
      expect(
        TargetingEngine.canFire(timeSinceLastShot: 0.4, fireRate: 2.0),
        isFalse,
      );
      expect(
        TargetingEngine.canFire(timeSinceLastShot: 0.0, fireRate: 2.0),
        isFalse,
      );
    });

    test('fire rate timer fires at correct intervals (1 shot/sec)', () {
      // fireRate = 1.0 => fires every 1.0s
      expect(
        TargetingEngine.canFire(timeSinceLastShot: 0.99, fireRate: 1.0),
        isFalse,
      );
      expect(
        TargetingEngine.canFire(timeSinceLastShot: 1.0, fireRate: 1.0),
        isTrue,
      );
    });

    test('nextTimeSinceLastShot resets correctly after firing', () {
      // When fire occurs, timeSinceLastShot should reset (subtract interval)
      const fireRate = 2.0;
      const timeSinceLastShot = 0.7; // more than 0.5s interval
      final next = TargetingEngine.nextTimeSinceLastShot(
        timeSinceLastShot: timeSinceLastShot,
        fireRate: fireRate,
        fired: true,
        deltaTime: 0.0,
      );
      // Subtract the interval (0.5) from 0.7 => 0.2 remainder
      expect(next, closeTo(0.2, 1e-10));
    });

    test('nextTimeSinceLastShot accumulates when not firing', () {
      const fireRate = 1.0;
      const timeSinceLastShot = 0.3;
      const deltaTime = 0.2;
      final next = TargetingEngine.nextTimeSinceLastShot(
        timeSinceLastShot: timeSinceLastShot,
        fireRate: fireRate,
        fired: false,
        deltaTime: deltaTime,
      );
      expect(next, closeTo(0.5, 1e-10));
    });
  });

  // ---------------------------------------------------------------------------
  // enemiesInRange helper
  // ---------------------------------------------------------------------------

  group('TargetingEngine — enemiesInRange', () {
    test('returns only alive enemies within range', () {
      // Tower at (50, 0), range = 30
      // A at progress 0.5 => (50, 0), distance = 0 (in range)
      // B at progress 0.1 => (10, 0), distance = 40 (out of range)
      // C at progress 0.5 but dead (out)
      final tower = makeTower(x: 50.0, y: 0.0);
      final enemies = [
        makeEnemy(id: 'a', pathProgress: 0.5),
        makeEnemy(id: 'b', pathProgress: 0.1),
        makeEnemy(id: 'c', pathProgress: 0.5, alive: false),
      ];

      final inRange = TargetingEngine.enemiesInRange(
        tower: tower,
        towerRange: 30.0,
        enemies: enemies,
        map: testMap,
      );

      expect(inRange.map((e) => e.id).toList(), containsAll(['a']));
      expect(inRange.map((e) => e.id), isNot(contains('b')));
      expect(inRange.map((e) => e.id), isNot(contains('c')));
    });

    test('returns empty list when no enemies in range', () {
      final tower = makeTower(x: 50.0, y: 50.0);
      final enemies = [makeEnemy(id: 'far', pathProgress: 0.5)];
      // Distance from (50,50) to (50,0) = 50 > range 30

      final inRange = TargetingEngine.enemiesInRange(
        tower: tower,
        towerRange: 30.0,
        enemies: enemies,
        map: testMap,
      );
      expect(inRange, isEmpty);
    });
  });
}
