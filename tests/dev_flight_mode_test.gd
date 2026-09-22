extends Node2D # Verify the replacement developer flight controls.

@onready var player: CharacterBody2D = $Main/Player
@onready var dev_mode: CanvasLayer = $Main/DevMode
@onready var flight_button: CheckButton = $Main/DevMode/Overlay/Margin/Content/FlightModeButton
@onready var pause_menu: CanvasLayer = $Main/PauseMenu


func _ready() -> void:
	call_deferred("_run") # Wait until the player and menus are connected.


func _run() -> void:
	player.set_physics_process(false) # Let the test control individual movement steps.
	dev_mode.call("_open_dev_mode") # Open the controller-navigable dev menu.
	if not _check(get_viewport().gui_get_focus_owner() == flight_button, "Flight Mode did not receive menu focus."):
		return
	flight_button.button_pressed = true # Activate the same signal used by controller A / Cross.
	if not _check(bool(player.get("dev_flight_mode")) and player.velocity == Vector2.ZERO, "Flight did not engage and stop momentum."):
		return
	dev_mode.call("_close_dev_mode") # Resume gameplay with flight still enabled.
	Input.action_press("move_right")
	Input.action_press("glide_dive") # The existing up action supplies vertical flight input.
	player.call("_apply_dev_flight") # Compute one free-flight movement step.
	var flight_speed := float(player.get("dev_flight_speed"))
	if not _check(player.velocity.x > 0.0 and player.velocity.y < 0.0 and player.velocity.length() <= flight_speed + 0.01, "Diagonal flight direction or speed is wrong."):
		return
	Input.action_release("move_right")
	Input.action_release("glide_dive")
	player.call("_apply_dev_flight") # Released controls must halt immediately in midair.
	if not _check(player.velocity == Vector2.ZERO, "Flight did not hover when controls were released."):
		return
	var binding_buttons: Dictionary = pause_menu.get("binding_buttons")
	if not _check(binding_buttons.has("dev_toggle_flight:controller"), "Flight shortcut is missing from controller rebinding."):
		return
	var flight_press := InputEventJoypadButton.new()
	flight_press.device = 0
	flight_press.button_index = JOY_BUTTON_X
	flight_press.pressed = true
	player.set_physics_process(true) # Let the real controller shortcut be handled by normal gameplay.
	Input.parse_input_event(flight_press) # Exercise the default X / Square shortcut through the input map.
	await get_tree().process_frame # Let the input queue dispatch before the physics tick.
	await get_tree().physics_frame # Let the queued controller event reach gameplay.
	await get_tree().physics_frame # Observe the player after its movement callback.
	player.set_physics_process(false) # Return to deterministic direct checks.
	var flight_release := flight_press.duplicate() as InputEventJoypadButton
	flight_release.pressed = false
	Input.parse_input_event(flight_release) # Leave the shortcut released for later tests.
	if not _check(not bool(player.get("dev_flight_mode")) and not flight_button.button_pressed, "Flight shortcut did not turn off or sync the menu."):
		return
	player.velocity = Vector2.ZERO
	player.set("coyote_timer", 0.0)
	player.set("jump_buffer_timer", 0.1)
	player.call("_handle_jump") # Ordinary airborne jumps must be restored after flight.
	if not _check(player.velocity == Vector2.ZERO, "Normal airborne jump rules did not return."):
		return
	print("PASS: developer flight, hover, shortcut, and controller binding") # Report the regression check.
	get_tree().quit() # Exit after successful assertions.


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true # Continue when the behavior matches.
	push_error(message) # Explain which flight behavior failed.
	get_tree().paused = false # Let the failing test exit cleanly.
	get_tree().quit(1) # Return a failing command-line status.
	return false # Stop dependent assertions.
