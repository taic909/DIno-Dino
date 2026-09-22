# Paintable tile sets

Assign one of the `.tres` resources in this folder to a room's `TileMapLayer` **Tile Set** property. All four use this project's 128 × 128 grid. `Archive/` holds earlier source art and documentation; the new Stringstar and Tinyforest source files remain untouched in their own folders.

## Stringstar and Tinyforest

- `stringstar_tileset.tres`: 139 paintable 16-pixel-source cells enlarged 8×, plus three non-solid, one-click Parallax background chunks.
- `tinyforest_tileset.tres`: 269 paintable 32-pixel-source cells enlarged 4×, plus four non-solid, one-click Parallax background chunks.

The **Pixel tiles** source preserves each original sheet's grid coordinates. Paint adjacent cells to reconstruct large trees or terrain pieces; nearest-neighbor scaling keeps the pixel art crisp. The **Parallax** sources are large visual chunks suitable for a background `TileMapLayer`. If they should scroll at different speeds, use the original background PNGs with `Parallax2D` nodes instead.

Selected flat ground cells have starter collision on physics layer 1: 23 in Stringstar and 52 in Tinyforest. Trees, coins, spikes, and backgrounds have no collision. Slopes and irregular shapes remain visual-only until their polygons are tuned; spike art does not deal damage yet. Check collision shapes in-game before relying on a tile for gameplay.

To rebuild, run `tools/build_pixel_tile_atlases.py` with Python and Pillow, let Godot import the generated PNGs, then run `godot --headless --path . --script res://tools/build_imported_tilesets.gd -- stringstar tinyforest`. The manifests under `converted/stringstar/` and `converted/tinyforest/` record the original source-grid coordinates and starter collision cells.
