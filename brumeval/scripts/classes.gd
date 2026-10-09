# Les classes et les métiers (monde/classes_metiers.md), lus dans data/classes.csv
# et data/metiers.csv (modifiables au tableur, séparateur ;).
#
# classes.csv :
#   favorites    caractéristiques de la classe : à chaque niveau, 2 points y vont d'office
#   competences  « cle niveau » séparés par des virgules : la compétence (Combattant.COMPETENCES)
#                s'apprend à ce niveau de classe, si les caractéristiques suivent ; on la garde
#                même en changeant de classe
#   style        « tag poids » : ce qu'il faut avoir fait en combat pour qu'on te la propose
#                (arme_for, poings, prise, lance, dague, arc, lancer, bouclier, encaisse,
#                esquive, dos, distance, frappe, plusieurs, achever, betes, fuite, bouge, soin)
#   evolutions   les voies des niveaux 25 / 50 / 75 (affichées, pas encore jouées)
#
# metiers.csv :
#   action, lieux  l'action de data/actions.csv qui fait travailler le métier, et où
#   maitre         le PNJ qui l'enseigne : s'il est là quand tu travailles, ça monte deux fois plus vite
#   competences    « nom niveau » : ce que le métier apprend (affiché)
#   bonus          paie N (cuivre en plus par heure), pain N (un pain toutes les N heures),
#                  poisson N, plante N, soins N (% de soin des remèdes),
#                  vente_armes N, vente_tissus N (% de mieux à la revente)
class_name Classes
extends RefCounted

## Une journée de travail pour devenir apprenti.
const HEURES_APPRENTI := 8.0

static var _classes := {}
static var _metiers := {}


static func _paires(texte: String) -> Array:
	var r := []
	for morceau in texte.split(",", false):
		var m := morceau.strip_edges()
		var i := m.rfind(" ")
		if i > 0 and m.substr(i + 1).is_valid_int():
			r.append([m.substr(0, i).strip_edges(), int(m.substr(i + 1))])
		elif m != "":
			r.append([m, 1])
	return r


static func classes() -> Dictionary:
	if _classes.is_empty():
		for l in Donnees.lire_csv("res://data/classes.csv"):
			l.favorites = Array(str(l.favorites).replace(" ", "").split(",", false))
			l.competences = _paires(l.competences)
			var style := {}
			for p in _paires(l.style):
				style[p[0]] = p[1]
			l.style = style
			_classes[l.id] = l
	return _classes


static func classe(id: String) -> Dictionary:
	return classes().get(id, {})


static func metiers() -> Dictionary:
	if _metiers.is_empty():
		for l in Donnees.lire_csv("res://data/metiers.csv"):
			l.lieux = Array(str(l.lieux).replace(" ", "").split(",", false))
			l.favorites = Array(str(l.favorites).replace(" ", "").split(",", false))
			l.competences = _paires(l.competences)
			var bonus := {}
			for p in _paires(l.bonus):
				bonus[p[0]] = p[1]
			l.bonus = bonus
			_metiers[l.id] = l
	return _metiers


static func metier(id: String) -> Dictionary:
	return metiers().get(id, {})


## Le métier que fait travailler cette action à cet endroit ("" sinon).
static func metier_pour(action: String, lieu: String) -> String:
	for id in metiers():
		var m: Dictionary = metiers()[id]
		if m.action == action and lieu in m.lieux:
			return id
	return ""


## Retrouve l'id d'une classe d'après le texte des fiches de PNJ (« Voleuse », « Garde »…).
static func par_nom(nom: String) -> String:
	var n := nom.to_lower()
	for id in classes():
		if str(classes()[id].nom).to_lower() == n:
			return id
	for id in classes():
		var racine: String = str(classes()[id].nom).to_lower().left(5)
		if n.begins_with(racine):
			return id
	return ""


## Les compétences de la classe jusqu'à ce niveau.
static func competences_jusqua(id: String, niveau: int) -> Array:
	return classe(id).get("competences", []).filter(func(p): return p[1] <= niveau).map(func(p): return p[0])


## Les classes à proposer d'après le style de combat (tag -> nombre de fois) : les 3 meilleures.
static func offre(style: Dictionary, n := 3) -> Array:
	var scores := []
	for id in classes():
		var s := 0.0
		var poids: Dictionary = classes()[id].style
		for tag in poids:
			s += poids[tag] * style.get(tag, 0)
		if s > 0:
			scores.append([s, id])
	scores.sort_custom(func(a, b): return a[0] > b[0])
	return scores.slice(0, n).map(func(p): return p[1])


static func titre_metier(nom: String, niveau: int) -> String:
	if niveau >= 25:
		return "Maître " + nom.to_lower()
	if niveau >= 10:
		return "Compagnon " + nom.to_lower()
	return "Apprenti " + nom.to_lower()
