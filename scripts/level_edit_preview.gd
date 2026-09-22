@tool
extends Node2D

const LAYER_DEPTHS: Array[int] = [-8, 0, 2, 8]
const SAVE_VERSION := 1

@export_file("*.tscn") var room_scene_path := ""
@export var save_directory := "res://level_edits"
@export var refresh_interval := 1.0

var refresh_timer := 0.0
var loaded_hash := ""


func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = false # Gameplay uses the level editor's own runtime TileMapLayers.
		set_process(false) # Avoid duplicate artwork or collision at runtime.
		return
	call_deferred("reload_preview") # Let the edited room finish entering the editor scene tree.


func _process(delta: float) -> void:
	refresh_timer -= delta
	if refresh_timer > 0.0:
		return # Check only once per interval while the 2D editor is open.
	refresh_timer = refresh_interval
	var save_path := _save_path()
	var current_hash := FileAccess.get_md5(save_path) if FileAccess.file_exists(save_path) else ""
	if current_hash != loaded_hash:
		reload_preview() # Show newly painted tiles after the game writes its save file.


func reload_preview() -> void:
	for child: Node in get_children():
		child.free() # Replace only preview-owned children, never authored room tiles.
	var save_path := _save_path()
	loaded_hash = FileAccess.get_md5(save_path) if FileAccess.file_exists(save_path) else ""
	if loaded_hash.is_empty():
		return # A new room has no painted overlay to preview.
	var save_file := FileAccess.open(save_path, FileAccess.READ)
	if save_file == null:
		return # Leave the edited room intact when its JSON cannot be read.
	var parsed: Variant = JSON.parse_string(save_file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("version", -1)) != SAVE_VERSION or str(parsed.get("room", "")) != room_scene_path:
		return # Do not display data belonging to another room.
	for layer_data: Variant in parsed.get("layers", []):
		if layer_data is Dictionary:
			_add_preview_layer(layer_data) # Reconstruct each saved visual role.


func _add_preview_layer(layer_data: Dictionary) -> void:
	var layer_kind := int(layer_data.get("kind", -1))
	var resource_path := str(layer_data.get("tileset", ""))
	if layer_kind < 0 or layer_kind >= LAYER_DEPTHS.size() or not resource_path.begins_with("res://assets/tilemaps/"):
		return # Reject unknown roles and resources outside the project's tile art.
	if not ResourceLoader.exists(resource_path, "TileSet"):
		return # Missing TileSets should not break the editor canvas.
	var layer := TileMapLayer.new()
	layer.name = "PreviewLayer_%d" % get_child_count()
	layer.tile_set = load(resource_path) as TileSet
	layer.z_index = LAYER_DEPTHS[layer_kind]
	layer.collision_enabled = layer_kind == 1 # Match runtime terrain physics without altering source layers.
	add_child(layer) # Keep preview nodes unowned so they do not save into the room .tscn.
	for cell_data: Variant in layer_data.get("cells", []):
		if not cell_data is Dictionary:
			continue # Ignore malformed saved cells.
		var cell := Vector2i(int(cell_data.get("x", 0)), int(cell_data.get("y", 0)))
		var atlas_coords := Vector2i(int(cell_data.get("atlas_x", -1)), int(cell_data.get("atlas_y", -1)))
		var source_id := int(cell_data.get("source", -1))
		if not layer.tile_set.has_source(source_id):
			continue # Do not pass unknown source IDs to TileMapLayer.
		var atlas := layer.tile_set.get_source(source_id) as TileSetAtlasSource
		if atlas != null and atlas.has_tile(atlas_coords):
			layer.set_cell(cell, source_id, atlas_coords, int(cell_data.get("alternative", 0))) # Draw a validated saved tile in Godot's 2D view.


func _save_path() -> String:
	if room_scene_path.is_empty():
		return "" # An unassigned preview cannot identify a room.
	return save_directory.path_join(room_scene_path.md5_text() + ".json") # Match the live editor's per-room filename.
