extends Control

signal play_requested

const TILESET_CHOICES: Array[Dictionary] = [
	{"name": "Mossy", "path": "res://assets/tilemaps/mossy_tileset.tres"},
	{"name": "Cave", "path": "res://assets/tilemaps/cave_tileset.tres"},
	{"name": "Stringstar", "path": "res://assets/tilemaps/stringstar_tileset.tres"},
	{"name": "Tinyforest", "path": "res://assets/tilemaps/tinyforest_tileset.tres"},
]
const LAYER_NAMES: Array[String] = ["Background", "Terrain", "Decoration", "Foreground"]
const LAYER_DEPTHS: Array[int] = [-8, 0, 2, 8]
const SAVE_VERSION := 1
const UI_NAVIGATION_ACTIONS: Array[StringName] = [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]
const PLAYER_DPAD_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"glide_dive", &"glide_climb"]

@export_category("Editor")
@export var save_directory := "res://level_edits"
@export var controller_cursor_speed := 760.0
@export var controller_deadzone := 0.2
@export var preview_zoom := 0.25
@export var max_undo_strokes := 100
@export var camera_zoom_step := 1.15
@export var minimum_camera_zoom := 0.25
@export var maximum_camera_zoom := 1.8

@onready var layer_picker: OptionButton = $Dock/Margin/Content/LayerPicker
@onready var tileset_picker: OptionButton = $Dock/Margin/Content/TilesetPicker
@onready var source_picker: OptionButton = $Dock/Margin/Content/SourcePicker
@onready var palette: GridContainer = $Dock/Margin/Content/PaletteScroll/Palette
@onready var selection_label: Label = $Dock/Margin/Content/Selection
@onready var feedback_label: Label = $Dock/Margin/Content/Feedback
@onready var save_button: Button = $Dock/Margin/Content/Actions/SaveButton
@onready var play_button: Button = $Dock/Margin/Content/Actions/PlayButton
@onready var dock: PanelContainer = $Dock
@onready var paint_button: Button = $Dock/Margin/Content/ToolRow/PaintButton
@onready var erase_button: Button = $Dock/Margin/Content/ToolRow/EraseButton
@onready var undo_button: Button = $Dock/Margin/Content/ToolRow/UndoButton
@onready var preview_picture: TextureRect = $Dock/Margin/Content/PreviewPicture
@onready var preview_viewport: SubViewport = $PreviewViewport
@onready var preview_camera: Camera2D = $PreviewViewport/PreviewCamera
@onready var zoom_out_button: Button = $Dock/Margin/Content/CameraZoomRow/ZoomOutButton
@onready var zoom_in_button: Button = $Dock/Margin/Content/CameraZoomRow/ZoomInButton
@onready var zoom_label: Label = $Dock/Margin/Content/CameraZoomRow/ZoomLabel

