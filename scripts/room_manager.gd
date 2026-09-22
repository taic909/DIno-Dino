extends Node # Persist room-entry state between scene changes.

@export var room_entry_lock_time := 0.2

var pending_spawn_position := Vector2.ZERO
var pending_velocity := Vector2.ZERO
var pending_health := -1
var pending_facing_direction := 1.0
var has_pending_entry := false
var transition_in_progress := false
var entry_lock_remaining := 0.0


func _ready() -> void: # Prepare the global room-change service.
	process_mode = Node.PROCESS_MODE_ALWAYS # Keep transition timing active while paused.
	get_tree().scene_changed.connect(_on_scene_changed) # Unlock after Godot installs the next room.


func _process(delta: float) -> void: # Count down the entry protection window.
	entry_lock_remaining = maxf(entry_lock_remaining - delta, 0.0) # Prevent immediate door retriggers.


func can_change_room() -> bool: # Report whether a door may start a transition.
	return not transition_in_progress and entry_lock_remaining <= 0.0 # Reject overlapping room requests.


func request_room_change(target_room: PackedScene, spawn_position: Vector2, player: CharacterBody2D, preserve_momentum: bool, entry_velocity: Vector2) -> void: # Store entry state and load the destination.
	if target_room == null or not can_change_room(): # Validate the destination and transition state.
		return # Ignore invalid or duplicate requests.
	transition_in_progress = true # Block other doors during the scene change.
	pending_spawn_position = spawn_position # Remember the destination-room coordinates.
	pending_velocity = player.velocity if preserve_momentum else entry_velocity # Choose carried or authored entry motion.
	pending_health = int(player.get("current_health")) # Preserve prototype health between rooms.
	pending_facing_direction = float(player.get("facing_direction")) # Preserve the dinosaur's facing direction.
	has_pending_entry = true # Mark the stored state for the next Player instance.
	var change_error := get_tree().change_scene_to_packed(target_room)
	if change_error != OK: # Detect a failed scene-change request.
		push_error("Room change failed with error %s." % change_error) # Report the failure for debugging.
		transition_in_progress = false # Allow another attempt.
		has_pending_entry = false # Discard entry state for the room that did not load.


func apply_pending_entry(player: CharacterBody2D) -> void: # Restore entry state on the new Player instance.
	if not has_pending_entry: # Check whether this room was entered through a door.
		return # Keep the room's authored starting position.
	player.position = pending_spawn_position # Place the player at the configured entrance.
	player.velocity = pending_velocity # Restore or replace room-entry momentum.
	player.set("current_health", pending_health) # Restore prototype health.
	player.set("facing_direction", pending_facing_direction) # Restore visual facing.
	has_pending_entry = false # Consume the one-time entry state.
	entry_lock_remaining = room_entry_lock_time # Prevent an overlapping destination door from firing.


func _on_scene_changed() -> void: # Finish the global transition after the new room enters the tree.
	transition_in_progress = false # Allow later door transitions.
	entry_lock_remaining = maxf(entry_lock_remaining, room_entry_lock_time) # Keep a short arrival lock.
