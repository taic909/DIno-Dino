extends SceneTree

const TILE_SIZE := Vector2i(128, 128)
const BIOMES := ["mossy", "cave", "stringstar", "tinyforest"]


func _initialize() -> void:
	var failed := false
	var requested: PackedStringArray = OS.get_cmdline_user_args() # Allow rebuilding only the named new sets.
	var selected: PackedStringArray = requested if not requested.is_empty() else PackedStringArray(BIOMES) # Preserve the original all-sets behavior.
	for biome in selected:
		if biome not in BIOMES: # Reject a typo before trying to read a missing manifest.
			push_error("Unknown tile biome: %s" % biome) # Explain the invalid name.
			failed = true # Return a failing exit code.
			continue # Keep checking the other requested names.
		if not _build_biome(biome):
			failed = true
	quit(1 if failed else 0)


func _build_biome(biome: String) -> bool:
	var manifest_path := "res://assets/tilemaps/converted/%s/manifest.json" % biome
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if manifest.is_empty():
		push_error("Could not read %s" % manifest_path)
		return false
	var tile_set := TileSet.new()
	tile_set.tile_size = TILE_SIZE
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	var total := 0
	for source_info in manifest["sources"]:
		var texture: Texture2D = load(source_info["texture"])
		if texture == null:
			push_error("Could not load %s" % source_info["texture"])
			return false
		var atlas := TileSetAtlasSource.new()
		atlas.resource_name = source_info["name"]
		atlas.texture = texture
		atlas.texture_region_size = TILE_SIZE
		tile_set.add_source(atlas)
		for item in source_info["tiles"]:
			var coord := Vector2i(item["coord"][0], item["coord"][1])
			var size := Vector2i(item["size"][0], item["size"][1])
			atlas.create_tile(coord, size)
			if item.get("solid", source_info["solid"]): # Support mixed art and walkable cells in one atlas.
				var bounds: Array = item["collision"]
				var data := atlas.get_tile_data(coord, 0)
				data.add_collision_polygon(0)
				data.set_collision_polygon_points(0, 0, PackedVector2Array([
					Vector2(bounds[0], bounds[1]),
					Vector2(bounds[2], bounds[1]),
					Vector2(bounds[2], bounds[3]),
					Vector2(bounds[0], bounds[3]),
				]))
			total += 1
	var output := "res://assets/tilemaps/%s_tileset.tres" % biome
	var error := ResourceSaver.save(tile_set, output)
	if error != OK:
		push_error("Could not save %s: %s" % [output, error])
		return false
	print("Saved %s with %d placeable blocks." % [output, total])
	return true
