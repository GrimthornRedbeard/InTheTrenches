# Trench Defense — Flutter Mobile Master Plan

## Project Overview

A fixed-path tower defense game where players fortify trench lines across human history. Launch with 2 eras (WWI and Medieval), with additional eras added as paid content drops. Each era has 5 handcrafted maps, 3 base tower types with branching Tier 2 specializations, and era-themed enemies.

**Platform:** iOS + Android (Flutter)
**Monetization:** Free-to-play with era IAP ($2.99), gem economy for cosmetics, rewarded ads, remove-ads IAP
**Stack:** Flutter 3.38 / Dart 3.10, Riverpod 2.x, Hive, Firebase (Auth, Analytics), Google AdMob, in_app_purchase

---

## Game Design Reference

### Core Loop

Select map → Place towers at fixed positions along the trench → Survive waves → Earn resources → Upgrade/branch towers mid-battle → Complete map → Earn stars + XP → Unlock next map or harder difficulty.

### Era System

Data-driven era registry. Each era is a config bundle containing tower definitions, enemy definitions, wave templates, and map layouts. The engine loads eras from the registry and never hardcodes era-specific logic. Adding an era means adding config files — no engine changes.

**Launch eras:**
| Era | Towers | Enemies | Maps | Unlock Condition |
|-----|--------|---------|------|-----------------|
| WWI | 3 base / 6 branched | 8 types | 5 | Available at start |
| Medieval | 3 base / 6 branched | 8 types | 5 | Complete WWI Map 3 on Normal |

**Future eras (content drops):**
| Era | IAP Price | Status at Launch |
|-----|-----------|-----------------|
| Prehistoric | $2.99 | "Coming Soon" |
| Ancient | $2.99 | "Coming Soon" |
| Modern | $2.99 | "Coming Soon" |
| Future | $2.99 | "Coming Soon" |

### Tower System

Fixed placement positions along the trench line. Each map has pre-set defensive positions (sandbag spots, bunker foundations, watchtower locations). Players choose what to build where.

**Upgrade path:** 3 tiers with branching at Tier 2.
- Tier 1: Base tower (build cost)
- Tier 2: Branch A or Branch B (upgrade cost, meaningful strategic choice)
- Tier 3: Enhanced version of chosen branch (final upgrade cost)

**WWI Towers:**
| Base Tower | Branch A | Branch B |
|-----------|----------|----------|
| Rifleman | Machine Gunner (area damage, short range) | Sharpshooter (single-target, long range) |
| Mortar | Artillery (high damage, large splash) | Gas Mortar (area DoT, slow effect) |
| Barbed Wire | Razor Wire (damage on contact, high HP) | Electric Fence (stun effect, moderate damage) |

**Medieval Towers:**
| Base Tower | Branch A | Branch B |
|-----------|----------|----------|
| Archer | Longbowman (long range, piercing) | Crossbowman (slow fire, high damage, armor-piercing) |
| Catapult | Trebuchet (massive splash, slow) | Oil Cauldron (fire DoT, area denial) |
| Spike Trap | Moat (heavy slow, moderate damage) | Caltrops Field (wide area, light damage + bleed) |

### Enemy Types

**WWI Enemies:**
| Enemy | HP | Speed | Special |
|-------|-----|-------|---------|
| Infantry | Low | Normal | None — basic unit |
| Runner | Low | Fast | Moves at 2x speed |
| Shield Bearer | Medium | Slow | 50% reduced frontal damage |
| Officer | Medium | Normal | Buffs nearby enemy speed +25% |
| Medic | Low | Normal | Heals nearby enemies over time |
| Sapper | Medium | Normal | Damages towers when adjacent |
| Heavy | High | Slow | Armored — flat damage reduction |
| Elite | High | Fast | Armored + fast, mini-boss |

**Medieval Enemies:**
| Enemy | HP | Speed | Special |
|-------|-----|-------|---------|
| Peasant | Low | Normal | None — basic unit |
| Swordsman | Medium | Normal | Slightly armored |
| Shield Wall | High | Slow | Very high frontal armor |
| Knight | High | Fast | Armored + fast |
| Battering Ram | Very High | Slow | Targets towers, ignores path to attack nearest tower |
| Cavalry | Low | Very Fast | Fastest unit, comes in packs |
| Healer Monk | Low | Normal | Heals nearby enemies |
| Siege Tower | Very High | Very Slow | Spawns Swordsmen at your trench line when it arrives |

