import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  group('TowerDefinition', () {
    const tower = TowerDefinition(
      id: 'test_tower',
      name: 'Test Tower',
      eraId: 'test_era',
      tier: 1,
      cost: 50,
      range: 3.0,
      damage: 10,
      attackSpeed: 1.0,
      description: 'A test tower.',
      category: TowerCategory.damage,
    );

    test('constructs with correct values', () {
      expect(tower.id, 'test_tower');
      expect(tower.name, 'Test Tower');
      expect(tower.eraId, 'test_era');
      expect(tower.tier, 1);
      expect(tower.cost, 50);
      expect(tower.range, 3.0);
      expect(tower.damage, 10);
      expect(tower.attackSpeed, 1.0);
      expect(tower.description, 'A test tower.');
      expect(tower.category, TowerCategory.damage);
      expect(tower.upgradesFromId, isNull);
      expect(tower.upgradesTo, isEmpty);
    });

    test('JSON round-trip preserves all fields', () {
      final json = tower.toJson();
      final restored = TowerDefinition.fromJson(json);
      expect(restored, tower);
    });

    test('JSON round-trip with nullable upgradesFromId', () {
      final towerWithUpgrade = tower.copyWith(
        id: 'tier2_tower',
        tier: 2,
        upgradesFromId: 'test_tower',
      );
      final json = towerWithUpgrade.toJson();
      final restored = TowerDefinition.fromJson(json);
      expect(restored.upgradesFromId, 'test_tower');
      expect(restored.tier, 2);
      expect(restored, towerWithUpgrade);
    });

    test('upgrade path: tier 1 tower has upgradesTo', () {
      final tier1 = tower.copyWith(
        upgradesTo: ['tier2a', 'tier2b'],
      );
      expect(tier1.upgradesTo, ['tier2a', 'tier2b']);
      expect(tier1.upgradesTo.length, 2);
    });

    test('upgrade path: tier 2 tower has upgradesFromId', () {
      final tier2 = tower.copyWith(
        id: 'tier2a',
        tier: 2,
        upgradesFromId: 'test_tower',
      );
      expect(tier2.upgradesFromId, 'test_tower');
      expect(tier2.tier, 2);
    });

    test('copyWith creates new instance with changed fields', () {
      final modified = tower.copyWith(name: 'Modified Tower', cost: 100);
      expect(modified.name, 'Modified Tower');
      expect(modified.cost, 100);
      expect(modified.id, tower.id); // unchanged
      expect(modified.range, tower.range); // unchanged
    });

    test('equality works correctly', () {
      final tower2 = TowerDefinition(
        id: 'test_tower',
        name: 'Test Tower',
        eraId: 'test_era',
        tier: 1,
        cost: 50,
        range: 3.0,
        damage: 10,
        attackSpeed: 1.0,
        description: 'A test tower.',
        category: TowerCategory.damage,
      );
      expect(tower, tower2);
    });
  });

  group('TowerCategory', () {
    test('enum serialization round-trip for damage', () {
      expect(TowerCategory.fromJson(TowerCategory.damage.toJson()),
          TowerCategory.damage);
    });

    test('enum serialization round-trip for area', () {
      expect(TowerCategory.fromJson(TowerCategory.area.toJson()),
          TowerCategory.area);
    });

    test('enum serialization round-trip for slow', () {
      expect(TowerCategory.fromJson(TowerCategory.slow.toJson()),
          TowerCategory.slow);
    });

    test('toJson returns enum name string', () {
      expect(TowerCategory.damage.toJson(), 'damage');
      expect(TowerCategory.area.toJson(), 'area');
      expect(TowerCategory.slow.toJson(), 'slow');
    });
  });
}
