import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/models/models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // StatusEffect model
  // ---------------------------------------------------------------------------

  group('StatusEffect — model', () {
    test('StatusEffect can be created with required fields', () {
      const effect = StatusEffect(
        type: StatusEffectType.slow,
        magnitude: 0.3,
        duration: 2.0,
        tickInterval: 0.0,
      );

      expect(effect.type, StatusEffectType.slow);
      expect(effect.magnitude, 0.3);
      expect(effect.duration, 2.0);
    });

    test('StatusEffect supports copyWith', () {
      const effect = StatusEffect(
        type: StatusEffectType.slow,
        magnitude: 0.3,
        duration: 2.0,
        tickInterval: 0.0,
      );

      final updated = effect.copyWith(duration: 1.0);
      expect(updated.duration, 1.0);
      expect(updated.type, StatusEffectType.slow);
    });

    test('StatusEffect equality via Equatable', () {
      const a = StatusEffect(
        type: StatusEffectType.dot,
        magnitude: 5.0,
        duration: 3.0,
        tickInterval: 1.0,
      );
      const b = StatusEffect(
        type: StatusEffectType.dot,
        magnitude: 5.0,
        duration: 3.0,
        tickInterval: 1.0,
      );
      expect(a, equals(b));
    });
  });

  // ---------------------------------------------------------------------------
  // StatusEffectType enum
  // ---------------------------------------------------------------------------

  group('StatusEffectType enum', () {
    test('all three effect types exist', () {
      expect(StatusEffectType.values, contains(StatusEffectType.slow));
      expect(StatusEffectType.values, contains(StatusEffectType.dot));
      expect(
        StatusEffectType.values,
        contains(StatusEffectType.armorReduction),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // StatusEffectManager — apply and tick
  // ---------------------------------------------------------------------------

  group('StatusEffectManager — apply effects', () {
    EnemyInstance makeEnemy({
      double currentHp = 100.0,
      double speed = 10.0,
      double armor = 5.0,
    }) {
      return EnemyInstance(
        id: 'enemy_0',
        definitionId: 'infantry',
        currentHp: currentHp,
        speed: speed,
        armor: armor,
        pathProgress: 0.5,
        alive: true,
      );
    }

    test('slow reduces enemy speed by magnitude', () {
      final enemy = makeEnemy(speed: 10.0);
      const slowEffect = StatusEffect(
        type: StatusEffectType.slow,
        magnitude: 0.5,
        duration: 2.0,
        tickInterval: 0.0,
      );

      final result = StatusEffectManager.applyEffectiveSpeed(enemy, [
        slowEffect,
      ]);
      // speed * (1.0 - 0.5) = 5.0
      expect(result, closeTo(5.0, 1e-10));
    });

    test('slow reduces enemy speed for duration', () {
      final enemy = makeEnemy(speed: 10.0);
      const slow = StatusEffect(
        type: StatusEffectType.slow,
        magnitude: 0.3,
        duration: 2.0,
        tickInterval: 0.0,
      );

      // Effective speed = 10 * (1 - 0.3) = 7.0
      expect(
        StatusEffectManager.applyEffectiveSpeed(enemy, [slow]),
        closeTo(7.0, 1e-10),
      );
    });

    test('no slow effects returns base speed', () {
      final enemy = makeEnemy(speed: 10.0);
      expect(
        StatusEffectManager.applyEffectiveSpeed(enemy, []),
        closeTo(10.0, 1e-10),
      );
    });

    test('stacking slow refreshes duration instead of doubling', () {
      // Two slow effects of magnitude 0.3 should not stack additively.
      // The stronger / newer one should win; speed still only reduced by 0.3.
      const slow1 = StatusEffect(
        type: StatusEffectType.slow,
        magnitude: 0.3,
        duration: 1.0,
        tickInterval: 0.0,
      );
      const slow2 = StatusEffect(
        type: StatusEffectType.slow,
        magnitude: 0.3,
        duration: 2.0, // refresh
        tickInterval: 0.0,
      );

      final merged = StatusEffectManager.mergeEffects([slow1, slow2]);
      // Should have exactly one slow effect after merge
      final slows = merged
          .where((e) => e.type == StatusEffectType.slow)
          .toList();
      expect(slows.length, 1);
      // Duration should be refreshed to 2.0 (max of the two)
      expect(slows.first.duration, 2.0);
    });
  });

  // ---------------------------------------------------------------------------
  // StatusEffectManager — tick
  // ---------------------------------------------------------------------------

  group('StatusEffectManager — tick', () {
    test('tick reduces duration by deltaTime', () {
      const slow = StatusEffect(
        type: StatusEffectType.slow,
        magnitude: 0.3,
        duration: 2.0,
        tickInterval: 0.0,
      );

      final ticked = StatusEffectManager.tickEffects([slow], deltaTime: 0.5);
      expect(ticked.first.duration, closeTo(1.5, 1e-10));
    });

    test('expired effects are removed', () {
      const slow = StatusEffect(
        type: StatusEffectType.slow,
        magnitude: 0.3,
        duration: 0.3,
        tickInterval: 0.0,
      );

      final ticked = StatusEffectManager.tickEffects([slow], deltaTime: 0.5);
      expect(ticked, isEmpty);
    });

    test('DoT ticks damage over time then expires', () {
      // DoT: 5 dmg per tick, tickInterval=1.0, duration=2.0
      const dot = StatusEffect(
        type: StatusEffectType.dot,
        magnitude: 5.0,
        duration: 2.0,
        tickInterval: 1.0,
      );

      final result = StatusEffectManager.tickEffects([dot], deltaTime: 1.0);

      // After 1s: duration = 1.0, dot should have triggered once
      expect(result, hasLength(1));
      expect(result.first.duration, closeTo(1.0, 1e-10));
    });

    test('DoT damage is calculated for elapsed ticks', () {
      const dot = StatusEffect(
        type: StatusEffectType.dot,
        magnitude: 5.0,
        duration: 3.0,
        tickInterval: 1.0,
      );

      final damage = StatusEffectManager.calculateDotDamage(
        effect: dot,
        deltaTime: 1.0,
      );
      expect(damage, closeTo(5.0, 1e-10));
    });

    test('DoT damage is 0 when less than one tick has passed', () {
      const dot = StatusEffect(
        type: StatusEffectType.dot,
        magnitude: 5.0,
        duration: 3.0,
        tickInterval: 1.0,
      );

      final damage = StatusEffectManager.calculateDotDamage(
        effect: dot,
        deltaTime: 0.5,
      );
      expect(damage, closeTo(0.0, 1e-10));
    });

    test('multiple DoT ticks can fire in one large deltaTime', () {
      const dot = StatusEffect(
        type: StatusEffectType.dot,
        magnitude: 5.0,
        duration: 3.0,
        tickInterval: 1.0,
      );

      // 2.5s passes → 2 ticks fire → 10 damage
      final damage = StatusEffectManager.calculateDotDamage(
        effect: dot,
        deltaTime: 2.5,
      );
      expect(damage, closeTo(10.0, 1e-10));
    });
  });
}
