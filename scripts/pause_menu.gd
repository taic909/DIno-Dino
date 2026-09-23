extends CanvasLayer

const SETTINGS_PATH := "user://controls.cfg"
const CONTROLS_VERSION := 2
const KEYBOARD_DEVICE := "keyboard"
const CONTROLLER_DEVICE := "controller"
const CONTROL_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"glide_dive",
	&"glide_climb",
	&"glide_spin",
	&"jump",
	&"pounce",
	&"tail_swipe",
	&"pause",
	&"field_journal",
	&"toggle_dev_mode",
	&"dev_toggle_flight",
]
const CONTROL_LABELS: Dictionary = {
	&"move_left": "Move Left",
	&"move_right": "Move Right",
	&"glide_dive": "Glide Stick Up",
	&"glide_climb": "Glide Stick Down",
	&"glide_spin": "Glide Spin",
	&"jump": "Jump / Glide",
	&"pounce": "Pounce",
	&"tail_swipe": "Tail Swipe",
	&"pause": "Pause",
	&"field_journal": "Field Journal",
	&"toggle_dev_mode": "Dev Mode",
	&"dev_toggle_flight": "Flight Mode",
}

static var project_default_bindings: Dictionary = {}

@onready var main_panel: VBoxContainer = $Dimmer/Center/MenuPanel/Margin/MainPanel
@onready var controls_panel: VBoxContainer = $Dimmer/Center/MenuPanel/Margin/ControlsPanel
@onready var controls_rows: VBoxContainer = $Dimmer/Center/MenuPanel/Margin/ControlsPanel/ControlsScroll/ControlsRows
@onready var controls_scroll: ScrollContainer = $Dimmer/Center/MenuPanel/Margin/ControlsPanel/ControlsScroll
@onready var controls_help: Label = $Dimmer/Center/MenuPanel/Margin/ControlsPanel/ControlsHelp
@onready var resume_button: Button = $Dimmer/Center/MenuPanel/Margin/MainPanel/ResumeButton
@onready var controls_button: Button = $Dimmer/Center/MenuPanel/Margin/MainPanel/ControlsButton
@onready var controls_back_button: Button = $Dimmer/Center/MenuPanel/Margin/ControlsPanel/BackButton
@onready var reset_defaults_button: Button = $Dimmer/Center/MenuPanel/Margin/ControlsPanel/ResetDefaultsButton
@onready var menu_panel: PanelContainer = $Dimmer/Center/MenuPanel
@onready var journal_panel: VBoxContainer = $Dimmer/Center/MenuPanel/Margin/JournalPanel
@onready var journal_content: VBoxContainer = $Dimmer/Center/MenuPanel/Margin/JournalPanel/JournalBody/JournalContent
@onready var journal_body: PanelContainer = $Dimmer/Center/MenuPanel/Margin/JournalPanel/JournalBody
@onready var journal_button: Button = $Dimmer/Center/MenuPanel/Margin/MainPanel/JournalButton
@onready var inventory_tab: Button = $Dimmer/Center/MenuPanel/Margin/JournalPanel/JournalTabs/InventoryTab
@onready var map_tab: Button = $Dimmer/Center/MenuPanel/Margin/JournalPanel/JournalTabs/MapTab
@onready var codex_tab: Button = $Dimmer/Center/MenuPanel/Margin/JournalPanel/JournalTabs/CodexTab
@onready var journal_back_button: Button = $Dimmer/Center/MenuPanel/Margin/JournalPanel/JournalBackButton

var default_bindings: Dictionary = {}
var binding_buttons: Dictionary = {}
var listening_action: StringName = &""
var listening_device := ""
var is_listening := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_ensure_controller_menu_accept() # Let A / Cross activate focused menu buttons.
	_reserve_menu_back_button() # Keep B / Circle out of gameplay actions before capturing defaults.
	_capture_default_bindings()
	_load_bindings()
	if _reserve_menu_back_button():
		_save_bindings() # Migrate an older saved binding that used B for gameplay.
	_build_control_rows()
	_apply_look() # Share the expedition palette across the pause and journal screens.
	resume_button.pressed.connect(_close_menu)
	controls_button.pressed.connect(_show_controls)
	journal_button.pressed.connect(_show_journal.bind(0))
	inventory_tab.pressed.connect(_fill_journal.bind(0))
	map_tab.pressed.connect(_fill_journal.bind(1))
	codex_tab.pressed.connect(_fill_journal.bind(2))
	journal_back_button.pressed.connect(_show_main_panel)
	controls_back_button.pressed.connect(_show_main_panel)
	reset_defaults_button.pressed.connect(_reset_defaults)


