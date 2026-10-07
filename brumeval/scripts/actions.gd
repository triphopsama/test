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
#                   « vol_tire » (faire les poches : réussir dépend de l'Agi et des témoins),
#                   « crochetage », « pistage », « piege », « plongee », « maree », « soin_magie »,
#                   « feu_camp », « benir » : les compétences hors combat (voir _hors_combat)
#   competence      la compétence qu'il faut avoir pour que l'action apparaisse (Combattant.COMPETENCES),
#                   ou plusieurs au choix séparées par | ; vide : tout le monde
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
		if l.intime == "1" and not (intime_possible(pnj) if pnj != null else intime_lieu_possible()):
			continue
		if l.intime == "1" and not _intime_dispo(str(l.donne), pnj):
			continue
		if l.id in COMBATS and (pnj == null or int(pnj.donnees.get("age", "0")) < AGE_ADULTE):
			continue
		if l.id == "lecon" and monde.lecons_de(pnj).is_empty():
			continue
		if str(l.get("competence", "")) != "" and _competence_requise(l) == "":
			continue
		if l.id in ["vol_tire", "benir"] and (pnj == null or int(pnj.donnees.get("age", "0")) < AGE_ADULTE):
			continue
		if not choix.has(l.id) or precise:
			choix[l.id] = l
	return choix.values()


## Une action intime sur place (danser, travailler la nuit) : contenu adulte activé, aucun enfant à portée.
func intime_lieu_possible() -> bool:
	return monde.fiche.options.get("adulte", true) and not monde.enfant_proche(monde.joueur.pos2d())


func _de_nuit() -> bool:
	var h: float = Horloge.heure()
	return h >= 20.0 or h < 3.0


## Ce qui a du sens selon où tu en es avec ce PNJ (couple, pacte) et l'heure.
func _intime_dispo(donne: String, pnj: Node) -> bool:
	var f: Fiche = monde.fiche
	var id: String = pnj.id if pnj else ""
	match donne:
		"couple":
			return f.partenaires.get(id, "") != "couple"
		"rompre":
			return f.partenaires.get(id, "") == "couple"
		"pacte_maitre", "pacte_esclave":
			return not f.pactes.has(id)
		"rompre_pacte":
			return f.pactes.has(id)
		"danser", "courtisan":
			return _de_nuit()
	return true


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
	if donne == "lecon":
		monde.fenetres.lecons(pnj)
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
	if donne in INTIMES:
		var res := _intime(donne, l, pnj, lieu, texte)
		if res[0] == "":
			return   # la scène prend le relais
		Horloge.avancer(float(l.duree_min))
		Illustrations.montrer(l.id + ("_refus" if res[1] else ""), cles, _remplacer(res[0], pnj, lieu))
		return
	if donne in HORS_COMBAT:
		var t := _hors_combat(donne, l, pnj, lieu, texte)
		if t == "":
			return   # l'action a lancé autre chose (un combat)
		Horloge.avancer(float(l.duree_min))
		Illustrations.montrer(l.id, cles, _remplacer(t, pnj, lieu).strip_edges())
		return
	if pnj != null:
		var effet := int(l.effet_affection)
		if effet > 0 and monde.fiche.a("charisme"):
			effet += 1
		monde.relations[pnj.id] = clampi(monde.relations.get(pnj.id, 0) + effet, -100, 100)
		monde.sauver_etat()
	var gains := _donner(donne)
	if l.id == "pecher" and Horloge.maintenant() - float(monde.fiche.drapeaux.get("maree_lue", -99999.0)) < 3 * 3600.0:
		monde.fiche.ajouter("BRV003", 2)
		gains += " +2 maquereaux : tu avais lu la marée."
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
			f.mana = f.mana_max()
			r.append("Tu te sens reposé : %d/%d PV, %d mana." % [f.pv, f.pv_max(), f.mana])
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
		if action in ["travailler", "travailler_nuit"] and paie > 0:
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


const INTIMES := ["seduire", "embrasser", "nuit", "gouts", "masser", "couple", "rompre", "pacte_maitre", "pacte_esclave",
	"rompre_pacte", "danser", "courtisan"]


