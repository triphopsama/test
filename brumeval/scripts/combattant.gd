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

## Les compétences du prototype. mult × stat s'ajoute aux dégâts de l'arme.
const COMPETENCES := {
	"frappe_lourde": {"nom": "Frappe lourde", "mult": 1.5, "stat": "For", "endurance": 10},
	"tir_precis": {"nom": "Tir précis", "mult": 1.2, "stat": "Agi", "endurance": 8, "toucher": 20},
	"coup_sournois": {"nom": "Coup sournois", "mult": 1.3, "stat": "Agi", "endurance": 8, "crit": 25},
	"prise": {"nom": "Prise de lutte", "mult": 0.8, "stat": "For", "endurance": 8, "etat": "renverse", "resiste": "For"},
	"coup_bouclier": {"nom": "Coup de bouclier", "mult": 0.6, "stat": "For", "endurance": 8, "etat": "etourdi", "resiste": "Rob"},
	"morsure": {"nom": "Morsure", "mult": 1.2, "stat": "Agi", "endurance": 6, "etat": "saignement", "resiste": "Vit"},
	"soin": {"nom": "Soin", "soin": 2.0, "stat": "Sag", "mana": 8, "portee": 3},
	"charge": {"nom": "Charge", "mult": 1.3, "stat": "For", "endurance": 8, "etat": "renverse", "resiste": "Rob"},
}

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
	c._calculer()
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