func _ensure_controller_menu_accept() -> void: # Add the missing gamepad confirm action without changing keyboard UI defaults.
	var confirm_event := InputEventJoypadButton.new()
	confirm_event.device = -1 # Accept the confirm button from any connected controller.
	confirm_event.button_index = JOY_BUTTON_A # Match the familiar A / Cross menu confirm button.
	for existing_event: InputEvent in InputMap.action_get_events("ui_accept"): # Avoid duplicating an existing binding.
		if existing_event is InputEventJoypadButton and existing_event.button_index == JOY_BUTTON_A: # Keep a project-provided mapping.
			return
	InputMap.action_add_event("ui_accept", confirm_event) # Enable standard button activation on the controller.


func _reserve_menu_back_button() -> bool: # Give B / Circle only the menu Back/Cancel role.
	var bindings_changed := false
	for action: StringName in InputMap.get_actions():
		if action == &"ui_cancel":
			continue # Keep the standard menu-cancel action available.
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_B:
				InputMap.action_erase_event(action, event) # Remove old gameplay and developer B bindings.
				bindings_changed = true
	for event: InputEvent in InputMap.action_get_events("ui_cancel"):
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_B:
			return bindings_changed # Avoid adding a duplicate menu-cancel button.
	var cancel_event := InputEventJoypadButton.new()
	cancel_event.device = -1 # Let any connected controller use the Back button.
	cancel_event.button_index = JOY_BUTTON_B # Use B / Circle for menus only.
	InputMap.action_add_event("ui_cancel", cancel_event) # Make B available to pause and developer menus.
	return true # The InputMap gained its dedicated Back binding.


func _input(event: InputEvent) -> void:
	if is_listening:
		_handle_rebind_event(event)
		return
	if visible and event.is_action_pressed("ui_cancel"):
		if controls_panel.visible or journal_panel.visible:
			_show_main_panel() # Back out of controls without leaving the pause menu.
		else:
			_close_menu() # Return to gameplay from the main pause panel.
		get_viewport().set_input_as_handled() # Do not send the same Back press to gameplay.
		return

	if event.is_action_pressed("pause"):
		if visible and (controls_panel.visible or journal_panel.visible):
			_show_main_panel()
		elif visible:
			_close_menu()
		else:
			_open_menu()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("field_journal") and not event.is_echo():
		if visible and journal_panel.visible:
			_close_menu()
		elif visible:
			_show_journal(0)
		else:
			_open_menu()
			_show_journal(0)
		get_viewport().set_input_as_handled()


func _open_menu() -> void:
	visible = true
	_show_main_panel()
	get_tree().paused = true
	resume_button.grab_focus()


func _close_menu() -> void:
	_cancel_listening()
	get_tree().paused = false
	visible = false


func _show_controls() -> void:
	main_panel.visible = false
	controls_panel.visible = true
	journal_panel.visible = false
	controls_help.text = "Choose a slot, then press a new input. Delete clears it; Escape cancels."
	var first_button := binding_buttons.get(_button_key(CONTROL_ACTIONS[0], KEYBOARD_DEVICE)) as Button
	if first_button:
		first_button.grab_focus()


func _show_main_panel() -> void:
	_cancel_listening()
	controls_panel.visible = false
	journal_panel.visible = false
	main_panel.visible = true
	if visible:
		resume_button.grab_focus()


func _apply_look() -> void: # Apply one consistent palette to authored and generated menu controls.
	menu_panel.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.BLUE, UiStyle.CREAM, 24, 5))
	journal_body.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.FOREST, UiStyle.CREAM, 18, 2))
	$Dimmer/Center/MenuPanel/Margin/MainPanel/Hero.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.FOREST, UiStyle.MOSS, 18, 2))
	UiStyle.style_tree($Dimmer/Center/MenuPanel)
	UiStyle.label($Dimmer/Center/MenuPanel/Margin/MainPanel/Eyebrow, UiStyle.MOSS, 14)
	UiStyle.label($Dimmer/Center/MenuPanel/Margin/MainPanel/Hero/HeroRow/HeroWords/HeroKicker, UiStyle.MOSS, 15)
	UiStyle.label($Dimmer/Center/MenuPanel/Margin/MainPanel/Hero/HeroRow/HeroWords/HeroTitle, UiStyle.CREAM, 56)
	UiStyle.label($Dimmer/Center/MenuPanel/Margin/MainPanel/Hero/HeroRow/HeroWords/HeroSubtitle, UiStyle.CREAM, 15)
	UiStyle.label($Dimmer/Center/MenuPanel/Margin/JournalPanel/JournalTitle, UiStyle.CREAM, 38)
	UiStyle.label($Dimmer/Center/MenuPanel/Margin/JournalPanel/JournalKicker, UiStyle.MOSS, 14)
	UiStyle.button(resume_button, UiStyle.RED)
	UiStyle.button(journal_button, UiStyle.RED)