## L'intime (intime.gd). Renvoie [texte, refusé ?] ; ["", false] si la scène de nuit s'ouvre.
## texte : la description de data/actions.csv (à toi de l'écrire) ; sinon un texte suggéré.
func _intime(quoi: String, l: Dictionary, pnj: Node, lieu: String, texte: String) -> Array:
	var f: Fiche = monde.fiche
	var demande := {"seduire": "seduire", "embrasser": "embrasser", "nuit": "nuit", "gouts": "seduire", "masser": "embrasser", "couple": "couple"}
	if demande.has(quoi):
		var raison := Intime.consentement(monde, pnj, demande[quoi])
		if raison != "":
			return [raison, true]
	var id: String = pnj.id if pnj else ""
	var r := ""
	match quoi:
		"seduire":
			monde.desirs[id] = mini(100, Intime.desir(monde, id) + 15)
			monde.relations[id] = mini(100, monde.relations.get(id, 0) + 2)
			f.desir = mini(100, f.desir + 5)
			r = texte if texte != "" else "Un regard qui dure, un sourire qui en dit plus. {nom} ne détourne pas les yeux."
		"embrasser":
			monde.desirs[id] = mini(100, Intime.desir(monde, id) + 10)
			monde.relations[id] = mini(100, monde.relations.get(id, 0) + 3)
			f.desir = mini(100, f.desir + 10)
			r = texte if texte != "" else "Un baiser. Puis un autre. Le monde autour peut attendre."
		"nuit":
			monde.scene_intime([pnj], lieu)
			return ["", false]
		"gouts":
			r = Intime._reveler(monde, pnj, Intime.profil(id), "lecture_envies" in f.competences())
		"masser":
			if not _une_fois("massage_" + id):
				return ["{nom} sourit : « Demain. Mes épaules s'en souviennent encore. »", true]
			var aime: bool = "massage" in Intime.profil(id).aime
			monde.relations[id] = mini(100, monde.relations.get(id, 0) + (8 if aime else 4))
			monde.desirs[id] = mini(100, Intime.desir(monde, id) + 10)
			r = texte if texte != "" else ("Tes mains sur ses épaules, sa nuque. {nom} ferme les yeux." + (" Exactement ce qu'il fallait." if aime else ""))
		"couple":
			r = Intime.devenir_couple(monde, pnj)
		"rompre":
			f.partenaires.erase(id)
			var perte := 35 if Intime.profil(id).jalousie >= 70 else 20
			monde.relations[id] = clampi(monde.relations.get(id, 0) - perte, -100, 100)
			r = "Tu le dis comme tu peux. {nom} encaisse (−%d)." % perte
		"pacte_maitre", "pacte_esclave":
			var role := "maitre" if quoi == "pacte_maitre" else "esclave"
			r = Intime.pacte(monde, pnj, role)
			if not f.pactes.has(id):
				return [r, true]
		"rompre_pacte":
			f.pactes.erase(id)
			monde.relations[id] = clampi(monde.relations.get(id, 0) - 5, -100, 100)
			r = "Le jeu s'arrête là, d'un commun accord. Rien d'autre ne change entre vous."
		"danser":
			if not _une_fois("danse"):
				return ["Tu as déjà dansé ce soir. Les jambes ne suivent plus.", true]
			var regards: Array = monde.temoins(15.0).filter(func(n): return int(n.donnees.get("age", "0")) >= 18)
			var c := randi_range(4, 12) + regards.size() * 2
			f.bourse += c
			for n in regards:
				if Intime.profils().has(n.id):
					monde.desirs[n.id] = mini(100, Intime.desir(monde, n.id) + 15)
					if Intime.profil(n.id).pudeur >= 70:
						monde.relations[n.id] = clampi(monde.relations.get(n.id, 0) - 2, -100, 100)
			r = (texte if texte != "" else "La musique, les regards, la chaleur de la salle. Tu danses, et la taverne se tait.") + " +%s de pourboires." % Objets.texte_prix(c)
		"courtisan":
			var c := 10 + 3 * Intime.maitrise_art(f) + (4 if "seduction" in f.competences() else 0)
			f.bourse += c
			f.drapeaux["art_xp"] = int(f.drapeaux.get("art_xp", 0)) + 1
			r = (texte if texte != "" else "Une heure avec un marin de passage, qui paie ce qui était convenu.") + " +%s." % Objets.texte_prix(c)
			var t := _metier("courtisan", 1.0, "travailler_nuit")
			if t != "" and t != "propose":
				r += " " + t
			var bruit := Intime.rumeur(monde, [], "ton métier de nuit")
			if bruit != "":
				r += "\n\n" + bruit
	monde.sauver_etat()
	f.sauver()
	return [r, false]


