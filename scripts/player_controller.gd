extends CharacterBody2D

@export_category("Movement")
@export var max_speed := 240.0
@export var ground_acceleration := 650.0
@export var ground_deceleration := 2200.0
@export var air_acceleration := 1100.0

@export_category("Jump")
@export var jump_velocity := -1000.0
@export var gravity := 1200.0
@export var fall_gravity_multiplier := 1.35
@export var jump_release_multiplier := 0.5
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.12

@export_category("Glide")
@export var glide_duration := 5.0
@export var glide_speed := 285.0
@export var glide_acceleration := 1600.0
@export var glide_shallow_acceleration := 80.0
@export var glide_climb_drag := 700.0
@export var glide_max_speed := 520.0
@export var glide_pitch_speed := 100.0
@export_range(0.0, 45.0, 1.0, "suffix:°") var neutral_glide_pitch := 10.0
@export var neutral_glide_pitch_speed := 45.0
@export_range(0.0, 90.0, 1.0, "suffix:°") var glide_max_climb_angle := 35.0
@export_range(0.0, 90.0, 1.0, "suffix:°") var glide_max_dive_angle := 80.0
@export var glide_low_momentum_threshold := 150.0
@export var glide_low_momentum_cancel_time := 0.2

@export_category("Air Rotation")
@export var air_rotation_speed := 8.0

@export_category("Pounce")
@export var pounce_speed := 520.0
@export var glide_pounce_speed_multiplier := 1.5
@export var pounce_duration := 0.2
@export var pounce_cooldown := 0.35
@export_range(0.0, 1.0, 0.05) var pounce_gravity_multiplier := 0.7
@export var pounce_stretch_scale := Vector2(1.24, 0.82)
@export var pounce_rebound_speed := Vector2(220.0, -320.0)
@export var pounce_rebound_scale := Vector2(0.86, 1.18)
@export_range(0.0, 1.0, 0.05) var glide_pounce_momentum_retention := 0.75
@export var glide_pounce_rebound_speed_cap := 480.0
@export var glide_pounce_refill_time := 1.25
@export_range(0.1, 3.0, 0.05) var glide_pounce_upward_bias := 1.0
@export var glide_pounce_dome_half_width := 48.0
@export var glide_pounce_vertical_snap_distance := 6.0

@export_category("Tail Swipe")
@export var tail_swipe_duration := 0.16
@export var tail_swipe_cooldown := 0.3
@export_range(0.0, 1.0, 0.05) var tail_swipe_down_stutter_vertical_retention := 0.35
@export_range(0.0, 1.0, 0.05) var tail_swipe_gravity_multiplier := 0.4
@export_range(0.0, 1.0, 0.05) var tail_swipe_lateral_hit_momentum_retention := 0.6
@export var tail_swipe_lateral_recoil_speed := 180.0
@export var tail_swipe_down_bounce_speed := 420.0
@export var tail_swipe_scale := Vector2(1.12, 0.9)
@export var tail_swipe_reach := 82.0
@export_range(0.0, 1.0, 0.05) var tail_swipe_down_aim_threshold := 0.5

@export_category("Landing Feedback")
@export var minimum_squash_speed := 180.0
@export var landing_squash_scale := Vector2(1.12, 0.82)
@export var landing_recovery_time := 0.12

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var glide_sprite: Sprite2D = $Visuals/GlideSprite
@onready var pounce_hitbox: Area2D = $PounceHitbox
@onready var pounce_hitbox_shape: CollisionShape2D = $PounceHitbox/HitboxShape
@onready var tail_swipe_hitbox: Area2D = $TailSwipeHitbox
@onready var tail_swipe_hitbox_shape: CollisionShape2D = $TailSwipeHitbox/HitboxShape
@onready var tail_swipe_indicator: Line2D = $TailSwipeIndicator

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var glide_time_remaining := 0.0
var gliding := false
var glide_momentum := 0.0
var glide_speed_limit := 0.0
var glide_pitch := 0.0
var glide_low_momentum_timer := 0.0
var pounce_timer := 0.0
var pounce_cooldown_timer := 0.0
var pounce_direction := 1.0
var active_pounce_speed := 0.0
var pounce_started_from_glide := false
var glide_speed_before_pounce := 0.0
var tail_swipe_timer := 0.0
var tail_swipe_cooldown_timer := 0.0
var tail_swipe_direction := Vector2.RIGHT
var facing_direction := 1.0
var visuals_rest_scale := Vector2.ONE
var feedback_tween: Tween


