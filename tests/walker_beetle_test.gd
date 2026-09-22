extends Node2D # Run integration checks with the project's autoloads active.

const BEETLE_SCENE = preload("res://scenes/enemy/walker_beetle.tscn")
const PLAYER_SCENE = preload("res://scenes/player/player.tscn")


func _ready() -> void: # Wait until all test nodes can join the physics world.
	call_deferred("_run") # Start the checks after scene startup.


func _run() -> void: # Verify patrol, contact damage, and combat responses.
	var beetle: Area2D = BEETLE_SCENE.instantiate()
	beetle.set("starting_direction", 1.0)
	beetle.set("patrol_half_width", 80.0)
	add_child(beetle) # Place a beetle above the test ground.
	for frame in 30: # Give the beetle time to walk forward.
		await get_tree().physics_frame # Advance one physics step.
	var moved_forward := beetle.global_position.x > 15.0
	for frame in 105: # Let the beetle reach and leave its patrol edge.
		await get_tree().physics_frame # Advance one physics step.
	var turned_around := float(beetle.get("direction")) < 0.0
	beetle.set_physics_process(false) # Hold position during contact tests.
	var player: CharacterBody2D = PLAYER_SCENE.instantiate()
	add_child(player) # Initialize the real player Hurtbox.
	player.set_physics_process(false) # Prevent movement from changing overlap.
	player.global_position = beetle.global_position # Touch the beetle body.
	for frame in 3: # Allow overlap signals to reach the player.
		await get_tree().physics_frame # Advance one physics step.
	var touch_damaged := int(player.get("current_health")) == int(player.get("max_health")) - 1
	player.set("pounce_timer", 1.0)
	beetle.call("receive_pounce", player) # Test the existing Pounce interface.
	var pounce_stunned := bool(beetle.get("stunned")) and int(beetle.call("get_contact_damage")) == 0
	var pounce_locked: bool = beetle.get("target_player") == player # Pounce should also mark the attacker for pursuit.
	player.set("tail_swipe_timer", 1.0)
	beetle.call("receive_tail_swipe", player) # Test the stun-bonus finisher.
	var swipe_defeated := bool(beetle.get("defeated"))
	var step := _add_obstacle(Vector2(65.0, 25.0), Vector2(40.0, 30.0)) # Raise the floor briefly without making a full wall.
	var patrol_beetle: Area2D = BEETLE_SCENE.instantiate()
	patrol_beetle.set("starting_direction", 1.0) # Walk toward the raised step.
	patrol_beetle.set("patrol_half_width", 300.0) # Keep the patrol limit beyond both test obstacles.
	patrol_beetle.position = Vector2(-40.0, 0.0)
	add_child(patrol_beetle) # Run the real probes against the step.
	for frame in 125:
		await get_tree().physics_frame # Give the beetle time to cross the small rise.
	var crossed_step := patrol_beetle.global_position.x > 85.0 and float(patrol_beetle.get("direction")) > 0.0
	var wall := _add_obstacle(Vector2(170.0, -10.0), Vector2(30.0, 100.0)) # Put a body-height obstacle farther ahead.
	for frame in 80:
		await get_tree().physics_frame # Let the raised wall reach the beetle's forward ray.
	var turned_at_wall := float(patrol_beetle.get("direction")) < 0.0
	var chase_beetle: Area2D = BEETLE_SCENE.instantiate()
	chase_beetle.set("starting_direction", -1.0) # Patrol away from the nearby player before a hit.
	chase_beetle.set("patrol_half_width", 20.0) # Make the ordinary patrol range shorter than a chase.
	add_child(chase_beetle) # Run the actual enemy scene and terrain probes.
	player.global_position = Vector2(5.0, 0.0) # Put the player beside the new beetle without triggering pursuit.
	for frame in 10:
		await get_tree().physics_frame # Verify normal pre-hit patrol still runs.
	var ignored_before_hit := chase_beetle.get("target_player") == null and float(chase_beetle.get("direction")) < 0.0
	player.set("tail_swipe_timer", 1.0)
	chase_beetle.call("receive_tail_swipe", player) # A nonlethal strike should awaken pursuit.
	var swipe_locked: bool = chase_beetle.get("target_player") == player and not bool(chase_beetle.get("defeated"))
	player.global_position = Vector2(120.0, 0.0) # Lead it beyond its original patrol bound.
	for frame in 80:
		await get_tree().physics_frame # Let the beetle track the player's new position.
	var chased_beyond_patrol := chase_beetle.global_position.x > 40.0 and float(chase_beetle.get("direction")) > 0.0
	var chase_position_before_turn := chase_beetle.global_position.x
	player.global_position = Vector2(-150.0, 0.0) # Make the target reverse direction.
	for frame in 20:
		await get_tree().physics_frame # Allow the beetle to respond to the moving player.
	var followed_turn := float(chase_beetle.get("direction")) < 0.0 and chase_beetle.global_position.x < chase_position_before_turn
	var passed: bool = moved_forward and turned_around and touch_damaged and pounce_stunned and pounce_locked and swipe_defeated and crossed_step and turned_at_wall and ignored_before_hit and swipe_locked and chased_beyond_patrol and followed_turn
	if not passed: # Report the specific broken behavior.
		push_error("Beetle failed: moved=%s turned=%s touch=%s stunned=%s pounce_lock=%s defeated=%s step=%s wall=%s prehit=%s swipe_lock=%s chased=%s followed=%s" % [moved_forward, turned_around, touch_damaged, pounce_stunned, pounce_locked, swipe_defeated, crossed_step, turned_at_wall, ignored_before_hit, swipe_locked, chased_beyond_patrol, followed_turn])
	else: # Confirm the complete beginner-enemy loop.
		print("PASS: beetle patrol, hit-triggered pursuit, terrain checks, and combat.")
	await get_tree().create_timer(0.4).timeout # Let the defeat burst finish.
	player.queue_free() # Release the player before exiting the test.
	patrol_beetle.queue_free() # Release the separate terrain-probe test enemy.
	chase_beetle.queue_free() # Release the hit-triggered pursuit test enemy.
	step.queue_free() # Remove only the test's small raised obstacle.
	wall.queue_free() # Remove only the test's full-height wall.
	await get_tree().process_frame # Complete queued node cleanup.
	get_tree().quit(0 if passed else 1) # Return the check result.


func _add_obstacle(obstacle_position: Vector2, obstacle_size: Vector2) -> StaticBody2D:
	var obstacle := StaticBody2D.new()
	obstacle.collision_layer = 1 # Match the normal room terrain physics layer.
	obstacle.position = obstacle_position
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = obstacle_size
	collision.shape = rectangle
	obstacle.add_child(collision) # Give the new body a raycast target.
	add_child(obstacle) # Register it with the active test physics world.
	return obstacle # Keep the obstacle available for cleanup.
