extends Node2D # Exercise pause-menu navigation using gamepad-shaped events.

@onready var menu: CanvasLayer = $Main/PauseMenu


func _ready() -> void: # Run after the scene and control rows are initialized.
	call_deferred("_run") # Avoid sending input during node startup.


func _run() -> void: # Verify D-pad selection, A activation, and the dev binding row.
	var b_cancels := false
	var b_has_other_binding := false
	for action: StringName in InputMap.get_actions(): # Inspect defaults and migrated saved bindings alike.
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_B:
				if action == &"ui_cancel":
					b_cancels = true # Require a real B menu-back binding.
				else:
					b_has_other_binding = true # Any other B binding violates the reservation.
	if not _check(b_cancels and not b_has_other_binding, "B / Circle was not reserved for menu Back only."):
		return
	var cycle_events := InputMap.action_get_events("dev_cycle_room")
	if not _check(cycle_events.size() == 1 and cycle_events[0] is InputEventJoypadButton and cycle_events[0].button_index == JOY_BUTTON_Y, "Room cycle is not bound only to Y / Triangle."):
		return
	var dev_mode := $Main/DevMode as CanvasLayer
	var room_paths: Array[String] = dev_mode.get("room_paths")
	if not _check(room_paths.size() >= 2 and int(dev_mode.call("_next_room_index", room_paths.size() - 1)) == 0, "Room cycle did not wrap from the last room to the first."):
		return
	menu.call("_open_menu") # Open through the production pause-menu path.
	await get_tree().process_frame # Let Godot apply the focus request.
	var focus_owner := get_viewport().gui_get_focus_owner()
	if not _check(focus_owner != null and focus_owner.name == "ResumeButton", "Pause did not focus Resume."): # Require visible initial focus.
		return
	var down := InputEventJoypadButton.new()
	down.device = 0
	down.button_index = JOY_BUTTON_DPAD_DOWN
	down.pressed = true
	Input.parse_input_event(down) # Send the same button shape as a real controller.
	await get_tree().process_frame # Let GUI focus navigation respond.
	focus_owner = get_viewport().gui_get_focus_owner()
	if not _check(focus_owner != null and focus_owner.name == "ControlsButton", "D-pad did not focus Controls."): # Require menu navigation.
		return
	var accept := InputEventJoypadButton.new()
	accept.device = 0
	accept.button_index = JOY_BUTTON_A
	accept.pressed = true
	Input.parse_input_event(accept) # Try to open Controls from the focused button.
	await get_tree().process_frame # Give the press its own input frame.
	var release := accept.duplicate() as InputEventJoypadButton
	release.pressed = false
	Input.parse_input_event(release) # Release to complete the button click.
	await get_tree().process_frame # Allow the button activation to run.
	if not _check(menu.get_node("Dimmer/Center/MenuPanel/Margin/ControlsPanel").visible, "A / Cross did not open Controls."): # Require gamepad activation.
		return
	var binding_buttons: Dictionary = menu.get("binding_buttons")
	if not _check(binding_buttons.has("toggle_dev_mode:keyboard") and binding_buttons.has("toggle_dev_mode:controller") and binding_buttons.has("dev_toggle_flight:controller"), "Developer controls are missing from rebinding."): # Require both dev actions.
		return
	var dev_button := binding_buttons["toggle_dev_mode:controller"] as Button
	dev_button.grab_focus() # Visit the final row with controller-style focus.
	await get_tree().process_frame # Let the scroll container follow focus.
	await get_tree().process_frame # Wait for its updated layout and scroll position.
	var controls_scroll := menu.get_node("Dimmer/Center/MenuPanel/Margin/ControlsPanel/ControlsScroll") as ScrollContainer
	if not _check(controls_scroll.scroll_vertical > 0, "Controls list did not scroll to Dev Mode."): # Keep the last row reachable.
		return
	var select_binding := InputEventJoypadButton.new()
	select_binding.device = 0
	select_binding.button_index = JOY_BUTTON_A
	select_binding.pressed = true
	Input.parse_input_event(select_binding) # Activate the focused Dev Mode controller slot.
	await get_tree().process_frame # Separate the press and release frames.
	var finish_select := select_binding.duplicate() as InputEventJoypadButton
	finish_select.pressed = false
	Input.parse_input_event(finish_select) # Complete the button click.
	await get_tree().process_frame # Let the listening request run.
	await get_tree().process_frame # Allow the deferred listener to begin.
	if not _check(bool(menu.get("is_listening")), "A / Cross did not select the Dev Mode binding slot."): # Verify controller rebinding access.
		return
	var reserved_back := InputEventJoypadButton.new()
	reserved_back.button_index = JOY_BUTTON_B
	reserved_back.pressed = true
	menu.call("_apply_new_binding", reserved_back) # Reject a B rebinding without altering saved controls.
	if not _check(not bool(menu.get("is_listening")) and not _action_has_button(&"toggle_dev_mode", JOY_BUTTON_B), "B / Circle could still be assigned to gameplay controls."):
		return
	var flight_button := binding_buttons["dev_toggle_flight:controller"] as Button
	flight_button.grab_focus() # Visit the new final controller binding row.
	await get_tree().process_frame # Let the focus scroll update.
	await get_tree().process_frame # Wait for the deferred visibility check.
	if not _check(get_viewport().gui_get_focus_owner() == flight_button and controls_scroll.scroll_vertical > 0, "Flight Mode controller binding is not visible and focusable."):
		return
	var back := InputEventJoypadButton.new()
	back.device = 0
	back.button_index = JOY_BUTTON_B
	back.pressed = true
	Input.parse_input_event(back) # Use B / Circle to back out of the Controls screen.
	await get_tree().process_frame # Let the pause menu process the back action.
	if not _check(menu.get_node("Dimmer/Center/MenuPanel/Margin/MainPanel").visible, "B / Circle did not back out of Controls."):
		return
	var back_release := back.duplicate() as InputEventJoypadButton
	back_release.pressed = false
	Input.parse_input_event(back_release) # Reset the button before using Back again.
	await get_tree().process_frame # Finish the release frame.
	Input.parse_input_event(back) # Close the pause menu with B / Circle.
	await get_tree().process_frame # Let the menu process its second back action.
	if not _check(not menu.visible, "B / Circle did not close the pause menu."):
		return
	Input.parse_input_event(back_release) # Release B before testing the developer menu.
	await get_tree().process_frame # Finish the release frame.
	dev_mode.call("_open_dev_mode") # Open the other menu with a Back action.
	Input.parse_input_event(back) # Ask B / Circle to leave developer controls.
	await get_tree().process_frame # Let unhandled menu input close the overlay.
	if not _check(not bool(dev_mode.get("enabled")), "B / Circle did not close the developer menu."):
		return
	print("PASS: Y-only room cycle, B-only menu back, and controller menu navigation") # Summarize the regression check.
	get_tree().paused = false # Restore the tree before exiting.
	get_tree().quit() # End the inspection run.


func _check(condition: bool, message: String) -> bool: # Report a failed navigation assertion.
	if condition: # Continue when the control behaved as expected.
		return true
	push_error(message) # Explain the failed check in headless output.
	get_tree().paused = false # Unpause before failing the scene.
	get_tree().quit(1) # Return a failing exit code.
	return false # Stop later checks that depend on this one.


func _action_has_button(action: StringName, button_index: int) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button_index:
			return true # Find a matching gamepad button on this action.
	return false # No binding uses the requested button.
