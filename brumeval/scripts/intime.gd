# L'intime entre adultes consentants (univers.md, « Désir et sexualité »).
#
# data/intime.csv : un profil par PNJ adulte (tiré de pnj.csv par outils/intime.py, réglable à la main)
#   attire      hommes, femmes (ce qui l'attire)
#   cherche     amour, plaisir, aventure, sécurité, statut, fidélité, passion, paix…
#   libido      0 à 100 : son désir monte de libido/10 par heure, retombe quand il est comblé
#   axe         -100 (très soumis) à +100 (très dominant)
#   pudeur      0 à 100 : refuse plus souvent devant témoins ou l'inconnu
#   experience  vierge, peu, experimente
#   bdsm        0 à 100 : intérêt pour les jeux de pouvoir (toujours consentis, avec un mot d'arrêt)
#   partage     0 à 100 : accepte un harem, une nuit à plusieurs (50 et plus)
#   jalousie    0 à 100 : ce que lui coûte de te savoir avec d'autres
#   couple      id du PNJ avec qui il est (on ne trompe pas sans conséquence)
#   aime        étiquettes qu'il aime ; talents : ce qu'il fait très bien ; refuse : ses limites
#   endurance   combien de fois il peut être comblé dans une nuit avant d'être épuisé
#   bruit       0 à 100 : une nuit bruyante s'entend, et la rumeur part plus facilement
#   fantasme    une étiquette qu'il n'avoue qu'à qui il aime (affection 70) ; la vivre vaut beaucoup
#   prefere     ce qu'il aime chez l'autre : grande, petite, mince, athletique, musclee, ronde,
#               sexe_grand, poitrine_genereuse… (le corps du joueur : fiche, C)
#   ages        plus_jeune (une cougar, un homme mûr qui aime la jeunesse) ou plus_vieux ;
#               toujours entre majeurs
#   fige        1 : outils/intime.py ne réécrit plus cette ligne
#
# Étiquettes : mots_doux, conversation, rire, baisers, tendresse, massage, lenteur, rapide,
# passion, jeu, roleplay, risque, audace, oral, dominer, etre_domine, nuit_entiere, dehors,
# cadeaux, doigts, poitrine, chevaucher, derriere, debout, anal, jouet, bain, mots_crus,
# cordes, douleur_douce ; limites : public, brutal, groupe, infidelite, moquerie, engagement,
# pitie, jalousie (ou n'importe quelle étiquette ci-dessus).
# Tu peux en inventer : un geste de data/gestes.csv qui porte l'étiquette la fait jouer.
#
# Les règles fixes (dans le code, quoi qu'il y ait dans les fichiers) :
#   - adultes seulement, jamais si un enfant est à portée, jamais avec un captif ou un esclave ;
#   - le consentement se demande, selon l'affection, le désir, l'attirance, la pudeur, le couple ;
#   - le malaise ou l'intensité au-delà de ses limites, et c'est le mot d'arrêt : tout s'arrête ;
#   - le pacte maître/esclave est un jeu convenu entre adultes, révocable, jamais un statut.
class_name Intime
extends RefCounted

const SEUILS := {"seduire": 30, "embrasser": 40, "risque": 55, "nuit": 60, "groupe": 65, "couple": 70, "pacte": 75}
## Le risque d'être surpris, à chaque geste, dans un lieu exposé.
const RISQUE_SURPRIS := 0.08
const MOT_D_ARRET := "Brume"
## Les étiquettes qui gênent quand on ne les aime pas.
const OSE := ["anal", "douleur_douce", "mots_crus", "jouet", "cordes", "derriere"]

static var _profils := {}
static var _gestes := []


static func _liste(t: String) -> Array:
	return Array(t.replace(" ", "").split(",", false))


