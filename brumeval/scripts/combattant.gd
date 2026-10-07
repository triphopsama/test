# Un combattant : ses valeurs de combat tirées des caractéristiques (combat.md, section 2).
class_name Combattant
extends RefCounted

const STATS := ["For", "Agi", "End", "Vit", "Rob", "Int", "Sag", "Per", "Vol"]

const ARMES := {
	"poings": {"nom": "poings", "degats": 2, "portee": 1, "stat": "For"},
	"lutte": {"nom": "poings de lutteur", "degats": 5, "portee": 1, "stat": "For"},
	"dague": {"nom": "lame cachée", "degats": 5, "portee": 1, "stat": "Agi", "crit": 10, "objet": "OBJ002"},
	"marteau": {"nom": "marteau de forge", "degats": 12, "portee": 1, "stat": "For"},
	"epee": {"nom": "épée courte", "degats": 8, "portee": 1, "stat": "For", "objet": "OBJ007"},
	"masse": {"nom": "masse", "degats": 7, "portee": 1, "stat": "For"},
	"arc": {"nom": "arc de chasse", "degats": 8, "portee": 6, "stat": "Agi", "objet": "OBJ072"},
	"baton": {"nom": "bâton", "degats": 4, "portee": 1, "stat": "For"},
	"crocs": {"nom": "crocs", "degats": 4, "portee": 1, "stat": "Agi"},
	"dents": {"nom": "dents", "degats": 3, "portee": 1, "stat": "Agi"},
	"pinces": {"nom": "pinces", "degats": 8, "portee": 1, "stat": "For"},
	"defenses": {"nom": "défenses", "degats": 7, "portee": 1, "stat": "For"},
}

