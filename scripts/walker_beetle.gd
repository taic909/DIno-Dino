extends Area2D # Use the existing enemy hurtbox and player-contact layer.

const STEP_PROBE_CLEARANCE := 2.0

@export_category("Patrol")
@export var walk_speed := 65.0
@export var patrol_half_width := 145.0
@export var starting_direction := -1.0
@export var walkable_step_height := 48.0
@export var chase_speed := 100.0
@export var chase_stop_distance := 28.0

@export_category("Combat")
@export var max_health := 2
@export var contact_damage := 1
@export var stun_duration := 0.8
@export var stun_color := Color(1.0, 0.9, 0.35, 1.0)
@export var hit_color := Color(1.0, 0.55, 0.35, 1.0)
@export var hit_flash_duration := 0.14

@onready var visuals: Node2D = $Visuals
@onready var hurtbox_shape: CollisionShape2D = $HurtboxShape
@onready var floor_probe: RayCast2D = $FloorProbe
@onready var wall_probe: RayCast2D = $WallProbe
@onready var defeat_burst: CPUParticles2D = $DefeatBurst
@onready var stun_sfx: AudioStreamPlayer2D = $StunSfx
@onready var hit_sfx: AudioStreamPlayer2D = $HitSfx
@onready var defeat_sfx: AudioStreamPlayer2D = $DefeatSfx

var health := 0
var direction := -1.0
var patrol_center_x := 0.0
var stunned := false
var stun_timer := 0.0
var hit_flash_timer := 0.0
var walk_phase := 0.0
var defeated := false
var target_player: CharacterBody2D


func _ready() -> void: # Record the placed position as the patrol center.
	health = max_health
	direction = -1.0 if starting_direction < 0.0 else 1.0
	patrol_center_x = global_position.x
	_aim_probes() # Point ground and wall checks toward travel.
	visuals.scale.x = direction # Face the beetle's head forward.


func _physics_process(delta: float) -> void: # Walk only while the beetle is active.
	if defeated: # Stop moving after defeat.
		return
	if stunned: # A Pounce gives the player a safe opening.
		stun_timer = maxf(stun_timer - delta, 0.0)
		if stun_timer <= 0.0: # Resume patrol after the stun.
			stunned = false
			visuals.modulate = Color.WHITE
		return
	if hit_flash_timer > 0.0: # End the Tail Swipe flash naturally.
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		if hit_flash_timer <= 0.0: # Restore shell colors after a hit.
			visuals.modulate = Color.WHITE
	var chasing := is_instance_valid(target_player) # Targeting begins only after a valid player hit.
	if chasing:
		var distance_to_player := target_player.global_position.x - global_position.x
		if absf(distance_to_player) <= chase_stop_distance:
			return # Stay near the player without jittering back and forth.
		var desired_direction := signf(distance_to_player)
		if direction != desired_direction:
			direction = desired_direction # Turn toward the player instead of following the old patrol route.
			visuals.scale.x = direction # Keep the beetle's head aimed at its target.
			_aim_probes() # Move the wall and ledge checks to the new leading side.
	floor_probe.force_raycast_update() # Check for ground in front of the feet.
	wall_probe.force_raycast_update() # Check for a wall in front of the head.
	var past_patrol_limit := absf(global_position.x - patrol_center_x) >= patrol_half_width and signf(global_position.x - patrol_center_x) == direction
	if _wall_ahead() or not _ground_ahead():
		if not chasing:
			_turn_around() # Patrol reverses at real walls and ledges.
		return # Pursuit waits rather than trying to walk through blocked terrain.
	if not chasing and past_patrol_limit:
		_turn_around() # Keep the original patrol bounds before the beetle is attacked.
		return
	var movement_speed := chase_speed if chasing else walk_speed
	global_position.x += direction * movement_speed * delta # Pursue faster after a hit; otherwise keep the normal patrol.
	walk_phase += delta * 11.0 # Drive a subtle placeholder walk bob.
	visuals.position.y = sin(walk_phase) * 1.5 # Keep the hitbox steady while the shell moves.