### Map Design

5 maps per era. Each map is a unique trench layout with:
- A fixed enemy path (or paths — later maps can have split paths)
- 8-12 tower placement positions along the path
- A base/HQ at the end of the path (if HP reaches 0, you lose)
- Visual backdrop unique to the map

**WWI Maps:**
1. **Somme Trenches** — Tutorial map. Single straight path, 8 positions. Muddy no-man's-land.
2. **Belgian Forest** — Winding path through trees. 10 positions. Some positions have natural cover (bonus range).
3. **Bombed Village** — Two entry points merge into one path. 10 positions. Introduces split-path concept.
4. **Mountain Pass** — Narrow switchback path, enemies close together. 9 positions. High-altitude backdrop.
5. **Coastal Bunker** — Long path with a choke point midway. 12 positions. Beach/cliff setting.

**Medieval Maps:**
1. **Castle Gate** — Single path to the castle entrance. 8 positions. Stone walls backdrop.
2. **Forest Clearing** — Path winds through a clearing. 10 positions. Dense forest edges.
3. **River Crossing** — Enemies cross a bridge (choke point) then spread. 10 positions.
4. **Hillfort** — Elevated defense. Path spirals uphill. 9 positions with height advantage (bonus range for some).
5. **Siege Camp** — Two paths, wide open field. 12 positions. The hardest map — tests all your skills.

### Difficulty Modes

| Difficulty | Enemy HP | Enemy Count | Starting Resources | Star Multiplier |
|-----------|---------|------------|-------------------|----------------|
| Normal | 1.0x | 1.0x | 100% | 1x |
| Hard | 1.5x | 1.25x | 80% | 1.5x |
| Nightmare | 2.0x | 1.5x | 60% | 2x |

### Star Rating

- 3 stars: Base takes 0 damage
- 2 stars: Base above 50% HP
- 1 star: Survived (base above 0% HP)

Stars gate progression — need X total stars to unlock later maps within an era.

### Wave System

Each map has 10-20 waves (varies by map). Waves are defined per-map in era config:
- Wave composition: which enemy types and how many
- Spawn delay between enemies within a wave
- Time between waves (30s default, player can send early for bonus resources)
- Boss waves: every 5th wave has an Elite or Siege Tower

### Resource Economy

- **Starting resources:** Varies by difficulty (100/80/60)
- **Earn per kill:** Varies by enemy type (Infantry=5, Heavy=15, Elite=25, etc.)
- **Early send bonus:** +10% of next wave's total kill value
- **Tower costs:** Base tower 20-40 resources, Tier 2 upgrade 30-50, Tier 3 upgrade 50-80
- **Sell refund:** 60% of total invested resources

---

## Monetization Design

### Philosophy
"Shortcut, never a gate." All gameplay content in the 2 launch eras is free. Paid content is additional eras (more game) and cosmetics (look cool). No pay-to-win.

### Gem Economy

**Earn gems:**
- First-time star completion: 3 gems per star (max 270 gems from completing all launch content)
- Level-up rewards: 10 gems per level
- Rewarded ads: 5 gems per ad (cooldown: 1 per map attempt)

**Spend gems:**
- Tower skin sets: 50-100 gems per set
- Profile banners: 25 gems
- Profile icons: 15 gems

### IAP Products

| Product | Type | Price |
|---------|------|-------|
| Era: Prehistoric | Non-consumable | $2.99 |
| Era: Ancient | Non-consumable | $2.99 |
| Era: Modern | Non-consumable | $2.99 |
| Era: Future | Non-consumable | $2.99 |
| Remove Ads | Non-consumable | $2.99 |
| 500 Gems | Consumable | $0.99 |
| 1,200 Gems | Consumable | $1.99 |
| 3,000 Gems | Consumable | $4.99 |

### Ads

- **Rewarded video (between waves):** Watch for +25% resources next wave. Player-initiated.
- **Rewarded video (on fail):** Watch to continue with 50% base HP restored. Once per attempt.
- **Banner ad:** Map select screen only. Removed by "Remove Ads" IAP.
- **No forced interstitials.** Ever.

---

## Player Progression

### XP System