static func profils() -> Dictionary:
	if _profils.is_empty():
		for l in Donnees.lire_csv("res://data/intime.csv"):
			for k in ["attire", "cherche", "aime", "talents", "refuse", "prefere"]:
				l[k] = _liste(l.get(k, ""))
			for k in ["libido", "axe", "pudeur", "bdsm", "partage", "jalousie"]:
				l[k] = int(l[k])
			l.endurance = maxi(1, int(l.get("endurance", "1")))
			l.bruit = int(l.get("bruit", "30"))
			l.fantasme = str(l.get("fantasme", ""))
			l.ages = str(l.get("ages", ""))
			l.couple_depart = str(l.get("couple", ""))   # liens.gd change « couple » au fil des jours
			_profils[l.id] = l
	return _profils


static func profil(id: String) -> Dictionary:
	return profils().get(id, {})


static func gestes() -> Array:
	if _gestes.is_empty():
		for l in Donnees.lire_csv("res://data/gestes.csv"):
			l.tags = _liste(l.tags)
			l.intensite = int(l.intensite)
			_gestes.append(l)
	return _gestes


static func geste(id: String) -> Dictionary:
	for g in gestes():
		if g.id == id:
			return g
	return {}


static func attire_par(p: Dictionary, f: Fiche) -> bool:
	match f.sexe.to_lower():
		"homme":
			return "hommes" in p.attire
		"femme":
			return "femmes" in p.attire
	return not p.attire.is_empty()


## Ce qu'on voit du joueur : « grande », « musclee », « sexe_grand »…
static func corps_tags(f: Fiche) -> Array:
	var c: Dictionary = f.corps
	var r := [str(c.get("taille", "")), str(c.get("silhouette", ""))]
	if f.sexe.to_lower() == "homme":
		r.append("sexe_" + str(c.get("sexe", "moyen")))
	elif f.sexe.to_lower() == "femme":
		r.append("poitrine_" + str(c.get("poitrine", "moyenne")))
	else:
		r.append("sexe_" + str(c.get("sexe", "moyen")))
		r.append("poitrine_" + str(c.get("poitrine", "moyenne")))
	return r


## Ton corps et ton âge lui plaisent-ils ? +1 (oui), 0, −1 (pas son genre d'âge).
static func a_son_gout(m: Node, pnj: Node) -> int:
	var p := profil(pnj.id)
	var f: Fiche = m.fiche
	var r := 0
	if p.prefere.any(func(t): return t in corps_tags(f)):
		r += 1
	var age_pnj := int(pnj.donnees.get("age", "30"))
	if p.ages == "plus_jeune":
		r += 1 if f.age <= age_pnj - 8 else -1
	elif p.ages == "plus_vieux":
		r += 1 if f.age >= age_pnj + 8 else -1
	return clampi(r, -1, 2)


static func desir(m: Node, id: String) -> int:
	return int(m.desirs.get(id, profil(id).get("libido", 0) / 2))


## Le désir monte avec le temps (combat.md n'en parle pas : univers.md, « le désir est un besoin »).
static func passer_temps(m: Node, heures: int) -> void:
	for id in profils():
		# au bout d'un moment à son comble, il se soulage loin de tes yeux
		if desir(m, id) >= 100 and randf() < 0.5:
			m.desirs[id] = 40
			continue
		m.desirs[id] = mini(100, desir(m, id) + int(profil(id).libido / 10.0) * heures)
	m.fiche.desir = mini(100, m.fiche.desir + 4 * heures)


