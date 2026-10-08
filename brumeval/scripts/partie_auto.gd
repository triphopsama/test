# Une partie jouée toute seule, du réveil au soir du jour 3 : godot --headless -- --partie=heros
# (heros, complice, captif, pierrefane, rien). Un personnage neuf, l'horloge au jour 1 à 6 h, un
# itinéraire (où être, à quelle heure), une personnalité (quels choix préférer), et le monde qui
# tourne : les scènes se déclenchent toutes seules, les combats se jouent seuls. Le journal dit tout
# ce qui s'est passé, puis le bilan des fils au soir du jour 3.
extends Node

var monde: Node3D
var profil := "heros"

const PAS_MIN := 5.0
var _dernier_but: Array = []
const JOURS := 3

## L'itinéraire : [jour, heure, carte, lieu]. On est au dernier point dont l'heure est passée.
const ROUTES := {
	"heros": [
		[1, 6.0, "brumeval", "chene"], [1, 6.4, "brumeval", "agnes"], [1, 7.2, "brumeval", "boulangerie"],
		[1, 9.2, "brumeval", "moulin"], [1, 10.9, "brumeval", "forge"], [1, 12.1, "brumeval", "port"],
		[1, 14.0, "brumeval", "chapelle"], [1, 14.45, "brumeval", "plage"], [1, 14.95, "brumeval", "place"],
		[1, 17.45, "brumeval", "forge"], [1, 17.95, "brumeval", "taverne"], [1, 21.0, "brumeval", "chapelle"],
		[1, 21.5, "brumeval", "bouche"], [1, 22.5, "brumeval", "falaise"], [1, 23.1, "brumeval", "crique"],
		[2, 0.1, "brumeval", "falaise"], [2, 5.5, "brumeval", "comptoir"], [2, 6.0, "brumeval", "agnes"],
		[2, 7.0, "brumeval", "boulangerie"], [2, 7.95, "brumeval", "moulin"], [2, 8.95, "brumeval", "boulangerie"],
		[2, 10.0, "brumeval", "bouche"], [2, 11.95, "brumeval", "forge"], [2, 12.95, "brumeval", "port"],
		[2, 13.95, "brumeval", "chapelle"], [2, 14.45, "brumeval", "plage"], [2, 14.95, "brumeval", "place"],
		[2, 15.95, "brumeval", "ferme"], [2, 16.45, "brumeval", "agnes"], [2, 19.95, "brumeval", "taverne"],
		[2, 22.0, "brumeval", "bouche"], [2, 23.45, "brumeval", "moulin"],
		[3, 0.0, "brumeval", "guet"], [3, 6.0, "brumeval", "taverne"], [3, 7.45, "brumeval", "boulangerie"],
		[3, 8.45, "brumeval", "place"], [3, 8.95, "brumeval", "port"], [3, 9.45, "brumeval", "chapelle"],
		[3, 9.95, "brumeval", "agnes"], [3, 10.95, "brumeval", "moulin"], [3, 11.95, "brumeval", "forge"],
		[3, 13.95, "brumeval", "falaise"], [3, 17.45, "brumeval", "boulangerie"], [3, 17.95, "brumeval", "plage"],
		[3, 19.45, "brumeval", "mairie"], [3, 21.95, "brumeval", "taverne"], [3, 22.95, "brumeval", "crique"]],
	"complice": [
		[1, 6.0, "brumeval", "reveil"], [1, 8.4, "brumeval", "boulangerie"], [1, 10.9, "brumeval", "forge"],
		[1, 17.95, "brumeval", "taverne"], [1, 22.7, "brumeval", "crique"],
		[2, 7.95, "brumeval", "comptoir"], [2, 11.0, "pierrefane", "lanternes"], [2, 19.95, "pierrefane", "lanternes"],
		[3, 6.0, "pierrefane", "sentier"], [3, 9.5, "brumeval", "place"], [3, 22.45, "brumeval", "comptoir"],
		[3, 22.95, "brumeval", "crique"]],
	"captif": [
		[1, 6.0, "brumeval", "reveil"], [1, 12.0, "brumeval", "place"], [1, 23.1, "brumeval", "crique"],
		[2, 11.0, "pierrefane", "lanternes"]],
	"pierrefane": [
		[1, 6.0, "pierrefane", "chantier"], [1, 9.45, "pierrefane", "entrepot"],
		[1, 11.95, "pierrefane", "jetee"], [1, 12.95, "pierrefane", "prevot"], [1, 13.95, "pierrefane", "chapelle"],
		[1, 14.95, "pierrefane", "auberge"], [1, 15.95, "pierrefane", "lanternes"], [1, 16.95, "pierrefane", "mahaut"],
		[1, 19.95, "pierrefane", "lanternes"], [1, 22.95, "pierrefane", "hangar"],
		[2, 6.95, "pierrefane", "entrepot"], [2, 8.95, "pierrefane", "prevot"], [2, 10.6, "pierrefane", "port"],
		[2, 10.95, "pierrefane", "lanternes"], [2, 11.7, "pierrefane", "auberge"], [2, 12.95, "pierrefane", "lanternes"],
		[2, 15.95, "pierrefane", "lanternes"], [2, 20.95, "pierrefane", "jetee"], [2, 22.95, "pierrefane", "hangar"],
		[3, 6.95, "pierrefane", "entrepot"], [3, 7.95, "pierrefane", "lande"], [3, 8.95, "pierrefane", "hangar"],
		[3, 10.95, "pierrefane", "lanternes"], [3, 12.45, "pierrefane", "prevot"], [3, 13.95, "pierrefane", "lanternes"],
		[3, 16.95, "pierrefane", "port"], [3, 17.95, "pierrefane", "lanternes"]],
	"rien": [[1, 6.0, "brumeval", "reveil"]],
}

