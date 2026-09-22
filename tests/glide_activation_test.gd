extends Node2D # Run the regression check as a normal project scene with autoloads.

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")


func _ready() -> void: # Start after the test scene is ready.
	call_deferred("_run") # Keep assertions out of node startup.


func _run() -> void: # Check Glide entry from representative air velocities.
	var player: CharacterBody2D = PLAYER_SCENE.instantiate()
	add_child(player) # Initialize the real player controller and its audio nodes.
	var cases := [
		{"name": "rising jump", "velocity": Vector2(250.0, -800.0)}, # Catch upward-speed conversion.
		{"name": "falling jump", "velocity": Vector2(250.0, 800.0)}, # Catch downward-speed conversion.
		{"name": "vertical jump", "velocity": Vector2(0.0, -800.0)}, # Verify walking-speed launch.
		{"name": "slow horizontal travel", "velocity": Vector2(100.0, -800.0)}, # Verify the speed floor.
		{"name": "fast horizontal travel", "velocity": Vector2(600.0, -300.0)}, # Preserve earned speed.
	]
	var failed := false
	for test_case in cases: # Repeat the entry check for each movement state.
		var entry_velocity: Vector2 = test_case["velocity"]
		player.velocity = entry_velocity # Set the pre-Glide air velocity.
		player.set("facing_direction", 1.0) # Keep the test facing right.
		player.call("_begin_glide") # Enter Glide through the controller path.
		var entry_momentum: float = player.get("glide_momentum")
		player.call("_apply_glide_movement", 0.0, 0.0) # Isolate entry from frame acceleration.
		var expected_momentum: float = maxf(absf(entry_velocity.x), player.get("max_speed"))
		if not is_equal_approx(entry_momentum, expected_momentum): # Check the walking-speed floor without vertical transfer.
			push_error("%s: glide did not start at walking speed or preserve faster travel" % test_case["name"]) # Explain the failure.
			failed = true # Return a failing exit code.
		if absf(player.velocity.x) > expected_momentum + 0.001: # Reject extra forward speed from vertical motion.
			push_error("%s: glide activation exceeded its intended entry speed" % test_case["name"]) # Explain the failure.
			failed = true # Return a failing exit code.
		if entry_momentum <= player.get("glide_low_momentum_threshold"): # Ensure stationary Glide will not auto-cancel.
			push_error("%s: glide entry fell below the low-momentum cutoff" % test_case["name"]) # Explain the failure.
			failed = true # Return a failing exit code.
	for reversal_direction: float in [-1.0, 1.0]: # Check both left-to-right and right-to-left turnarounds.
		var walking_speed: float = player.get("max_speed")
		player.set("facing_direction", -reversal_direction) # Begin by gliding the old way.
		player.velocity = Vector2(-reversal_direction * 600.0, -100.0) # Keep fast airborne momentum from that Glide.
		player.call("_begin_glide") # Enter the old-direction Glide.
		player.call("_begin_glide_exit") # Cancel it without deleting its velocity.
		player.call("_update_facing", reversal_direction) # Turn around in the air before pressing Glide again.
		player.call("_begin_glide") # Start a fresh Glide facing the new way.
		if not is_zero_approx(player.get("glide_momentum")) or not player.get("glide_reversal_active"): # Reject instant transfer of old speed.
			push_error("Glide reversal inherited speed from the old direction") # Explain the regression.
			failed = true # Return a failing exit code.
		player.call("_apply_glide_movement", 0.0, 0.05) # Advance one short physics interval.
		if player.velocity.x * reversal_direction <= 0.0 or absf(player.velocity.x) >= walking_speed: # Require early motion below walking pace.
			push_error("Glide reversal did not begin a gradual new-direction acceleration") # Explain the regression.
			failed = true # Return a failing exit code.
		for frame: int in 5: # Let the short ramp reach its ordinary Glide entry speed.
			player.call("_apply_glide_movement", 0.0, 0.05) # Advance another fixed interval.
		if absf(player.velocity.x) < walking_speed * 0.9 or player.get("glide_reversal_active"): # Ensure the slowdown is temporary.
			push_error("Glide reversal did not recover walking-speed travel") # Explain the regression.
			failed = true # Return a failing exit code.
	if not failed: # Print a concise success result.
		print("PASS: Glide entry preserves same-direction speed and ramps through reversals.") # Confirm all cases passed.
	player.queue_free() # Release the instantiated controller before the engine exits.
	await get_tree().process_frame # Let queued node cleanup complete.
	get_tree().quit(1 if failed else 0) # Propagate the result to automation.