var room: Node2D
var player_camera: Camera2D
var edit_root: Node2D
var cursor_outline: Line2D
var tileset_paths: Array[String] = []
var edit_layers: Dictionary = {}
var selected_atlas_coords := Vector2i(-1, -1)
var cursor_world := Vector2.ZERO
var cursor_screen_position := Vector2.ZERO
var controller_aiming := false
var mouse_painting := false
var mouse_erasing := false
var dirty := false
var erase_tool_selected := false
var stroke_active := false
var current_stroke: Dictionary = {}
var undo_strokes: Array[Dictionary] = []
var reserved_input_events: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Keep the editor usable while gameplay is paused.
	_resize_editor() # Fill the actual viewport even when parented under a CanvasLayer.
	get_viewport().size_changed.connect(_resize_editor) # Keep the right dock anchored after window resizing.
	room = get_parent().get_parent() as Node2D # The dev overlay is a direct child of the room.
	player_camera = room.get_node("Player/Camera2D") as Camera2D # Zoom the character-following camera, not the small preview camera.
	preview_viewport.world_2d = room.get_world_2d() # Render the live room in a separate small camera.
	preview_picture.texture = preview_viewport.get_texture() # Display the camera as an in-menu picture.
	preview_camera.zoom = Vector2.ONE * preview_zoom # Fit the nearby building area in the preview.
	preview_camera.make_current() # Give the small viewport its own viewpoint.
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED # Avoid extra rendering during normal play.
	call_deferred("_build_edit_root") # Add runtime world nodes after the room finishes entering the tree.
	_fill_layer_picker() # Expose visual and collision layer choices.
	_fill_tileset_picker() # Include converted sets and sets already used by this room.
	layer_picker.item_selected.connect(_on_layer_selected) # Update placement depth when the layer changes.
	tileset_picker.item_selected.connect(_on_tileset_selected) # Rebuild sources for a newly chosen TileSet.
	source_picker.item_selected.connect(_on_source_selected) # Rebuild the visual tile palette.
	paint_button.pressed.connect(_select_paint_tool) # Make left-click place the selected tile.
	erase_button.pressed.connect(_select_erase_tool) # Make left-click erase editor-owned tiles.
	undo_button.pressed.connect(undo_last_stroke) # Offer controller-accessible undo.
	zoom_out_button.pressed.connect(_change_camera_zoom.bind(-1)) # Make camera zoom usable by controller menus.
	zoom_in_button.pressed.connect(_change_camera_zoom.bind(1)) # Provide the matching zoom-in control.
	_update_zoom_label() # Show the player's current camera scale.
	save_button.pressed.connect(save_edits) # Persist this room's runtime tile changes.
	play_button.pressed.connect(_on_play_pressed) # Test the room immediately after editing.
	_rebuild_sources() # Start with the first available atlas.
	call_deferred("load_edits") # Wait until the room has a stable scene path.


func _resize_editor() -> void:
	size = get_viewport_rect().size # Give the world overlay a real viewport-sized layout.


func _reserve_editor_inputs() -> void:
	if not reserved_input_events.is_empty():
		return # Do not remove the same global bindings twice.
	for action: StringName in UI_NAVIGATION_ACTIONS:
		var removed: Array[InputEvent] = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
				removed.append(event.duplicate() as InputEvent) # Preserve user and default stick navigation for later.
				InputMap.action_erase_event(action, event) # Stop movement from changing focused editor buttons.
		reserved_input_events[action] = removed
	for action: StringName in PLAYER_DPAD_ACTIONS:
		var removed: Array[InputEvent] = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]:
				removed.append(event.duplicate() as InputEvent) # Remember D-pad movement assignments.
				InputMap.action_erase_event(action, event) # Reserve D-pad for editing controls.
		reserved_input_events[action] = removed


func _restore_editor_inputs() -> void:
	for action: StringName in reserved_input_events:
		for event: InputEvent in reserved_input_events[action]:
			InputMap.action_add_event(action, event) # Restore exactly the removed controller bindings.
	reserved_input_events.clear() # Let the editor open cleanly again later.


func _change_camera_zoom(direction: int) -> void:
	var zoom_factor := pow(camera_zoom_step, direction)
	var target_zoom := clampf(player_camera.zoom.x * zoom_factor, minimum_camera_zoom, maximum_camera_zoom)
	player_camera.zoom = Vector2.ONE * target_zoom # Zoom around the character-following camera.
	_update_zoom_label() # Show the new scale beside the controls.


func _update_zoom_label() -> void:
	zoom_label.text = "Camera %d%%" % roundi(player_camera.zoom.x * 100.0) # Display a familiar percent rather than a raw Vector2.


func _build_edit_root() -> void:
	edit_root = Node2D.new()
	edit_root.name = "LevelEditorTiles"
	room.add_child(edit_root) # Do not set owner, so edits never alter the .tscn scene.
	cursor_outline = Line2D.new()
	cursor_outline.name = "EditorCursor"
	cursor_outline.width = 3.0
	cursor_outline.default_color = Color(1.0, 0.82, 0.24, 0.95)
	cursor_outline.z_index = 100
	cursor_outline.visible = false
	room.add_child(cursor_outline) # Draw the placement cursor above room artwork.


func _fill_layer_picker() -> void:
	for layer_name: String in LAYER_NAMES:
		layer_picker.add_item("Layer: " + layer_name) # Keep the TileMap role visible without a separate label.
	layer_picker.select(1) # Start with collidable terrain.