Earn XP from completing maps:
- Base XP per map: 100
- Bonus per star: +50 per star
- Difficulty multiplier: Normal 1x, Hard 1.5x, Nightmare 2x
- First completion bonus: 2x XP

### Level Rewards

Every level up grants:
- 10 gems
- Every 5 levels: cosmetic unlock (skin, banner, or icon)
- Every 10 levels: title unlock (displayed on profile)

### Statistics Tracked

- Total enemies defeated
- Towers built / upgraded / sold
- Maps completed (per difficulty)
- Stars earned (total and per era)
- Favorite tower (most built)
- Favorite branch choice
- Total play time
- Longest win streak

---

## Technical Architecture

### Folder Structure

```
lib/
  models/          # Tower, Enemy, Wave, Map, Era, PlayerProfile, etc.
  engine/          # Core TD engine — wave spawner, targeting, damage, pathfinding
  data/            # Era configs (WWI, Medieval, future eras)
    eras/
      wwi/         # WWI tower defs, enemy defs, map layouts, wave configs
      medieval/    # Medieval tower defs, enemy defs, map layouts, wave configs
  ui/
    screens/       # Map select, era select, game screen, shop, profile, settings
    widgets/       # Tower build menu, upgrade menu, HUD, enemy sprites, effects
    theme/         # App theming, era-specific color palettes
  services/        # Firebase, Hive persistence, IAP, ads, audio
  config/          # Era registry, difficulty modifiers, gem economy constants
  utils/           # Shared utilities
```

### Key Models

```dart
// Era definition — purely data, no logic
class Era {
  final String id;           // 'wwi', 'medieval', etc.
  final String name;
  final List<TowerDef> towers;
  final List<EnemyDef> enemies;
  final List<MapDef> maps;
  final bool isLocked;       // Unlocked via gameplay or IAP
}

// Tower definition with branching
class TowerDef {
  final String id;
  final String name;
  final int buildCost;
  final double range;
  final double damage;
  final double fireRate;
  final TowerDef? branchA;   // Tier 2 option A
  final TowerDef? branchB;   // Tier 2 option B
  final TowerDef? tier3;     // Tier 3 (set on branch, not base)
}

// Placed tower instance during gameplay
class Tower {
  final String defId;
  final int positionIndex;
  final int tier;            // 1, 2, or 3
  final String? branchId;    // null until Tier 2
  final String? skinId;      // Cosmetic override
}

// Enemy instance during gameplay
class Enemy {
  final String defId;
  final double hp;
  final double maxHp;
  final double speed;
  final double pathProgress; // 0.0 to 1.0 along the path
  final List<StatusEffect> effects; // Slow, DoT, etc.
}

// Map definition
class MapDef {
  final String id;
  final String name;
  final String eraId;
  final List<PathPoint> path;         // Enemy walk path
  final List<PlacementPosition> positions; // Where towers can go
  final Map<Difficulty, List<WaveDef>> waves;
  final int unlockStarsRequired;
}
```

### State Management (Riverpod)

```
gameEngineProvider       — Core game loop state (enemies, towers, wave, resources)
playerProfileProvider    — XP, level, gems, unlocks (persisted via Hive)
eraRegistryProvider      — All era definitions (loaded at startup)
mapProgressProvider      — Star ratings, completion state (persisted via Hive)
shopProvider             — IAP products, purchase state
audioProvider            — Music/SFX playback, volume settings
```

---

## Iteration Plan

### Iteration 1: Project Scaffold + Core Engine

**Goal:** Flutter project with a data-driven TD engine that processes towers, enemies, paths, and waves from configuration. No UI, no specific era content — pure engine.

**Deliverables:**

1. Flutter project scaffold
   - pubspec.yaml with dependencies: flutter_riverpod, hive_flutter, equatable, uuid, collection, firebase_core, firebase_analytics
   - Folder structure per architecture above
   - CLAUDE.md with project overview, architecture, commands
   - .gitignore, analysis_options.yaml

2. Data models
   - Era, TowerDef, EnemyDef, WaveDef, MapDef, PathPoint, PlacementPosition
   - Tower (placed instance), Enemy (spawned instance), StatusEffect
   - PlayerProfile, MapProgress, Difficulty enum
   - All with Equatable + copyWith

