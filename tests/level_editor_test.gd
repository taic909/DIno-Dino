extends Node2D # Exercise live painting, save/reload, and return to gameplay.

@onready var dev_mode: CanvasLayer = $Main/DevMode
@onready var player: CharacterBody2D = $Main/Player


func _ready() -> void:
	call_deferred("_run") # Let the editor finish creating its runtime world nodes.


func _run() -> void:
	var editor := dev_mode.get_node("LevelEditor") as Control
	var original_ui_right_count := InputMap.action_get_events("ui_right").size()
	var original_move_right_count := InputMap.action_get_events("move_right").size()
	if not _check(int(ProjectSettings.get_setting("display/window/size/window_width_override")) == 1920 and int(ProjectSettings.get_setting("display/window/size/window_height_override")) == 1080, "Project output resolution is not 1920 by 1080."):
		return
	editor.save_directory = "res://tests/.level_editor_test_output" # Keep test data in the writable project directory.
	dev_mode.call("_open_dev_mode") # Pause the room through the real developer menu.
	dev_mode.get_node("Overlay/Margin/Content/EditLevelButton").emit_signal("pressed") # Enter live editing through its menu control.
	if not _check(editor.visible and not get_tree().paused, "Editor did not keep the room running."):
		return
	if not _check(InputMap.action_get_events("ui_right").size() < original_ui_right_count and InputMap.action_get_events("move_right").size() < original_move_right_count, "Editor did not separate left-stick movement from D-pad navigation."):
		return
	var focused_tile := get_viewport().gui_get_focus_owner()
	var stick_motion := InputEventJoypadMotion.new()
	stick_motion.device = 0
	stick_motion.axis = JOY_AXIS_LEFT_X
	stick_motion.axis_value = 1.0
	var start_position := player.global_position
	Input.parse_input_event(stick_motion) # Move with the controller while the palette retains focus.
	await get_tree().process_frame # Let Godot dispatch the stick motion.
	await get_tree().physics_frame # Allow live player movement to process.
	await get_tree().physics_frame # Observe the resulting position after a second step.
	stick_motion.axis_value = 0.0
	Input.parse_input_event(stick_motion) # Release the controller axis for later checks.
	if not _check(player.global_position.x > start_position.x and get_viewport().gui_get_focus_owner() == focused_tile, "Left stick did not move the player independently of editor focus."):
		return
	var player_camera := player.get_node("Camera2D") as Camera2D
	var starting_zoom := player_camera.zoom.x
	(editor.get_node("Dock/Margin/Content/CameraZoomRow/ZoomOutButton") as Button).emit_signal("pressed") # Test controller-accessible zoom out.
	if not _check(player_camera.zoom.x < starting_zoom, "Editor zoom-out button did not widen the character camera."):
		return
	(editor.get_node("Dock/Margin/Content/CameraZoomRow/ZoomInButton") as Button).emit_signal("pressed") # Test the matching zoom-in action.
	if not _check(is_equal_approx(player_camera.zoom.x, starting_zoom), "Editor zoom-in button did not restore the camera scale."):
		return
	var wheel := InputEventMouseButton.new()
	wheel.position = Vector2(300.0, 300.0) # Stay over the world instead of the palette dock.
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	editor.call("_input", wheel) # Exercise the world-view wheel shortcut directly in headless mode.
	if not _check(player_camera.zoom.x < starting_zoom, "Mouse wheel did not zoom out from the character."):
		return
	player.set_physics_process(false) # Freeze the room actor for deterministic grid-cell assertions below.
	player_camera.position_smoothing_enabled = false # Stop camera easing from shifting the world under the test cursor.
	await get_tree().process_frame # Apply the snapped camera transform before painting.
	var screen_before_follow: Vector2 = editor.cursor_screen_position
	var world_before_follow: Vector2 = editor.cursor_world
	player.global_position.x += 128.0 # Scroll the character camera while the controller brush rests.
	await get_tree().process_frame # Let the player camera and brush update together.
	await get_tree().process_frame # Observe their final positions after the camera transform.
	if not _check(editor.cursor_screen_position == screen_before_follow and editor.cursor_world.x > world_before_follow.x, "Brush did not stay in place on screen while the character camera moved."):
		return
	var tileset_picker := editor.get_node("Dock/Margin/Content/TilesetPicker") as OptionButton
	if not _check(tileset_picker.item_count >= 5, "TileMap art list did not discover archived and converted TileSets."):
		return
	var picture := editor.get_node("Dock/Margin/Content/PreviewPicture") as TextureRect
	var picture_viewport := editor.get_node("PreviewViewport") as SubViewport
	if not _check(picture.texture == picture_viewport.get_texture() and picture_viewport.world_2d == ($Main as Node2D).get_world_2d(), "Nearby room picture is not rendering the live world."):
		return
	await get_tree().process_frame # Let the dock size its palette and preview picture.
	var palette_scroll := editor.get_node("Dock/Margin/Content/PaletteScroll") as ScrollContainer
	if not _check(picture.size.y >= 80.0 and palette_scroll.size.y >= 80.0, "Preview picture or tile palette does not fit in the editor dock."):
		return
	_aim_at_world(editor, Vector2(512.0, 384.0))
	editor.call("_update_preview_camera") # Center the picture on a new build point.
	if not _check((editor.get_node("PreviewViewport/PreviewCamera") as Camera2D).global_position == Vector2(512.0, 384.0), "Live room picture did not follow the brush."):
		return
	_aim_at_world(editor, Vector2(384.0, 384.0)) # Choose a cell away from existing graybox geometry.
	editor.call("_paint_at_cursor", false) # Paint the selected atlas tile.
	var layer: TileMapLayer = editor.edit_layers.values()[0] as TileMapLayer
	var cell := layer.local_to_map(layer.to_local(Vector2(384.0, 384.0)))
	if not _check(layer.get_cell_source_id(cell) >= 0 and layer.collision_enabled, "Painted terrain tile or collision layer is missing."):
		return
	var tile_size := Vector2(layer.tile_set.tile_size)
	_aim_at_world(editor, Vector2(384.0, 384.0) + tile_size * 0.25) # Hover inside the painted cell, away from its edge.
	editor.call("_update_cursor_outline") # Compare the visual frame to the tile that painting actually changes.
	var hovered_cell := layer.local_to_map(layer.to_local(editor.cursor_world))
	var expected_outline_position := ($Main as Node2D).to_local(layer.to_global(layer.map_to_local(hovered_cell) - tile_size * 0.5))
	if not _check((editor.cursor_outline as Line2D).position.is_equal_approx(expected_outline_position), "Brush indicator does not align with the painted tile cell."):
		return
	_aim_at_world(editor, Vector2(640.0, 384.0)) # Move the controller brush to another cell.
	await _press_controller_button(JOY_BUTTON_RIGHT_SHOULDER) # Paint with the advertised RB control.
	var controller_cell := layer.local_to_map(layer.to_local(Vector2(640.0, 384.0)))
	if not _check(layer.get_cell_source_id(controller_cell) >= 0, "Controller RB did not paint a tile."):
		return
	await _press_controller_button(JOY_BUTTON_LEFT_SHOULDER) # Erase with the advertised LB control.
	if not _check(layer.get_cell_source_id(controller_cell) == -1, "Controller LB did not erase its tile."):
		return
	await _press_undo_shortcut() # Restore the controller-erased tile with Ctrl+Z.
	if not _check(layer.get_cell_source_id(controller_cell) >= 0, "Ctrl+Z did not undo an erasure."):
		return
	(editor.get_node("Dock/Margin/Content/ToolRow/UndoButton") as Button).emit_signal("pressed") # Undo the earlier controller paint using the visible button.
	if not _check(layer.get_cell_source_id(controller_cell) == -1, "Undo button did not reverse a paint stroke."):
		return
	(editor.get_node("Dock/Margin/Content/ToolRow/EraseButton") as Button).emit_signal("pressed") # Choose the dedicated eraser.
	_aim_at_world(editor, Vector2(384.0, 384.0))
	editor.call("_paint_at_cursor", editor.erase_tool_selected) # Erase the first painted tile with the selected tool.
	if not _check(layer.get_cell_source_id(cell) == -1, "Dedicated Erase tool did not remove a tile."):
		return
	editor.call("undo_last_stroke") # Bring the tile back for persistence assertions.
	if not _check(layer.get_cell_source_id(cell) >= 0, "Undo did not restore the erased terrain tile."):
		return
	(editor.get_node("Dock/Margin/Content/ToolRow/PaintButton") as Button).emit_signal("pressed") # Return to painting.
	editor.call("_begin_stroke") # Simulate a mouse drag spanning two tiles.
	_aim_at_world(editor, Vector2(768.0, 384.0))
	editor.call("_paint_at_cursor", false)
	_aim_at_world(editor, Vector2(896.0, 384.0))
	editor.call("_paint_at_cursor", false)
	editor.call("_finish_stroke") # Commit both cells as one undo step.
	editor.call("undo_last_stroke") # Reverse the entire drag in one action.
	if not _check(layer.get_cell_source_id(Vector2i(6, 3)) == -1 and layer.get_cell_source_id(Vector2i(7, 3)) == -1, "One Undo did not reverse the full paint drag."):
		return
	(editor.get_node("Dock/Margin/Content/LayerPicker") as OptionButton).select(0) # Switch to the non-solid background role.
	_aim_at_world(editor, Vector2(512.0, 384.0))
	editor.call("_paint_at_cursor", false) # Place a decorative background block.
	var background_layer: TileMapLayer = editor.edit_layers.values()[1] as TileMapLayer
	if not _check(not background_layer.collision_enabled, "Background tiles unexpectedly have physics collision."):
		return
	editor.call("save_edits") # Persist the painted overlay.
	if not _check(not editor.dirty, "Editor did not save the painted tile."):
		return
	var preview := $Main/LevelEditPreview as Node2D
	preview.save_directory = editor.save_directory # Point the editor preview at this test's isolated save.
	preview.call("reload_preview") # Reconstruct the tiles shown in Godot's 2D canvas.
	if not _check(preview.get_child_count() == 2, "Editor preview did not create both painted layer roles."):
		return
	var preview_layer := preview.get_child(0) as TileMapLayer
	if not _check(preview_layer.get_cell_source_id(cell) >= 0 and preview_layer.owner == null, "Saved terrain was not reconstructed as a non-destructive editor preview."):
		return
	layer.erase_cell(cell) # Simulate a fresh room without this runtime cell.
	editor.call("load_edits") # Restore the saved tile.
	if not _check(layer.get_cell_source_id(cell) >= 0, "Saved tile was not restored."):
		return
	editor.get_node("Dock/Margin/Content/Actions/PlayButton").emit_signal("pressed") # Return to the running game.
	if not _check(not editor.visible and not get_tree().paused, "Done did not close the editor cleanly."):
		return
	if not _check(InputMap.action_get_events("ui_right").size() == original_ui_right_count and InputMap.action_get_events("move_right").size() == original_move_right_count, "Editor did not restore normal controller bindings."):
		return
	var test_file: String = editor.save_directory.path_join("res://scenes/main.tscn".md5_text() + ".json")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_file)) # Remove only this test's known output file.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(editor.save_directory)) # Remove the now-empty test directory.
	print("PASS: live editor movement, camera zoom, tile painting, preview, and persistence") # Report the full workflow.
	get_tree().quit() # Exit after successful assertions.


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true # Continue when behavior matches expectation.
	push_error(message) # Include the failing feature in test output.
	get_tree().quit(1) # Signal test failure to the command line.
	return false # Stop dependent assertions.


