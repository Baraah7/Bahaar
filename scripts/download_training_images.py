"""
Download diverse training images for Red Mullet and Shrimp to fix
classifier under-confidence on real-world photos.

Usage:
    python scripts/download_training_images.py

Images are saved to assets/data/extra_training/<ClassName>/
"""

import io
import time
from pathlib import Path

import requests
from ddgs import DDGS
from PIL import Image

OUTPUT_ROOT = Path("assets/data/extra_training")
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    )
}

# Targeted queries covering the visual styles the model currently fails on:
# - Red Mullet: food/plate context, market displays, multiple fish per frame
# - Shrimp: raw/grey/uncooked bulk — NOT cooked pink shrimp
DOWNLOAD_PLAN = {
    "Red Mullet": [
        ("red mullet fish plate food", 15),
        ("red mullet fish market fresh", 15),
        ("red mullet fish raw whole", 15),
        ("mullus barbatus fish fresh", 15),
    ],
    "Shrimp": [
        ("raw shrimp grey uncooked fresh", 15),
        ("fresh shrimp bulk ice market", 15),
        ("raw prawns grey translucent seafood", 15),
        ("uncooked shrimp whole fresh seafood", 15),
    ],
}


def download_image(url: str, dest: Path) -> bool:
    try:
        resp = requests.get(url, headers=HEADERS, timeout=10)
        if resp.status_code != 200:
            return False
        img = Image.open(io.BytesIO(resp.content))
        if img.width < 150 or img.height < 150:
            return False
        img.convert("RGB").save(dest, "JPEG", quality=92)
        return True
    except Exception:
        return False


def download(label: str, queries: list[tuple[str, int]]) -> None:
    out_dir = OUTPUT_ROOT / label
    out_dir.mkdir(parents=True, exist_ok=True)
    index = len(list(out_dir.glob("*.jpg")))
    print(f"\n>>> {label} — existing: {index} images")

    for query, count in queries:
        print(f"    '{query}' — searching...", end=" ", flush=True)
        try:
            results = list(DDGS().images(query, max_results=count))
        except Exception as e:
            print(f"search failed: {e}")
            continue

        print(f"{len(results)} found — downloading...", end=" ", flush=True)
        saved = 0
        for r in results:
            url = r.get("image", "")
            if not url:
                continue
            dest = out_dir / f"{index:04d}.jpg"
            if download_image(url, dest):
                index += 1
                saved += 1
            time.sleep(0.05)
        print(f"{saved} saved")

    total = len(list(out_dir.glob("*.jpg")))
    print(f"    Total: {total} images in {out_dir}")


def main() -> None:
    print("Downloading extra training images for Red Mullet and Shrimp...")
    for label, queries in DOWNLOAD_PLAN.items():
        download(label, queries)
    print(f"\nDone. Images saved to: {OUTPUT_ROOT.resolve()}")


if __name__ == "__main__":
    main()