func _show_journal(tab: int) -> void: # Open the three-page field journal from pause or its own shortcut.
	main_panel.visible = false
	controls_panel.visible = false
	journal_panel.visible = true
	_fill_journal(tab)
	inventory_tab.grab_focus()


func _fill_journal(tab: int) -> void: # Populate the selected prototype page with real current-room context.
	for child: Node in journal_content.get_children():
		child.queue_free()
	var tabs: Array[Button] = [inventory_tab, map_tab, codex_tab]
	for index: int in tabs.size():
		UiStyle.button(tabs[index], UiStyle.RED if index == tab else UiStyle.BLUE, true)
		if index == tab:
			tabs[index].add_theme_stylebox_override("normal", UiStyle.panel(UiStyle.RED, UiStyle.CREAM, 13, 2))
			tabs[index].add_theme_color_override("font_color", UiStyle.CREAM)
	if tab == 0:
		_add_journal_card("CARRIED RELICS", "Your pack is empty. Future finds will appear here as the adventure grows.", UiStyle.RED)
		_add_journal_card("EXPLORER'S KIT", "Pounce and Tail Swipe are innate moves. Check Controls to see their current bindings.", UiStyle.MOSS)
	elif tab == 1:
		var room: Node = get_parent()
		var room_name := room.name.replace("_", " ")
		var player := room.get_node_or_null("Player") as Node2D
		var position_note := ""
		if player:
			position_note = "  •  X %d / Y %d" % [roundi(player.global_position.x), roundi(player.global_position.y)]
		_add_journal_card("CURRENT LOCATION", room_name + position_note, UiStyle.MOSS)
		var map := preload("res://scripts/ui_room_map.gd").new() as Control
		map.custom_minimum_size = Vector2(0, 185)
		map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		map.set("room", room)
		journal_content.add_child(map)
		_add_journal_card("TRAIL MAP", "Green marks charted terrain. Red marks your current position.", UiStyle.RED)
	else:
		_add_journal_card("01  ARCHAEOPTERYX", "A feathered explorer built for speed. Glide, dive, Pounce, and use your tail to finish a fight.", UiStyle.RED)
		_add_journal_card("02  WALKER BEETLE", "A ground patrol. A Pounce stuns it; Tail Swipe defeats it in two hits, or one while stunned.", UiStyle.MOSS)
		_add_journal_card("03  FLYER BEETLE", "A hovering threat. Time a Pounce to open a brief, safe strike window.", UiStyle.MOSS)


func _add_journal_card(heading: String, body: String, accent: Color) -> void: # Keep journal information in large, readable field cards.
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 82)
	card.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.CREAM, accent, 14, 3))
	journal_content.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var title := Label.new()
	title.text = heading
	UiStyle.label(title, UiStyle.BLUE, 20)
	column.add_child(title)
	var description := Label.new()
	description.text = body
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.label(description, UiStyle.INK, 15)
	column.add_child(description)


func _build_control_rows() -> void:
	for child: Node in controls_rows.get_children():
		child.queue_free()
	binding_buttons.clear()

	for action: StringName in CONTROL_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		controls_rows.add_child(row)

		var action_label := Label.new()
		action_label.text = str(CONTROL_LABELS[action])
		action_label.custom_minimum_size = Vector2(210.0, 40.0)
		action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(action_label)

		_add_binding_cell(row, action, KEYBOARD_DEVICE)
		_add_binding_cell(row, action, CONTROLLER_DEVICE)

	_update_binding_labels()