## Oui ("") ou non (la raison). quoi : seduire, embrasser, nuit, groupe, couple, pacte.
## avec : les autres participants déjà là (une nuit à plusieurs).
static func consentement(m: Node, pnj: Node, quoi: String, avec: Array = []) -> String:
	var p := profil(pnj.id)
	var nom: String = Donnees.prenom(pnj.donnees.nom)
	if p.is_empty() or not m.actions.intime_possible(pnj):
		return "%s n'est pas de ceux-là, ou pas ici, pas maintenant." % nom
	var f: Fiche = m.fiche
	if f.age < 18 or int(pnj.donnees.get("age", "0")) < 18:
		return "Entre majeurs seulement."
	if str(pnj.donnees.get("detresse", "0")) == "1":
		return "%s a faim, a peur, n'a nulle part où aller. Ce n'est pas le moment, et tu le sais." % nom
	if not attire_par(p, f):
		return "%s te sourit, mais pas comme ça. Tu ne l'attires pas." % nom
	var aff: int = m.relations.get(pnj.id, 0)
	var seuil: int = SEUILS[quoi]
	if "seduction" in f.competences():
		seuil -= 10
	seuil -= int(desir(m, pnj.id) / 10.0)
	seuil -= 8 * a_son_gout(m, pnj)
	var engage: bool = f.partenaires.get(pnj.id, "") == "couple"
	if quoi == "nuit" and not engage and p.cherche.any(func(c): return c in ["amour", "fidélité", "sécurité"]):
		seuil += 15   # on ne se donne pas comme ça quand on cherche l'amour
	if aff < seuil:
		return "%s secoue doucement la tête. Pas encore (affection %d, il en faudrait %d)." % [nom, aff, seuil]
	if p.couple != "" and not m.morts.has(p.couple) and quoi != "seduire" and p.partage < 60:
		return "%s est avec quelqu'un, et n'est pas de ceux qui trompent." % nom
	var autres: Array = f.partenaires.keys().filter(func(id): return id != pnj.id and f.partenaires[id] == "couple")
	if quoi in ["couple", "nuit"] and not autres.is_empty() and p.jalousie >= 70 and p.partage < 50:
		return "%s le sait : tu n'es pas seul dans ton cœur. « Je ne partage pas. »" % nom
	if quoi == "groupe" and (p.partage < 50 or "groupe" in p.refuse):
		return "%s refuse : à deux, ou pas du tout." % nom
	if quoi == "risque" and not ("risque" in p.aime or "dehors" in p.aime or "audace" in p.aime or p.pudeur < 40):
		return "%s rit nerveusement : « Ici ? N'importe qui pourrait passer. Non. »" % nom
	if quoi == "risque" and "public" in p.refuse:
		return "%s refuse : être vu, c'est sa limite." % nom
	if quoi == "pacte" and p.bdsm < 40:
		return "Ce jeu-là n'attire pas %s." % nom
	var regards: Array = m.temoins(20.0).filter(func(n): return n != pnj and not n in avec and int(n.donnees.get("age", "0")) >= 18)
	if quoi != "seduire" and quoi != "risque" and not regards.is_empty() and ("public" in p.refuse or (p.pudeur >= 60 and not "risque" in p.aime)):
		return "%s jette un œil aux autres : « Pas devant tout le monde. »" % nom
	for autre in avec:
		if str(pnj.donnees.get("relations", "")).contains("ennemi") and str(pnj.donnees.get("relations", "")).contains(autre.id):
			return "%s ne veut pas de %s dans ce lit." % [nom, Donnees.prenom(autre.donnees.nom)]
	return ""


## Quand le désir d'un PNJ est à son comble : avec qui il se soulage, s'il y a quelqu'un
## (null : seul). Attirance des deux côtés, assez de désir, jamais en famille, pas de
## tromperie s'il ne partage pas ; ceux qui se rapprochent déjà passent en premier.
static func partenaire_pour(m: Node, n: Node) -> Node:
	var p := profil(n.id)
	var meilleur: Node = null
	for o in m.pnjs:
		var q := profil(o.id)
		if o == n or q.is_empty() or not o.visible or o.mort or o.pos2d().distance_to(n.pos2d()) > 25.0:
			continue
		if not (str(o.donnees.sexe).to_lower() + "s") in p.attire or not (str(n.donnees.sexe).to_lower() + "s") in q.attire:
			continue
		if desir(m, o.id) < 50 or m.enfant_proche(o.pos2d()):
			continue
		var lien := _lien(n, o)
		if lien == "famille":
			continue
		if Liens.entre(m, n.id, o.id).get("etat", "") in ["liaison", "couple"]:
			return o   # leurs amours d'aujourd'hui (liens.gd)
		if (p.couple != "" and p.couple != o.id and p.partage < 60) or (q.couple != "" and q.couple != n.id and q.partage < 60):
			continue
		if lien == "proche":
			return o
		if p.partage >= 50 and q.partage >= 50 and meilleur == null:
			meilleur = o
	return meilleur


