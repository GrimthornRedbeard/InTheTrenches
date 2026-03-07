import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/config/era_registry.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  group('EraRegistry - WWI Era', () {
    test('has exactly 3 base towers', () {
      expect(EraRegistry.wwi.towers.length, 3);
    });

    test('has exactly 8 enemy types', () {
      expect(EraRegistry.wwi.enemies.length, 8);
    });

    test('each tower has valid stats (positive cost, range, damage)', () {
      for (final tower in EraRegistry.wwi.towers) {
        expect(
          tower.cost,
          greaterThan(0),
          reason: '${tower.name} should have positive cost',
        );
        expect(
          tower.range,
          greaterThan(0),
          reason: '${tower.name} should have positive range',
        );
        expect(
          tower.damage,
          greaterThan(0),
          reason: '${tower.name} should have positive damage',
        );
      }
    });

    test('each enemy has valid stats (positive hp, speed, reward)', () {
      for (final enemy in EraRegistry.wwi.enemies) {
        expect(
          enemy.hp,
          greaterThan(0),
          reason: '${enemy.name} should have positive hp',
        );
        expect(
          enemy.speed,
          greaterThan(0),
          reason: '${enemy.name} should have positive speed',
        );
        expect(
          enemy.reward,
          greaterThan(0),
          reason: '${enemy.name} should have positive reward',
        );
      }
    });

    test('contains one tower of each category', () {
      final categories = EraRegistry.wwi.towers.map((t) => t.category).toSet();
      expect(categories, contains(TowerCategory.damage));
      expect(categories, contains(TowerCategory.area));
      expect(categories, contains(TowerCategory.slow));
    });

    test('all towers belong to wwi era', () {
      for (final tower in EraRegistry.wwi.towers) {
        expect(
          tower.eraId,
          'wwi',
          reason: '${tower.name} should belong to wwi era',
        );
      }
    });

    test('all enemies belong to wwi era', () {
      for (final enemy in EraRegistry.wwi.enemies) {
        expect(
          enemy.eraId,
          'wwi',
          reason: '${enemy.name} should belong to wwi era',
        );
      }
    });

    test('tower IDs are unique', () {
      final ids = EraRegistry.wwi.towers.map((t) => t.id).toSet();
      expect(ids.length, EraRegistry.wwi.towers.length);
    });

    test('enemy IDs are unique', () {
      final ids = EraRegistry.wwi.enemies.map((e) => e.id).toSet();
      expect(ids.length, EraRegistry.wwi.enemies.length);
    });
  });

  group('EraRegistry - Medieval Era', () {
    test('has exactly 3 base towers', () {
      expect(EraRegistry.medieval.towers.length, 3);
    });

    test('has exactly 8 enemy types', () {
      expect(EraRegistry.medieval.enemies.length, 8);
    });

    test('each tower has valid stats (positive cost, range, damage)', () {
      for (final tower in EraRegistry.medieval.towers) {
        expect(
          tower.cost,
          greaterThan(0),
          reason: '${tower.name} should have positive cost',
        );
        expect(
          tower.range,
          greaterThan(0),
          reason: '${tower.name} should have positive range',
        );
        expect(
          tower.damage,
          greaterThan(0),
          reason: '${tower.name} should have positive damage',
        );
      }
    });

    test('each enemy has valid stats (positive hp, speed, reward)', () {
      for (final enemy in EraRegistry.medieval.enemies) {
        expect(
          enemy.hp,
          greaterThan(0),
          reason: '${enemy.name} should have positive hp',
        );
        expect(
          enemy.speed,
          greaterThan(0),
          reason: '${enemy.name} should have positive speed',
        );
        expect(
          enemy.reward,
          greaterThan(0),
          reason: '${enemy.name} should have positive reward',
        );
      }
    });

    test('contains one tower of each category', () {
      final categories = EraRegistry.medieval.towers
          .map((t) => t.category)
          .toSet();
      expect(categories, contains(TowerCategory.damage));
      expect(categories, contains(TowerCategory.area));
      expect(categories, contains(TowerCategory.slow));
    });

    test('all towers belong to medieval era', () {
      for (final tower in EraRegistry.medieval.towers) {
        expect(
          tower.eraId,
          'medieval',
          reason: '${tower.name} should belong to medieval era',
        );
      }
    });

    test('all enemies belong to medieval era', () {
      for (final enemy in EraRegistry.medieval.enemies) {
        expect(
          enemy.eraId,
          'medieval',
          reason: '${enemy.name} should belong to medieval era',
        );
      }
    });

    test('tower IDs are unique', () {
      final ids = EraRegistry.medieval.towers.map((t) => t.id).toSet();
      expect(ids.length, EraRegistry.medieval.towers.length);
    });

    test('enemy IDs are unique', () {
      final ids = EraRegistry.medieval.enemies.map((e) => e.id).toSet();
      expect(ids.length, EraRegistry.medieval.enemies.length);
    });
  });

  group('EraRegistry - Registry Access', () {
    test('allEras contains both eras', () {
      expect(EraRegistry.allEras.length, 2);
      expect(
        EraRegistry.allEras.map((e) => e.id),
        containsAll(['wwi', 'medieval']),
      );
    });

    test('getEra returns correct era by ID', () {
      expect(EraRegistry.getEra('wwi'), EraRegistry.wwi);
      expect(EraRegistry.getEra('medieval'), EraRegistry.medieval);
    });

    test('getEra returns null for unknown ID', () {
      expect(EraRegistry.getEra('unknown'), isNull);
    });

    test('getTower returns correct tower by ID', () {
      final rifleman = EraRegistry.getTower('wwi_rifleman');
      expect(rifleman, isNotNull);
      expect(rifleman!.name, 'Rifleman');
    });

    test('getTower returns null for unknown ID', () {
      expect(EraRegistry.getTower('unknown'), isNull);
    });

    test('getEnemy returns correct enemy by ID', () {
      final infantry = EraRegistry.getEnemy('wwi_infantry');
      expect(infantry, isNotNull);
      expect(infantry!.name, 'Infantry');
    });

    test('getEnemy returns null for unknown ID', () {
      expect(EraRegistry.getEnemy('unknown'), isNull);
    });
  });
}