func _add_binding_cell(row: HBoxContainer, action: StringName, device_type: String) -> void:
	var cell := HBoxContainer.new()
	cell.add_theme_constant_override("separation", 4)
	row.add_child(cell)

	var binding_button := Button.new()
	binding_button.custom_minimum_size = Vector2(205.0, 40.0)
	binding_button.pressed.connect(_queue_listening.bind(action, device_type))
	binding_button.focus_entered.connect(_scroll_to_binding.bind(binding_button)) # Keep lower rebindable actions visible to controller users.
	cell.add_child(binding_button)
	binding_buttons[_button_key(action, device_type)] = binding_button

	var clear_button := Button.new()
	clear_button.text = "×"
	clear_button.tooltip_text = "Clear this binding slot"
	clear_button.custom_minimum_size = Vector2(38.0, 40.0)
	clear_button.pressed.connect(_clear_binding.bind(action, device_type))
	cell.add_child(clear_button)


func _scroll_to_binding(button: Button) -> void:
	controls_scroll.ensure_control_visible.call_deferred(button) # Wait for the controls panel layout before scrolling to focus.


func _queue_listening(action: StringName, device_type: String) -> void:
	call_deferred("_begin_listening", action, device_type)


func _begin_listening(action: StringName, device_type: String) -> void:
	listening_action = action
	listening_device = device_type
	is_listening = true
	controls_help.text = "Listening for %s input… Escape cancels." % device_type
	var button := binding_buttons.get(_button_key(action, device_type)) as Button
	if button:
		button.text = "Press an input…"


func _cancel_listening() -> void:
	if not is_listening:
		return
	is_listening = false
	listening_action = &""
	listening_device = ""
	_update_binding_labels()


func _handle_rebind_event(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			_cancel_listening()
			controls_help.text = "Rebinding canceled."
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_BACKSPACE, KEY_DELETE] or event.physical_keycode in [KEY_BACKSPACE, KEY_DELETE]:
			_clear_binding(listening_action, listening_device)
			get_viewport().set_input_as_handled()
			return

	if listening_device == KEYBOARD_DEVICE:
		if event is InputEventKey and event.pressed and not event.echo:
			_apply_new_binding(event)
		elif event is InputEventMouseButton and event.pressed:
			_apply_new_binding(event)
	elif listening_device == CONTROLLER_DEVICE:
		if event is InputEventJoypadButton and event.pressed:
			_apply_new_binding(event)
		elif event is InputEventJoypadMotion and absf(event.axis_value) >= 0.7:
			_apply_new_binding(event)


