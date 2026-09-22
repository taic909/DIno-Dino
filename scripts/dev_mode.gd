extends CanvasLayer

@export_category("Enemy Spawns")
@export var spawnable_enemies: Array[PackedScene] = [
	preload("res://scenes/enemy/walker_beetle.tscn"),
	preload("res://scenes/enemy/practice_dummy.tscn"),
]
@export var spawn_distance := 190.0
@export var floor_search_height := 96.0
@export var floor_search_depth := 700.0
@export var default_floor_offset := 35.0

@onready var overlay: PanelContainer = $Overlay
@onready var status_label: Label = $Overlay/Margin/Content/Status
@onready var flight_mode_button: CheckButton = $Overlay/Margin/Content/FlightModeButton
@onready var enemy_picker: OptionButton = $Overlay/Margin/Content/SpawnRow/EnemyPicker
@onready var spawn_button: Button = $Overlay/Margin/Content/SpawnRow/SpawnButton
@onready var clear_button: Button = $Overlay/Margin/Content/ClearButton
@onready var edit_level_button: Button = $Overlay/Margin/Content/EditLevelButton
@onready var spawn_feedback: Label = $Overlay/Margin/Content/SpawnFeedback
@onready var player: CharacterBody2D = get_parent().get_node("Player") as CharacterBody2D

var enabled := false
var paused_before_open := false
var collision_shapes_visible := false
var room_paths: Array[String] = []
var spawned_enemies: Array[Node2D] = []
var level_editor: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Keep developer controls available around pause state.
	overlay.visible = false # Start with the developer overlay hidden.
	get_tree().debug_collisions_hint = false # Start with collision drawing hidden.
	_refresh_room_paths() # Collect the current MetSys test-room list.
	_fill_enemy_picker() # Build the spawn list from the scenes registered above.
	flight_mode_button.toggled.connect(_on_flight_mode_toggled) # Allow mouse or controller to change developer flight.
	player.dev_flight_changed.connect(_on_player_flight_changed) # Reflect the live shortcut in the menu.
	spawn_button.pressed.connect(_on_spawn_pressed) # Give the selected enemy a single spawn action.
	clear_button.pressed.connect(_on_clear_pressed) # Remove only enemies created by this menu.
	edit_level_button.pressed.connect(_on_edit_level_pressed) # Open the live tile editor from the dev menu.
	level_editor = preload("res://scenes/ui/level_editor.tscn").instantiate() as Control
	add_child(level_editor) # Give every room with DevMode the same editor without changing authored scenes.
	level_editor.play_requested.connect(_close_dev_mode) # Resume gameplay directly from the editor.


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_mode"):
		if enabled:
			_close_dev_mode() # Close either the normal menu or the live editor.
		else:
			_open_dev_mode() # Pause the room before showing developer controls.
		get_viewport().set_input_as_handled()
		return

	if level_editor.visible:
		return # Do not trigger room cycling or reset while painting tiles.
	if enabled and event.is_action_pressed("ui_cancel"):
		_close_dev_mode() # Let B / Circle back out of the developer menu.
		get_viewport().set_input_as_handled() # Keep the menu-back press from reaching gameplay.
		return # Do not treat this press as another developer command.

	if enabled and event.is_action_pressed("dev_toggle_collision_shapes"): # Handle the collision-view command.
		collision_shapes_visible = not collision_shapes_visible # Toggle hitbox and hurtbox visibility.
		get_tree().debug_collisions_hint = collision_shapes_visible # Draw the real physics shapes.
		get_viewport().set_input_as_handled() # Consume the developer input.
		return # Stop processing this event.

	if enabled and event.is_action_pressed("dev_cycle_room"): # Handle the one-button room cycle.
		get_viewport().set_input_as_handled() # Consume the developer input.
		_change_room() # Load the next room, wrapping to the first after the last.
		return # Stop processing this event.

	if enabled and event.is_action_pressed("dev_reset_room"): # Handle the room-reset command.
		get_viewport().set_input_as_handled() # Consume the input before the current overlay is destroyed.
		get_tree().paused = false # Let the replacement room start running normally.
		get_tree().reload_current_scene() # Reload the room after handling the event.
		return # Stop processing this event.


