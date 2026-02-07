import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/engine/pathfinding_engine.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Test map — a simple straight horizontal path from (0,0) to (100,0)
  // totalPathLength = 100.0
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
  // Helper to create enemy instances with sensible defaults
  // ---------------------------------------------------------------------------
  EnemyInstance makeEnemy({
    String id = 'enemy_0',
    double speed = 10.0,
    double pathProgress = 0.0,
    double currentHp = 100.0,
    double armor = 0.0,
    bool alive = true,
  }) {
    return EnemyInstance(
      id: id,
      definitionId: 'test_infantry',
      currentHp: currentHp,
      speed: speed,
      armor: armor,
      pathProgress: pathProgress,
      alive: alive,
    );
  }

  late PathfindingEngine engine;

  setUp(() {
    engine = PathfindingEngine();
  });

  group('PathfindingEngine — single enemy movement', () {
    test('single enemy moves forward by correct amount', () {
      // speed=10, deltaTime=1.0, totalPathLength=100
      // progressDelta = (10 * 1.0) / 100 = 0.1
      final enemies = [makeEnemy(speed: 10.0, pathProgress: 0.0)];
      final result = engine.tick(1.0, enemies, testMap);

      expect(result.updatedEnemies, hasLength(1));
      expect(result.updatedEnemies[0].pathProgress, closeTo(0.1, 1e-10));
      expect(result.reachedBase, isEmpty);
    });

    test('enemy moves proportionally to deltaTime', () {
      // speed=20, deltaTime=0.5, totalPathLength=100
      // progressDelta = (20 * 0.5) / 100 = 0.1
      final enemies = [makeEnemy(speed: 20.0, pathProgress: 0.0)];
      final result = engine.tick(0.5, enemies, testMap);

      expect(result.updatedEnemies[0].pathProgress, closeTo(0.1, 1e-10));
    });

    test('enemy at mid-path continues moving forward', () {
      // speed=10, deltaTime=1.0, start at 0.5
      // progressDelta = 0.1 => new progress = 0.6
      final enemies = [makeEnemy(speed: 10.0, pathProgress: 0.5)];
      final result = engine.tick(1.0, enemies, testMap);

      expect(result.updatedEnemies[0].pathProgress, closeTo(0.6, 1e-10));
    });
  });

  group('PathfindingEngine — multiple enemies', () {
    test('multiple enemies at different speeds move correctly', () {
      // enemy A: speed=10, deltaTime=1.0 => +0.1
      // enemy B: speed=20, deltaTime=1.0 => +0.2
      final enemies = [
        makeEnemy(id: 'enemy_a', speed: 10.0, pathProgress: 0.0),
        makeEnemy(id: 'enemy_b', speed: 20.0, pathProgress: 0.0),
      ];
      final result = engine.tick(1.0, enemies, testMap);

      expect(result.updatedEnemies, hasLength(2));

      final a = result.updatedEnemies.firstWhere((e) => e.id == 'enemy_a');
      final b = result.updatedEnemies.firstWhere((e) => e.id == 'enemy_b');

      expect(a.pathProgress, closeTo(0.1, 1e-10));
      expect(b.pathProgress, closeTo(0.2, 1e-10));
    });
  });

  group('PathfindingEngine — reaching base', () {
    test('enemy reaching pathProgress >= 1.0 goes to reachedBase list', () {
      // speed=100, deltaTime=1.0, totalPathLength=100
      // progressDelta = (100 * 1.0) / 100 = 1.0 => 0.0 + 1.0 = 1.0
      final enemies = [makeEnemy(speed: 100.0, pathProgress: 0.0)];
      final result = engine.tick(1.0, enemies, testMap);

      expect(result.reachedBase, hasLength(1));
      expect(result.reachedBase[0].id, 'enemy_0');
      expect(result.reachedBase[0].alive, isFalse);
    });

    test('enemy overshooting pathProgress 1.0 still goes to reachedBase', () {
      // speed=10, deltaTime=1.0, start at 0.95
      // progressDelta = 0.1 => 0.95 + 0.1 = 1.05 >= 1.0
      final enemies = [makeEnemy(speed: 10.0, pathProgress: 0.95)];
      final result = engine.tick(1.0, enemies, testMap);

      expect(result.reachedBase, hasLength(1));
      expect(result.reachedBase[0].alive, isFalse);
    });

    test('enemy in reachedBase is also in updatedEnemies as not alive', () {
      final enemies = [makeEnemy(speed: 100.0, pathProgress: 0.5)];
      final result = engine.tick(1.0, enemies, testMap);

      expect(result.reachedBase, hasLength(1));
      // The updatedEnemies list should contain all enemies, including reached ones
      expect(result.updatedEnemies, hasLength(1));
      expect(result.updatedEnemies[0].alive, isFalse);
    });
  });

  group('PathfindingEngine — zero deltaTime', () {
    test('zero deltaTime means no movement', () {
      final enemies = [makeEnemy(speed: 10.0, pathProgress: 0.3)];
      final result = engine.tick(0.0, enemies, testMap);

      expect(result.updatedEnemies[0].pathProgress, closeTo(0.3, 1e-10));
      expect(result.reachedBase, isEmpty);
    });
  });

  group('PathfindingEngine — dead enemies', () {
    test('dead enemies do not move', () {
      final enemies = [
        makeEnemy(
          id: 'dead_one',
          speed: 10.0,
          pathProgress: 0.3,
          alive: false,
        ),
      ];
      final result = engine.tick(1.0, enemies, testMap);

      expect(result.updatedEnemies, hasLength(1));
      expect(result.updatedEnemies[0].pathProgress, closeTo(0.3, 1e-10));
      expect(result.updatedEnemies[0].alive, isFalse);
      expect(result.reachedBase, isEmpty);
    });

    test('mix of alive and dead enemies — only alive ones move', () {
      final enemies = [
        makeEnemy(id: 'alive_one', speed: 10.0, pathProgress: 0.0, alive: true),
        makeEnemy(
            id: 'dead_one', speed: 10.0, pathProgress: 0.5, alive: false),
      ];
      final result = engine.tick(1.0, enemies, testMap);

      final aliveOne =
          result.updatedEnemies.firstWhere((e) => e.id == 'alive_one');
      final deadOne =
          result.updatedEnemies.firstWhere((e) => e.id == 'dead_one');

      expect(aliveOne.pathProgress, closeTo(0.1, 1e-10));
      expect(deadOne.pathProgress, closeTo(0.5, 1e-10));
    });
  });

  group('PathfindingEngine — empty list', () {
    test('empty enemy list returns empty results', () {
      final result = engine.tick(1.0, [], testMap);

      expect(result.updatedEnemies, isEmpty);
      expect(result.reachedBase, isEmpty);
    });
  });

  group('PathfindingEngine — multi-segment path', () {
    test('enemy moves correctly on a multi-segment path', () {
      // Path: (0,0) -> (50,0) -> (50,50) => totalPathLength = 50 + 50 = 100
      const multiSegmentMap = GameMap(
        id: 'multi_map',
        name: 'Multi Segment',
        eraId: 'test',
        path: [
          PathPoint(x: 0, y: 0),
          PathPoint(x: 50, y: 0),
          PathPoint(x: 50, y: 50),
        ],
        placements: [],
        waveCount: 1,
      );

      // speed=10, deltaTime=1.0, totalPathLength=100
      // progressDelta = 0.1
      final enemies = [makeEnemy(speed: 10.0, pathProgress: 0.0)];
      final result = engine.tick(1.0, enemies, multiSegmentMap);

      expect(result.updatedEnemies[0].pathProgress, closeTo(0.1, 1e-10));
    });
  });
}
