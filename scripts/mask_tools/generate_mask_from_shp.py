"""
Generate navigation mask from bahrain_territorial_12nm_mobile.shp.

Reads the shapefile, rasterizes the water polygon into a binary grid,
and writes the result to assets/navigation/ replacing the existing mask.

Usage:
    python generate_mask_from_shp.py

Requirements:
    pip install geopandas shapely numpy rasterio
"""

import json
import struct
import numpy as np
from pathlib import Path

# ── Paths ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR   = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent.parent   # lib/widgets/map/mask → lib/widgets/map → lib/widgets → lib → Bahaar
SHP_PATH     = PROJECT_ROOT / "bahrain_territorial_12nm_mobile.shp"
OUT_DIR      = PROJECT_ROOT / "assets" / "navigation"
OUT_BIN      = OUT_DIR / "bahrain_navigation_mask.bin"
OUT_META     = OUT_DIR / "mask_metadata.json"

RESOLUTION = 0.001   # degrees per cell
PAD        = 0.01    # padding around shapefile bounds (degrees)

print(f"[INFO] SHP  : {SHP_PATH}")
print(f"[INFO] Output BIN : {OUT_BIN}")
print(f"[INFO] Output META: {OUT_META}")


def read_shapefile_geometry():
    """Return a Shapely geometry from the .shp file."""
    import os
    import geopandas as gpd
    from shapely.ops import unary_union

    # Allow fiona/GDAL to reconstruct the missing .shx index on-the-fly
    os.environ["SHAPE_RESTORE_SHX"] = "YES"

    gdf = gpd.read_file(str(SHP_PATH))
    geom = unary_union(gdf.geometry)
    bounds = gdf.total_bounds  # (minX, minY, maxX, maxY)
    print(f"[INFO] Loaded {len(gdf)} feature(s), type={geom.geom_type}")
    print(f"[INFO] SHP bounds: lon [{bounds[0]:.4f}, {bounds[2]:.4f}]  "
          f"lat [{bounds[1]:.4f}, {bounds[3]:.4f}]")
    return geom, bounds


def make_bbox(shp_bounds) -> dict:
    """Derive a snapped grid bbox from the shapefile bounds + padding."""
    min_lon = round(shp_bounds[0] - PAD, 3)
    min_lat = round(shp_bounds[1] - PAD, 3)
    max_lon = round(shp_bounds[2] + PAD, 3)
    max_lat = round(shp_bounds[3] + PAD, 3)
    return {"min_lon": min_lon, "min_lat": min_lat,
            "max_lon": max_lon, "max_lat": max_lat}


def rasterize_geometry(geom, bbox: dict) -> np.ndarray:
    """
    Rasterize a Shapely geometry into a height x width uint8 grid.
    Cells INSIDE the polygon  → 1 (water / navigable)
    Cells OUTSIDE the polygon → 0 (land / blocked)
    Row 0 = max_lat (top), matching the Dart NavigationMask convention.
    """
    width  = round((bbox["max_lon"] - bbox["min_lon"]) / RESOLUTION)
    height = round((bbox["max_lat"] - bbox["min_lat"]) / RESOLUTION)
    print(f"[INFO] Grid size: {width} x {height}  ({width*height:,} cells)")

    from rasterio.transform import from_bounds
    from rasterio.features import rasterize as rio_rasterize
    from shapely.geometry import mapping

    transform = from_bounds(
        bbox["min_lon"], bbox["min_lat"],
        bbox["max_lon"], bbox["max_lat"],
        width, height,
    )

    grid = rio_rasterize(
        [(mapping(geom), 1)],
        out_shape=(height, width),
        transform=transform,
        fill=0,
        dtype=np.uint8,
    )
    # rasterio row 0 = top (max_lat) — matches Dart: row = (maxLat - lat) / res
    print(f"[INFO] Rasterized  water cells={grid.sum():,}")
    return grid


def write_bin(grid: np.ndarray, path: Path):
    path.write_bytes(grid.astype(np.uint8).tobytes())
    print(f"[OK] Written {path}  ({path.stat().st_size:,} bytes)")


def write_metadata(path: Path, bbox: dict, grid: np.ndarray):
    height, width = grid.shape
    meta = {
        "bbox": bbox,
        "grid": {
            "width": width,
            "height": height,
            "resolution_degrees": RESOLUTION,
            "resolution_meters_approx": 111.0,
        },
        "projection": "EPSG:4326",
        "encoding": {"water": 1, "land": 0},
        "territorial_waters": "12 nautical miles (22,224 meters)",
        "source": "bahrain_territorial_12nm_mobile.shp",
    }
    path.write_text(json.dumps(meta, indent=2))
    print(f"[OK] Written {path}")


if __name__ == "__main__":
    if not SHP_PATH.exists():
        raise FileNotFoundError(f"Shapefile not found: {SHP_PATH}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    geom, shp_bounds = read_shapefile_geometry()
    bbox  = make_bbox(shp_bounds)
    print(f"[INFO] Grid bbox: lon [{bbox['min_lon']}, {bbox['max_lon']}]  "
          f"lat [{bbox['min_lat']}, {bbox['max_lat']}]")

    grid  = rasterize_geometry(geom, bbox)
    write_bin(grid, OUT_BIN)
    write_metadata(OUT_META, bbox, grid)

    water_pct = grid.sum() / grid.size * 100
    print(f"\n[DONE] {water_pct:.1f}% of cells are water (navigable).")
    print("assets/navigation/bahrain_navigation_mask.bin replaced successfully.")
