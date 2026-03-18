import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  const testDefinition = EnemyDefinition(
    id: 'test_infantry',
    name: 'Test Infantry',
    eraId: 'test',
    hp: 100,
    speed: 1.0,
    armor: 0,
    reward: 10,
    description: 'Test enemy',
  );

  const armoredDefinition = EnemyDefinition(
    id: 'test_heavy',
    name: 'Test Heavy',
    eraId: 'test',
    hp: 250,
    speed: 0.6,
    armor: 8,
    reward: 35,
    description: 'Armored test enemy',
  );

  group('EnemyInstance (new fields)', () {
    test('fromDefinition sets position to Offset.zero and state to advancing', () {
      final inst = EnemyInstance.fromDefinition(
        id: 'e0',
        definition: testDefinition,
      );
      expect(inst.position, const Offset(0, 0));
      expect(inst.velocity, const Offset(0, 0));
      expect(inst.movementState, EnemyMovementState.advancing);
      expect(inst.targetSegmentIndex, 0);
    });

    test('copyWith updates position without touching other fields', () {
      final inst = EnemyInstance.fromDefinition(
        id: 'e0',
        definition: testDefinition,
      );
      final moved = inst.copyWith(position: const Offset(100, 200));
      expect(moved.position, const Offset(100, 200));
      expect(moved.speed, testDefinition.speed);
    });

    test('fromDefinition with spawnPosition sets position correctly', () {
      const spawn = Offset(50, 75);
      final inst = EnemyInstance.fromDefinition(
        id: 'e1',
        definition: testDefinition,
        spawnPosition: spawn,
      );
      expect(inst.position, spawn);
    });

    test('fromDefinition with targetSegment sets targetSegmentIndex', () {
      final inst = EnemyInstance.fromDefinition(
        id: 'e2',
        definition: testDefinition,
        targetSegment: 3,
      );
      expect(inst.targetSegmentIndex, 3);
    });

    test('copyWith updates movementState', () {
      final inst = EnemyInstance.fromDefinition(
        id: 'e0',
        definition: testDefinition,
      );
      final breaching = inst.copyWith(
        movementState: EnemyMovementState.breaching,
      );
      expect(breaching.movementState, EnemyMovementState.breaching);
      expect(breaching.position, const Offset(0, 0));
    });

    test('copyWith updates velocity', () {
      final inst = EnemyInstance.fromDefinition(
        id: 'e0',
        definition: testDefinition,
      );
      final moving = inst.copyWith(velocity: const Offset(10, 5));
      expect(moving.velocity, const Offset(10, 5));
      expect(moving.id, 'e0');
    });
  });

  group('EnemyInstance fromDefinition factory', () {
    test('copies hp from definition', () {
      final instance = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      expect(instance.currentHp, testDefinition.hp);
    });

    test('copies speed from definition', () {
      final instance = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      expect(instance.speed, testDefinition.speed);
    });

    test('copies armor from definition', () {
      final instance = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: armoredDefinition,
      );
      expect(instance.armor, armoredDefinition.armor);
    });

    test('sets definitionId from definition', () {
      final instance = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      expect(instance.definitionId, testDefinition.id);
    });

    test('assigns the given id', () {
      final instance = EnemyInstance.fromDefinition(
        id: 'wave1_enemy_5',
        definition: testDefinition,
      );
      expect(instance.id, 'wave1_enemy_5');
    });

    test('all stats copied correctly from armored definition', () {
      final instance = EnemyInstance.fromDefinition(
        id: 'enemy_1',
        definition: armoredDefinition,
      );
      expect(instance.currentHp, 250);
      expect(instance.speed, 0.6);
      expect(instance.armor, 8);
      expect(instance.definitionId, 'test_heavy');
    });
  });

  group('EnemyInstance initial state', () {
    test('alive starts as true', () {
      final instance = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      expect(instance.alive, isTrue);
    });

    test('position starts at Offset.zero', () {
      final instance = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      expect(instance.position, Offset.zero);
    });
  });

  group('EnemyInstance copyWith', () {
    test('creates new instance with changed currentHp', () {
      final instance = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      final damaged = instance.copyWith(currentHp: 50);
      expect(damaged.currentHp, 50);
      expect(damaged.id, instance.id);
      expect(damaged.speed, instance.speed);
    });

    test('creates new instance with changed position', () {
      final instance = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      final moved = instance.copyWith(position: const Offset(50, 100));
      expect(moved.position, const Offset(50, 100));
      expect(moved.currentHp, instance.currentHp);
    });

    test('creates new instance with alive set to false', () {
      final instance = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      final dead = instance.copyWith(alive: false);
      expect(dead.alive, isFalse);
      expect(dead.id, instance.id);
    });

    test('unchanged fields remain the same', () {
      final instance = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: armoredDefinition,
      );
      final copy = instance.copyWith(currentHp: 100);
      expect(copy.id, instance.id);
      expect(copy.definitionId, instance.definitionId);
      expect(copy.speed, instance.speed);
      expect(copy.armor, instance.armor);
      expect(copy.position, instance.position);
      expect(copy.alive, instance.alive);
      expect(copy.movementState, instance.movementState);
    });

    test('can change multiple fields at once', () {
      final instance = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      final updated = instance.copyWith(
        currentHp: 25,
        position: const Offset(75, 0),
        alive: false,
      );
      expect(updated.currentHp, 25);
      expect(updated.position, const Offset(75, 0));
      expect(updated.alive, isFalse);
    });
  });

  group('EnemyInstance Equatable', () {
    test('two instances with same values are equal', () {
      final a = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      final b = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      expect(a, b);
    });

    test('two instances with different ids are not equal', () {
      final a = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      final b = EnemyInstance.fromDefinition(
        id: 'enemy_1',
        definition: testDefinition,
      );
      expect(a, isNot(b));
    });

    test('instance differs after copyWith change', () {
      final original = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      final modified = original.copyWith(currentHp: 50);
      expect(original, isNot(modified));
    });

    test('hashCode matches for equal instances', () {
      final a = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      final b = EnemyInstance.fromDefinition(
        id: 'enemy_0',
        definition: testDefinition,
      );
      expect(a.hashCode, b.hashCode);
    });
  });

  group('EnemyInstance const construction', () {
    test('can be constructed directly with const', () {
      const instance = EnemyInstance(
        id: 'enemy_0',
        definitionId: 'test_infantry',
        currentHp: 100,
        speed: 1.0,
        armor: 0,
        alive: true,
      );
      expect(instance.id, 'enemy_0');
      expect(instance.definitionId, 'test_infantry');
      expect(instance.position, Offset.zero);
      expect(instance.movementState, EnemyMovementState.advancing);
    });
  });
}
