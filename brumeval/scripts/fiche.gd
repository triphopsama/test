# La fiche du joueur : caractéristiques, niveau, expérience, sac, équipement, bourse.
# Sauvée dans user://joueur.cfg.
class_name Fiche
extends RefCounted

const FICHIER := "user://joueur.cfg"
const HEURES_APPRENTI := Classes.HEURES_APPRENTI
const POINTS_PAR_NIVEAU := 4      # combat.md : +2 fixés par la classe et +2 libres ; sans classe, tout est libre
## Ce que tout le monde sait faire dès que ses caractéristiques le permettent (univers.md :
## chaque compétence a des caractéristiques minimales, voir Combattant.COMPETENCES).
const DE_BASE := ["frappe_lourde", "coup_sournois", "tir_precis"]

var stats := {}
var niveau := 1
var xp := 0
var points := 0
var pv := -1
var bourse := 0                   # en cuivre
var sac := {}                     # id -> nombre
var equipement := {}              # emplacement -> id
var drapeaux := {}                # choses faites une fois (lame trouvée…)

# classe et métier (classes_metiers.md)
var classe := ""                  # id de data/classes.csv, "" tant qu'on n'en a pas
var niveau_classe := 0
var xp_classe := 0
var apprises: Array = []          # compétences de classe apprises : on les garde en changeant de classe
var style := {}                   # ce qu'on fait en combat (tag -> fois), pour les classes proposées
var metier := ""                  # id de data/metiers.csv
var niveau_metier := 0
var xp_metier := 0.0              # en heures de travail
var heures := {}                  # métier -> heures travaillées sans l'avoir (une journée = apprenti)
var annonces: Array = []          # ce qui vient de se passer (niveau, compétence), pas sauvé

# ce qu'on choisit à la création (creation_personnage.md)
var nom := "Toi"
var peuple := "humain"
var lignee := ""
var sexe := "Homme"
var pronoms := "il"
var age := 25
var astre := ""
var vie := ""                     # vie d'avant
var traits: Array = []            # avantages et défauts
var archetype := "neutre"
var caractere := {}               # trait -> -100..100
var valeurs: Array = []
var passions: Array = []
var tenue := "ailleurs"
var objet_ailleurs := ""
var affinites := {}               # élément -> 0..100, cachées par défaut
var options := {"chiffres": "complet", "adulte": true, "mort_definitive": false}

const CHAMPS := ["stats", "niveau", "xp", "points", "pv", "bourse", "sac", "equipement", "drapeaux",
	"classe", "niveau_classe", "xp_classe", "apprises", "style", "metier", "niveau_metier", "xp_metier", "heures",
	"nom", "peuple", "lignee", "sexe", "pronoms", "age", "astre", "vie", "traits", "archetype", "caractere",
	"valeurs", "passions", "tenue", "objet_ailleurs", "affinites", "options"]


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
	var m := 1.0 + (0.15 if a("robuste") else 0.0) - (0.15 if a("fragile") else 0.0)
	return roundi((20 + stats_totales().Vit * 8 + niveau * 4) * m)


## Le joueur a-t-il cet avantage ou ce défaut ?
func a(trait_id: String) -> bool:
	return trait_id in traits


func xp_suivant() -> int:
	return 50 * niveau


## Ajoute de l'expérience ; renvoie le nombre de niveaux gagnés.
func gagner_xp(n: int) -> int:
	if a("apprend_vite"):
		n = roundi(n * 1.25)
	xp += n
	var gagnes := 0
	while xp >= xp_suivant():
		xp -= xp_suivant()
		niveau += 1
		gagnes += 1
		if classe == "":
			points += POINTS_PAR_NIVEAU
		else:
			# combat.md : 2 points fixés par la classe, 2 libres
			var fav: Array = Classes.classe(classe).favorites
			var donnes := []
			for i in 2:
				var st: String = fav[(niveau + i) % fav.size()]
				stats[st] += 1
				donnes.append("+1 " + st)
			points += POINTS_PAR_NIVEAU - 2
			annonces.append("Ta classe de %s te donne %s." % [Classes.classe(classe).nom.to_lower(), ", ".join(donnes)])
	if classe != "":
		_gagner_xp_classe(n)
	if gagnes:
		pv = pv_max()
	return gagnes


func xp_classe_suivant() -> int:
	return 50 * maxi(1, niveau_classe)


func _gagner_xp_classe(n: int) -> void:
	xp_classe += n
	while xp_classe >= xp_classe_suivant():
		xp_classe -= xp_classe_suivant()
		niveau_classe += 1
		annonces.append("%s niveau %d !" % [Classes.classe(classe).nom, niveau_classe])
	_apprendre_classe()


## Apprend les compétences de la classe que le niveau permet (les caractéristiques
## comptent au moment de s'en servir).
func _apprendre_classe() -> void:
	for k in Classes.competences_jusqua(classe, niveau_classe):
		if not k in apprises:
			apprises.append(k)
			var c: Dictionary = Combattant.COMPETENCES[k]
			var manque := []
			for st in c.get("cond", {}):
				if stats_totales()[st] < c.cond[st]:
					manque.append("%s %d" % [st, c.cond[st]])
			annonces.append("Nouvelle compétence : %s%s." % [c.nom, (" (il te faut " + ", ".join(manque) + " pour t'en servir)") if manque else ""])


