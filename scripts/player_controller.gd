extends CharacterBody2D

signal dev_flight_changed(active: bool)

@export_category("Movement")
## Top horizontal running speed.
@export var max_speed := 300.0
## How quickly ground movement reaches running speed.
@export var ground_acceleration := 650.0
## How quickly the player stops after releasing movement.
@export var ground_deceleration := 2200.0
## How quickly horizontal input changes speed in the air.
@export var air_acceleration := 1100.0

@export_category("Developer Flight")
## Direct movement speed while developer Flight Mode is active.
@export var dev_flight_speed := 2020.0

@export_category("Jump")
## Initial upward jump speed; a more negative value jumps higher.
@export var jump_velocity := -600.0
## Downward acceleration applied while airborne.
@export var gravity := 1200.0
## Extra gravity while falling; higher values make falls snappier.
@export var fall_gravity_multiplier := 1.35
## Upward speed kept when Jump is released early; lower values shorten jumps more.
@export var jump_release_multiplier := 0.5
## Seconds after leaving a ledge that a jump is still allowed.
@export var coyote_time := 0.1
## Seconds an early Jump press is remembered before landing.
@export var jump_buffer_time := 0.12

@export_category("Glide")
## Maximum seconds one Glide can remain active.
@export var glide_duration := 10.0
## Strength of gravity projected along the Glide direction.
@export_range(0.0, 2.0, 0.05) var glide_gravity_multiplier := 1.0
## Safety cap for extremely fast Glide movement.
@export var glide_max_speed := 1400.0
## Degrees per second that climb or dive input changes pitch.
@export var glide_pitch_speed := 100.0
## Downward angle the Glide settles toward with no pitch input.
@export_range(0.0, 45.0, 1.0, "suffix:°") var neutral_glide_pitch := 10.0
## Degrees per second that pitch returns toward its neutral angle.
@export var neutral_glide_pitch_speed := 45.0
## Steepest upward Glide angle.
@export_range(0.0, 90.0, 1.0, "suffix:°") var glide_max_climb_angle := 35.0
## Steepest downward Glide angle.
@export_range(0.0, 180.0, 1.0, "suffix:°") var glide_max_dive_angle := 115.0
## Furthest pitch reachable after an inverted roll, allowing a midair U-turn.
@export_range(90.0, 360.0, 1.0, "suffix:°") var glide_inverted_turn_limit := 270.0
## Speed below which Glide is considered too slow to sustain.
@export var glide_low_momentum_threshold := 150.0
## Seconds spent below the low-speed threshold before Glide ends.
@export var glide_low_momentum_cancel_time := 0.2
## Minimum seconds that post-Glide momentum handling remains active.
@export var glide_exit_momentum_time := 1.0
## Speed removed per second after Glide ends.
@export var glide_exit_drag := 220.0
## Horizontal steering strength while carrying momentum after Glide.
@export var glide_exit_air_steering := 100.0
## Acceleration used when restarting Glide in the opposite direction.
@export var glide_reverse_acceleration := 1800.0
## Seconds for one visual 180-degree Glide roll.
@export_range(0.05, 2.0, 0.01) var glide_spin_duration := 0.28
## Roll angle where steering is halfway between upright and inverted.
@export_range(90.0, 150.0, 1.0, "suffix:°") var glide_spin_steering_switch_angle := 115.0
## Flight-path angle allowed while rolling before inverted steering takes over.
@export_range(90.0, 180.0, 1.0, "suffix:°") var glide_spin_transition_pitch_limit := 115.0
## Maximum degrees from parallel for a glancing wall or ceiling bounce.
@export_range(0.0, 45.0, 1.0, "suffix:°") var glide_surface_glance_max_angle := 20.0
## Fraction of speed kept after a shallow wall or ceiling bounce.
@export_range(0.0, 1.0, 0.05) var glide_surface_glance_speed_retention := 0.65
## Fraction of speed kept after a direct wall or ceiling impact.
@export_range(0.0, 1.0, 0.05) var glide_hard_impact_speed_retention := 0.3
## Fraction of horizontal Glide speed kept on landing.
@export_range(0.0, 1.0, 0.05) var glide_ground_impact_speed_retention := 0.55
## Horizontal speed removed per second while the landing carry settles.
@export var glide_ground_momentum_drag := 1600.0
## Minimum seconds spent easing out of a Glide landing.
@export var glide_ground_momentum_time := 0.2
## Extra speed pushing the player away after a hard wall impact.
@export var glide_wall_hard_impact_recoil := 40.0
## Minimum speed into a surface before it counts as a Glide impact.
@export var glide_min_surface_impact_speed := 25.0