## Ce que disent leurs fiches l'un de l'autre : famille, proche, ou rien.
static func _lien(a: Node, b: Node) -> String:
	for paire in [[a, b], [b, a]]:
		var rel := str(paire[0].donnees.get("relations", "")).to_lower()
		var i := rel.find(str(paire[1].id).to_lower())
		if i < 0:
			continue
		var avant := rel.substr(maxi(0, rel.rfind(",", i) + 1), i - maxi(0, rel.rfind(",", i) + 1))
		for mot in ["père", "mère", "fils", "fille", "frère", "sœur", "soeur"]:
			if avant.contains(mot):
				return "famille"
		for mot in ["amoureu", "rapproche", "couple", "mari", "femme d", "a travaillé de nuit", "complice"]:
			if avant.contains(mot):
				return "proche"
	return ""


# ---------------------------------------------------------------- la scène

## Une scène : participants, jauges, journal.
static func nouvelle_scene(m: Node, pnjs: Array, lieu: String) -> Dictionary:
	var s := {"pnjs": [], "lieu": lieu, "barres": {}, "joueur": {"plaisir": 0.0, "desir": float(m.fiche.desir)}, "journal": [], "fini": false}
	for n in pnjs:
		ajouter(m, s, n)
	return s


static func ajouter(m: Node, s: Dictionary, n: Node) -> void:
	s.pnjs.append(n)
	s.barres[n.id] = {"plaisir": 0.0, "desir": float(desir(m, n.id)), "malaise": 0.0, "intensite": 0.0, "comble": false, "stop": false,
		"fois": 0, "fantasme": false}


static func actifs(s: Dictionary) -> Array:
	return s.pnjs.filter(func(n): return not s.barres[n.id].comble and not s.barres[n.id].stop)


## Les gestes possibles maintenant (compétence, nombre de participants).
static func gestes_possibles(m: Node, s: Dictionary) -> Array:
	var comps: Array = m.fiche.competences()
	var pacte: bool = s.pnjs.any(func(n): return m.fiche.pactes.has(n.id))
	return gestes().filter(func(g):
		if g.groupe == "1" and s.pnjs.size() < 2:
			return false
		if g.competence != "" and not g.competence in comps and not (g.competence == "jeu_pouvoir" and pacte):
			return false
		return true)


