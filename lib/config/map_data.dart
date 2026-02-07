import '../models/game_map.dart';

/// Predefined maps for each era.
class MapData {
  MapData._();

  /// WWI Map 1: The Somme — zigzag trench approach
  static const wwi1 = GameMap(
    id: 'wwi_somme',
    name: 'The Somme',
    eraId: 'wwi',
    waveCount: 10,
    path: [
      PathPoint(x: 0, y: 300),
      PathPoint(x: 200, y: 300),
      PathPoint(x: 200, y: 100),
      PathPoint(x: 400, y: 100),
      PathPoint(x: 400, y: 300),
      PathPoint(x: 600, y: 300),
    ],
    placements: [
      PlacementPosition(id: 'p1', x: 100, y: 200),
      PlacementPosition(id: 'p2', x: 300, y: 200),
      PlacementPosition(id: 'p3', x: 300, y: 50),
      PlacementPosition(id: 'p4', x: 500, y: 200),
      PlacementPosition(id: 'p5', x: 150, y: 400),
      PlacementPosition(id: 'p6', x: 450, y: 400),
    ],
  );

  /// Medieval Map 1: Castle Approach — winding path to the castle
  static const medieval1 = GameMap(
    id: 'medieval_castle',
    name: 'Castle Approach',
    eraId: 'medieval',
    waveCount: 10,
    path: [
      PathPoint(x: 0, y: 200),
      PathPoint(x: 150, y: 200),
      PathPoint(x: 150, y: 400),
      PathPoint(x: 350, y: 400),
      PathPoint(x: 350, y: 200),
      PathPoint(x: 500, y: 200),
      PathPoint(x: 500, y: 50),
      PathPoint(x: 600, y: 50),
    ],
    placements: [
      PlacementPosition(id: 'p1', x: 75, y: 100),
      PlacementPosition(id: 'p2', x: 250, y: 300),
      PlacementPosition(id: 'p3', x: 250, y: 500),
      PlacementPosition(id: 'p4', x: 425, y: 300),
      PlacementPosition(id: 'p5', x: 550, y: 150),
      PlacementPosition(id: 'p6', x: 100, y: 300),
      PlacementPosition(id: 'p7', x: 425, y: 100),
      PlacementPosition(id: 'p8', x: 550, y: 50),
    ],
  );

  /// All available maps.
  static const List<GameMap> allMaps = [wwi1, medieval1];

  /// Look up map by ID.
  static GameMap? getMap(String id) {
    for (final map in allMaps) {
      if (map.id == id) return map;
    }
    return null;
  }

  /// Get maps for a specific era.
  static List<GameMap> getMapsForEra(String eraId) {
    return allMaps.where((m) => m.eraId == eraId).toList();
  }
}
