"""Convert Stringstar and Tinyforest pixel sheets to 128-pixel Godot atlases.

Run with Python and Pillow. Source art is read only; generated PNGs and
manifests live under assets/tilemaps/converted/{stringstar,tinyforest}.
"""

import json
import math
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
TILE_ROOT = ROOT / "assets" / "tilemaps"
OUTPUT_ROOT = TILE_ROOT / "converted"
GAME_CELL = 128

SHEETS = {
    "stringstar": {
        "folder": "Stringstar",
        "tiles": "tileset.png",
        "cell": 16,
        "backgrounds": ["background_0.png", "background_1.png", "background_2.png"],
    },
    "tinyforest": {
        "folder": "Tinyforest",
        "tiles": "32x32WoodsItchio.png",
        "cell": 32,
        "backgrounds": ["Forest1.png", "Forest2.png", "Forest3.png", "Forest4.png"],
    },
}


def is_flat_ground(biome: str, x: int, y: int) -> bool:
    """Mark only obvious walkable strips; slopes and hazards need hand-tuning."""
    if biome == "stringstar":
        return y == 9 or (y == 4 and 5 <= x <= 9)
    flat_strips = [
        (0, 0, 2), (1, 9, 11), (1, 14, 16), (3, 7, 9),
        (5, 0, 2), (5, 10, 11), (5, 16, 17), (6, 52, 55),
        (9, 32, 40), (9, 48, 52), (10, 0, 3), (12, 24, 28),
        (17, 0, 3), (19, 7, 9), (23, 0, 3),
    ]
    return any(y == row and start <= x <= end for row, start, end in flat_strips)


def convert_grid(biome: str, source: Path, cell: int, output: Path) -> dict:
    """Retain source-grid coordinates while scaling each source pixel exactly."""
    image = Image.open(source).convert("RGBA")
    columns = math.ceil(image.width / cell)
    rows = math.ceil(image.height / cell)
    occupied = []
    for y in range(rows):
        for x in range(columns):
            tile = image.crop((x * cell, y * cell, (x + 1) * cell, (y + 1) * cell))
            bounds = tile.getchannel("A").getbbox()
            if bounds is not None:
                occupied.append((x, y, bounds))
    if not occupied:
        raise ValueError(f"No visible tiles in {source}")
    width = (max(x for x, _, _ in occupied) + 1) * cell
    height = (max(y for _, y, _ in occupied) + 1) * cell
    trimmed = image.crop((0, 0, width, height))
    scale = GAME_CELL // cell
    atlas = trimmed.resize((width * scale, height * scale), Image.Resampling.NEAREST)
    atlas.save(output)
    tiles = []
    for x, y, bounds in occupied:
        item = {"coord": [x, y], "size": [1, 1], "source_coord": [x, y]}
        if is_flat_ground(biome, x, y):
            top = max(-64, bounds[1] * scale - 64)
            item["solid"] = True
            item["collision"] = [-64, top, 64, 64]
        tiles.append(item)
    return {
        "name": "Pixel tiles (flat ground has starter collision)",
        "texture": "res://" + output.relative_to(ROOT).as_posix(),
        "solid": False,
        "tiles": tiles,
    }


def convert_background(source: Path, output: Path, cell: int, name: str) -> dict:
    """Make one placeable, non-solid chunk from each parallax image."""
    image = Image.open(source).convert("RGBA")
    scale = GAME_CELL // cell
    columns = math.ceil(image.width / cell)
    rows = math.ceil(image.height / cell)
    canvas = Image.new("RGBA", (columns * cell, rows * cell), (0, 0, 0, 0))
    canvas.alpha_composite(image)
    canvas.resize((columns * GAME_CELL, rows * GAME_CELL), Image.Resampling.NEAREST).save(output)
    return {
        "name": name,
        "texture": "res://" + output.relative_to(ROOT).as_posix(),
        "solid": False,
        "tiles": [{"coord": [0, 0], "size": [columns, rows]}],
    }


def main() -> None:
    for biome, settings in SHEETS.items():
        source_dir = TILE_ROOT / settings["folder"]
        output_dir = OUTPUT_ROOT / biome
        output_dir.mkdir(parents=True, exist_ok=True)
        tile_output = output_dir / "tiles.png"
        sources = [convert_grid(biome, source_dir / settings["tiles"], settings["cell"], tile_output)]
        for index, filename in enumerate(settings["backgrounds"]):
            background_output = output_dir / f"background_{index}.png"
            sources.append(convert_background(source_dir / filename, background_output, settings["cell"], f"Parallax {index + 1}"))
        manifest = {"tile_size": GAME_CELL, "source_cell_size": settings["cell"], "sources": sources}
        (output_dir / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
        solid_count = sum(bool(tile.get("solid")) for tile in sources[0]["tiles"])
        print(f"{biome}: {len(sources[0]['tiles'])} paintable tiles, {solid_count} starter solids, {len(sources) - 1} backgrounds")


if __name__ == "__main__":
    main()
