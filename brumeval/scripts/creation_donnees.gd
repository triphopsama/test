# Les choix de la création de personnage (monde/creation_personnage.md), en un seul endroit.
# Chaque choix : nom, texte, et ce qu'il fait (stats, points, effets).
# Les effets marqués « plus tard » sont gardés dans la fiche mais pas encore en jeu.
class_name CreationDonnees
extends RefCounted

const BASE := 5
const POINTS := 20
const MAX_DEPART := 12

const PEUPLES := {
	"humain": {"nom": "Humain", "stats": {}, "points": 3, "texte": "+3 points libres. Apprend tous les métiers 10 % plus vite. À Brumeval : un étranger de plus."},
	"elfe": {"nom": "Elfe", "stats": {"Agi": 1, "Per": 1, "Sag": 1}, "texte": "Vision de nuit, longévité. À Brumeval : curiosité, méfiance (un espion d'Aëlinde ?). Pierrick, demi-elfe, te regarde autrement."},
	"nain": {"nom": "Nain", "stats": {"For": 1, "Rob": 2, "End": 1, "Agi": -1}, "texte": "Vision dans le noir, résiste au poison. À Brumeval : bon accueil, Rosalie te traite en cousin."},
	"homme_bete": {"nom": "Homme-bête", "stats": {}, "texte": "Sens aiguisés. À Brumeval : danger, Silas y voit une marchandise."},
	"demi_sang": {"nom": "Demi-sang", "stats": {}, "texte": "Un bonus de chacun de tes deux peuples. À Brumeval : mépris discret ; Pierrick se reconnaît en toi."},
	"demon": {"nom": "Démon", "stats": {}, "texte": "Magie puissante, longévité. Commence avec Voile de chair pour cacher ses traits, mais l'illusion est fragile. Danger mortel s'il est reconnu."},
}