3. Era registry system
   - EraRegistry class: load/register eras, look up by ID
   - Era config format: Dart const definitions (no JSON parsing needed at launch)
   - Validate era configs on load (correct tower counts, wave references, etc.)

4. Core game engine
   - WaveSpawner: spawn enemies from WaveDef at intervals, track wave progress
   - Pathfinding: move enemies along fixed PathPoints at their speed
   - Targeting: towers select targets by priority (nearest, strongest, first — configurable per tower)
   - Damage resolution: projectile hit → apply damage → check death → award resources
   - StatusEffect system: slow, DoT, armor reduction with duration/stacking rules
   - Resource manager: starting amount, earn per kill, spend to build/upgrade, sell refund
   - Tower commands: build at position, upgrade (choose branch at Tier 2), sell
   - Base HP: enemies that reach the end deal damage to base, game over at 0
   - Wave completion: detect all enemies dead, trigger inter-wave phase
   - Win/lose conditions: survive all waves = win (calculate stars), base HP 0 = lose
   - Difficulty modifiers: multiply enemy HP/count/speed, adjust starting resources

5. Difficulty system
   - Normal/Hard/Nightmare modifier configs
   - Applied to wave data at map load time
   - Star calculation: 3 stars (0 damage), 2 stars (>50% base HP), 1 star (survived)

**Tests:**
- Wave spawning: correct enemy types, correct counts, correct timing
- Pathfinding: enemies reach end of path, speed scaling works
- Targeting: nearest/strongest/first selection is correct
- Damage: HP reduction, death detection, resource award
- Status effects: slow reduces speed, DoT ticks damage, duration expires
- Resources: build cost deducted, kill reward added, sell refund correct
- Tower branching: Tier 1 → branch choice → Tier 2A or 2B → Tier 3
- Difficulty: modifier math applied correctly to all values
- Star calculation: all three thresholds tested
- Win/lose: both conditions trigger correctly

**Exit criteria:** All engine tests pass. A programmatic test can load a mock era config, simulate placing towers, run waves, and produce a win/lose result with correct star rating.

---

### Iteration 2: WWI Era Content + Game UI

**Goal:** First playable era. Tap to place towers, watch enemies march, play through all 5 WWI maps on all difficulties.

**Deliverables:**

1. WWI era configuration
   - 3 base towers with full branch trees (6 total variants), costs, stats, ranges
   - 8 enemy types with HP, speed, special abilities, kill rewards
   - 5 map layouts: path coordinates, placement positions (8-12 per map)
   - Wave definitions for all 5 maps (10-20 waves each, per-difficulty)
   - Balance pass: playtest each map on Normal, verify winnable but challenging

2. Game screen
   - Top-down scrollable/zoomable map view
   - Trench path rendered with era-appropriate art (brown trenches, mud, sandbags)
   - Placement positions highlighted as interactive spots
   - Pinch-to-zoom, drag-to-pan with bounds

3. Tower interaction
   - Tap empty position → build menu (shows 3 tower options with cost/stats)
   - Tap placed tower → context menu (upgrade/branch/sell with costs)
   - At Tier 2: branch selection UI showing both options side-by-side with stat comparison
   - Tower range indicator on tap (semi-transparent circle)
   - Build/upgrade confirmation with resource check

4. Enemy rendering
   - Sprite-based enemies walking along path
   - Health bar above each enemy
   - Damage flash on hit
   - Death animation (fade + particle)
   - Special ability indicators (Officer buff aura, Medic heal glow, etc.)

5. HUD
   - Top bar: resources (coin icon + count), wave counter (3/15), base HP bar
   - Bottom bar: pause button, fast-forward toggle (1x/2x), settings gear
   - Wave incoming preview: shows next wave composition as enemy icons

6. Wave flow UI
   - Countdown timer between waves (30s)
   - "Send Early" button with bonus resource preview
   - Wave complete: brief summary (enemies killed, resources earned)

7. Map select screen
   - WWI era header with themed art
   - 5 map cards in scrollable list
   - Each card shows: map name, thumbnail, star rating per difficulty, locked/unlocked
   - Tap to select difficulty, then start

**Tests:**
- Widget tests: build menu shows correct towers, upgrade menu shows correct branches, HUD updates on resource change
- Integration tests: programmatic playthrough of Map 1 Normal — place towers, advance waves, verify win
- Touch interaction tests: tap position triggers build, tap tower triggers upgrade menu