## Prend une classe : le niveau de classe repart de 1, les compétences apprises restent.
func prendre_classe(id: String) -> void:
	classe = id
	niveau_classe = 1
	xp_classe = 0
	_apprendre_classe()


## Note ce que le joueur a fait en combat (tag -> fois).
func noter_style(s: Dictionary) -> void:
	for tag in s:
		style[tag] = style.get(tag, 0) + s[tag]


# ---------------------------------------------------------------- métier

func xp_metier_suivant() -> float:
	return 4.0 * maxi(1, niveau_metier)


func titre_metier() -> String:
	return "" if metier == "" else Classes.titre_metier(Classes.metier(metier).nom, niveau_metier)


## Bonus du métier en cours (« paie », « pain »…), 0 sinon.
func bonus_metier(cle: String) -> int:
	return 0 if metier == "" else int(Classes.metier(metier).bonus.get(cle, 0))


## Des heures de travail dans un métier (avec un maître : deux fois plus vite).
## Renvoie le texte de ce qui change ; "propose" si on pourrait changer de métier.
func travailler(id: String, h: float, avec_maitre: bool) -> String:
	var gain := h * (2.0 if avec_maitre else 1.0)
	if id != metier:
		heures[id] = heures.get(id, 0.0) + gain
		if heures[id] < HEURES_APPRENTI:
			return "Encore %d h de travail ici pour en faire ton métier." % ceili(HEURES_APPRENTI - heures[id])
		if metier != "":
			return "propose"
		prendre_metier(id)
		return "Une journée de travail : te voilà %s." % titre_metier().to_lower()
	xp_metier += gain
	var monte := false
	while xp_metier >= xp_metier_suivant():
		xp_metier -= xp_metier_suivant()
		niveau_metier += 1
		monte = true
	return "%s, niveau %d." % [titre_metier(), niveau_metier] if monte else ""


## Prend un métier : le niveau repart de 1.
func prendre_metier(id: String) -> void:
	metier = id
	niveau_metier = 1
	xp_metier = 0.0
	heures.erase(id)


func depenser_point(s: String) -> bool:
	if points <= 0 or not stats.has(s):
		return false
	stats[s] += 1
	points -= 1
	return true


## Ce que tu sais faire maintenant : la base (selon tes caractéristiques) et ce que tes
## classes t'ont appris, si tes caractéristiques, ton arme et ton bouclier le permettent.
func competences(toutes := false) -> Array:
	var t := stats_totales()
	var o := Objets.get_(equipement.get("main", ""))
	var arme: Dictionary = Combattant.ARMES.poings if o.is_empty() else {"nom": o.nom, "portee": int(o.portee)}
	var bouclier := 0
	for e in equipement:
		bouclier += int(Objets.get_(equipement[e]).get("bouclier", "0"))
	var r := []
	for k in DE_BASE + apprises:
		if k in r:
			continue
		if toutes and k in apprises:
			r.append(k)
		elif Combattant.peut_utiliser(k, t, arme, bouclier):
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
	var m := (1.5 if vie == "cuisinier" else 1.0) * (1.0 + bonus_metier("soins") / 100.0)
	pv = mini(pv_max(), pv + roundi(int(o.soin) * m))
	return "%s : +%d PV (%d/%d)." % [o.nom, pv - avant, pv, pv_max()]


## Les consommables qui soignent, pour le combat.
func soins() -> Array:
	return sac.keys().filter(func(id): return Objets.get_(id).get("type", "") == "consommable" and int(Objets.get_(id).soin) > 0)


# ---------------------------------------------------------------- sauvegarde

func sauver() -> void:
	var cfg := ConfigFile.new()
	for k in CHAMPS:
		cfg.set_value("joueur", k, get(k))
	cfg.save(FICHIER)


static func charger() -> Fiche:
	var f := Fiche.new()
	var cfg := ConfigFile.new()
	if cfg.load(FICHIER) == OK:
		for k in CHAMPS:
			if cfg.has_section_key("joueur", k):
				f.set(k, cfg.get_value("joueur", k))
	f.pv = clampi(f.pv, 1, f.pv_max())
	return f


## Le personnage tel qu'on l'a créé. c : les choix de l'écran de création.
static func depuis_creation(c: Dictionary) -> Fiche:
	var f := Fiche.new()
	f.sac.clear()
	f.equipement.clear()
	for k in c:
		if k in CHAMPS and k != "stats":
			f.set(k, c[k])
	f.stats = CreationDonnees.stats_finales(c)
	if f.a("ferme_magie"):
		f.stats.Vol += 2
	var tenue_obj: String = CreationDonnees.TENUES[f.tenue].objet
	for id in [tenue_obj, "OBJ511", f.objet_ailleurs]:
		if id != "":
			f.ajouter(id)
			if Objets.emplacement(id) != "" and id != "BRV013" and id != "BRV017":
				f.equiper(id)
	f.drapeaux["cree"] = true
	f.pv = f.pv_max()
	return f


## Le pronom sujet et l'accord : « Il est », « Elle est », « Iel est ».
func accord(m: String, f_: String, n: String = "") -> String:
	match pronoms:
		"elle": return f_
		"iel": return n if n != "" else m
	return m