@export_category("Air Rotation")
## How quickly Glide artwork rotates to match the movement angle.
@export var air_rotation_speed := 8.0

@export_category("Pounce")
## Fixed horizontal Pounce speed when not Gliding.
@export var pounce_speed := 520.0
## Multiplier applied to current speed for a Glide Pounce.
@export var glide_pounce_speed_multiplier := 1.5
## Seconds the Pounce movement burst lasts.
@export var pounce_duration := 0.2
## Seconds before Pounce can be used again.
@export var pounce_cooldown := 0.35
## Fraction of normal gravity applied during a Pounce.
@export_range(0.0, 1.0, 0.05) var pounce_gravity_multiplier := 0.7
## Temporary visual stretch at Pounce startup.
@export var pounce_stretch_scale := Vector2(1.24, 0.82)
## Horizontal and vertical launch speed after a normal Pounce rebound.
@export var pounce_rebound_speed := Vector2(220.0, -320.0)
## Temporary visual squash after a Pounce rebound.
@export var pounce_rebound_scale := Vector2(0.86, 1.18)
## Fraction of pre-Pounce Glide speed kept by an enemy rebound.
@export_range(0.0, 1.0, 0.05) var glide_pounce_momentum_retention := 0.9
## Maximum speed allowed after a Glide-Pounce rebound.
@export var glide_pounce_rebound_speed_cap := 560.0
## Minimum Glide time remaining after a successful Pounce hit.
@export var glide_pounce_refill_time := 1.25
## Upward strength of the rounded enemy rebound direction.
@export_range(0.1, 3.0, 0.05) var glide_pounce_upward_bias := 1.0
## Horizontal distance used to shape an enemy like a rounded bounce surface.
@export var glide_pounce_dome_half_width := 48.0
## Distance from enemy center that produces a straight-up rebound.
@export var glide_pounce_vertical_snap_distance := 6.0

@export_category("Tail Swipe")
## Seconds a Tail Swipe remains active.
@export var tail_swipe_duration := 0.16
## Seconds before Tail Swipe can be used again.
@export var tail_swipe_cooldown := 0.3
## Fraction of vertical speed kept when starting a downward Swipe.
@export_range(0.0, 1.0, 0.05) var tail_swipe_down_stutter_vertical_retention := 0.35
## Fraction of normal gravity applied during a Tail Swipe.
@export_range(0.0, 1.0, 0.05) var tail_swipe_gravity_multiplier := 0.4
## Fraction of horizontal speed kept when a lateral Swipe hits.
@export_range(0.0, 1.0, 0.05) var tail_swipe_lateral_hit_momentum_retention := 0.6
## Minimum recoil speed away from a lateral Swipe target.
@export var tail_swipe_lateral_recoil_speed := 180.0
## Upward bounce speed after a downward Swipe connects.
@export var tail_swipe_down_bounce_speed := 600.0
## Temporary visual scale while Tail Swipe is active.
@export var tail_swipe_scale := Vector2(1.12, 0.9)
## Distance the Tail Swipe hitbox reaches from the player.
@export var tail_swipe_reach := 82.0
## Down-input strength required to choose the downward Swipe.
@export_range(0.0, 1.0, 0.05) var tail_swipe_down_aim_threshold := 0.5

@export_category("Landing Feedback")
## Minimum falling speed required to show landing squash feedback.
@export var minimum_squash_speed := 180.0
## Temporary visual squash used on a hard landing.
@export var landing_squash_scale := Vector2(1.12, 0.82)
## Seconds for landing squash to return to normal.
@export var landing_recovery_time := 0.12

@export_category("Contact Damage")
## Player health points at the start of a room.
@export var max_health := 3
## Seconds of protection after taking enemy contact damage.
@export var contact_invulnerability_time := 0.6
## Horizontal and vertical velocity applied when hurt.
@export var contact_knockback := Vector2(260.0, -260.0)
## Temporary player tint after taking damage.
@export var damage_flash_color := Color(1.0, 0.35, 0.35, 1.0)
## Seconds the damage tint takes to fade.
@export var damage_flash_time := 0.14

