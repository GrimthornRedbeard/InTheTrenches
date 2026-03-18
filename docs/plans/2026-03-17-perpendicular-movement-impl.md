# Perpendicular Movement Refactor — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace 1D path-following with free 2D steering across no man's land, a segmented dynamic trench line with breach/push-back, and three defender placement zones.

**Architecture:** Enemies get `position`/`velocity`/`state` instead of `pathProgress`. A new `SteeringEngine` replaces `PathfindingEngine`. `GameMap` gains zone boundaries, trench segments, and obstacle data. Two new engines (`BreachEngine`, `TrenchEngine`) handle the in-trench combat and segment collapse. `CombatEngine` gains a melee phase. `GameMapWidget` renderer is rewritten for the new layout.

**Tech Stack:** Flutter/Dart, Riverpod (state), CustomPainter (rendering). No new packages needed.

**Design doc:** `docs/plans/2026-03-17-perpendicular-movement-refactor.md`

**Test runner:** `/home/grimmy/flutter/bin/flutter test`

---

## Task 1: TrenchSegment model

**Files:**
- Create: `lib/models/trench_segment.dart`
- Create: `test/models/trench_segment_test.dart`

**Step 1: Write the failing test**

```dart
// test/models/trench_segment_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/models/trench_segment.dart';

void main() {
  group('TrenchSegment', () {
    test('starts as held with full breach HP', () {
      final seg = TrenchSegment(
        index: 0,
        worldX: 100,
        worldY: 300,
        breachHp: 100,
      );
      expect(seg.state, TrenchSegmentState.held);
      expect(seg.breachHp, 100);
    });

    test('copyWith updates fields', () {
      final seg = TrenchSegment(index: 0, worldX: 100, worldY: 300, breachHp: 100);
      final updated = seg.copyWith(breachHp: 50, state: TrenchSegmentState.contested);
      expect(updated.breachHp, 50);
      expect(updated.state, TrenchSegmentState.contested);
      expect(updated.worldX, 100); // unchanged
    });

    test('isBreached true when state is breached or collapsed', () {
      final breached = TrenchSegment(index: 0, worldX: 0, worldY: 0, breachHp: 0,
          state: TrenchSegmentState.breached);
      final collapsed = TrenchSegment(index: 0, worldX: 0, worldY: 0, breachHp: 0,
          state: TrenchSegmentState.collapsed);
      final held = TrenchSegment(index: 0, worldX: 0, worldY: 0, breachHp: 100);
      expect(breached.isBreached, true);
      expect(collapsed.isBreached, true);
      expect(held.isBreached, false);
    });
  });
}
```

**Step 2: Run to confirm failure**

```bash
/home/grimmy/flutter/bin/flutter test test/models/trench_segment_test.dart
```
Expected: compilation error — `trench_segment.dart` doesn't exist.

**Step 3: Implement**

```dart
// lib/models/trench_segment.dart
import 'package:equatable/equatable.dart';

enum TrenchSegmentState { held, contested, breached, collapsed }

class TrenchSegment extends Equatable {
  final int index;
  final double worldX;
  final double worldY;
  final double breachHp;
  final TrenchSegmentState state;

  const TrenchSegment({
    required this.index,
    required this.worldX,
    required this.worldY,
    required this.breachHp,
    this.state = TrenchSegmentState.held,
  });

  bool get isBreached =>
      state == TrenchSegmentState.breached ||
      state == TrenchSegmentState.collapsed;

  TrenchSegment copyWith({
    int? index,
    double? worldX,
    double? worldY,
    double? breachHp,
    TrenchSegmentState? state,
  }) => TrenchSegment(
        index: index ?? this.index,
        worldX: worldX ?? this.worldX,
        worldY: worldY ?? this.worldY,
        breachHp: breachHp ?? this.breachHp,
        state: state ?? this.state,
      );

  @override
  List<Object?> get props => [index, worldX, worldY, breachHp, state];
}
```

**Step 4: Run to confirm pass**

```bash
/home/grimmy/flutter/bin/flutter test test/models/trench_segment_test.dart
```
Expected: All tests pass.

**Step 5: Export from models barrel**

Add to `lib/models/models.dart`:
```dart
export 'trench_segment.dart';
```

**Step 6: Commit**

```bash
git add lib/models/trench_segment.dart test/models/trench_segment_test.dart lib/models/models.dart
git commit -m "feat: add TrenchSegment model with state machine"
```

---

## Task 2: EnemyState enum + update EnemyInstance

**Files:**
- Create: `lib/models/enemy_state.dart`
- Modify: `lib/models/enemy_instance.dart`
- Modify: `test/engine/pathfinding_engine_test.dart` (update helper to compile)

**Step 1: Write failing tests for new EnemyInstance fields**

```dart
// test/models/enemy_instance_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  group('EnemyInstance (new fields)', () {
    test('fromDefinition sets position to Offset.zero and state to advancing', () {
      final def = EnemyDefinition(
        id: 'test', name: 'Test', hp: 50, speed: 8,
        armor: 0, reward: 10, abilities: [],
      );
      final inst = EnemyInstance.fromDefinition(id: 'e0', definition: def);
      expect(inst.position, const Offset(0, 0));
      expect(inst.velocity, const Offset(0, 0));
      expect(inst.movementState, EnemyMovementState.advancing);
      expect(inst.targetSegmentIndex, 0);
    });

    test('copyWith updates position without touching other fields', () {
      final def = EnemyDefinition(
        id: 'test', name: 'T', hp: 50, speed: 8,
        armor: 0, reward: 10, abilities: [],
      );
      final inst = EnemyInstance.fromDefinition(id: 'e0', definition: def);
      final moved = inst.copyWith(position: const Offset(100, 200));
      expect(moved.position, const Offset(100, 200));
      expect(moved.speed, 8);
    });
  });
}
```

