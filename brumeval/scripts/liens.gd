# La vie amoureuse des habitants entre eux : liaisons, couples qui se font et se défont,
# infidélités découvertes, couples qui s'ouvrent et t'invitent. Tout ça vit sans toi, à
# toute heure, même dans la ville où tu n'es pas ; tu le vois si tu es là, ou tu l'apprends
# par les ragots.
#
# Règles fixes : seulement entre adultes qui ont un profil intime (jamais un enfant, jamais
# un captif) ; jamais dans une même famille ; chacun selon ses goûts (qui l'attire, ce qu'il
# cherche, sa jalousie, ce qu'il accepte de partager). Une invitation peut toujours se refuser.
#
# Ce que tu peux y faire (data/actions.csv, colonne donne) :
#   ragots         écouter les ragots (taverne, auberge) : les dernières nouvelles
#   confidences    lui demander où il en est (affection 30 ; 50 pour un secret)
#   entremetteur   lui présenter quelqu'un qui pourrait lui plaire
#   denoncer       dire à quelqu'un qu'on le trompe (si tu le sais)
#   couvrir        couvrir des amants (un alibi) : ils te le revaudront
#   chantage       faire payer ton silence (de l'argent, rien d'autre) : risqué
#   consoler       consoler après une rupture
#   reconcilier    réconcilier un couple qui s'est séparé
#   zizanie        semer le doute dans un couple : risqué
#   attiser        jeter deux ennemis l'un contre l'autre jusqu'à ce que la haine change de nature
#   proposer_trois proposer une nuit à trois à un couple ouvert (intime)
# Et quand c'est ton couple qui te trompe : pardonner, rompre, proposer de partager, ou
# t'expliquer avec l'autre (une bagarre).
#
# Images : illustrations/lien_<evenement>/ (liaison, couple, rupture, infidelite, pardon,
# ouvert, reconciliation, fin, invitation, trahison) et illustrations/<action>/ comme toujours.
class_name Liens
extends RefCounted

const ACTIONS := ["ragots", "confidences", "entremetteur", "denoncer", "couvrir", "chantage", "consoler",
	"reconcilier", "zizanie", "proposer_trois", "attiser"]
## Chance, par heure du monde, qu'il se passe quelque chose entre eux.
const PAR_HEURE := 0.06
const JOURNAL_MAX := 40


## Pas parti au loin (« en route vers Saltevaux »).
static func present(m: Node, id: String) -> bool:
	return m.present(id)


