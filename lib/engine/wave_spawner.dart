import '../models/enemy.dart';
import '../models/enemy_instance.dart';
import '../models/wave.dart';
import '../models/wave_group.dart';

/// The current state of a wave.
enum WaveState { pending, active, complete }

/// Pure-logic engine that manages enemy spawning from [Wave] definitions.
///
/// Creates [EnemyInstance]s at timed intervals according to [WaveGroup]
/// definitions, tracks wave progress and completion.
///
/// Groups spawn **sequentially**: group 2 starts only after all enemies in
/// group 1 have been spawned. Within a group, the first enemy spawns
/// immediately, then [WaveGroup.delayBetween] seconds between subsequent
/// spawns.
///
/// This class is pure game logic with no widget dependencies.
class WaveSpawner {
  /// The wave definition this spawner is executing.
  final Wave wave;

  /// Lookup table mapping enemy IDs to their definitions.
  /// Passed in so tests can provide test data without depending on EraRegistry.
  final Map<String, EnemyDefinition> enemyLookup;

  WaveState _state = WaveState.pending;

  /// Index of the current group being spawned.
  int _currentGroupIndex = 0;

  /// Number of enemies spawned so far in the current group.
  int _spawnedInCurrentGroup = 0;

  /// Accumulated time since the last spawn in the current group.
  double _timeSinceLastSpawn = 0.0;

  /// Global incrementing counter for unique enemy IDs.
  int _globalSpawnCounter = 0;

  /// Total number of enemies spawned across all groups so far.
  int _totalSpawned = 0;

  /// Number of enemies killed so far.
  int _killedCount = 0;

  /// Whether the very first enemy of the current group needs to spawn
  /// immediately (without waiting for a delay).
  bool _needsImmediateSpawn = false;

  WaveSpawner({
    required this.wave,
    required this.enemyLookup,
  });

  /// The current state of the wave.
  WaveState get state {
    if (_state == WaveState.active && waveComplete) {
      return WaveState.complete;
    }
    return _state;
  }

  /// Transition from [WaveState.pending] to [WaveState.active].
  ///
  /// Throws a [StateError] if the wave is not in the pending state.
  void start() {
    if (_state != WaveState.pending) {
      throw StateError('Cannot start wave: current state is $_state');
    }
    _state = WaveState.active;
    _needsImmediateSpawn = true;
  }

  /// Advance timers by [deltaTime] seconds and return any newly spawned
  /// enemies.
  ///
  /// Returns an empty list if the wave is not active or all enemies have
  /// already been spawned.
  List<EnemyInstance> tick(double deltaTime) {
    if (_state == WaveState.pending) return [];
    if (allSpawned) return [];

    final spawned = <EnemyInstance>[];

    _timeSinceLastSpawn += deltaTime;

    while (!allSpawned) {
      final group = _currentGroup;
      if (group == null) break;

      if (_needsImmediateSpawn) {
        // First enemy in the group spawns immediately.
        // Note: _spawnEnemy may set _needsImmediateSpawn = true again
        // if this was the only enemy in the group (triggering the next
        // group). We must NOT blindly reset it after the spawn.
        _needsImmediateSpawn = false;
        spawned.add(_spawnEnemy(group));
        continue;
      }

      // Check if enough time has passed to spawn the next enemy.
      if (_timeSinceLastSpawn >= group.delayBetween) {
        _timeSinceLastSpawn -= group.delayBetween;
        spawned.add(_spawnEnemy(group));
      } else {
        // Not enough time accumulated; wait for the next tick.
        break;
      }
    }

    // Update state if wave is now complete.
    if (waveComplete) {
      _state = WaveState.complete;
    }

    return spawned;
  }

  /// Mark an enemy as killed by its [enemyId].
  ///
  /// Increments the kill counter and updates wave state if complete.
  void markEnemyKilled(String enemyId) {
    _killedCount++;
    if (waveComplete) {
      _state = WaveState.complete;
    }
  }

  /// Whether all enemies from all groups have been spawned.
  bool get allSpawned => _totalSpawned >= totalEnemies;

  /// Whether the wave is complete: all enemies spawned and all that have
  /// spawned are accounted for (killed).
  bool get waveComplete => allSpawned && remainingEnemies == 0;

  /// Number of enemies still alive (spawned but not yet killed).
  int get remainingEnemies => _totalSpawned - _killedCount;

  /// Total number of enemies across all groups in the wave.
  int get totalEnemies {
    var total = 0;
    for (final group in wave.groups) {
      total += group.count;
    }
    return total;
  }

  /// Number of enemies killed so far.
  int get killedCount => _killedCount;

  /// The current group being spawned, or null if all groups are done.
  WaveGroup? get _currentGroup {
    if (_currentGroupIndex >= wave.groups.length) return null;
    return wave.groups[_currentGroupIndex];
  }

  /// Spawns a single enemy from the given [group] and advances counters.
  EnemyInstance _spawnEnemy(WaveGroup group) {
    final definition = enemyLookup[group.enemyId];
    if (definition == null) {
      throw StateError(
        'Enemy definition not found for id: ${group.enemyId}',
      );
    }

    final id = 'enemy_$_globalSpawnCounter';
    _globalSpawnCounter++;
    _totalSpawned++;
    _spawnedInCurrentGroup++;

    final instance = EnemyInstance.fromDefinition(
      id: id,
      definition: definition,
    );

    // Check if the current group is fully spawned.
    if (_spawnedInCurrentGroup >= group.count) {
      _currentGroupIndex++;
      _spawnedInCurrentGroup = 0;
      // Carry over accumulated time surplus to the next group so that
      // large deltaTime values correctly spawn across group boundaries.
      // Next group's first enemy spawns immediately.
      if (_currentGroupIndex < wave.groups.length) {
        _needsImmediateSpawn = true;
      }
    }

    return instance;
  }
}
