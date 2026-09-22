extends SceneTree

const EXPECTED := {"mossy": 70, "cave": 101}


func _initialize() -> void:
	var failed := false
	for biome in EXPECTED:
		var path := "res://assets/tilemaps/%s_tileset.tres" % biome
		var tile_set: TileSet = load(path)
		if tile_set == null:
			push_error("Could not load %s" % path)
			failed = true
			continue
		var total := 0
		if tile_set.tile_size != Vector2i(128, 128) or tile_set.get_source_count() != 6:
			push_error("%s has wrong grid size or source count" % path)
			failed = true
		var layer := TileMapLayer.new()
		layer.tile_set = tile_set
		root.add_child(layer)
		for source_index in tile_set.get_source_count():
			var source_id := tile_set.get_source_id(source_index)
			var atlas: TileSetAtlasSource = tile_set.get_source(source_id)
			if atlas == null or atlas.texture == null:
				push_error("%s source %d has no atlas texture" % [biome, source_id])
				failed = true
				continue
			var first_coord := atlas.get_tile_id(0)
			layer.set_cell(Vector2i(source_index, 0), source_id, first_coord)
			if layer.get_cell_source_id(Vector2i(source_index, 0)) != source_id:
				push_error("%s source %d cannot be painted" % [biome, source_id])
				failed = true
			var should_collide := atlas.resource_name in (["Solid terrain", "Floating platforms"] if biome == "mossy" else ["Solid platforms", "Floor pieces"])
			for tile_index in atlas.get_tiles_count():
				var coord := atlas.get_tile_id(tile_index)
				var size := atlas.get_tile_size_in_atlas(coord)
				if size.x < 1 or size.y < 1:
					push_error("%s has an invalid tile at %s" % [biome, coord])
					failed = true
				var polygon_count := atlas.get_tile_data(coord, 0).get_collision_polygons_count(0)
				if (polygon_count > 0) != should_collide:
					push_error("%s has incorrect collision on %s at %s" % [biome, atlas.resource_name, coord])
					failed = true
				total += 1
		layer.queue_free()
		if total != EXPECTED[biome]:
			push_error("%s has %d tiles, expected %d" % [biome, total, EXPECTED[biome]])
			failed = true
		else:
			print("%s TileSet loads with %d placeable blocks across 6 sources." % [biome, total])
	quit(1 if failed else 0)