func _ready() -> void:
	visuals_rest_scale = visuals.scale
	glide_time_remaining = glide_duration
	pounce_hitbox.monitoring = false
	tail_swipe_hitbox.monitoring = false
	_update_sprite_facing()
	_update_sprite_state()


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	# These action names predate the switch to conventional controls. Reversing
	# the axis here also updates existing saved bindings without discarding them.
	var glide_pitch_input := Input.get_axis("glide_dive", "glide_climb")
	var was_on_floor := is_on_floor()
	var fall_speed := velocity.y
	_update_timers(delta)
	_update_glide(delta)
	_update_facing(direction)
	_try_start_pounce(direction)
	_try_start_tail_swipe(direction, glide_pitch_input)
	_update_pounce_hitbox()
	_update_tail_swipe_hitbox()
	_update_sprite_state()

	if pounce_timer > 0.0:
		_apply_pounce(delta)
	elif tail_swipe_timer > 0.0:
		_apply_tail_swipe(delta)
	elif gliding:
		_apply_glide_movement(glide_pitch_input, delta)
	else:
		_apply_horizontal_movement(direction, delta)
		_apply_gravity(delta)
		_handle_jump()

	move_and_slide()
	_update_air_rotation(delta)
	_handle_landing_feedback(was_on_floor, fall_speed)


func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	pounce_timer = maxf(pounce_timer - delta, 0.0)
	pounce_cooldown_timer = maxf(pounce_cooldown_timer - delta, 0.0)
	tail_swipe_timer = maxf(tail_swipe_timer - delta, 0.0)
	tail_swipe_cooldown_timer = maxf(tail_swipe_cooldown_timer - delta, 0.0)


func _apply_horizontal_movement(direction: float, delta: float) -> void:
	var target_speed := direction * max_speed
	var acceleration := air_acceleration

	if is_on_floor():
		acceleration = ground_acceleration if direction != 0.0 else ground_deceleration

	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	var current_gravity := gravity
	if velocity.y > 0.0:
		current_gravity *= fall_gravity_multiplier

	velocity.y += current_gravity * delta


func _handle_jump() -> void:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_release_multiplier


func _update_glide(delta: float) -> void:
	if is_on_floor():
		glide_time_remaining = glide_duration
		gliding = false
		glide_low_momentum_timer = 0.0
		return

	if pounce_timer > 0.0:
		# A Glide Pounce remains part of the same Glide, including its artwork.
		# Pause the Glide timer during the short burst so Pounce does not consume it.
		gliding = pounce_started_from_glide
		if pounce_started_from_glide:
			# Keep glide_momentum/pitch in sync with the pounce's actual velocity
			# (and raise the speed ceiling to match) so a pounce's burst of speed
			# carries straight into the glide once the burst ends, instead of
			# being discarded.
			var current_speed := velocity.length()
			glide_pitch = clampf(
				atan2(velocity.y, maxf(absf(velocity.x), 0.01)),
				deg_to_rad(-glide_max_climb_angle),
				deg_to_rad(glide_max_dive_angle)
			)
			glide_speed_limit = maxf(glide_speed_limit, current_speed)
			glide_momentum = current_speed
		return

	if gliding and Input.is_action_just_pressed("jump"):
		gliding = false
		jump_buffer_timer = 0.0
		glide_low_momentum_timer = 0.0
		return

	var should_start_glide := (
		not gliding
		and Input.is_action_just_pressed("jump")
		and coyote_timer <= 0.0
		and glide_time_remaining > 0.0
	)
	if should_start_glide:
		gliding = true
		jump_buffer_timer = 0.0
		_begin_glide()

	if gliding:
		glide_time_remaining = maxf(glide_time_remaining - delta, 0.0)

		# Sustained climbing bleeds glide_momentum (see _apply_glide_movement).
		# Once that momentum has been spent for too long, the glide cancels
		# instead of letting the player hang there indefinitely.
		if glide_momentum <= glide_low_momentum_threshold:
			glide_low_momentum_timer += delta
		else:
			glide_low_momentum_timer = 0.0

		if glide_time_remaining <= 0.0 or glide_low_momentum_timer >= glide_low_momentum_cancel_time:
			gliding = false
			glide_low_momentum_timer = 0.0
	else:
		glide_low_momentum_timer = 0.0