**Exit criteria:** A human can play through all 5 WWI maps on Normal difficulty, placing towers, upgrading them, and seeing a win/lose screen with star rating.

---

### Iteration 3: Medieval Era + Player Progression

**Goal:** Second launch era playable. Player profile with XP, levels, unlocks, and persistent save/load.

**Deliverables:**

1. Medieval era configuration
   - 3 base towers with full branch trees (6 total variants)
   - 8 enemy types with specials (Battering Ram targets towers, Siege Tower spawns troops)
   - 5 map layouts with medieval visual theming
   - Wave definitions for all 5 maps, per-difficulty
   - Balance pass

2. Player profile system
   - PlayerProfile model: XP, level, gems, unlocked skins, equipped skins, titles
   - XP calculation: base 100 per map + 50 per star + difficulty multiplier + first-completion 2x bonus
   - Level thresholds: increasing XP curve (level 1 = 100 XP, level 2 = 250 XP, etc.)
   - Level-up rewards: 10 gems per level, cosmetic every 5, title every 10

3. Persistence (Hive)
   - PlayerProfile box: XP, level, gems, unlocks, equipped cosmetics
   - MapProgress box: per-map star ratings for each difficulty, first-completion flags
   - Settings box: volume levels, graphics quality, accessibility toggles
   - Auto-save after every completed map and every purchase
   - App launch: load all boxes, hydrate Riverpod providers

4. Star gating
   - Maps 1-2 per era: unlocked by default (or by completing prior era Map 3)
   - Maps 3-5: require cumulative star thresholds within the era
   - Display lock reason on map card ("Need 6 more stars to unlock")

5. Era select screen
   - Grid/carousel of era cards
   - Owned eras show progress (stars earned / total possible)
   - Future eras show "Coming Soon" with themed silhouette art
   - Tap owned era → opens that era's map select

6. Campaign flow
   - Fresh install: WWI era available, Medieval locked
   - Complete WWI Map 3 on Normal → Medieval unlocks (notification + animation)
   - Both eras freely switchable after that

7. Profile screen
   - Player name, level, XP progress bar
   - Statistics: enemies defeated, towers built, maps completed, stars earned, time played, favorite tower
   - Equipped cosmetics display

**Tests:**
- XP/level math: correct XP awards for various scenarios, level-up at correct thresholds
- Star calculation and gating: unlock conditions verified
- Hive persistence: save profile → kill app → relaunch → profile intact
- Era unlock flow: complete WWI Map 3 → Medieval appears unlocked
- Medieval balance: programmatic playthrough of each map verifies winnability

**Exit criteria:** Both eras playable with persistent progress. Close app, reopen, all stars/XP/gems preserved. Medieval unlocks correctly after WWI Map 3 completion.

---

### Iteration 4: Monetization + Gem Economy

**Goal:** Revenue systems wired up — IAP for future eras, gem shop for cosmetics, rewarded ads for bonus resources.

**Deliverables:**

1. Gem economy
   - Earn: 3 gems per first-time star, 10 gems per level-up, 5 gems per rewarded ad (1 ad per map attempt cooldown)
   - Spend: tower skin sets (50-100 gems), profile banners (25 gems), profile icons (15 gems)
   - Balance persisted via Hive, display in HUD and shop

2. IAP integration (in_app_purchase package)
   - Products registered with App Store Connect and Google Play Console
   - Non-consumable: era packs ($2.99 each), Remove Ads ($2.99)
   - Consumable: gem bundles (500/$0.99, 1200/$1.99, 3000/$4.99)
   - Purchase flow: tap product → platform payment sheet → receipt validation → unlock content
   - Receipt validation: server-side via Firebase Cloud Function (prevents tampering)
   - Restore purchases: button in settings, restores all non-consumables

3. Cosmetic shop screen
   - Tower skin sets: grouped by era, preview image, gem cost, owned/equipped state
   - Profile customization: banners and icons in grid, preview on tap, purchase confirmation
   - Gem balance displayed prominently
   - "Get More Gems" button → gem bundle IAP options