## Les compétences (noms et chiffres repris de monde/donnees/competences).
## mult × stat s'ajoute aux dégâts de l'arme. cond : caractéristiques minimales ;
## arme : catégorie d'arme nécessaire (dague, arc, lance, bouclier, poings).
## type : attaque (par défaut), soi (sur soi), allies (autour de soi), soin,
## passif (toujours actif), hors_combat (s'utilise dans le village, ou plus tard).
const COMPETENCES := {
	"frappe_lourde": {"nom": "Frappe lourde", "mult": 1.5, "stat": "For", "endurance": 10, "cond": {"For": 10},
		"desc": "Un coup appuyé : 1,5 × For."},
	"tir_precis": {"nom": "Tir précis", "mult": 1.2, "stat": "Agi", "endurance": 8, "toucher": 20, "cond": {"Per": 10}, "arme": "arc",
		"desc": "Un tir appliqué : 1,2 × Agi, +20 % pour toucher."},
	"coup_sournois": {"nom": "Coup sournois", "mult": 1.3, "stat": "Agi", "endurance": 8, "crit": 25, "cond": {"Agi": 10}, "arme": "dague",
		"desc": "La lame là où ça fait mal : 1,3 × Agi, +25 % de critique."},
	"prise": {"nom": "Prise de lutte", "mult": 0.8, "stat": "For", "endurance": 8, "etat": "renverse", "resiste": "For", "cond": {"For": 8},
		"desc": "Saisir et faire tomber : 0,8 × For, renverse (For contre For)."},
	"coup_bouclier": {"nom": "Coup de bouclier", "mult": 0.6, "stat": "For", "endurance": 8, "etat": "etourdi", "resiste": "Rob", "cond": {"Rob": 8}, "arme": "bouclier",
		"desc": "Le bouclier en plein visage : 0,6 × For, étourdit (contre Rob)."},
	"morsure": {"nom": "Morsure", "mult": 1.2, "stat": "Agi", "endurance": 6, "etat": "saignement", "resiste": "Vit"},
	"soin": {"nom": "Soin", "type": "soin", "soin": 2.0, "stat": "Sag", "mana": 8, "portee": 3},
	"charge": {"nom": "Charge", "mult": 1.3, "stat": "For", "endurance": 8, "etat": "renverse", "resiste": "Rob", "cond": {"For": 10, "End": 8},
		"desc": "Foncer dans le tas : 1,3 × For, renverse (contre Rob)."},
	# Guerrier
	"parade": {"nom": "Parade", "type": "passif", "cond": {"Agi": 6},
		"desc": "30 % de chances de parer un coup au corps à corps : il ne fait que 30 % des dégâts."},
	"cri_guerre": {"nom": "Cri de guerre", "type": "allies", "zone": 2, "endurance": 5, "etat_allies": "galvanise", "duree": 3, "cond": {"Vol": 8},
		"desc": "Les alliés à 2 cases font +10 % de dégâts pendant 3 tours."},
	# Lutteur
	"coup_tete": {"nom": "Coup de tête", "mult": 0.8, "stat": "For", "endurance": 3, "etat": "etourdi", "resiste": "Rob", "recul": 0.1,
		"desc": "0,8 × For, peut étourdir ; ça fait mal aussi à celui qui le donne."},
	"projection": {"nom": "Projection", "mult": 1.0, "stat": "For", "endurance": 7, "etat": "renverse", "resiste": "For", "cond": {"For": 12},
		"desc": "Soulever et jeter au sol : 1,0 × For, renverse (For contre For)."},
	# Garde
	"bouclier_leve": {"nom": "Lever le bouclier", "type": "soi", "endurance": 4, "etat_soi": "garde", "cond": {"Rob": 8}, "arme": "bouclier",
		"desc": "Jusqu'à ton prochain tour, −40 % de dégâts reçus de face."},
	"provocation": {"nom": "Provocation", "type": "provoquer", "portee": 3, "endurance": 4, "resiste": "Vol", "stat": "Vol", "cond": {"Vol": 8},
		"desc": "La cible (à 3 cases) doit s'en prendre à toi à son prochain tour (Vol contre Vol)."},
	# Lancier
	"allonge": {"nom": "Allonge", "mult": 1.0, "stat": "For", "endurance": 4, "portee": 2, "cond": {"Agi": 8}, "arme": "lance",
		"desc": "Frapper à 2 cases : 1,0 × For."},
	"mur_piques": {"nom": "Mur de piques", "type": "soi", "endurance": 5, "etat_soi": "piques", "cond": {"Vol": 10}, "arme": "lance",
		"desc": "Jusqu'à ton prochain tour, qui t'attaque de face au corps à corps prend 0,5 × ta For."},
	# Duelliste
	"pas_de_cote": {"nom": "Pas de côté", "type": "passif", "cond": {"Agi": 8},
		"desc": "20 % de chances d'esquiver un coup au corps à corps."},
	"feinte": {"nom": "Feinte", "mult": 0.8, "stat": "Agi", "endurance": 4, "toucher": 30, "imparable": true, "cond": {"Int": 8, "Agi": 10},
		"desc": "Tromper la garde : 0,8 × Agi, +30 % pour toucher, ni parade ni bouclier."},
	"riposte": {"nom": "Riposte", "type": "passif", "cond": {"Agi": 12},
		"desc": "Quand un coup au corps à corps te rate, tu frappes aussitôt : 1,0 × Agi."},
	# Moine
	"poings_de_fer": {"nom": "Poings de fer", "type": "passif", "cond": {"Rob": 8},
		"desc": "À mains nues, tes poings comptent comme des masses (6 dégâts)."},
	"souffle": {"nom": "Souffle intérieur", "type": "soi", "etat_soi": "concentre", "cond": {"Vol": 10},
		"desc": "Regagne 20 % d'endurance et 10 % de mana ; ton prochain coup fait +30 %."},
	"esquive_parfaite": {"nom": "Esquive parfaite", "type": "passif", "cond": {"Agi": 14},
		"desc": "Une fois par combat, annule entièrement un coup qui t'aurait touché."},
	# Mercenaire
	"toutes_armes": {"nom": "Toutes armes", "type": "passif",
		"desc": "À l'aise avec n'importe quelle arme : +5 % pour toucher."},
	"pillage": {"nom": "Pillage", "type": "passif", "cond": {"Per": 8},
		"desc": "Après une victoire, +50 % d'argent et plus de butin."},
	"dernier_debout": {"nom": "Dernier debout", "type": "passif", "cond": {"End": 12},
		"desc": "Une fois par combat, quand tu es le dernier de ton camp debout et à moins de 30 % de vie, tu remontes à 30 %."},
	# Archer
	"volee": {"nom": "Volée", "mult": 0.7, "stat": "Per", "endurance": 6, "portee": 5, "zone": 1, "cond": {"Agi": 10}, "arme": "arc",
		"desc": "Une volée de flèches : 0,7 × Per sur la cible et chaque ennemi collé à elle."},
	"tir_oeil": {"nom": "Tir dans l'œil", "mult": 1.5, "stat": "Per", "endurance": 8, "toucher": -10, "crit": 30, "cond": {"Per": 16}, "arme": "arc",
		"desc": "Viser l'œil : 1,5 × Per, +30 % de critique, mais −10 % pour toucher."},
	# Lanceur
	"couteaux": {"nom": "Couteaux de lancer", "mult": 0.6, "stat": "Agi", "endurance": 4, "portee": 4, "coups": 2, "cond": {"Agi": 8}, "arme": "dague",
		"desc": "Deux lames lancées à 4 cases : 0,6 × Agi chacune."},
	"javelot": {"nom": "Javelot", "mult": 1.0, "stat": "For", "endurance": 5, "portee": 4, "cond": {"For": 8}, "arme": "lance",
		"desc": "Lancer sa lance à 4 cases : 1,0 × For."},
	"pluie_lames": {"nom": "Pluie de lames", "mult": 0.6, "stat": "Agi", "endurance": 8, "portee": 4, "zone": 1, "cond": {"Agi": 14}, "arme": "dague",
		"desc": "Des lames partout : 0,6 × Agi sur la cible et chaque ennemi collé à elle."},
	# Voleur
	"vol_tire": {"nom": "Vol à la tire", "type": "hors_combat", "cond": {"Agi": 8},
		"desc": "Dans le village : « Voler à la tire » sur quelqu'un. Réussir dépend de ton Agi ; être pris, de ceux qui regardent."},
	"crochetage": {"nom": "Crochetage", "type": "hors_combat", "cond": {"Agi": 10},
		"desc": "Ouvrir les serrures (quand les maisons auront des intérieurs)."},
	# Éclaireur
	"camouflage": {"nom": "Camouflage", "type": "soi", "endurance": 4, "etat_soi": "cache", "duree": 2, "cond": {"Agi": 8},
		"desc": "Disparaître : on ne peut plus te viser de loin, et ton prochain coup compte comme dans le dos."},
	"course_longue": {"nom": "Course longue", "type": "passif", "cond": {"End": 10},
		"desc": "+1 case de déplacement."},
	"pistage": {"nom": "Pistage", "type": "hors_combat", "cond": {"Per": 8},
		"desc": "Suivre des traces (pas encore en jeu)."},
	# Chasseur de monstres
	"point_faible": {"nom": "Point faible", "mult": 1.2, "stat": "Per", "endurance": 5, "crit": 15, "vs_betes": true, "cond": {"Per": 12},
		"desc": "Contre une bête : 1,2 × Per, sa défense compte moitié, +15 % de critique."},
	"trophee": {"nom": "Trophée", "type": "passif",
		"desc": "+25 % d'expérience contre les bêtes."},
	"piege": {"nom": "Piège", "type": "hors_combat", "cond": {"Int": 8},
		"desc": "Poser des pièges (pas encore en jeu)."},
	# Rôdeur
	"soin_bois": {"nom": "Soin des bois", "type": "soin", "soin": 1.0, "stat": "Sag", "endurance": 6, "portee": 1, "cond": {"Sag": 8},
		"desc": "Des herbes sur la plaie : soigne un allié à côté (ou toi) de 1,0 × Sag."},
}