@export_category("Animation")
## Playback speed of the two-frame running animation.
@export var run_animation_fps := 8.0
## Alignment correction for the first running frame.
@export var run_frame_zero_offset := Vector2(-3.4, 0.0)
## Alignment correction for the second running frame.
@export var run_frame_one_offset := Vector2(3.4, 0.4)

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var glide_sprite: Sprite2D = $Visuals/GlideSprite
@onready var run_sprite: Sprite2D = $Visuals/RunSprite
@onready var lateral_tail_swipe_sprite: Sprite2D = $Visuals/LateralTailSwipeSprite
@onready var downward_tail_swipe_sprite: Sprite2D = $Visuals/DownwardTailSwipeSprite
@onready var pounce_hitbox: Area2D = $PounceHitbox
@onready var pounce_hitbox_shape: CollisionShape2D = $PounceHitbox/HitboxShape
@onready var tail_swipe_hitbox: Area2D = $TailSwipeHitbox
@onready var tail_swipe_hitbox_shape: CollisionShape2D = $TailSwipeHitbox/HitboxShape
@onready var tail_swipe_indicator: Line2D = $TailSwipeIndicator
@onready var downward_tail_swipe_hitbox: Area2D = $DownwardTailSwipeHitbox
@onready var downward_tail_swipe_indicator: Line2D = $DownwardTailSwipeIndicator
@onready var jump_sfx: AudioStreamPlayer = $JumpSfx
@onready var glide_sfx: AudioStreamPlayer = $GlideSfx
@onready var pounce_sfx: AudioStreamPlayer = $PounceSfx
@onready var tail_swipe_sfx: AudioStreamPlayer = $TailSwipeSfx
@onready var land_sfx: AudioStreamPlayer = $LandSfx
@onready var hurt_sfx: AudioStreamPlayer = $HurtSfx

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var glide_time_remaining := 0.0
var gliding := false
var glide_momentum := 0.0
var glide_speed_limit := 0.0
var glide_pitch := 0.0
var glide_visual_pitch := 0.0
var glide_roll_angle := 0.0
var glide_roll_target := 0.0
var glide_sprite_rest_scale_y := 0.0
var glide_low_momentum_timer := 0.0
var glide_exit_timer := 0.0
var glide_exit_active := false
var glide_reversal_active := false
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
var dev_flight_mode := false # Allow precise, gravity-free movement for room testing.
var current_health := 0
var contact_invulnerability_timer := 0.0
var visuals_rest_scale := Vector2.ONE
var feedback_tween: Tween
var damage_tween: Tween


func _ready() -> void:
	visuals_rest_scale = visuals.scale
	glide_sprite_rest_scale_y = glide_sprite.scale.y # Preserve the authored sprite size for the roll.
	glide_time_remaining = glide_duration
	current_health = max_health # Fill the prototype health value.
	RoomManager.apply_pending_entry(self) # Restore state when entering through a RoomDoor.
	pounce_hitbox.monitoring = false
	tail_swipe_hitbox.monitoring = false
	downward_tail_swipe_hitbox.monitoring = false # Disable the downward attack at startup.
	_update_sprite_facing()
	_update_sprite_state()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("dev_toggle_flight"):
		set_dev_flight_mode(not dev_flight_mode) # Toggle flight from the rebindable gameplay shortcut.
	if dev_flight_mode:
		_apply_dev_flight() # Replace ordinary physics with direct four-direction movement.
		move_and_slide() # Keep terrain collision active while flying.
		_update_sprite_state() # Keep player art visible during flight.
		return # Skip gravity, Glide, jumps, and attacks in flight mode.
	var direction := Input.get_axis("move_left", "move_right")
	# These action names predate the switch to conventional controls. Reversing
	# the axis here also updates existing saved bindings without discarding them.
	# Existing action names remain so saved bindings work; inversion reverses pitch below.
	var glide_pitch_input := Input.get_axis("glide_dive", "glide_climb")
	var was_on_floor := is_on_floor()
	var fall_speed := velocity.y
	_update_timers(delta)
	_update_facing(direction) # Let a new Glide see a turn made on this same physics frame.
	_update_glide(delta)
	_try_glide_spin() # Accept a roll only during an active Glide.
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

	var gliding_into_terrain := gliding and pounce_timer <= 0.0 # Leave the Glide-Pounce burst's own momentum rules intact.
	var velocity_before_collision := velocity
	move_and_slide()
	if gliding_into_terrain:
		_handle_glide_surface_collisions(velocity_before_collision) # Apply the actual surface impact before the next Glide frame.
	_update_air_rotation(delta)
	_handle_landing_feedback(was_on_floor, fall_speed)


