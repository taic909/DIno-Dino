extends Area2D # Use the existing enemy hurtbox and player-contact layer.

@export_category("Hover")
@export var hover_amplitude := 6.0
@export var hover_speed := 2.0

@export_category("Combat")
@export var max_health := 2
@export var contact_damage := 1
@export var stun_duration := 0.8
@export var stun_color := Color(1.0, 0.9, 0.35, 1.0)
@export var hit_color := Color(1.0, 0.55, 0.35, 1.0)
@export var hit_flash_duration := 0.14

@onready var visuals: Node2D = $Visuals
@onready var hurtbox_shape: CollisionShape2D = $HurtboxShape
@onready var defeat_burst: CPUParticles2D = $DefeatBurst
@onready var stun_sfx: AudioStreamPlayer2D = $StunSfx
@onready var hit_sfx: AudioStreamPlayer2D = $HitSfx
@onready var defeat_sfx: AudioStreamPlayer2D = $DefeatSfx

var health := 0
var home_position := Vector2.ZERO
var hover_phase := 0.0
var stunned := false
var stun_timer := 0.0
var hit_flash_timer := 0.0
var defeated := false


func _ready() -> void: # Hover around wherever this beetle was placed.
	health = max_health
	home_position = global_position
	hover_phase = randf() * TAU # Desync multiple flyers so they don't bob in unison.


func _physics_process(delta: float) -> void: # Bob gently in place; no patrol or chase.
	if defeated: # Stop moving after defeat.
		return
	if stunned: # A Pounce gives the player a safe opening.
		stun_timer = maxf(stun_timer - delta, 0.0)
		if stun_timer <= 0.0: # Resume hovering after the stun.
			stunned = false
			visuals.modulate = Color.WHITE
		return
	if hit_flash_timer > 0.0: # End the Tail Swipe flash naturally.
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		if hit_flash_timer <= 0.0: # Restore shell colors after a hit.
			visuals.modulate = Color.WHITE
	hover_phase += delta * hover_speed
	global_position = home_position + Vector2(0.0, sin(hover_phase) * hover_amplitude)


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