## La riposte, qui n'est pas dans le menu.
const RIPOSTE := {"nom": "riposte", "mult": 1.0, "stat": "Agi"}


var id := ""
var nom := ""
var camp := 0              # 0 : le camp du joueur, 1 : l'autre
var est_joueur := false
var est_bete := false
var stats := {}
var niveau := 1
var pv := 0
var pv_max := 0
var endurance := 0
var endurance_max := 0
var mana := 0
var mana_max := 0
var vitesse := 10
var deplacement := 3
var saut := 1
var def_phys := 0
var def_mag := 0
var bouclier := 0
var arme: Dictionary = ARMES.poings
var competences: Array = []
var case := Vector2i.ZERO
var orientation := Vector2i(0, 1)
var ct := 0.0
var etats := {}
var a_terre := false
var stable := false
var mort := false
var sorti := false         # a fui ou s'est rendu
var tours_saignement := 3
var ventre_mou := false      # crabe-rocher : de flanc ou de dos, la carapace ne protège plus
var bonus_toucher := 0       # Soldat : +5
var bonus_distance := 0      # Œil de tireur +10, Mauvaise vue −10
var increvable := false      # une fois : reste debout à 1 PV
var chance := 0              # +1 Chanceux (rejoue un raté), −1 Malchanceux (rejoue un réussi), une fois
var noeud: Node3D
var style := {}              # ce que le joueur a fait pendant le combat (pour lui proposer une classe)
var utilise := {}            # compétences une fois par combat déjà servies
var provoque_par: Combattant = null


