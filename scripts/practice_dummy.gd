extends Area2D

@export_category("Impact Feedback")
@export_range(0.01, 0.12, 0.005, "suffix:s") var hit_pause_duration := 0.055
@export var stun_duration := 0.8
@export var stun_color := Color(1.0, 0.9, 0.35, 1.0)

@onready var visuals: Node2D = $Visuals
@onready var stun_burst: CPUParticles2D = $StunBurst

var stunned := false
var stun_sequence := 0
var hit_pause_active := false
var time_scale_before_hit_pause := 1.0
var stun_tween: Tween


func receive_pounce(player: CharacterBody2D) -> void:
	if not player.has_method("is_pouncing"):
		return
	if not bool(player.call("is_pouncing")):
		return

	player.call("rebound_from_pounce", global_position)
	await _play_hit_pause()
	stun_burst.restart()
	stun_burst.emitting = true
	_play_stun_feedback()


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


func is_stunned() -> bool:
	return stunned


func _exit_tree() -> void:
	if hit_pause_active:
		Engine.time_scale = time_scale_before_hit_pause