## Ce que le geste fait à chacun. Renvoie les lignes du journal.
static func jouer(m: Node, s: Dictionary, id_geste: String) -> Array:
	var g := geste(id_geste)
	var f: Fiche = m.fiche
	var comps: Array = f.competences()
	var maitrise := maitrise_art(f)
	var lignes := []
	if g.texte != "":
		lignes.append(g.texte)
	for n in actifs(s):
		var b: Dictionary = s.barres[n.id]
		var p := profil(n.id)
		var nom: String = Donnees.prenom(n.donnees.nom)
		if id_geste == "demander":
			lignes.append(_reveler(m, n, p, "lecture_envies" in comps))
			continue
		if id_geste == "souffler":
			b.intensite = maxf(0.0, b.intensite - 20.0)
			b.malaise = maxf(0.0, b.malaise - 15.0)
			continue
		var plait := false
		var deplait := false
		for t in g.tags:
			match t:
				"audace":
					plait = plait or p.pudeur < 50
					deplait = deplait or p.pudeur >= 75
				"etre_domine":
					plait = plait or p.axe <= -20 or "etre_domine" in p.aime
					deplait = deplait or p.axe >= 40
				"dominer":
					plait = plait or p.axe >= 20 or "dominer" in p.aime
					deplait = deplait or p.axe <= -40
				"pouvoir_fort":
					var ok: bool = (p.bdsm >= 40 or f.pactes.get(n.id, "") == "maitre") and (p.axe <= 0 or "etre_domine" in p.aime)
					plait = plait or ok
					deplait = deplait or not ok
				"pouvoir_servi":
					var ok2: bool = (p.bdsm >= 40 or f.pactes.get(n.id, "") == "esclave") and (p.axe >= 0 or "dominer" in p.aime)
					plait = plait or ok2
					deplait = deplait or not ok2
				"groupe_ok":
					plait = plait or p.partage >= 50
					deplait = deplait or p.partage < 50 or "groupe" in p.refuse
				_:
					plait = plait or t in p.aime or t in p.talents
					deplait = deplait or t in p.refuse
		var gain := 6.0
		var mal := 0.0
		if deplait:
			mal += 45.0
		elif plait:
			gain += 16.0
			mal -= 3.0
		else:
			mal += p.pudeur / 25.0
			# les pratiques osées, quand il ne les aime pas : ça gêne davantage
			if g.tags.any(func(t): return t in OSE):
				mal += 15.0
		if g.competence != "" and g.competence in comps:
			gain += 8.0
		if s.get("risque", false) and ("risque" in p.aime or "dehors" in p.aime):
			gain += 10.0   # le frisson d'être vus
		if p.fantasme != "" and p.fantasme in g.tags and not deplait:
			gain += 25.0
			if not b.fantasme:
				b.fantasme = true
				lignes.append("%s frissonne : c'est exactement ce dont il rêvait." % nom)
		gain *= 0.5 + b.desir / 100.0
		gain *= 1.0 + 0.03 * maitrise + (0.1 if "seduction" in comps else 0.0) + 0.1 * a_son_gout(m, n)
		gain *= 0.8 + f.corps.get("sensibilite", 50) / 250.0 if g.qui == "partenaire" else 1.0
		if p.experience == "vierge" and (id_geste.begins_with("amour") or id_geste.begins_with("bouche")):
			mal += 5.0
			gain *= 0.8
		b.plaisir = minf(100.0, b.plaisir + gain)
		b.malaise = maxf(0.0, b.malaise + mal)
		b.intensite = maxf(0.0, b.intensite + g.intensite)
		# le joueur aussi
		var pour_moi := 8.0 + (6.0 if p.experience == "experimente" else 0.0)
		if g.qui == "partenaire" and g.tags.any(func(t): return t in p.talents):
			pour_moi += 18.0
		s.joueur.plaisir = minf(100.0, s.joueur.plaisir + pour_moi * (0.5 + s.joueur.desir / 100.0))
		# les limites : le mot d'arrêt
		var limite_intensite: float = maxf(30.0, p.bdsm + (20.0 if f.pactes.has(n.id) else 0.0))
		if b.malaise >= 60.0 or b.intensite > limite_intensite:
			b.stop = true
			f.drapeaux["brute_" + n.id] = true   # il s'en souviendra (Margo ne te reprendra pas)
			lignes.append("« %s. » %s a dit le mot d'arrêt. Pour %s, tout s'arrête là." % [MOT_D_ARRET, nom, nom])
		elif deplait:
			lignes.append("%s se raidit : ce n'est pas pour %s." % [nom, nom])
		elif b.plaisir >= 100.0:
			var defi: Dictionary = s.get("defi", {})
			b.fois += 1
			if defi.get("pnj", "") == n.id:
				defi.compte = int(defi.get("compte", 0)) + 1
			if defi.get("pnj", "") == n.id and defi.compte < int(defi.fois):
				b.plaisir = 0.0
				b.desir = maxf(b.desir, 50.0)
				lignes.append("%s est comblé·e (%d/%d)… et en redemande." % [nom, defi.compte, defi.fois])
			elif defi.get("pnj", "") != n.id and b.fois < p.endurance and b.desir > 30.0:
				b.plaisir = 0.0
				b.desir -= 25.0
				lignes.append("%s est comblé·e (%d)… et en veut encore." % [nom, b.fois])
			else:
				b.comble = true
				lignes.append("%s est comblé·e%s." % [nom, (" (%d/%d)" % [defi.compte, defi.fois]) if defi.get("pnj", "") == n.id else ""])
		elif plait:
			lignes.append("%s aime ça." % nom)
	if s.get("risque", false) and not s.has("surpris") and id_geste != "demander" and randf() < RISQUE_SURPRIS:
		s.surpris = true
		lignes.append("Des pas, une lanterne : quelqu'un vous a vus. Ça se saura.")
	if actifs(s).is_empty():
		s.fini = true
	return lignes