## La catégorie d'une arme d'après son nom et sa portée : dague, arc, lance, poings ou for.
static func categorie_arme(arme: Dictionary) -> String:
	var n := str(arme.get("nom", "")).to_lower()
	if int(arme.get("portee", 1)) > 1 or n.contains("arc"):
		return "arc"
	for mot in ["dague", "couteau", "lame cachée"]:
		if n.contains(mot):
			return "dague"
	for mot in ["lance", "trident", "épieu", "pique"]:
		if n.contains(mot):
			return "lance"
	if n.contains("poing"):
		return "poings"
	return "for"


## Peut-on se servir de cette compétence avec ces caractéristiques, cette arme et ce bouclier ?
static func peut_utiliser(k: String, s: Dictionary, arme: Dictionary, bouclier: int) -> bool:
	var c: Dictionary = COMPETENCES.get(k, {})
	if c.is_empty():
		return false
	for st in c.get("cond", {}):
		if s.get(st, 0) < c.cond[st]:
			return false
	match str(c.get("arme", "")):
		"":
			return true
		"bouclier":
			return bouclier > 0
		var cat:
			return categorie_arme(arme) == cat


func a_comp(k: String) -> bool:
	return k in competences


## Les passifs qui changent les valeurs de combat (à appeler une fois les compétences connues).
func appliquer_passifs() -> void:
	if a_comp("poings_de_fer") and categorie_arme(arme) == "poings":
		arme = {"nom": "poings de fer", "degats": 6, "portee": 1, "stat": "For"}
	if a_comp("course_longue"):
		deplacement += 1
	if a_comp("toutes_armes"):
		bonus_toucher += 5


func _calculer() -> void:
	pv_max = 20 + stats.Vit * 8 + niveau * 4
	pv = pv_max
	mana_max = stats.Sag * 6 + stats.Int * 2
	mana = mana_max
	endurance_max = 20 + stats.End * 5
	endurance = endurance_max
	vitesse = 10 + stats.Agi
	deplacement = 3 + int(stats.Agi / 10.0)
	saut = 1 + int(stats.Agi / 15.0)
	def_phys += stats.Rob
	def_mag = stats.Vol * 2


static func depuis_pnj(d: Dictionary, n: Node3D) -> Combattant:
	var c := Combattant.new()
	c.id = d.id
	c.nom = d.nom
	c.noeud = n
	for s in STATS:
		c.stats[s] = int(d.get(s, "6"))
	c.niveau = maxi(1, int(d.get("niveau_classe", "1")))
	var classe := str(d.get("classe", "")).to_lower()
	if classe.contains("archer"):
		c.arme = ARMES.arc
		c.competences = ["tir_precis"]
	elif classe.contains("voleu"):
		c.arme = ARMES.dague
		c.competences = ["coup_sournois"]
		c.def_phys = 4
	elif classe.contains("lutteu"):
		c.arme = ARMES.lutte
		c.competences = ["prise"]
	elif classe.contains("garde"):
		c.arme = ARMES.epee
		c.competences = ["coup_bouclier"]
		c.def_phys = 8
		c.bouclier = 15
	elif classe.contains("guerri"):
		c.arme = ARMES.marteau if c.id == "BRU002" else ARMES.epee
		c.competences = ["frappe_lourde"]
		c.def_phys = 4
	elif classe.contains("prêtre") or classe.contains("soin"):
		c.arme = ARMES.masse if classe.contains("prêtre") else ARMES.baton
		c.competences = ["soin"]
	# les PNJ suivent les mêmes règles : les compétences de leur classe, à leur niveau
	var id_classe := Classes.par_nom(str(d.get("classe", "")))
	for k in Classes.competences_jusqua(id_classe, c.niveau):
		if not k in c.competences and peut_utiliser(k, c.stats, c.arme, c.bouclier):
			c.competences.append(k)
	c._calculer()
	c.appliquer_passifs()
	return c