func _begin_glide() -> void:
	# facing_direction is not derived from velocity.x here: _update_facing()
	# already keeps it in sync with the player's held input for every frame
	# spent airborne and not gliding, including right after canceling a
	# glide. Overriding it from velocity would re-point a fresh glide at
	# whatever direction the old glide's momentum still happened to be
	# carrying, even if the player has since turned around and is holding
	# the opposite direction.

	# Always start level (neutral pitch), regardless of how much vertical
	# speed was carried into the glide - climbing is something the player
	# chooses with input afterward, not an angle inherited from the jump that
	# preceded it (glide can only start once coyote time has expired, so
	# velocity.y is often still strongly upward, which used to point the
	# glide - and the sprite - into a climb for the first second).
	# That vertical speed isn't wasted, though: it still feeds into the
	# glide's starting momentum, so a fast jump still yields a fast glide.
	glide_pitch = deg_to_rad(neutral_glide_pitch)
	glide_momentum = maxf(velocity.length(), glide_speed)
	glide_speed_limit = maxf(glide_max_speed, glide_momentum)


func _apply_glide_movement(pitch_input: float, delta: float) -> void:
	var min_pitch := deg_to_rad(-glide_max_climb_angle)
	var max_pitch := deg_to_rad(glide_max_dive_angle)

	if absf(pitch_input) > 0.05:
		var pitch_change := deg_to_rad(glide_pitch_speed) * pitch_input * delta
		glide_pitch += pitch_change
	else:
		glide_pitch = move_toward(
			glide_pitch,
			deg_to_rad(neutral_glide_pitch),
			deg_to_rad(neutral_glide_pitch_speed) * delta
		)
	glide_pitch = clampf(glide_pitch, min_pitch, max_pitch)

	# Downward steepness controls acceleration: diving builds momentum, while
	# climbing (a negative pitch) spends it - so pulling up trades speed for
	# altitude instead of generating free lift, and a glide can't sustain or
	# gain height forever without diving again to earn the momentum back.
	var angle_factor := sin(glide_pitch)
	var current_acceleration := (
		lerpf(glide_shallow_acceleration, glide_acceleration, angle_factor)
		if angle_factor >= 0.0
		else angle_factor * glide_climb_drag
	)
	glide_momentum = clampf(
		glide_momentum + current_acceleration * delta,
		0.0,
		glide_speed_limit
	)

	var glide_direction := Vector2(
		cos(glide_pitch) * facing_direction,
		sin(glide_pitch)
	)
	velocity = glide_direction * glide_momentum


func is_gliding() -> bool:
	return gliding


func _try_start_pounce(direction: float) -> void:
	if (
		not Input.is_action_just_pressed("pounce")
		or pounce_cooldown_timer > 0.0
		or tail_swipe_timer > 0.0
	):
		return

	_start_pounce(direction)


