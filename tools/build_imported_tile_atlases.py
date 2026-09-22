"""Extract the user's loose art sheets into aligned 128 px Godot atlases.

Run with the bundled Python that has Pillow and NumPy. The originals are never
modified. Run once with --dry-run to inspect extraction counts, then normally.
"""

import argparse
import json
import math
import re
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
TILE_ROOT = ROOT / "assets" / "tilemaps"
OUT_ROOT = TILE_ROOT / "converted"
CELL = 128
ATLAS_COLUMNS = 16
SCALE = 0.25

BIOMES = {
    "mossy": [
        ("Mossy Tileset", "Mossy - TileSet.png", "Solid terrain", True),
        ("Mossy Tileset", "Mossy - FloatingPlatforms.png", "Floating platforms", True),
        ("Mossy Tileset", "Mossy - MossyHills.png", "Hills", False),
        ("Mossy Tileset", "Mossy - Decorations&Hazards.png", "Decorations and hazards", False),
        ("Mossy Tileset", "Mossy - Hanging Plants.png", "Hanging plants", False),
        ("Mossy Tileset", "Mossy - BackgroundDecoration.png", "Background decoration", False),
    ],
    "cave": [
        ("Assets 1024 Cave", "Cave - Platforms.png", "Solid platforms", True),
        ("Assets 1024 Cave", "Cave - Floor.png", "Floor pieces", True),
        ("Assets 1024 Cave", "Cave - BigRocks1.png", "Big rocks", False),
        ("Assets 1024 Cave", "Cave - SmallRocks.png", "Small rocks", False),
        ("Assets 1024 Cave", "Cave - RockCombinations1.png", "Rock combinations", False),
        ("Assets 1024 Cave", "Square - Black.jpg", "Black background", False),
    ],
}


def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")


def extract_components(image: Image.Image) -> list[tuple[tuple[int, int, int, int], Image.Image, int]]:
    """Find 8-connected alpha regions by row runs, then return isolated sprites."""
    pixels = np.asarray(image.convert("RGBA"))
    mask = pixels[:, :, 3] > 12
    parent: list[int] = []
    rank: list[int] = []
    segments: list[tuple[int, int, int, int]] = []

    def find(index: int) -> int:
        while parent[index] != index:
            parent[index] = parent[parent[index]]
            index = parent[index]
        return index

    def union(a: int, b: int) -> None:
        a, b = find(a), find(b)
        if a == b:
            return
        if rank[a] < rank[b]:
            a, b = b, a
        parent[b] = a
        if rank[a] == rank[b]:
            rank[a] += 1

    previous: list[tuple[int, int, int]] = []
    for y, row in enumerate(mask):
        active = np.flatnonzero(row)
        if len(active) == 0:
            previous = []
            continue
        gaps = np.flatnonzero(np.diff(active) > 1)
        starts = np.r_[active[0], active[gaps + 1]]
        ends = np.r_[active[gaps] + 1, active[-1] + 1]
        current = []
        prior = 0
        for start, end in zip(starts, ends):
            start, end = int(start), int(end)
            index = len(parent)
            parent.append(index)
            rank.append(0)
            segments.append((y, start, end, index))
            current.append((start, end, index))
            while prior < len(previous) and previous[prior][1] < start - 1:
                prior += 1
            compare = prior
            while compare < len(previous) and previous[compare][0] <= end:
                union(index, previous[compare][2])
                compare += 1
        previous = current

    groups: dict[int, list[tuple[int, int, int]]] = {}
    for y, start, end, index in segments:
        groups.setdefault(find(index), []).append((y, start, end))

    sprites = []
    for runs in groups.values():
        area = sum(end - start for _, start, end in runs)
        left = min(start for _, start, _ in runs)
        right = max(end for _, _, end in runs)
        top = runs[0][0]
        bottom = runs[-1][0] + 1
        if area < 24 or right - left < 4 or bottom - top < 4:
            continue
        crop = pixels[top:bottom, left:right].copy()
        own_alpha = np.zeros((bottom - top, right - left), dtype=bool)
        for y, start, end in runs:
            own_alpha[y - top, start - left : end - left] = True
        crop[:, :, 3] = np.where(own_alpha, crop[:, :, 3], 0)
        sprites.append(((left, top, right, bottom), Image.fromarray(crop, "RGBA"), area))
    sprites.sort(key=lambda item: (item[0][1], item[0][0]))
    return sprites


def pack_atlas(sprites: list, hanging: bool) -> tuple[Image.Image, list[dict]]:
    placements = []
    x = y = row_height = 0
    for bounds, sprite, area in sprites:
        cells_w = math.ceil((sprite.width + 8) / CELL)
        cells_h = math.ceil((sprite.height + 8) / CELL)
        if cells_w > ATLAS_COLUMNS:
            raise ValueError(f"sprite {bounds} is wider than {ATLAS_COLUMNS} cells")
        if x + cells_w > ATLAS_COLUMNS:
            x = 0
            y += row_height
            row_height = 0
        placements.append((x, y, cells_w, cells_h, sprite, bounds, area))
        x += cells_w
        row_height = max(row_height, cells_h)
    height_cells = y + row_height
    atlas = Image.new("RGBA", (ATLAS_COLUMNS * CELL, height_cells * CELL), (0, 0, 0, 0))
    tiles = []
    for cell_x, cell_y, cells_w, cells_h, sprite, bounds, area in placements:
        left = cell_x * CELL + (cells_w * CELL - sprite.width) // 2
        extra_y = 4 if hanging else cells_h * CELL - sprite.height - 4
        top = cell_y * CELL + extra_y
        atlas.alpha_composite(sprite, (left, top))
        relative_left = left - cell_x * CELL - cells_w * CELL / 2
        relative_top = top - cell_y * CELL - cells_h * CELL / 2
        tiles.append({
            "coord": [cell_x, cell_y],
            "size": [cells_w, cells_h],
            "collision": [round(relative_left + 4), round(relative_top + 4), round(relative_left + sprite.width - 4), round(relative_top + sprite.height - 4)],
            "source_bounds": list(bounds),
            "visible_pixels": area,
        })
    return atlas, tiles


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    for biome, sheets in BIOMES.items():
        manifest = {"tile_size": CELL, "scale": SCALE, "sources": []}
        biome_dir = OUT_ROOT / biome
        for source_dir, filename, display_name, collidable in sheets:
            source = TILE_ROOT / source_dir / filename
            if source.suffix.lower() == ".jpg":
                sprite = Image.open(source).convert("RGBA").resize((CELL - 8, CELL - 8), Image.Resampling.LANCZOS)
                sprites = [((0, 0, 512, 512), sprite, sprite.width * sprite.height)]
            else:
                original = Image.open(source).convert("RGBA")
                reduced = original.resize((round(original.width * SCALE), round(original.height * SCALE)), Image.Resampling.LANCZOS)
                sprites = extract_components(reduced)
            print(f"{biome}: {filename}: {len(sprites)} placeable pieces")
            if args.dry_run:
                continue
            atlas, tiles = pack_atlas(sprites, "Hanging" in display_name)
            biome_dir.mkdir(parents=True, exist_ok=True)
            atlas_path = biome_dir / f"{slug(display_name)}.png"
            atlas.save(atlas_path)
            manifest["sources"].append({
                "name": display_name,
                "texture": "res://" + atlas_path.relative_to(ROOT).as_posix(),
                "solid": collidable,
                "tiles": tiles,
            })
        if not args.dry_run:
            (biome_dir / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
