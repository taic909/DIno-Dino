extends Node2D # Run the real movement room with a dev-menu spawn check.

@onready var room: Node2D = $Main
@onready var dev_mode: CanvasLayer = $Main/DevMode
@onready var player: CharacterBody2D = $Main/Player


func _ready() -> void: # Verify the scene registry and both menu buttons.
	await get_tree().physics_frame # Let the room and physics world initialize.
	dev_mode.set("enabled", true) # Open dev mode for its guarded actions.
	dev_mode.get_node("Overlay").visible = true # Match the visible UI state.
	get_tree().paused = true # Match the new controller-friendly paused dev menu.
	var picker := dev_mode.get_node("Overlay/Margin/Content/SpawnRow/EnemyPicker") as OptionButton
	if not _check(picker.item_count == 2, "Expected beetle and dummy in the picker."): # Verify registered enemies.
		return
	var authored_beetle := room.get_node("WalkerBeetle") as Node2D
	var spawn_button := dev_mode.get_node("Overlay/Margin/Content/SpawnRow/SpawnButton") as Button
	spawn_button.pressed.emit() # Use the button signal instead of calling spawn internals.
	var spawned: Array[Node2D] = dev_mode.get("spawned_enemies")
	if not _check(spawned.size() == 1, "Spawn button did not add one enemy."): # Verify the button connection.
		return
	if not _check(spawned[0].scene_file_path.ends_with("walker_beetle.tscn"), "The default enemy was not the beetle."): # Check selection.
		return
	if not _check(absf(spawned[0].global_position.x - player.global_position.x) > 100.0, "Enemy spawned too close to the player."): # Check spacing.
		return
	picker.select(1) # Select the practice dummy from the same registry.
	spawn_button.pressed.emit() # Spawn another enemy without a separate handler.
	spawned = dev_mode.get("spawned_enemies")
	if not _check(spawned.size() == 2, "Second enemy did not spawn."): # Check modular selection.
		return
	if not _check(spawned[1].scene_file_path.ends_with("practice_dummy.tscn"), "The selected dummy did not spawn."): # Check scene choice.
		return
	var spawned_beetle := spawned[0]
	var spawned_dummy := spawned[1]
	var clear_button := dev_mode.get_node("Overlay/Margin/Content/ClearButton") as Button
	clear_button.pressed.emit() # Remove the two temporary instances.
	if not _check(is_instance_valid(authored_beetle) and not authored_beetle.is_queued_for_deletion(), "Clear removed an authored enemy."): # Protect placed enemies.
		return
	if not _check(spawned_beetle.is_queued_for_deletion() and spawned_dummy.is_queued_for_deletion(), "Clear missed a spawned enemy."): # Check cleanup.
		return
	print("PASS: dev enemy picker, spawn, and clear") # Mark the integration test complete.
	get_tree().paused = false # Restore normal tree processing before exit.
	get_tree().quit() # Exit the headless test successfully.


func _check(condition: bool, message: String) -> bool: # Report one clear failure at a time.
	if condition: # Continue when the expected behavior occurred.
		return true
	push_error(message) # Explain the failed assertion in headless output.
	get_tree().paused = false # Restore normal processing after a failure.
	get_tree().quit(1) # Give automated runs a failing exit code.
	return false # Stop this test before later assumptions run.