## Le joueur, tiré de sa fiche : caractéristiques avec les bonus portés, arme, armure, bouclier, PV actuels.
static func joueur(n: Node3D, f: Fiche = null) -> Combattant:
	var c := Combattant.new()
	c.id = "joueur"
	c.nom = "Toi"
	c.est_joueur = true
	c.noeud = n
	if f == null:
		f = Fiche.new()
	c.stats = f.stats_totales()
	c.niveau = f.niveau
	for e in f.equipement:
		var o := Objets.get_(f.equipement[e])
		c.def_phys += int(o.get("defense", "0"))
		c.bouclier += int(o.get("bouclier", "0"))
		if o.get("type", "") == "arme":
			c.arme = {"nom": o.nom, "degats": int(o.degats), "portee": int(o.portee), "stat": o.stat, "crit": int(o.crit), "objet": o.id}
	c.competences = f.competences()
	c._calculer()
	c.pv_max = f.pv_max()
	c.pv = clampi(f.pv, 1, c.pv_max)
	if f.a("rapide"):
		c.vitesse += 3
	if f.a("ferme_magie"):
		c.mana_max = int(c.mana_max * 0.6)
		c.mana = c.mana_max
	c.bonus_toucher = 5 if f.vie == "soldat" else 0
	c.bonus_distance = (10 if f.a("tireur") else 0) - (10 if f.a("mauvaise_vue") and not f.equipe("BRV014") else 0)
	c.increvable = f.a("increvable")
	c.chance = (1 if f.a("chanceux") else 0) - (1 if f.a("malchanceux") else 0)
	c.appliquer_passifs()
	c.nom = f.nom if f.nom != "" else "Toi"
	return c


## Les bêtes de la côte (monde/bestiaire.md). armure : défense en plus de la Robustesse.
const BETES := {
	"loup": {"nom": "Loup gris", "niveau": 2, "arme": "crocs", "competences": ["morsure"], "planche": "res://sprites/loup_planche.png",
		"stats": {"For": 6, "Agi": 9, "End": 7, "Vit": 3, "Rob": 4, "Int": 1, "Sag": 2, "Per": 9, "Vol": 3}},
	"rat": {"nom": "Rat géant", "niveau": 1, "arme": "dents", "competences": [], "planche": "res://sprites/rat_planche.png",
		"stats": {"For": 3, "Agi": 7, "End": 4, "Vit": 1, "Rob": 2, "Int": 1, "Sag": 1, "Per": 6, "Vol": 2}},
	"crabe": {"nom": "Crabe-rocher", "niveau": 2, "arme": "pinces", "competences": [], "armure": 10, "ventre_mou": true,
		"planche": "res://sprites/crabe_planche.png",
		"stats": {"For": 6, "Agi": 3, "End": 6, "Vit": 5, "Rob": 12, "Int": 1, "Sag": 1, "Per": 5, "Vol": 4}},
	"sanglier": {"nom": "Sanglier des ronces", "niveau": 3, "arme": "defenses", "competences": ["charge"], "planche": "res://sprites/sanglier_planche.png",
		"stats": {"For": 12, "Agi": 6, "End": 8, "Vit": 7, "Rob": 7, "Int": 1, "Sag": 2, "Per": 5, "Vol": 6}},
}


static func bete(type: String, i: int, n: Node3D) -> Combattant:
	var b: Dictionary = BETES[type]
	var c := Combattant.new()
	c.id = "%s%d" % [type, i]
	c.nom = b.nom + (" %d" % i if i > 0 else "")
	c.est_bete = true
	c.noeud = n
	c.niveau = b.niveau
	c.stats = b.stats.duplicate()
	c.arme = ARMES[b.arme]
	c.competences = b.competences.duplicate()
	c.def_phys = b.get("armure", 0)
	c.ventre_mou = b.get("ventre_mou", false)
	c._calculer()
	return c


static func loup(i: int, n: Node3D) -> Combattant:
	return bete("loup", i, n)


func en_jeu() -> bool:
	return not (a_terre or mort or sorti)


func etat_texte() -> String:
	if mort:
		return "mort"
	if sorti:
		return "hors du combat"
	if a_terre:
		return "stabilisé" if stable else "à terre (%d tours)" % tours_saignement
	return "%d/%d PV" % [pv, pv_max]
