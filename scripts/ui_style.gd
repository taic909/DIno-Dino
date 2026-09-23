extends RefCounted
class_name UiStyle

const INK := Color("183234")
const FOREST := Color("244c46")
const CREAM := Color("fff7e7")
const PAPER := Color("f2e8d2")
const BLUE := Color("1659ce")
const RED := Color("e84936")
const MOSS := Color("8bb76a")
const MUTED := Color("9db9aa")


static func panel(fill: Color, border: Color = CREAM, radius: int = 20, width: int = 3) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 15
	box.content_margin_right = 15
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


static func button(control: BaseButton, accent: Color = BLUE, compact: bool = false) -> void:
	control.add_theme_stylebox_override("normal", panel(CREAM, INK, 13, 2))
	control.add_theme_stylebox_override("hover", panel(MOSS, INK, 13, 2))
	control.add_theme_stylebox_override("pressed", panel(accent, CREAM, 13, 2))
	control.add_theme_stylebox_override("focus", panel(Color.TRANSPARENT, RED, 13, 3))
	control.add_theme_stylebox_override("disabled", panel(PAPER, MUTED, 13, 2))
	control.add_theme_color_override("font_color", INK)
	control.add_theme_color_override("font_hover_color", INK)
	control.add_theme_color_override("font_pressed_color", CREAM)
	control.add_theme_color_override("font_focus_color", INK)
	control.add_theme_color_override("font_disabled_color", FOREST)
	control.add_theme_font_size_override("font_size", 15 if compact else 18)
	if control is Button:
		(control as Button).alignment = HORIZONTAL_ALIGNMENT_CENTER


static func label(control: Label, color: Color = CREAM, size: int = 16) -> void:
	control.add_theme_color_override("font_color", color)
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_shadow_color", Color(INK, 0.25))
	control.add_theme_constant_override("shadow_offset_x", 1)
	control.add_theme_constant_override("shadow_offset_y", 2)


static func style_tree(root: Node) -> void:
	for child: Node in root.get_children():
		if child is BaseButton:
			button(child as BaseButton)
		elif child is Label:
			label(child as Label)
		style_tree(child)