**Step 2: Run to confirm failure**

```bash
/home/grimmy/flutter/bin/flutter test test/models/enemy_instance_test.dart
```

**Step 3: Create EnemyState enum**

```dart
// lib/models/enemy_state.dart
enum EnemyMovementState {
  advancing,   // moving across no man's land toward trench
  breaching,   // at trench wall, draining breach HP
  inTrench,    // inside trench, only melee defenders can engage
  crossed,     // past trench, heading for command post
}
```

**Step 4: Update EnemyInstance**

Replace `pathProgress: double` with new fields. Keep `alive` unchanged.

```dart
// lib/models/enemy_instance.dart
import 'dart:ui' show Offset;
import 'package:equatable/equatable.dart';
import 'enemy.dart';
import 'enemy_state.dart';

class EnemyInstance extends Equatable {
  final String id;
  final String definitionId;
  final double currentHp;
  final double speed;
  final double armor;
  final bool alive;

  // New 2D movement fields (replaces pathProgress)
  final Offset position;
  final Offset velocity;
  final EnemyMovementState movementState;
  final int targetSegmentIndex;

  const EnemyInstance({
    required this.id,
    required this.definitionId,
    required this.currentHp,
    required this.speed,
    required this.armor,
    required this.alive,
    this.position = Offset.zero,
    this.velocity = Offset.zero,
    this.movementState = EnemyMovementState.advancing,
    this.targetSegmentIndex = 0,
  });

  factory EnemyInstance.fromDefinition({
    required String id,
    required EnemyDefinition definition,
    Offset spawnPosition = Offset.zero,
    int targetSegment = 0,
  }) => EnemyInstance(
        id: id,
        definitionId: definition.id,
        currentHp: definition.hp,
        speed: definition.speed,
        armor: definition.armor,
        alive: true,
        position: spawnPosition,
        targetSegmentIndex: targetSegment,
      );

  EnemyInstance copyWith({
    String? id,
    String? definitionId,
    double? currentHp,
    double? speed,
    double? armor,
    bool? alive,
    Offset? position,
    Offset? velocity,
    EnemyMovementState? movementState,
    int? targetSegmentIndex,
  }) => EnemyInstance(
        id: id ?? this.id,
        definitionId: definitionId ?? this.definitionId,
        currentHp: currentHp ?? this.currentHp,
        speed: speed ?? this.speed,
        armor: armor ?? this.armor,
        alive: alive ?? this.alive,
        position: position ?? this.position,
        velocity: velocity ?? this.velocity,
        movementState: movementState ?? this.movementState,
        targetSegmentIndex: targetSegmentIndex ?? this.targetSegmentIndex,
      );

  @override
  List<Object?> get props => [
        id, definitionId, currentHp, speed, armor, alive,
        position, velocity, movementState, targetSegmentIndex,
      ];
}
```

**Step 5: Export new file and fix broken imports**

Add to `lib/models/models.dart`:
```dart
export 'enemy_state.dart';
```

The old `pathfinding_engine.dart` and its tests reference `pathProgress` — they will break. That's expected; we replace `PathfindingEngine` in Task 3. For now, update `test/engine/pathfinding_engine_test.dart` to skip its tests by renaming the file temporarily or commenting the group with `// TODO: replaced by steering_engine`.

Actually: just delete `lib/engine/pathfinding_engine.dart` and `test/engine/pathfinding_engine_test.dart` — we replace them entirely in Task 3.

```bash
rm lib/engine/pathfinding_engine.dart
rm test/engine/pathfinding_engine_test.dart
```

**Step 6: Fix compile errors from removed pathProgress**

Search for remaining `pathProgress` references:
```bash
grep -r "pathProgress" lib/ test/ --include="*.dart" -l
```

For each file, update to use `position` instead. Primary locations:
- `lib/providers/game_providers.dart`: remove `pathfindingEngine`, update enemy spawn call
- `lib/engine/targeting_engine.dart`: uses `map.positionAtProgress(enemy.pathProgress)` → replace with `enemy.position`
- `lib/engine/wave_spawner.dart`: `EnemyInstance.fromDefinition` call — add `spawnPosition`
- `lib/ui/widgets/game_map_widget.dart`: rendering uses `positionAtProgress` — will be fully replaced in Task 7

Update `targeting_engine.dart` now (simple change):
```dart
// In lib/engine/targeting_engine.dart
// OLD:
// final pos = map.positionAtProgress(enemy.pathProgress);
// NEW:
final pos = enemy.position; // already in world coordinates
// Change type from PathPoint to Offset:
final dx = tower.x - pos.dx;
final dy = tower.y - pos.dy;
```

**Step 7: Run full test suite**

```bash
/home/grimmy/flutter/bin/flutter test
```
Expected: all remaining tests pass (pathfinding tests deleted, others unaffected).

**Step 8: Commit**