func set_dev_flight_mode(active: bool) -> void:
	if dev_flight_mode == active:
		return # Avoid resetting momentum on a duplicate menu update.
	dev_flight_mode = active
	velocity = Vector2.ZERO # Freeze immediately when flight changes, including in midair.
	gliding = false # Leave the normal Glide state behind.
	glide_exit_active = false # Do not carry Glide momentum into or out of flight.
	glide_reversal_active = false # Clear a mid-turn acceleration ramp when switching to flight.
	jump_buffer_timer = 0.0 # Discard presses buffered before free movement started.
	coyote_timer = 0.0 # Avoid an unexpected grace-period jump when flight ends.
	pounce_timer = 0.0 # Cancel an in-progress movement attack.
	tail_swipe_timer = 0.0 # Cancel an in-progress close attack.
	_update_pounce_hitbox() # Disable Pounce collision during free flight.
	_update_tail_swipe_hitbox() # Hide swipe hitboxes and indicators when flight interrupts an attack.
	visuals.rotation = 0.0 # Keep the dinosaur upright while hovering.
	_reset_glide_spin() # Keep the dinosaur upright while hovering.
	_update_sprite_state() # Restore neutral artwork immediately after cancelling attacks or Glide.
	dev_flight_changed.emit(active) # Keep the dev-menu checkbox synchronized.


func _apply_dev_flight() -> void:
	var horizontal := Input.get_axis("move_left", "move_right")
	var vertical := Input.get_axis("glide_dive", "glide_climb")
	var flight_direction := Vector2(horizontal, vertical).limit_length() # Prevent diagonal movement from exceeding flight speed.
	velocity = flight_direction * dev_flight_speed # Zero stick input stops the player on this physics frame.
	if horizontal != 0.0:
		facing_direction = signf(horizontal) # Face the direction of horizontal flight.
		_update_sprite_facing() # Mirror the current artwork to match movement.


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
	glide_exit_timer = maxf(glide_exit_timer - delta, 0.0) # Count down the soft momentum window.
	contact_invulnerability_timer = maxf(contact_invulnerability_timer - delta, 0.0) # Count down contact protection.


func _apply_horizontal_movement(direction: float, delta: float) -> void:
	var target_speed := direction * max_speed
	var acceleration := air_acceleration

	if glide_exit_active: # Keep earned speed briefly after either an air exit or a landing.
		if is_on_floor():
			velocity.x = move_toward(velocity.x, target_speed, glide_ground_momentum_drag * delta) # Settle toward running speed without an instant clamp.
		else:
			velocity.x = move_toward(velocity.x, 0.0, glide_exit_drag * delta) # Bleed horizontal air momentum gradually.
			velocity.x += direction * glide_exit_air_steering * delta # Allow mild steering during the air carry.
		if glide_exit_timer <= 0.0 and absf(velocity.x) <= max_speed: # End once carry time and overspeed have both passed.
			glide_exit_active = false # Restore ordinary ground or air movement.
		return # Skip the normal speed clamp.

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
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0: # Keep normal jumps grounded when flight is off.
		velocity.y = jump_velocity
		jump_sfx.play() # Play the placeholder jump sound.
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_release_multiplier


