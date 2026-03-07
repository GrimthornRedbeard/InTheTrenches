import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'enemy_instance.dart';

/// The kind of status effect that can be applied to an enemy.
enum StatusEffectType {
  /// Reduces the enemy's effective movement speed.
  slow,

  /// Deals periodic damage (damage-over-time).
  dot,

  /// Reduces the enemy's armor value.
  armorReduction,
}

/// An active status effect applied to an enemy.
///
/// Immutable — use [copyWith] to produce updated versions each tick.
class StatusEffect extends Equatable {
  /// What kind of effect this is.
  final StatusEffectType type;

  /// Effect magnitude:
  /// - [StatusEffectType.slow]: fraction of speed removed (0.0–1.0).
  /// - [StatusEffectType.dot]: damage per tick.
  /// - [StatusEffectType.armorReduction]: flat armor reduction.
  final double magnitude;

  /// Remaining duration in seconds. When this reaches 0 the effect expires.
  final double duration;

  /// For DoT effects: seconds between damage ticks.
  /// 0.0 for non-DoT effects.
  final double tickInterval;

  /// Accumulated time since the last DoT tick.
  final double _timeSinceTick;

  const StatusEffect({
    required this.type,
    required this.magnitude,
    required this.duration,
    required this.tickInterval,
    double timeSinceTick = 0.0,
  }) : _timeSinceTick = timeSinceTick;

  StatusEffect copyWith({
    StatusEffectType? type,
    double? magnitude,
    double? duration,
    double? tickInterval,
    double? timeSinceTick,
  }) {
    return StatusEffect(
      type: type ?? this.type,
      magnitude: magnitude ?? this.magnitude,
      duration: duration ?? this.duration,
      tickInterval: tickInterval ?? this.tickInterval,
      timeSinceTick: timeSinceTick ?? _timeSinceTick,
    );
  }

  @override
  List<Object?> get props => [
    type,
    magnitude,
    duration,
    tickInterval,
    _timeSinceTick,
  ];
}

/// Pure-static helpers for applying and ticking status effects.
class StatusEffectManager {
  StatusEffectManager._();

  // ---------------------------------------------------------------------------
  // Speed modification
  // ---------------------------------------------------------------------------

  /// Computes the effective movement speed of [enemy] after all [effects] are applied.
  ///
  /// Only [StatusEffectType.slow] effects modify speed.
  /// The strongest slow wins — effects do not stack additively.
  static double applyEffectiveSpeed(
    EnemyInstance enemy,
    List<StatusEffect> effects,
  ) {
    final slows = effects.where((e) => e.type == StatusEffectType.slow);
    if (slows.isEmpty) return enemy.speed;

    // Use the largest slow magnitude.
    final maxSlow = slows.map((e) => e.magnitude).reduce(math.max);
    return enemy.speed * (1.0 - maxSlow);
  }

  // ---------------------------------------------------------------------------
  // Effect merging (prevent duplicate stacking)
  // ---------------------------------------------------------------------------

  /// Merges [incoming] effects with [existing] ones, preventing duplicate stacking.
  ///
  /// For each type, keeps the one with the longer remaining duration.
  /// Distinct types are additive (e.g., slow + DoT both apply).
  static List<StatusEffect> mergeEffects(List<StatusEffect> effects) {
    // Group by type and keep the one with the highest duration.
    final Map<StatusEffectType, StatusEffect> merged = {};
    for (final effect in effects) {
      final existing = merged[effect.type];
      if (existing == null || effect.duration > existing.duration) {
        merged[effect.type] = effect;
      }
    }
    return merged.values.toList();
  }

  // ---------------------------------------------------------------------------
  // Ticking
  // ---------------------------------------------------------------------------

  /// Advances all [effects] by [deltaTime] seconds and returns the surviving ones.
  ///
  /// Effects with `duration <= 0` after the tick are removed.
  static List<StatusEffect> tickEffects(
    List<StatusEffect> effects, {
    required double deltaTime,
  }) {
    final result = <StatusEffect>[];
    for (final effect in effects) {
      final newDuration = effect.duration - deltaTime;
      if (newDuration <= 0) continue; // expired
      result.add(effect.copyWith(duration: newDuration));
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // DoT damage calculation
  // ---------------------------------------------------------------------------

  /// Calculates the total DoT damage for [effect] over [deltaTime] seconds.
  ///
  /// Returns 0.0 if [effect] is not a DoT or fewer than one tick has elapsed.
  static double calculateDotDamage({
    required StatusEffect effect,
    required double deltaTime,
  }) {
    if (effect.type != StatusEffectType.dot) return 0.0;
    if (effect.tickInterval <= 0) return 0.0;

    final ticks = (deltaTime / effect.tickInterval).floor();
    return ticks * effect.magnitude;
  }
}
