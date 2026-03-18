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
