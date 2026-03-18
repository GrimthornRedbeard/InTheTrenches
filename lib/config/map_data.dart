// lib/config/map_data.dart — replace path-based maps with zone-based
import 'dart:ui' show Offset;
import '../models/models.dart';

class MapData {
  MapData._();

  static const wwi1 = GameMap(
    id: 'wwi_somme',
    name: 'The Somme',
    eraId: 'wwi',
    waveCount: 10,
    width: 600,
    height: 800,
    spawnZoneY: 60,
    commandPostY: 720,
    trenchSegments: [
      TrenchSegment(index: 0, worldX: 60,  worldY: 400, breachHp: 100),
      TrenchSegment(index: 1, worldX: 180, worldY: 400, breachHp: 100),
      TrenchSegment(index: 2, worldX: 300, worldY: 400, breachHp: 100),
      TrenchSegment(index: 3, worldX: 420, worldY: 400, breachHp: 100),
      TrenchSegment(index: 4, worldX: 540, worldY: 400, breachHp: 100),
    ],
    placements: [
      // No man's land forward positions
      PlacementPosition(id: 'nml_1', x: 120, y: 200, zone: PlacementZone.noMansLand),
      PlacementPosition(id: 'nml_2', x: 300, y: 240, zone: PlacementZone.noMansLand),
      PlacementPosition(id: 'nml_3', x: 480, y: 200, zone: PlacementZone.noMansLand),
      // In-trench
      PlacementPosition(id: 'tr_1', x: 120, y: 400, zone: PlacementZone.trench),
      PlacementPosition(id: 'tr_2', x: 300, y: 400, zone: PlacementZone.trench),
      PlacementPosition(id: 'tr_3', x: 480, y: 400, zone: PlacementZone.trench),
      // Behind trench (ranged)
      PlacementPosition(id: 'bt_1', x: 60,  y: 560, zone: PlacementZone.behindTrench),
      PlacementPosition(id: 'bt_2', x: 180, y: 540, zone: PlacementZone.behindTrench),
      PlacementPosition(id: 'bt_3', x: 300, y: 560, zone: PlacementZone.behindTrench),
      PlacementPosition(id: 'bt_4', x: 420, y: 540, zone: PlacementZone.behindTrench),
      PlacementPosition(id: 'bt_5', x: 540, y: 560, zone: PlacementZone.behindTrench),
    ],
    obstacles: [
      Obstacle(id: 'wire_1', type: ObstacleType.barbedWire, position: Offset(150, 300), radius: 30),
      Obstacle(id: 'wire_2', type: ObstacleType.barbedWire, position: Offset(450, 280), radius: 30),
      Obstacle(id: 'crater_1', type: ObstacleType.shellCrater, position: Offset(300, 200), radius: 25),
      Obstacle(id: 'crater_2', type: ObstacleType.shellCrater, position: Offset(100, 320), radius: 20),
    ],
  );

  static const medieval1 = GameMap(
    id: 'medieval_castle',
    name: 'Castle Approach',
    eraId: 'medieval',
    waveCount: 10,
    width: 600,
    height: 800,
    spawnZoneY: 60,
    commandPostY: 720,
    trenchSegments: [
      TrenchSegment(index: 0, worldX: 75,  worldY: 420, breachHp: 100),
      TrenchSegment(index: 1, worldX: 225, worldY: 400, breachHp: 100),
      TrenchSegment(index: 2, worldX: 375, worldY: 420, breachHp: 100),
      TrenchSegment(index: 3, worldX: 525, worldY: 400, breachHp: 100),
    ],
    placements: [
      PlacementPosition(id: 'nml_1', x: 150, y: 220, zone: PlacementZone.noMansLand),
      PlacementPosition(id: 'nml_2', x: 450, y: 220, zone: PlacementZone.noMansLand),
      PlacementPosition(id: 'tr_1', x: 150, y: 410, zone: PlacementZone.trench),
      PlacementPosition(id: 'tr_2', x: 450, y: 410, zone: PlacementZone.trench),
      PlacementPosition(id: 'bt_1', x: 75,  y: 580, zone: PlacementZone.behindTrench),
      PlacementPosition(id: 'bt_2', x: 225, y: 560, zone: PlacementZone.behindTrench),
      PlacementPosition(id: 'bt_3', x: 375, y: 580, zone: PlacementZone.behindTrench),
      PlacementPosition(id: 'bt_4', x: 525, y: 560, zone: PlacementZone.behindTrench),
    ],
    obstacles: [
      Obstacle(id: 'wall_1', type: ObstacleType.barbedWire, position: Offset(300, 300), radius: 40),
      Obstacle(id: 'crater_1', type: ObstacleType.shellCrater, position: Offset(150, 320), radius: 22),
    ],
  );

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