func _update_glide(delta: float) -> void:
	if is_on_floor():
		_adopt_glide_return_heading() # Keep the new facing when an inverted turn reaches ground.
		glide_time_remaining = glide_duration
		gliding = false
		glide_low_momentum_timer = 0.0
		glide_reversal_active = false # A grounded start uses the normal walking-speed floor.
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
			var pounce_pitch := atan2(velocity.y, velocity.x * facing_direction)
			if glide_pitch > PI * 0.5 and pounce_pitch < 0.0:
				pounce_pitch += TAU # Keep a U-turn arc continuous when the heading crosses left.
			glide_pitch = clampf(pounce_pitch, deg_to_rad(-glide_max_climb_angle), deg_to_rad(glide_inverted_turn_limit))
			glide_speed_limit = maxf(glide_speed_limit, current_speed)
			glide_momentum = current_speed
		return

	if gliding and Input.is_action_just_pressed("jump"):
		_begin_glide_exit() # Preserve speed when Glide is canceled.
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
			_begin_glide_exit() # Ease out when Glide ends naturally.
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
	# A stationary or same-direction start uses at least walking speed.
	# Ignore vertical jump speed, and ramp up when old travel opposes the new facing.
	glide_pitch = deg_to_rad(neutral_glide_pitch)
	glide_reversal_active = velocity.x * facing_direction < -0.1 # Opposite travel cannot become free speed in the new direction.
	glide_momentum = 0.0 if glide_reversal_active else maxf(absf(velocity.x), max_speed) # Reversing starts slow; other entries keep earned speed.
	glide_speed_limit = maxf(glide_max_speed, glide_momentum)
	glide_exit_active = false # Stop any previous exit carry.
	glide_sfx.play() # Play the placeholder Glide sound.


func _begin_glide_exit() -> void: # Start a soft transition from Glide.
	_adopt_glide_return_heading() # Keep the new facing after a completed U-turn.
	gliding = false # Leave active Glide physics.
	glide_reversal_active = false # A later Glide decides its own entry direction.
	glide_exit_active = true # Keep overspeed air movement temporarily.
	glide_exit_timer = glide_exit_momentum_time # Set the minimum carry time.


func _adopt_glide_return_heading() -> void:
	if gliding and glide_pitch > PI * 0.5 and absf(velocity.x) > 0.1:
		facing_direction = signf(velocity.x) # Face the new travel direction after the return arc.
		_update_sprite_facing()


func _apply_glide_movement(pitch_input: float, delta: float) -> void:
	var min_pitch := deg_to_rad(-glide_max_climb_angle)
	var roll_phase := fposmod(glide_roll_angle, TAU)
	var switch_angle := deg_to_rad(glide_spin_steering_switch_angle)
	var blend_half_width := deg_to_rad(25.0)
	var inversion_weight := smoothstep(switch_angle - blend_half_width, switch_angle + blend_half_width, roll_phase)
	if roll_phase > PI:
		inversion_weight = 1.0 - smoothstep(PI + switch_angle - blend_half_width, PI + switch_angle + blend_half_width, roll_phase)
	var rolling := not is_equal_approx(glide_roll_angle, glide_roll_target)
	var pitch_limit := glide_max_dive_angle
	if rolling or inversion_weight > 0.0:
		pitch_limit = lerpf(glide_spin_transition_pitch_limit, glide_inverted_turn_limit, inversion_weight) # Permit a little extra turn before steering fully inverts.
	var max_pitch := maxf(deg_to_rad(pitch_limit), glide_pitch) # Rolling upright mid-turn cannot snap the heading.

	if absf(pitch_input) > 0.05:
		var local_pitch_input := pitch_input * (1.0 - 2.0 * inversion_weight) # Ease through the control reversal instead of flipping it in one frame.
		var pitch_change := deg_to_rad(glide_pitch_speed) * local_pitch_input * delta
		glide_pitch += pitch_change
	elif not rolling and (inversion_weight < 0.5 or glide_pitch <= PI * 0.5):
		glide_pitch = move_toward(
			glide_pitch,
			deg_to_rad(neutral_glide_pitch),
			deg_to_rad(neutral_glide_pitch_speed) * delta
		) # Hold the return-arc angle while inverted with no stick input.
	glide_pitch = clampf(glide_pitch, min_pitch, max_pitch)
	if glide_reversal_active:
		glide_momentum = minf(glide_momentum + glide_reverse_acceleration * delta, max_speed) # Build speed in the new direction over a short ramp.
		if glide_momentum >= max_speed:
			glide_reversal_active = false # Return to gravity-driven Glide speed after reaching walking pace.

	# Project gravity onto the chosen flight direction so downward travel gains
	# speed continuously, level travel gains none, and climbing spends momentum.
	var gravity_along_glide := gravity * sin(glide_pitch) * glide_gravity_multiplier
	glide_momentum = clampf(glide_momentum + gravity_along_glide * delta, 0.0, glide_speed_limit) # Apply gravity without a low artificial Glide cap.

	var glide_direction := Vector2(
		cos(glide_pitch) * facing_direction,
		sin(glide_pitch)
	)
	velocity = glide_direction * glide_momentum


