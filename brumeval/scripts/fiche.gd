# La fiche du joueur : caractéristiques, niveau, expérience, sac, équipement, bourse.
# Sauvée dans user://joueur.cfg.
class_name Fiche
extends RefCounted

const FICHIER := "user://joueur.cfg"
const POINTS_PAR_NIVEAU := 4      # combat.md : +2 fixés par la classe et +2 libres ; sans classe, tout est libre
## Ce que le joueur sait faire dès que ses caractéristiques le permettent (univers.md :
## chaque compétence a des caractéristiques minimales). arme : type d'arme nécessaire.
const COMPETENCES := {
	"frappe_lourde": {"For": 10},
	"coup_sournois": {"Agi": 10, "arme": "Agi"},
	"tir_precis": {"Per": 10, "arme": "arc"},
}

var stats := {}
var niveau := 1
var xp := 0
var points := 0
var pv := -1
var bourse := 0                   # en cuivre
var sac := {}                     # id -> nombre
var equipement := {}              # emplacement -> id
var drapeaux := {}                # choses faites une fois (lame trouvée…)


func _init() -> void:
	for s in Combattant.STATS:
		stats[s] = 7
	# au réveil dans le bois : les vêtements d'ailleurs et l'anneau, rien d'autre
	for id in ["OBJ222", "OBJ511"]:
		ajouter(id)
		equiper(id)
	pv = pv_max()


# ---------------------------------------------------------------- caractéristiques

func stats_totales() -> Dictionary:
	var t := stats.duplicate()
	for e in equipement:
		var b := Objets.bonus(equipement[e])
		for s in b:
			t[s] = maxi(1, t[s] + b[s])
	return t


func pv_max() -> int:
	return 20 + stats_totales().Vit * 8 + niveau * 4


func xp_suivant() -> int:
	return 50 * niveau


## Ajoute de l'expérience ; renvoie le nombre de niveaux gagnés.
func gagner_xp(n: int) -> int:
	xp += n
	var gagnes := 0
	while xp >= xp_suivant():
		xp -= xp_suivant()
		niveau += 1
		points += POINTS_PAR_NIVEAU
		gagnes += 1
	if gagnes:
		pv = pv_max()
	return gagnes


func depenser_point(s: String) -> bool:
	if points <= 0 or not stats.has(s):
		return false
	stats[s] += 1
	points -= 1
	return true


func competences() -> Array:
	var t := stats_totales()
	var arme := Objets.get_(equipement.get("main", ""))
	var r := []
	for k in COMPETENCES:
		var ok := true
		for s in COMPETENCES[k]:
			if s == "arme":
				var voulu: String = COMPETENCES[k].arme
				if arme.is_empty() or not (str(arme.stat) == voulu or (voulu == "arc" and int(arme.portee) > 1)):
					ok = false
			elif t[s] < COMPETENCES[k][s]:
				ok = false
		if ok:
			r.append(k)
	return r


# ---------------------------------------------------------------- sac

func nombre(id: String) -> int:
	return sac.get(id, 0)


func ajouter(id: String, n := 1) -> void:
	sac[id] = nombre(id) + n


func retirer(id: String, n := 1) -> bool:
	if nombre(id) < n:
		return false
	sac[id] -= n
	if sac[id] <= 0:
		sac.erase(id)
		for e in equipement.keys():
			if equipement[e] == id:
				equipement.erase(e)
	return true


func equipe(id: String) -> bool:
	return id in equipement.values()


## Équipe un objet. Renvoie "" si c'est fait, sinon pourquoi pas.
func equiper(id: String) -> String:
	var e := Objets.emplacement(id)
	if e == "" or nombre(id) == 0:
		return "Ça ne se porte pas."
	var cond := Objets.conditions(id)
	var t := stats_totales()
	for s in cond:
		if t[s] < cond[s]:
			return "Il faut %s %d pour s'en servir (tu as %d)." % [s, cond[s], t[s]]
	if equipement.get(e, "") == "OBJ511":
		return "L'anneau ne s'enlève pas."
	equipement[e] = id
	if Objets.deux_mains(id):
		equipement.erase("main_gauche")
	elif e == "main_gauche" and Objets.deux_mains(equipement.get("main", "")):
		equipement.erase("main")
	pv = mini(pv, pv_max())
	return ""


func desequiper(id: String) -> String:
	if id == "OBJ511":
		return "L'anneau ne s'enlève pas."
	for e in equipement.keys():
		if equipement[e] == id:
			equipement.erase(e)
	pv = mini(pv, pv_max())
	return ""


## Mange ou applique un consommable. Renvoie le texte de ce qui se passe.
func utiliser(id: String) -> String:
	var o := Objets.get_(id)
	if o.is_empty() or o.type != "consommable" or not retirer(id):
		return ""
	var avant := pv
	pv = mini(pv_max(), pv + int(o.soin))
	return "%s : +%d PV (%d/%d)." % [o.nom, pv - avant, pv, pv_max()]


## Les consommables qui soignent, pour le combat.
func soins() -> Array:
	return sac.keys().filter(func(id): return Objets.get_(id).get("type", "") == "consommable" and int(Objets.get_(id).soin) > 0)


# ---------------------------------------------------------------- sauvegarde

func sauver() -> void:
	var cfg := ConfigFile.new()
	for k in ["stats", "niveau", "xp", "points", "pv", "bourse", "sac", "equipement", "drapeaux"]:
		cfg.set_value("joueur", k, get(k))
	cfg.save(FICHIER)


static func charger() -> Fiche:
	var f := Fiche.new()
	var cfg := ConfigFile.new()
	if cfg.load(FICHIER) == OK:
		for k in ["stats", "niveau", "xp", "points", "pv", "bourse", "sac", "equipement", "drapeaux"]:
			if cfg.has_section_key("joueur", k):
				f.set(k, cfg.get_value("joueur", k))
	f.pv = clampi(f.pv, 1, f.pv_max())
	return f
