# Fabrique les planches 16×24 des petites bêtes (4 colonnes × 4 lignes : bas, gauche, droite, haut).
# python3 outils/betes.py  →  sprites/{rat,crabe,sanglier,araignee,slime,bete_aveugle}_planche.png
from PIL import Image

def planche(dessiner):
    im = Image.new("RGBA", (64, 96), (0, 0, 0, 0))
    for ligne, sens in enumerate(["bas", "gauche", "droite", "haut"]):
        for f in range(4):
            case = Image.new("RGBA", (16, 24), (0, 0, 0, 0))
            dessiner(case.load(), sens, f)
            im.paste(case, (f * 16, ligne * 24))
    return im

def rect(px, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < 16 and 0 <= y < 24:
                px[x, y] = c

def rat(px, sens, f):
    corps, sombre, oeil, queue = (120, 100, 90, 255), (80, 65, 60, 255), (230, 60, 60, 255), (200, 150, 150, 255)
    pas = f % 2
    if sens in ("gauche", "droite"):
        d = 1
        x0 = 3
        rect(px, x0, 17, x0 + 8, 20, corps)
        tete = x0 + 9 if d == 1 else x0 - 3
        rect(px, tete, 17, tete + 2, 19, corps)
        px[tete + (2 if d == 1 else 0), 17] = oeil
        qx = x0 - 1 if d == 1 else x0 + 9
        rect(px, qx - (2 if d == 1 else 0), 19, qx + (0 if d == 1 else 2), 19, queue)
        for i, lx in enumerate((x0 + 1, x0 + 6)):
            rect(px, lx + (pas if i == 0 else -pas), 21, lx + (pas if i == 0 else -pas), 21, sombre)
        if sens == "gauche":
            for y in range(24):
                ligne = [px[x, y] for x in range(16)]
                for x in range(16):
                    px[x, y] = ligne[15 - x]
    else:
        rect(px, 6, 15, 9, 21, corps)
        rect(px, 6, 13, 6, 14, corps); rect(px, 9, 13, 9, 14, corps)
        if sens == "bas":
            px[6, 16] = oeil; px[9, 16] = oeil
        else:
            rect(px, 7, 21, 8, 23, queue)
        rect(px, 5, 20 - pas, 5, 21, sombre); rect(px, 10, 20 - (1 - pas), 10, 21, sombre)

def crabe(px, sens, f):
    carap, sombre, pince, oeil = (150, 80, 60, 255), (95, 55, 45, 255), (190, 110, 80, 255), (20, 20, 20, 255)
    pas = f % 2
    rect(px, 3, 16, 12, 20, carap)
    rect(px, 4, 15, 11, 15, carap)
    rect(px, 3, 20, 12, 20, sombre)
    for x in (4, 6, 9, 11):
        rect(px, x, 21, x, 22 - ((x + pas) % 2), sombre)
    if sens != "haut":
        rect(px, 0, 14 + pas, 2, 16 + pas, pince); rect(px, 13, 14 + (1 - pas), 15, 16 + (1 - pas), pince)
        px[6, 14] = oeil; px[9, 14] = oeil
        rect(px, 6, 15, 6, 15, sombre); rect(px, 9, 15, 9, 15, sombre)
    else:
        rect(px, 1, 17, 2, 18, pince); rect(px, 13, 17, 14, 18, pince)

def sanglier(px, sens, f):
    poil, sombre, defense, oeil = (90, 70, 55, 255), (55, 42, 35, 255), (235, 230, 210, 255), (200, 40, 30, 255)
    pas = f % 2
    if sens in ("gauche", "droite"):
        rect(px, 2, 12, 11, 18, poil)
        rect(px, 3, 11, 9, 11, sombre)             # crête de soies
        rect(px, 12, 13, 15, 17, poil)             # hure
        px[15, 17] = defense; px[14, 16] = defense
        px[13, 14] = oeil
        for i, lx in enumerate((3, 5, 8, 10)):
            dy = pas if i % 2 == 0 else 1 - pas
            rect(px, lx, 19, lx, 21 - dy, sombre)
        if sens == "gauche":
            for y in range(24):
                ligne = [px[x, y] for x in range(16)]
                for x in range(16):
                    px[x, y] = ligne[15 - x]
    else:
        rect(px, 4, 10, 11, 19, poil)
        rect(px, 7, 9, 8, 19, sombre)
        if sens == "bas":
            rect(px, 5, 17, 10, 20, poil)
            px[5, 19] = defense; px[10, 19] = defense
            px[5, 13] = oeil; px[10, 13] = oeil
        rect(px, 4, 20, 5, 22 - pas, sombre); rect(px, 10, 20, 11, 22 - (1 - pas), sombre)

def miroir(px):
    for y in range(24):
        ligne = [px[x, y] for x in range(16)]
        for x in range(16):
            px[x, y] = ligne[15 - x]

def araignee(px, sens, f):
    corps, sombre, oeil, poil = (60, 55, 70, 255), (35, 30, 40, 255), (220, 40, 40, 255), (110, 100, 120, 255)
    pas = f % 2
    rect(px, 5, 15, 10, 19, corps)            # abdomen
    rect(px, 6, 14, 9, 14, poil)
    if sens != "haut":
        rect(px, 6, 19, 9, 21, sombre)        # tête
        px[6, 20] = oeil; px[9, 20] = oeil; px[7, 19] = oeil; px[8, 19] = oeil
    for i, y in enumerate((15, 17, 19, 21)):
        dy = pas if i % 2 == 0 else 1 - pas
        rect(px, 1, y - dy, 4, y - dy, sombre); rect(px, 0, y - dy + 1, 0, y + 1, sombre)
        rect(px, 11, y - (1 - dy), 14, y - (1 - dy), sombre); rect(px, 15, y - (1 - dy) + 1, 15, y + 1, sombre)

def slime(px, sens, f):
    gel, clair, noyau = (90, 170, 120, 200), (170, 230, 190, 220), (40, 90, 60, 255)
    gonfle = (0, 1, 2, 1)[f]
    rect(px, 3 - gonfle // 2, 17 + gonfle, 12 + gonfle // 2, 22, gel)
    rect(px, 4, 15 + gonfle, 11, 17 + gonfle, gel)
    rect(px, 5, 16 + gonfle, 6, 17 + gonfle, clair)
    rect(px, 8, 19, 9, 20, noyau)
    px[10, 21] = (150, 150, 160, 255)         # une boucle de métal à moitié digérée

def bete_aveugle(px, sens, f):
    peau, sombre, bouche, pli = (205, 190, 180, 255), (140, 120, 115, 255), (90, 30, 40, 255), (170, 150, 145, 255)
    pas = f % 2
    if sens in ("gauche", "droite"):
        rect(px, 1, 12, 13, 20, peau)
        for x in (3, 6, 9, 12):
            rect(px, x, 12, x, 20, pli)
        rect(px, 13, 14, 15, 19, peau); rect(px, 14, 16, 15, 18, bouche)
        for i, lx in enumerate((2, 5, 8, 11)):
            rect(px, lx, 21, lx, 23 - (pas if i % 2 else 1 - pas), sombre)
        if sens == "gauche":
            miroir(px)
    else:
        rect(px, 3, 9, 12, 21, peau)
        for y in (11, 14, 17):
            rect(px, 3, y, 12, y, pli)
        if sens == "bas":
            rect(px, 5, 18, 10, 21, bouche)
            for x in (5, 7, 9):
                px[x, 18] = (240, 235, 225, 255)
        rect(px, 1, 20 - pas, 2, 22, sombre); rect(px, 13, 20 - (1 - pas), 14, 22, sombre)

for nom, f in [("rat", rat), ("crabe", crabe), ("sanglier", sanglier), ("araignee", araignee), ("slime", slime), ("bete_aveugle", bete_aveugle)]:
    planche(f).save(f"sprites/{nom}_planche.png")
    print("sprites/%s_planche.png" % nom)
