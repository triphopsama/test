"""Extrait les sprites pixel et les portraits de Lyra depuis la planche de référence.

Usage : python3 tools/extract_lyra.py [planche.webp]
Produit assets/lyra/sprites/*.png (vrai pixel art, fond transparent)
et assets/lyra/portraits/*.png (portraits de dialogue).
"""
import sys
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "assets/reference/lyra_sheet.webp"
OUT_SPRITES = ROOT / "assets/lyra/sprites"
OUT_PORTRAITS = ROOT / "assets/lyra/portraits"

# Zones (x0, y0, x1, y1) dans la planche 1312x1199.
SPRITES = {
    "idle": (330, 650, 428, 800),
    "marche": (428, 650, 528, 800),
    "course": (528, 650, 630, 800),
    "saut": (630, 650, 730, 800),
    "attaque": (735, 650, 855, 800),
    "cast": (322, 870, 430, 1012),
    "hit": (430, 870, 532, 1012),
    "mort": (530, 930, 625, 1012),
}
PORTRAITS = {
    "souriante": (868, 648),
    "clin_oeil": (1011, 648),
    "colere": (1156, 648),
    "surprise": (868, 888),
    "triste": (1011, 888),
    "rougissante": (1156, 888),
}
PORTRAIT_SIZE = 140
# Taille d'un « pixel » de la planche : les sprites font ~48 px de haut en jeu.
PIXEL = 2.6
PALETTE_COLORS = 32


def remove_background(img: Image.Image, tolerance: int = 40, min_hole: int = 150) -> Image.Image:
    """Rend transparent le fond crème relié aux bords (le chemisier blanc,
    entouré d'un contour sombre, reste intact), puis les grandes poches de
    fond enfermées (ex. dans l'arc de l'attaque)."""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    bg = px[1, 1]
    seen = set()
    queue = deque((x, y) for x in range(w) for y in (0, h - 1))
    queue.extend((x, y) for y in range(h) for x in (0, w - 1))
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        seen.add((x, y))
        r, g, b, _ = px[x, y]
        if abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) > tolerance:
            continue
        px[x, y] = (0, 0, 0, 0)
        queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

    def is_bg(x: int, y: int) -> bool:
        r, g, b, a = px[x, y]
        return a > 0 and abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) <= tolerance // 2

    done = set()
    for y0 in range(h):
        for x0 in range(w):
            if (x0, y0) in done or not is_bg(x0, y0):
                continue
            region, stack = [], [(x0, y0)]
            done.add((x0, y0))
            while stack:
                x, y = stack.pop()
                region.append((x, y))
                for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= n[0] < w and 0 <= n[1] < h and n not in done and is_bg(*n):
                        done.add(n)
                        stack.append(n)
            if len(region) >= min_hole:
                for x, y in region:
                    px[x, y] = (0, 0, 0, 0)
    return img


def to_pixel_art(img: Image.Image) -> Image.Image:
    w, h = img.size
    small = img.resize((round(w / PIXEL), round(h / PIXEL)), Image.Resampling.BOX)
    # Alpha binaire + palette réduite = vrai pixel art.
    alpha = small.getchannel("A").point(lambda a: 255 if a > 140 else 0)
    rgb = small.convert("RGB").quantize(PALETTE_COLORS, method=Image.Quantize.MEDIANCUT).convert("RGB")
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out.crop(out.getbbox())


def main() -> None:
    sheet = Image.open(SRC).convert("RGB")
    OUT_SPRITES.mkdir(parents=True, exist_ok=True)
    OUT_PORTRAITS.mkdir(parents=True, exist_ok=True)
    for name, box in SPRITES.items():
        sprite = to_pixel_art(remove_background(sheet.crop(box)))
        sprite.save(OUT_SPRITES / f"{name}.png")
        print(f"sprite {name}: {sprite.size}")
    for name, (x, y) in PORTRAITS.items():
        sheet.crop((x, y, x + PORTRAIT_SIZE, y + PORTRAIT_SIZE)).save(OUT_PORTRAITS / f"{name}.png")
    print(f"{len(PORTRAITS)} portraits")


if __name__ == "__main__":
    main()
