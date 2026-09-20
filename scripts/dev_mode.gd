extends CanvasLayer

@onready var overlay: PanelContainer = $Overlay
@onready var status_label: Label = $Overlay/Margin/Status
@onready var player: CharacterBody2D = get_parent().get_node("Player") as CharacterBody2D

var enabled := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_mode"):
		enabled = not enabled
		overlay.visible = enabled
		get_viewport().set_input_as_handled()
		return

	if enabled and not get_tree().paused and event.is_action_pressed("dev_reset_room"):
		get_tree().reload_current_scene()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not enabled or not is_instance_valid(player):
		return

	var pounce_state := "READY"
	if bool(player.call("is_pouncing")):
		pounce_state = "ACTIVE"
	elif float(player.get("pounce_cooldown_timer")) > 0.0:
		pounce_state = "COOLDOWN"

	var glide_state := "ACTIVE" if bool(player.call("is_gliding")) else "READY"
	if float(player.get("glide_time_remaining")) <= 0.0:
		glide_state = "EMPTY"
	var health_state := "%d / %d" % [int(player.get("current_health")), int(player.get("max_health"))]

	status_label.text = "DEV MODE\nF3 / Right Stick: Hide\nR / View: Reset room\nPosition: %s\nVelocity: %s\nHealth: %s\nGlide: %s (%.2fs, %.0f°, speed %.0f)\nPounce: %s" % [ # Show health with movement state.
		player.position.round(),
		player.velocity.round(),
		health_state, # Display current prototype health.
		glide_state,
		float(player.get("glide_time_remaining")),
		rad_to_deg(float(player.get("glide_pitch"))),
		float(player.get("glide_momentum")),
		pounce_state,
	]