```bash
git add lib/models/enemy_state.dart lib/models/enemy_instance.dart lib/models/models.dart
git add lib/engine/targeting_engine.dart lib/providers/game_providers.dart
git rm lib/engine/pathfinding_engine.dart test/engine/pathfinding_engine_test.dart
git commit -m "feat: replace pathProgress with 2D position/velocity/state on EnemyInstance"
```

---

## Task 3: GameMap refactor — zones, segments, obstacles

**Files:**
- Modify: `lib/models/game_map.dart`
- Create: `lib/models/obstacle.dart`
- Modify: `lib/config/map_data.dart`
- Create: `test/models/game_map_zones_test.dart`

**Step 1: Write failing tests**

```dart
// test/models/game_map_zones_test.dart
import 'package:flutter/painting.dart';
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
```

**Step 2: Run to confirm failure**

```bash
/home/grimmy/flutter/bin/flutter test test/models/game_map_zones_test.dart
```

**Step 3: Create Obstacle model**

```dart
// lib/models/obstacle.dart
import 'dart:ui' show Offset;
import 'package:equatable/equatable.dart';

enum ObstacleType { barbedWire, shellCrater }

class Obstacle extends Equatable {
  final String id;
  final ObstacleType type;
  final Offset position;
  final double radius; // repulsion/collision radius

  const Obstacle({
    required this.id,
    required this.type,
    required this.position,
    required this.radius,
  });

  @override
  List<Object?> get props => [id, type, position, radius];
}
```

**Step 4: Replace GameMap with zone-based version**

```dart
// lib/models/game_map.dart
import 'dart:ui' show Offset;
import 'package:equatable/equatable.dart';
import 'obstacle.dart';
import 'placed_tower.dart';
import 'trench_segment.dart';

class PlacementPosition extends Equatable {
  final String id;
  final double x;
  final double y;
  final PlacementZone zone;

  const PlacementPosition({
    required this.id,
    required this.x,
    required this.y,
    required this.zone,
  });

  @override
  List<Object?> get props => [id, x, y, zone];
}

enum PlacementZone { noMansLand, trench, behindTrench }

class GameMap extends Equatable {
  final String id;
  final String name;
  final String eraId;
  final int waveCount;
  final double width;
  final double height;

  // Vertical zone boundaries
  final double spawnZoneY;        // enemies spawn at this Y (top)
  final List<TrenchSegment> trenchSegments;
  final double commandPostY;      // lose if enemy reaches this Y (bottom)

  // Placement slots and obstacles
  final List<PlacementPosition> placements;
  final List<Obstacle> obstacles;

  const GameMap({
    required this.id,
    required this.name,
    required this.eraId,
    required this.waveCount,
    required this.width,
    required this.height,
    required this.spawnZoneY,
    required this.trenchSegments,
    required this.commandPostY,
    required this.placements,
    required this.obstacles,
  });

  int get segmentCount => trenchSegments.length;

  double get segmentWidth => width / segmentCount;

  double get averageTrenchY {
    if (trenchSegments.isEmpty) return height / 2;
    return trenchSegments.map((s) => s.worldY).reduce((a, b) => a + b) /
        segmentCount;
  }

  int get weakestSegmentIndex {
    int idx = 0;
    double min = double.infinity;
    for (int i = 0; i < trenchSegments.length; i++) {
      if (trenchSegments[i].breachHp < min) {
        min = trenchSegments[i].breachHp;
        idx = i;
      }
    }
    return idx;
  }

  /// X spawn position for a given fractional offset (0.0–1.0 across width).
  double spawnX(double fraction) => fraction * width;

  GameMap copyWith({
    List<TrenchSegment>? trenchSegments,
    List<PlacementPosition>? placements,
    List<Obstacle>? obstacles,
  }) => GameMap(
        id: id, name: name, eraId: eraId, waveCount: waveCount,
        width: width, height: height, spawnZoneY: spawnZoneY,
        trenchSegments: trenchSegments ?? this.trenchSegments,
        commandPostY: commandPostY,
        placements: placements ?? this.placements,
        obstacles: obstacles ?? this.obstacles,
      );

  @override
  List<Object?> get props => [
        id, name, eraId, waveCount, width, height,
        spawnZoneY, trenchSegments, commandPostY, placements, obstacles,
      ];
}
```

**Step 5: Update map_data.dart**

```dart
// lib/config/map_data.dart — replace path-based maps with zone-based
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
}
```

**Step 6: Add exports to models barrel**

```dart
// lib/models/models.dart — add:
export 'obstacle.dart';
```

**Step 7: Run tests**

```bash
/home/grimmy/flutter/bin/flutter test test/models/game_map_zones_test.dart
/home/grimmy/flutter/bin/flutter test
```

**Step 8: Commit**

```bash
git add lib/models/game_map.dart lib/models/obstacle.dart lib/models/models.dart
git add lib/config/map_data.dart test/models/game_map_zones_test.dart
git commit -m "feat: replace path-based GameMap with zone-based layout (segments, obstacles, placement zones)"
```

---

## Task 4: SteeringEngine

**Files:**
- Create: `lib/engine/steering_engine.dart`
- Create: `test/engine/steering_engine_test.dart`

**Step 1: Write failing tests**

