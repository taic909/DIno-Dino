# Fossilheart Dev Mode Reference

Dev mode is a small testing overlay for development builds. It should make the current prototype faster to inspect and repeat without becoming a gameplay system.

## Current tools

Press **F3** or click the **right stick** to show or hide the developer overlay. The first press shows it. While it is visible:

- **R** or **View / Create** reloads the current room.
- The overlay shows the player's rounded position and velocity.
- The overlay shows Glide state, remaining time, pitch angle, and preserved momentum speed.
- The overlay shows whether Pounce is ready, active, or cooling down.

Reloading the room restores the practice dummy and the player's starting position. Saved control bindings remain active.

## Files and responsibilities

| File | Responsibility |
| --- | --- |
| `scenes/ui/dev_mode.tscn` | The overlay's visible nodes and layout |
| `scripts/dev_mode.gd` | Toggle, reset, and live readout behavior |
| `project.godot` | Input actions such as `toggle_dev_mode` and `dev_reset_room` |
| `scenes/main.tscn` | Adds one `DevMode` instance to the movement room |

Keep development-only behavior inside the dev-mode scene and script where practical. Gameplay code must not require dev mode to exist.

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

The real status text contains several lines, so extend it rather than replacing useful existing readouts.

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
- Do not make combat, movement, or level scenes depend on the overlay.
- Do not use dev mode to silently change normal difficulty or final controls.
- Prefer a short readout or one-purpose command over a general cheat framework.
- Remove or explicitly disable unsafe developer actions before a public build.
