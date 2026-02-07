import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  group('EnemyDefinition', () {
    const enemy = EnemyDefinition(
      id: 'test_infantry',
      name: 'Infantry',
      eraId: 'test_era',
      hp: 100,
      speed: 1.0,
      armor: 0,
      reward: 10,
      description: 'Basic foot soldier.',
    );

    const enemyWithAbility = EnemyDefinition(
      id: 'test_officer',
      name: 'Officer',
      eraId: 'test_era',
      hp: 120,
      speed: 1.0,
      armor: 2,
      reward: 25,
      ability: EnemyAbility.buff,
      description: 'Commands nearby troops.',
    );

    test('constructs with correct values', () {
      expect(enemy.id, 'test_infantry');
      expect(enemy.name, 'Infantry');
      expect(enemy.eraId, 'test_era');
      expect(enemy.hp, 100);
      expect(enemy.speed, 1.0);
      expect(enemy.armor, 0);
      expect(enemy.reward, 10);
      expect(enemy.description, 'Basic foot soldier.');
    });

    test('nullable ability field: Infantry has no ability', () {
      expect(enemy.ability, isNull);
    });

    test('ability field present when specified', () {
      expect(enemyWithAbility.ability, EnemyAbility.buff);
    });

    test('JSON round-trip preserves all fields (no ability)', () {
      final json = enemy.toJson();
      final restored = EnemyDefinition.fromJson(json);
      expect(restored, enemy);
      expect(restored.ability, isNull);
    });

    test('JSON round-trip preserves all fields (with ability)', () {
      final json = enemyWithAbility.toJson();
      final restored = EnemyDefinition.fromJson(json);
      expect(restored, enemyWithAbility);
      expect(restored.ability, EnemyAbility.buff);
    });

    test('toJson encodes null ability as null', () {
      final json = enemy.toJson();
      expect(json['ability'], isNull);
    });

    test('toJson encodes ability as string', () {
      final json = enemyWithAbility.toJson();
      expect(json['ability'], 'buff');
    });

    test('copyWith creates new instance with changed fields', () {
      final modified = enemy.copyWith(hp: 200, speed: 0.5);
      expect(modified.hp, 200);
      expect(modified.speed, 0.5);
      expect(modified.id, enemy.id); // unchanged
      expect(modified.reward, enemy.reward); // unchanged
    });

    test('equality works correctly', () {
      final enemy2 = EnemyDefinition(
        id: 'test_infantry',
        name: 'Infantry',
        eraId: 'test_era',
        hp: 100,
        speed: 1.0,
        armor: 0,
        reward: 10,
        description: 'Basic foot soldier.',
      );
      expect(enemy, enemy2);
    });
  });

  group('EnemyAbility', () {
    test('enum serialization round-trip for all values', () {
      for (final ability in EnemyAbility.values) {
        expect(EnemyAbility.fromJson(ability.toJson()), ability);
      }
    });

    test('toJson returns enum name string', () {
      expect(EnemyAbility.heal.toJson(), 'heal');
      expect(EnemyAbility.buff.toJson(), 'buff');
      expect(EnemyAbility.shield.toJson(), 'shield');
      expect(EnemyAbility.sap.toJson(), 'sap');
      expect(EnemyAbility.siege.toJson(), 'siege');
    });

    test('all five abilities are present', () {
      expect(EnemyAbility.values.length, 5);
    });
  });
}