```dart
// test/engine/steering_engine_test.dart
import 'dart:ui' show Offset;
import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/engine/steering_engine.dart';
import 'package:trench_defense/models/models.dart';

// Minimal test map — trench at y=300, spawn at y=50, command post at y=600
const _map = GameMap(
  id: 't', name: 'T', eraId: 't', waveCount: 1,
  width: 600, height: 800, spawnZoneY: 50, commandPostY: 600,
  trenchSegments: [
    TrenchSegment(index: 0, worldX: 150, worldY: 300, breachHp: 100),
    TrenchSegment(index: 1, worldX: 450, worldY: 300, breachHp: 100),
  ],
  placements: [], obstacles: [],
);

EnemyInstance _enemy({
  String id = 'e0',
  Offset pos = const Offset(150, 100),
  Offset vel = Offset.zero,
  EnemyMovementState state = EnemyMovementState.advancing,
  int target = 0,
  double speed = 60.0,
}) => EnemyInstance(
      id: id, definitionId: 'inf', currentHp: 50,
      speed: speed, armor: 0, alive: true,
      position: pos, velocity: vel,
      movementState: state, targetSegmentIndex: target,
    );

void main() {
  late SteeringEngine engine;
  setUp(() => engine = SteeringEngine());

  group('SteeringEngine — advancing', () {
    test('dead enemy is not moved', () {
      final dead = _enemy().copyWith(alive: false);
      final result = engine.tick(0.016, [dead], _map);
      expect(result.updatedEnemies.first.position, const Offset(150, 100));
    });

    test('advancing enemy moves toward trench segment (increasing Y)', () {
      final e = _enemy(pos: const Offset(150, 100));
      final result = engine.tick(0.016, [e], _map);
      final moved = result.updatedEnemies.first;
      // Enemy starts above trench (y=100), trench is at y=300 — should move downward
      expect(moved.position.dy, greaterThan(100));
    });

    test('enemy transitions to breaching when it reaches trench Y', () {
      // Place enemy right above the trench — one tick should reach it
      final e = _enemy(pos: const Offset(150, 295), speed: 200.0);
      final result = engine.tick(0.016, [e], _map);
      final updated = result.updatedEnemies.first;
      expect(updated.movementState, EnemyMovementState.breaching);
    });

    test('crossed enemy continues toward command post', () {
      final e = _enemy(
        pos: const Offset(150, 350),
        state: EnemyMovementState.crossed,
      );
      final result = engine.tick(0.016, [e], _map);
      final moved = result.updatedEnemies.first;
      expect(moved.position.dy, greaterThan(350)); // moved further down
    });

    test('enemy that reaches commandPostY is marked reached', () {
      final e = _enemy(
        pos: const Offset(150, 595),
        state: EnemyMovementState.crossed,
        speed: 200.0,
      );
      final result = engine.tick(0.016, [e], _map);
      expect(result.reachedCommandPost, isNotEmpty);
    });

    test('two enemies spread apart — separation prevents perfect overlap', () {
      final e1 = _enemy(id: 'e1', pos: const Offset(150, 100));
      final e2 = _enemy(id: 'e2', pos: const Offset(152, 100)); // nearly same pos
      final result = engine.tick(0.016, [e1, e2], _map);
      final p1 = result.updatedEnemies[0].position;
      final p2 = result.updatedEnemies[1].position;
      final dist = (p1 - p2).distance;
      expect(dist, greaterThan(0)); // they pushed apart
    });
  });
}
```

**Step 2: Run to confirm failure**

```bash
/home/grimmy/flutter/bin/flutter test test/engine/steering_engine_test.dart
```

**Step 3: Implement SteeringEngine**