const HORS_COMBAT := ["crochetage", "pistage", "piege", "plongee", "maree", "soin_magie", "feu_camp", "benir"]


## La compétence (parmi celles demandées) que le joueur sait utiliser, "" sinon.
func _competence_requise(l: Dictionary) -> String:
	var a: Array = monde.fiche.competences()
	for k in str(l.get("competence", "")).split("|", false):
		if k in a:
			return k
	return ""


## Une fois par jour (par lieu ou par personne) : vrai si c'est encore possible, et le note.
func _une_fois(cle: String) -> bool:
	var f: Fiche = monde.fiche
	if f.drapeaux.get(cle, -1) == Horloge.jour():
		return false
	f.drapeaux[cle] = Horloge.jour()
	return true


## Les compétences hors combat. Renvoie le texte à montrer ("" si un combat prend le relais).
func _hors_combat(quoi: String, l: Dictionary, pnj: Node, lieu: String, texte: String) -> String:
	var f: Fiche = monde.fiche
	var t := f.stats_totales()
	var r := ""
	match quoi:
		"crochetage":
			if not _une_fois("crochet_" + lieu):
				return "Tu as déjà forcé cette serrure aujourd'hui. Mieux vaut ne pas tenter le sort."
			var regards: Array = monde.temoins(20.0)
			var chance := clampi(30 + (t.Agi - 10) * 6 - regards.size() * 15, 5, 90)
			if randi_range(1, 100) > chance:
				for n in regards:
					monde.relations[n.id] = clampi(monde.relations.get(n.id, 0) - 15, -100, 100)
				monde.sauver_etat()
				var vus: Array = regards.map(func(n): return n.donnees.nom.get_slice(" ", 0))
				return "Le crochet ripe, la serrure tient bon (%d %%).%s" % [chance,
					(" Et %s %s vu faire." % [", ".join(vus), "t'ont" if vus.size() > 1 else "t'a"]) if vus else ""]
			var c := randi_range(4, 20) if lieu == "falaise" else randi_range(12, 30)
			f.bourse += c
			r = "%s

Derrière : %s (%d %%)." % [texte, Objets.texte_prix(c), chance]
			if lieu == "comptoir":
				r += " L'argent de Silas. S'il l'apprend, il ne pardonnera pas."
		"pistage":
			if not _une_fois("pistage_" + lieu):
				return "Tu as déjà suivi toutes les traces fraîches d'ici aujourd'hui."
			var chance := clampi(40 + (t.Per - 8) * 6, 10, 95)
			if randi_range(1, 100) > chance:
				return "%s

Les traces se mêlent et se perdent dans les fougères (%d %%)." % [texte, chance]
			var bete := "sanglier" if lieu == "landes" or randf() < 0.35 else "loup"
			var p: Vector2 = monde.joueur.pos2d() + Vector2(3, 3)
			monde.attaque_de_betes(bete, 1, p, "%s

Une piste fraîche : %s. Tu le trouves avant qu'il ne te trouve (%d %%)." % [
				texte, "un sanglier, seul" if bete == "sanglier" else "un loup isolé", chance], {"betes": bete})
			return ""
		"piege":
			var pose: int = f.drapeaux.get("piege_" + lieu, -1)
			if pose < 0:
				f.drapeaux["piege_" + lieu] = Horloge.jour()
				r = "Tu tends deux collets sur les passages de bêtes, bien cachés sous les feuilles. Reviens demain."
			elif pose == Horloge.jour():
				r = "Tes collets sont posés. Ils ont besoin d'une nuit."
			else:
				f.drapeaux.erase("piege_" + lieu)
				var chance := clampi(45 + (t.Int - 8) * 5, 10, 90)
				if randi_range(1, 100) <= chance:
					var prise := "BRV021" if randf() < 0.4 else "OBJ407"
					f.ajouter(prise)
					r = "Un des collets a pris : %s (%d %%)." % [Objets.get_(prise).nom.to_lower(), chance]
				else:
					r = "Les collets sont vides, l'un est rongé. Un renard plus malin que toi (%d %%)." % chance
		"plongee":
			if not _une_fois("plongee_" + lieu):
				return "Tu as déjà fouillé le fond ici aujourd'hui. Le froid te rentre dans les os."
			var c := randi_range(2, 10)
			f.bourse += c
			r = "%s

