# CLAUDE.md - Trench Defense (Roblox)

## Project Overview

A father-son learning project: a Roblox trench warfare defense game. Players command a trench fortification, building defenses and fighting off waves of AI enemies.

**Primary Goal:** Learn game development together. Code should be readable, well-commented, and educational.

**Son's Experience Level:** Brand new to coding - this is his first project.

---

## Game Concept

### Core Loop
1. Wave announced → prepare defenses
2. Enemies spawn and advance toward base
3. Player shoots enemies, repairs defenses
4. Wave cleared → earn resources → upgrade/build
5. Repeat with harder waves

### Key Systems
- **Building** - Place sandbags, bunkers, barbed wire, gun emplacements
- **Combat** - Rifles, grenades, mortars vs AI enemies
- **Resources** - Ammunition, building materials, reinforcements
- **Progression** - Unlock better weapons and defenses over time

---

## Technical Decisions

### Platform
- **Roblox Studio** with Lua scripting
- Must run well on both mobile and desktop

### Code Philosophy
- **Readable over clever** - Simple code with clear names
- **Comments explain WHY** - Not just what, but reasoning
- **Modular** - Each system independent where possible
- **Config-driven** - Easy balance tweaking without code changes

### Architecture
Following Roblox best practices:
- **ServerScriptService** - Game logic, enemy AI, rules (trusted code)
- **StarterPlayerScripts** - UI, input, camera (runs on player's device)
- **ReplicatedStorage** - Shared modules, configs, events (both can access)

Why this split? In online games, player devices can't be trusted (cheaters). Important logic like "did the enemy die?" must run on the server.

---

## Folder Structure

```
trench-defense/
├── CLAUDE.md              # This file - project context
├── README.md              # Setup instructions
├── docs/
│   └── LEARNING_NOTES.md  # Concepts explained for learning
├── src/
│   ├── Server/            # → Goes in ServerScriptService
│   │   ├── GameManager.lua
│   │   ├── WaveSpawner.lua
│   │   ├── EnemyAI.lua
│   │   └── BuildingSystem.lua
│   ├── Client/            # → Goes in StarterPlayerScripts
│   │   ├── InputHandler.lua
│   │   ├── UIController.lua
│   │   └── BuildingPreview.lua
│   └── Shared/            # → Goes in ReplicatedStorage
│       ├── Config.lua
│       ├── Events.lua
│       └── Utils.lua
└── assets/                # Reference images, sounds (not code)
```

---

## How to Use This Project

### Initial Setup (One Time)
1. Open Roblox Studio
2. Create new project from "Baseplate" template
3. Save as `TrenchDefense.rbxl`
4. Create folders in Explorer panel matching our structure
5. Copy code from `src/` files into corresponding Roblox scripts

### Development Workflow
1. Edit code here in this repo (better editor, version control)
2. Copy changed files into Roblox Studio
3. Test in Studio with Play button
4. When working, save both `.rbxl` and commit code changes here

### Learning Workflow
1. Read the code together - understand what each part does
2. Make small changes - see what happens
3. Break things on purpose - learn by fixing
4. Add features incrementally - one small piece at a time

---

## Current Status

**Phase:** Project Setup (not yet started in Roblox Studio)

**Next Steps:**
1. Create Roblox Studio project from Baseplate template
2. Set up folder structure in Explorer panel
3. Add first script: basic player spawning
4. Add second script: place/remove sandbags
5. Add third script: one enemy type with basic movement

---

## Building Order (When We Start)

We'll build in this order, each step small and testable:

### Phase 1: Foundation
- [ ] Player spawns and can move around
- [ ] Basic flat terrain (the "no man's land")

### Phase 2: Building Basics
- [ ] Place a sandbag at cursor position
- [ ] Remove a sandbag by clicking it
- [ ] Sandbags cost resources
- [ ] UI shows current resources

### Phase 3: First Enemy
- [ ] Enemy spawns at edge of map
- [ ] Enemy walks toward base (simple pathfinding)
- [ ] Enemy dies when health reaches 0
- [ ] Player earns resources when enemy dies

### Phase 4: Combat
- [ ] Player can shoot (click to fire)
- [ ] Bullets hit enemies and deal damage
- [ ] Ammo counter in UI
- [ ] Reload mechanic

### Phase 5: Wave System
- [ ] Waves with increasing enemy counts
- [ ] Pause between waves for building
- [ ] Win condition (survive X waves)
- [ ] Lose condition (enemies reach base)

### Phase 6: Polish & Expand
- [ ] More building types
- [ ] More enemy types
- [ ] Sound effects
- [ ] Progression/unlocks

---

## Config Values (For Easy Tweaking)

These will live in `src/Shared/Config.lua`:

```lua
-- RESOURCES
STARTING_RESOURCES = 100
RESOURCE_PER_KILL = 10

-- BUILDING COSTS
SANDBAG_COST = 10
BUNKER_COST = 50
BARBED_WIRE_COST = 25

-- PLAYER
PLAYER_MAX_HEALTH = 100
PLAYER_MOVE_SPEED = 16

-- ENEMIES
ENEMY_BASE_HEALTH = 50
ENEMY_MOVE_SPEED = 8
ENEMY_DAMAGE = 10

-- WAVES
WAVE_START_COUNT = 5
WAVE_ENEMY_INCREMENT = 3
TIME_BETWEEN_WAVES = 30
```

---

## Concepts to Learn

As we build, we'll encounter these programming concepts:

1. **Variables** - Storing information (health = 100)
2. **Functions** - Reusable chunks of code
3. **Events** - "When X happens, do Y"
4. **Loops** - Repeat something multiple times
5. **Conditions** - If this, then that
6. **Tables** - Lists of things (all enemies, all buildings)
7. **Modules** - Organizing code into separate files
8. **Client-Server** - What runs where and why

Each concept will be explained when we first use it.

---

*This document will be updated as we make decisions and build features.*