func _start_pounce(direction: float) -> void:
	pounce_started_from_glide = gliding
	glide_speed_before_pounce = velocity.length() if gliding else 0.0
	active_pounce_speed = (
		velocity.length() * glide_pounce_speed_multiplier
		if gliding
		else pounce_speed
	)
	pounce_direction = facing_direction if gliding else direction
	if absf(pounce_direction) <= 0.1:
		pounce_direction = facing_direction
	gliding = pounce_started_from_glide
	pounce_timer = pounce_duration
	pounce_cooldown_timer = pounce_cooldown
	_play_sprite_feedback(pounce_stretch_scale, pounce_duration)


func _apply_pounce(delta: float) -> void:
	velocity.x = pounce_direction * active_pounce_speed
	if not is_on_floor():
		velocity.y += gravity * pounce_gravity_multiplier * delta


func is_pouncing() -> bool:
	return pounce_timer > 0.0


func _update_pounce_hitbox() -> void:
	var hitbox_offset := absf(pounce_hitbox_shape.position.x)
	pounce_hitbox_shape.position.x = hitbox_offset * pounce_direction
	pounce_hitbox.monitoring = is_pouncing()


func _try_start_tail_swipe(horizontal_input: float, vertical_input: float) -> void:
	if (
		not Input.is_action_just_pressed("tail_swipe")
		or tail_swipe_cooldown_timer > 0.0
		or pounce_timer > 0.0
	):
		return

	_start_tail_swipe(horizontal_input, vertical_input)


func _start_tail_swipe(horizontal_input: float, vertical_input: float) -> void:
	if absf(horizontal_input) > 0.1:
		facing_direction = signf(horizontal_input)
		_update_sprite_facing()

	var down_is_dominant := (
		vertical_input >= tail_swipe_down_aim_threshold
		and vertical_input > absf(horizontal_input)
	)
	tail_swipe_direction = Vector2.DOWN if down_is_dominant else Vector2(facing_direction, 0.0)
	gliding = false
	if down_is_dominant:
		# The downward version keeps a brief vertical stutter for aiming, but it
		# does not erase horizontal travel. Lateral Swipes preserve all momentum.
		velocity.y *= tail_swipe_down_stutter_vertical_retention
	tail_swipe_timer = tail_swipe_duration
	tail_swipe_cooldown_timer = tail_swipe_cooldown
	_play_sprite_feedback(tail_swipe_scale, tail_swipe_duration)


