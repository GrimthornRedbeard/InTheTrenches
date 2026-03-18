# Trench Defense: Perpendicular Movement Refactor

**Date:** 2026-03-17
**Status:** Approved for implementation
**Supersedes:** Original path-following movement mechanic

---

## Problem

The current game plays like a conventional tower defense: enemies follow a fixed 1D polyline path *along* the trench. The trench is decorative. This contradicts the WWI setting where the drama is enemies crossing no man's land *toward* the trench, attempting to breach it.

---

## Design Goal

Enemies spawn across the top of the map and advance freely in 2D through no man's land toward a dynamic, segmented trench line. Reaching the trench triggers a breach mechanic. Sustained breaches push the trench line back toward the command post. Players deploy defenders in three zones and can redeploy them to reinforce contested segments mid-wave.

---

## Battlefield Layout

The map is oriented top-to-bottom with three zones:

```
┌─────────────────────────────────┐
│         ENEMY SPAWN ZONE        │  ← enemies appear here (random X)
│                                 │
│         NO MAN'S LAND           │  ← free 2D movement, obstacles
│   [wire] [crater] [post] [wire] │  ← Zone 1: forward positions
│                                 │
│━━━━━━━━ TRENCH LINE ━━━━━━━━━━━│  ← dynamic, segmented, can be pushed back
│  [mg] [rifleman] [mortar] [mg]  │  ← Zone 2: in-trench defenders
│                                 │
│       COMMAND POST ZONE         │  ← Zone 3: rear ranged defenders
│                                 │  ← lose if enemies reach bottom
└─────────────────────────────────┘
```

The trench line is divided into 5–8 segments across the width. Each segment tracks breach HP independently and can be pushed back toward the command post if it collapses.

---

## Enemy Movement & AI

Enemies use **steering behaviors** — no fixed paths or waypoints.

Each tick, steering force = `seek(target) + avoid(obstacles) + separate(nearby_enemies)`

- **Seek:** Target = trench segment with lowest current breach HP (enemies sense weak points)
- **Obstacle avoidance:** Shell craters and barbed wire are repulsion zones
- **Separation:** Enemies spread across the front naturally, preventing single-column funneling

### Enemy State Machine

```
ADVANCING
    │ reaches trench segment worldY
    ▼
BREACHING  ← can still be hit by ranged (reduced effectiveness)
    │ breach HP depleted
    ▼
IN_TRENCH  ← only melee defenders / grenades effective
    │ killed by melee defender
    ▼
  dead
    │ survives long enough
    ▼
CROSSED → advancing on command post
```

### EnemyInstance Changes

| Old field | New field |
|-----------|-----------|
| `pathProgress: double` | `position: Offset` |
| *(none)* | `velocity: Offset` |
| *(none)* | `state: EnemyState` |
| *(none)* | `targetSegmentIndex: int` |

---

## Trench Line System

```dart
class TrenchSegment {
  final int index;             // 0..N left to right
  double breachHp;             // starts 100, depleted by IN_TRENCH enemies
  double worldX;               // horizontal center
  double worldY;               // starts fixed; pushed back ~60px on collapse
  TrenchSegmentState state;    // held | contested | breached | collapsed
}
```

### Segment State Transitions

```
held
  │ enemy enters IN_TRENCH state on this segment
  ▼
contested  ←──── player reinforces (recoverable)
  │ breach HP → 0
  ▼
breached
  │ ignored (no melee defender kills enemies fast enough)
  ▼
collapsed  → worldY += 60px (permanent for this wave)
```

- **Breach HP drain:** Each IN_TRENCH enemy drains breach HP at a fixed rate per second
- **Breach HP repair:** Melee defenders in the trench passively regenerate breach HP on their segment
- **Collapse:** Enough collapsed segments = defeat (command post overrun)
- **Visual:** Collapsed segments render visibly lower on screen; contested segments pulse red — the front line becomes visibly jagged

---

## Defender Placement & Roles

### Zone 1 — No Man's Land (forward positions)
Can be overrun if enemies pass through.

| Unit | Role |
|------|------|
| Listening Post | Reveals cloaked/gas-obscured enemies; small ranged attack |
| Wire Layer | Places barbed wire obstacle (slows ADVANCING enemies) |
| Sniper Post | Long range, single target, high damage; repositions if overrun |

### Zone 2 — Trench Line (in-trench defenders)
Only engage BREACHING or IN_TRENCH enemies.

| Unit | Role |
|------|------|
| Bayonet Fighter | Melee; repairs breach HP passively; primary IN_TRENCH counter |
| Grenadier | Area damage to BREACHING enemies; short cooldown |
| Officer | Buffs adjacent trench defenders; speeds breach HP repair |

### Zone 3 — Behind the Trench (ranged fire)
Safe until a segment collapses. Primary damage dealers against ADVANCING enemies.

| Unit | Role |
|------|------|
| Machine Gunner | High rate of fire, cone sweep across no man's land |
| Mortar | Large splash, slow reload, targets clusters |
| Artillery | Longest range, can hit spawn zone, expensive |

### Redeployment
Any defender can be manually dragged to a new valid slot within their zone for a small gold cost and a ~3 second redeploy delay. Core tactical gesture: drag a bayonet fighter to a contested segment before it collapses.

---

## Codebase Changes

### Replaced Entirely

| Old | New |
|-----|-----|
| `engine/pathfinding_engine.dart` | `engine/steering_engine.dart` — 2D velocity/steering |
| `models/game_map.dart` path waypoints | `TrenchSegment` list + obstacle registry |
| `config/map_data.dart` path definitions | Zone boundaries + obstacle placement per map |
| `enemy_instance.dart` `pathProgress` | `position`, `velocity`, `state`, `targetSegmentIndex` |

### Extended

| File | Change |
|------|--------|
| `engine/combat_engine.dart` | Add melee combat phase for IN_TRENCH enemies; ranged reduced vs BREACHING |
| `providers/game_providers.dart` | Trench segment state updates, breach HP drain, collapse logic, push-back |
| `ui/widgets/game_map_widget.dart` | Rewrite renderer: three zones, segmented trench with state colors, free-positioned enemies |

### New Files

| File | Purpose |
|------|---------|
| `models/trench_segment.dart` | TrenchSegment model + TrenchSegmentState enum |
| `engine/breach_engine.dart` | IN_TRENCH combat and breach HP drain/repair |
| `engine/trench_engine.dart` | Segment state transitions, collapse, worldY push-back |

### Unchanged

- `engine/wave_spawner.dart` — still spawns on timer; spawn position changes to random X across top zone instead of single path start
- `era_registry.dart`, `difficulty_config.dart` — data-driven config unchanged
- Tower upgrade/build/sell economy — same system, applied to three zones

---

## Implementation Order

1. `TrenchSegment` model + `TrenchSegmentState` enum
2. `EnemyInstance` model update (position/velocity/state)
3. `SteeringEngine` replacing `PathfindingEngine`
4. `GameMap` refactor (zones + segments + obstacles)
5. `BreachEngine` + `TrenchEngine`
6. `CombatEngine` melee phase
7. `GameMapWidget` renderer rewrite
8. `GameProviders` game loop wiring
9. Map data updates (Somme, Castle Approach)
10. Defender zone placement validation
