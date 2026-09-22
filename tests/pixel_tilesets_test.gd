extends SceneTree # Validate the two newly converted pixel-art TileSets.

const EXPECTED := {
	"stringstar": {"tiles": 139, "solid": 23, "sources": 4},
	"tinyforest": {"tiles": 269, "solid": 52, "sources": 5},
}


func _initialize() -> void: # Check every atlas source and terrain collision rule.
	var failed := false
	for biome: String in EXPECTED: # Verify each new resource independently.
		var path := "res://assets/tilemaps/%s_tileset.tres" % biome
		var tile_set := load(path) as TileSet
		if tile_set == null: # Report a missing or unreadable resource.
			push_error("Could not load %s" % path) # Identify the broken TileSet.
			failed = true # Return failure after checking remaining resources.
			continue # Avoid using an invalid resource.
		var expected: Dictionary = EXPECTED[biome]
		if tile_set.tile_size != Vector2i(128, 128) or tile_set.get_source_count() != expected["sources"]: # Check the project grid and all sources.
			push_error("Wrong tile size or source count in %s" % path) # Explain the resource mismatch.
			failed = true # Keep the failure visible to automation.
		var layer := TileMapLayer.new()
		layer.tile_set = tile_set # Use the resource as a real paintable layer.
		root.add_child(layer) # Make cell assignment run inside a scene tree.
		var terrain_source := tile_set.get_source(tile_set.get_source_id(0)) as TileSetAtlasSource
		var solid_count := 0
		if terrain_source.get_tiles_count() != expected["tiles"]: # Confirm every visible source cell survived conversion.
			push_error("Missing paintable cells in %s" % path) # Report incomplete art extraction.
			failed = true # Mark this conversion incomplete.
		for tile_index: int in terrain_source.get_tiles_count(): # Count starter terrain collision polygons.
			var coordinate := terrain_source.get_tile_id(tile_index)
			solid_count += terrain_source.get_tile_data(coordinate, 0).get_collision_polygons_count(0) # Read the tile's physics data.
		if solid_count != expected["solid"]: # Reject too few or too many solid cells.
			push_error("Wrong starter collision count in %s" % path) # Keep hazards from becoming terrain.
			failed = true # Mark the physics conversion incorrect.
		for source_index: int in tile_set.get_source_count(): # Check terrain and each parallax source.
			var source_id := tile_set.get_source_id(source_index)
			var atlas := tile_set.get_source(source_id) as TileSetAtlasSource
			if atlas == null or atlas.texture == null or atlas.get_tiles_count() == 0: # Reject unusable atlas sources.
				push_error("Missing atlas art in %s source %d" % [path, source_index]) # Identify the broken source.
				failed = true # Continue checking the rest.
				continue # Avoid reading a missing tile.
			var first_tile := atlas.get_tile_id(0)
			layer.set_cell(Vector2i(source_index * 20, 0), source_id, first_tile) # Paint one tile from each source.
			if layer.get_cell_source_id(Vector2i(source_index * 20, 0)) != source_id: # Verify painting retained the selected source.
				push_error("Could not paint %s source %d" % [path, source_index]) # Explain the layer failure.
				failed = true # Mark painting as broken.
			if source_index > 0: # Background chunks should never block the player.
				var background_data := atlas.get_tile_data(first_tile, 0)
				if background_data.get_collision_polygons_count(0) != 0: # Reject accidental background physics.
					push_error("Background collision in %s source %d" % [path, source_index]) # Explain the hazard.
					failed = true # Mark the source unsafe.
		layer.queue_free() # Release this temporary paint test layer.
		print("%s: %d tiles, %d starter solids, %d backgrounds" % [biome, expected["tiles"], solid_count, expected["sources"] - 1]) # Summarize the resource.
	quit(1 if failed else 0) # Return the validation result.