4. Ad integration (google_mobile_ads)
   - Rewarded video (between waves): "Watch ad for +25% resources" button during inter-wave countdown. Grants bonus on completion callback.
   - Rewarded video (on fail): "Watch ad to continue" option on game over screen. Restores 50% base HP, once per attempt.
   - Banner ad: bottom of map select screen. Hidden if "Remove Ads" purchased.
   - Ad loading: preload next rewarded ad during gameplay. Handle load failure gracefully (hide button if no ad available).
   - No forced interstitials.

5. "Remove Ads" IAP
   - Non-consumable purchase
   - Removes banner on map select
   - Rewarded ads remain available (player-initiated)
   - Check purchase state at app launch via restore

6. Future era placeholders
   - Era select shows locked Prehistoric, Ancient, Modern, Future
   - "Coming Soon" label on each
   - When an era IAP is purchased, the era config loads from the registry (configs included in app bundle but locked behind purchase flag)
   - No era content built yet — just the purchase → unlock → "content coming in update" flow

7. Offline-first
   - All purchases cached locally in Hive
   - Gem balance changes queued if offline
   - Reconcile with server when connectivity returns

**Tests:**
- Gem math: earn/spend calculations correct, balance never goes negative
- IAP mock tests: purchase flow with mock store, receipt validation with mock server
- Ad reward tests: mock ad callback grants correct resource bonus
- Restore purchases: mock restore returns non-consumables correctly
- Offline: purchase while offline → cached → sync on reconnect

**Exit criteria:** Can purchase gem bundles, buy cosmetics, watch rewarded ads for bonus resources. IAP era unlock flow works end-to-end (with placeholder "coming soon" content). All purchases persist across app restarts.

---

### Iteration 5: Polish + Audio + Visual Effects

**Goal:** Make it satisfying to play. Juice, feedback, and accessibility.

**Deliverables:**

1. Visual effects
   - Projectile visuals per tower type: bullet trails (Rifleman), arrows (Archer), mortar arcs (Mortar/Catapult)
   - Impact effects: dirt splash, sparks, explosion radius indicator
   - Tower build animation: construction sequence (0.5s)
   - Tower upgrade animation: glow + transform
   - Enemy death effects: era-appropriate (WWI dust cloud, Medieval ragdoll fade)
   - Base damage: screen shake (short, subtle)
   - Wave complete: particle celebration + XP/resource summary flyout

2. Audio
   - Background music per era: WWI (tense military percussion), Medieval (orchestral strings)
   - Tower sounds: unique fire sound per tower type, upgrade chime, sell sound
   - Enemy sounds: march footsteps (ambient), death sounds, special ability triggers
   - UI sounds: tap, build confirm, menu open/close
   - Wave sounds: horn/trumpet for wave start, victory fanfare, defeat stinger
   - Volume controls: master, music, SFX (3 independent sliders)
   - Audio manager: preload sounds per era, crossfade music on era switch

3. Tower range visualization
   - Hold-tap tower: range circle with gradient edge
   - During placement: range preview before confirming build
   - Branch comparison: show both branch ranges side-by-side

4. Enemy path preview
   - Faint dotted line on map load showing enemy route
   - Fades out after first wave starts
   - Always visible on pause screen

5. Speed controls
   - 1x / 2x / 3x toggle button
   - Game state interpolation stays smooth at all speeds
   - Pause: full stop, menu overlay with resume/restart/quit

6. Map visual themes
   - WWI: Somme (mud/brown), Belgian (green forest), Village (grey rubble), Mountain (rocky grey), Coastal (sandy/blue)
   - Medieval: Castle (grey stone), Forest (deep green), River (blue/green), Hillfort (brown/green elevation), Siege (open tan field)
   - Each map has a distinct background layer + path art

7. Settings screen
   - Volume sliders (master/music/SFX)
   - Graphics quality: Low/Medium/High (particle count, shadow quality)
   - Accessibility section (see below)
   - Credits, privacy policy link, support email link
   - Notification preferences

8. Accessibility
   - Colorblind mode: towers and enemies differentiated by shape, not just color
   - Font size: Normal/Large toggle
   - Reduced motion: disables screen shake, reduces particles, simplifies animations
   - All interactive elements meet minimum 44x44pt touch target

**Tests:**
- Widget tests: settings changes persist (volume, quality, accessibility toggles)
- Performance benchmarks: 60fps target with 50+ enemies on screen at Medium quality on reference device
- Audio tests: verify sounds play for correct events (mock audio service)
- Accessibility: verify colorblind mode renders correct shape indicators

