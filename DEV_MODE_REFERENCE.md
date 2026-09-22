# Fossilheart Dev Mode Reference

Dev mode is a small testing menu for development builds. It should make the current prototype faster to inspect and repeat without becoming a gameplay system.

## Current tools

Press **F3** or click the **right stick** to show or hide the developer menu. The first press shows it. These are defaults; change the toggle under **Pause > Controls > Dev Mode** for keyboard/mouse or controller. Gameplay pauses in the main menu; entering the level editor resumes the room. Use the **D-pad or left stick** to navigate the main menu, **A / Cross** to select, and **B / Circle** to go back. B is reserved for menu Back/Cancel and cannot be assigned to gameplay controls. While the menu is visible:

- **R** or **View / Create** reloads the current room.
- **F4** or click the **left stick** to show or hide live collision shapes, including hitboxes and hurtboxes.
- **Y / Triangle** loads the next available room, returning to the first after the last. The list includes the project main scene, the current test scene, and rooms assigned in MetSys.
- The overlay shows the player's rounded position and velocity.
- The overlay shows current prototype health.
- The overlay shows Glide state, remaining time, pitch angle, and preserved momentum speed.
- The overlay shows whether Pounce is ready, active, or cooling down.
- Use the **Enemy** dropdown and **Spawn** button to place a walker beetle, flyer beetle, or practice dummy on nearby floor ahead of the player. If no floor is found, move closer to a platform and try again.
- **Clear spawned enemies** removes only enemies created by the menu; enemies placed in the room scene remain.
- **Flight Mode** gives direct movement in all directions with no gravity. Releasing movement stops the dinosaur immediately, even in midair. Toggle it with the checkbox, **F5**, or **X / Square** during play; change the shortcut under **Pause > Controls > Flight Mode**. It turns off on room reload.
- **Edit level** opens a live tile palette while the room keeps running, so you can move the dinosaur and place tiles together. Choose a TileMap layer, TileSet art, atlas source, and tile thumbnail. The art list automatically includes TileSets added under `assets/tilemaps` and art already used by the room. Choose **Paint** or **Erase** for left click/drag; right click/drag is a quick eraser. **Ctrl+Z** or **Undo** reverses the last full stroke, including erasures. The small picture shows the live room around the brush. On controller, the left stick moves the dinosaur, the right stick aims the brush, RB / R1 paints, LB / L1 erases, and the D-pad plus A / Cross chooses controls. Use the mouse wheel over the world, **+ / −**, or the dock's **Camera** buttons to zoom the player-following view. **Done**, Escape / Menu, B / Circle, or the Dev Mode toggle saves changes and closes the editor; **Save** keeps editing.

Reloading the room restores the practice dummy and the player's starting position. Saved control bindings remain active.

Level-editor changes are stored per room in the project's `res://level_edits` folder, not in the room `.tscn` files. They load automatically next time that room starts. A `LevelEditPreview` node displays those saved tiles in Godot's 2D canvas and refreshes after new saves. Older `user://level_edits` saves migrate automatically when the room runs. Terrain tiles use their TileSet collision; Background, Decoration, and Foreground tiles are visual-only. Erase affects only tiles added through this editor, so existing authored tilemaps remain safe. The preview is visible but not directly editable in Godot; use the in-game editor to change these overlay tiles.

## Files and responsibilities

| File | Responsibility |
| --- | --- |
| `scenes/ui/dev_mode.tscn` | The overlay's visible nodes and layout |
| `scripts/dev_mode.gd` | Toggle, reset, and live readout behavior |
| `scenes/ui/level_editor.tscn` | Live editor dock and visual palette |
| `scripts/level_editor.gd` | Runtime tile layers, painting, and per-room JSON persistence |
| `scenes/world/level_edit_preview.tscn` and `scripts/level_edit_preview.gd` | Non-destructive, live-updating 2D-editor preview of saved tiles |
| `project.godot` | Input actions such as `toggle_dev_mode`, `dev_reset_room`, and the Y-only room-cycle command |
| `scenes/main.tscn` | Adds one `DevMode` instance to the movement room |

To add another spawnable enemy, add its `PackedScene` to the exported `spawnable_enemies` list on the `DevMode` instance (or to the default list near the top of `scripts/dev_mode.gd`). The dropdown builds itself from that list. Use a `Node2D`-based enemy scene with a rectangular `HurtboxShape` to align it automatically to the floor; other shapes use the editable `default_floor_offset`. No new menu button or handler is needed.

Keep development-only behavior inside the dev-mode scene and script where practical. Gameplay code must not require dev mode to exist.

For another converted TileSet, put its `.tres` file anywhere under `assets/tilemaps`; the editor scans that folder and its subfolders. TileSets already assigned to room TileMapLayers also appear automatically. Each painted cell calls `TileMapLayer.set_cell`; an undo stroke remembers the cells' prior source and atlas coordinates before changing them. Saved JSON records each tile's grid coordinate, atlas source, and tile coordinate. `load_edits` recreates it in the game, while the `@tool` preview script displays the same data in Godot's 2D canvas. Add a `LevelEditPreview` instance with its `room_scene_path` set when creating another room. This overlay stays separate from authored scene tiles.

## Add a live readout

For a simple value such as jump state or current floor status:

1. Open `scripts/dev_mode.gd`.
2. Calculate the value inside `_process`.
3. Add a descriptive line to `status_label.text` and add its value to the format list.
4. Run the game, press **F3**, and verify the value updates without affecting movement.

Example shape:

```gdscript
var floor_state := "YES" if player.is_on_floor() else "NO"

status_label.text = "DEV MODE\nOn floor: %s" % floor_state
```

The real status text contains several lines, so extend it rather than replacing useful existing readouts. Values are a paused snapshot while the menu is open.

## Add a developer command

Use this pattern for a command such as respawning a dummy or teleporting to a test marker:

1. In Godot, open **Project > Project Settings > Input Map**.
2. Add a clearly named action beginning with `dev_`, such as `dev_respawn_dummy`.
3. Give it a development-only key or controller binding that does not collide with player controls.
4. Handle the action in `scripts/dev_mode.gd` inside `_unhandled_input`.
5. Add the control to the overlay text and to the table in `GODOT_CODE_LIBRARY.md`.
6. Test the command with dev mode both hidden and visible. Commands should normally work only while the overlay is visible.

Example shape:

```gdscript
if enabled and event.is_action_pressed("dev_example"):
	_run_example_tool()
	get_viewport().set_input_as_handled()
```

## Add a rebindable player action

The pause menu builds its rows from `CONTROL_ACTIONS` and `CONTROL_LABELS` near the top of `scripts/pause_menu.gd`.

1. Add the action in **Project > Project Settings > Input Map**. It may begin empty.
2. Add its action name to `CONTROL_ACTIONS`.
3. Add its player-facing label to `CONTROL_LABELS`.
4. Update the current-controls table in `GODOT_CODE_LIBRARY.md` after the control is implemented or deliberately assigned.
5. Verify keyboard/mouse and controller slots independently, restart the game, and confirm the saved bindings return.

Tail Swipe is the current implemented example. Older control files saved it as an empty slot, so the versioned binding migration preserves its new defaults while continuing to respect later player rebindings.

## Guardrails

- Prefix developer-only input actions with `dev_`.
- Keep collision-shape drawing available only while the developer overlay is enabled.
- Do not make combat, movement, or level scenes depend on the overlay.
- Do not use dev mode to silently change normal difficulty or final controls.
- Prefer a short readout or one-purpose command over a general cheat framework.
- Remove or explicitly disable unsafe developer actions before a public build.