```dart
// lib/engine/steering_engine.dart
import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../models/enemy_instance.dart';
import '../models/enemy_state.dart';
import '../models/game_map.dart';
import '../models/obstacle.dart';
import '../models/trench_segment.dart';

class SteeringResult {
  final List<EnemyInstance> updatedEnemies;
  final List<EnemyInstance> reachedCommandPost;

  const SteeringResult({
    required this.updatedEnemies,
    required this.reachedCommandPost,
  });
}

class SteeringEngine {
  static const double _separationRadius = 24.0;
  static const double _separationStrength = 80.0;
  static const double _obstacleRadius = 40.0;
  static const double _obstacleStrength = 120.0;
  static const double _arrivalThreshold = 8.0;

  SteeringResult tick(
    double dt,
    List<EnemyInstance> enemies,
    GameMap map,
  ) {
    final updated = <EnemyInstance>[];
    final reached = <EnemyInstance>[];
    final alive = enemies.where((e) => e.alive).toList();

    for (final enemy in enemies) {
      if (!enemy.alive) {
        updated.add(enemy);
        continue;
      }

      // Breaching/inTrench enemies are handled by BreachEngine — don't move them
      if (enemy.movementState == EnemyMovementState.breaching ||
          enemy.movementState == EnemyMovementState.inTrench) {
        updated.add(enemy);
        continue;
      }

      // Compute steering forces
      final seek = _seekForce(enemy, map);
      final separate = _separationForce(enemy, alive);
      final avoid = _obstacleAvoidance(enemy, map.obstacles);

      final steering = (seek + separate + avoid);
      final newVel = _clamp(steering, enemy.speed);
      final newPos = enemy.position + newVel * dt;

      // Check state transitions
      final seg = map.trenchSegments[enemy.targetSegmentIndex];

      if (enemy.movementState == EnemyMovementState.advancing &&
          newPos.dy >= seg.worldY - _arrivalThreshold) {
        // Reached trench — transition to breaching
        updated.add(enemy.copyWith(
          position: Offset(newPos.dx, seg.worldY),
          velocity: Offset.zero,
          movementState: EnemyMovementState.breaching,
        ));
        continue;
      }

      if (enemy.movementState == EnemyMovementState.crossed &&
          newPos.dy >= map.commandPostY) {
        final done = enemy.copyWith(
          position: newPos,
          velocity: newVel,
          alive: false,
        );
        updated.add(done);
        reached.add(done);
        continue;
      }

      updated.add(enemy.copyWith(position: newPos, velocity: newVel));
    }

    return SteeringResult(updatedEnemies: updated, reachedCommandPost: reached);
  }

  // ---- Force calculators ----

  Offset _seekForce(EnemyInstance enemy, GameMap map) {
    late Offset target;
    if (enemy.movementState == EnemyMovementState.crossed) {
      // Head straight down toward command post
      target = Offset(enemy.position.dx, map.commandPostY);
    } else {
      final seg = map.trenchSegments[enemy.targetSegmentIndex];
      target = Offset(seg.worldX, seg.worldY);
    }
    final desired = target - enemy.position;
    final dist = desired.distance;
    if (dist < 0.001) return Offset.zero;
    return desired / dist * enemy.speed;
  }

  Offset _separationForce(EnemyInstance enemy, List<EnemyInstance> all) {
    var force = Offset.zero;
    for (final other in all) {
      if (other.id == enemy.id) continue;
      final diff = enemy.position - other.position;
      final dist = diff.distance;
      if (dist < _separationRadius && dist > 0.001) {
        force += diff / dist * (_separationStrength * (1 - dist / _separationRadius));
      }
    }
    return force;
  }

  Offset _obstacleAvoidance(EnemyInstance enemy, List<Obstacle> obstacles) {
    var force = Offset.zero;
    for (final obs in obstacles) {
      final diff = enemy.position - obs.position;
      final dist = diff.distance;
      final combined = _obstacleRadius + obs.radius;
      if (dist < combined && dist > 0.001) {
        force += diff / dist * (_obstacleStrength * (1 - dist / combined));
      }
    }
    return force;
  }

  Offset _clamp(Offset v, double maxLen) {
    final len = v.distance;
    if (len < 0.001 || len <= maxLen) return v;
    return v / len * maxLen;
  }
}
```

**Step 4: Run tests**

```bash
/home/grimmy/flutter/bin/flutter test test/engine/steering_engine_test.dart
```

**Step 5: Run full suite**

```bash
/home/grimmy/flutter/bin/flutter test
```

**Step 6: Commit**

```bash
git add lib/engine/steering_engine.dart test/engine/steering_engine_test.dart
git commit -m "feat: add SteeringEngine with seek/separation/obstacle-avoidance forces"
```

---

## Task 5: BreachEngine + TrenchEngine

**Files:**
- Create: `lib/engine/breach_engine.dart`
- Create: `lib/engine/trench_engine.dart`
- Create: `test/engine/breach_engine_test.dart`
- Create: `test/engine/trench_engine_test.dart`

**Step 1: Write failing tests**

```dart
// test/engine/breach_engine_test.dart
import 'dart:ui' show Offset;
import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/engine/breach_engine.dart';
import 'package:trench_defense/models/models.dart';

EnemyInstance _breaching({String id = 'e0', double hp = 50}) => EnemyInstance(
      id: id, definitionId: 'inf', currentHp: hp,
      speed: 8, armor: 0, alive: true,
      position: const Offset(150, 300),
      movementState: EnemyMovementState.breaching,
      targetSegmentIndex: 0,
    );

const _seg = TrenchSegment(index: 0, worldX: 150, worldY: 300, breachHp: 100);

void main() {
  group('BreachEngine', () {
    test('breaching enemy drains segment breach HP each tick', () {
      final result = BreachEngine.tick(
        dt: 1.0,
        enemies: [_breaching()],
        segments: [_seg],
        drainPerSecond: 20,
      );
      expect(result.updatedSegments[0].breachHp, closeTo(80, 0.1));
    });

    test('enemy transitions to inTrench when breach HP hits zero', () {
      final result = BreachEngine.tick(
        dt: 10.0,
        enemies: [_breaching()],
        segments: [_seg],
        drainPerSecond: 20, // 200 drain > 100 HP
      );
      expect(result.updatedSegments[0].breachHp, 0);
      expect(result.updatedEnemies[0].movementState, EnemyMovementState.inTrench);
    });

    test('inTrench enemy killed by melee tick transitions to dead', () {
      final inTrench = _breaching().copyWith(
        movementState: EnemyMovementState.inTrench,
        currentHp: 10,
      );
      final result = BreachEngine.tick(
        dt: 0.016,
        enemies: [inTrench],
        segments: [_seg],
        drainPerSecond: 20,
        meleeDamagePerSecond: 800,
      );
      expect(result.updatedEnemies[0].alive, false);
    });
  });
}
```

