import '../models/models.dart';

/// Static registry of all eras and their content.
///
/// Contains the complete definitions for all launch eras: WWI and Medieval.
/// This serves as the single source of truth for tower and enemy definitions.
class EraRegistry {
  EraRegistry._();

  // ---------------------------------------------------------------------------
  // WWI Era
  // ---------------------------------------------------------------------------

  static const wwi = Era(
    id: 'wwi',
    name: 'World War I',
    description: 'The Great War: trenches, rifles, and mortar fire.',
    mapCount: 5,
    towers: wwiTowers,
    enemies: wwiEnemies,
  );

  static const wwiTowers = [
    TowerDefinition(
      id: 'wwi_rifleman',
      name: 'Rifleman',
      eraId: 'wwi',
      tier: 1,
      cost: 50,
      range: 3.0,
      damage: 10,
      attackSpeed: 1.0,
      description: 'Standard infantry with a bolt-action rifle.',
      category: TowerCategory.damage,
    ),
    TowerDefinition(
      id: 'wwi_mortar',
      name: 'Mortar',
      eraId: 'wwi',
      tier: 1,
      cost: 100,
      range: 4.0,
      damage: 25,
      attackSpeed: 0.5,
      description: 'Explosive shells rain down on clustered enemies.',
      category: TowerCategory.area,
    ),
    TowerDefinition(
      id: 'wwi_barbed_wire',
      name: 'Barbed Wire',
      eraId: 'wwi',
      tier: 1,
      cost: 30,
      range: 2.0,
      damage: 2,
      attackSpeed: 0.0,
      description: 'Tangles of wire that slow and damage passing enemies.',
      category: TowerCategory.slow,
    ),
  ];