## La lignée, le clan ou l'animal, selon le peuple.
const LIGNEES := {
	"humain": {},
	"elfe": {
		"sylvain": {"nom": "Elfe sylvain", "stats": {}, "texte": "Nature +15 d'affinité, Pas sans trace (plus tard)."},
		"marees": {"nom": "Elfe des marées", "stats": {}, "texte": "Eau +15, respiration sous l'eau prolongée (plus tard)."},
		"lunaire": {"nom": "Elfe lunaire", "stats": {}, "texte": "Lumière +15, voit la magie la nuit (plus tard)."},
	},
	"nain": {
		"forge": {"nom": "Clan de la Forge", "stats": {}, "texte": "Métiers de forge +20 % d'expérience (plus tard)."},
		"profondeurs": {"nom": "Clan des Profondeurs", "stats": {"End": 1}, "texte": "End +1, Sentir la roche (plus tard)."},
		"marchand": {"nom": "Clan Marchand", "stats": {}, "texte": "Estimation ; prix −5 % chez les nains (Rosalie)."},
	},
	"homme_bete": {
		"chat": {"nom": "Chat", "stats": {"Agi": 2, "Per": 1}, "texte": "Oreilles, queue, yeux fendus ; retombe toujours sur ses pieds."},
		"renard": {"nom": "Renard", "stats": {"Agi": 1, "Int": 1, "Per": 1}, "texte": "Oreilles, grande queue rousse ; ruse. Nina se méfiera moins."},
		"loup": {"nom": "Loup", "stats": {"For": 1, "End": 1, "Per": 1}, "texte": "Oreilles, queue ; Odorat de chasse."},
		"chien": {"nom": "Chien", "stats": {"Vit": 1, "Per": 1, "Vol": 1}, "texte": "Oreilles tombantes ou droites ; loyauté."},
		"lapin": {"nom": "Lapin", "stats": {"Agi": 2, "Per": 1, "Rob": -1}, "texte": "Longues oreilles ; ouïe exceptionnelle, saut."},
		"ours": {"nom": "Ours", "stats": {"For": 2, "Vit": 1, "Agi": -1}, "texte": "Oreilles rondes, carrure ; Peau épaisse."},
		"fauve": {"nom": "Tigre, lion", "stats": {"For": 1, "Agi": 1, "Vol": 1}, "texte": "Rayures ou crinière ; présence."},
		"cerf": {"nom": "Cerf, chèvre", "stats": {"End": 2, "Per": 1}, "texte": "Bois ou cornes ; endurance."},
		"raton": {"nom": "Raton laveur", "stats": {"Agi": 1, "Int": 1, "Per": 1}, "texte": "Masque, queue annelée ; mains habiles."},
		"rat": {"nom": "Rat, souris", "stats": {"Agi": 2, "Per": 1, "Vit": -1}, "texte": "Petites oreilles, queue fine ; se faufile."},
		"oiseau": {"nom": "Oiseau", "stats": {"Per": 2, "Agi": 1}, "texte": "Plumes, ailes vestigiales ; vue perçante."},
		"serpent": {"nom": "Serpent, lézard", "stats": {"Rob": 1, "Agi": 1, "Vol": 1}, "texte": "Écailles, langue fine ; résiste au poison."},
		"taureau": {"nom": "Vache, taureau", "stats": {"For": 1, "End": 1, "Vit": 1}, "texte": "Cornes, oreilles ; force tranquille."},
		"ecureuil": {"nom": "Écureuil", "stats": {"Agi": 2, "Per": 1}, "texte": "Grande queue touffue ; grimpe partout."},
	},
	"demi_sang": {
		"humain_elfe": {"nom": "Humain et elfe", "stats": {"Agi": 1}, "points": 1, "texte": "1 point libre (humain) et Agi +1 (elfe). Comme Pierrick."},
		"humain_nain": {"nom": "Humain et nain", "stats": {"Rob": 1}, "points": 1, "texte": "1 point libre (humain) et Rob +1 (nain)."},
		"humain_bete": {"nom": "Humain et homme-bête", "stats": {"Per": 1}, "points": 1, "texte": "1 point libre (humain) et Per +1 (homme-bête)."},
		"elfe_bete": {"nom": "Elfe et homme-bête", "stats": {"Sag": 1, "Agi": 1}, "texte": "Sag +1 (elfe) et Agi +1 (homme-bête)."},
		"nain_elfe": {"nom": "Nain et elfe", "stats": {"Rob": 1, "Per": 1}, "texte": "Rob +1 (nain) et Per +1 (elfe). Rare, et mal vu des deux côtés."},
	},
	"demon": {
		"succube": {"nom": "Succube / incube", "stats": {"Vol": 1, "Per": 1}, "texte": "Cornes, ailes, queue fine ; Lecture des désirs (plus tard)."},
		"cornu": {"nom": "Cornu", "stats": {"For": 2, "Rob": 1}, "texte": "Grandes cornes, peau épaisse."},
		"aile": {"nom": "Ailé", "stats": {"Agi": 2}, "texte": "Grandes ailes ; Vol court (plus tard)."},
		"sang_noir": {"nom": "Sang-noir", "stats": {"Int": 1, "Vit": 1}, "texte": "Veines sombres, yeux rouges ; magie du sang (plus tard)."},
		"ombre": {"nom": "Ombre", "stats": {"Agi": 1, "Int": 1}, "texte": "Peau très sombre, contours flous ; Pas d'ombre (plus tard)."},
	},
}

const SEXES := ["Homme", "Femme", "Intersexe"]
const PRONOMS := ["il", "elle", "iel"]

const ASTRES := {
	"soleil": {"nom": "Le Soleil", "stats": {"Vol": 1}},
	"rouge": {"nom": "La Rouge", "stats": {"For": 1}},
	"mer": {"nom": "L'Étoile de la Mer", "stats": {"Per": 1}},
	"berger": {"nom": "L'Étoile du Berger", "stats": {"Sag": 1}},
	"pale": {"nom": "La Pâle", "stats": {"Int": 1}},
	"lune": {"nom": "La Lune", "stats": {"Agi": 1}},
	"derniere": {"nom": "La Dernière", "stats": {"Vit": 1}},
}