func _fill_tileset_picker() -> void:
	var preferred_path := ""
	for choice: Dictionary in TILESET_CHOICES:
		_add_tileset_choice(str(choice["name"]), str(choice["path"])) # Register converted art.
	_add_tilesets_from_directory("res://assets/tilemaps") # Discover TileSets added after this editor was built.
	for child: Node in room.find_children("*", "TileMapLayer", true, false):
		var existing_layer := child as TileMapLayer
		if existing_layer.tile_set != null:
			var resource_path := existing_layer.tile_set.resource_path
			if not resource_path.is_empty():
				_add_tileset_choice(resource_path.get_file().get_basename().capitalize(), resource_path) # Include room-specific art.
				if preferred_path.is_empty() and not existing_layer.get_used_cells().is_empty():
					preferred_path = resource_path # Favor art already painted in this room.
	if tileset_picker.item_count > 0:
		tileset_picker.select(maxi(tileset_paths.find(preferred_path), 0)) # Start with the room's current art when possible.


func _add_tilesets_from_directory(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return # Missing optional art folders should not stop the editor.
	for filename: String in directory.get_files():
		if filename.ends_with(".tres"):
			var resource_path := directory_path.path_join(filename)
			_add_tileset_choice(filename.get_basename().replace("_", " ").capitalize(), resource_path) # List all imported TileSet resources.
	for folder_name: String in directory.get_directories():
		_add_tilesets_from_directory(directory_path.path_join(folder_name)) # Include TileSets in subfolders too.


func _add_tileset_choice(display_name: String, resource_path: String) -> void:
	if resource_path in tileset_paths or not ResourceLoader.exists(resource_path, "TileSet"):
		return # Avoid duplicate and missing TileSets.
	tileset_paths.append(resource_path)
	tileset_picker.add_item("Art: " + display_name) # Identify this picker as the TileMap art library.


func _selected_tileset() -> TileSet:
	if tileset_picker.selected < 0 or tileset_picker.selected >= tileset_paths.size():
		return null # No valid TileSet is available.
	return load(tileset_paths[tileset_picker.selected]) as TileSet # Reuse the imported TileSet resource.


func _rebuild_sources() -> void:
	source_picker.clear() # Remove atlas sources from the old TileSet.
	var tile_set := _selected_tileset()
	if tile_set == null:
		_rebuild_palette() # Show an empty palette when assets are missing.
		return
	for source_index: int in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(source_index)
		var source := tile_set.get_source(source_id)
		if source is TileSetAtlasSource:
			source_picker.add_item("%d: %s" % [source_id, source.resource_name if not source.resource_name.is_empty() else "Tiles"], source_id) # Only atlas sources have paintable thumbnails.
	if source_picker.item_count > 0:
		source_picker.select(0) # Start at the main tile atlas.
	_rebuild_palette() # Populate thumbnail buttons for the selected source.


func _rebuild_palette() -> void:
	for child: Node in palette.get_children():
		child.free() # Discard thumbnails before choosing focus in the replacement palette.
	selected_atlas_coords = Vector2i(-1, -1)
	selection_label.text = "Select a tile"
	var atlas := _selected_atlas()
	if atlas == null:
		return # Missing or unsupported source has no thumbnails.
	var button_group := ButtonGroup.new()
	for tile_index: int in atlas.get_tiles_count():
		var atlas_coords := atlas.get_tile_id(tile_index)
		var thumbnail := AtlasTexture.new()
		thumbnail.atlas = atlas.texture
		thumbnail.region = atlas.get_tile_texture_region(atlas_coords)
		var tile_button := Button.new()
		tile_button.custom_minimum_size = Vector2(72.0, 72.0)
		tile_button.icon = thumbnail
		tile_button.expand_icon = true
		tile_button.toggle_mode = true
		tile_button.button_group = button_group
		tile_button.tooltip_text = "Tile %s" % atlas_coords
		tile_button.pressed.connect(_select_tile.bind(atlas_coords)) # Let mouse and controller choose the same tile.
		palette.add_child(tile_button) # Add a keyboard-focusable visual tile button.
		if tile_index == 0:
			tile_button.button_pressed = true
			_select_tile(atlas_coords) # Give the user an immediately usable paint tile.


func _selected_atlas() -> TileSetAtlasSource:
	var tile_set := _selected_tileset()
	if tile_set == null or source_picker.selected < 0:
		return null # There is no selected atlas source.
	return tile_set.get_source(source_picker.get_selected_id()) as TileSetAtlasSource # Match the source dropdown ID.


func _select_tile(atlas_coords: Vector2i) -> void:
	selected_atlas_coords = atlas_coords
	selection_label.text = "Tile %s  •  %s" % [atlas_coords, LAYER_NAMES[layer_picker.selected]] # Confirm the current brush.
	_update_cursor_outline() # Match the cursor to the chosen TileSet grid.


func open_editor() -> void:
	visible = true # Keep the dock visible while the room is running.
	_reserve_editor_inputs() # Give left stick to the dinosaur and D-pad to the editor UI.
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS # Refresh the room picture while painting.
	cursor_screen_position = get_viewport_rect().size * 0.5
	cursor_world = get_viewport().get_canvas_transform().affine_inverse() * cursor_screen_position # Aim at the center of the current view.
	controller_aiming = true
	cursor_outline.visible = true
	_update_cursor_outline() # Show the first paintable cell.
	_update_preview_camera() # Show the surrounding room as soon as editing begins.
	if palette.get_child_count() > 0:
		(palette.get_child(0) as Control).grab_focus() # Make the palette controller-navigable.


func close_editor() -> void:
	_finish_stroke() # Keep a drag undoable even when the menu closes mid-stroke.
	_restore_editor_inputs() # Return normal stick and D-pad menu bindings.
	visible = false # Return the screen to gameplay.
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED # Stop the second camera outside edit mode.
	cursor_outline.visible = false
	mouse_painting = false
	mouse_erasing = false
	controller_aiming = false


func _exit_tree() -> void:
	_restore_editor_inputs() # Do not leave global InputMap changed after a room transition.


func _input(event: InputEvent) -> void:
	if not visible:
		return # Leave ordinary gameplay input untouched.
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_on_play_pressed() # Escape, Menu, or B closes editing before another menu opens.
		get_viewport().set_input_as_handled() # Prevent a second menu from changing input bindings mid-edit.
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_Z and (event.ctrl_pressed or event.meta_pressed):
		undo_last_stroke() # Ctrl+Z reverses the last completed paint or erase stroke.
		get_viewport().set_input_as_handled() # Keep the shortcut out of other focused controls.
		return
	if event is InputEventKey and event.pressed and not event.echo and not event.ctrl_pressed and not event.meta_pressed:
		if event.physical_keycode in [KEY_EQUAL, KEY_KP_ADD]:
			_change_camera_zoom(1) # Plus or equals zooms toward the dinosaur.
			get_viewport().set_input_as_handled() # Keep the shortcut out of GUI controls.
			return
		if event.physical_keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			_change_camera_zoom(-1) # Minus zooms away from the dinosaur.
			get_viewport().set_input_as_handled() # Keep the shortcut out of GUI controls.
			return
	if event is InputEventMouseButton and event.pressed and not dock.get_global_rect().has_point(event.position):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_change_camera_zoom(1) # Wheel up zooms in without painting a cell.
			get_viewport().set_input_as_handled() # Keep the wheel from reaching the world.
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_change_camera_zoom(-1) # Wheel down reveals more of the room.
			get_viewport().set_input_as_handled() # Keep the wheel from reaching the world.
			return
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_painting = false # Stop dragging even when released over the dock.
			_finish_stroke() # Group the entire mouse drag as one undo step.
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			mouse_erasing = false # Stop erase dragging anywhere in the viewport.
			_finish_stroke() # Group the entire erase drag as one undo step.
	if event is InputEventMouseMotion and not dock.get_global_rect().has_point(event.position):
		cursor_screen_position = event.position # Remember the pointer position as the character camera moves.
		cursor_world = get_viewport().get_canvas_transform().affine_inverse() * cursor_screen_position # Move the brush with the pointer.
		controller_aiming = false
		_update_cursor_outline() # Snap the highlight to the hovered cell.
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			_paint_at_cursor(false) # RB places a tile under the controller cursor.
		elif event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_paint_at_cursor(true) # LB erases an editor-owned tile.


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event is InputEventMouseButton or not event.pressed:
		return # GUI and non-paint input are handled elsewhere.
	if dock.get_global_rect().has_point(event.position):
		return # Never paint through the editor dock.
	cursor_screen_position = event.position
	cursor_world = get_viewport().get_canvas_transform().affine_inverse() * cursor_screen_position
	controller_aiming = false # Let the mouse own brush position after a world click.
	if event.button_index == MOUSE_BUTTON_LEFT:
		mouse_painting = true
		_begin_stroke() # Start one undo record for this drag.
		_paint_at_cursor(erase_tool_selected) # Left-click uses the selected Paint or Erase tool.
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		mouse_erasing = true
		_begin_stroke() # Right-click begins a quick erase stroke.
		_paint_at_cursor(true) # Right-click erases only editor-added tiles.
	_update_cursor_outline() # Show the exact edited cell.


func _process(delta: float) -> void:
	if not visible:
		return # Keep the editor dormant during play.
	var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if stick.length() > controller_deadzone:
		cursor_screen_position += stick * controller_cursor_speed * delta # Pan the controller cursor across the visible screen.
		cursor_screen_position.x = clampf(cursor_screen_position.x, 0.0, dock.position.x - 1.0) # Keep the brush out of the dock.
		cursor_screen_position.y = clampf(cursor_screen_position.y, 0.0, size.y) # Keep the brush inside the viewport.
		controller_aiming = true
	if not controller_aiming and not dock.get_global_rect().has_point(get_viewport().get_mouse_position()):
		cursor_screen_position = get_viewport().get_mouse_position() # Track a stationary pointer while the player camera scrolls.
	cursor_world = get_viewport().get_canvas_transform().affine_inverse() * cursor_screen_position # Follow camera movement without drifting off the pointer.
	_update_cursor_outline() # Keep the grid highlight under the current brush.
	_update_preview_camera() # Center the picture on the area being built.
	if mouse_painting or mouse_erasing:
		var mouse_position := get_viewport().get_mouse_position()
		if not dock.get_global_rect().has_point(mouse_position):
			cursor_screen_position = mouse_position
			cursor_world = get_viewport().get_canvas_transform().affine_inverse() * cursor_screen_position
			_paint_at_cursor(mouse_erasing or erase_tool_selected) # Fill or erase each crossed grid cell during a drag.
			_update_cursor_outline() # Follow the dragged mouse brush.


func _layer_key(layer_kind: int, resource_path: String) -> String:
	return "%d|%s" % [layer_kind, resource_path] # One overlay layer per role and TileSet.


func _get_edit_layer(layer_kind: int, resource_path: String, create_if_missing: bool) -> TileMapLayer:
	var key := _layer_key(layer_kind, resource_path)
	if edit_layers.has(key):
		return edit_layers[key] as TileMapLayer # Reuse existing runtime edits.
	if not create_if_missing or not ResourceLoader.exists(resource_path, "TileSet"):
		return null # Do not create a layer for a hover or invalid asset.
	var layer := TileMapLayer.new()
	layer.name = "Edited_%s_%d" % [LAYER_NAMES[layer_kind], edit_layers.size()]
	layer.tile_set = load(resource_path) as TileSet
	layer.z_index = LAYER_DEPTHS[layer_kind]
	layer.collision_enabled = layer_kind == 1 # Only Terrain tiles participate in physics.
	edit_root.add_child(layer) # Place tiles without changing authored room nodes.
	edit_layers[key] = layer
	return layer


func _paint_at_cursor(erase: bool) -> void:
	var single_cell_stroke := not stroke_active
	if single_cell_stroke:
		_begin_stroke() # Controller taps and direct calls are one-cell undo steps.
	if erase:
		_erase_at_cursor() # Remove the highest editor-added tile under the brush.
	else:
		_paint_selected_tile() # Place the chosen atlas tile on its selected TileMap layer.
	if single_cell_stroke:
		_finish_stroke() # Commit a tap without waiting for a mouse release.


func _paint_selected_tile() -> void:
	if selected_atlas_coords.x < 0 or source_picker.selected < 0 or layer_picker.selected < 0 or tileset_picker.selected < 0:
		return # A real tile selection is required before painting.
	var resource_path := tileset_paths[tileset_picker.selected]
	var layer_kind := layer_picker.selected
	var layer := _get_edit_layer(layer_kind, resource_path, true)
	if layer == null:
		return # Do not place a tile from a missing TileSet.
	var cell := layer.local_to_map(layer.to_local(cursor_world))
	var source_id := source_picker.get_selected_id()
	if layer.get_cell_source_id(cell) == source_id and layer.get_cell_atlas_coords(cell) == selected_atlas_coords:
		return # Dragging within one cell need not write repeatedly.
	_record_before_change(layer, layer_kind, resource_path, cell) # Remember the original tile for Ctrl+Z.
	layer.set_cell(cell, source_id, selected_atlas_coords) # Place one TileSet atlas tile and its optional collision.
	_mark_unsaved() # Prompt the user to save the changed room.


func _erase_at_cursor() -> void:
	var candidates: Array[Dictionary] = []
	for key: String in edit_layers:
		var layer := edit_layers[key] as TileMapLayer
		var cell := layer.local_to_map(layer.to_local(cursor_world))
		if layer.get_cell_source_id(cell) < 0:
			continue # Ignore empty editor layers and authored room art.
		var parts := key.split("|", true, 1)
		candidates.append({"layer": layer, "kind": int(parts[0]), "tileset": parts[1], "cell": cell}) # Collect painted overlays under the cursor.
	if candidates.is_empty():
		return # The eraser never changes tiles placed directly in a scene.
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return LAYER_DEPTHS[int(a["kind"])] > LAYER_DEPTHS[int(b["kind"])]) # Erase the topmost visible overlay first.
	var target: Dictionary = candidates[0]
	var target_layer := target["layer"] as TileMapLayer
	_record_before_change(target_layer, int(target["kind"]), str(target["tileset"]), target["cell"] as Vector2i) # Remember what erasing removed.
	target_layer.erase_cell(target["cell"] as Vector2i) # Remove one editor-added tile at the brush.
	_mark_unsaved() # Keep the erasure eligible for Save and Undo.


