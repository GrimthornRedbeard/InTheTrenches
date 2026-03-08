import 'package:flutter_test/flutter_test.dart';
import 'package:trench_defense/engine/resource_manager.dart';

void main() {
  late ResourceManager resources;

  setUp(() {
    resources = ResourceManager(startingGold: 200);
  });

  // ---------------------------------------------------------------------------
  // Basic gold tracking
  // ---------------------------------------------------------------------------

  group('ResourceManager — gold tracking', () {
    test('starts with configured starting gold', () {
      expect(resources.gold, 200);
    });

    test('earn adds resources', () {
      resources.earn(50);
      expect(resources.gold, 250);
    });

    test('earn with zero has no effect', () {
      resources.earn(0);
      expect(resources.gold, 200);
    });
  });

  // ---------------------------------------------------------------------------
  // trySpend
  // ---------------------------------------------------------------------------

  group('ResourceManager — trySpend', () {
    test('trySpend succeeds when sufficient resources', () {
      final result = resources.trySpend(100);
      expect(result, isTrue);
      expect(resources.gold, 100);
    });

    test('trySpend fails if insufficient — returns false', () {
      final result = resources.trySpend(300);
      expect(result, isFalse);
      expect(resources.gold, 200); // unchanged
    });

    test('trySpend at exact balance succeeds', () {
      final result = resources.trySpend(200);
      expect(result, isTrue);
      expect(resources.gold, 0);
    });

    test('resource spend fails if insufficient', () {
      final result = resources.trySpend(201);
      expect(result, isFalse);
    });

    test('multiple spend calls accumulate', () {
      resources.trySpend(50);
      resources.trySpend(80);
      expect(resources.gold, 70);
    });
  });

  // ---------------------------------------------------------------------------
  // Tower investment tracking (for sell refund)
  // ---------------------------------------------------------------------------

  group('ResourceManager — investment tracking', () {
    test('recordInvestment tracks amount spent on tower', () {
      resources.recordInvestment(towerId: 'tower_1', amount: 50);
      expect(resources.totalInvested('tower_1'), 50);
    });

    test('multiple investments accumulate for same tower', () {
      resources.recordInvestment(towerId: 'tower_1', amount: 50);
      resources.recordInvestment(towerId: 'tower_1', amount: 80);
      expect(resources.totalInvested('tower_1'), 130);
    });

    test('totalInvested returns 0 for unknown tower', () {
      expect(resources.totalInvested('ghost'), 0);
    });

    test('clearInvestment removes tower from tracking', () {
      resources.recordInvestment(towerId: 'tower_1', amount: 50);
      resources.clearInvestment('tower_1');
      expect(resources.totalInvested('tower_1'), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // sell refund
  // ---------------------------------------------------------------------------

  group('ResourceManager — sell refund', () {
    test('sell refund is 60% of total invested', () {
      resources.recordInvestment(towerId: 'tower_1', amount: 50);
      resources.trySpend(50);

      resources.sell(towerId: 'tower_1');

      // 60% of 50 = 30
      expect(resources.gold, 200 - 50 + 30);
    });

    test('sell refunds 60% of buy + upgrade costs', () {
      resources.recordInvestment(towerId: 'tower_1', amount: 50); // buy
      resources.trySpend(50);
      resources.recordInvestment(towerId: 'tower_1', amount: 80); // upgrade
      resources.trySpend(80);

      resources.sell(towerId: 'tower_1');

      // Total invested = 130; 60% = 78
      expect(resources.gold, 200 - 50 - 80 + 78);
    });

    test('sell clears investment tracking for tower', () {
      resources.recordInvestment(towerId: 'tower_1', amount: 50);
      resources.sell(towerId: 'tower_1');
      expect(resources.totalInvested('tower_1'), 0);
    });

    test('sell on unknown tower id does nothing', () {
      final goldBefore = resources.gold;
      resources.sell(towerId: 'ghost');
      expect(resources.gold, goldBefore);
    });
  });

  // ---------------------------------------------------------------------------
  // earlyWaveSendBonus
  // ---------------------------------------------------------------------------

  group('ResourceManager — earlyWaveSendBonus', () {
    test('earlyWaveSendBonus adds 10% of next wave kill value', () {
      // Next wave kill value = 100; bonus = 10
      resources.earlyWaveSendBonus(nextWaveKillValue: 100);
      expect(resources.gold, 210);
    });

    test('earlyWaveSendBonus rounds down fractional amounts', () {
      // 10% of 15 = 1.5 -> floor to 1
      resources.earlyWaveSendBonus(nextWaveKillValue: 15);
      expect(resources.gold, 201);
    });

    test('earlyWaveSendBonus with 0 kill value gives no bonus', () {
      resources.earlyWaveSendBonus(nextWaveKillValue: 0);
      expect(resources.gold, 200);
    });
  });
}