## Demander ce qu'il aime : une envie et une limite (toutes avec Lecture des envies).
static func _reveler(m: Node, n: Node, p: Dictionary, tout: bool) -> String:
	var f: Fiche = m.fiche
	var connus: Array = f.gouts_connus.get(n.id, [])
	var nouveaux := []
	if p.fantasme != "" and not ("fantasme_" + p.fantasme) in connus and int(m.relations.get(n.id, 0)) >= 70:
		connus.append("fantasme_" + p.fantasme)
		f.gouts_connus[n.id] = connus
		return "%s hésite, puis te l'avoue tout bas : son fantasme, c'est %s." % [Donnees.prenom(n.donnees.nom), p.fantasme.replace("_", " ")]
	for t in p.aime + p.talents:
		if not t in connus and (tout or nouveaux.is_empty()):
			nouveaux.append(t)
	var limites := []
	for t in p.refuse:
		if not ("non_" + t) in connus and (tout or limites.is_empty()):
			limites.append("non_" + t)
	connus.append_array(nouveaux + limites)
	f.gouts_connus[n.id] = connus
	var nom: String = Donnees.prenom(n.donnees.nom)
	if nouveaux.is_empty() and limites.is_empty():
		return "%s rit : « Tu sais déjà tout de moi. »" % nom
	return "%s te le dit à l'oreille : %s." % [nom, ", ".join((nouveaux + limites).map(func(t): return t.replace("_", " ").replace("non ", "jamais : ")))]


## L'art d'aimer, de 1 à 10, monte avec les nuits.
static func maitrise_art(f: Fiche) -> int:
	return 0 if not "art_aimer" in f.apprises else clampi(1 + int(f.drapeaux.get("art_xp", 0) / 3), 1, 10)


## La fin : après (rester, partir, promettre), affection, désir, rumeurs, jalousie. Renvoie le texte.
static func finir(m: Node, s: Dictionary, apres: String) -> String:
	var f: Fiche = m.fiche
	var lignes := []
	for n in s.pnjs:
		var b: Dictionary = s.barres[n.id]
		var p := profil(n.id)
		var nom: String = Donnees.prenom(n.donnees.nom)
		var d := 2
		if b.comble:
			d = 6 + 2 * b.fois
		if b.fantasme and not b.stop:
			d += 5
		if b.stop:
			d = -10
		var tendre: bool = p.cherche.any(func(c): return c in ["amour", "fidélité", "sécurité"]) or "nuit_entiere" in p.aime
		if apres == "rester" and tendre and not b.stop:
			d += 4
		elif apres == "partir" and tendre:
			d -= 4
		m.relations[n.id] = clampi(m.relations.get(n.id, 0) + d, -100, 100)
		m.desirs[n.id] = 0 if b.comble else maxi(0, int(b.desir) - 20)
		f.nuits[n.id] = f.nuits.get(n.id, 0) + 1
		if apres == "promettre" and not b.stop:
			var raison := consentement(m, n, "couple", s.pnjs.filter(func(x): return x != n))
			if raison == "":
				lignes.append(devenir_couple(m, n))
			else:
				lignes.append(raison)
		lignes.append("%s : %s (%+d)." % [nom, "comblé·e" if b.comble else ("le mot d'arrêt" if b.stop else "une belle nuit"), d])
	f.desir = 0 if s.joueur.plaisir >= 100.0 else maxi(0, f.desir - 30)
	if not "art_aimer" in f.apprises:
		f.apprises.append("art_aimer")
		lignes.append("Nouvelle compétence : Art d'aimer.")
	f.drapeaux["art_xp"] = int(f.drapeaux.get("art_xp", 0)) + 1
	var bruit := 0
	for n in s.pnjs:
		bruit = maxi(bruit, profil(n.id).bruit)
	if s.has("surpris"):
		bruit = 1000   # surpris : la rumeur part à coup sûr
	var r := rumeur(m, s.pnjs, "une nuit", bruit)
	if r != "":
		lignes.append(r)
	f.sauver()
	m.sauver_etat()
	return " ".join(lignes)


