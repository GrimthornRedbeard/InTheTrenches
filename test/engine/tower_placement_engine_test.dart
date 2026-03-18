import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/engine/tower_placement_engine.dart';
import 'package:trench_defense/engine/resource_manager.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared fixtures
  // ---------------------------------------------------------------------------

  const rifle = TowerDefinition(
    id: 'rifle_t1',
    name: 'Rifle Pit',
    eraId: 'ww1',
    tier: 1,
    cost: 50,
    range: 60.0,
    damage: 20.0,
    attackSpeed: 1.0,
    description: 'Basic riflemen',
    category: TowerCategory.damage,
    upgradesTo: ['rifle_t2a', 'rifle_t2b'],
  );

  const rifleT2a = TowerDefinition(
    id: 'rifle_t2a',
    name: 'Marksmen Pit',
    eraId: 'ww1',
    tier: 2,
    cost: 80,
    range: 80.0,
    damage: 35.0,
    attackSpeed: 0.8,
    description: 'Precise shooters',
    upgradesFromId: 'rifle_t1',
    category: TowerCategory.damage,
    upgradesTo: ['rifle_t3a'],
  );

  const rifleT2b = TowerDefinition(
    id: 'rifle_t2b',
    name: 'Rapid Fire Pit',
    eraId: 'ww1',
    tier: 2,
    cost: 80,
    range: 55.0,
    damage: 18.0,
    attackSpeed: 2.5,
    description: 'Fast rate of fire',
    upgradesFromId: 'rifle_t1',
    category: TowerCategory.damage,
    upgradesTo: ['rifle_t3b'],
  );

  const rifleT3a = TowerDefinition(
    id: 'rifle_t3a',
    name: 'Sniper Nest',
    eraId: 'ww1',
    tier: 3,
    cost: 120,
    range: 120.0,
    damage: 60.0,
    attackSpeed: 0.5,
    description: 'Long-range precision',
    upgradesFromId: 'rifle_t2a',
    category: TowerCategory.damage,
  );

  final towerLookup = <String, TowerDefinition>{
    rifle.id: rifle,
    rifleT2a.id: rifleT2a,
    rifleT2b.id: rifleT2b,
    rifleT3a.id: rifleT3a,
  };

  // Map with placement positions at (0,0) and (50,0)
  const testMap = GameMap(
    id: 'test_map',
    name: 'Test',
    eraId: 'ww1',
    waveCount: 3,
    width: 600,
    height: 800,
    spawnZoneY: 0,
    commandPostY: 800,
    trenchSegments: [],
    placements: [
      PlacementPosition(id: 'pos_0', x: 0, y: 0),
      PlacementPosition(id: 'pos_1', x: 50, y: 0),
    ],
    obstacles: [],
  );

  late ResourceManager resources;
  late TowerPlacementEngine engine;

  setUp(() {
    resources = ResourceManager(startingGold: 500);
    engine = TowerPlacementEngine(map: testMap, towerLookup: towerLookup);
  });

  // ---------------------------------------------------------------------------
  // buildTower
  // ---------------------------------------------------------------------------

  group('TowerPlacementEngine — buildTower', () {
    test('build places tower at valid position and deducts cost', () {
      final tower = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      );

      expect(tower, isNotNull);
      expect(tower!.definitionId, 'rifle_t1');
      expect(tower.x, 0.0);
      expect(tower.y, 0.0);
      expect(tower.currentTier, 1);
      expect(resources.gold, 450); // 500 - 50
    });

    test('build deducts cost from resources', () {
      engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      );
      expect(resources.gold, 450);
    });

    test('build returns null when insufficient resources', () {
      final poorResources = ResourceManager(startingGold: 10);
      final tower = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: poorResources,
      );

      expect(tower, isNull);
      expect(poorResources.gold, 10); // unchanged
    });

    test('build returns null for unknown position', () {
      final tower = engine.buildTower(
        positionId: 'unknown_pos',
        towerDefId: 'rifle_t1',
        resources: resources,
      );
      expect(tower, isNull);
    });

    test('build returns null for unknown tower definition', () {
      final tower = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'unknown_tower',
        resources: resources,
      );
      expect(tower, isNull);
    });

    test('build returns null if position already occupied', () {
      engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      );

      // Try to build again at same position
      final second = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      );
      expect(second, isNull);
      expect(resources.gold, 450); // only one deduction
    });

    test('can build at two separate positions', () {
      engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      );
      engine.buildTower(
        positionId: 'pos_1',
        towerDefId: 'rifle_t1',
        resources: resources,
      );
      expect(resources.gold, 400); // 500 - 50 - 50
      expect(engine.towers.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // sellTower
  // ---------------------------------------------------------------------------

  group('TowerPlacementEngine — sellTower', () {
    test('sell refunds 60% of cost and removes tower', () {
      final tower = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      )!;

      engine.sellTower(towerId: tower.id, resources: resources);

      expect(resources.gold, 500 - 50 + 30); // 30 = 60% of 50
      expect(engine.towers, isEmpty);
    });

    test('sell frees the position for a new tower', () {
      final tower = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      )!;

      engine.sellTower(towerId: tower.id, resources: resources);

      // Position should be free again
      final rebuilt = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      );
      expect(rebuilt, isNotNull);
    });

    test('sell refunds 60% of total invested including upgrades', () {
      // Build (cost 50) then upgrade to T2a (cost 80) => total 130
      // Refund = 60% of 130 = 78
      final tower = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      )!;

      engine.upgradeTower(towerId: tower.id, resources: resources);
      final goldAfterUpgrade = resources.gold;

      engine.sellTower(towerId: tower.id, resources: resources);

      // After upgrade: 500 - 50 - 80 = 370. Refund: 60% of 130 = 78 => 448
      expect(resources.gold, goldAfterUpgrade + 78);
    });

    test('sell does nothing for unknown tower id', () {
      final goldBefore = resources.gold;
      engine.sellTower(towerId: 'ghost_tower', resources: resources);
      expect(resources.gold, goldBefore);
    });
  });

  // ---------------------------------------------------------------------------
  // upgradeTower (Tier 1 → Tier 2 branch selection)
  // ---------------------------------------------------------------------------

  group('TowerPlacementEngine — upgradeTower (Tier 1 → Tier 2)', () {
    test('upgrade from T1 chooses first upgrade branch by default', () {
      final tower = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      )!;

      final upgraded = engine.upgradeTower(
        towerId: tower.id,
        resources: resources,
      );

      expect(upgraded, isNotNull);
      // Should upgrade to first option: rifle_t2a
      expect(upgraded!.definitionId, 'rifle_t2a');
      expect(upgraded.currentTier, 2);
    });

    test('upgrade deducts cost of target definition', () {
      final tower = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      )!;

      engine.upgradeTower(towerId: tower.id, resources: resources);
      expect(resources.gold, 500 - 50 - 80); // rifle_t2a costs 80
    });

    test('upgrade fails if insufficient resources', () {
      final poorResources = ResourceManager(startingGold: 60);
      final tower = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: poorResources,
      )!; // costs 50, leaves 10

      final upgraded = engine.upgradeTower(
        towerId: tower.id,
        resources: poorResources,
      ); // upgrade costs 80 — should fail

      expect(upgraded, isNull);
      expect(poorResources.gold, 10);
    });

    test('upgrade fails for unknown tower id', () {
      final upgraded = engine.upgradeTower(
        towerId: 'ghost',
        resources: resources,
      );
      expect(upgraded, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // chooseBranch (explicitly select a Tier 2 branch)
  // ---------------------------------------------------------------------------

  group('TowerPlacementEngine — chooseBranch', () {
    test('chooseBranch selects the specified T2 branch', () {
      final tower = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      )!;

      final upgraded = engine.chooseBranch(
        towerId: tower.id,
        branchDefId: 'rifle_t2b',
        resources: resources,
      );

      expect(upgraded, isNotNull);
      expect(upgraded!.definitionId, 'rifle_t2b');
      expect(upgraded.currentTier, 2);
    });

    test('chooseBranch deducts correct cost for chosen branch', () {
      final tower = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      )!;

      engine.chooseBranch(
        towerId: tower.id,
        branchDefId: 'rifle_t2b',
        resources: resources,
      );

      expect(resources.gold, 500 - 50 - 80); // rifle_t2b also costs 80
    });

    test('branch choice locked after Tier 2 selected', () {
      final tower = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      )!;

      // First branch selection
      final t2 = engine.chooseBranch(
        towerId: tower.id,
        branchDefId: 'rifle_t2a',
        resources: resources,
      )!;

      // Trying to pick a different branch should fail (already at T2)
      final reselect = engine.chooseBranch(
        towerId: t2.id,
        branchDefId: 'rifle_t2b',
        resources: resources,
      );

      expect(reselect, isNull);
      // Gold unchanged from failed attempt
      expect(resources.gold, 500 - 50 - 80);
    });

    test('chooseBranch fails for invalid branch id', () {
      final tower = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      )!;

      final upgraded = engine.chooseBranch(
        towerId: tower.id,
        branchDefId: 'invalid_branch',
        resources: resources,
      );

      expect(upgraded, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // upgradeTier3 (Tier 2 → Tier 3)
  // ---------------------------------------------------------------------------

  group('TowerPlacementEngine — upgradeTier3', () {
    test('upgradeTier3 advances T2 tower to T3', () {
      final t1 = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      )!;

      final t2 = engine.chooseBranch(
        towerId: t1.id,
        branchDefId: 'rifle_t2a',
        resources: resources,
      )!;

      final t3 = engine.upgradeTier3(towerId: t2.id, resources: resources);

      expect(t3, isNotNull);
      expect(t3!.definitionId, 'rifle_t3a');
      expect(t3.currentTier, 3);
    });

    test('upgradeTier3 fails if tower is not at Tier 2', () {
      final t1 = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      )!;

      final t3 = engine.upgradeTier3(towerId: t1.id, resources: resources);
      expect(t3, isNull);
    });

    test('upgradeTier3 fails if already at Tier 3', () {
      final t1 = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      )!;
      final t2 = engine.chooseBranch(
        towerId: t1.id,
        branchDefId: 'rifle_t2a',
        resources: resources,
      )!;
      final t3first = engine.upgradeTier3(
        towerId: t2.id,
        resources: resources,
      )!;

      final t3second = engine.upgradeTier3(
        towerId: t3first.id,
        resources: resources,
      );
      expect(t3second, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // towers accessor
  // ---------------------------------------------------------------------------

  group('TowerPlacementEngine — towers list', () {
    test('towers is empty initially', () {
      expect(engine.towers, isEmpty);
    });

    test('towers updates after build and sell', () {
      final t = engine.buildTower(
        positionId: 'pos_0',
        towerDefId: 'rifle_t1',
        resources: resources,
      )!;
      expect(engine.towers, hasLength(1));

      engine.sellTower(towerId: t.id, resources: resources);
      expect(engine.towers, isEmpty);
    });
  });
}
