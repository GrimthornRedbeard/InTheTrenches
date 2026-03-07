/// Tracks the player's gold and tower investment history.
///
/// Manages spending, earning, and sell-refund calculations.
/// Tower investments are tracked separately so that the sell refund (60%)
/// can be calculated from the total buy + upgrade cost.
class ResourceManager {
  int _gold;

  /// Per-tower accumulated investment (buy + upgrade costs).
  final Map<String, int> _investments = {};

  ResourceManager({required int startingGold}) : _gold = startingGold;

  /// Current gold balance.
  int get gold => _gold;

  // ---------------------------------------------------------------------------
  // Earning
  // ---------------------------------------------------------------------------

  /// Adds [amount] to the current gold balance.
  void earn(int amount) {
    _gold += amount;
  }

  // ---------------------------------------------------------------------------
  // Spending
  // ---------------------------------------------------------------------------

  /// Attempts to spend [amount] gold.
  ///
  /// Returns `true` and deducts the amount if the player has sufficient funds.
  /// Returns `false` without changing the balance if funds are insufficient.
  bool trySpend(int amount) {
    if (_gold < amount) return false;
    _gold -= amount;
    return true;
  }

  // ---------------------------------------------------------------------------
  // Investment tracking (for sell refunds)
  // ---------------------------------------------------------------------------

  /// Records that [amount] gold was spent on [towerId] (buy or upgrade cost).
  void recordInvestment({required String towerId, required int amount}) {
    _investments[towerId] = (_investments[towerId] ?? 0) + amount;
  }

  /// Returns the total gold invested in [towerId] across buy and upgrades.
  int totalInvested(String towerId) => _investments[towerId] ?? 0;

  /// Removes all investment records for [towerId].
  void clearInvestment(String towerId) {
    _investments.remove(towerId);
  }

  // ---------------------------------------------------------------------------
  // Sell refund
  // ---------------------------------------------------------------------------

  /// Refunds 60% of total invested in [towerId] and clears the investment record.
  ///
  /// Does nothing if [towerId] is not tracked.
  void sell({required String towerId}) {
    final invested = _investments[towerId];
    if (invested == null) return;

    final refund = (invested * 0.6).floor();
    _gold += refund;
    _investments.remove(towerId);
  }

  // ---------------------------------------------------------------------------
  // Early wave send bonus
  // ---------------------------------------------------------------------------

  /// Awards a bonus of 10% of [nextWaveKillValue] (rounded down).
  ///
  /// Called when the player manually triggers the next wave early.
  void earlyWaveSendBonus({required int nextWaveKillValue}) {
    final bonus = (nextWaveKillValue * 0.1).floor();
    _gold += bonus;
  }
}