## Préréglages des caractéristiques (20 points, à partir de 5 partout).
const PRESETS := {
	"Combattant": {"For": 5, "Vit": 5, "End": 4, "Rob": 4, "Agi": 2},
	"Rôdeur": {"Agi": 6, "Per": 6, "End": 3, "Vit": 3, "For": 2},
	"Mage": {"Int": 7, "Sag": 5, "Vol": 4, "Per": 2, "Vit": 2},
	"Soigneur": {"Sag": 7, "Vol": 4, "Vit": 4, "Int": 3, "End": 2},
	"Voleur": {"Agi": 7, "Per": 5, "Int": 3, "Vit": 3, "End": 2},
	"Beau parleur": {"Vol": 5, "Int": 4, "Per": 4, "Agi": 4, "Vit": 3},
	"Artisan": {"End": 5, "Int": 5, "For": 4, "Per": 3, "Vit": 3},
	"Équilibré": {"For": 2, "Agi": 3, "End": 2, "Vit": 3, "Rob": 2, "Int": 2, "Sag": 2, "Per": 2, "Vol": 2},
}

const VIES := {
	"etudiant": {"nom": "Étudiant", "stats": {"Int": 1}, "texte": "Int +1 ; les livres font progresser 20 % plus vite (plus tard)."},
	"soignant": {"nom": "Infirmier, soignant", "stats": {"Sag": 1}, "texte": "Sag +1 ; Bandage dès le départ (tout le monde peut déjà bander un blessé dans le prototype)."},
	"cuisinier": {"nom": "Cuisinier", "stats": {}, "texte": "Ce qu'on mange rend 50 % de PV en plus."},
	"ouvrier": {"nom": "Ouvrier, artisan", "stats": {"End": 1}, "texte": "End +1 ; une heure de travail rapporte 2 cuivre de plus."},
	"sportif": {"nom": "Sportif", "stats": {"Agi": 1, "End": 1}, "texte": "Agi +1, End +1."},
	"soldat": {"nom": "Soldat, policier", "stats": {"Vol": 1}, "texte": "Vol +1 ; Toutes armes : tu touches 5 % plus souvent."},
	"artiste": {"nom": "Artiste", "stats": {}, "texte": "Chant ou dessin ; les nobles l'apprécient (plus tard)."},
	"commercant": {"nom": "Commerçant, vendeur", "stats": {}, "texte": "Marchandage : tu achètes 5 % moins cher et revends 10 % plus cher."},
	"agriculteur": {"nom": "Agriculteur", "stats": {}, "texte": "Cueillir rapporte le double ; résiste à la fatigue (plus tard)."},
	"chercheur": {"nom": "Chercheur, ingénieur", "stats": {}, "texte": "Recettes découvertes plus vite, classe Bricoleur plus tôt (plus tard)."},
	"joueur": {"nom": "Joueur de jeux vidéo", "stats": {}, "texte": "Les fenêtres de système sont plus détaillées : tu vois le niveau des autres en combat."},
	"debrouillard": {"nom": "Sans emploi, débrouillard", "stats": {}, "points": 2, "texte": "+2 points libres ; Débrouille (trouve toujours de quoi manger, plus tard)."},
	"nuit": {"nom": "Personne de la nuit", "stats": {"Per": 1}, "texte": "Barman, danseur, travailleur du sexe : Per +1 ; Lire les gens (plus tard)."},
}