```dart
// test/engine/trench_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/engine/trench_engine.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  group('TrenchEngine — segment state transitions', () {
    test('segment transitions held → contested when breach HP drops below 80', () {
      final seg = const TrenchSegment(index: 0, worldX: 0, worldY: 300, breachHp: 79);
      final result = TrenchEngine.updateSegmentStates([seg]);
      expect(result[0].state, TrenchSegmentState.contested);
    });

    test('segment transitions contested → breached when breach HP hits 0', () {
      final seg = const TrenchSegment(
        index: 0, worldX: 0, worldY: 300, breachHp: 0,
        state: TrenchSegmentState.contested,
      );
      final result = TrenchEngine.updateSegmentStates([seg]);
      expect(result[0].state, TrenchSegmentState.breached);
    });

    test('breached segment collapses (worldY advances) after collapse delay', () {
      final seg = const TrenchSegment(
        index: 0, worldX: 0, worldY: 300, breachHp: 0,
        state: TrenchSegmentState.breached,
      );
      final result = TrenchEngine.collapseSegment(seg, pushDistance: 60);
      expect(result.state, TrenchSegmentState.collapsed);
      expect(result.worldY, 360);
    });

    test('segment repairs breach HP when melee defender present', () {
      final seg = const TrenchSegment(
        index: 0, worldX: 0, worldY: 300, breachHp: 40,
        state: TrenchSegmentState.contested,
      );
      final result = TrenchEngine.repairSegment(seg, repairPerSecond: 10, dt: 1.0);
      expect(result.breachHp, closeTo(50, 0.1));
    });

    test('repair does not exceed 100', () {
      final seg = const TrenchSegment(index: 0, worldX: 0, worldY: 300, breachHp: 95);
      final result = TrenchEngine.repairSegment(seg, repairPerSecond: 20, dt: 1.0);
      expect(result.breachHp, 100);
    });
  });
}
```

**Step 2: Run to confirm failures**

```bash
/home/grimmy/flutter/bin/flutter test test/engine/breach_engine_test.dart test/engine/trench_engine_test.dart
```

**Step 3: Implement BreachEngine**

```dart
// lib/engine/breach_engine.dart
import '../models/enemy_instance.dart';
import '../models/enemy_state.dart';
import '../models/trench_segment.dart';

class BreachResult {
  final List<EnemyInstance> updatedEnemies;
  final List<TrenchSegment> updatedSegments;
  final int goldAwarded;

  const BreachResult({
    required this.updatedEnemies,
    required this.updatedSegments,
    required this.goldAwarded,
  });
}

class BreachEngine {
  static BreachResult tick({
    required double dt,
    required List<EnemyInstance> enemies,
    required List<TrenchSegment> segments,
    double drainPerSecond = 15,
    double meleeDamagePerSecond = 50,
    Map<String, int> enemyRewards = const {},
  }) {
    final updatedSegs = segments.map((s) => s).toList();
    final updatedEnemies = <EnemyInstance>[];
    int gold = 0;

    for (final enemy in enemies) {
      if (!enemy.alive) { updatedEnemies.add(enemy); continue; }

      if (enemy.movementState == EnemyMovementState.breaching) {
        // Drain segment breach HP
        final seg = updatedSegs[enemy.targetSegmentIndex];
        final newHp = (seg.breachHp - drainPerSecond * dt).clamp(0.0, 100.0);
        updatedSegs[enemy.targetSegmentIndex] = seg.copyWith(breachHp: newHp);

        if (newHp <= 0) {
          // Transition to inTrench
          updatedEnemies.add(enemy.copyWith(movementState: EnemyMovementState.inTrench));
        } else {
          updatedEnemies.add(enemy);
        }
        continue;
      }

      if (enemy.movementState == EnemyMovementState.inTrench) {
        // Melee damage
        final dmg = meleeDamagePerSecond * dt;
        final newHp = enemy.currentHp - dmg;
        if (newHp <= 0) {
          gold += enemyRewards[enemy.definitionId] ?? 0;
          updatedEnemies.add(enemy.copyWith(currentHp: 0, alive: false));
        } else {
          updatedEnemies.add(enemy.copyWith(currentHp: newHp));
        }
        continue;
      }

      updatedEnemies.add(enemy);
    }

    return BreachResult(
      updatedEnemies: updatedEnemies,
      updatedSegments: updatedSegs,
      goldAwarded: gold,
    );
  }
}
```

**Step 4: Implement TrenchEngine**

```dart
// lib/engine/trench_engine.dart
import '../models/trench_segment.dart';

class TrenchEngine {
  static const double _contestedThreshold = 80.0;
  static const double _maxBreachHp = 100.0;

  /// Update segment states based on current breach HP values.
  static List<TrenchSegment> updateSegmentStates(List<TrenchSegment> segments) {
    return segments.map((seg) {
      if (seg.state == TrenchSegmentState.collapsed) return seg;

      if (seg.breachHp <= 0 &&
          seg.state != TrenchSegmentState.breached) {
        return seg.copyWith(state: TrenchSegmentState.breached);
      }
      if (seg.breachHp < _contestedThreshold &&
          seg.state == TrenchSegmentState.held) {
        return seg.copyWith(state: TrenchSegmentState.contested);
      }
      if (seg.breachHp >= _contestedThreshold &&
          seg.state == TrenchSegmentState.contested) {
        return seg.copyWith(state: TrenchSegmentState.held);
      }
      return seg;
    }).toList();
  }

  /// Push a breached segment back toward the command post.
  static TrenchSegment collapseSegment(
    TrenchSegment seg, {
    double pushDistance = 60,
  }) => seg.copyWith(
        state: TrenchSegmentState.collapsed,
        worldY: seg.worldY + pushDistance,
        breachHp: 0,
      );

  /// Repair a segment's breach HP (from melee defenders).
  static TrenchSegment repairSegment(
    TrenchSegment seg, {
    required double repairPerSecond,
    required double dt,
  }) {
    final newHp = (seg.breachHp + repairPerSecond * dt).clamp(0.0, _maxBreachHp);
    return seg.copyWith(breachHp: newHp);
  }
}
```

