extends Control

var room: Node2D


func _draw() -> void: # Sketch the authored terrain and the player's current position.
	var outer := Rect2(Vector2.ZERO, size)
	draw_rect(outer, Color("163d43"), true)
	for index: int in 9:
		var x := size.x * float(index + 1) / 10.0
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color("33585b"), 1.0)
	for index: int in 3:
		var y := size.y * float(index + 1) / 4.0
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("33585b"), 1.0)
	if not is_instance_valid(room):
		return
	var layer := room.get_node_or_null("Environment/Geometry/Forest") as TileMapLayer
	if not layer:
		layer = room.find_child("TerrainTiles", true, false) as TileMapLayer
	if not layer:
		_draw_player_marker(size * 0.5)
		return
	var bounds := layer.get_used_rect()
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		_draw_player_marker(size * 0.5)
		return
	var padding := Vector2(16, 14)
	var scale := minf((size.x - padding.x * 2.0) / float(bounds.size.x), (size.y - padding.y * 2.0) / float(bounds.size.y))
	var origin := (size - Vector2(bounds.size) * scale) * 0.5
	for cell: Vector2i in layer.get_used_cells():
		var pixel := origin + Vector2(cell - bounds.position) * scale
		draw_rect(Rect2(pixel, Vector2.ONE * maxf(scale, 1.0)), Color("8bb76a"), true)
	var player := room.get_node_or_null("Player") as Node2D
	if player:
		var cell := layer.local_to_map(layer.to_local(player.global_position))
		var marker := origin + Vector2(cell - bounds.position) * scale
		_draw_player_marker(marker)


func _draw_player_marker(marker: Vector2) -> void: # Keep the player's location visible in unfinished test rooms too.
	draw_circle(marker, 8.0, Color("e84936"))
	draw_arc(marker, 11.0, 0, TAU, 24, Color("fff7e7"), 2.0)
