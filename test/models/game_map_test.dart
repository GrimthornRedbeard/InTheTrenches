import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/config/map_data.dart';
import 'package:trench_defense/models/models.dart';

void main() {
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
    const testMap = GameMap(
      id: 'test',
      name: 'Test',
      eraId: 'test',
      waveCount: 1,
      width: 600,
      height: 800,
      spawnZoneY: 50,
      commandPostY: 750,
      trenchSegments: [
        TrenchSegment(index: 0, worldX: 100, worldY: 400, breachHp: 100),
        TrenchSegment(index: 1, worldX: 300, worldY: 400, breachHp: 100),
        TrenchSegment(index: 2, worldX: 500, worldY: 400, breachHp: 100),
      ],
      placements: [],
      obstacles: [],
    );

    test('segmentCount is correct', () {
      expect(testMap.segmentCount, 3);
    });

    test('segmentWidth is width / segmentCount', () {
      expect(testMap.segmentWidth, 200.0); // 600 / 3
    });

    test('averageTrenchY is correct', () {
      expect(testMap.averageTrenchY, 400.0);
    });

    test('weakestSegmentIndex returns lowest breachHp index', () {
      final damaged = testMap.copyWith(trenchSegments: [
        testMap.trenchSegments[0],
        testMap.trenchSegments[1].copyWith(breachHp: 10),
        testMap.trenchSegments[2],
      ]);
      expect(damaged.weakestSegmentIndex, 1);
    });

    test('spawnX scales fraction across width', () {
      expect(testMap.spawnX(0.5), 300.0);
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

    test('each map has at least 4 trench segments', () {
      for (final map in MapData.allMaps) {
        expect(
          map.trenchSegments.length,
          greaterThanOrEqualTo(4),
          reason: '${map.id} should have at least 4 trench segments',
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