## La personnalité : les mots des choix qu'il préfère, dans l'ordre.
const GOUTS := {
	"heros": ["Répondre calmement", "Entrer", "Proposer ton aide", "Conseiller à Mara", "déconseiller", "Proposer un partage",
		"« Il te doit", "Parler à Tim", "Parler au verrier", "Lui proposer ton aide", "Dire que tu en es", "La cacher",
		"Garder le secret", "Écouter", "Faire le guet", "Défendre", "Monter la rejoindre", "Compter", "L'aider, et la cacher",
		"Intervenir en parlant", "Ne rien lui demander", "Lui promettre", "Lui apporter le grain", "Approcher", "Crocheter", "Demander à Lucas", "Envoyer Nina",
		"La récupérer", "Lui demander de rester", "Soutenir Ysolde", "Venir avec eux", "Faire la paix", "Confirmer",
		"Lui dire ce que vous", "Leur parler du Passeur", "Lui dire la vérité", "Encourager", "L'encourager", "Regarder",
		"Témoigner", "Faire campagne", "Distribuer", "Payer la miche", "Prendre la faute", "Parler pour elle", "Lui conseiller de dire",
		"Les présenter", "Leur expliquer", "Te montrer", "Lui parler de Léa", "Plaider", "Leur dire l'heure",
		"Faire sortir Gaëlle", "Sauver Lucas", "L'empêcher", "Partir sans bruit", "Décliner", "Ouvrir le collier"],
	"complice": ["Proposer tes services", "Te moquer", "Les dénoncer", "Lui proposer tes services", "Porter", "Aider Silas",
		"Monter sur la charrette", "Regarder sans rien dire", "L'encourager", "Vendre l'information", "Y aller",
		"Garder un tonneau", "Soutenir Silas", "La porter sans l'ouvrir", "Accepter", "Partir sans bruit", "Décliner"],
	"captif": ["Te battre", "Lui parler, à elle", "Attendre", "Te laisser examiner", "Prendre le double", "Fuir avec Lysa, Bastien",
		"Fuir par la lande", "Crocheter les colliers", "Partir sans bruit", "Décliner"],
	"pierrefane": ["Plonger", "Demander cette farine", "T'asseoir à côté", "Garder ce que tu as entendu", "Regarder par la fenêtre",
		"Ne pas lui mentir", "Jouer aux dés", "Lui dire ce que tu as entendu", "Parler doucement", "Faire diversion",
		"Aider à pousser", "Lui montrer ce que tu sais", "Faire payer ton silence", "L'arrêter avec Kael",
		"Faire venir le prévôt", "Enchérir", "Regarder la bourse", "Le lire", "Parler à Lysa", "Proposer d'avancer",
		"Rien", "Arriver avant elle", "T'interposer", "Courir avec eux", "La laisser sous le plancher", "Rester près",
		"Ramener", "Le dire à Ondine", "L'arrêter", "Lui dire ce qu'Orsoline", "Fuir avec Lysa, Bastien, et elle",
		"Fuir par la lande", "Ouvrir le collier", "Partir sans bruit", "Décliner"],
	"rien": ["Ne rien faire", "Partir sans bruit", "Décliner"],
}
const PAR_DEFAUT := ["Ne rien faire", "Partir sans bruit", "Décliner", "Garder", "Plus tard", "Rien", "Laisser"]


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not monde.fiche.drapeaux.has("partie_auto"):
		_commencer()
		_arriver(ROUTES[profil][0][2])     # le monde se rouvre, neuf : rien de l'ancienne sauvegarde ne traîne
		return
	else:
		print("[partie] (la carte change : %s, jour %d, %s)" % [monde.carte, Horloge.jour(), Horloge.texte_heure()])
	await _jouer()