## cout > 0 : avantage ; cout < 0 : défaut (rapporte des points). Le total doit rester à 0 ou plus.
const TRAITS := {
	"robuste": {"nom": "Robuste", "cout": 2, "texte": "PV +15 %."},
	"rapide": {"nom": "Rapide", "cout": 2, "texte": "Vitesse +3 : tu joues plus souvent en combat."},
	"increvable": {"nom": "Increvable", "cout": 3, "texte": "Une fois par combat, tu restes debout à 1 PV au lieu de tomber."},
	"beaute": {"nom": "Beauté frappante", "cout": 2, "texte": "Première impression +5 chez tout le monde (le détail des goûts viendra)."},
	"sang_froid": {"nom": "Sang-froid", "cout": 1, "texte": "Résiste à la peur +20 % (plus tard)."},
	"bon_dormeur": {"nom": "Bon dormeur", "cout": 1, "texte": "Récupère en 6 h au lieu de 8 (plus tard)."},
	"estomac": {"nom": "Estomac de fer", "cout": 1, "texte": "Résiste aux poisons et à l'alcool (plus tard)."},
	"memoire": {"nom": "Mémoire parfaite", "cout": 2, "texte": "Retient chaque rumeur, nom, carte (plus tard)."},
	"apprend_vite": {"nom": "Apprend vite", "cout": 3, "texte": "Expérience +25 %."},
	"volonte": {"nom": "Volonté de fer", "cout": 2, "texte": "Résiste au charme et au contrôle +25 % (plus tard)."},
	"charisme": {"nom": "Charisme naturel", "cout": 2, "texte": "Ce qui fait plaisir aux PNJ leur fait un peu plus plaisir (+1 d'affection)."},
	"confiance": {"nom": "Visage de confiance", "cout": 1, "texte": "Les PNJ croient tes mensonges plus facilement (plus tard)."},
	"ami_betes": {"nom": "Ami des bêtes", "cout": 1, "texte": "Les animaux n'attaquent pas d'abord : les loups te laissent passer."},
	"ami_enfants": {"nom": "Ami des enfants", "cout": 1, "texte": "Tim et Nina t'apprécient d'emblée (+15)."},
	"chanceux": {"nom": "Chanceux", "cout": 2, "texte": "Une fois par combat, un coup raté est rejoué."},
	"trouvaille": {"nom": "Trouvaille", "cout": 1, "texte": "Butin un peu meilleur : plus de cuivre dans les poches."},
	"tireur": {"nom": "Œil de tireur", "cout": 2, "texte": "Toucher à distance +10 %."},
	"fragile": {"nom": "Fragile", "cout": -2, "texte": "PV −15 %."},
	"mauvaise_vue": {"nom": "Mauvaise vue", "cout": -1, "texte": "Toucher à distance −10 %, sauf avec des lunettes."},
	"maladroit": {"nom": "Maladroit", "cout": -1, "texte": "Les jets ratés de fabrication cassent parfois l'outil (plus tard)."},
	"phobie_noir": {"nom": "Phobie du noir", "cout": -2, "texte": "Malus et risque de panique dans le noir (plus tard)."},
	"phobie_eau": {"nom": "Phobie de l'eau", "cout": -2, "texte": "Malus et risque de panique près de l'eau (plus tard)."},
	"dependance": {"nom": "Dépendance (alcool)", "cout": -2, "texte": "Doit boire, sinon le moral chute (plus tard)."},
	"cauchemars": {"nom": "Cauchemars", "cout": -1, "texte": "Le moral baisse un peu chaque matin (plus tard)."},
	"grande_gueule": {"nom": "Grande gueule", "cout": -1, "texte": "Répète parfois des secrets (plus tard)."},
	"sang_chaud": {"nom": "Sang chaud", "cout": -1, "texte": "Une insulte te pousse à la bagarre (plus tard)."},
	"coeur": {"nom": "Cœur d'artichaut", "cout": -1, "texte": "Tombe amoureux vite (plus tard)."},
	"louche": {"nom": "Air louche", "cout": -1, "texte": "Corentin, le garde, se méfie de toi (−15)."},
	"ferme_magie": {"nom": "Fermé à la magie", "cout": -3, "texte": "Mana −40 %, mais Volonté +2."},
	"malchanceux": {"nom": "Malchanceux", "cout": -2, "texte": "Une fois par combat, un coup réussi est rejoué."},
	"ennemi": {"nom": "Ennemi", "cout": -2, "texte": "Quelqu'un du village t'en veut sans raison claire (choisi par le jeu)."},
}
const MAX_TRAITS := 5

