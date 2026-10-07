# Les objets du prototype, lus dans data/objets.csv (modifiable à la main).
#
# Colonnes :
#   id           OBJ… (repris de monde/donnees/objets/objets.csv) ou BRV… (propre au prototype)
#   type         arme, armure, bouclier, bijou, consommable, materiau, outil
#   emplacement  main, deux_mains, main_gauche, tete, torse, mains, jambes, pieds, cou, anneau
#   degats, portee, stat, crit   pour les armes (combat.md : dégâts de l'arme + mult × stat)
#   defense      s'ajoute à la défense physique ; bouclier : chance de bloquer de face
#   bonus        « Agi +2, Per -1 » : s'ajoute aux caractéristiques tant que c'est porté
#   soin         PV rendus quand on le mange ou l'applique
#   conditions   caractéristiques minimales pour s'en servir (« For 10 »)
#   prix         « 3 argent 6 cuivre » ; 1 or = 20 argent, 1 argent = 12 cuivre ; invendable
#   vendeurs     ids des PNJ qui le vendent
class_name Objets
extends RefCounted

const CHEMIN := "res://data/objets.csv"
const EMPLACEMENTS := ["main", "main_gauche", "tete", "torse", "mains", "jambes", "pieds", "cou", "anneau"]
const NOMS_EMPLACEMENTS := {"main": "main", "main_gauche": "main gauche", "tete": "tête", "torse": "torse",
	"mains": "mains", "jambes": "jambes", "pieds": "pieds", "cou": "cou", "anneau": "doigt"}

static var _tous := {}


static func tous() -> Dictionary:
	if _tous.is_empty():
		for l in Donnees.lire_csv(CHEMIN):
			_tous[l.id] = l
	return _tous


static func get_(id: String) -> Dictionary:
	return tous().get(id, {})


static func existe(id: String) -> bool:
	return tous().has(id)


## L'emplacement où il se porte ("" si ça ne se porte pas). Deux mains = la main.
static func emplacement(id: String) -> String:
	var e := str(get_(id).get("emplacement", "—"))
	if e == "deux_mains":
		return "main"
	return e if e in EMPLACEMENTS else ""


static func deux_mains(id: String) -> bool:
	return str(get_(id).get("emplacement", "")) == "deux_mains"


## « Agi +2, Per -1 » -> {"Agi": 2, "Per": -1}. Sert aux bonus et aux conditions.
static func lire_stats(texte: String) -> Dictionary:
	var r := {}
	for morceau in texte.split(",", false):
		var m := morceau.strip_edges().split(" ", false)
		if m.size() >= 2 and m[0] in Combattant.STATS:
			r[m[0]] = int(m[1])
	return r


static func bonus(id: String) -> Dictionary:
	return lire_stats(str(get_(id).get("bonus", "")))


static func conditions(id: String) -> Dictionary:
	return lire_stats(str(get_(id).get("conditions", "")))


## Prix en cuivre (-1 : invendable).
static func prix(id: String) -> int:
	return cuivre_de(str(get_(id).get("prix", "invendable")))


## « 1 or 3 argent 6 cuivre » -> en cuivre. -1 si invendable.
static func cuivre_de(texte: String) -> int:
	var m := texte.strip_edges().split(" ", false)
	if m.is_empty() or not m[0].is_valid_int():
		return -1
	var total := 0
	var i := 0
	while i + 1 < m.size():
		var n := int(m[i])
		match m[i + 1]:
			"or": total += n * 240
			"argent": total += n * 12
			_: total += n
		i += 2
	return total


static func texte_prix(cuivre: int) -> String:
	if cuivre < 0:
		return "invendable"
	if cuivre == 0:
		return "rien"
	var morceaux := []
	var o := cuivre / 240
	var a := (cuivre % 240) / 12
	var c := cuivre % 12
	if o:
		morceaux.append("%d or" % o)
	if a:
		morceaux.append("%d argent" % a)
	if c:
		morceaux.append("%d cuivre" % c)
	return " ".join(morceaux)


## Une ligne courte pour les listes : « Épée courte · 8 dégâts (For) · Agi +2 ».
static func resume(id: String) -> String:
	var o := get_(id)
	if o.is_empty():
		return id
	var r: Array = [o.nom]
	match str(o.type):
		"arme":
			var t := "%s dégâts (%s)" % [o.degats, o.stat]
			if int(o.portee) > 1:
				t += ", portée %s" % o.portee
			if deux_mains(id):
				t += ", deux mains"
			r.append(t)
		"armure":
			r.append("défense %s, %s" % [o.defense, NOMS_EMPLACEMENTS.get(o.emplacement, o.emplacement)])
		"bouclier":
			r.append("blocage %s %%" % o.bouclier)
		"consommable":
			r.append("+%s PV" % o.soin)
	if str(o.bonus) != "—" and str(o.bonus) != "":
		r.append(o.bonus)
	return " · ".join(r)