func _handle_glide_surface_collisions(incoming_velocity: Vector2) -> void: # Choose the strongest terrain impact from this slide.
	var strongest_normal := Vector2.ZERO
	var strongest_impact_speed := glide_min_surface_impact_speed
	for collision_index: int in get_slide_collision_count():
		var surface_normal := get_slide_collision(collision_index).get_normal()
		var impact_speed := -incoming_velocity.dot(surface_normal)
		if impact_speed > strongest_impact_speed:
			strongest_normal = surface_normal # Use the surface absorbing the most speed.
			strongest_impact_speed = impact_speed
	if strongest_normal != Vector2.ZERO:
		_apply_glide_surface_impact(incoming_velocity, strongest_normal) # Resolve one meaningful impact per physics frame.


func _apply_glide_surface_impact(incoming_velocity: Vector2, surface_normal: Vector2) -> void: # Trade Glide speed for a glancing bounce or a hard stop.
	var impact_fraction := -incoming_velocity.normalized().dot(surface_normal)
	var impact_angle_from_parallel := rad_to_deg(asin(clampf(impact_fraction, 0.0, 1.0)))
	var is_wall := absf(surface_normal.x) > absf(surface_normal.y)
	var is_ceiling := surface_normal.y > absf(surface_normal.x)
	var is_floor := surface_normal.y < -absf(surface_normal.x)
	var can_glance_bounce := (is_wall or is_ceiling) and impact_angle_from_parallel <= glide_surface_glance_max_angle
	if can_glance_bounce:
		velocity = incoming_velocity.bounce(surface_normal) * glide_surface_glance_speed_retention # Reflect a shallow hit without restoring full speed.
	elif is_floor:
		velocity = incoming_velocity.slide(surface_normal) * glide_ground_impact_speed_retention # Preserve some horizontal landing travel.
	else:
		velocity = incoming_velocity.bounce(surface_normal) * glide_hard_impact_speed_retention # Rebound hard wall or ceiling hits at much lower speed.
		if is_wall:
			velocity += surface_normal * glide_wall_hard_impact_recoil # Push slightly away so the player does not stick to the wall.
	glide_momentum = velocity.length() # Do not restore the old Glide speed on the next frame.
	_begin_glide_exit() # Let normal air physics carry the bounce or slowdown afterward.
	if is_floor:
		glide_exit_timer = glide_ground_momentum_time # Hold the gentler ground carry briefly after landing.


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
	glide_reversal_active = false # A Pounce takes over velocity instead of continuing a turn ramp.
	glide_speed_before_pounce = velocity.length() if gliding else 0.0
	active_pounce_speed = (
		velocity.length() * glide_pounce_speed_multiplier
		if gliding
		else pounce_speed
	)
	pounce_direction = signf(velocity.x) if gliding and absf(velocity.x) > 0.1 else direction # Follow the U-turn's real heading.
	if absf(pounce_direction) <= 0.1:
		pounce_direction = facing_direction
	gliding = pounce_started_from_glide
	pounce_timer = pounce_duration
	pounce_cooldown_timer = pounce_cooldown
	pounce_sfx.play() # Play the placeholder Pounce sound.
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
	if gliding: # Detect a Swipe used to cancel Glide.
		_begin_glide_exit() # Preserve Glide momentum after the Swipe.
	if down_is_dominant:
		# The downward version keeps a brief vertical stutter for aiming, but it
		# does not erase horizontal travel. Lateral Swipes preserve all momentum.
		velocity.y *= tail_swipe_down_stutter_vertical_retention
	tail_swipe_timer = tail_swipe_duration
	tail_swipe_cooldown_timer = tail_swipe_cooldown
	tail_swipe_sfx.play() # Play the placeholder Tail Swipe sound.
	_play_sprite_feedback(tail_swipe_scale, tail_swipe_duration)