**Exit criteria:** Game feels polished — towers fire with visible projectiles and sound, enemies react to damage, waves have audio cues. Runs at 60fps on mid-range devices. All settings persist. Accessibility modes functional.

---

### Iteration 6: App Store Submission + Launch

**Goal:** Ship it. QA, compliance, store assets, analytics, soft launch.

**Deliverables:**

1. App store assets
   - App icon: trench silhouette with tower, era-neutral design
   - Screenshots: 5 per platform (gameplay, upgrade branching, era select, map select, shop)
   - Short description (30 chars): "Defend the trench through history"
   - Full description: keyword-optimized, feature highlights, era list
   - Feature graphic (Google Play): 1024x500 banner
   - Preview video: 30s gameplay montage across both eras

2. Platform compliance
   - iOS: App Tracking Transparency prompt for ad tracking
   - Google Play: data safety form (what data collected, how used)
   - Privacy policy: hosted URL, covers analytics + ads + IAP data
   - Age rating: 9+ (iOS) / E10+ (Google Play) for cartoon violence
   - COPPA compliance review (no collection of data from children under 13)

3. Performance pass
   - Profile on low-end devices: iPhone SE 2nd gen, budget Android (~$150 device)
   - Memory audit: sprite atlas optimization, dispose all controllers/streams
   - Cold start: under 3 seconds to main menu
   - Gameplay: no drops below 30fps on minimum spec with 50+ enemies
   - Battery: no excessive drain during gameplay sessions

4. QA checklist
   - Full playthrough: all 10 maps, all 3 difficulties (30 completions)
   - IAP: purchase flow, restore flow, both platforms
   - Ads: rewarded ad display + reward granting, banner display + removal
   - Persistence: kill app mid-wave → relaunch → profile intact (map restarts, progress saved)
   - Offline: airplane mode full playthrough (no ads, no IAP, gameplay works)
   - Edge cases: sell all towers mid-wave, spam "send early", upgrade during active targeting, pause/resume mid-projectile, rapid tap build menu

5. Analytics (Firebase Analytics)
   - Map completion rates (per map, per difficulty)
   - Average stars per map
   - Tower popularity (build counts per tower type)
   - Branch choice distribution (A vs B per tower type)
   - Wave fail point (which wave players die on most)
   - IAP conversion rate
   - Ad engagement rate (rewarded ad watch rate)
   - Session length, sessions per day
   - Retention: D1 / D7 / D30
   - Funnel: install → tutorial complete → WWI Map 1 complete → Medieval unlock → IAP purchase

6. Soft launch
   - Release to single market (Canada or Australia) for 1-2 weeks
   - Monitor: crash rate (<0.5%), ANR rate, store rating, analytics dashboards
   - Fix critical issues before global launch
   - Adjust balance if analytics show problematic drop-off points

7. CI/CD
   - GitHub Actions: build + analyze + test on every PR
   - Fastlane: automated builds and store uploads
   - Separate staging and production Firebase projects
   - Version bumping script

**Tests:**
- Full integration test suite: automated playthrough of Map 1 on each difficulty
- Smoke tests: app launches, navigates to all screens, no crashes (both platforms)
- Automated screenshot generation for store listings (flutter_driver or integration_test)
- Analytics event verification: key events fire with correct parameters

**Exit criteria:** App approved on both App Store and Google Play. Soft launch metrics within acceptable bounds (crash rate <0.5%, D1 retention >30%). Ready for global launch.

---

## Content Roadmap (Post-Launch)

Each new era follows the same pattern: 3 towers (6 branched), 8 enemies, 5 maps, wave configs. Released as $2.99 IAP.

| Release | Era | Theme Highlights |
|---------|-----|-----------------|
| Update 1 | Ancient | Spearmen, chariots, siege rams, desert/Egyptian maps |
| Update 2 | Modern | Drones, tanks, missile launchers, urban/jungle maps |
| Update 3 | Prehistoric | Rock throwers, fire pits, mammoth riders, cave/volcano maps |
| Update 4 | Future | Laser turrets, shield generators, mech walkers, space station/alien planet maps |

Each era update also includes:
- New cosmetic skin sets for the era's towers
- 2-3 new profile banners/icons
- Balance adjustments based on analytics
- Potential new game mode (endless/survival) once 4+ eras exist