**Step 5: Run tests**

```bash
/home/grimmy/flutter/bin/flutter test test/engine/breach_engine_test.dart test/engine/trench_engine_test.dart
/home/grimmy/flutter/bin/flutter test
```

**Step 6: Commit**

```bash
git add lib/engine/breach_engine.dart lib/engine/trench_engine.dart
git add test/engine/breach_engine_test.dart test/engine/trench_engine_test.dart
git commit -m "feat: add BreachEngine (breach HP drain, melee combat) and TrenchEngine (segment state transitions, collapse, repair)"
```

---

## Task 6: Wire up the game loop in GameProviders

**Files:**
- Modify: `lib/providers/game_providers.dart`

**Context:** Replace `PathfindingEngine` with `SteeringEngine`. Add trench segment list to `GameController` state. Wire `BreachEngine` and `TrenchEngine` into the tick loop. Update wave spawner to assign spawn positions and target segments.

**Step 1: Update imports and engine fields**

In `game_providers.dart`, replace:
```dart
import '../engine/pathfinding_engine.dart';
// with:
import '../engine/steering_engine.dart';
import '../engine/breach_engine.dart';
import '../engine/trench_engine.dart';
```

Replace field:
```dart
// OLD:
late final PathfindingEngine pathfindingEngine;
// NEW:
late final SteeringEngine steeringEngine;
```

Add trench segment state:
```dart
List<TrenchSegment> trenchSegments = [];
```

**Step 2: Update constructor**

```dart
// In GameController constructor, replace:
pathfindingEngine = PathfindingEngine();
// with:
steeringEngine = SteeringEngine();
trenchSegments = List<TrenchSegment>.from(gameMap.trenchSegments);
```

**Step 3: Update wave spawner to use spawn positions**

When spawning enemies, assign random X across spawn zone and target the weakest segment:
```dart
// In _tick(), where spawned enemies are created, add:
final spawned = _waveSpawner!.tick(dt);
final weakIdx = _currentWeakestSegmentIndex();
final enriched = spawned.map((e) {
  final spawnX = gameMap.spawnX(0.1 + 0.8 * (enemies.length % 5) / 5.0);
  return e.copyWith(
    position: Offset(spawnX, gameMap.spawnZoneY),
    targetSegmentIndex: weakIdx,
  );
}).toList();
enemies = [...enemies, ...enriched];
```

Add helper:
```dart
int _currentWeakestSegmentIndex() => gameMap
    .copyWith(trenchSegments: trenchSegments)
    .weakestSegmentIndex;
```

**Step 4: Replace _tick() movement section**

```dart
void _tick(double dt) {
  if (state.phase != GamePhase.waveActive) return;

  // 1. Spawn enemies
  final spawned = _waveSpawner!.tick(dt);
  // ... enrich with positions as above ...

  // 2. Steering (ADVANCING + CROSSED enemies only)
  final steerResult = steeringEngine.tick(dt, enemies, gameMap);
  enemies = steerResult.updatedEnemies;

  // 3. Handle enemies that reached command post
  for (final reached in steerResult.reachedCommandPost) {
    loopState = GameLoop.applyBaseHpDamage(state: loopState, damage: 1);
    state = state.copyWith(lives: loopState.baseHp);
    _waveSpawner?.markEnemyKilled(reached.id);
  }

  // 4. Breach phase (BREACHING + IN_TRENCH enemies)
  final breachResult = BreachEngine.tick(
    dt: dt,
    enemies: enemies,
    segments: trenchSegments,
    enemyRewards: enemyRewards,
  );
  enemies = breachResult.updatedEnemies;
  trenchSegments = breachResult.updatedSegments;
  if (breachResult.goldAwarded > 0) {
    resources.earn(breachResult.goldAwarded);
    state = state.copyWith(gold: resources.gold);
  }

  // 5. Update segment states (transitions + collapse check)
  trenchSegments = TrenchEngine.updateSegmentStates(trenchSegments);
  for (int i = 0; i < trenchSegments.length; i++) {
    if (trenchSegments[i].state == TrenchSegmentState.breached) {
      trenchSegments[i] = TrenchEngine.collapseSegment(trenchSegments[i]);
    }
  }

  // 6. Check defeat (all segments collapsed)
  if (trenchSegments.every((s) => s.state == TrenchSegmentState.collapsed)) {
    state = state.copyWith(phase: GamePhase.defeat);
    _stopTimer();
    notifyListeners();
    return;
  }

  // 7. Ranged combat (towers fire at ADVANCING enemies)
  final combatResult = combatEngine.tick(
    deltaTime: dt,
    towers: state.towers,
    enemies: enemies,
    map: gameMap,
    towerLookup: towerLookup,
    enemyRewards: enemyRewards,
  );
  enemies = combatResult.updatedEnemies;
  if (combatResult.goldAwarded > 0) {
    resources.earn(combatResult.goldAwarded);
    state = state.copyWith(gold: resources.gold);
  }

  // 8. Wave complete check
  // ... existing logic unchanged ...

  notifyListeners();
}
```

