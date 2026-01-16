--[[
    Config.lua - Game Configuration

    This file holds all the numbers that control how the game feels.
    Change these values to make the game easier, harder, or just different!

    WHY A SEPARATE FILE?
    Instead of hunting through code to find "how much health does the player have?",
    all the important numbers are here in one place. Easy to find, easy to change.

    HOW TO USE:
    In other files, we'll do:
        local Config = require(game.ReplicatedStorage.TrenchDefense.Config)
        local health = Config.PLAYER_MAX_HEALTH
]]

local Config = {}

-- ============================================================================
-- RESOURCES
-- These control the economy - how much stuff players have and earn
-- ============================================================================

Config.STARTING_RESOURCES = 100      -- How much you start with
Config.RESOURCE_PER_KILL = 10        -- Reward for killing an enemy

-- ============================================================================
-- BUILDING COSTS
-- How much each defensive structure costs to build
-- ============================================================================

Config.SANDBAG_COST = 10             -- Cheap, basic cover
Config.BUNKER_COST = 50              -- Expensive, strong protection
Config.BARBED_WIRE_COST = 25         -- Slows enemies down

-- ============================================================================
-- BUILDING STATS
-- How tough buildings are
-- ============================================================================

Config.SANDBAG_HEALTH = 50           -- Takes a few hits
Config.BUNKER_HEALTH = 200           -- Very tough
Config.BARBED_WIRE_HEALTH = 25       -- Fragile but useful

-- ============================================================================
-- PLAYER STATS
-- How the player character behaves
-- ============================================================================

Config.PLAYER_MAX_HEALTH = 100       -- How much damage before game over
Config.PLAYER_MOVE_SPEED = 16        -- How fast the player moves (Roblox default is 16)
Config.PLAYER_START_AMMO = 30        -- Bullets at game start
Config.PLAYER_MAX_AMMO = 100         -- Most bullets you can carry

-- ============================================================================
-- WEAPON STATS
-- How guns work
-- ============================================================================

Config.RIFLE_DAMAGE = 25             -- Damage per bullet
Config.RIFLE_FIRE_RATE = 0.3         -- Seconds between shots (lower = faster)
Config.RIFLE_RELOAD_TIME = 2         -- Seconds to reload
Config.RIFLE_CLIP_SIZE = 10          -- Bullets before reload needed

-- ============================================================================
-- ENEMY STATS
-- How enemies behave (these are BASE values - harder enemies will be stronger)
-- ============================================================================

Config.ENEMY_BASE_HEALTH = 50        -- Basic enemy health
Config.ENEMY_MOVE_SPEED = 8          -- How fast enemies walk (slower than player)
Config.ENEMY_DAMAGE = 10             -- Damage enemies deal to player/buildings
Config.ENEMY_ATTACK_RATE = 1         -- Seconds between enemy attacks

-- ============================================================================
-- WAVE SYSTEM
-- How the waves of enemies work
-- ============================================================================

Config.WAVE_START_COUNT = 5          -- Enemies in wave 1
Config.WAVE_ENEMY_INCREMENT = 3      -- Extra enemies each wave (+3, so wave 2 has 8)
Config.TIME_BETWEEN_WAVES = 30       -- Seconds to prepare after clearing a wave
Config.SPAWN_DELAY = 1               -- Seconds between each enemy spawning

-- ============================================================================
-- GAME RULES
-- Win and lose conditions
-- ============================================================================

Config.WAVES_TO_WIN = 10             -- Survive this many waves to win
Config.BASE_HEALTH = 100             -- If enemies reach base, this goes down

-- ============================================================================
-- Don't change this part - it makes the module work
-- ============================================================================
return Config
