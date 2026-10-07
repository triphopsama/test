# Données du plan de Pierrefane (monde/republique/pierrefane.md, monde/cartes/pierrefane.md).
# x vers l'est, y vers le sud, en mètres. 1 case = 1 m. La mer est à l'ouest, l'anse au milieu.
import math, heapq

LIEUX = [
# id, nom, type, x, y, hauteur(m), habitants, horaires, acces, cache, terrain
("place","Place du port","village",470,470,4,"—","toujours","libre","Le marché aux poissons du matin","Pavés, étals (couvert), filets qui sèchent"),
("port","Le quai et le Goéland gris","village",330,440,1,"Capitaine Daunel, Yann, Kael","toujours","libre","Le Goéland gris part tous les 6 jours vers Saltevaux","Quai de pierre, caisses (couvert), eau profonde au bord"),
("lanternes","Maison des Lanternes","métier",360,560,3,"Madame Orsoline, Hugues, Margo, Lysa, Bastien","18 h – 4 h","Hugues à la porte ; la cave fermée à clé","Le carnet d'Orsoline ; la cave des captifs punis","Salon (couvert), escalier (hauteur), lanterne rouge"),
("auberge","Au Mouillage (auberge)","métier",520,400,5,"Ondine, Pâris, Fleur","6 h – 23 h","libre aux heures d'ouverture","Les ragots d'Ondine ; l'arrière-salle des dés","Tables et bancs (couvert), cheminée (feu)"),
("entrepot","Épicerie-entrepôt Daunel","métier",410,360,3,"Bérénice, Ambroise, Yann","7 h – 19 h","libre aux heures d'ouverture","Le dossier secret de Bérénice","Caisses et tonneaux (couvert)"),
("chantier","Chantier naval","métier",330,250,2,"Maître Ferrat, Thorga","6 h – 18 h","libre","La forge d'ancres de Thorga ; une coque à moitié finie","Coque (hauteur +2), poutres (couvert), forge (feu)"),
("chapelle","Petite chapelle des Sept Astres","sacré",600,300,12,"Sœur Odile","toujours ouverte","libre","Les messages des Libres sous l'autel","Lieu sacré (lumière ×1,2)"),
("prevot","Maison du prévôt","maison",600,500,8,"Prévôt Gourdin","9 h – 12 h, en principe","porte fermée la nuit","L'enveloppe d'Orsoline, chaque mois","Bureau (couvert)"),
("plage","Plage aux coquillages","côte",430,660,0,"—","toujours","libre","Les coquillages de Fleur","Sable (déplacement -1), eau peu profonde"),
("jetee","Bout de la jetée","côte",230,470,0,"—","toujours","libre","Là où Kael mange seul, à midi","Pierres glissantes, eau profonde des deux côtés"),
("hangar","Hangar à bateaux du Passeur","maison",250,110,1,"Gilles le Passeur","jour : il dort ; nuit : en mer","porte cadenassée","Les barques des fugitifs vers Aëlinde","Barques (couvert), eau profonde"),
("lande","La lande","landes",800,330,36,"—","toujours","libre","Le chemin de nuit de Kael","Bruyère, vent, aucun couvert"),
("mahaut","Cabane de Mahaut","maison",880,170,44,"Vieille Mahaut","à toute heure si on vient la chercher","la porte n'est jamais fermée","Les noms des enfants vendus","Herbes sèches (brûlent)"),
("sentier","Sentier côtier (vers Brumeval)","route",960,720,14,"—","toujours","libre","Brumeval à 16 km, 3 h de marche","Lande, vent, falaises basses"),
]

CHEMINS = [
("place","port",1.1,""),("place","auberge",1.1,""),("place","lanternes",1.15,""),("place","prevot",1.1,""),
("place","entrepot",1.15,""),("entrepot","chantier",1.15,""),("entrepot","port",1.15,""),("chantier","hangar",1.3,"le long des rochers"),
("port","jetee",1.05,""),("lanternes","plage",1.15,""),("plage","port",1.2,""),("auberge","chapelle",1.15,""),
("chapelle","lande",1.2,""),("lande","mahaut",1.2,""),("lande","sentier",1.25,""),("prevot","sentier",1.25,""),
]

MARCHE = 1.5
COURSE = 4.0
L = {l[0]: l for l in LIEUX}


def d(a, b):
    A, B = L[a], L[b]
    return math.hypot(A[3] - B[3], A[4] - B[4])


def graphe(maree_basse=True):
    g = {k: [] for k in L}
    for a, b, f, c in CHEMINS:
        if not maree_basse and "marée basse" in c:
            continue
        w = d(a, b) * f
        g[a].append((b, w))
        g[b].append((a, w))
    return g


def dist(a, b, maree_basse=False):
    g = graphe(maree_basse)
    best = {a: 0}
    q = [(0, a)]
    while q:
        w, n = heapq.heappop(q)
        if n == b:
            return w
        if w > best.get(n, 1e18):
            continue
        for m, x in g[n]:
            if w + x < best.get(m, 1e18):
                best[m] = w + x
                heapq.heappush(q, (w + x, m))
    return None


def minutes(m, v):
    return m / v / 60


# Zones (polygones en mètres). La côte : la terre, de la mer (ouest) au bord est de la carte.
COTE = [(320, 0), (300, 80), (240, 100), (220, 180), (290, 230), (280, 330), (300, 400), (210, 440), (200, 500),
        (300, 520), (320, 600), (380, 680), (470, 700), (520, 760), (560, 800), (1100, 800), (1100, 0)]
LANDES = [(700, 120), (1100, 80), (1100, 560), (880, 600), (700, 420)]
BOIS = []
RUISSEAU = []
