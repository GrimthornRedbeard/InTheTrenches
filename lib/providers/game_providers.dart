import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/difficulty_config.dart';
import '../config/era_registry.dart';
import '../config/game_constants.dart';
import '../config/map_data.dart';
import '../engine/combat_engine.dart';
import '../engine/game_loop.dart';
import '../engine/resource_manager.dart';
import '../engine/scoring.dart';
import '../engine/tower_placement_engine.dart';
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

  // -- State --
  GameState state;
  List<EnemyInstance> enemies = [];
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

    // 1. Spawn enemies
    if (_waveSpawner != null) {
      final spawned = _waveSpawner!.tick(dt);
      enemies = [...enemies, ...spawned];
    }

    // 2. Move enemies — 2D movement engine (Task 3) will replace this stub.
    // For now enemies remain at their spawned position until the movement
    // engine is wired up.

    // 3. Handle enemies reaching base — stub until movement engine is added.

    // 4. Combat
    final combatResult = combatEngine.tick(
      deltaTime: dt,
      towers: state.towers,
      enemies: enemies,
      map: gameMap,
      towerLookup: towerLookup,
      enemyRewards: enemyRewards,
    );
    enemies = combatResult.updatedEnemies;
    lastFireEvents = combatResult.fireEvents;

    // Track damaged enemies for flash effect
    recentlyDamagedEnemies = {};
    for (final event in combatResult.fireEvents) {
      recentlyDamagedEnemies.add(event.enemyId);
    }

    // 5. Award gold for kills
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

    // 6. Check defeat
    if (loopState.isGameOver) {
      state = state.copyWith(phase: GamePhase.defeat);
      _showBanner('DEFEAT');
      notifyListeners();
      return;
    }

    // 7. Check wave complete
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
