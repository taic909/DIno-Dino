extends CharacterBody2D

@export_category("Movement")
@export var max_speed := 240.0
@export var ground_acceleration := 650.0
@export var ground_deceleration := 2200.0
@export var air_acceleration := 1100.0

@export_category("Jump")
@export var jump_velocity := -500.0
@export var gravity := 1200.0
@export var fall_gravity_multiplier := 1.35
@export var jump_release_multiplier := 0.5
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.12

@export_category("Glide")
@export var glide_duration := .35
@export var glide_speed := 285.0
@export var glide_acceleration := 1600.0
@export var glide_shallow_acceleration := 80.0
@export var glide_max_speed := 520.0
@export var glide_pitch_speed := 100.0

@export_category("Air Rotation")
@export_range(-45.0, 0.0, 1.0, "suffix:°") var minimum_air_rotation := -15.0
@export_range(0.0, 60.0, 1.0, "suffix:°") var maximum_air_rotation := 35.0
@export var air_rotation_speed := 8.0

@export_category("Pounce")
@export var pounce_speed := 520.0
@export var pounce_duration := 0.2
@export var pounce_cooldown := 0.35
@export_range(0.0, 1.0, 0.05) var pounce_gravity_multiplier := 0.7
@export var pounce_stretch_scale := Vector2(1.24, 0.82)
@export var pounce_rebound_speed := Vector2(220.0, -320.0)
@export var pounce_rebound_scale := Vector2(0.86, 1.18)

@export_category("Landing Feedback")
@export var minimum_squash_speed := 180.0
@export var landing_squash_scale := Vector2(1.12, 0.82)
@export var landing_recovery_time := 0.12

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var glide_sprite: Sprite2D = $Visuals/GlideSprite
@onready var pounce_hitbox: Area2D = $PounceHitbox
@onready var pounce_hitbox_shape: CollisionShape2D = $PounceHitbox/HitboxShape

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var glide_time_remaining := 0.0
var gliding := false
var glide_momentum := 0.0
var glide_speed_limit := 0.0
var glide_pitch := 0.0
var pounce_timer := 0.0
var pounce_cooldown_timer := 0.0
var pounce_direction := 1.0
var facing_direction := 1.0
var visuals_rest_scale := Vector2.ONE
var feedback_tween: Tween


func _ready() -> void:
	visuals_rest_scale = visuals.scale
	glide_time_remaining = glide_duration
	pounce_hitbox.monitoring = false
	_update_sprite_facing()
	_update_sprite_state()


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var was_on_floor := is_on_floor()
	var fall_speed := velocity.y
	_update_timers(delta)
	_update_glide(delta)
	_update_facing(direction)
	_try_start_pounce(direction)
	_update_pounce_hitbox()
	_update_sprite_state()

	if pounce_timer > 0.0:
		_apply_pounce(delta)
	elif gliding:
		_apply_glide_movement(direction, delta)
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
		return

	var was_gliding := gliding
	gliding = (
		velocity.y >= 0.0
		and Input.is_action_pressed("jump")
		and glide_time_remaining > 0.0
		and pounce_timer <= 0.0
	)

	if gliding:
		if not was_gliding:
			_begin_glide()
		glide_time_remaining = maxf(glide_time_remaining - delta, 0.0)


func _begin_glide() -> void:
	if absf(velocity.x) > 0.1:
		facing_direction = signf(velocity.x)
		_update_sprite_facing()

	glide_momentum = maxf(velocity.length(), glide_speed)
	glide_speed_limit = maxf(glide_max_speed, glide_momentum)
	var horizontal_speed := maxf(absf(velocity.x), 0.1)
	glide_pitch = clampf(
		atan2(velocity.y, horizontal_speed),
		deg_to_rad(minimum_air_rotation),
		deg_to_rad(maximum_air_rotation)
	)


func _apply_glide_movement(direction: float, delta: float) -> void:
	# Forward input dives; backward input raises the nose without reversing direction.
	var pitch_input := direction * facing_direction
	var pitch_change := deg_to_rad(glide_pitch_speed) * pitch_input * delta
	glide_pitch = clampf(
		glide_pitch + pitch_change,
		deg_to_rad(minimum_air_rotation),
		deg_to_rad(maximum_air_rotation)
	)

	var angle_factor := inverse_lerp(
		deg_to_rad(minimum_air_rotation),
		deg_to_rad(maximum_air_rotation),
		glide_pitch
	)
	var current_acceleration := lerpf(
		glide_shallow_acceleration,
		glide_acceleration,
		angle_factor
	)
	glide_momentum = minf(
		glide_momentum + current_acceleration * delta,
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
	if not Input.is_action_just_pressed("pounce") or pounce_cooldown_timer > 0.0:
		return

	_start_pounce(direction)


func _start_pounce(direction: float) -> void:
	pounce_direction = facing_direction if gliding else direction
	if absf(pounce_direction) <= 0.1:
		pounce_direction = facing_direction
	gliding = false
	pounce_timer = pounce_duration
	pounce_cooldown_timer = pounce_cooldown
	_play_sprite_feedback(pounce_stretch_scale, pounce_duration)


func _apply_pounce(delta: float) -> void:
	velocity.x = pounce_direction * pounce_speed
	if not is_on_floor():
		velocity.y += gravity * pounce_gravity_multiplier * delta


func is_pouncing() -> bool:
	return pounce_timer > 0.0


func _update_pounce_hitbox() -> void:
	var hitbox_offset := absf(pounce_hitbox_shape.position.x)
	pounce_hitbox_shape.position.x = hitbox_offset * pounce_direction
	pounce_hitbox.monitoring = is_pouncing()


func _on_pounce_hitbox_area_entered(area: Area2D) -> void:
	if not is_pouncing() or not area.has_method("receive_pounce"):
		return
	area.call("receive_pounce", self)


func rebound_from_pounce(hit_position: Vector2) -> void:
	var rebound_direction := signf(global_position.x - hit_position.x)
	if is_zero_approx(rebound_direction):
		rebound_direction = -pounce_direction

	pounce_timer = 0.0
	pounce_cooldown_timer = 0.0
	pounce_hitbox.set_deferred("monitoring", false)
	facing_direction = rebound_direction
	_update_sprite_facing()
	velocity = Vector2(rebound_direction * pounce_rebound_speed.x, pounce_rebound_speed.y)
	_play_sprite_feedback(pounce_rebound_scale, landing_recovery_time)


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