## Un personnage neuf, au réveil du jour 1.
func _commencer() -> void:
	var f := Fiche.new()
	f.drapeaux["cree"] = true
	f.drapeaux["partie_auto"] = profil
	f.sexe = "homme"
	for s in f.stats:
		f.stats[s] = 10
	match profil:
		"heros":
			f.stats.Int = 13
			f.stats.Per = 13
			f.stats.Agi = 12
		"captif":
			f.peuple = "homme_bete"
			f.stats.For = 6
			f.stats.Agi = 6
		"pierrefane":
			f.tenue = "ailleurs"
			f.ajouter("BRV011")
			f.ajouter("BRV017")
			f.stats.End = 13
	monde.fiche = f
	monde.desirs.clear()
	monde.morts.clear()
	monde.nouvelle_vie()
	Horloge.aller_a(1, 6.0)
	f.drapeaux["repas"] = Horloge.maintenant()
	f.drapeaux["reveil"] = Horloge.maintenant()
	f.sauver()
	print("[partie] ===== %s : un personnage neuf se réveille au bois de Ronceval, jour %d, %s =====" % [profil, Horloge.jour(), Horloge.texte_heure()])


## Du bois de Ronceval au sentier côtier (3 h de marche), puis le monde se recharge autour du personnage neuf.
func _arriver(vers: String) -> void:
	var f: Fiche = monde.fiche
	f.drapeaux["carte"] = vers
	f.drapeaux["arrivee"] = vers
	Horloge.avancer(monde.VOYAGE_MIN)
	monde.sauver_etat()
	f.sauver()
	print("[partie] -> le sentier côtier, vers %s" % vers)
	get_tree().reload_current_scene()


## Une image ; faux si la scène s'est rechargée entre-temps (un voyage) : la nouvelle partie_auto prend la suite.
func _attendre() -> bool:
	if not is_inside_tree():
		return false
	await get_tree().process_frame
	return is_inside_tree()


func _jouer() -> void:
	var garde := 0
	while Horloge.jour() <= JOURS:
		if not is_inside_tree():
			return     # la scène s'est rechargée (voyage) : la nouvelle partie_auto prend la suite
		garde += 1
		if garde > 20000:
			print("[partie] ÉCHEC : la partie tourne en rond")
			break
		if Illustrations.ouvert:
			var t: String = Illustrations._texte.text
			print("[partie]   j%d %s · %s" % [Horloge.jour(), Horloge.texte_heure(), t.left(160).replace("\n", " ")])
			Illustrations.fermer()
			if not await _attendre():
				return
			continue
		if monde.fenetres.ouvert == "choix":
			_choisir()
			if not await _attendre():
				return
			continue
		if monde.fenetres.ouvert != "":
			monde.fenetres.fermer()
			if not await _attendre():
				return
			continue
		if monde.combat != null:
			monde.combat.auto = true
			if not await _attendre():
				return
			continue
		if _aller():
			return     # la carte change : la scène se recharge, une nouvelle partie_auto prend la suite
		Scenes.surveiller(monde, 1.0)
		if not await _attendre():
			return
		if not await _attendre():
			return
		if not Illustrations.ouvert and monde.fenetres.ouvert == "" and monde.combat == null:
			Horloge.avancer(PAS_MIN)
	_bilan()


