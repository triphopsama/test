"""Dessine le plan d'une carte (touche Tab en jeu) à partir de son module de plan.

Usage : python3 outils/image_carte.py pierrefane "Pierrefane"
Écrit images/plan_<carte>.png (Brumeval garde son outil historique, image.py).
"""
import importlib, os, sys
from PIL import Image, ImageDraw, ImageFont

carte, titre = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
D = importlib.import_module(f"{carte}_data")
S = 1.6
W, H = int(max(x for x, y in D.COTE) * S), int(max(y for x, y in D.COTE) * S)
img = Image.new("RGB", (W, H), (64, 112, 160))
dr = ImageDraw.Draw(img)
F = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
f = ImageFont.truetype(F, 15); fb = ImageFont.truetype(FB, 16); ft = ImageFont.truetype(FB, 28); fs = ImageFont.truetype(F, 12)
P = lambda x, y: (x * S, y * S)
dr.polygon([P(*p) for p in D.COTE], fill=(132, 168, 96))
if D.LANDES:
    dr.polygon([P(*p) for p in D.LANDES], fill=(150, 140, 110))
if D.BOIS:
    dr.polygon([P(*p) for p in D.BOIS], fill=(52, 96, 58))
for a, b, fac, c in D.CHEMINS:
    A, B = D.L[a], D.L[b]
    dr.line([P(A[3], A[4]), P(B[3], B[4])], fill=(225, 205, 160), width=6)
couleurs = {"maison": (170, 90, 60), "métier": (190, 120, 60), "village": (220, 200, 140), "sacré": (235, 235, 250),
            "côte": (230, 220, 170), "landes": (120, 110, 80), "route": (225, 205, 160), "bois": (30, 60, 35)}
for i, l in enumerate(D.LIEUX, 1):
    x, y = P(l[3], l[4]); c = couleurs.get(l[2], (200, 200, 200)); r = 9
    if l[2] in ("maison", "métier", "sacré"):
        dr.rectangle([x - r, y - r, x + r, y + r], fill=c, outline=(30, 30, 30))
    else:
        dr.ellipse([x - r, y - r, x + r, y + r], fill=c, outline=(30, 30, 30))
    t = str(i); tw = dr.textlength(t, font=fs); dr.text((x - tw / 2, y - 8), t, font=fs, fill=(0, 0, 0))
    nom = l[1].split(" (")[0]
    dr.text((x + 13, y - 9), nom, font=f, fill=(15, 15, 15), stroke_width=2, stroke_fill=(245, 240, 225))
dr.text((20, 14), titre, font=ft, fill=(255, 255, 255), stroke_width=2, stroke_fill=(30, 40, 60))
dr.text((20, 52), "MER", font=fb, fill=(220, 235, 255))
x0, y0 = W - 300, H - 40
dr.line([x0, y0, x0 + 100 * S, y0], fill=(0, 0, 0), width=3); dr.text((x0, y0 - 20), "100 m · 1 min à pied", font=f, fill=(0, 0, 0))
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "images", f"plan_{carte}.png")
img.save(out)
print(img.size, "->", os.path.relpath(out))
