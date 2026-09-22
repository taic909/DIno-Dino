# Fossilheart Room System

The current room system is intentionally small. MetSys provides map-authoring tools, while the project-owned `RoomManager` and `RoomDoor` handle scene changes. Saving, portals, minimaps, and MetSys persistence modules are not enabled yet.

## Files

| File | Purpose |
| --- | --- |
| `scripts/room_manager.gd` | Autoload that carries spawn position, velocity, health, and facing between room scenes |
| `scripts/room_door.gd` | Reusable doorway behavior with Inspector settings |
| `scenes/world/room_door.tscn` | Ready-to-place `Area2D` door scene |
| `scenes/levels/level_room_template.tscn` | Duplicate-ready starting structure for new playable rooms |
| `MapData.txt` | MetSys map database, initially containing one named layer |
| `addons/MetroidvaniaSystem/` | Third-party MetSys 1.6 addon; keep project gameplay code outside this folder |

## Make a room

1. Open `scenes/levels/level_room_template.tscn` and use **Scene > Save Scene As** to create a new room. Do not edit the template into a specific level.
2. Rename the root to match the room, then build collision under `Environment/Geometry`, visuals under `Background`, `Environment/Decoration`, or `Foreground`, enemies under `Enemies`, and doors under `Doors`.
3. Keep `Player`, `RoomInstance`, `DevMode`, and `PauseMenu` in the scene. Keep `Player` directly under the room root because the current developer overlay finds it there.
4. Move the Player to the desired starting position. The `SpawnPoints` markers show useful default, left-entry, and right-entry coordinates; copy a marker's position into a connected door's **Target Spawn Position**.
5. Assign the saved room scene to cells in the MetSys editor. The included `RoomInstance` is already at global position `(0, 0)`.
6. Keep the room root at `(0, 0)` so exported spawn positions match visible editor coordinates.

`scenes/main.tscn` remains the existing movement sandbox and current startup scene. It can later become a real first room, but do not assign it as a generic template or reuse it for multiple MetSys rooms.

## Configure a door

1. Add `scenes/world/room_door.tscn` to the source room.
2. Set **Target Room** to the destination `.tscn` scene.
3. Set **Target Spawn Position** to the coordinates where the player should appear in that destination.
4. Leave **Preserve Momentum** enabled for seamless movement. Disable it to use **Entry Velocity** instead.
5. For an entrance that launches the player upward, disable **Preserve Momentum** and use an entry velocity such as `(0, -500)`.
6. Put a corresponding door in the destination room that points back to the source room.

The manager applies a short `0.2` second entry lock so a player spawning over a destination door does not immediately bounce back to the previous room. This value is exported on the `RoomManager` autoload.

## Current boundary

This setup changes whole room scenes. It does not yet save progress, stream adjacent rooms, fade the screen, or automatically derive door destinations from the MetSys map. Add those only after multiple real rooms demonstrate a need.
