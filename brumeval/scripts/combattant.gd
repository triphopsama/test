# Un combattant : ses valeurs de combat tirées des caractéristiques (combat.md, section 2).
class_name Combattant
extends RefCounted

const STATS := ["For", "Agi", "End", "Vit", "Rob", "Int", "Sag", "Per", "Vol"]

const ARMES := {
	"poings": {"nom": "poings", "degats": 2, "portee": 1, "stat": "For"},
	"lutte": {"nom": "poings de lutteur", "degats": 5, "portee": 1, "stat": "For"},
	"dague": {"nom": "lame cachée", "degats": 5, "portee": 1, "stat": "Agi", "crit": 10},
	"marteau": {"nom": "marteau de forge", "degats": 12, "portee": 1, "stat": "For"},
	"epee": {"nom": "épée courte", "degats": 8, "portee": 1, "stat": "For"},
	"masse": {"nom": "masse", "degats": 7, "portee": 1, "stat": "For"},
	"arc": {"nom": "arc de chasse", "degats": 8, "portee": 6, "stat": "Agi"},
	"baton": {"nom": "bâton", "degats": 4, "portee": 1, "stat": "For"},
	"crocs": {"nom": "crocs", "degats": 4, "portee": 1, "stat": "Agi"},
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


static func joueur(n: Node3D) -> Combattant:
	var c := Combattant.new()
	c.id = "joueur"
	c.nom = "Toi"
	c.est_joueur = true
	c.noeud = n
	for s in STATS:
		c.stats[s] = 7
	c._calculer()
	return c


static func loup(i: int, n: Node3D) -> Combattant:
	var c := Combattant.new()
	c.id = "loup%d" % i
	c.nom = "Loup gris %d" % i
	c.est_bete = true
	c.noeud = n
	c.niveau = 2
	c.stats = {"For": 6, "Agi": 9, "End": 7, "Vit": 3, "Rob": 4, "Int": 1, "Sag": 2, "Per": 9, "Vol": 3}
	c.arme = ARMES.crocs
	c.competences = ["morsure"]
	c._calculer()
	return c


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
