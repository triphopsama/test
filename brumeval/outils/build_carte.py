"""Construit les données d'une carte à partir de son module de plan.

Usage : python3 outils/build_carte.py pierrefane PIE
Lit outils/<carte>_data.py et écrit data/<carte>/lieux.csv, chemins.csv, zones.csv
(Brumeval garde son outil historique, build.py, et ses fichiers à la racine de data/).
"""
import csv, importlib, os, sys

carte, prefixe = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
D = importlib.import_module(f"{carte}_data")
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", carte)
os.makedirs(out, exist_ok=True)
num = {l[0]: i for i, l in enumerate(D.LIEUX, 1)}
with open(f"{out}/lieux.csv", "w", encoding="utf-8", newline="") as fh:
    w = csv.writer(fh, delimiter=";")
    w.writerow(["id", "cle", "numero", "nom", "type", "x", "y", "hauteur", "habitants", "horaires", "acces", "cache", "terrain_combat", "relie_a"])
    for l in D.LIEUX:
        rel = sorted({b for a, b, f, c in D.CHEMINS if a == l[0]} | {a for a, b, f, c in D.CHEMINS if b == l[0]})
        w.writerow([f"{prefixe}_L%02d" % num[l[0]], l[0], num[l[0]], *l[1:11], ",".join(f"{prefixe}_L%02d" % num[r] for r in rel)])
with open(f"{out}/chemins.csv", "w", encoding="utf-8", newline="") as fh:
    w = csv.writer(fh, delimiter=";")
    w.writerow(["de", "a", "distance_m", "marche_min", "course_min", "condition"])
    for a, b, f, c in D.CHEMINS:
        m = D.d(a, b) * f
        w.writerow([f"{prefixe}_L%02d" % num[a], f"{prefixe}_L%02d" % num[b], round(m), round(D.minutes(m, D.MARCHE), 1), round(D.minutes(m, D.COURSE), 1), c or "—"])
with open(f"{out}/zones.csv", "w", encoding="utf-8", newline="") as fh:
    w = csv.writer(fh, delimiter=";")
    w.writerow(["zone", "ordre", "x", "y"])
    for nom, pts in (("cote", D.COTE), ("landes", D.LANDES), ("bois", D.BOIS), ("ruisseau", D.RUISSEAU)):
        for i, (x, y) in enumerate(pts):
            w.writerow([nom, i, x, y])
print(f"{len(D.LIEUX)} lieux, {len(D.CHEMINS)} chemins écrits dans data/{carte}/")