static func cle(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


static func _nom(m: Node, id: String) -> String:
	return Donnees.prenom(str(m.pnj_donnees.get(id, {}).get("nom", id)))


static func _ville(id: String) -> String:
	return id.left(3)


## Au chargement : les couples du départ (intime.csv), puis ce qui a changé depuis.
static func installer(m: Node) -> void:
	if not m.liens.has("_init"):
		m.liens["_init"] = true
		for id in Intime.profils():
			var c: String = Intime.profil(id).get("couple_depart", "")
			if c != "" and Intime.profils().has(c) and not m.liens.has(cle(id, c)):
				m.liens[cle(id, c)] = {"a": id, "b": c, "etat": "couple", "secret": false, "depuis": 0, "connu": true, "ouvert": false}
	appliquer(m)


## Les profils suivent les couples d'aujourd'hui (pour le consentement, la jalousie, les rumeurs).
static func appliquer(m: Node) -> void:
	for id in Intime.profils():
		Intime.profil(id).couple = ""
	for k in m.liens:
		var l = m.liens[k]
		if l is Dictionary and l.etat == "couple":
			Intime.profil(l.a).couple = l.b
			Intime.profil(l.b).couple = l.a


static func entre(m: Node, a: String, b: String) -> Dictionary:
	return m.liens.get(cle(a, b), {})


## Les liens d'une personne (liaison ou couple, pas les histoires finies).
static func de(m: Node, id: String, etats := ["liaison", "couple"]) -> Array:
	var r := []
	for k in m.liens:
		var l = m.liens[k]
		if l is Dictionary and (l.a == id or l.b == id) and l.etat in etats:
			r.append(l)
	return r


static func autre(l: Dictionary, id: String) -> String:
	return l.b if l.a == id else l.a


static func couple_de(m: Node, id: String) -> String:
	for l in de(m, id, ["couple"]):
		return autre(l, id)
	return ""


## Peuvent-ils s'aimer ? Deux adultes vivants avec un profil, de la même ville, qui s'attirent, pas de la même famille.
static func compatibles(m: Node, a: String, b: String, haine_ok := false) -> bool:
	if a == b or _ville(a) != _ville(b) or not _ville(a) in ["BRU", "PIE"]:
		return false
	var pa := Intime.profil(a)
	var pb := Intime.profil(b)
	if pa.is_empty() or pb.is_empty() or m.morts.has(a) or m.morts.has(b):
		return false
	var da: Dictionary = m.pnj_donnees.get(a, {})
	var db: Dictionary = m.pnj_donnees.get(b, {})
	if int(da.get("age", "0")) < 18 or int(db.get("age", "0")) < 18:
		return false
	if not present(m, a) or not present(m, b):
		return false   # parti au loin
	if not (str(db.get("sexe", "")).to_lower() + "s") in pa.attire or not (str(da.get("sexe", "")).to_lower() + "s") in pb.attire:
		return false
	return not famille(da, db) and (haine_ok or not ennemis(da, db) or braise(m, a, b) >= BRAISE_MAX)


## Des ennemis qui finissent amants : il y faut un chemin. Chaque pas (forcés à travailler ensemble,
## un danger partagé, une dispute qui dure trop longtemps) attise la braise ; à BRAISE_MAX la haine
## a changé de nature, et le reste suit comme pour n'importe qui (désir, attirance, envie).
const BRAISE_MAX := 3
const BRAISE_TEXTES := [
	"%s et %s se sont encore disputés. Plus longtemps que nécessaire, et en se regardant beaucoup.",
	"%s et %s ont dû se serrer les coudes, un temps. Ils n'en parlent pas. Ils évitent même de se croiser.",
	"%s et %s : on les a vus se crier dessus, très près l'un de l'autre. Puis plus rien. Le silence a duré.",
]

static func braise(m: Node, a: String, b: String) -> int:
	return int(m.fiche.drapeaux.get("braise_" + cle(a, b), 0))


## Attiser : un pas de plus sur le chemin. Renvoie le texte du ragot.
static func attiser(m: Node, a: String, b: String) -> String:
	var n := mini(braise(m, a, b) + 1, BRAISE_MAX)
	m.fiche.drapeaux["braise_" + cle(a, b)] = n
	var t: String = BRAISE_TEXTES[n - 1] % [_nom(m, a), _nom(m, b)]
	_noter(m, "braise", [a, b], t, false)
	m.sauver_etat()
	return t


## Deux ennemis qui pourraient s'aimer, si la haine changeait de nature (même ville, adultes, attirés).
static func ennemis_attires(m: Node, a: String, b: String) -> bool:
	return ennemis(m.pnj_donnees.get(a, {}), m.pnj_donnees.get(b, {})) and compatibles(m, a, b, true)


## Ennemis d'après leurs fiches (« ennemie de Basile », « méprise Corentin », « en veut à Aldric ») :
## ceux-là ne finissent pas dans le même lit.
static func ennemis(da: Dictionary, db: Dictionary) -> bool:
	for paire in [[da, db], [db, da]]:
		var rel := str(paire[0].get("relations", "")).to_lower()
		var i := rel.find(str(paire[1].get("id", "?")).to_lower())
		if i < 0:
			continue
		var debut := maxi(0, rel.rfind(",", i) + 1)
		var avant := rel.substr(debut, i - debut)
		for mot in ["ennemi", "méprise", "en veut", "déteste", "hait", "se méfie"]:
			if avant.contains(mot):
				return true
	return false


static func famille(da: Dictionary, db: Dictionary) -> bool:
	for paire in [[da, db], [db, da]]:
		var rel := str(paire[0].get("relations", "")).to_lower()
		var i := rel.find(str(paire[1].get("id", "?")).to_lower())
		if i < 0:
			continue
		var debut := maxi(0, rel.rfind(",", i) + 1)
		var avant := rel.substr(debut, i - debut)
		for mot in ["père", "mère", "fils", "fille", "frère", "sœur", "soeur", "oncle", "tante", "neveu", "nièce", "cousin"]:
			if avant.contains(mot):
				return true
	return false


## Cherche-t-il le plaisir, l'aventure ou la passion (une liaison peut naître vite) ?
static func _leger(id: String) -> bool:
	return Intime.profil(id).cherche.any(func(c): return c in ["plaisir", "aventure", "passion", "liberté"])


static func _fidele_en_couple(m: Node, id: String) -> bool:
	var p := Intime.profil(id)
	return couple_de(m, id) != "" and p.partage < 60 and p.cherche.any(func(c): return c in ["amour", "fidélité", "sécurité", "statut"])


## Tromper : il est en couple avec quelqu'un d'autre, qui ne partage pas.
static func _trompe(m: Node, id: String, avec: String) -> String:
	var c := couple_de(m, id)
	if c == "" or c == avec:
		return ""
	var l := entre(m, id, c)
	if l.get("ouvert", false) or Intime.profil(c).partage >= 60:
		return ""
	return c


# ---------------------------------------------------------------- le temps qui passe

## Les tests coupent le hasard (pour que les couples du départ restent ceux du départ).
static var hasard := true


static func passer_temps(m: Node, heures: int) -> void:
	if not hasard:
		return
	for h in heures:
		if randf() < PAR_HEURE:
			evenement(m)


## Un événement au hasard parmi ceux qui sont possibles (ou celui demandé). Renvoie le texte.
static func evenement(m: Node, force := "") -> String:
	var possibles := []   # [poids, type, données]
	var jour: int = Horloge.jour()
	var ids: Array = Intime.profils().keys().filter(func(i): return _ville(i) in ["BRU", "PIE"])
	# une nouvelle liaison : deux qui se plaisent et qui en ont envie
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: String = ids[i]
			var b: String = ids[j]
			if m.liens.has(cle(a, b)) and m.liens[cle(a, b)].etat in ["liaison", "couple"]:
				continue
			if Intime.desir(m, a) < 50 or Intime.desir(m, b) < 50 or not compatibles(m, a, b):
				continue
			if Intime.profil(a).libido < 30 or Intime.profil(b).libido < 30:
				continue
			var pousse: bool = m.fiche.drapeaux.get("pousse_" + cle(a, b), false)
			var braise_pleine := braise(m, a, b) >= BRAISE_MAX
			if braise_pleine:
				pousse = true    # la haine a tourné : la passion n'attend pas qu'on la courtise
			if not pousse and jour <= 3:
				continue     # les trois premiers jours sont écrits (monde/chronique) : rien d'inventé, sauf ce que tu provoques
			if not pousse and not (_leger(a) or _leger(b)):
				continue     # deux qui cherchent l'amour se courtisent d'abord (l'entremetteur peut les pousser)
			if not pousse and (_fidele_en_couple(m, a) or _fidele_en_couple(m, b)):
				continue     # en couple et fidèle de cœur : pas sans qu'on l'y pousse
			possibles.append([2.0 if pousse else 1.0, "liaison", [a, b]])
	# des ennemis sur le chemin : allumée (par toi ou par une scène), la braise couve seule d'un pas ;
	# le dernier, il faut un vrai moment (toi, ou une scène qui les jette l'un contre l'autre)
	for k in m.fiche.drapeaux.keys():
		if not str(k).begins_with("braise_"):
			continue
		var paire: PackedStringArray = str(k).substr(7).split("|")
		if paire.size() == 2 and int(m.fiche.drapeaux[k]) == 1 and ennemis_attires(m, paire[0], paire[1]):
			possibles.append([0.3, "braise", [paire[0], paire[1]]])
	for k in m.liens:
		var l = m.liens[k]
		if not l is Dictionary or not present(m, l.a) or not present(m, l.b):
			continue
		var pa := Intime.profil(l.a)
		var pb := Intime.profil(l.b)
		var age: int = jour - int(l.depuis)
		match l.etat:
			"liaison":
				if l.secret:
					possibles.append([0.4 if l.get("couvert", false) else 1.2, "infidelite", [l.a, l.b]])
				elif age >= 2 and couple_de(m, l.a) == "" and couple_de(m, l.b) == "" \
						and pa.cherche.any(func(c): return c in ["amour", "compagnie", "fidélité", "sécurité"]) \
						and pb.cherche.any(func(c): return c in ["amour", "compagnie", "fidélité", "sécurité"]):
					possibles.append([1.5, "couple", [l.a, l.b]])
				if age >= 3:
					possibles.append([0.3, "fin", [l.a, l.b]])
			"couple":
				if not l.get("ouvert", false) and pa.partage >= 50 and pb.partage >= 50 and age >= 1:
					possibles.append([0.4, "ouvert", [l.a, l.b]])
				possibles.append([0.08, "rupture", [l.a, l.b]])
			"rompu":
				if age >= 1:
					possibles.append([0.25, "reconciliation", [l.a, l.b]])
	if force != "":
		possibles = possibles.filter(func(p): return p[1] == force)
	elif jour <= 3:
		possibles = possibles.filter(func(p): return not p[1] in ["rupture", "ouvert", "fin", "couple"])   # la chronique tient
	if possibles.is_empty():
		return ""
	var total := 0.0
	for p in possibles:
		total += p[0]
	var tirage := randf() * total
	for p in possibles:
		tirage -= p[0]
		if tirage <= 0.0:
			return appliquer_evenement(m, p[1], p[2][0], p[2][1])
	return appliquer_evenement(m, possibles[-1][1], possibles[-1][2][0], possibles[-1][2][1])


static func _poser(m: Node, a: String, b: String, etat: String, extra := {}) -> Dictionary:
	var l: Dictionary = m.liens.get(cle(a, b), {"a": a, "b": b, "secret": false, "connu": false, "ouvert": false})
	l.etat = etat
	l.depuis = Horloge.jour()
	l.merge(extra, true)
	m.liens[cle(a, b)] = l
	return l


static func appliquer_evenement(m: Node, type: String, a: String, b: String) -> String:
	var na := _nom(m, a)
	var nb := _nom(m, b)
	var t := ""
	var secret := false
	match type:
		"liaison":
			var trahi_a := _trompe(m, a, b)
			var trahi_b := _trompe(m, b, a)
			secret = trahi_a != "" or trahi_b != ""
			_poser(m, a, b, "liaison", {"secret": secret, "trahis": [trahi_a, trahi_b].filter(func(x): return x != ""), "connu": false, "couvert": false})
			m.desirs[a] = 20
			m.desirs[b] = 20
			t = "%s et %s ont passé la nuit ensemble." % [na, nb]
			if ennemis(m.pnj_donnees.get(a, {}), m.pnj_donnees.get(b, {})):
				t = "%s et %s, les ennemis jurés, ont passé la nuit ensemble. Personne n'y comprend rien. Eux non plus." % [na, nb]
			if secret:
				t += " En secret : %s." % " et ".join(entre(m, a, b).trahis.map(func(x): return _nom(m, x) + " n'en sait rien"))
		"couple":
			_poser(m, a, b, "couple")
			t = "%s et %s, c'est officiel : ils s'installent ensemble." % [na, nb]
		"fin":
			_poser(m, a, b, "fini")
			t = "Entre %s et %s, c'est fini. Sans drame, ou presque." % [na, nb]
		"ouvert":
			_poser(m, a, b, "couple", {"ouvert": true})
			t = "%s et %s ont parlé longtemps. Leur couple s'ouvre : ce qu'ils vivent ailleurs ne les menace plus." % [na, nb]
		"rupture":
			_poser(m, a, b, "rompu")
			t = "%s et %s se séparent. Les éclats de voix ont traversé les murs." % [na, nb]
		"reconciliation":
			_poser(m, a, b, "couple")
			t = "%s et %s se sont retrouvés. On les a vus main dans la main." % [na, nb]
		"infidelite":
			t = decouverte(m, a, b)
		"braise":
			return attiser(m, a, b)
	appliquer(m)
	_noter(m, type, [a, b], t, secret)
	m.sauver_etat()
	return t


## Une liaison secrète découverte : celui ou celle qu'on trompait pardonne, ou c'est la rupture.
static func decouverte(m: Node, a: String, b: String) -> String:
	var l := entre(m, a, b)
	var lignes := ["%s découvre tout, pour %s et %s." % [" et ".join(l.get("trahis", []).map(func(x): return _nom(m, x))), _nom(m, a), _nom(m, b)]]
	for trahi in l.get("trahis", []):
		var amant := a if couple_de(m, a) == trahi else b
		var p := Intime.profil(trahi)
		if p.partage >= 40 and p.jalousie < 60:
			_poser(m, trahi, amant, "couple", {"ouvert": true})
			lignes.append("%s pardonne, et leur couple s'ouvre." % _nom(m, trahi))
		else:
			_poser(m, trahi, amant, "rompu")
			lignes.append("%s claque la porte : c'est fini avec %s." % [_nom(m, trahi), _nom(m, amant)])
	l.secret = false
	l.trahis = []
	l.connu = true
	appliquer(m)
	return " ".join(lignes)


## Le journal (les ragots), et ce que tu vois si tu es là. Ton couple qui te trompe : on te le dit… ou pas.
static func _noter(m: Node, type: String, ids: Array, texte: String, secret: bool) -> void:
	if texte == "":
		return
	var vu := false
	for id in ids:
		var n: Node = m._pnj_par_id(id)
		if n and n.visible and m.joueur and n.pos2d().distance_to(m.joueur.pos2d()) < 30.0:
			vu = true
	if vu and m.liens.has(cle(ids[0], ids[1])):
		m.liens[cle(ids[0], ids[1])].connu = true
	if not secret or vu:
		m.journal_liens.append({"jour": Horloge.jour(), "texte": texte, "ids": ids})
		while m.journal_liens.size() > JOURNAL_MAX:
			m.journal_liens.pop_front()
	if vu and not Illustrations.ouvert and m.combat == null:
		Illustrations.montrer("lien_" + type, ["+".join(ids)] + ids, texte)
	# toi : ton couple avec quelqu'un d'autre
	if type == "liaison":
		for id in ids:
			if m.fiche.partenaires.get(id, "") == "couple" and not m.fiche.drapeaux.get("ouvert_" + id, false):
				m.fiche.drapeaux["trahison_" + id] = autre(entre(m, ids[0], ids[1]), id)


# ---------------------------------------------------------------- ce que tu peux y faire

## L'action a-t-elle un sens avec ce PNJ, maintenant ?
static func dispo(m: Node, quoi: String, pnj: Node) -> bool:
	if pnj == null:
		return quoi == "ragots"
	var id: String = pnj.id
	if Intime.profil(id).is_empty():
		return false
	var secretes := de(m, id, ["liaison"]).filter(func(l): return l.secret and l.connu)
	match quoi:
		"confidences":
			return true
		"entremetteur":
			return couple_de(m, id) == "" or entre(m, id, couple_de(m, id)).get("ouvert", false)
		"denoncer":
			return _trahisons_connues(m, id) != ""
		"couvrir", "chantage":
			return not secretes.is_empty() and not m.fiche.drapeaux.has("%s_%s_%d" % [quoi, id, Horloge.jour()])
		"consoler":
			return de(m, id, ["rompu", "fini"]).any(func(l): return Horloge.jour() - int(l.depuis) <= 3)
		"reconcilier":
			return de(m, id, ["rompu"]).any(func(l): return not m.morts.has(autre(l, id)))
		"zizanie":
			return couple_de(m, id) != ""
		"attiser":
			return not _ennemis_attires_de(m, id).is_empty() and not m.fiche.drapeaux.has("attiser_%s_%d" % [id, Horloge.jour()])
		"proposer_trois":
			var c := _partenaire_present(m, pnj)
			return c != null
	return false


## Qui trompe ce PNJ, à ta connaissance ("" : personne).
static func _trahisons_connues(m: Node, id: String) -> String:
	for k in m.liens:
		var l = m.liens[k]
		if l is Dictionary and l.etat == "liaison" and l.secret and l.connu and id in l.get("trahis", []):
			return k
	return ""


## Son partenaire (couple ou liaison), à côté, et partant pour partager.
static func _partenaire_present(m: Node, pnj: Node) -> Node:
	if Intime.profil(pnj.id).partage < 50:
		return null
	for l in de(m, pnj.id):
		if l.secret:
			continue
		var o: Node = m._pnj_par_id(autre(l, pnj.id))
		if o and o.visible and not o.mort and o.pos2d().distance_to(pnj.pos2d()) < 15.0 and Intime.profil(o.id).partage >= 50:
			return o
	return null


static func agir(m: Node, quoi: String, pnj: Node) -> String:
	var f: Fiche = m.fiche
	var st: Dictionary = f.stats_totales()
	var id: String = pnj.id if pnj else ""
	var nom: String = Donnees.prenom(pnj.donnees.nom) if pnj else ""
	match quoi:
		"ragots":
			return ragots(m)
		"confidences":
			return confidences(m, pnj)
		"entremetteur":
			var choix := []
			for o in Intime.profils():
				if o != id and compatibles(m, id, o) and couple_de(m, o) == "" and not entre(m, id, o).get("etat", "") in ["liaison", "couple"]:
					choix.append([_nom(m, o), _presenter.bind(m, pnj, o), "Lui parler de %s." % _nom(m, o)])
			if choix.is_empty():
				return "Tu cherches, mais tu ne vois personne pour %s, ici." % nom
			choix.append(["Laisser tomber", func(): pass, ""])
			m.fenetres.choix("Jouer les entremetteurs", "Qui pourrait plaire à %s ?" % nom, choix.slice(0, 9) + [choix[-1]])
			return ""
		"denoncer":
			var k := _trahisons_connues(m, id)
			var l: Dictionary = m.liens[k]
			var t := "Tu lui dis ce que tu sais. %s pâlit." % nom
			for x in [l.a, l.b]:
				m.relations[x] = clampi(m.relations.get(x, 0) - 20, -100, 100)
			m.relations[id] = clampi(m.relations.get(id, 0) + 8, -100, 100)   # il te sait gré de la vérité
			var d := decouverte(m, l.a, l.b)
			t += " " + d + " Les amants savent qui a parlé (-20)."
			_noter(m, "infidelite", [l.a, l.b], d, false)
			m.sauver_etat()
			return t
		"couvrir":
			f.drapeaux["couvrir_%s_%d" % [id, Horloge.jour()]] = true
			for l in de(m, id, ["liaison"]).filter(func(x): return x.secret):
				l.couvert = true
				for x in [l.a, l.b]:
					m.relations[x] = clampi(m.relations.get(x, 0) + 10, -100, 100)
			m.sauver_etat()
			return "« Il était avec moi, hier soir. » Tu mens sans ciller. %s te le revaudra (+10, et pour l'autre aussi)." % nom
		"chantage":
			f.drapeaux["chantage_%s_%d" % [id, Horloge.jour()]] = true
			var lui := Combattant.depuis_pnj(pnj.donnees, pnj).stats
			var moi: int = st.Vol + st.Int + randi_range(1, 20)
			var resiste: int = int(lui.Vol) + int(lui.Int) + randi_range(1, 20)
			m.relations[id] = clampi(m.relations.get(id, 0) - 30, -100, 100)
			if moi >= resiste:
				var c := randi_range(10, 30) + 5 * int(str(pnj.donnees.get("statut_social", "")).contains("notable"))
				f.bourse += c
				f.sauver()
				m.sauver_etat()
				return "%s serre les dents et te glisse %s : « Et tu te tais. » (-30)" % [nom, Objets.texte_prix(c)]
			var l: Dictionary = de(m, id, ["liaison"]).filter(func(x): return x.secret)[0]
			var d := decouverte(m, l.a, l.b)
			var t := "%s te rit au nez : « Va le dire. Je le dirai moi-même avant toi. » (-30) " % nom + d
			_noter(m, "infidelite", [l.a, l.b], d, false)
			m.sauver_etat()
			return t + "\n\n" + Intime.rumeur(m, [], "ton chantage", 200)
		"consoler":
			if f.drapeaux.get("console_" + id, -1) == Horloge.jour():
				return "%s te remercie, mais a besoin d'être seul·e, maintenant." % nom
			f.drapeaux["console_" + id] = Horloge.jour()
			m.relations[id] = clampi(m.relations.get(id, 0) + 8, -100, 100)
			m.desirs[id] = mini(100, Intime.desir(m, id) + 5)
			m.sauver_etat()
			return "Tu l'écoutes. Longtemps. %s finit par sourire à travers ses larmes (+8)." % nom
		"reconcilier":
			var l: Dictionary = de(m, id, ["rompu"])[0]
			var o := autre(l, id)
			var reussi: bool = st.Sag + st.Int + randi_range(1, 20) >= 28
			if reussi:
				_poser(m, id, o, "couple")
				appliquer(m)
				for x in [id, o]:
					m.relations[x] = clampi(m.relations.get(x, 0) + 10, -100, 100)
				var t := "Tu les fais asseoir à la même table. Les mots viennent, puis les mains. %s et %s se retrouvent (+10)." % [nom, _nom(m, o)]
				_noter(m, "reconciliation", [id, o], "%s et %s se sont retrouvés. Quelqu'un les a aidés, dit-on." % [nom, _nom(m, o)], false)
				m.sauver_etat()
				return t
			m.relations[id] = clampi(m.relations.get(id, 0) - 3, -100, 100)
			m.sauver_etat()
			return "%s secoue la tête : « Ne te mêle pas de ça. » (-3)" % nom
		"zizanie":
			var o := couple_de(m, id)
			var lui := Combattant.depuis_pnj(pnj.donnees, pnj).stats
			var moi: int = st.Int + st.Agi + randi_range(1, 20)
			var flair: int = int(lui.Per) + int(lui.Sag) + randi_range(1, 20)
			if moi >= flair:
				_poser(m, id, o, "rompu")
				appliquer(m)
				var t := "Un mot de trop, un doute bien placé. Le soir même, %s et %s se déchirent. Ils se séparent." % [nom, _nom(m, o)]
				_noter(m, "rupture", [id, o], "%s et %s se séparent. Personne ne sait vraiment pourquoi." % [nom, _nom(m, o)], false)
				m.sauver_etat()
				return t
			for x in [id, o]:
				m.relations[x] = clampi(m.relations.get(x, 0) - 25, -100, 100)
			m.sauver_etat()
			return "%s te regarde longuement : « Pourquoi tu me racontes ça ? » Ils en parlent le soir même, et comprennent que c'est toi (-25 chacun).\n\n%s" % [nom, Intime.rumeur(m, [], "tes mensonges", 200)]
		"attiser":
			var choix := []
			for o in _ennemis_attires_de(m, id):
				choix.append([_nom(m, o), _attiser_avec.bind(m, pnj, o), ATTISER_PAS[braise(m, id, o)] % [nom, _nom(m, o)]])
			choix.append(["Laisser tomber", func(): pass, ""])
			m.fenetres.choix("Les jeter l'un contre l'autre", "Qui %s déteste-t-il assez pour que ça change ?" % nom, choix)
			return ""
		"proposer_trois":
			var o := _partenaire_present(m, pnj)
			if o == null:
				return "%s est seul·e, maintenant." % nom
			for x in [[pnj, o], [o, pnj]]:
				var raison := Intime.consentement(m, x[0], "groupe", [x[1]])
				if raison != "":
					return raison
			m.scene_intime([pnj, o], m.lieu_proche(pnj.pos2d(), 40.0))
			return ""
	return ""


const ATTISER_PAS := [
	"Les obliger à travailler ensemble, %s et %s : une corvée, une seule, à deux.",
	"Les mettre face à face, %s et %s, et les laisser vider leur sac. Jusqu'au bout.",
	"Les enfermer dans la même nuit, %s et %s : un orage, une seule lanterne, et toi qui t'en vas.",
]

static func _ennemis_attires_de(m: Node, id: String) -> Array:
	var r := []
	for o in Intime.profils():
		if ennemis_attires(m, id, o) and braise(m, id, o) < BRAISE_MAX and not entre(m, id, o).get("etat", "") in ["liaison", "couple"]:
			r.append(o)
	return r


static func _attiser_avec(m: Node, pnj: Node, o: String) -> void:
	var f: Fiche = m.fiche
	var st: Dictionary = f.stats_totales()
	f.drapeaux["attiser_%s_%d" % [pnj.id, Horloge.jour()]] = true
	var nom := Donnees.prenom(pnj.donnees.nom)
	var seuil := 24 + 3 * braise(m, pnj.id, o)
	var t := ""
	if st.Sag + st.Vol + randi_range(1, 20) >= seuil:
		t = "Ça ne se passe pas comme tu crois. Ça se passe mieux. " + attiser(m, pnj.id, o)
		if braise(m, pnj.id, o) >= BRAISE_MAX:
			m.desirs[pnj.id] = maxi(Intime.desir(m, pnj.id), 60)
			m.desirs[o] = maxi(Intime.desir(m, o), 60)
			t += "\n\nLa haine a changé de nature. Le reste, ils le feront seuls, ou pas."
	else:
		for x in [pnj.id, o]:
			m.relations[x] = clampi(m.relations.get(x, 0) - 10, -100, 100)
		t = "%s et %s finissent par se mettre d'accord sur une seule chose : t'en vouloir (-10 chacun)." % [nom, _nom(m, o)]
	m.sauver_etat()
	Illustrations.montrer("attiser", [pnj.id, o], t)


static func _presenter(m: Node, pnj: Node, o: String) -> void:
	var f: Fiche = m.fiche
	var st: Dictionary = f.stats_totales()
	var t := ""
	if st.Sag + st.Per + randi_range(1, 20) >= 25:
		f.drapeaux["pousse_" + cle(pnj.id, o)] = true
		m.desirs[pnj.id] = mini(100, Intime.desir(m, pnj.id) + 15)
		m.desirs[o] = mini(100, Intime.desir(m, o) + 15)
		m.relations[pnj.id] = clampi(m.relations.get(pnj.id, 0) + 3, -100, 100)
		t = "Tu parles de %s à %s, au bon moment, avec les bons mots. Une lueur dans le regard : « Tu crois ? » (+3)" % [_nom(m, o), Donnees.prenom(pnj.donnees.nom)]
		if Intime.desir(m, pnj.id) >= 50 and Intime.desir(m, o) >= 50 and randf() < 0.5:
			t += "\n\n" + appliquer_evenement(m, "liaison", pnj.id, o)
	else:
		m.relations[pnj.id] = clampi(m.relations.get(pnj.id, 0) - 2, -100, 100)
		t = "%s rit jaune : « %s ? Tu plaisantes. » (-2)" % [Donnees.prenom(pnj.donnees.nom), _nom(m, o)]
	m.sauver_etat()
	Illustrations.montrer("entremetteur", [pnj.id, o], t)


## Les ragots : les dernières nouvelles, et parfois un soupçon de ce qui se cache.
static func ragots(m: Node) -> String:
	var r := []
	var ville: String = "BRU" if m.carte == "brumeval" else "PIE"
	var vus: Array = m.journal_liens.filter(func(e): return _ville(e.ids[0]) == ville)
	for e in vus.slice(maxi(0, vus.size() - 5)):
		r.append("- %s (%s)" % [e.texte, "aujourd'hui" if e.jour == Horloge.jour() else "il y a %d jour%s" % [Horloge.jour() - e.jour, "s" if Horloge.jour() - e.jour > 1 else ""]])
	for k in m.liens:
		var l = m.liens[k]
		if l is Dictionary and l.etat == "liaison" and l.secret and not l.connu and _ville(l.a) == ville and randf() < 0.35:
			l.connu = true
			r.append("- On murmure que %s ne rentre pas toujours seul·e, et que %s a des rougeurs quand %s passe..." % [_nom(m, l.a), _nom(m, l.b), _nom(m, l.a)])
			break
	if r.is_empty():
		return "Rien de neuf. On parle du temps, de la pêche, du prix du sel."
	m.sauver_etat()
	return "On baisse la voix, on se penche :\n" + "\n".join(r)


## Ce qu'il te confie de sa vie (affection 30 ; un secret à 50).
static func confidences(m: Node, pnj: Node) -> String:
	var id: String = pnj.id
	var nom: String = Donnees.prenom(pnj.donnees.nom)
	var aff: int = m.relations.get(id, 0)
	if aff < 30:
		return "%s hausse les épaules : « Ma vie, c'est ma vie. » (affection 30)" % nom
	var r := []
	var c := couple_de(m, id)
	if c != "":
		r.append("« %s et moi, ça tient%s. »" % [_nom(m, c), ", et chacun est libre" if entre(m, id, c).get("ouvert", false) else ""])
	for l in de(m, id, ["liaison"]):
		if l.secret and aff < 50:
			r.append("Un silence, un sourire en coin : il y a quelqu'un, mais tu n'en sauras pas plus. (affection 50)")
		else:
			l.connu = true
			r.append("« Il y a %s, aussi%s. »" % [_nom(m, autre(l, id)), ". Personne ne le sait. Garde-le pour toi" if l.secret else ""])
	for l in de(m, id, ["rompu", "fini"]):
		r.append("« %s ? C'est fini. »" % _nom(m, autre(l, id)))
	if r.is_empty():
		r.append("« Personne. Pas en ce moment. »" + (" Un regard vers toi, qui dure un peu." if Intime.attire_par(Intime.profil(id), m.fiche) and aff >= 40 else ""))
	m.sauver_etat()
	return "%s se confie. %s" % [nom, " ".join(r)]


# ---------------------------------------------------------------- toi au milieu

## Ton couple t'a trompé·e, et tu l'apprends (près de lui ou d'elle).
static func trahison(m: Node, n: Node) -> void:
	var id: String = n.id
	var amant: String = m.fiche.drapeaux.get("trahison_" + id, "")
	m.fiche.drapeaux.erase("trahison_" + id)
	var nom: String = Donnees.prenom(n.donnees.nom)
	var texte := "%s n'arrive pas à te regarder. Puis ça sort : %s, l'autre nuit." % [nom, _nom(m, amant)]
	Illustrations.montrer("lien_trahison", [id, amant], texte)
	await Illustrations.ferme
	var options := [
		["Pardonner", _pardonner.bind(m, n), "Ça fait mal. Mais tu restes."],
		["Rompre", _rompre.bind(m, n), "C'est fini entre vous."],
		["Partager", _partager.bind(m, n, amant), "Plus de secrets : chacun est libre, et pourquoi pas à trois."]]
	var rival: Node = m._pnj_par_id(amant)
	if rival and int(rival.donnees.get("age", "0")) >= 18:
		options.append(["T'expliquer avec %s" % _nom(m, amant), _expliquer.bind(m, rival), "Une bagarre, à mains nues."])
	m.fenetres.choix("On t'a trompé·e", texte, options)


static func _pardonner(m: Node, n: Node) -> void:
	m.relations[n.id] = clampi(m.relations.get(n.id, 0) + 5, -100, 100)
	m.sauver_etat()
	Illustrations.montrer("lien_pardon", [n.id], "Tu le dis tout bas. %s pleure, de soulagement (+5)." % Donnees.prenom(n.donnees.nom))


static func _rompre(m: Node, n: Node) -> void:
	m.fiche.partenaires.erase(n.id)
	m.relations[n.id] = clampi(m.relations.get(n.id, 0) - 10, -100, 100)
	m.fiche.sauver()
	m.sauver_etat()
	Illustrations.montrer("lien_rupture", [n.id], "Tu rends ce qu'il faut rendre. %s ne te retient pas (-10)." % Donnees.prenom(n.donnees.nom))


static func _partager(m: Node, n: Node, amant: String) -> void:
	var nom: String = Donnees.prenom(n.donnees.nom)
	if Intime.profil(n.id).partage < 40:
		m.relations[n.id] = clampi(m.relations.get(n.id, 0) - 5, -100, 100)
		Illustrations.montrer("lien_ouvert", [n.id], "%s secoue la tête : « Je ne veux pas de ça. C'était une erreur. » (-5)" % nom)
		return
	m.fiche.drapeaux["ouvert_" + n.id] = true
	var l := entre(m, n.id, amant)
	if not l.is_empty():
		l.secret = false
		l.connu = true
	m.fiche.sauver()
	m.sauver_etat()
	Illustrations.montrer("lien_ouvert", [n.id, amant], "Plus de secrets. %s, toi, et %s s'il le veut : chacun est libre, et la porte est ouverte à trois." % [nom, _nom(m, amant)])


static func _expliquer(m: Node, rival: Node) -> void:
	m.combat_contre_pnj(rival, "bagarre")


## Un couple (ou des amants) qui t'aime bien, à côté de toi, avec l'envie : ils t'invitent. Une fois par jour.
static func invitation_possible(m: Node) -> Array:
	if not m.fiche.options.get("adulte", true) or m.enfant_proche(m.joueur.pos2d()):
		return []
	for k in m.liens:
		var l = m.liens[k]
		if not l is Dictionary or not l.etat in ["liaison", "couple"] or l.secret:
			continue
		if m.fiche.drapeaux.has("invite_%s_%d" % [k, Horloge.jour()]):
			continue
		var a: Node = m._pnj_par_id(l.a)
		var b: Node = m._pnj_par_id(l.b)
		if a == null or b == null or not a.visible or not b.visible or a.mort or b.mort or a.suit or b.suit:
			continue
		if a.pos2d().distance_to(m.joueur.pos2d()) > 8.0 or b.pos2d().distance_to(m.joueur.pos2d()) > 8.0:
			continue
		var ok := true
		for n in [a, b]:
			var p := Intime.profil(n.id)
			if p.partage < 50 or "groupe" in p.refuse or not Intime.attire_par(p, m.fiche) or m.relations.get(n.id, 0) < 40 or Intime.desir(m, n.id) < 60:
				ok = false
		if ok:
			m.fiche.drapeaux["invite_%s_%d" % [k, Horloge.jour()]] = true
			return [a, b]
	return []


static func inviter(m: Node, a: Node, b: Node) -> void:
	var texte := "%s et %s échangent un regard, puis te regardent. %s, tout bas : « On rentre. Tu viens avec nous ? »" % [
		Donnees.prenom(a.donnees.nom), Donnees.prenom(b.donnees.nom), Donnees.prenom(a.donnees.nom)]
	Illustrations.montrer("lien_invitation", ["+".join([a.id, b.id])] + [a.id, b.id], texte)
	await Illustrations.ferme
	m.fenetres.choix("Une invitation", texte, [
		["Les suivre", _suivre.bind(m, a, b), "Une nuit à trois."],
		["Décliner avec un sourire", func(): pass, "« Une autre fois. » Ils ne t'en veulent pas."],
		["Refuser net", _refuser.bind(m, a, b), "Ils rougissent, un peu vexés (-3)."]])


static func _suivre(m: Node, a: Node, b: Node) -> void:
	m.scene_intime([a, b], m.lieu_proche(a.pos2d(), 40.0))


static func _refuser(m: Node, a: Node, b: Node) -> void:
	for n in [a, b]:
		m.relations[n.id] = clampi(m.relations.get(n.id, 0) - 3, -100, 100)
	m.sauver_etat()
