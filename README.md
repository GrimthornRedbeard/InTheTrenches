# Trench Defense

A Roblox trench warfare defense game - a father-son learning project.

## What Is This?

Defend your trench against waves of enemies! Build sandbags, bunkers, and gun emplacements. Manage your resources. Survive as long as you can.

## Setup Instructions

### 1. Install Roblox Studio
- Go to https://www.roblox.com/create
- Download and install Roblox Studio
- Sign in with your Roblox account

### 2. Create the Project
1. Open Roblox Studio
2. Click **"New"** in the top left
3. Select **"Baseplate"** template
4. Go to **File → Save to File As...**
5. Save as `TrenchDefense.rbxl` in this folder

### 3. Set Up Folders in Roblox Studio
In the Explorer panel (right side), create these folders:

**In ServerScriptService:**
- Right-click → Insert Object → Folder → Name it "TrenchDefense"

**In StarterPlayerScripts:**
- Right-click → Insert Object → Folder → Name it "TrenchDefense"

**In ReplicatedStorage:**
- Right-click → Insert Object → Folder → Name it "TrenchDefense"

### 4. Add Scripts
For each `.lua` file in our `src/` folder:
1. Right-click the matching Roblox folder
2. Insert Object → Script (for Server) or LocalScript (for Client) or ModuleScript (for Shared)
3. Copy-paste the code from our file
4. Name it to match (without .lua extension)

## Project Structure

```
trench-defense/
├── src/
│   ├── Server/    → ServerScriptService/TrenchDefense
│   ├── Client/    → StarterPlayerScripts/TrenchDefense
│   └── Shared/    → ReplicatedStorage/TrenchDefense
├── docs/          → Learning notes and explanations
└── assets/        → Images, sounds (reference only)
```

## How to Test

1. Open `TrenchDefense.rbxl` in Roblox Studio
2. Click the **Play** button (or press F5)
3. Your game runs in a test window
4. Press **Stop** to end the test

## Learning Resources

- [Roblox Creator Documentation](https://create.roblox.com/docs)
- [Lua Basics](https://create.roblox.com/docs/scripting/luau)
- [Roblox Scripting Tutorials](https://create.roblox.com/docs/tutorials)

## Files

| File | What It Does |
|------|--------------|
| `CLAUDE.md` | Full project details for AI assistant |
| `README.md` | This file - setup instructions |
| `docs/LEARNING_NOTES.md` | Programming concepts explained |
| `src/Server/*.lua` | Server-side game logic |
| `src/Client/*.lua` | Player UI and input |
| `src/Shared/*.lua` | Shared configuration and utilities |
