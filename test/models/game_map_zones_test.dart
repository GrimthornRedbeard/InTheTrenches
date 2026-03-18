import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  // 600x800 map: spawn zone top, trench at y=300, command post at bottom
  const testMap = GameMap(
    id: 'test',
    name: 'Test',
    eraId: 'test',
    waveCount: 5,
    width: 600,
    height: 800,
    spawnZoneY: 50,
    trenchSegments: [
      TrenchSegment(index: 0, worldX: 60,  worldY: 300, breachHp: 100),
      TrenchSegment(index: 1, worldX: 180, worldY: 300, breachHp: 100),
      TrenchSegment(index: 2, worldX: 300, worldY: 300, breachHp: 100),
      TrenchSegment(index: 3, worldX: 420, worldY: 300, breachHp: 100),
      TrenchSegment(index: 4, worldX: 540, worldY: 300, breachHp: 100),
    ],
    commandPostY: 700,
    placements: [],
    obstacles: [],
  );

  group('GameMap zones', () {
    test('spawnY is above trench', () {
      expect(testMap.spawnZoneY, lessThan(testMap.trenchSegments.first.worldY));
    });

    test('segmentCount returns correct count', () {
      expect(testMap.segmentCount, 5);
    });

    test('averageTrenchY is mean of segment worldY values', () {
      expect(testMap.averageTrenchY, 300);
    });

    test('segmentWidth is map width / segment count', () {
      expect(testMap.segmentWidth, 120); // 600 / 5
    });

    test('weakestSegmentIndex returns index with lowest breachHp', () {
      final damaged = testMap.copyWith(trenchSegments: [
        ...testMap.trenchSegments.take(2),
        testMap.trenchSegments[2].copyWith(breachHp: 30), // weakest
        ...testMap.trenchSegments.skip(3),
      ]);
      expect(damaged.weakestSegmentIndex, 2);
    });
  });
}