**Step 5: Update CombatEngine to skip non-advancing enemies**

In `lib/engine/combat_engine.dart`, in the targeting section, add a filter:
```dart
// Only ranged towers fire at ADVANCING enemies
final targetableEnemies = enemies
    .where((e) => e.alive && e.movementState == EnemyMovementState.advancing)
    .toList();
// Use targetableEnemies instead of enemies in targeting calls
```

And update `targeting_engine.dart` to use `enemy.position` directly (already done in Task 2).

**Step 6: Run full test suite**

```bash
/home/grimmy/flutter/bin/flutter test
```

**Step 7: Commit**

```bash
git add lib/providers/game_providers.dart lib/engine/combat_engine.dart
git commit -m "feat: wire SteeringEngine, BreachEngine, TrenchEngine into game loop"
```

---

## Task 7: Rewrite GameMapWidget renderer

**Files:**
- Modify: `lib/ui/widgets/game_map_widget.dart`

**Context:** The renderer currently draws a path, enemies as circles along it, and placement slots. Replace with: three zones (tinted bands), segmented trench line (colored by state), enemies as free-positioned circles, obstacles, and placement slots by zone.

**Step 1: No new tests needed** — CustomPainter rendering is visual. Manual QA on device/emulator is the check.

**Step 2: Replace the draw methods**

The key changes in `_GameMapPainter` (or equivalent CustomPainter):

```dart
// Remove: _drawPath(), any positionAtProgress() calls
// Add: _drawZones(), _drawTrench(), _drawObstacles()
// Modify: _drawEnemies() to use enemy.position directly
// Modify: _drawPlacements() to color by zone

void _drawZones(Canvas canvas, Size size) {
  // No man's land (top to trench)
  final trenchY = _averageTrenchY();
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.width, trenchY),
    Paint()..color = const Color(0xFF3D4A1E).withOpacity(0.4),
  );
  // Behind trench (trench to command post)
  canvas.drawRect(
    Rect.fromLTWH(0, trenchY, size.width, size.height - trenchY),
    Paint()..color = const Color(0xFF2A3010).withOpacity(0.5),
  );
}

void _drawTrench(Canvas canvas) {
  for (final seg in controller.trenchSegments) {
    final color = switch (seg.state) {
      TrenchSegmentState.held => const Color(0xFF5C4A32),
      TrenchSegmentState.contested => const Color(0xFFAA5500),
      TrenchSegmentState.breached => const Color(0xFFCC2200),
      TrenchSegmentState.collapsed => const Color(0xFF880000),
    };
    final rect = Rect.fromCenter(
      center: Offset(seg.worldX, seg.worldY),
      width: controller.gameMap.segmentWidth - 4,
      height: 28,
    );
    canvas.drawRect(rect, Paint()..color = color);

    // Breach HP bar
    if (seg.state != TrenchSegmentState.collapsed) {
      final barW = (controller.gameMap.segmentWidth - 8) * (seg.breachHp / 100);
      canvas.drawRect(
        Rect.fromLTWH(seg.worldX - controller.gameMap.segmentWidth / 2 + 4,
            seg.worldY + 16, barW, 4),
        Paint()..color = const Color(0xFF00FF88),
      );
    }
  }
}

void _drawObstacles(Canvas canvas) {
  for (final obs in controller.gameMap.obstacles) {
    final paint = Paint()
      ..color = obs.type == ObstacleType.barbedWire
          ? const Color(0xFF888866)
          : const Color(0xFF554433);
    canvas.drawCircle(obs.position, obs.radius, paint);
  }
}

void _drawEnemies(Canvas canvas) {
  for (final enemy in controller.enemies) {
    if (!enemy.alive) continue;
    final pos = enemy.position; // direct — no positionAtProgress needed
    final color = switch (enemy.movementState) {
      EnemyMovementState.advancing => const Color(0xFFCC3333),
      EnemyMovementState.breaching => const Color(0xFFFF6600),
      EnemyMovementState.inTrench => const Color(0xFFFF0000),
      EnemyMovementState.crossed => const Color(0xFF990000),
    };
    canvas.drawCircle(pos, 8, Paint()..color = color);
  }
}
```

**Step 3: Run on emulator / hot reload and visually verify**

```bash
/home/grimmy/flutter/bin/flutter run
```

Check:
- Three zones visible (lighter green / darker green)
- Trench line shows 5 segments
- Enemies spawn at top and move downward toward trench
- Segments turn orange/red when contested/breached

**Step 4: Commit**

```bash
git add lib/ui/widgets/game_map_widget.dart
git commit -m "feat: rewrite game map renderer for perpendicular layout (zones, segmented trench, free-positioned enemies)"
```

---

## Task 8: Final integration — compile clean + full test pass

**Step 1: Full compile check**

```bash
/home/grimmy/flutter/bin/flutter analyze 2>&1 | grep -v "^Analyzing" | head -30
```

Fix any remaining type errors or missing imports.

**Step 2: Full test suite**

```bash
/home/grimmy/flutter/bin/flutter test
```
Expected: all tests pass (291+ existing + new tests from Tasks 1–5).

**Step 3: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: resolve remaining analyze warnings post-refactor"
```

---

## Completion

When all tasks are done, use `superpowers:finishing-a-development-branch` to merge, create PR, or discard.
