extends Node2D # Check shallow bounces, hard impacts, and a real wall collision.

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")


func _ready() -> void:
	call_deferred("_run") # Let the physics world initialize before testing collisions.


func _run() -> void:
	var player: CharacterBody2D = PLAYER_SCENE.instantiate()
	add_child(player) # Use the production controller and collision capsule.
	player.set_physics_process(false) # Keep the angle checks independent from frame timing.
	player.set("gliding", true)
	player.call("_apply_glide_surface_impact", Vector2(100.0, 600.0), Vector2.LEFT) # Graze a vertical wall at a shallow angle.
	if not _check(player.velocity.x < 0.0 and player.velocity.y > 300.0 and player.velocity.length() < 500.0 and not bool(player.get("gliding")), "Shallow wall contact did not produce a reduced bounce."):
		return
	player.set("gliding", true)
	player.call("_apply_glide_surface_impact", Vector2(600.0, 100.0), Vector2.LEFT) # Strike the same wall mostly head-on.
	if not _check(player.velocity.x < 0.0 and player.velocity.length() < 100.0 and float(player.get("glide_momentum")) < 100.0, "Direct wall contact did not heavily reduce Glide momentum."):
		return
	player.set("gliding", true)
	player.call("_apply_glide_surface_impact", Vector2(100.0, 600.0), Vector2.UP) # Land on a horizontal surface.
	if not _check(player.velocity.y == 0.0 and player.velocity.x < 30.0, "Floor contact incorrectly used the wall-bounce rule."):
		return
	var wall := StaticBody2D.new()
	wall.position = Vector2(100.0, 0.0)
	var wall_collision := CollisionShape2D.new()
	var wall_rectangle := RectangleShape2D.new()
	wall_rectangle.size = Vector2(20.0, 600.0)
	wall_collision.shape = wall_rectangle
	wall.add_child(wall_collision) # Make a tall surface that the player cannot fly over.
	add_child(wall) # Register the wall in the same physics world as the player.
	player.global_position = Vector2.ZERO
	player.velocity = Vector2.ZERO
	player.set("gliding", true)
	player.set("glide_momentum", 600.0)
	player.set("glide_speed_limit", 1400.0)
	player.set("glide_pitch", 0.0)
	player.set("facing_direction", 1.0)
	player.set("glide_time_remaining", 4.0)
	player.set("glide_exit_active", false)
	player.set_physics_process(true) # Exercise the actual move-and-slide collision path.
	for frame: int in 20:
		await get_tree().physics_frame # Allow the flying player to reach the wall.
		if not bool(player.get("gliding")):
			break # Observe the first impact before ordinary air movement takes over.
	if not _check(not bool(player.get("gliding")) and float(player.get("glide_momentum")) < 200.0, "A live wall collision restored the old Glide momentum."):
		return
	print("PASS: glancing wall bounces, direct impacts lose momentum, and live Glide collision exits cleanly.") # Report the complete regression check.
	player.queue_free() # Release the production controller after testing.
	wall.queue_free() # Remove the test-only collision surface.
	await get_tree().process_frame # Finish queued cleanup before exiting.
	get_tree().quit() # Return a successful test result.


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true # Continue while the expected impact behavior holds.
	push_error(message) # Make a failing angle or integration case visible.
	get_tree().quit(1) # Return failure to the command line.
	return false # Stop checks that depend on the failed state.