const ARCHETYPES := {
	"neutre": {"nom": "Neutre", "traits": {}},
	"candide": {"nom": "Le Candide", "traits": {"honnete": 60, "curieux": 50, "prudent": -30, "empathique": 40}},
	"cynique": {"nom": "Le Cynique", "traits": {"honnete": -30, "empathique": -40, "joueur": 30, "pieux": -60}},
	"heros": {"nom": "Le Héros", "traits": {"courageux": 80, "honnete": 50, "genereux": 50, "orgueilleux": 30}},
	"filou": {"nom": "Le Filou", "traits": {"honnete": -60, "joueur": 60, "curieux": 40, "prudent": 20}},
	"sage": {"nom": "Le Sage", "traits": {"prudent": 70, "colerique": -60, "curieux": 50, "empathique": 40}},
	"brute": {"nom": "La Brute", "traits": {"colerique": 70, "courageux": 50, "empathique": -50, "prudent": -50}},
	"seducteur": {"nom": "Le Séducteur", "traits": {"sociable": 70, "romantique": 40, "pudique": -50, "joueur": 40}},
	"timide": {"nom": "Le Timide", "traits": {"sociable": -60, "pudique": 60, "prudent": 40, "courageux": -20}},
	"ambitieux": {"nom": "L'Ambitieux", "traits": {"ambitieux": 80, "orgueilleux": 50, "genereux": -30}},
	"rebelle": {"nom": "Le Rebelle", "traits": {"colerique": 30, "courageux": 50, "pieux": -40, "prudent": -40}},
}

const VALEURS := ["famille", "justice", "liberté", "richesse", "pouvoir", "savoir", "foi", "tradition", "loyauté", "aventure",
	"plaisir", "honneur", "vengeance", "survie", "ordre", "nature", "beauté", "amour", "gloire", "paix"]
const PASSIONS := ["musique", "chant", "cuisine", "bonne chère", "alcool", "combat", "chasse", "pêche", "mer", "livres",
	"histoire", "magie", "étoiles", "jeux d'argent", "animaux", "monstres", "artisanat", "mode et beauté", "danse", "plantes",
	"voyages", "collection", "rumeurs", "séduction", "amour", "sport", "mécanique", "art", "religion", "nature"]

## Tenue au réveil : l'objet porté, et ce qu'en pensent les PNJ.
const TENUES := {
	"ailleurs": {"nom": "Vêtements de l'autre monde", "objet": "OBJ222", "texte": "Étranges ici. On te croit d'un pays lointain. Ils se vendent bien à un curieux."},
	"simples": {"nom": "Vêtements simples", "objet": "OBJ223", "texte": "Tu passes inaperçu."},
	"haillons": {"nom": "En haillons", "objet": "BRV010", "texte": "Pitié ou mépris selon les gens."},
	"nu": {"nom": "Nu", "objet": "", "texte": "Rien du tout. Moqueries, gêne, pitié, une couverture tendue par Agnès, un regard intéressé ; on risque de te prendre pour un captif évadé."},
}

const OBJETS_AILLEURS := {
	"": {"nom": "Aucun"},
	"BRV011": {"nom": "Une montre"},
	"BRV012": {"nom": "Un briquet"},
	"BRV013": {"nom": "Un couteau suisse"},
	"BRV014": {"nom": "Des lunettes"},
	"BRV015": {"nom": "Un téléphone éteint"},
	"BRV016": {"nom": "Une photo"},
	"BRV017": {"nom": "Un bijou"},
}

