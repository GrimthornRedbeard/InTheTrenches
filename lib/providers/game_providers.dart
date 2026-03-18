import 'dart:async';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/difficulty_config.dart';
import '../config/era_registry.dart';
import '../config/game_constants.dart';
import '../config/map_data.dart';
import '../engine/breach_engine.dart';
import '../engine/combat_engine.dart';
import '../engine/game_loop.dart';
import '../engine/resource_manager.dart';
import '../engine/scoring.dart';
import '../engine/steering_engine.dart';
import '../engine/tower_placement_engine.dart';
import '../engine/trench_engine.dart';
import '../engine/wave_spawner.dart';
import '../models/models.dart';

// ---------------------------------------------------------------------------
// Game configuration — set before starting a game
// ---------------------------------------------------------------------------

/// Selected era ID (default: 'wwi').
final selectedEraProvider = StateProvider<String>((ref) => 'wwi');

/// Selected difficulty.
final selectedDifficultyProvider =
    StateProvider<Difficulty>((ref) => Difficulty.normal);

/// Selected map ID (default: first WWI map).
final selectedMapProvider = StateProvider<String>((ref) => 'wwi_somme');

// ---------------------------------------------------------------------------
// Game speed
// ---------------------------------------------------------------------------

enum GameSpeed { paused, normal, fast }

final gameSpeedProvider = StateProvider<GameSpeed>((ref) => GameSpeed.normal);

// ---------------------------------------------------------------------------
// Main game controller
// ---------------------------------------------------------------------------

/// The runtime game controller that owns all engine instances and the
/// mutable game state. Created when the player hits "Deploy!".
class GameController extends ChangeNotifier {
  // -- Configuration --
  final GameMap gameMap;
  final Era era;
  final DifficultyConfig difficulty;

  // -- Engine instances --
  late final ResourceManager resources;
  late final TowerPlacementEngine placementEngine;
  late final CombatEngine combatEngine;
  late final SteeringEngine steeringEngine;

  // -- State --
  GameState state;
  List<EnemyInstance> enemies = [];
  List<TrenchSegment> trenchSegments = [];
  WaveSpawner? _waveSpawner;
  GameLoopState loopState;
  Timer? _timer;

  // -- Tower lookup maps --
  late final Map<String, TowerDefinition> towerLookup;
  late final Map<String, int> enemyRewards;
  late final Map<String, EnemyDefinition> enemyLookup;

  // -- Visual state --
  List<FireEvent> lastFireEvents = [];
  Set<String> recentlyDamagedEnemies = {};
  String? waveBannerText;
  DateTime? waveBannerTime;

  // -- Speed --
  GameSpeed speed = GameSpeed.normal;

  // -- Wave data (generated) --
  late final List<Wave> waves;

  GameController({
    required this.gameMap,
    required this.era,
    required this.difficulty,
  })  : state = GameState(
          gold: difficulty
              .adjustedStartingGold(GameConstants.startingGold),
          lives: GameConstants.startingLives,
          currentWave: 0,
          eraId: era.id,
          mapId: gameMap.id,
          phase: GamePhase.building,
          towers: const [],
        ),
        loopState = GameLoopState(
          baseHp: GameConstants.startingLives,
          maxBaseHp: GameConstants.startingLives,
        ) {
    // Build lookup maps
    towerLookup = {for (final t in era.towers) t.id: t};
    enemyLookup = {
      for (final e in era.enemies) e.id: difficulty.applyToEnemy(e)
    };
    enemyRewards = {for (final e in era.enemies) e.id: e.reward};

    // Create engines
    resources = ResourceManager(startingGold: state.gold);
    placementEngine = TowerPlacementEngine(
      map: gameMap,
      towerLookup: towerLookup,
    );
    combatEngine = CombatEngine();
    steeringEngine = SteeringEngine();

    // Initialise live trench segment state from the map definition
    trenchSegments = List<TrenchSegment>.from(gameMap.trenchSegments);

    // Generate waves
    waves = _generateWaves();
  }