Tu remontes %s de pièces verdies." % [texte, Objets.texte_prix(c)]
			if randf() < 0.2:
				f.ajouter("BRV020")
				r += " Et une vieille carapace de crabe-rocher, vide."
		"maree":
			var bm: Array = Horloge.basses_mers()
			f.drapeaux["maree_lue"] = Horloge.maintenant()
			r = "%s

Basse mer à %s, puis à %s. Les poissons monteront avec le flot : pêche dans les trois heures, ça mordra." % [
				texte, Horloge.texte_heure(bm[0]), Horloge.texte_heure(fposmod(bm[1], 24.0))]
		"soin_magie":
			var k := _competence_requise(l)
			var comp: Dictionary = Combattant.COMPETENCES[k]
			var cout := int(comp.get("mana", 0))
			if f.mana_actuelle() < cout:
				return "Pas assez de mana (%d, il en faut %d). Dors, ou attends une heure." % [f.mana_actuelle(), cout]
			f.mana = f.mana_actuelle() - cout
			var soin := roundi(comp.soin * t[comp.stat] * (1.0 + maxf(0, f.affinite("lumière") - 50) / 100.0 if comp.has("element") else 1.0))
			if pnj == null:
				var avant := f.pv
				f.pv = mini(f.pv_max(), f.pv + soin)
				r = "%s : tes plaies se referment, +%d PV (%d/%d)." % [comp.nom, f.pv - avant, f.pv, f.pv_max()]
			elif not _une_fois("soin_" + pnj.id):
				r = "Tu as déjà soigné {nom} aujourd'hui. Ses bobos attendront demain."
			else:
				var gain := 4
				r = "%s : tu poses les mains sur {nom}. Les petites douleurs s'en vont, {nom} te regarde autrement." % comp.nom
				if pnj.id == "BRU002":
					gain = 10   # ses mains qui tremblent, qu'il cache à tout le monde
					r = "%s : tu prends les mains de Bram. Elles tremblent. Sous la chaleur du sort, elles se calment un moment. Il retire les siennes, gêné : « T'as rien vu. »" % comp.nom
				monde.relations[pnj.id] = clampi(monde.relations.get(pnj.id, 0) + gain, -100, 100)
				monde.sauver_etat()
			if cout > 0:
				r += " (−%d mana)" % cout
		"feu_camp":
			if not _une_fois("feu_camp"):
				return "Tu as déjà fait un feu aujourd'hui. Le bois sec manque."
			var avant := f.pv
			f.pv = mini(f.pv_max(), f.pv + maxi(1, f.pv_max() / 4))
			f.pratiquer_element("feu", 1)
			r = "%s Tu te réchauffes une heure : +%d PV (%d/%d)." % [texte, f.pv - avant, f.pv, f.pv_max()]
		"benir":
			if f.mana_actuelle() < 6:
				return "Pas assez de mana pour bénir (il en faut 6)."
			if not _une_fois("benir_" + pnj.id):
				return "Tu as déjà béni {nom} aujourd'hui."
			f.mana = f.mana_actuelle() - 6
			var pieux := str(pnj.donnees.get("traits", "")).contains("pieux +")
			var gain := 6 if pieux else 2
			monde.relations[pnj.id] = clampi(monde.relations.get(pnj.id, 0) + gain, -100, 100)
			monde.sauver_etat()
			r = "Tu traces le signe de la Pâle sur le front de {nom}. %s" % ("Ses yeux brillent : « Que les Astres te le rendent. »" if pieux else "{nom} hausse les épaules, mais ne dit pas non.")
	f.sauver()
	return r


## Vol à la tire : Agi contre les regards. Une fois par jour et par personne.
func _vol_tire(pnj: Node, texte: String) -> String:
	var f: Fiche = monde.fiche
	if not _une_fois("vol_" + pnj.id):
		return "{nom} garde la main sur sa bourse aujourd'hui. Pas deux fois le même jour."
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