const PRENOMS := {
	"humain": ["Aubin", "Héloïse", "Gauvain", "Margot", "Thibault", "Isolde", "Renaud", "Blanche"],
	"elfe": ["Aëlis", "Sylvaën", "Lirien", "Naëlle", "Thalion", "Ilwë"],
	"nain": ["Brokka", "Durgrim", "Helka", "Thorin", "Ragna", "Orsk"],
	"homme_bete": ["Roux", "Fauve", "Brindille", "Croc", "Plume", "Griffe"],
	"demi_sang": ["Elian", "Maëlis", "Corwin", "Nyssa", "Ywen", "Sorel"],
	"demon": ["Vesh", "Lilaë", "Morvaën", "Kesh", "Nyx", "Azraël"],
}


# ---------------------------------------------------------------- calculs

## Bonus d'âge apparent : jeune Agi +1, mûr Vol +1, âgé Sag +1 et End −1 (pas pour les elfes et les démons).
static func bonus_age(c: Dictionary) -> Dictionary:
	if c.get("peuple", "") in ["elfe", "demon"]:
		return {}
	var age: int = c.get("age", 25)
	if age <= 25:
		return {"Agi": 1}
	if age >= 60:
		return {"Sag": 1, "End": -1}
	if age >= 40:
		return {"Vol": 1}
	return {}


## Tout ce qui s'ajoute aux points répartis : peuple, lignée, âge, astre, vie d'avant.
static func bonus(c: Dictionary) -> Dictionary:
	var r := {}
	var sources := [PEUPLES.get(c.get("peuple", ""), {}).get("stats", {}),
		LIGNEES.get(c.get("peuple", ""), {}).get(c.get("lignee", ""), {}).get("stats", {}),
		bonus_age(c),
		ASTRES.get(c.get("astre", ""), {}).get("stats", {}),
		VIES.get(c.get("vie", ""), {}).get("stats", {})]
	for src in sources:
		for s in src:
			r[s] = r.get(s, 0) + src[s]
	return r


## Les points à répartir : 20, plus ceux du peuple et de la vie d'avant, plus 2 par caractéristique baissée à 3.
static func budget(c: Dictionary) -> int:
	var b := POINTS
	b += int(PEUPLES.get(c.get("peuple", ""), {}).get("points", 0))
	b += int(LIGNEES.get(c.get("peuple", ""), {}).get(c.get("lignee", ""), {}).get("points", 0))
	b += int(VIES.get(c.get("vie", ""), {}).get("points", 0))
	for s in c.get("repartition", {}):
		if c.repartition[s] < 0:
			b += 2
	return b


static func depenses(c: Dictionary) -> int:
	var d := 0
	for s in c.get("repartition", {}):
		d += maxi(0, c.repartition[s])
	return d


static func stats_finales(c: Dictionary) -> Dictionary:
	var r := {}
	var b := bonus(c)
	for s in Combattant.STATS:
		r[s] = maxi(1, BASE + int(c.get("repartition", {}).get(s, 0)) + int(b.get(s, 0)))
	return r


## Points des avantages et défauts : doit rester à 0 ou plus.
static func solde_traits(c: Dictionary) -> int:
	var t := 0
	for k in c.get("traits", []):
		t -= int(TRAITS[k].cout)
	return t


## Les affinités magiques tirées au hasard selon le peuple, souvent avec un pic inattendu.
static func affinites_au_hasard(peuple: String) -> Dictionary:
	var r := {}
	for e in ["feu", "eau", "air", "terre", "lumière", "ombre", "nature", "sang"]:
		r[e] = randi_range(5, 35)
	match peuple:
		"elfe":
			for e in ["nature", "air", "lumière"]:
				r[e] += 20
		"nain":
			for e in ["terre", "feu"]:
				r[e] += 20
		"demon":
			for e in ["ombre", "sang"]:
				r[e] += 25
	var pic: String = r.keys().pick_random()
	r[pic] = mini(100, r[pic] + randi_range(20, 40))
	return r