func _apply_new_binding(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_B:
		_cancel_listening() # Reserve B for menu Back/Cancel instead of any gameplay action.
		controls_help.text = "B / Circle is reserved for menu Back."
		get_viewport().set_input_as_handled() # Do not let this B press close the menu too.
		return
	var clean_event := event.duplicate() as InputEvent
	clean_event.device = -1

	if clean_event is InputEventKey:
		clean_event.pressed = false
		clean_event.echo = false
	elif clean_event is InputEventMouseButton:
		clean_event.pressed = false
		clean_event.button_mask = 0
	elif clean_event is InputEventJoypadButton:
		clean_event.pressed = false
		clean_event.pressure = 0.0
	elif clean_event is InputEventJoypadMotion:
		clean_event.axis_value = signf(clean_event.axis_value)

	_replace_device_bindings(listening_action, listening_device, clean_event)
	_save_bindings()
	is_listening = false
	controls_help.text = "Binding saved."
	listening_action = &""
	listening_device = ""
	_update_binding_labels()
	get_viewport().set_input_as_handled()


func _replace_device_bindings(action: StringName, device_type: String, new_event: InputEvent) -> void:
	for existing_event: InputEvent in InputMap.action_get_events(action):
		if _event_matches_device(existing_event, device_type):
			InputMap.action_erase_event(action, existing_event)
	InputMap.action_add_event(action, new_event)


func _clear_binding(action: StringName, device_type: String) -> void:
	if action == &"pause" and _count_other_device_bindings(action, device_type) == 0:
		controls_help.text = "Pause must keep at least one binding."
		_cancel_listening()
		return

	for existing_event: InputEvent in InputMap.action_get_events(action):
		if _event_matches_device(existing_event, device_type):
			InputMap.action_erase_event(action, existing_event)

	is_listening = false
	listening_action = &""
	listening_device = ""
	_save_bindings()
	controls_help.text = "Binding cleared."
	_update_binding_labels()


func _count_other_device_bindings(action: StringName, device_type: String) -> int:
	var count := 0
	for event: InputEvent in InputMap.action_get_events(action):
		if not _event_matches_device(event, device_type):
			count += 1
	return count


func _capture_default_bindings() -> void:
	if project_default_bindings.is_empty():
		for action: StringName in CONTROL_ACTIONS:
			var copies: Array[InputEvent] = []
			for event: InputEvent in InputMap.action_get_events(action):
				copies.append(event.duplicate() as InputEvent)
			project_default_bindings[action] = copies
	default_bindings = project_default_bindings


func _reset_defaults() -> void:
	for action: StringName in CONTROL_ACTIONS:
		InputMap.action_erase_events(action)
		var defaults: Array = default_bindings[action]
		for event: InputEvent in defaults:
			InputMap.action_add_event(action, event.duplicate() as InputEvent)
	_save_bindings()
	controls_help.text = "Default bindings restored."
	_update_binding_labels()


func _save_bindings(path: String = SETTINGS_PATH) -> Error:
	var config := ConfigFile.new()
	config.set_value("meta", "version", CONTROLS_VERSION)
	for action: StringName in CONTROL_ACTIONS:
		var saved_events: Array[InputEvent] = []
		for event: InputEvent in InputMap.action_get_events(action):
			saved_events.append(event.duplicate() as InputEvent)
		config.set_value("controls", String(action), saved_events)
	return config.save(path)


func _load_bindings(path: String = SETTINGS_PATH) -> Error:
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK:
		return load_error
	var saved_version := int(config.get_value("meta", "version", 1))

	for action: StringName in CONTROL_ACTIONS:
		var saved_events: Variant = config.get_value("controls", String(action), null)
		if not saved_events is Array:
			continue
		# Tail Swipe used to be deliberately empty. Keep its new defaults when
		# loading an older controls file instead of restoring that obsolete slot.
		if action == &"tail_swipe" and saved_version < CONTROLS_VERSION and saved_events.is_empty():
			continue
		InputMap.action_erase_events(action)
		for event: Variant in saved_events:
			if event is InputEvent:
				InputMap.action_add_event(action, event)
	return OK


func _update_binding_labels() -> void:
	for action: StringName in CONTROL_ACTIONS:
		for device_type: String in [KEYBOARD_DEVICE, CONTROLLER_DEVICE]:
			var button := binding_buttons.get(_button_key(action, device_type)) as Button
			if button:
				button.text = _binding_summary(action, device_type)


func _binding_summary(action: StringName, device_type: String) -> String:
	var names: PackedStringArray = []
	for event: InputEvent in InputMap.action_get_events(action):
		if _event_matches_device(event, device_type):
			names.append(_friendly_event_name(event))
	return "Unassigned" if names.is_empty() else " / ".join(names)


func _event_matches_device(event: InputEvent, device_type: String) -> bool:
	if device_type == KEYBOARD_DEVICE:
		return event is InputEventKey or event is InputEventMouseButton
	return event is InputEventJoypadButton or event is InputEventJoypadMotion


func _friendly_event_name(event: InputEvent) -> String:
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_X:
			return "Left Stick Left" if event.axis_value < 0.0 else "Left Stick Right"
		if event.axis == JOY_AXIS_LEFT_Y:
			return "Left Stick Up" if event.axis_value < 0.0 else "Left Stick Down"
		if event.axis == JOY_AXIS_TRIGGER_LEFT:
			return "LT / L2"
		if event.axis == JOY_AXIS_TRIGGER_RIGHT:
			return "RT / R2"
	if event is InputEventJoypadButton:
		var button_names := {
			JOY_BUTTON_A: "A / Cross",
			JOY_BUTTON_B: "B / Circle",
			JOY_BUTTON_X: "X / Square",
			JOY_BUTTON_Y: "Y / Triangle",
			JOY_BUTTON_BACK: "View / Create",
			JOY_BUTTON_START: "Menu / Options",
			JOY_BUTTON_LEFT_SHOULDER: "LB / L1",
			JOY_BUTTON_RIGHT_SHOULDER: "RB / R1",
			JOY_BUTTON_DPAD_LEFT: "D-pad Left",
			JOY_BUTTON_DPAD_RIGHT: "D-pad Right",
			JOY_BUTTON_DPAD_UP: "D-pad Up",
			JOY_BUTTON_DPAD_DOWN: "D-pad Down",
		}
		return str(button_names.get(event.button_index, event.as_text()))
	return event.as_text()


func _button_key(action: StringName, device_type: String) -> String:
	return "%s:%s" % [action, device_type]