func _aim_at_world(editor: Control, world_position: Vector2) -> void:
	editor.cursor_world = world_position # Aim the test brush at a chosen room cell.
	editor.cursor_screen_position = get_viewport().get_canvas_transform() * world_position # Keep its screen-space controller cursor in sync.
	editor.controller_aiming = true # Avoid the headless mouse position overriding this test aim.


func _press_controller_button(button_index: int) -> void:
	var press := InputEventJoypadButton.new()
	press.device = 0
	press.button_index = button_index
	press.pressed = true
	Input.parse_input_event(press) # Dispatch through the live editor's input handler.
	await get_tree().process_frame # Let the queued press reach the editor.
	var release := press.duplicate() as InputEventJoypadButton
	release.pressed = false
	Input.parse_input_event(release) # Finish the button click.
	await get_tree().process_frame # Finish processing the release before asserting.


func _press_undo_shortcut() -> void:
	var undo_press := InputEventKey.new()
	undo_press.physical_keycode = KEY_Z
	undo_press.ctrl_pressed = true
	undo_press.pressed = true
	Input.parse_input_event(undo_press) # Send a real Ctrl+Z-shaped editor shortcut.
	await get_tree().process_frame # Let the editor apply the queued input.
	var undo_release := undo_press.duplicate() as InputEventKey
	undo_release.pressed = false
	Input.parse_input_event(undo_release) # Complete the shortcut for later key checks.
	await get_tree().process_frame # Keep subsequent assertions on a fresh frame.