## Devenir un couple. Un harem, c'est plusieurs couples : chacun l'apprend, et les jaloux en souffrent.
static func devenir_couple(m: Node, n: Node) -> String:
	var f: Fiche = m.fiche
	var lignes := ["%s et toi, c'est officiel." % Donnees.prenom(n.donnees.nom)]
	for id in f.partenaires.keys():
		if id == n.id or f.partenaires[id] != "couple":
			continue
		var p := profil(id)
		if p.partage < 50:
			var perte := int(p.jalousie / 3.0)
			m.relations[id] = clampi(m.relations.get(id, 0) - perte, -100, 100)
			lignes.append("%s l'apprend et le vit mal (-%d)." % [Donnees.prenom(m._pnj_par_id(id).donnees.nom), perte])
	f.partenaires[n.id] = "couple"
	return " ".join(lignes)


## Les rumeurs : des témoins, ou un secret qui fuit (moins avec Discrétion). Renvoie le texte.
static func rumeur(m: Node, pnjs: Array, quoi: String, bruit := 0) -> String:
	var f: Fiche = m.fiche
	var regards: Array = m.temoins(25.0).filter(func(n): return not n in pnjs and int(n.donnees.get("age", "0")) >= 18)
	var fuite := 0.25 + bruit / 400.0 - (0.15 if "discretion" in f.competences() else 0.0)
	if regards.is_empty() and randf() >= fuite:
		return ""
	var lignes := ["Ça se sait%s." % ((" : %s %s vu" % [", ".join(regards.map(func(n): return Donnees.prenom(n.donnees.nom))), "ont" if regards.size() > 1 else "a"]) if regards else ", sans qu'on sache comment")]
	var ids := pnjs.map(func(n): return n.id)
	for n in pnjs:
		var c: String = profil(n.id).get("couple", "")
		if c != "" and not c in ids and not m.morts.has(c):
			m.relations[c] = clampi(m.relations.get(c, 0) - 40, -100, 100)
			lignes.append("%s découvre %s avec %s (-40)." % [Donnees.prenom(m._pnj_par_id(c).donnees.nom) if m._pnj_par_id(c) else c, quoi, Donnees.prenom(n.donnees.nom)])
	for id in f.partenaires:
		if id in ids:
			continue
		var p := profil(id)
		if p.jalousie > p.partage:
			var perte := int(p.jalousie / 3.0)
			m.relations[id] = clampi(m.relations.get(id, 0) - perte, -100, 100)
			lignes.append("%s est jaloux·se (-%d)." % [Donnees.prenom(m._pnj_par_id(id).donnees.nom) if m._pnj_par_id(id) else id, perte])
	for id in profils():
		if profil(id).pudeur >= 70 and not id in ids and not f.partenaires.has(id):
			m.relations[id] = clampi(m.relations.get(id, 0) - 3, -100, 100)
	lignes.append("Les plus prudes du village te regardent de travers.")
	m.sauver_etat()
	return " ".join(lignes)


## Le pacte maître/esclave, un jeu convenu entre adultes (univers.md). role : ton rôle, maitre ou esclave.
static func pacte(m: Node, n: Node, role: String) -> String:
	var p := profil(n.id)
	var nom: String = Donnees.prenom(n.donnees.nom)
	var raison := consentement(m, n, "pacte")
	if raison != "":
		return raison
	if role == "maitre" and not (p.axe <= -20 or "etre_domine" in p.aime):
		return "%s rit : « Moi, à genoux ? Non. »" % nom
	if role == "esclave" and not (p.axe >= 20 or "dominer" in p.aime):
		return "%s secoue la tête : « Je ne sais pas mener, et je ne veux pas. »" % nom
	m.fiche.pactes[n.id] = role
	m.fiche.sauver()
	return "Vous en parlez longtemps : ce que chacun veut, ce que chacun refuse. Le mot d'arrêt sera « %s », et il sera toujours respecté. %s" % [
		MOT_D_ARRET, "Tu mèneras." if role == "maitre" else "Tu seras à son service, dans ce jeu-là seulement."]