func _mark_unsaved() -> void:
	dirty = true
	feedback_label.text = "Unsaved changes • Save or Play to keep them." # Make persistence state visible.


func _begin_stroke() -> void:
	stroke_active = true
	current_stroke.clear() # Each stroke records a cell's original state only once.


func _record_before_change(layer: TileMapLayer, layer_kind: int, resource_path: String, cell: Vector2i) -> void:
	var change_key := "%s#%d,%d" % [_layer_key(layer_kind, resource_path), cell.x, cell.y]
	if current_stroke.has(change_key):
		return # Repainting the same cell in one drag keeps its first previous value.
	current_stroke[change_key] = {"kind": layer_kind, "tileset": resource_path, "cell": cell, "source": layer.get_cell_source_id(cell), "atlas": layer.get_cell_atlas_coords(cell), "alternative": layer.get_cell_alternative_tile(cell)} # Capture the old tile or empty state.


func _finish_stroke() -> void:
	if not stroke_active:
		return # Ignore releases that did not begin on the world.
	stroke_active = false
	if current_stroke.is_empty():
		return # Empty clicks do not create undo steps.
	var changes: Array[Dictionary] = []
	for change: Dictionary in current_stroke.values():
		changes.append(change) # Preserve every cell affected by the drag.
	undo_strokes.append({"changes": changes}) # Undo the whole drag together.
	if undo_strokes.size() > maxi(max_undo_strokes, 1):
		undo_strokes.pop_front() # Bound memory used by long editing sessions.
	current_stroke.clear()
	undo_button.disabled = false # Expose the new undo step to controller navigation.


