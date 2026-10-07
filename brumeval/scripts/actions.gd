# Les actions, lues dans data/actions.csv (une ligne par action, modifiable à la main).
#
# Colonnes :
#   id              nom technique, aussi le nom du dossier d'illustrations
#   nom             ce qui s'affiche dans le menu
#   cible           pnj (on agit sur quelqu'un) ou lieu (on agit sur place)
#   lieux           * ou liste de lieux séparés par des virgules (cle de lieux.csv)
#   pnj             * ou liste d'ids (BRU001…) : une ligne avec un id précis
#                   remplace la ligne * pour ce PNJ (texte propre à chacun)
#   intime          1 pour une action intime
#   duree_min       minutes qui passent pendant l'action
#   affection_min   affection du PNJ envers toi pour qu'il accepte
#   effet_affection gain ou perte d'affection
#   description     le texte affiché ; {nom} {activite} {parole} {lieu} sont remplacés
#
# Règles fixes (dans le code, pas dans le fichier) pour les actions intimes :
#   - jamais avec un PNJ de moins de 18 ans, ni sans profil intime (« — ») ;
#   - jamais avec une personne captive, esclave ou sous contrat de dette ;
#   - jamais si un enfant est à moins de 20 m ;
#   - le PNJ dit non si son affection est trop basse, et non veut dire non ;
#   - Échap arrête la scène à tout moment.
extends RefCounted

const AGE_ADULTE := 18
## Actions qui lancent un combat (jamais contre un enfant).
const COMBATS := {"bagarre": "bagarre", "attaquer": "mortel"}
const CAPTIF := ["captif", "captive", "esclave", "sous contrat", "contrat de dette"]

var monde: Node3D
var lignes: Array = []


func _init(m: Node3D) -> void:
	monde = m
	lignes = Donnees.lire_csv("res://data/actions.csv")


func _liste(champ: String) -> PackedStringArray:
	return champ.replace(" ", "").split(",", false)


## Les actions possibles sur ce PNJ (pnj = nœud ou null) ou dans ce lieu.
func disponibles(pnj: Node, lieu: String) -> Array:
	var choix := {}     # id -> ligne (la plus précise gagne)
	for l in lignes:
		var sur_pnj: bool = l.cible == "pnj"
		if sur_pnj != (pnj != null):
			continue
		if l.lieux != "*" and not _liste(l.lieux).has(lieu):
			continue
		var precise := false
		if sur_pnj and l.pnj != "*":
			if not _liste(l.pnj).has(pnj.id):
				continue
			precise = true
		if l.intime == "1" and not intime_possible(pnj):
			continue
		if l.id in COMBATS and (pnj == null or int(pnj.donnees.get("age", "0")) < AGE_ADULTE):
			continue
		if not choix.has(l.id) or precise:
			choix[l.id] = l
	return choix.values()


## Les garde-fous des actions intimes. Faux = l'action n'apparaît même pas.
func intime_possible(pnj: Node) -> bool:
	if pnj == null:
		return false
	var d: Dictionary = pnj.donnees
	if int(d.get("age", "0")) < AGE_ADULTE:
		return false
	var profil := str(d.get("profil_intime", "")).strip_edges()
	if profil == "" or profil == "—":
		return false
	var statut := str(d.get("statut_social", "")).to_lower()
	for mot in CAPTIF:
		if statut.contains(mot):
			return false
	if monde.enfant_proche(monde.joueur.pos2d()):
		return false
	return true


func executer(l: Dictionary, pnj: Node, lieu: String) -> void:
	var texte := str(l.description)
	var cles := [lieu]
	if pnj != null:
		cles = [pnj.id, lieu]
		var aff: int = monde.relations.get(pnj.id, 0)
		if aff < int(l.affection_min):
			_refus(l, pnj, cles)
			return
		monde.relations[pnj.id] = clampi(aff + int(l.effet_affection), -100, 100)
	if texte.strip_edges() == "":
		texte = "%s (texte à écrire dans data/actions.csv)" % l.nom
	if l.intime == "1":
		texte += "\n\nÉchap : arrêter."
	texte = _remplacer(texte, pnj, lieu)
	Horloge.avancer(float(l.duree_min))
	Illustrations.montrer(l.id, cles, texte)
	if COMBATS.has(l.id):
		await Illustrations.ferme
		monde.combat_contre_pnj(pnj, COMBATS[l.id])


func _refus(l: Dictionary, pnj: Node, cles: Array) -> void:
	var texte := "%s refuse. Tu n'insistes pas." % pnj.donnees.get("nom", "")
	if l.intime == "1":
		texte = "%s te regarde et secoue la tête : « Non. » C'est non." % pnj.donnees.get("nom", "")
	Illustrations.montrer(l.id + "_refus", cles, texte)


func _remplacer(t: String, pnj: Node, lieu: String) -> String:
	if pnj != null:
		t = t.replace("{nom}", pnj.donnees.get("nom", ""))
		t = t.replace("{activite}", pnj.activite)
		var parole := str(pnj.donnees.get("parole", ""))
		var a := parole.find("«")
		var b := parole.rfind("»")
		if a >= 0 and b > a:
			parole = parole.substr(a + 1, b - a - 1).strip_edges()
		t = t.replace("{parole}", parole)
	if monde.lieux.has(lieu):
		t = t.replace("{lieu}", monde.lieux[lieu].nom)
	return t
