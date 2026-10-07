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
#   prix            ce que ça coûte : « 1 argent », « 3 cuivre », ou un objet du sac
#                   (« OBJ327 1 » : un pain de Mara). Sans ça, l'action est refusée.
#   donne           ce que ça rapporte, séparé par des virgules : « cuivre 6 », « BRV003 2 »
#                   (un objet de data/objets.csv), « repos » (tous les PV),
#                   « boutique » / « vente » (ouvre le marchand), « lame_sans_nom »,
#                   « chasse_rats » (les rats géants de la cave, une fois par jour, payé si tu gagnes),
#                   « vol_tire » (le Voleur fait les poches : réussir dépend de l'Agi et des témoins)
#
# Travailler, pêcher, cueillir font avancer le métier lié au lieu (data/metiers.csv) :
# une journée (8 h) pour devenir apprenti, deux fois plus vite si le maître est là.
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
		if l.id == "vol_tire" and (not "vol_tire" in monde.fiche.competences() or pnj == null or int(pnj.donnees.get("age", "0")) < AGE_ADULTE):
			continue
		if not choix.has(l.id) or precise:
			choix[l.id] = l
	return choix.values()


## Les garde-fous des actions intimes. Faux = l'action n'apparaît même pas.
func intime_possible(pnj: Node) -> bool:
	if pnj == null or not monde.fiche.options.get("adulte", true):
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
	var manque := _manque(str(l.get("prix", "")))
	if manque != "":
		Illustrations.montrer(l.id + "_refus", cles, manque)
		return
	_payer(str(l.get("prix", "")))
	var donne := str(l.get("donne", ""))
	if donne in ["boutique", "vente"]:
		monde.fenetres.marchand(pnj, donne == "vente")
		return
	if donne == "chasse_rats":
		if monde.fiche.drapeaux.get("rats_jour", 0) == Horloge.jour():
			Illustrations.montrer(l.id + "_refus", cles, "Rosalie secoue la tête : « Tu les as déjà chassés aujourd'hui. Ils reviendront demain, ils reviennent toujours. »")
			return
		monde.fiche.drapeaux["rats_jour"] = Horloge.jour()
		Horloge.avancer(float(l.duree_min))
		monde.attaque_de_betes("rat", 2 + randi() % 2, monde.joueur.pos2d() + Vector2(0, 4), _remplacer(texte, pnj, lieu),
			{"paie": 12, "payeur": "Rosalie", "payeur_id": "BRU011"})
		return
	if donne == "vol_tire":
		Horloge.avancer(float(l.duree_min))
		Illustrations.montrer(l.id, cles, _remplacer(_vol_tire(pnj, texte), pnj, lieu))
		return
	if pnj != null:
		var effet := int(l.effet_affection)
		if effet > 0 and monde.fiche.a("charisme"):
			effet += 1
		monde.relations[pnj.id] = clampi(monde.relations.get(pnj.id, 0) + effet, -100, 100)
		monde.sauver_etat()
	var gains := _donner(donne)
	var proposer := ""
	var id_metier := Classes.metier_pour(l.id, lieu)
	if id_metier != "":
		var t := _metier(id_metier, float(l.duree_min) / 60.0, l.id)
		if t == "propose":
			proposer = id_metier
		elif t != "":
			gains = (gains + " " + t).strip_edges()
	if gains != "":
		texte += "\n\n" + gains
	if texte.strip_edges() == "":
		texte = "%s (texte à écrire dans data/actions.csv)" % l.nom
	if l.intime == "1":
		texte += "\n\nÉchap : arrêter."
	texte = _remplacer(texte, pnj, lieu)
	Horloge.avancer(float(l.duree_min))
	Illustrations.montrer(l.id, cles, texte)
	if proposer != "":
		await Illustrations.ferme
		monde.fenetres.offre_metier(proposer)
	if COMBATS.has(l.id):
		await Illustrations.ferme
		monde.combat_contre_pnj(pnj, COMBATS[l.id])


## Ce qui manque pour payer (texte), ou "".
func _manque(prix: String) -> String:
	for morceau in prix.split(",", false):
		var m := morceau.strip_edges()
		var id := m.split(" ")[0]
		if Objets.existe(id):
			var n := int(m.split(" ")[1]) if m.split(" ").size() > 1 else 1
			if monde.fiche.nombre(id) < n:
				return "Il te faudrait %s, et tu n'en as pas." % Objets.get_(id).nom.to_lower()
		elif Objets.cuivre_de(m) > monde.fiche.bourse:
			return "Ça coûte %s, et tu n'as que %s." % [Objets.texte_prix(Objets.cuivre_de(m)), Objets.texte_prix(monde.fiche.bourse)]
	return ""


func _payer(prix: String) -> void:
	for morceau in prix.split(",", false):
		var m := morceau.strip_edges()
		var id := m.split(" ")[0]
		if Objets.existe(id):
			monde.fiche.retirer(id, int(m.split(" ")[1]) if m.split(" ").size() > 1 else 1)
		elif Objets.cuivre_de(m) > 0:
			monde.fiche.bourse -= Objets.cuivre_de(m)
	monde.fiche.sauver()


