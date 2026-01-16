# Learning Notes

Programming concepts we'll learn as we build Trench Defense.

---

## Concept 1: Variables

A **variable** is a name that holds a value. Like a labeled box.

```lua
-- This creates a variable named "health" holding the number 100
local health = 100

-- This creates a variable holding some text (called a "string")
local playerName = "Hero"

-- "local" means this variable only exists in this section of code
-- Always use "local" - it's a good habit
```

**Why?** Games need to remember things: How much health do I have? How many enemies are alive? What wave are we on?

---

## Concept 2: Functions

A **function** is a reusable chunk of code with a name.

```lua
-- This DEFINES a function (teaches the computer what "sayHello" means)
local function sayHello(name)
    print("Hello, " .. name .. "!")
end

-- This CALLS the function (actually runs it)
sayHello("Dad")    -- Prints: Hello, Dad!
sayHello("Son")    -- Prints: Hello, Son!
```

**Why?** Instead of writing the same code over and over, write it once as a function and call it whenever you need it.

---

## Concept 3: Events

An **event** is something that happens in the game. We can write code that runs WHEN an event happens.

```lua
-- This runs when a player touches a part
part.Touched:Connect(function(hit)
    print("Something touched me!")
end)

-- This runs when a player clicks
mouse.Button1Down:Connect(function()
    print("Player clicked!")
end)
```

**Why?** Games are all about reacting to things: When the player clicks, shoot. When an enemy reaches the base, take damage. When a wave ends, give rewards.

---

## Concept 4: Conditions (if/then)

**Conditions** let code make decisions.

```lua
local health = 30

if health <= 0 then
    print("Game Over!")
elseif health < 25 then
    print("Warning: Low health!")
else
    print("You're doing fine.")
end
```

- `if` checks if something is true
- `elseif` checks another thing if the first was false
- `else` runs if nothing above was true
- `then` and `end` mark where the code block starts and ends

**Why?** Games constantly make decisions: Is the player dead? Did the bullet hit? Can I afford this building?

---

## Concept 5: Loops

**Loops** repeat code multiple times.

```lua
-- "for" loop: repeat a specific number of times
for i = 1, 5 do
    print("This is loop number " .. i)
end
-- Prints 1, 2, 3, 4, 5

-- "while" loop: repeat as long as something is true
local count = 0
while count < 3 do
    print("Count is " .. count)
    count = count + 1
end
-- Prints 0, 1, 2 then stops
```

**Why?** Games have lots of repetition: Spawn 10 enemies. Check all buildings for damage. Move every bullet forward.

---

## Concept 6: Tables

A **table** is a list of things (or a collection of named things).

```lua
-- A list (values accessed by number)
local fruits = {"apple", "banana", "cherry"}
print(fruits[1])  -- "apple" (Lua counts from 1, not 0!)

-- A dictionary (values accessed by name)
local player = {
    name = "Hero",
    health = 100,
    score = 0
}
print(player.name)    -- "Hero"
print(player.health)  -- 100
```

**Why?** Games track lots of things: All enemies, all buildings, all players. Tables let us organize them.

---

## Concept 7: Modules

A **module** is code in a separate file that other files can use.

```lua
-- In Config.lua (a module)
local Config = {}
Config.PLAYER_HEALTH = 100
Config.ENEMY_SPEED = 8
return Config

-- In another file (using the module)
local Config = require(game.ReplicatedStorage.TrenchDefense.Config)
print(Config.PLAYER_HEALTH)  -- 100
```

**Why?** Big games have thousands of lines of code. Modules keep it organized - each file does one job.

---

## Concept 8: Client vs Server

In online games, code runs in two places:

**Server** (Roblox's computers)
- Runs game rules everyone must follow
- Spawns enemies
- Decides if hits count
- Saves player data
- TRUSTED - players can't cheat this

**Client** (Player's computer/phone)
- Shows the game on screen
- Handles keyboard/mouse input
- Plays sounds
- Updates UI
- NOT TRUSTED - cheaters can modify this

```lua
-- Server can tell clients things happened
RemoteEvent:FireClient(player, "EnemyDied", enemyId)

-- Clients can ask the server to do things
RemoteEvent:FireServer("PlaceBuilding", position)
-- But server CHECKS if it's valid before doing it!
```

**Why?** If important logic ran on the client, cheaters could give themselves infinite health or instant kills. Server decides what's real.

---

## Common Roblox Services

```lua
-- Get built-in Roblox services
local Players = game:GetService("Players")           -- All players
local Workspace = game:GetService("Workspace")       -- The 3D world
local ReplicatedStorage = game:GetService("ReplicatedStorage")  -- Shared stuff

-- Examples
local allPlayers = Players:GetPlayers()              -- Get list of all players
local myPart = Workspace:FindFirstChild("MyPart")    -- Find something in the world
```

---

## Debugging Tips

When code doesn't work:

1. **Use print()** - Add `print("Got here!")` to see what code actually runs
2. **Check Output window** - View → Output shows print statements and errors
3. **Read the error** - It tells you the line number and what went wrong
4. **Check spelling** - `Health` and `health` are different!
5. **Check paths** - Is the thing you're looking for actually where you think it is?

```lua
-- Add prints to understand what's happening
print("About to spawn enemy")
spawnEnemy()
print("Enemy spawned successfully")
```

---

*More concepts will be added as we encounter them in the project!*