func undo_last_stroke() -> void:
	_finish_stroke() # Include a stroke still being dragged when Ctrl+Z is pressed.
	mouse_painting = false # Do not immediately repaint an undone drag before mouse release.
	mouse_erasing = false # Do not immediately re-erase an undone drag before mouse release.
	if undo_strokes.is_empty():
		return # Nothing has been changed in this editing session.
	var stroke: Dictionary = undo_strokes.pop_back()
	for change: Dictionary in stroke["changes"]:
		var layer := _get_edit_layer(int(change["kind"]), str(change["tileset"]), true)
		if layer == null:
			continue # Skip a TileSet that disappeared after the stroke.
		var cell := change["cell"] as Vector2i
		if int(change["source"]) < 0:
			layer.erase_cell(cell) # Restore an originally empty cell.
		else:
			layer.set_cell(cell, int(change["source"]), change["atlas"] as Vector2i, int(change["alternative"])) # Restore the prior atlas tile.
	undo_button.disabled = undo_strokes.is_empty() # Reflect remaining history.
	_mark_unsaved() # Saved overlays must be rewritten after Undo.
	feedback_label.text = "Last stroke undone • Save or Play to keep it." # Confirm the action.


func _select_paint_tool() -> void:
	erase_tool_selected = false
	paint_button.set_pressed_no_signal(true) # Keep exactly one tool active.
	erase_button.set_pressed_no_signal(false) # Leave quick right-click erasing available.