## Ajoute au sac ce que l'action rapporte ; renvoie le texte du gain.
func _donner(donne: String) -> String:
	var r := []
	var f: Fiche = monde.fiche
	for morceau in donne.split(",", false):
		var m := morceau.strip_edges().split(" ", false)
		if m.is_empty():
			continue
		var n := int(m[1]) if m.size() > 1 else 1
		if m[0] == "repos":
			f.pv = f.pv_max()
			r.append("Tu te sens reposé : %d/%d PV." % [f.pv, f.pv_max()])
		elif m[0] == "lame_sans_nom":
			r.append(_lame_sans_nom())
		elif Objets.existe(m[0]):
			if m[0] == "BRV004" and f.vie == "agriculteur":
				n *= 2
			f.ajouter(m[0], n)
			r.append("+%d %s." % [n, Objets.get_(m[0]).nom.to_lower()])
		elif m[0] in ["cuivre", "argent", "or"]:
			if m[0] == "cuivre" and f.vie == "ouvrier":
				n += 2
			var c := Objets.cuivre_de("%d %s" % [n, m[0]])
			f.bourse += c
			r.append("+%s." % Objets.texte_prix(c))
	f.sauver()
	return " ".join(r)


## Le travail fait monter le métier ; le métier rapporte un peu plus. Renvoie le texte,
## ou "propose" si on pourrait changer de métier.
func _metier(id: String, h: float, action: String) -> String:
	var f: Fiche = monde.fiche
	var m := Classes.metier(id)
	var maitre: Node = monde._pnj_par_id(m.maitre)
	var avec_maitre: bool = maitre != null and maitre.visible and not maitre.mort and maitre.pos2d().distance_to(monde.joueur.pos2d()) < 30.0
	var r := []
	if id == f.metier:
		var paie := f.bonus_metier("paie") + int(f.niveau_metier / 5.0)
		if action == "travailler" and paie > 0:
			f.bourse += paie
			r.append("+%d cuivre de métier." % paie)
		if f.bonus_metier("pain") > 0:
			f.drapeaux["heures_pain"] = f.drapeaux.get("heures_pain", 0) + 1
			if f.drapeaux.heures_pain >= f.bonus_metier("pain"):
				f.drapeaux.heures_pain = 0
				f.ajouter("OBJ327")
				r.append("Un pain pour toi.")
		for b in [["poisson", "BRV003"], ["plante", "BRV004"]]:
			if f.bonus_metier(b[0]) > 0:
				f.ajouter(b[1], f.bonus_metier(b[0]))
				r.append("+%d %s (métier)." % [f.bonus_metier(b[0]), Objets.get_(b[1]).nom.to_lower()])
	var t := f.travailler(id, h, avec_maitre)
	if t == "propose":
		f.sauver()
		return t
	if avec_maitre:
		r.append("%s te montre les gestes : tu apprends deux fois plus vite." % maitre.donnees.nom.get_slice(" ", 0))
	if t != "":
		r.append(t)
	f.sauver()
	return " ".join(r)


## Vol à la tire : Agi contre les regards. Une fois par jour et par personne.
func _vol_tire(pnj: Node, texte: String) -> String:
	var f: Fiche = monde.fiche
	var cle: String = "vol_" + pnj.id
	if f.drapeaux.get(cle, -1) == Horloge.jour():
		return "{nom} garde la main sur sa bourse aujourd'hui. Pas deux fois le même jour."
	f.drapeaux[cle] = Horloge.jour()
	var regards: Array = monde.temoins(15.0).filter(func(n): return n != pnj)
	var chance := clampi(40 + (f.stats_totales().Agi - 8) * 5 - regards.size() * 10, 10, 90)
	if randi_range(1, 100) <= chance:
		var c := randi_range(2, 12) * (2 if f.a("trouvaille") else 1)
		f.bourse += c
		f.sauver()
		return "%s\n\n+%s. Personne n'a rien vu (%d %%)." % [texte, Objets.texte_prix(c), chance]
	# pris la main dans le sac : la victime et ceux qui ont vu s'en souviendront
	monde.relations[pnj.id] = clampi(monde.relations.get(pnj.id, 0) - 30, -100, 100)
	for n in regards:
		monde.relations[n.id] = clampi(monde.relations.get(n.id, 0) - 15, -100, 100)
	monde.sauver_etat()
	var vus: Array = regards.map(func(n): return n.donnees.nom.get_slice(" ", 0))
	return "{nom} attrape ton poignet : « Au voleur ! »%s (%d %%)" % [
		(" %s %s vu." % [", ".join(vus), "l'ont" if vus.size() > 1 else "l'a"]) if vus else " Heureusement, personne d'autre n'a vu.", chance]


## creation_personnage.md : « on la trouve dans le bois de Ronceval, ou non ».
## Une chance sur trois par jour de fouille, et une seule lame.
func _lame_sans_nom() -> String:
	var f: Fiche = monde.fiche
	if f.drapeaux.has("lame_sans_nom"):
		return "Plus rien d'intéressant ici."
	if f.drapeaux.get("fouille_jour", 0) == Horloge.jour():
		return "Tu as déjà tout retourné aujourd'hui."
	f.drapeaux["fouille_jour"] = Horloge.jour()
	if randi() % 3 != 0:
		return "Rien. Peut-être qu'en revenant un autre jour…"
	f.drapeaux["lame_sans_nom"] = true
	f.ajouter("OBJ510")
	return "Sous les ronces, ta main tombe sur une poignée froide : une épée banale, sans poinçon, sans une trace de rouille. Tu gagnes la Lame sans nom (sac : touche I)."


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
