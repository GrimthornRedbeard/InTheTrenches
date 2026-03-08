import '../models/game_map.dart';
import '../models/placed_tower.dart';
import '../models/tower.dart';
import 'resource_manager.dart';

/// Manages the placement, upgrade, and sale of towers on a [GameMap].
///
/// Validates placement positions, enforces resource checks, tracks per-tower
/// investment history for sell-refund calculations, and handles the three-tier
/// upgrade tree (Tier 1 → Tier 2 branch → Tier 3).
class TowerPlacementEngine {
  final GameMap map;
  final Map<String, TowerDefinition> towerLookup;

  /// Currently placed towers, keyed by tower ID.
  final Map<String, PlacedTower> _towers = {};

  /// Position IDs that are currently occupied.
  final Set<String> _occupiedPositions = {};

  /// Maps tower ID → position ID so that selling frees the position.
  final Map<String, String> _towerToPosition = {};

  int _nextId = 0;

  TowerPlacementEngine({required this.map, required this.towerLookup});

  /// All currently placed towers.
  List<PlacedTower> get towers => List.unmodifiable(_towers.values);

  // ---------------------------------------------------------------------------
  // buildTower
  // ---------------------------------------------------------------------------

  /// Places a tower at [positionId] using definition [towerDefId].
  ///
  /// Returns the new [PlacedTower] on success, or `null` if:
  /// - [positionId] is not on this map,
  /// - [positionId] is already occupied,
  /// - [towerDefId] is unknown, or
  /// - the player cannot afford the tower cost.
  PlacedTower? buildTower({
    required String positionId,
    required String towerDefId,
    required ResourceManager resources,
  }) {
    // Validate position exists and is free.
    final position = _findPosition(positionId);
    if (position == null) return null;
    if (_occupiedPositions.contains(positionId)) return null;

    // Validate tower definition.
    final def = towerLookup[towerDefId];
    if (def == null) return null;

    // Check and spend resources.
    if (!resources.trySpend(def.cost)) return null;

    // Build the tower.
    final id = 'tower_${_nextId++}';
    final tower = PlacedTower(
      id: id,
      definitionId: towerDefId,
      x: position.x,
      y: position.y,
      currentTier: 1,
    );

    _towers[id] = tower;
    _occupiedPositions.add(positionId);
    _towerToPosition[id] = positionId;

    // Track investment for sell refund.
    resources.recordInvestment(towerId: id, amount: def.cost);

    return tower;
  }

  // ---------------------------------------------------------------------------
  // sellTower
  // ---------------------------------------------------------------------------

  /// Removes [towerId] from the map and refunds 60% of total invested gold.
  ///
  /// Does nothing if [towerId] is not found.
  void sellTower({
    required String towerId,
    required ResourceManager resources,
  }) {
    final tower = _towers[towerId];
    if (tower == null) return;

    // Refund 60% (handled by ResourceManager).
    resources.sell(towerId: towerId);

    // Free the position.
    final positionId = _towerToPosition.remove(towerId);
    if (positionId != null) _occupiedPositions.remove(positionId);

    _towers.remove(towerId);
  }

  // ---------------------------------------------------------------------------
  // upgradeTower (Tier 1 → Tier 2, auto-selects first branch)
  // ---------------------------------------------------------------------------

  /// Advances [towerId] to the next tier using the first [upgradesTo] option.
  ///
  /// This is a convenience method that automatically picks the first available
  /// upgrade branch without validating the current tier. Use [chooseBranch]
  /// for explicit Tier-1 → Tier-2 branching, and [upgradeTier3] for
  /// enforced Tier-2 → Tier-3 progression.
  ///
  /// Returns the updated [PlacedTower], or `null` if the tower is not found,
  /// has no upgrade options, or the player cannot afford the upgrade.
  PlacedTower? upgradeTower({
    required String towerId,
    required ResourceManager resources,
  }) {
    final tower = _towers[towerId];
    if (tower == null) return null;

    final currentDef = towerLookup[tower.definitionId];
    if (currentDef == null || currentDef.upgradesTo.isEmpty) return null;

    final targetDefId = currentDef.upgradesTo.first;
    return _applyUpgrade(
      tower: tower,
      targetDefId: targetDefId,
      resources: resources,
    );
  }

  // ---------------------------------------------------------------------------
  // chooseBranch (explicit Tier 2 branch selection)
  // ---------------------------------------------------------------------------

  /// Upgrades [towerId] to the specific Tier-2 branch [branchDefId].
  ///
  /// Returns `null` if:
  /// - [towerId] is not found,
  /// - the tower is already at Tier 2 or higher,
  /// - [branchDefId] is not a valid upgrade option for the current definition, or
  /// - the player cannot afford the branch cost.
  PlacedTower? chooseBranch({
    required String towerId,
    required String branchDefId,
    required ResourceManager resources,
  }) {
    final tower = _towers[towerId];
    if (tower == null) return null;

    final currentDef = towerLookup[tower.definitionId];
    if (currentDef == null) return null;

    // Branch can only be selected at Tier 1.
    if (currentDef.tier != 1) return null;

    // Validate the branch is a valid upgrade option.
    if (!currentDef.upgradesTo.contains(branchDefId)) return null;

    return _applyUpgrade(
      tower: tower,
      targetDefId: branchDefId,
      resources: resources,
    );
  }

  // ---------------------------------------------------------------------------
  // upgradeTier3 (Tier 2 → Tier 3)
  // ---------------------------------------------------------------------------

  /// Upgrades [towerId] from Tier 2 to Tier 3.
  ///
  /// Returns `null` if the tower is not currently at Tier 2, has no Tier-3
  /// option, or the player cannot afford the upgrade.
  PlacedTower? upgradeTier3({
    required String towerId,
    required ResourceManager resources,
  }) {
    final tower = _towers[towerId];
    if (tower == null) return null;

    final currentDef = towerLookup[tower.definitionId];
    if (currentDef == null) return null;

    // Must be at exactly Tier 2 to upgrade to Tier 3.
    if (currentDef.tier != 2) return null;
    if (currentDef.upgradesTo.isEmpty) return null;

    final targetDefId = currentDef.upgradesTo.first;
    return _applyUpgrade(
      tower: tower,
      targetDefId: targetDefId,
      resources: resources,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Shared upgrade logic: validates cost, spends resources, updates tower.
  PlacedTower? _applyUpgrade({
    required PlacedTower tower,
    required String targetDefId,
    required ResourceManager resources,
  }) {
    final targetDef = towerLookup[targetDefId];
    if (targetDef == null) return null;

    if (!resources.trySpend(targetDef.cost)) return null;

    final upgraded = tower.copyWith(
      definitionId: targetDefId,
      currentTier: targetDef.tier,
    );

    _towers[tower.id] = upgraded;
    resources.recordInvestment(towerId: tower.id, amount: targetDef.cost);

    return upgraded;
  }

  /// Finds a [PlacementPosition] by its ID, or returns `null`.
  PlacementPosition? _findPosition(String positionId) {
    for (final pos in map.placements) {
      if (pos.id == positionId) return pos;
    }
    return null;
  }
}