func _select_erase_tool() -> void:
	erase_tool_selected = true
	paint_button.set_pressed_no_signal(false) # Turn left-click into an eraser.
	erase_button.set_pressed_no_signal(true) # Keep the chosen tool visibly selected.


func _update_preview_camera() -> void:
	preview_camera.global_position = cursor_world # Frame the nearby build area around the brush.


func _update_cursor_outline() -> void:
	if not visible or tileset_picker.selected < 0 or layer_picker.selected < 0:
		return # Nothing to outline without a target grid.
	var resource_path := tileset_paths[tileset_picker.selected]
	var layer := _get_edit_layer(layer_picker.selected, resource_path, true)
	if layer == null:
		return # A missing TileSet has no grid dimensions.
	var tile_size := Vector2(layer.tile_set.tile_size)
	var cell := layer.local_to_map(layer.to_local(cursor_world)) # Use the same cell conversion as painting and erasing.
	var cell_top_left := layer.map_to_local(cell) - tile_size * 0.5 # Godot returns the tile center from map_to_local().
	cursor_outline.position = room.to_local(layer.to_global(cell_top_left)) # Draw the frame in the room's coordinate space.
	cursor_outline.points = PackedVector2Array([Vector2.ZERO, Vector2(tile_size.x, 0.0), tile_size, Vector2(0.0, tile_size.y), Vector2.ZERO]) # Draw a one-cell placement frame.


