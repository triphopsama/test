"""Tire data/intime.csv des profils intimes de data/pnj.csv (univers.md, « Profil intime d'un PNJ adulte »).

Usage : python3 outils/intime.py
Seuls les PNJ adultes avec un profil sont repris. Le fichier produit est un point de départ :
règle ensuite les valeurs à la main (libido, goûts, talents, limites…). Relancer l'outil écrase
le fichier, sauf les lignes dont la colonne `fige` vaut 1.
"""
import csv
import re
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
PNJ = [RACINE / "data/pnj.csv", RACINE / "data/pierrefane/pnj.csv"]
SORTIE = RACINE / "data/intime.csv"
COLONNES = ["id", "nom", "attire", "cherche", "libido", "axe", "pudeur", "experience", "bdsm", "partage",
            "jalousie", "couple", "aime", "talents", "refuse", "endurance", "bruit", "fantasme", "prefere", "ages", "fige"]

# mots du profil -> étiquettes de goûts (voir scripts/intime.gd pour la liste)
AIME = [
    (r"baiser", "baisers"), (r"mots doux", "mots_doux"), (r"tendresse|caresses|gestes tendres|gestes retenus", "tendresse"),
    (r"passion|intensit", "passion"), (r"paris coquins|jeux de pouvoir|jeux de r[ôo]le", "jeu"), (r"jeux de pouvoir", "pouvoir"),
    (r"jeux de r[ôo]le", "roleplay"), (r"lente|lents", "lenteur"), (r"rapide", "rapide"), (r"surpris|risque", "risque"),
    (r"conversation|parler|histoires d'oreiller", "conversation"), (r"dormir|matins|nuits|enlac", "nuit_entiere"),
    (r"nuque|mains fortes", "massage"), (r"cadeaux|courtis", "cadeaux"), (r"rire|rires", "rire"), (r"lutte", "jeu"),
    (r"chans|chanter", "mots_doux"), (r"compliments", "mots_doux"), (r"[ée]toiles|belle [ée]toile|nature", "dehors"),
]
REFUSE = [
    (r"t[ée]moins|regard des autres|être vu|en public|ferait jaser", "public"), (r"brutalit|grossi[èe]ret", "brutal"),
    (r"partage", "groupe"), (r"infid[ée]lit", "infidelite"), (r"moque", "moquerie"), (r"s'attacher|tendresse qui engage|mariage", "engagement"),
    (r"pitié", "pitie"), (r"pressé", "rapide"), (r"jalousie", "jalousie"), (r"vulgarit", "brutal"),
]


def valeur(texte, mot, defaut):
    m = re.search(mot + r"\s*([+-]?\d+)", texte)
    return int(m.group(1)) if m else defaut


def profil(p):
    t = p["profil_intime"]
    tl = t.lower()
    attire = []
    if "par les hommes" in tl or "et les hommes" in tl or "parfois par les hommes" in tl or "parfois les hommes" in tl:
        attire.append("hommes")
    if "par les femmes" in tl or "par les femmes" in tl or "les femmes" in tl.split("cherche")[0]:
        attire.append("femmes")
    # ce qu'il cherche : le morceau après « cherche », jusqu'à la virgule, sans ce qui suit « plus que »
    seg = tl.split("cherche", 1)[1].split(",")[0].split("plus que")[0] if "cherche" in tl else ""
    cherche = [c for c in ["amour", "plaisir", "aventure", "sécurité", "statut", "compagnie", "passion", "fidélité", "paix"] if c in seg]
    if "fidèle" in seg or "fidélité" in seg:
        cherche.append("fidélité")
    cherche = list(dict.fromkeys(cherche))
    libido = 50
    if "plaisir" in cherche or "aventure" in cherche:
        libido = 75
    if "statut" in cherche or "sécurité" in cherche:
        libido = 35
    if "paix" in cherche:
        libido = 25
    if "ne cherche plus" in tl or "désir éteint" in tl:
        libido = 15
    axe = valeur(tl, "axe", 0)
    pudeur = valeur(tl, "pudeur", 50)
    experience = "vierge" if "vierge" in tl else ("peu" if "peu expériment" in tl else "experimente")
    aime = sorted({e for motif, e in AIME if re.search(motif, tl.split("limite")[0])})
    limite = tl.split("limite", 1)[1] if "limite" in tl else ""
    refuse = sorted({e for motif, e in REFUSE if re.search(motif, limite)})
    if "pouvoir" in aime:
        aime.remove("pouvoir")
        aime.append("dominer" if axe > 0 else "etre_domine")
    bdsm = 60 if "jeux de pouvoir" in tl else max(0, abs(axe) - 40)
    partage = 70 if ("sans attache" in tl or "aventure" in cherche or "plaisir" in cherche) else 30
    jalousie = 40
    if "fidélité" in cherche:
        partage, jalousie = 10, 70
    if "infidelite" in refuse or "groupe" in refuse:
        partage, jalousie = 5, 85
    if "jalousie" in refuse:
        jalousie = 0
    if "plaisir" in cherche or "aventure" in cherche:
        jalousie = min(jalousie, 20)
    m = re.search(r"(?:en couple avec|mariée? à)[^(]*\(((?:BRU|PIE)\d+)\)", t)
    couple = m.group(1) if m else ""
    return {"id": p["id"], "nom": p["nom"], "attire": ",".join(attire), "cherche": ",".join(cherche), "libido": libido,
            "axe": axe, "pudeur": pudeur, "experience": experience, "bdsm": bdsm, "partage": partage, "jalousie": jalousie,
            "couple": couple, "aime": ",".join(aime), "talents": "", "refuse": ",".join(refuse),
            "endurance": 1 + libido // 30, "bruit": max(0, 70 - pudeur // 2),
            "fantasme": next((t for t in ["dominer", "etre_domine", "risque", "roleplay", "jeu", "dehors"] if t in aime), ""),
            "prefere": ",".join(t for motif, t in [(r"costaud", "musclee"), (r"mains fortes", "musclee"), (r"nains", "petite")] if re.search(motif, tl)),
            "ages": "", "fige": "0"}


def main():
    anciens = {}
    if SORTIE.exists():
        for l in csv.DictReader(SORTIE.open(encoding="utf-8"), delimiter=";"):
            anciens[l["id"]] = l
    lignes = []
    tous = [p for f in PNJ for p in csv.DictReader(f.open(encoding="utf-8"), delimiter=";")]
    for p in tous:
        if int(p["age"] or 0) < 18 or p["profil_intime"].strip() in ("", "—"):
            continue
        # un captif (esclave, dette) ne peut pas consentir : pas de profil tant qu'il l'est
        if re.search(r"esclave|sous contrat|captif", p["statut_social"].lower()):
            continue
        if anciens.get(p["id"], {}).get("fige") == "1":
            lignes.append(anciens[p["id"]])
        else:
            lignes.append(profil(p))
    vus = {l["id"] for l in lignes}
    lignes += [l for id_, l in anciens.items() if l.get("fige") == "1" and id_ not in vus]   # ex. Vesperine
    with SORTIE.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLONNES, delimiter=";", lineterminator="\n")
        w.writeheader()
        w.writerows(lignes)
    print(f"{len(lignes)} profils écrits dans {SORTIE.relative_to(RACINE)}")


if __name__ == "__main__":
    main()