func _apply_tail_swipe(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * tail_swipe_gravity_multiplier * delta


func is_tail_swiping() -> bool:
	return tail_swipe_timer > 0.0


func _update_tail_swipe_hitbox() -> void: # Select the matching Tail Swipe presentation.
	var active := is_tail_swiping()
	var downward_active := active and tail_swipe_direction == Vector2.DOWN
	var lateral_active := active and not downward_active
	tail_swipe_hitbox_shape.position = Vector2.ZERO # Keep the lateral shape rooted at the player.
	tail_swipe_hitbox_shape.rotation = tail_swipe_direction.angle() # Face the lateral shape left or right.
	tail_swipe_hitbox.monitoring = lateral_active # Enable only the lateral attack area.
	downward_tail_swipe_hitbox.monitoring = downward_active # Enable only the downward attack area.
	tail_swipe_indicator.points = PackedVector2Array([Vector2.ZERO, tail_swipe_direction * tail_swipe_reach]) # Point the lateral line toward the attack.
	tail_swipe_indicator.visible = lateral_active # Show only the lateral indicator.
	downward_tail_swipe_indicator.visible = downward_active # Show only the downward indicator.


func _on_pounce_hitbox_area_entered(area: Area2D) -> void:
	if not is_pouncing() or not area.has_method("receive_pounce"):
		return
	area.call("receive_pounce", self)


func _on_tail_swipe_hitbox_area_entered(area: Area2D) -> void:
	if not is_tail_swiping() or not area.has_method("receive_tail_swipe"):
		return
	area.call("receive_tail_swipe", self)


func _on_hurtbox_area_entered(area: Area2D) -> void: # Handle enemy contact through the player Hurtbox.
	if contact_invulnerability_timer > 0.0: # Ignore contact during protection.
		return # Prevent repeated damage.
	if not area.has_method("get_contact_damage"): # Accept only enemy damage areas.
		return # Ignore unrelated areas.
	var damage := int(area.call("get_contact_damage"))
	_take_contact_damage(damage, area.global_position) # Apply enemy contact damage.


func _take_contact_damage(damage: int, hit_position: Vector2) -> void: # Apply the prototype damage response.
	if damage <= 0: # Reject harmless contacts.
		return # Keep the current state.
	current_health = maxi(current_health - damage, 0) # Reduce health without going negative.
	contact_invulnerability_timer = contact_invulnerability_time # Start brief protection.
	gliding = false # End Glide on a damaging impact.
	glide_exit_active = false # Let knockback replace carried momentum.
	var knockback_direction := signf(global_position.x - hit_position.x)
	if is_zero_approx(knockback_direction): # Resolve centered contact.
		knockback_direction = -facing_direction # Push opposite the facing direction.
	velocity = Vector2(knockback_direction * contact_knockback.x, contact_knockback.y) # Apply visible knockback.
	hurt_sfx.play() # Play the placeholder player-hurt sound.
	_play_damage_feedback() # Flash the player sprite.


func _play_damage_feedback() -> void: # Show temporary damage feedback.
	if damage_tween and damage_tween.is_valid(): # Check for an older flash.
		damage_tween.kill() # Stop the older flash.
	visuals.modulate = damage_flash_color # Tint the player immediately.
	damage_tween = create_tween() # Create the recovery animation.
	damage_tween.tween_property(visuals, "modulate", Color.WHITE, damage_flash_time) # Restore the normal color.


func rebound_from_tail_swipe(hit_position: Vector2) -> void: # Apply the matching enemy-hit response.
	if tail_swipe_direction == Vector2.DOWN: # Check for the downward attack.
		velocity.y = minf(velocity.y, -tail_swipe_down_bounce_speed) # Bounce upward from the enemy.
	else: # Handle a lateral enemy hit.
		var recoil_direction := signf(global_position.x - hit_position.x)
		if is_zero_approx(recoil_direction): # Resolve a centered hit.
			recoil_direction = -tail_swipe_direction.x # Recoil opposite the attack.
		var retained_speed := absf(velocity.x) * tail_swipe_lateral_hit_momentum_retention
		velocity.x = recoil_direction * maxf(tail_swipe_lateral_recoil_speed, retained_speed) # Redirect retained momentum away from the enemy.

	tail_swipe_timer = 0.0 # End the attack after one enemy hit.
	tail_swipe_hitbox.set_deferred("monitoring", false) # Disable the lateral hitbox safely.
	downward_tail_swipe_hitbox.set_deferred("monitoring", false) # Disable the downward hitbox safely.


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
	glide_reversal_active = false # Rebound momentum is earned speed, not a fresh reversal.
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
	run_sprite.flip_h = facing_direction > 0.0 # Face the running sheet toward movement.
	lateral_tail_swipe_sprite.flip_h = facing_direction > 0.0 # Face the lateral strike toward its target.
	downward_tail_swipe_sprite.flip_h = facing_direction > 0.0 # Match the downward strike to player facing.


func _update_sprite_state() -> void: # Select and advance the current player artwork.
	var tail_swiping := is_tail_swiping()
	var downward_swiping := tail_swiping and tail_swipe_direction == Vector2.DOWN
	var lateral_swiping := tail_swiping and not downward_swiping
	var running := is_on_floor() and absf(velocity.x) > 10.0 and not tail_swiping and not is_pouncing()
	sprite.visible = not gliding and not running and not tail_swiping # Show idle and ordinary airborne artwork.
	glide_sprite.visible = gliding and not tail_swiping # Show Glide artwork only during Glide.
	run_sprite.visible = running # Show the running sheet during grounded movement.
	lateral_tail_swipe_sprite.visible = lateral_swiping # Show the lateral strike sheet for forward attacks.
	downward_tail_swipe_sprite.visible = downward_swiping # Show the front-flip sheet for downward attacks.
	run_sprite.frame = int(Time.get_ticks_msec() * run_animation_fps / 1000.0) % 2 # Loop the two running frames.
	var run_frame_offset := run_frame_zero_offset if run_sprite.frame == 0 else run_frame_one_offset
	run_sprite.position = Vector2(run_frame_offset.x * -facing_direction, 1.0 + run_frame_offset.y) # Stabilize the run-cycle anchor in either direction.
	var tail_progress := 1.0 - tail_swipe_timer / maxf(tail_swipe_duration, 0.001)
	var tail_frame := mini(int(tail_progress * 2.0), 1)
	lateral_tail_swipe_sprite.frame = tail_frame # Advance the lateral strike once per attack.
	downward_tail_swipe_sprite.frame = tail_frame # Advance the downward strike once per attack.


func _try_glide_spin() -> void:
	if gliding and Input.is_action_just_pressed("glide_spin"):
		glide_roll_target += PI # Each press alternates inverted and upright.


func _reset_glide_spin() -> void:
	glide_visual_pitch = 0.0 # Clear the previous Glide's pitch.
	glide_roll_angle = 0.0 # Clear any unfinished visual roll.
	glide_roll_target = 0.0 # Start the next Glide upright.
	glide_sprite.scale.y = glide_sprite_rest_scale_y # Restore the authored sprite scale.
	visuals.rotation = 0.0 # Keep normal artwork upright.


func _update_air_rotation(delta: float) -> void:
	if not gliding:
		_reset_glide_spin() # Landing, cancelling, or colliding ends the inverted pose.
		return

	var target_pitch := glide_pitch * facing_direction
	var rotation_weight := clampf(air_rotation_speed * delta, 0.0, 1.0)
	glide_visual_pitch = lerpf(glide_visual_pitch, target_pitch, rotation_weight) # Smooth steering independently of the roll.
	var roll_step := PI * delta / maxf(glide_spin_duration, 0.01)
	glide_roll_angle = move_toward(glide_roll_angle, glide_roll_target, roll_step) # Rotate through the half-turn.
	glide_sprite.scale.y = glide_sprite_rest_scale_y * cos(glide_roll_angle) # Invert the art while its head stays forward.
	visuals.rotation = glide_visual_pitch # Leave the collision body unaffected.


func _handle_landing_feedback(was_on_floor: bool, fall_speed: float) -> void:
	var just_landed := not was_on_floor and is_on_floor()
	if not just_landed or fall_speed < minimum_squash_speed:
		return

	land_sfx.play() # Play the placeholder landing sound.
	_play_sprite_feedback(landing_squash_scale, landing_recovery_time)


func _play_sprite_feedback(start_scale: Vector2, recovery_time: float) -> void:
	if feedback_tween and feedback_tween.is_valid():
		feedback_tween.kill()

	visuals.scale = visuals_rest_scale * start_scale
	feedback_tween = create_tween()
	feedback_tween.tween_property(visuals, "scale", visuals_rest_scale, recovery_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
