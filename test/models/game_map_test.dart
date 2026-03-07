import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/config/map_data.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  group('PathPoint', () {
    group('distanceTo', () {
      test('horizontal distance', () {
        const a = PathPoint(x: 0, y: 0);
        const b = PathPoint(x: 3, y: 0);
        expect(a.distanceTo(b), 3.0);
      });

      test('vertical distance', () {
        const a = PathPoint(x: 0, y: 0);
        const b = PathPoint(x: 0, y: 4);
        expect(a.distanceTo(b), 4.0);
      });

      test('diagonal distance (3-4-5 triangle)', () {
        const a = PathPoint(x: 0, y: 0);
        const b = PathPoint(x: 3, y: 4);
        expect(a.distanceTo(b), 5.0);
      });

      test('same point returns 0', () {
        const a = PathPoint(x: 5, y: 10);
        expect(a.distanceTo(a), 0.0);
      });
    });

    group('equality', () {
      test('same coordinates are equal', () {
        const a = PathPoint(x: 1, y: 2);
        const b = PathPoint(x: 1, y: 2);
        expect(a, b);
      });

      test('different coordinates are not equal', () {
        const a = PathPoint(x: 1, y: 2);
        const b = PathPoint(x: 3, y: 4);
        expect(a, isNot(b));
      });
    });
  });

  group('PlacementPosition', () {
    group('equality', () {
      test('same values are equal', () {
        const a = PlacementPosition(id: 'p1', x: 10, y: 20);
        const b = PlacementPosition(id: 'p1', x: 10, y: 20);
        expect(a, b);
      });

      test('different id makes not equal', () {
        const a = PlacementPosition(id: 'p1', x: 10, y: 20);
        const b = PlacementPosition(id: 'p2', x: 10, y: 20);
        expect(a, isNot(b));
      });

      test('different coordinates makes not equal', () {
        const a = PlacementPosition(id: 'p1', x: 10, y: 20);
        const b = PlacementPosition(id: 'p1', x: 30, y: 40);
        expect(a, isNot(b));
      });
    });
  });

  group('GameMap', () {
    group('totalPathLength', () {
      test('sum of segment distances for known path', () {
        const map = GameMap(
          id: 'test',
          name: 'Test',
          eraId: 'test',
          path: [
            PathPoint(x: 0, y: 0),
            PathPoint(x: 3, y: 0),
            PathPoint(x: 3, y: 4),
          ],
          placements: [],
          waveCount: 1,
        );
        // 3 + 4 = 7
        expect(map.totalPathLength, 7.0);
      });

      test('single point path has length 0', () {
        const map = GameMap(
          id: 'test',
          name: 'Test',
          eraId: 'test',
          path: [PathPoint(x: 5, y: 5)],
          placements: [],
          waveCount: 1,
        );
        expect(map.totalPathLength, 0.0);
      });

      test('two points returns distance between them', () {
        const map = GameMap(
          id: 'test',
          name: 'Test',
          eraId: 'test',
          path: [PathPoint(x: 0, y: 0), PathPoint(x: 3, y: 4)],
          placements: [],
          waveCount: 1,
        );
        expect(map.totalPathLength, 5.0);
      });
    });

    group('positionAtProgress', () {
      test('progress 0.0 returns first path point', () {
        const map = GameMap(
          id: 'test',
          name: 'Test',
          eraId: 'test',
          path: [
            PathPoint(x: 0, y: 0),
            PathPoint(x: 100, y: 0),
            PathPoint(x: 100, y: 100),
          ],
          placements: [],
          waveCount: 1,
        );
        expect(map.positionAtProgress(0.0), const PathPoint(x: 0, y: 0));
      });

      test('progress 1.0 returns last path point', () {
        const map = GameMap(
          id: 'test',
          name: 'Test',
          eraId: 'test',
          path: [
            PathPoint(x: 0, y: 0),
            PathPoint(x: 100, y: 0),
            PathPoint(x: 100, y: 100),
          ],
          placements: [],
          waveCount: 1,
        );
        expect(map.positionAtProgress(1.0), const PathPoint(x: 100, y: 100));
      });

      test('progress 0.5 returns midpoint for a 2-point path', () {
        const map = GameMap(
          id: 'test',
          name: 'Test',
          eraId: 'test',
          path: [PathPoint(x: 0, y: 0), PathPoint(x: 100, y: 0)],
          placements: [],
          waveCount: 1,
        );
        final mid = map.positionAtProgress(0.5);
        expect(mid.x, closeTo(50, 0.001));
        expect(mid.y, closeTo(0, 0.001));
      });

      test('negative progress is clamped to first point', () {
        const map = GameMap(
          id: 'test',
          name: 'Test',
          eraId: 'test',
          path: [PathPoint(x: 10, y: 20), PathPoint(x: 100, y: 200)],
          placements: [],
          waveCount: 1,
        );
        expect(map.positionAtProgress(-0.5), const PathPoint(x: 10, y: 20));
      });

      test('progress > 1.0 is clamped to last point', () {
        const map = GameMap(
          id: 'test',
          name: 'Test',
          eraId: 'test',
          path: [PathPoint(x: 10, y: 20), PathPoint(x: 100, y: 200)],
          placements: [],
          waveCount: 1,
        );
        expect(map.positionAtProgress(1.5), const PathPoint(x: 100, y: 200));
      });

      test('empty path returns (0, 0)', () {
        const map = GameMap(
          id: 'test',
          name: 'Test',
          eraId: 'test',
          path: [],
          placements: [],
          waveCount: 1,
        );
        expect(map.positionAtProgress(0.5), const PathPoint(x: 0, y: 0));
      });

      test('single point path returns that point', () {
        const map = GameMap(
          id: 'test',
          name: 'Test',
          eraId: 'test',
          path: [PathPoint(x: 42, y: 99)],
          placements: [],
          waveCount: 1,
        );
        expect(map.positionAtProgress(0.5), const PathPoint(x: 42, y: 99));
      });

      test('interpolates correctly on multi-segment path', () {
        // Path: (0,0) -> (100,0) -> (100,100), total length = 200
        // Progress 0.25 = 50 units along first segment
        const map = GameMap(
          id: 'test',
          name: 'Test',
          eraId: 'test',
          path: [
            PathPoint(x: 0, y: 0),
            PathPoint(x: 100, y: 0),
            PathPoint(x: 100, y: 100),
          ],
          placements: [],
          waveCount: 1,
        );
        final pos = map.positionAtProgress(0.25);
        expect(pos.x, closeTo(50, 0.001));
        expect(pos.y, closeTo(0, 0.001));
      });

      test('interpolates into second segment correctly', () {
        // Path: (0,0) -> (100,0) -> (100,100), total length = 200
        // Progress 0.75 = 150 units = 100 on first + 50 on second
        const map = GameMap(
          id: 'test',
          name: 'Test',
          eraId: 'test',
          path: [
            PathPoint(x: 0, y: 0),
            PathPoint(x: 100, y: 0),
            PathPoint(x: 100, y: 100),
          ],
          placements: [],
          waveCount: 1,
        );
        final pos = map.positionAtProgress(0.75);
        expect(pos.x, closeTo(100, 0.001));
        expect(pos.y, closeTo(50, 0.001));
      });
    });
  });

  group('MapData', () {
    test('allMaps has 2 entries', () {
      expect(MapData.allMaps.length, 2);
    });

    test('getMap returns wwi_somme', () {
      final map = MapData.getMap('wwi_somme');
      expect(map, isNotNull);
      expect(map!.id, 'wwi_somme');
      expect(map.name, 'The Somme');
      expect(map.eraId, 'wwi');
    });

    test('getMap returns medieval_castle', () {
      final map = MapData.getMap('medieval_castle');
      expect(map, isNotNull);
      expect(map!.id, 'medieval_castle');
      expect(map.name, 'Castle Approach');
      expect(map.eraId, 'medieval');
    });

    test('getMap returns null for nonexistent', () {
      expect(MapData.getMap('nonexistent'), isNull);
    });

    test('getMapsForEra wwi returns 1 map', () {
      final maps = MapData.getMapsForEra('wwi');
      expect(maps.length, 1);
      expect(maps.first.eraId, 'wwi');
    });

    test('getMapsForEra medieval returns 1 map', () {
      final maps = MapData.getMapsForEra('medieval');
      expect(maps.length, 1);
      expect(maps.first.eraId, 'medieval');
    });

    test('getMapsForEra future returns empty list', () {
      expect(MapData.getMapsForEra('future'), isEmpty);
    });

    test('each map has unique ID', () {
      final ids = MapData.allMaps.map((m) => m.id).toSet();
      expect(ids.length, MapData.allMaps.length);
    });

    test('each map has at least 2 path points', () {
      for (final map in MapData.allMaps) {
        expect(
          map.path.length,
          greaterThanOrEqualTo(2),
          reason: '${map.id} should have at least 2 path points',
        );
      }
    });

    test('each map has at least 4 placement positions', () {
      for (final map in MapData.allMaps) {
        expect(
          map.placements.length,
          greaterThanOrEqualTo(4),
          reason: '${map.id} should have at least 4 placement positions',
        );
      }
    });

    test('each placement position has a unique ID within its map', () {
      for (final map in MapData.allMaps) {
        final ids = map.placements.map((p) => p.id).toSet();
        expect(
          ids.length,
          map.placements.length,
          reason: '${map.id} should have unique placement IDs',
        );
      }
    });
  });
}