func _apply_tail_swipe(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * tail_swipe_gravity_multiplier * delta


func is_tail_swiping() -> bool:
	return tail_swipe_timer > 0.0


func _update_tail_swipe_hitbox() -> void:
	var active := is_tail_swiping()
	# The convex shape is authored as a right-facing half-circle rooted at the
	# player, then rotated to the direction that was locked at attack start.
	tail_swipe_hitbox_shape.position = Vector2.ZERO
	tail_swipe_hitbox_shape.rotation = tail_swipe_direction.angle()
	tail_swipe_hitbox.monitoring = active
	tail_swipe_indicator.points = PackedVector2Array([
		Vector2.ZERO,
		tail_swipe_direction * tail_swipe_reach,
	])
	tail_swipe_indicator.visible = active


func _on_pounce_hitbox_area_entered(area: Area2D) -> void:
	if not is_pouncing() or not area.has_method("receive_pounce"):
		return
	area.call("receive_pounce", self)


func _on_tail_swipe_hitbox_area_entered(area: Area2D) -> void:
	if not is_tail_swiping() or not area.has_method("receive_tail_swipe"):
		return
	area.call("receive_tail_swipe", self)


func rebound_from_tail_swipe(hit_position: Vector2) -> void:
	if tail_swipe_direction == Vector2.DOWN:
		velocity.y = minf(velocity.y, -tail_swipe_down_bounce_speed)
	else:
		var recoil_direction := signf(global_position.x - hit_position.x)
		if is_zero_approx(recoil_direction):
			recoil_direction = -tail_swipe_direction.x
		var retained_speed := absf(velocity.x) * tail_swipe_lateral_hit_momentum_retention
		velocity.x = recoil_direction * maxf(tail_swipe_lateral_recoil_speed, retained_speed)

	tail_swipe_timer = 0.0
	tail_swipe_hitbox.set_deferred("monitoring", false)


func rebound_from_pounce(hit_position: Vector2) -> void:
	var rebound_direction := signf(global_position.x - hit_position.x)
	if is_zero_approx(rebound_direction):
		rebound_direction = -pounce_direction

	pounce_timer = 0.0
	pounce_cooldown_timer = 0.0
	pounce_hitbox.set_deferred("monitoring", false)
	if pounce_started_from_glide:
		_apply_glide_pounce_rebound(hit_position)
		glide_time_remaining = minf(
			glide_duration,
			maxf(glide_time_remaining, glide_pounce_refill_time)
		)
	else:
		velocity = Vector2(rebound_direction * pounce_rebound_speed.x, pounce_rebound_speed.y)

	pounce_started_from_glide = false
	facing_direction = signf(velocity.x) if not is_zero_approx(velocity.x) else rebound_direction
	_update_sprite_facing()
	_play_sprite_feedback(pounce_rebound_scale, landing_recovery_time)


func _apply_glide_pounce_rebound(hit_position: Vector2) -> void:
	var horizontal_offset := global_position.x - hit_position.x
	var dome_x := 0.0
	if absf(horizontal_offset) > glide_pounce_vertical_snap_distance:
		dome_x = clampf(
			horizontal_offset / maxf(glide_pounce_dome_half_width, 1.0),
			-1.0,
			1.0
		)
	var bounce_direction := Vector2(dome_x, -glide_pounce_upward_bias).normalized()
	var minimum_rebound_speed := pounce_rebound_speed.length()
	var rebound_speed_cap := maxf(
		minimum_rebound_speed,
		glide_pounce_rebound_speed_cap
	)
	var rebound_speed := clampf(
		glide_speed_before_pounce * glide_pounce_momentum_retention,
		minimum_rebound_speed,
		rebound_speed_cap
	)
	velocity = bounce_direction * rebound_speed
	gliding = true
	glide_momentum = rebound_speed
	glide_speed_limit = maxf(glide_max_speed, rebound_speed)
	glide_pitch = clampf(
		atan2(velocity.y, maxf(absf(velocity.x), 0.1)),
		deg_to_rad(-glide_max_climb_angle),
		deg_to_rad(glide_max_dive_angle)
	)


func _update_facing(direction: float) -> void:
	if direction != 0.0 and not gliding:
		facing_direction = signf(direction)
		_update_sprite_facing()


func _update_sprite_facing() -> void:
	# The normal artwork faces left, while the glide artwork faces right.
	sprite.flip_h = facing_direction > 0.0
	glide_sprite.flip_h = facing_direction < 0.0


func _update_sprite_state() -> void:
	sprite.visible = not gliding
	glide_sprite.visible = gliding


func _update_air_rotation(delta: float) -> void:
	if not gliding:
		visuals.rotation = 0.0
		return

	var target_rotation := glide_pitch * facing_direction
	var rotation_weight := clampf(air_rotation_speed * delta, 0.0, 1.0)
	visuals.rotation = lerp_angle(visuals.rotation, target_rotation, rotation_weight)


func _handle_landing_feedback(was_on_floor: bool, fall_speed: float) -> void:
	var just_landed := not was_on_floor and is_on_floor()
	if not just_landed or fall_speed < minimum_squash_speed:
		return

	_play_sprite_feedback(landing_squash_scale, landing_recovery_time)


func _play_sprite_feedback(start_scale: Vector2, recovery_time: float) -> void:
	if feedback_tween and feedback_tween.is_valid():
		feedback_tween.kill()

	visuals.scale = visuals_rest_scale * start_scale
	feedback_tween = create_tween()
	feedback_tween.tween_property(visuals, "scale", visuals_rest_scale, recovery_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
