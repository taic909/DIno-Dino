# Prehistoric Placeholder Tileset

`prehistoric-vibrant-placeholder-tileset.png` is the untouched generated source image. `prehistoric-vibrant-tileset-128.png` is its normalized 1024 x 1024 working atlas, and `prehistoric_vibrant_tileset.tres` is the reusable Godot TileSet.

The atlas is arranged in four horizontal bands:

- Rows 1-2: background tiles
- Rows 3-4: normal ground tiles
- Rows 5-6: decorative tiles
- Rows 7-8: foreground tiles

The Godot resource exposes the bands as four named atlas sources: **Background**, **Solid Terrain**, **Decoration**, and **Foreground**. The working atlas crops the source's uneven gutters per tile: full-cell artwork reaches the 128-pixel edges, while props keep their proportions and are centered and bottom-aligned. Common square ground pieces and four slopes have starter collision on physics layer 1. The special cutout and valley pieces intentionally have no collision yet because their shapes need hand-tuning.

## Painting a room

1. Open a level scene and select one of its `TileMapLayer` nodes.
2. Use `BackgroundTiles` for distant scenery, `TerrainTiles` for solid ground, `DecorationTiles` for plants and fossils, and `ForegroundTiles` for artwork that should cover the player.
3. In the TileMap panel at the bottom, select the named atlas source and choose a tile.
4. Paint with the pencil tool. Right-click erases; the selection tool can copy and move painted areas.
5. Turn on **Debug > Visible Collision Shapes** while testing solid terrain, or use the project's F3 then F4 developer toggles.

The grid size is 128 x 128 pixels. Keep the original generated source image for future re-imports; paint levels with the normalized atlas and `.tres` resource.

## Mossy and cave block sets

The original art in `Mossy Tileset/` and `Assets 1024 Cave/` is preserved. Their loose pieces have been isolated, reduced to one-quarter size for this game's scale, and packed into 128-pixel-aligned atlases under `converted/`:

- `mossy_tileset.tres`: 70 placeable pieces across solid terrain, floating platforms, hills, decorations and hazards, hanging plants, and background decoration.
- `cave_tileset.tres`: 101 placeable pieces across solid platforms, floor pieces, big rocks, small rocks, rock combinations, and a black background tile.

To use either set, select a `TileMapLayer` in a room, assign the corresponding `.tres` to its **Tile Set** property, and choose a named source in the TileMap panel. Larger rocks and platforms are multi-cell tiles: select the whole piece, then click once to paint it. The solid terrain/platform/floor sources have starter rectangular collision on physics layer 1; decoration, hills, rocks, hanging plants, and backgrounds have no collision. The hazard artwork is visual only and does not deal damage yet. These are paintable atlas pieces, not seamless auto-tiling terrain sets.

To rebuild after changing the source sheets, run `tools/build_imported_tile_atlases.py` with Python and Pillow/NumPy installed, import the resulting PNGs in Godot, then run `tools/build_imported_tilesets.gd` with Godot. The `converted/*/manifest.json` files record every piece's quarter-scale source bounds and atlas position.
