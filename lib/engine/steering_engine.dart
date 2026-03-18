import 'dart:ui' show Offset;

import '../models/enemy_instance.dart';
import '../models/enemy_state.dart';
import '../models/game_map.dart';
import '../models/obstacle.dart';

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
          newPos.dy >= map.commandPostY - _arrivalThreshold) {
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
