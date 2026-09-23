extends Area2D # Use the existing enemy hurtbox and player-contact layer.

@export_category("Flight Patrol")
## Horizontal patrol speed in pixels per second.
@export var flight_speed := 225.0
## Initial travel direction: negative is left and positive is right.
@export var starting_direction := -1.0
## Maximum vertical distance from the dragonfly's placed height.
@export var bob_amplitude := 12.0
## Speed of the dragonfly's main up-and-down cycle.
@export var bob_speed := 2.4
## Adds a smaller second wave so the flight path feels less mechanical.
@export var flutter_amplitude := 3.0
## True when the authored artwork points left before runtime mirroring.
@export var art_faces_left := false
## Distance moved away from a wall during the turn frame to prevent repeated detection.
@export var wall_turn_clearance := 8.0

@export_category("Combat")
## Damage points the dragonfly can take before defeat.
@export var max_health := 2
## Health points removed when the dragonfly touches the player.
@export var contact_damage := 1
## Seconds the dragonfly remains stunned after a Pounce.
@export var stun_duration := 0.8
## Dragonfly tint while stunned.
@export var stun_color := Color(1.0, 0.9, 0.35, 1.0)
## Dragonfly tint after a nonlethal Tail Swipe.
@export var hit_color := Color(1.0, 0.55, 0.35, 1.0)
## Seconds the nonlethal hit tint remains visible.
@export var hit_flash_duration := 0.14

@onready var visuals: Node2D = $Visuals
@onready var wall_probe: RayCast2D = $WallProbe
@onready var defeat_burst: CPUParticles2D = $DefeatBurst
@onready var stun_sfx: AudioStreamPlayer2D = $StunSfx
@onready var hit_sfx: AudioStreamPlayer2D = $HitSfx
@onready var defeat_sfx: AudioStreamPlayer2D = $DefeatSfx

var health := 0
var direction := -1.0
var flight_height := 0.0
var bob_phase := 0.0
var visual_scale_x := 1.0
var stunned := false
var stun_timer := 0.0
var hit_flash_timer := 0.0
var defeated := false


func _ready() -> void: # Record the placed height and prepare the first patrol direction.
	health = max_health
	direction = -1.0 if starting_direction < 0.0 else 1.0
	flight_height = global_position.y
	bob_phase = randf() * TAU # Desync multiple dragonflies placed in one room.
	visual_scale_x = absf(visuals.scale.x)
	_update_facing() # Point the artwork toward its initial travel direction.
	_aim_wall_probe() # Point the terrain check toward the leading side.


func _physics_process(delta: float) -> void: # Patrol horizontally while layering a living flight bob over the path.
	if defeated: # Stop moving after defeat.
		return
	if stunned: # A Pounce gives the player a safe opening.
		stun_timer = maxf(stun_timer - delta, 0.0)
		if stun_timer <= 0.0: # Resume flight after the stun.
			stunned = false
			visuals.modulate = Color.WHITE
		return
	_update_hit_flash(delta) # Restore normal colors after a nonlethal hit.
	wall_probe.force_raycast_update() # Read the wall immediately before moving this frame.
	if _wall_ahead(): # Reverse before the body enters solid terrain.
		_turn_around()
	global_position.x += direction * flight_speed * delta # Fly steadily toward the current leading side.
	bob_phase += delta * bob_speed # Advance both vertical wave components together.
	var primary_bob := sin(bob_phase) * bob_amplitude
	var secondary_flutter := sin(bob_phase * 2.3 + 0.8) * flutter_amplitude
	global_position.y = flight_height + primary_bob + secondary_flutter # Combine slow drift with a smaller wing-like flutter.


func _update_hit_flash(delta: float) -> void: # End the Tail Swipe flash naturally.
	if hit_flash_timer <= 0.0: # Skip work when no flash is active.
		return
	hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
	if hit_flash_timer <= 0.0: # Restore the dragonfly colors after a hit.
		visuals.modulate = Color.WHITE


func _wall_ahead() -> bool: # Detect solid scenery without treating the player as a wall.
	var collider := wall_probe.get_collider() as CollisionObject2D
	if collider != null and collider.is_in_group("player"): # Let the dragonfly continue through the player's path.
		wall_probe.add_exception(collider) # Keep this player out of later wall checks.
		wall_probe.force_raycast_update() # Recheck for actual terrain behind the player.
	return wall_probe.is_colliding() # Turn only when scenery blocks the flight path.


func _turn_around() -> void: # Reverse horizontal travel at a wall.
	direction *= -1.0
	_update_facing() # Mirror the artwork with the new direction.
	_aim_wall_probe() # Move the terrain check to the new leading side.
	global_position.x += direction * wall_turn_clearance # Clear the wall immediately so the ray cannot retrigger there.
	wall_probe.force_raycast_update() # Refresh the ray after moving and turning in the same frame.


func _update_facing() -> void: # Preserve the scene's authored scale while mirroring its direction.
	var facing_sign := -direction if art_faces_left else direction
	visuals.scale.x = visual_scale_x * facing_sign


func _aim_wall_probe() -> void: # Point the ray toward the direction of flight.
	wall_probe.target_position.x = absf(wall_probe.target_position.x) * direction


func receive_pounce(player: CharacterBody2D) -> void: # Stun and rebound a real Pounce hit.
	if defeated or not player.has_method("is_pouncing"): # Ignore invalid or late hits.
		return
	if not bool(player.call("is_pouncing")): # Require an active Pounce.
		return
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
	player.call("rebound_from_tail_swipe", global_position) # Reuse the player's directional recoil.
	health -= 2 if stunned else 1
	if health <= 0: # Defeat the dragonfly after enough hits.
		_defeat()
		return
	visuals.modulate = hit_color
	hit_flash_timer = hit_flash_duration
	hit_sfx.play() # Confirm a nonlethal hit.


func get_contact_damage() -> int: # Let the player Hurtbox read this enemy's damage.
	return 0 if defeated or stunned else contact_damage # Stunned dragonflies are harmless.


func _defeat() -> void: # Show a short burst, then remove the enemy.
	defeated = true
	set_deferred("monitorable", false) # Stop further attack and contact events.
	visuals.visible = false
	defeat_burst.restart() # Make the defeat visible even with temporary effects.
	defeat_burst.emitting = true
	defeat_sfx.play() # Play the existing temporary defeat sound.
	_finish_defeat() # Delay removal long enough for feedback.


func _finish_defeat() -> void: # Keep the burst and sound alive briefly.
	await get_tree().create_timer(defeat_burst.lifetime).timeout
	queue_free() # Remove the defeated enemy from the room.