func _aim_probes() -> void: # Keep environmental checks on the leading side.
	var body_rectangle := hurtbox_shape.shape as RectangleShape2D
	var feet_y := hurtbox_shape.position.y + body_rectangle.size.y * 0.5
	var probe_y := feet_y - walkable_step_height - STEP_PROBE_CLEARANCE
	floor_probe.position.x = direction * 47.0
	floor_probe.position.y = probe_y # Begin above small rises so the floor ray can find their top.
	floor_probe.target_position.y = 70.0 - probe_y # Keep the original floor-search depth below the body.
	wall_probe.position.x = direction * 46.0
	wall_probe.position.y = probe_y # A low step no longer looks like a full wall.
	wall_probe.target_position.x = direction * 20.0


func _turn_around() -> void: # Reverse patrol direction without leaving the ledge.
	direction *= -1.0
	visuals.scale.x = direction
	_aim_probes()


func _ground_ahead() -> bool: # Probe the floor without treating the player as terrain.
	var collider := floor_probe.get_collider() as CollisionObject2D
	if collider != null and collider.is_in_group("player"): # Skip a player standing over the floor.
		floor_probe.add_exception(collider) # Keep this player out of future ground checks.
		floor_probe.force_raycast_update() # Recheck for the real floor below them.
	return floor_probe.is_colliding() # Stop at an actual ledge.


func _wall_ahead() -> bool: # Ignore the player when deciding whether to turn.
	var collider := wall_probe.get_collider() as CollisionObject2D
	if collider != null and collider.is_in_group("player"): # Continue toward a player in the path.
		wall_probe.add_exception(collider) # Keep this player out of future wall checks.
		wall_probe.force_raycast_update() # Check for actual scenery behind them.
	return wall_probe.is_colliding() # Turn only for a wall.


func receive_pounce(player: CharacterBody2D) -> void: # Stun and rebound a real Pounce hit.
	if defeated or not player.has_method("is_pouncing"): # Ignore invalid or late hits.
		return
	if not bool(player.call("is_pouncing")): # Require an active Pounce.
		return
	target_player = player # Remember who struck the beetle before the Pounce rebound.
	player.call("rebound_from_pounce", global_position) # Give the player the usual momentum rebound.
	stunned = true
	stun_timer = stun_duration
	hit_flash_timer = 0.0
	visuals.modulate = stun_color
	stun_sfx.play() # Signal the brief attack opening.


func receive_tail_swipe(player: CharacterBody2D) -> void: # Take ordinary or stun-bonus Swipe damage.
	if defeated or not player.has_method("is_tail_swiping"): # Ignore inactive hits.
		return
	if not bool(player.call("is_tail_swiping")): # Require an active Tail Swipe.
		return
	target_player = player # A nonlethal Swipe also triggers pursuit.
	player.call("rebound_from_tail_swipe", global_position) # Reuse the player's directional recoil.
	health -= 2 if stunned else 1
	if health <= 0: # Defeat the beetle after enough hits.
		_defeat()
		return
	visuals.modulate = hit_color
	hit_flash_timer = hit_flash_duration
	hit_sfx.play() # Confirm a nonlethal hit.


func get_contact_damage() -> int: # Let the player Hurtbox read this enemy's damage.
	return 0 if defeated or stunned else contact_damage # Stunned beetles are harmless.


func _defeat() -> void: # Show a short burst, then remove the enemy.
	defeated = true
	set_deferred("monitorable", false) # Stop further attack and contact events.
	visuals.visible = false
	defeat_burst.restart() # Make the defeat visible even with placeholder art.
	defeat_burst.emitting = true
	defeat_sfx.play() # Play the existing temporary defeat sound.
	_finish_defeat() # Delay removal long enough for feedback.


func _finish_defeat() -> void: # Keep the burst and sound alive briefly.
	await get_tree().create_timer(defeat_burst.lifetime).timeout
	queue_free() # Remove the defeated enemy from the room.