func save_edits() -> void:
	var room_path := _room_scene_path()
	if room_path.is_empty():
		feedback_label.text = "Cannot save: room has no scene path."
		return # Persistence must have a stable room identity.
	var saved_layers: Array[Dictionary] = []
	for key: String in edit_layers:
		var layer := edit_layers[key] as TileMapLayer
		var cells: Array[Dictionary] = []
		for cell: Vector2i in layer.get_used_cells():
			var atlas_coords := layer.get_cell_atlas_coords(cell)
			cells.append({"x": cell.x, "y": cell.y, "source": layer.get_cell_source_id(cell), "atlas_x": atlas_coords.x, "atlas_y": atlas_coords.y, "alternative": layer.get_cell_alternative_tile(cell)}) # Store every painted cell.
		if cells.is_empty():
			continue # Empty runtime layers do not need a save record.
		var parts := key.split("|", true, 1)
		saved_layers.append({"kind": int(parts[0]), "tileset": parts[1], "cells": cells}) # Keep role, art, and cells together.
	var absolute_directory := ProjectSettings.globalize_path(save_directory)
	if DirAccess.make_dir_recursive_absolute(absolute_directory) != OK:
		feedback_label.text = "Could not create save folder."
		return # Do not claim the edit was saved.
	var save_file := FileAccess.open(_save_path(room_path), FileAccess.WRITE)
	if save_file == null:
		feedback_label.text = "Could not write level edits."
		return # Preserve the dirty state on a failed write.
	save_file.store_string(JSON.stringify({"version": SAVE_VERSION, "room": room_path, "layers": saved_layers}, "\t")) # Write a human-readable per-room overlay.
	save_file.close() # Flush the completed JSON file.
	dirty = false
	feedback_label.text = "Saved %d edited layer(s)." % saved_layers.size() # Confirm persistence to the player.