## Va où l'itinéraire le dit. Vrai si la carte change (on voyage).
func _aller() -> bool:
	var j: int = Horloge.jour()
	var h: float = Horloge.heure()
	var but: Array = []
	for etape in ROUTES[profil]:
		if etape[0] < j or (etape[0] == j and etape[1] <= h):
			but = etape
	if but.is_empty():
		return false
	if Captif.est(monde):
		return false     # captif : on ne choisit pas où on va
	if but[2] != monde.carte:
		print("[partie] -> le sentier côtier, vers %s (j%d %s)" % [but[2], j, Horloge.texte_heure()])
		monde.voyager(but[2])
		return true
	if not monde.lieux.has(but[3]):
		return false
	if but != _dernier_but:
		_dernier_but = but
		print("[partie] -> %s (j%d %s)" % [but[3], j, Horloge.texte_heure()])
	var p: Vector2 = monde.lieux[but[3]].pos + Vector2(2, 4)
	if monde.joueur.pos2d().distance_to(p) > 12.0:
		monde.joueur.position = Vector3(p.x, monde.hauteur(p.x, p.y), p.y)
	return false


func _choisir() -> void:
	var options: Array = monde.fenetres.options_choix
	if options.is_empty():
		monde.fenetres.fermer()
		return
	var choisie = null
	for mot in GOUTS.get(profil, []) + PAR_DEFAUT:
		for o in options:
			if str(o[0]).to_lower().contains(str(mot).to_lower()):
				choisie = o
				break
		if choisie != null:
			break
	if choisie == null:
		choisie = options[options.size() - 1]
	print("[partie]   j%d %s · « %s » : %s" % [Horloge.jour(), Horloge.texte_heure(), monde.fenetres._titre.text, choisie[0]])
	monde.fenetres._choisir_option(choisie[1])


func _bilan() -> void:
	var f: Fiche = monde.fiche
	print("[partie] ===== %s : fin du jour %d =====" % [profil, JOURS])
	var vues := f.drapeaux.keys().filter(func(k): return str(k).begins_with("scene_"))
	print("[partie] scènes vues : %d" % vues.size())
	var fils := f.drapeaux.keys().filter(func(k): return str(k).begins_with("fil_"))
	fils.sort()
	print("[partie] fils : " + ", ".join(fils.map(func(k): return "%s=%s" % [str(k).trim_prefix("fil_"), f.drapeaux[k]])))
	print("[partie] Vesperine : %s · toi : %s · carte : %s · bourse : %s · PV %d/%d · niveau %d" % [
		Vesperine.etat(monde), Scenes.fil(monde, "captif"), monde.carte, Objets.texte_prix(f.bourse), f.pv, f.pv_max(), f.niveau])
	var amis := []
	for id in monde.relations:
		if absi(int(monde.relations[id])) >= 15:
			amis.append("%s %+d" % [Donnees.prenom(str(monde.pnj_donnees.get(id, Vesperine.DONNEES if id == Vesperine.ID else {}).get("nom", id))), monde.relations[id]])
	print("[partie] ce qu'ils pensent de toi : " + ", ".join(amis))
	print("[partie] ragots : " + Liens.ragots(monde).replace("\n", " | ").left(400))
	print("[partie] absents : " + ", ".join(["BRU009", "BRU010", "BRU017", "BRU021"].filter(func(id): return not monde.present(id))))
	f.drapeaux.erase("partie_auto")
	f.sauver()
	print("[partie] FIN")
	get_tree().quit()
