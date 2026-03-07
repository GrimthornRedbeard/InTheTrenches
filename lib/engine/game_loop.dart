import 'package:equatable/equatable.dart';

import '../models/enemy_instance.dart';

/// Immutable state for the game loop's base HP tracker.
class GameLoopState extends Equatable {
  /// Remaining base hit points.
  final int baseHp;

  /// Maximum base hit points (used for star calculation).
  final int maxBaseHp;

  /// Whether this is a victory state (all waves cleared with HP > 0).
  final bool isVictory;

  const GameLoopState({
    required this.baseHp,
    required this.maxBaseHp,
    this.isVictory = false,
  });

  /// Whether the game is over (base HP reached 0).
  bool get isGameOver => baseHp <= 0;

  GameLoopState copyWith({int? baseHp, int? maxBaseHp, bool? isVictory}) {
    return GameLoopState(
      baseHp: baseHp ?? this.baseHp,
      maxBaseHp: maxBaseHp ?? this.maxBaseHp,
      isVictory: isVictory ?? this.isVictory,
    );
  }

  @override
  List<Object?> get props => [baseHp, maxBaseHp, isVictory];
}

/// Pure-static functions for the game loop's win/lose detection.
///
/// All methods are side-effect-free: they take state and return new state.
class GameLoop {
  GameLoop._();

  // ---------------------------------------------------------------------------
  // Base HP damage
  // ---------------------------------------------------------------------------

  /// Returns a new [GameLoopState] after subtracting [damage] from base HP.
  ///
  /// Base HP is clamped to a minimum of 0.
  static GameLoopState applyBaseHpDamage({
    required GameLoopState state,
    required int damage,
  }) {
    final newHp = (state.baseHp - damage).clamp(0, state.maxBaseHp);
    return state.copyWith(baseHp: newHp);
  }

  // ---------------------------------------------------------------------------
  // Wave completion
  // ---------------------------------------------------------------------------

  /// Returns `true` when the current wave is fully resolved.
  ///
  /// A wave is complete when:
  /// 1. All enemies have been spawned ([allSpawned] is `true`), AND
  /// 2. All spawned enemies are dead (no alive enemies remain in [enemies]).
  static bool isWaveComplete({
    required List<EnemyInstance> enemies,
    required bool allSpawned,
  }) {
    if (!allSpawned) return false;
    return enemies.every((e) => !e.alive);
  }

  // ---------------------------------------------------------------------------
  // Win / lose evaluation
  // ---------------------------------------------------------------------------

  /// Evaluates whether the game should transition to a win or continue.
  ///
  /// Returns a new [GameLoopState] with [isVictory] set if:
  /// - [currentWave] == [totalWaves],
  /// - [waveComplete] is `true`, and
  /// - base HP is still positive.
  ///
  /// If base HP is 0, the returned state reflects game-over (no victory).
  static GameLoopState evaluateWin({
    required GameLoopState state,
    required int currentWave,
    required int totalWaves,
    required bool waveComplete,
  }) {
    // Game over takes precedence.
    if (state.isGameOver) return state;

    // Win condition: final wave cleared.
    if (currentWave >= totalWaves && waveComplete) {
      return state.copyWith(isVictory: true);
    }

    return state;
  }
}
