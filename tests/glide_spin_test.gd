extends Node2D

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var player: CharacterBody2D = PLAYER_SCENE.instantiate()
	add_child(player)
	player.set_physics_process(false)
	var trigger_bound := false
	for event: InputEvent in InputMap.action_get_events("glide_spin"):
		if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_LEFT and event.axis_value > 0.0:
			trigger_bound = true
	if not _check(trigger_bound, "Glide Spin is not bound to LT / L2 by default."):
		return
	player.set("gliding", true)
	for facing: float in [-1.0, 1.0]:
		player.set("facing_direction", facing)
		player.set("glide_pitch", deg_to_rad(80.0))
		player.set("glide_momentum", 900.0)
		player.set("glide_speed_limit", 1400.0)
		player.call("_apply_glide_movement", 1.0, 1.0)
		if not _check(is_equal_approx(rad_to_deg(float(player.get("glide_pitch"))), 115.0), "Ordinary Glide dive limit differs by facing direction."):
			return
	player.set("facing_direction", 1.0)
	player.set("glide_pitch", deg_to_rad(80.0))
	await get_tree().process_frame
	Input.action_press("glide_spin")
	player.call("_try_glide_spin")
	player.set("glide_momentum", 900.0)
	player.set("glide_speed_limit", 1400.0)
	player.set("glide_roll_angle", deg_to_rad(90.0))
	player.call("_apply_glide_movement", -1.0, 0.1)
	if not _check(float(player.get("glide_pitch")) < deg_to_rad(80.0), "Steering reversed too early in the roll."):
		return
	player.set("glide_pitch", deg_to_rad(80.0))
	player.set("glide_roll_angle", deg_to_rad(115.0))
	player.call("_apply_glide_movement", -1.0, 0.1)
	if not _check(is_equal_approx(float(player.get("glide_pitch")), deg_to_rad(80.0)), "Steering did not ease through the 115-degree transition."):
		return
	player.set("glide_roll_angle", deg_to_rad(140.0))
	player.call("_apply_glide_movement", -1.0, 0.1)
	if not _check(float(player.get("glide_pitch")) > deg_to_rad(80.0), "Steering did not invert after the transition."):
		return
	player.set("glide_roll_angle", 0.0)
	player.set("glide_pitch", deg_to_rad(80.0))
	player.call("_update_air_rotation", 0.28)
	if not _check(is_equal_approx(float(player.get("glide_roll_angle")), PI) and player.get_node("Visuals/GlideSprite").scale.y < 0.0, "First roll did not invert the Glide art."):
		return
	player.call("_apply_glide_movement", -1.0, 0.2)
	if not _check(rad_to_deg(float(player.get("glide_pitch"))) > 90.0 and player.velocity.x < 0.0, "Inverted up input did not turn past vertical."):
		return
	player.call("_apply_glide_movement", -1.0, 1.1)
	if not _check(player.velocity.x < 0.0 and player.velocity.y < 0.0, "Inverted pull-up did not complete the U-turn."):
		return
	var return_pitch := float(player.get("glide_pitch"))
	player.call("_apply_glide_movement", 0.0, 0.2)
	if not _check(is_equal_approx(float(player.get("glide_pitch")), return_pitch), "Released stick changed inverted heading."):
		return
	Input.action_release("glide_spin")
	await get_tree().process_frame
	Input.action_press("glide_spin")
	player.call("_try_glide_spin")
	player.call("_update_air_rotation", 0.28)
	if not _check(is_equal_approx(float(player.get("glide_roll_angle")), TAU) and player.get_node("Visuals/GlideSprite").scale.y > 0.0, "Second roll did not restore the upright pose."):
		return
	player.call("_begin_glide_exit")
	if not _check(is_equal_approx(float(player.get("facing_direction")), -1.0), "Glide exit did not adopt U-turn heading."):
		return
	player.call("_update_air_rotation", 0.016)
	if not _check(is_zero_approx(float(player.get("glide_roll_angle"))) and is_zero_approx(player.get_node("Visuals").rotation), "Glide exit did not reset the roll."):
		return
	player.set("gliding", true)
	player.set("facing_direction", -1.0)
	player.call("_update_sprite_facing")
	player.set("glide_pitch", deg_to_rad(80.0))
	player.set("glide_roll_angle", deg_to_rad(115.0))
	player.set("glide_roll_target", PI)
	player.set("glide_momentum", 900.0)
	player.set("glide_speed_limit", 1400.0)
	player.call("_apply_glide_movement", -1.0, 0.1)
	if not _check(is_equal_approx(float(player.get("glide_pitch")), deg_to_rad(80.0)), "Mirrored roll did not ease steering at 115 degrees."):
		return
	player.set("glide_roll_angle", PI)
	player.call("_apply_glide_movement", -1.0, 0.2)
	if not _check(float(player.get("glide_pitch")) > PI * 0.5 and player.velocity.x > 0.0, "Left-facing inverted Glide did not turn rightward."):
		return
	player.call("_begin_glide_exit")
	if not _check(is_equal_approx(float(player.get("facing_direction")), 1.0), "Mirrored Glide exit did not adopt its new heading."):
		return
	Input.action_release("glide_spin")
	print("PASS: LT Glide roll eases through 115 degrees and mirrors its U-turn in both directions.")
	get_tree().quit()


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	get_tree().quit(1)
	return false
