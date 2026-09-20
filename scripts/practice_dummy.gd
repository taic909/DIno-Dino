extends Area2D

@export_category("Impact Feedback")
@export_range(0.01, 0.12, 0.005, "suffix:s") var hit_pause_duration := 0.055
@export var stun_duration := 0.8
@export var stun_color := Color(1.0, 0.9, 0.35, 1.0)

@export_category("Tail Swipe")
@export var tail_swipe_health := 2
@export var tail_swipe_damage := 1
@export var stunned_tail_swipe_damage := 2
@export var tail_swipe_hit_color := Color(1.0, 0.55, 0.35, 1.0)
@export var contact_damage := 1

@onready var visuals: Node2D = $Visuals
@onready var stun_burst: CPUParticles2D = $StunBurst
@onready var stun_sfx: AudioStreamPlayer2D = $StunSfx
@onready var hit_sfx: AudioStreamPlayer2D = $HitSfx
@onready var defeat_sfx: AudioStreamPlayer2D = $DefeatSfx

var stunned := false
var stun_sequence := 0
var health := 0
var defeated := false
var hit_pause_active := false
var time_scale_before_hit_pause := 1.0
var stun_tween: Tween


func _ready() -> void:
	health = tail_swipe_health


func receive_pounce(player: CharacterBody2D) -> void:
	if defeated:
		return
	if not player.has_method("is_pouncing"):
		return
	if not bool(player.call("is_pouncing")):
		return

	player.call("rebound_from_pounce", global_position)
	stun_sfx.play() # Play the placeholder enemy-stun sound.
	await _play_hit_pause()
	stun_burst.restart()
	stun_burst.emitting = true
	_play_stun_feedback()


func receive_tail_swipe(player: CharacterBody2D) -> void:
	if defeated or not player.has_method("is_tail_swiping"):
		return
	if not bool(player.call("is_tail_swiping")):
		return

	if player.has_method("rebound_from_tail_swipe"):
		player.call("rebound_from_tail_swipe", global_position)

	var damage := stunned_tail_swipe_damage if stunned else tail_swipe_damage
	health -= damage
	if health <= 0:
		await _defeat()
	else:
		hit_sfx.play() # Play the placeholder enemy-hit sound.
		await _play_hit_pause()
		_play_tail_swipe_feedback()


func _play_hit_pause() -> void:
	time_scale_before_hit_pause = Engine.time_scale
	hit_pause_active = true
	Engine.time_scale = 0.0
	await get_tree().create_timer(hit_pause_duration, true, false, true).timeout
	Engine.time_scale = time_scale_before_hit_pause
	hit_pause_active = false


func _play_stun_feedback() -> void:
	stun_sequence += 1
	var current_sequence := stun_sequence
	stunned = true
	if stun_tween and stun_tween.is_valid():
		stun_tween.kill()

	visuals.scale = Vector2(1.2, 0.72)
	visuals.modulate = stun_color
	stun_tween = create_tween().set_parallel()
	stun_tween.tween_property(visuals, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	stun_tween.tween_property(visuals, "rotation", deg_to_rad(8.0), 0.08).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(stun_duration).timeout
	if current_sequence != stun_sequence:
		return

	stunned = false
	stun_tween = create_tween().set_parallel()
	stun_tween.tween_property(visuals, "modulate", Color.WHITE, 0.16)
	stun_tween.tween_property(visuals, "rotation", 0.0, 0.16)


func _play_tail_swipe_feedback() -> void:
	if stun_tween and stun_tween.is_valid():
		stun_tween.kill()

	visuals.scale = Vector2(0.82, 1.12)
	visuals.modulate = tail_swipe_hit_color
	stun_tween = create_tween().set_parallel()
	stun_tween.tween_property(visuals, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	stun_tween.tween_property(visuals, "modulate", Color.WHITE, 0.14)


func _defeat() -> void:
	defeated = true
	defeat_sfx.play() # Play the placeholder enemy-defeat sound.
	stun_sequence += 1
	set_deferred("monitorable", false)
	if stun_tween and stun_tween.is_valid():
		stun_tween.kill()

	await _play_hit_pause()
	stun_burst.restart()
	stun_burst.emitting = true
	visuals.visible = false
	await get_tree().create_timer(stun_burst.lifetime).timeout
	queue_free()


func is_stunned() -> bool:
	return stunned


func get_contact_damage() -> int: # Report damage to a touching player Hurtbox.
	return contact_damage # Return this enemy's contact damage.


func _exit_tree() -> void:
	if hit_pause_active:
		Engine.time_scale = time_scale_before_hit_pause
