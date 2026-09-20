extends Area2D

@export_category("Impact Feedback")
@export_range(0.01, 0.12, 0.005, "suffix:s") var hit_pause_duration := 0.055

@onready var visuals: Node2D = $Visuals
@onready var hurtbox_shape: CollisionShape2D = $HurtboxShape
@onready var defeat_burst: CPUParticles2D = $DefeatBurst

var defeated := false
var hit_pause_active := false
var time_scale_before_hit_pause := 1.0


func receive_pounce(player: CharacterBody2D) -> void:
	if defeated or not player.has_method("is_pouncing"):
		return
	if not bool(player.call("is_pouncing")):
		return

	defeated = true
	player.call("rebound_from_pounce", global_position)
	hurtbox_shape.set_deferred("disabled", true)
	await _play_hit_pause()
	defeat_burst.emitting = true
	_play_defeat_feedback()


func _play_hit_pause() -> void:
	time_scale_before_hit_pause = Engine.time_scale
	hit_pause_active = true
	Engine.time_scale = 0.0
	await get_tree().create_timer(hit_pause_duration, true, false, true).timeout
	Engine.time_scale = time_scale_before_hit_pause
	hit_pause_active = false


func _play_defeat_feedback() -> void:
	var defeat_tween := create_tween().set_parallel()
	defeat_tween.tween_property(visuals, "scale", Vector2(1.35, 0.15), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	defeat_tween.tween_property(visuals, "modulate", Color.TRANSPARENT, 0.14)
	await defeat_tween.finished
	visuals.visible = false
	await get_tree().create_timer(0.25).timeout
	queue_free()


func _exit_tree() -> void:
	if hit_pause_active:
		Engine.time_scale = time_scale_before_hit_pause