func _process(_delta: float) -> void:
	if not enabled or not is_instance_valid(player):
		return

	var pounce_state := "READY"
	if bool(player.call("is_pouncing")):
		pounce_state = "ACTIVE"
	elif float(player.get("pounce_cooldown_timer")) > 0.0:
		pounce_state = "COOLDOWN"

	var glide_state := "ACTIVE" if bool(player.call("is_gliding")) else "READY"
	if float(player.get("glide_time_remaining")) <= 0.0:
		glide_state = "EMPTY"
	var health_state := "%d / %d" % [int(player.get("current_health")), int(player.get("max_health"))]
	var collision_state := "ON" if collision_shapes_visible else "OFF"
	var room_state := _get_room_state()

	status_label.text = "DEV MODE\nToggle: set in Pause > Controls\nF4 / Left Stick: Hit/Hurt Boxes %s\nR / View: Reset room\nY / Triangle: Next room %s\nB / Circle: Back\nPosition: %s\nVelocity: %s\nHealth: %s\nGlide: %s (%.2fs, %.0f°, speed %.0f)\nPounce: %s" % [ # Show developer controls and movement state.
		collision_state, # Display whether collision drawing is enabled.
		room_state, # Display the current room and cycle position.
		player.position.round(),
		player.velocity.round(),
		health_state, # Display current prototype health.
		glide_state,
		float(player.get("glide_time_remaining")),
		rad_to_deg(float(player.get("glide_pitch"))),
		float(player.get("glide_momentum")),
		pounce_state,
	]


func _refresh_room_paths() -> void: # Build a stable list of rooms available to dev mode.
	room_paths.clear() # Remove paths collected by an earlier scan.
	_add_room_path(str(ProjectSettings.get_setting("application/run/main_scene", ""))) # Include the project's startup sandbox.
	if get_tree().current_scene != null: # Check for an active room scene.
		_add_room_path(get_tree().current_scene.scene_file_path) # Include an unassigned room being tested directly.
	for room_id: String in MetSys.map_data.assigned_scenes.keys(): # Include every scene assigned on the MetSys map.
		_add_room_path(ResourceUID.ensure_path(room_id)) # Convert the stored UID into its scene path.
	room_paths.sort() # Keep previous and next order consistent between rooms.


func _add_room_path(room_path: String) -> void: # Add one valid unique room path.
	if room_path.is_empty() or room_path in room_paths: # Reject empty and duplicate entries.
		return # Keep the existing room list unchanged.
	if not ResourceLoader.exists(room_path, "PackedScene"): # Confirm the path points to a loadable scene.
		return # Ignore invalid map assignments.
	room_paths.append(room_path) # Register the room for cycling.


func _change_room() -> void: # Cycle forward through registered room scenes.
	_refresh_room_paths() # Include any map assignments added since this scene loaded.
	if room_paths.size() < 2: # Require another room to visit.
		push_warning("Dev room change needs at least two available room scenes.") # Explain why the command did nothing.
		return # Keep the current room loaded.
	var current_path := get_tree().current_scene.scene_file_path
	var current_index := room_paths.find(current_path)
	if current_index < 0: # Handle an unexpected unregistered current scene.
		current_index = 0 # Start cycling from the first known room.
	var target_index := _next_room_index(current_index)
	var target_scene := load(room_paths[target_index]) as PackedScene
	if target_scene == null: # Confirm the destination scene loaded.
		push_warning("Dev mode could not load room: %s" % room_paths[target_index]) # Report the invalid destination.
		return # Keep the current room loaded.
	get_tree().debug_collisions_hint = false # Clear global collision drawing before replacing dev mode.
	get_tree().paused = false # Let the new room process after the menu is replaced.
	var change_error := get_tree().change_scene_to_packed(target_scene)
	if change_error != OK: # Detect a failed scene change.
		push_warning("Dev room change failed with error %s." % change_error) # Report the transition failure.


func _next_room_index(current_index: int) -> int: # Keep one forward-only room order.
	return wrapi(current_index + 1, 0, room_paths.size()) # Return to the first room after the last.


func _get_room_state() -> String: # Format the current room for the overlay.
	_refresh_room_paths() # Keep the displayed list current.
	var current_path := get_tree().current_scene.scene_file_path
	var current_index := room_paths.find(current_path)
	var room_name := current_path.get_file().get_basename().replace("_", " ")
	if current_index < 0: # Handle a scene outside the collected list.
		return room_name # Show its name without an index.
	return "%d/%d %s" % [current_index + 1, room_paths.size(), room_name] # Show cycle position and room name.


func _on_flight_mode_toggled(active: bool) -> void:
	if is_instance_valid(player):
		player.call("set_dev_flight_mode", active) # Apply the menu selection to the room's player.


func _on_player_flight_changed(active: bool) -> void:
	flight_mode_button.set_pressed_no_signal(active) # Show shortcut toggles without triggering another update.


func _fill_enemy_picker() -> void: # Create one dropdown entry for each registered scene.
	enemy_picker.clear() # Remove any entries left from an earlier setup.
	for index: int in spawnable_enemies.size(): # Visit every scene in the Inspector list.
		var enemy_scene := spawnable_enemies[index]
		if enemy_scene == null: # Ignore empty Inspector slots.
			continue
		var enemy_name := enemy_scene.resource_path.get_file().get_basename().capitalize()
		enemy_picker.add_item(enemy_name, index) # Keep the item ID aligned with its scene index.
	spawn_button.disabled = enemy_picker.item_count == 0 # Avoid a button that cannot spawn anything.
	if enemy_picker.item_count > 0: # Choose the first available enemy by default.
		enemy_picker.select(0)