  List<Wave> _generateWaves() {
    final enemyIds = era.enemies.map((e) => e.id).toList();
    final waveList = <Wave>[];
    for (int i = 1; i <= gameMap.waveCount; i++) {
      final groups = <WaveGroup>[];
      // Base count scales with wave number
      final baseCount = 3 + i * 2;
      final adjustedCount = difficulty.adjustedEnemyCount(baseCount);

      // Pick enemy types based on wave number
      if (i <= 3) {
        // Early waves: basic infantry
        groups.add(WaveGroup(
          enemyId: enemyIds[0], // infantry
          count: adjustedCount,
          delayBetween: 1.0,
        ));
      } else if (i <= 6) {
        // Mid waves: mix of infantry and runners
        groups.add(WaveGroup(
          enemyId: enemyIds[0],
          count: (adjustedCount * 0.6).ceil(),
          delayBetween: 1.0,
        ));
        final secondIdx = (i - 3).clamp(0, enemyIds.length - 1);
        groups.add(WaveGroup(
          enemyId: enemyIds[secondIdx],
          count: (adjustedCount * 0.4).ceil(),
          delayBetween: 0.8,
        ));
      } else {
        // Late waves: mix of three types
        groups.add(WaveGroup(
          enemyId: enemyIds[0],
          count: (adjustedCount * 0.4).ceil(),
          delayBetween: 0.8,
        ));
        final secondIdx = ((i - 4) % (enemyIds.length - 1)) + 1;
        groups.add(WaveGroup(
          enemyId: enemyIds[secondIdx],
          count: (adjustedCount * 0.3).ceil(),
          delayBetween: 0.7,
        ));
        final thirdIdx = ((i - 2) % (enemyIds.length - 1)) + 1;
        groups.add(WaveGroup(
          enemyId: enemyIds[thirdIdx],
          count: (adjustedCount * 0.3).ceil(),
          delayBetween: 0.6,
        ));
      }

      waveList.add(Wave(
        number: i,
        groups: groups,
        bonusReward: 10 + i * 5,
      ));
    }
    return waveList;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the index of the trench segment with the lowest breach HP, using
  /// the live [trenchSegments] state rather than the immutable map definition.
  int _currentWeakestSegmentIndex() => gameMap
      .copyWith(trenchSegments: trenchSegments)
      .weakestSegmentIndex;

  // ---------------------------------------------------------------------------
  // Game loop
  // ---------------------------------------------------------------------------

  void startGameLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (speed == GameSpeed.paused) return;
      final ticks = speed == GameSpeed.fast ? 2 : 1;
      for (int i = 0; i < ticks; i++) {
        _tick(0.016);
      }
    });
  }

  void stopGameLoop() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick(double dt) {
    if (state.phase == GamePhase.victory ||
        state.phase == GamePhase.defeat) {
      return;
    }

    if (state.phase != GamePhase.waveActive) return;

    // 1. Spawn enemies — enrich each new enemy with a world position and a
    //    target segment so the steering engine can guide them.
    if (_waveSpawner != null) {
      final spawned = _waveSpawner!.tick(dt);
      if (spawned.isNotEmpty) {
        final weakIdx = _currentWeakestSegmentIndex();
        final enriched = spawned.map((e) {
          final spawnX = gameMap.spawnX(
            0.1 + 0.8 * (enemies.length % 5) / 5.0,
          );
          return e.copyWith(
            position: Offset(spawnX, gameMap.spawnZoneY),
            targetSegmentIndex: weakIdx,
          );
        }).toList();
        enemies = [...enemies, ...enriched];
      }
    }

    // 2. Steering tick — moves ADVANCING and CROSSED enemies in 2D.
    //    BREACHING and IN_TRENCH enemies are handled by BreachEngine below.
    final steeringResult = steeringEngine.tick(dt, enemies, gameMap);
    enemies = steeringResult.updatedEnemies;

    // 3. Handle enemies that reached the command post — deal base HP damage
    //    and mark them as dead so they are excluded from further processing.
    for (int i = 0; i < steeringResult.reachedCommandPost.length; i++) {
      loopState = GameLoop.applyBaseHpDamage(
        state: loopState,
        damage: 1,
      );
    }

    // 4. Breach phase — BREACHING enemies drain segment breach HP;
    //    IN_TRENCH enemies take melee damage and can be killed for gold.
    final breachResult = BreachEngine.tick(
      dt: dt,
      enemies: enemies,
      segments: trenchSegments,
      enemyRewards: enemyRewards,
    );
    enemies = breachResult.updatedEnemies;
    trenchSegments = breachResult.updatedSegments;

    // 5. Award gold from breach kills (enemies killed in the trench).
    if (breachResult.goldAwarded > 0) {
      resources.earn(breachResult.goldAwarded);
      state = state.copyWith(gold: resources.gold);
    }

    // 6. Update segment states (held → contested → breached) based on
    //    current breach HP values.
    trenchSegments = TrenchEngine.updateSegmentStates(trenchSegments);

    // 7. Collapse any newly breached segments.
    trenchSegments = trenchSegments.map((seg) {
      if (seg.state == TrenchSegmentState.breached) {
        return TrenchEngine.collapseSegment(seg);
      }
      return seg;
    }).toList();

    // 8. Defeat check — if all trench segments have collapsed, the trench
    //    line is lost and the player loses immediately.
    final allCollapsed = trenchSegments
        .every((s) => s.state == TrenchSegmentState.collapsed);
    if (allCollapsed && trenchSegments.isNotEmpty) {
      state = state.copyWith(phase: GamePhase.defeat);
      _showBanner('DEFEAT');
      notifyListeners();
      return;
    }

    // 9. Ranged combat — towers only fire at ADVANCING enemies (they cannot
    //    target enemies inside the trench or past it).
    final advancingEnemies = enemies
        .where((e) => e.alive && e.movementState == EnemyMovementState.advancing)
        .toList();

    // Build a map from ID → index in the full enemy list for the merge step.
    final enemyIndexById = <String, int>{};
    for (int i = 0; i < enemies.length; i++) {
      enemyIndexById[enemies[i].id] = i;
    }

    final combatResult = combatEngine.tick(
      deltaTime: dt,
      towers: state.towers,
      enemies: advancingEnemies,
      map: gameMap,
      towerLookup: towerLookup,
      enemyRewards: enemyRewards,
    );

    // Merge updated advancing enemies back into the full list.
    final mergedEnemies = List<EnemyInstance>.from(enemies);
    for (final updated in combatResult.updatedEnemies) {
      final idx = enemyIndexById[updated.id];
      if (idx != null) {
        mergedEnemies[idx] = updated;
      }
    }
    enemies = mergedEnemies;

    lastFireEvents = combatResult.fireEvents;

    // Track damaged enemies for flash effect
    recentlyDamagedEnemies = {};
    for (final event in combatResult.fireEvents) {
      recentlyDamagedEnemies.add(event.enemyId);
    }

    // 10. Award gold for ranged kills
    if (combatResult.goldAwarded > 0) {
      resources.earn(combatResult.goldAwarded);
      state = state.copyWith(gold: resources.gold);
    }

    // Mark killed enemies in wave spawner
    for (final event in combatResult.fireEvents) {
      final enemy = enemies.firstWhere(
        (e) => e.id == event.enemyId,
        orElse: () => enemies.first,
      );
      if (!enemy.alive) {
        _waveSpawner?.markEnemyKilled(event.enemyId);
      }
    }

    // 11. Check base HP defeat (enemies reached command post)
    if (loopState.isGameOver) {
      state = state.copyWith(phase: GamePhase.defeat);
      _showBanner('DEFEAT');
      notifyListeners();
      return;
    }

    // 12. Check wave complete
    final allSpawned = _waveSpawner?.allSpawned ?? false;
    final waveComplete = GameLoop.isWaveComplete(
      enemies: enemies,
      allSpawned: allSpawned,
    );

    if (waveComplete) {
      // Award wave bonus
      if (state.currentWave <= waves.length) {
        final waveIdx = state.currentWave - 1;
        if (waveIdx >= 0 && waveIdx < waves.length) {
          resources.earn(waves[waveIdx].bonusReward);
          state = state.copyWith(gold: resources.gold);
        }
      }

      // Check victory
      loopState = GameLoop.evaluateWin(
        state: loopState,
        currentWave: state.currentWave,
        totalWaves: gameMap.waveCount,
        waveComplete: true,
      );

      if (loopState.isVictory) {
        state = state.copyWith(phase: GamePhase.victory);
        _showBanner('VICTORY!');
      } else {
        state = state.copyWith(phase: GamePhase.waveComplete);
        _showBanner('Wave ${state.currentWave} Complete!');
        // Auto-advance to building phase
        Future.delayed(const Duration(seconds: 2), () {
          if (state.phase == GamePhase.waveComplete) {
            state = state.copyWith(phase: GamePhase.building);
            notifyListeners();
          }
        });
      }
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Wave control
  // ---------------------------------------------------------------------------

  void sendWave() {
    if (state.phase != GamePhase.building &&
        state.phase != GamePhase.waveComplete) {
      return;
    }

    final nextWave = state.currentWave + 1;
    if (nextWave > gameMap.waveCount) return;

    // Clear dead enemies from previous wave
    enemies = enemies.where((e) => e.alive).toList();

    state = state.copyWith(
      currentWave: nextWave,
      phase: GamePhase.waveActive,
    );

    _waveSpawner = WaveSpawner(
      wave: waves[nextWave - 1],
      enemyLookup: enemyLookup,
    );
    _waveSpawner!.start();

    _showBanner('Wave $nextWave incoming!');
    combatEngine.resetCooldowns();

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Tower placement
  // ---------------------------------------------------------------------------

  PlacedTower? buildTower(String positionId, String towerDefId) {
    final tower = placementEngine.buildTower(
      positionId: positionId,
      towerDefId: towerDefId,
      resources: resources,
    );
    if (tower != null) {
      state = state.copyWith(
        towers: placementEngine.towers,
        gold: resources.gold,
      );
      notifyListeners();
    }
    return tower;
  }

  void sellTower(String towerId) {
    placementEngine.sellTower(towerId: towerId, resources: resources);
    state = state.copyWith(
      towers: placementEngine.towers,
      gold: resources.gold,
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Banner
  // ---------------------------------------------------------------------------

  void _showBanner(String text) {
    waveBannerText = text;
    waveBannerTime = DateTime.now();
  }

  bool get shouldShowBanner {
    if (waveBannerText == null || waveBannerTime == null) return false;
    return DateTime.now().difference(waveBannerTime!).inSeconds < 3;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Whether a placement slot is occupied.
  bool isSlotOccupied(String positionId) {
    return state.towers.any((t) {
      final pos = gameMap.placements.firstWhere(
        (p) => p.id == positionId,
        orElse: () => const PlacementPosition(id: '', x: -1, y: -1, zone: PlacementZone.behindTrench),
      );
      return (t.x - pos.x).abs() < 1 && (t.y - pos.y).abs() < 1;
    });
  }

  PlacedTower? getTowerAtSlot(String positionId) {
    final pos = gameMap.placements.firstWhere(
      (p) => p.id == positionId,
      orElse: () => const PlacementPosition(id: '', x: -1, y: -1, zone: PlacementZone.behindTrench),
    );
    try {
      return state.towers.firstWhere(
        (t) => (t.x - pos.x).abs() < 1 && (t.y - pos.y).abs() < 1,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    stopGameLoop();
    super.dispose();
  }
}

/// The main game controller provider. Created fresh each game session.
final gameControllerProvider =
    ChangeNotifierProvider.autoDispose<GameController>((ref) {
  final eraId = ref.read(selectedEraProvider);
  final difficulty = ref.read(selectedDifficultyProvider);
  final mapId = ref.read(selectedMapProvider);

  final era = EraRegistry.getEra(eraId)!;
  final gameMap = MapData.getMap(mapId)!;
  final diffConfig = DifficultyConfig.fromDifficulty(difficulty);

  final controller = GameController(
    gameMap: gameMap,
    era: era,
    difficulty: diffConfig,
  );
  controller.startGameLoop();

  return controller;
});