  static const wwiEnemies = [
    EnemyDefinition(
      id: 'wwi_infantry',
      name: 'Infantry',
      eraId: 'wwi',
      hp: 100,
      speed: 1.0,
      armor: 0,
      reward: 10,
      description: 'Basic foot soldier advancing across no man\'s land.',
    ),
    EnemyDefinition(
      id: 'wwi_runner',
      name: 'Runner',
      eraId: 'wwi',
      hp: 60,
      speed: 2.0,
      armor: 0,
      reward: 15,
      description: 'Fast messenger who sprints through the battlefield.',
    ),
    EnemyDefinition(
      id: 'wwi_shield_bearer',
      name: 'Shield Bearer',
      eraId: 'wwi',
      hp: 150,
      speed: 0.8,
      armor: 5,
      reward: 20,
      description: 'Carries a metal shield that absorbs incoming fire.',
    ),
    EnemyDefinition(
      id: 'wwi_officer',
      name: 'Officer',
      eraId: 'wwi',
      hp: 120,
      speed: 1.0,
      armor: 2,
      reward: 25,
      ability: EnemyAbility.buff,
      description: 'Commands nearby troops, boosting their effectiveness.',
    ),
    EnemyDefinition(
      id: 'wwi_medic',
      name: 'Medic',
      eraId: 'wwi',
      hp: 80,
      speed: 1.0,
      armor: 0,
      reward: 30,
      ability: EnemyAbility.heal,
      description: 'Heals wounded soldiers as they advance.',
    ),
    EnemyDefinition(
      id: 'wwi_sapper',
      name: 'Sapper',
      eraId: 'wwi',
      hp: 90,
      speed: 1.2,
      armor: 0,
      reward: 20,
      ability: EnemyAbility.sap,
      description: 'Explosives expert who disables defenses.',
    ),
    EnemyDefinition(
      id: 'wwi_heavy',
      name: 'Heavy',
      eraId: 'wwi',
      hp: 250,
      speed: 0.6,
      armor: 8,
      reward: 35,
      description: 'Heavily armored soldier that absorbs tremendous damage.',
    ),
    EnemyDefinition(
      id: 'wwi_elite',
      name: 'Elite',
      eraId: 'wwi',
      hp: 200,
      speed: 1.0,
      armor: 5,
      reward: 50,
      description: 'Veteran stormtrooper with superior training and gear.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Medieval Era
  // ---------------------------------------------------------------------------

  static const medieval = Era(
    id: 'medieval',
    name: 'Medieval',
    description: 'Castle defense: archers, catapults, and siege warfare.',
    mapCount: 5,
    towers: medievalTowers,
    enemies: medievalEnemies,
  );

  static const medievalTowers = [
    TowerDefinition(
      id: 'med_archer',
      name: 'Archer',
      eraId: 'medieval',
      tier: 1,
      cost: 40,
      range: 3.5,
      damage: 8,
      attackSpeed: 1.2,
      description: 'Longbow archer with rapid fire from the ramparts.',
      category: TowerCategory.damage,
    ),
    TowerDefinition(
      id: 'med_catapult',
      name: 'Catapult',
      eraId: 'medieval',
      tier: 1,
      cost: 120,
      range: 5.0,
      damage: 30,
      attackSpeed: 0.3,
      description: 'Hurls boulders that crush groups of enemies.',
      category: TowerCategory.area,
    ),
    TowerDefinition(
      id: 'med_spike_trap',
      name: 'Spike Trap',
      eraId: 'medieval',
      tier: 1,
      cost: 25,
      range: 1.5,
      damage: 5,
      attackSpeed: 0.0,
      description: 'Hidden spikes that slow and wound passing enemies.',
      category: TowerCategory.slow,
    ),
  ];

  static const medievalEnemies = [
    EnemyDefinition(
      id: 'med_peasant',
      name: 'Peasant',
      eraId: 'medieval',
      hp: 80,
      speed: 1.0,
      armor: 0,
      reward: 8,
      description: 'Conscripted villager armed with simple tools.',
    ),
    EnemyDefinition(
      id: 'med_swordsman',
      name: 'Swordsman',
      eraId: 'medieval',
      hp: 120,
      speed: 1.0,
      armor: 3,
      reward: 15,
      description: 'Trained soldier with sword and light armor.',
    ),
    EnemyDefinition(
      id: 'med_shield_wall',
      name: 'Shield Wall',
      eraId: 'medieval',
      hp: 180,
      speed: 0.7,
      armor: 8,
      reward: 25,
      ability: EnemyAbility.shield,
      description: 'Formation of soldiers behind interlocking shields.',
    ),
    EnemyDefinition(
      id: 'med_knight',
      name: 'Knight',
      eraId: 'medieval',
      hp: 200,
      speed: 0.9,
      armor: 5,
      reward: 30,
      ability: EnemyAbility.buff,
      description: 'Armored noble who inspires nearby troops.',
    ),
    EnemyDefinition(
      id: 'med_battering_ram',
      name: 'Battering Ram',
      eraId: 'medieval',
      hp: 300,
      speed: 0.4,
      armor: 10,
      reward: 40,
      ability: EnemyAbility.siege,
      description: 'Massive ram designed to breach fortifications.',
    ),
    EnemyDefinition(
      id: 'med_cavalry',
      name: 'Cavalry',
      eraId: 'medieval',
      hp: 150,
      speed: 2.0,
      armor: 2,
      reward: 35,
      description: 'Mounted warriors who charge at high speed.',
    ),
    EnemyDefinition(
      id: 'med_healer_monk',
      name: 'Healer Monk',
      eraId: 'medieval',
      hp: 90,
      speed: 1.0,
      armor: 0,
      reward: 30,
      ability: EnemyAbility.heal,
      description: 'Holy monk who mends the wounds of fellow attackers.',
    ),
    EnemyDefinition(
      id: 'med_siege_tower',
      name: 'Siege Tower',
      eraId: 'medieval',
      hp: 400,
      speed: 0.3,
      armor: 12,
      reward: 60,
      description: 'Massive mobile tower that delivers soldiers over walls.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Registry Access
  // ---------------------------------------------------------------------------

  /// All available eras in the game.
  static const List<Era> allEras = [wwi, medieval];

  /// Look up an era by its ID. Returns null if not found.
  static Era? getEra(String id) {
    for (final era in allEras) {
      if (era.id == id) return era;
    }
    return null;
  }

  /// Look up a tower definition by its ID across all eras.
  static TowerDefinition? getTower(String id) {
    for (final era in allEras) {
      for (final tower in era.towers) {
        if (tower.id == id) return tower;
      }
    }
    return null;
  }

  /// Look up an enemy definition by its ID across all eras.
  static EnemyDefinition? getEnemy(String id) {
    for (final era in allEras) {
      for (final enemy in era.enemies) {
        if (enemy.id == id) return enemy;
      }
    }
    return null;
  }
}