func load_edits() -> void:
	var room_path := _room_scene_path()
	if room_path.is_empty():
		return # A temporary room has no stable save identity.
	var save_path := _save_path(room_path)
	var migrating_legacy_save := false
	if not FileAccess.file_exists(save_path):
		save_path = "user://level_edits".path_join(room_path.md5_text() + ".json") # Find overlays made before editor previews existed.
		migrating_legacy_save = FileAccess.file_exists(save_path)
		if not migrating_legacy_save:
			return # New rooms simply have no saved overlay yet.
	var save_file := FileAccess.open(save_path, FileAccess.READ)
	if save_file == null:
		return # Keep the authored level playable if user data is unavailable.
	var parsed: Variant = JSON.parse_string(save_file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("version", -1)) != SAVE_VERSION or str(parsed.get("room", "")) != room_path:
		push_warning("Level editor ignored invalid saved edits for %s" % room_path) # Reject mismatched or outdated data.
		return
	for layer_data: Variant in parsed.get("layers", []):
		if not layer_data is Dictionary:
			continue # Skip malformed layer entries.
		var layer_kind := int(layer_data.get("kind", -1))
		var resource_path := str(layer_data.get("tileset", ""))
		if layer_kind < 0 or layer_kind >= LAYER_NAMES.size():
			continue # Accept only known visual roles.
		var layer := _get_edit_layer(layer_kind, resource_path, true)
		if layer == null:
			continue # Missing art should not prevent the rest of the room loading.
		for cell_data: Variant in layer_data.get("cells", []):
			if not cell_data is Dictionary:
				continue # Ignore malformed cells.
			var cell := Vector2i(int(cell_data.get("x", 0)), int(cell_data.get("y", 0)))
			var atlas_coords := Vector2i(int(cell_data.get("atlas_x", -1)), int(cell_data.get("atlas_y", -1)))
			var source_id := int(cell_data.get("source", -1))
			var source := layer.tile_set.get_source(source_id) if layer.tile_set.has_source(source_id) else null
			if source is TileSetAtlasSource and (source as TileSetAtlasSource).has_tile(atlas_coords):
				layer.set_cell(cell, source_id, atlas_coords, int(cell_data.get("alternative", 0))) # Reapply a validated painted tile.
	dirty = false
	feedback_label.text = "Loaded saved edits for this room." # Distinguish saved art from scene-authored art.
	if migrating_legacy_save:
		dirty = true
		save_edits() # Copy older user-data edits into the project so Godot's 2D editor can preview them.


func _room_scene_path() -> String:
	if not room.scene_file_path.is_empty():
		return room.scene_file_path # Prefer the exact room containing this dev overlay.
	if get_tree().current_scene != null:
		return get_tree().current_scene.scene_file_path # Support direct scene test runs.
	return "" # Unsaved temporary rooms cannot be persisted safely.


func _save_path(room_path: String) -> String:
	return save_directory.path_join(room_path.md5_text() + ".json") # Separate each room by a stable filename.


func _on_layer_selected(_index: int) -> void:
	selection_label.text = "Tile %s  •  %s" % [selected_atlas_coords, LAYER_NAMES[layer_picker.selected]] # Reflect the target drawing role.
	_update_cursor_outline() # Refresh the placement frame after a role change.


func _on_tileset_selected(_index: int) -> void:
	_rebuild_sources() # Switch palettes to the chosen TileSet.
	_update_cursor_outline() # Update the cursor to its grid size.


func _on_source_selected(_index: int) -> void:
	_rebuild_palette() # Show tiles from the chosen atlas source.


func _on_play_pressed() -> void:
	if dirty:
		save_edits() # Keep changes when switching directly back to play.
		if dirty:
			return # Keep the editor open if saving failed.
	play_requested.emit() # Ask the dev menu to unpause gameplay.
