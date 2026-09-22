extends Area2D # Detect the player and request a configured room change.

@export_category("Destination")
@export var target_room: PackedScene
@export var target_spawn_position := Vector2.ZERO

@export_category("Entry Motion")
@export var preserve_momentum := true
@export var entry_velocity := Vector2.ZERO


func _on_body_entered(body: Node2D) -> void: # Handle an object entering the doorway.
	if not body.is_in_group("player"): # Accept only the player scene.
		return # Ignore enemies and physics objects.
	if target_room == null: # Check that the door has a destination.
		push_warning("RoomDoor has no target_room assigned.") # Explain the missing Inspector setup.
		return # Keep the current room loaded.
	var player := body as CharacterBody2D
	if player == null: # Confirm the expected player body type.
		return # Ignore an incompatible player node.
	RoomManager.request_room_change(target_room, target_spawn_position, player, preserve_momentum, entry_velocity) # Send the configured transition to the global manager.