func _on_spawn_pressed() -> void: # Place the chosen enemy on nearby ground.
	if not enabled: # Keep dev actions inside the visible menu.
		return
	var scene_index := enemy_picker.get_selected_id()
	if scene_index < 0 or scene_index >= spawnable_enemies.size(): # Reject an invalid selection.
		spawn_feedback.text = "Select an enemy first."
		return
	var enemy_scene := spawnable_enemies[scene_index]
	if enemy_scene == null: # Handle a scene removed after the list was built.
		spawn_feedback.text = "Enemy scene is missing."
		return
	var instance := enemy_scene.instantiate()
	var enemy := instance as Node2D
	if enemy == null: # Keep non-2D scenes out of this room-spawn tool.
		instance.free() # Release an unsupported scene instead of leaving it orphaned.
		spawn_feedback.text = "Enemy must have a 2D root."
		return
	var facing := signf(float(player.get("facing_direction")))
	var spawn_x := player.global_position.x + facing * spawn_distance
	var ray_start := Vector2(spawn_x, player.global_position.y - floor_search_height)
	var ray_end := ray_start + Vector2.DOWN * floor_search_depth
	var floor_query := PhysicsRayQueryParameters2D.create(ray_start, ray_end, 1)
	floor_query.exclude = [player.get_rid()] # Find world geometry, not the player collider.
	var floor_hit := player.get_world_2d().direct_space_state.intersect_ray(floor_query)
	if floor_hit.is_empty(): # Do not leave a ground enemy floating in an empty gap.
		enemy.free()
		spawn_feedback.text = "No floor ahead; move closer to ground."
		return
	var floor_offset := _get_enemy_floor_offset(enemy)
	var spawn_position := Vector2(spawn_x, (floor_hit["position"] as Vector2).y - floor_offset)
	var room := get_parent() as Node2D
	enemy.position = room.to_local(spawn_position) # Set position before _ready records patrol centers.
	room.add_child(enemy) # Add the enemy to the current room, not the menu layer.
	spawned_enemies.append(enemy) # Remember this instance for the Clear button.
	spawn_feedback.text = "Spawned %s." % enemy_picker.get_item_text(enemy_picker.selected)


func _get_enemy_floor_offset(enemy: Node2D) -> float: # Align a rectangular enemy hurtbox with the floor.
	var hurtbox := enemy.get_node_or_null("HurtboxShape") as CollisionShape2D
	if hurtbox != null and hurtbox.shape is RectangleShape2D: # Use the scene's real collision height.
		var rectangle := hurtbox.shape as RectangleShape2D
		return hurtbox.position.y + rectangle.size.y * 0.5
	return default_floor_offset # Give other 2D enemy scenes a safe editable fallback.


func _on_clear_pressed() -> void: # Remove only enemies spawned from this menu.
	if not enabled: # Ignore actions while the developer overlay is hidden.
		return
	var cleared := 0
	for enemy: Node2D in spawned_enemies: # Leave enemies authored into the room untouched.
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion(): # Skip already defeated enemies.
			enemy.queue_free()
			cleared += 1
	spawned_enemies.clear() # Discard references to cleared or defeated instances.
	spawn_feedback.text = "Cleared %d spawned enem%s." % [cleared, "y" if cleared == 1 else "ies"]


func _open_dev_mode() -> void:
	enabled = true
	overlay.visible = true
	paused_before_open = get_tree().paused # Remember the prior pause state.
	get_tree().paused = true # Freeze the room while navigating dev controls.
	flight_mode_button.grab_focus() # Start controller navigation at the first action.


func _close_dev_mode() -> void:
	if level_editor.visible and level_editor.dirty:
		level_editor.save_edits() # Keep live-painted tiles when closing with the dev shortcut.
		if level_editor.dirty:
			return # Leave the editor open when disk persistence failed.
	level_editor.close_editor() # Hide the palette and world cursor.
	enabled = false
	overlay.visible = false
	get_viewport().gui_release_focus() # Return controller focus to gameplay.
	get_tree().paused = paused_before_open # Restore the room's previous pause state.
	collision_shapes_visible = false
	get_tree().debug_collisions_hint = false # Clear temporary collision drawing.


func _on_edit_level_pressed() -> void:
	overlay.visible = false # Trade the dev summary for the editor dock.
	get_tree().paused = false # Let the dinosaur and room physics run while placing tiles.
	level_editor.open_editor() # Show the palette and world cursor.
