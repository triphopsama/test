# Les scènes datées de la chronique (data/scenes.csv, data/scenes_choix.csv) : ce qui se passe
# tel jour, à telle heure, à tel endroit, avec ou sans toi (monde/chronique/joueur/).
#
# scenes.csv
#   id          nom technique, aussi le dossier d'illustrations (illustrations/<id>/)
#   carte       brumeval, pierrefane
#   jour        le jour (1, 2, 3…)
#   debut, fin  heures (8.5 = 8 h 30) : pendant ce temps, les PNJ de la colonne pnj vont au lieu
#   lieu        cle du lieu ; rayon : à combien de mètres tu dois être (30 par défaut)
#   pnj         ids séparés par des virgules (ils sont mis en scène, même sans toi)
#   condition   quand la scène existe (voir plus bas) ; vide : toujours
#   titre, texte  ce que tu vois en arrivant
#   sans_toi    les effets si la scène se termine sans que tu aies choisi (le monde continue)
#
# scenes_choix.csv
#   scene, id, texte, detail
#   condition   quand ce choix est proposé
#   test        un jet : « Agi 20 » (ta caractéristique + 1d20 contre 20) ; « Int 25 +crochetage 5 »
#               (bonus si tu as la compétence) ; vide : pas de jet
#   effets, texte_ok          si le jet réussit (ou s'il n'y a pas de jet)
#   effets_rate, texte_rate   s'il rate
#
# Conditions (séparées par « ; », toutes vraies) :
#   fil X=a|b     le fil X vaut a ou b (« - » : pas encore de valeur) ; fil X!=a
#   aff ID>=n     affection du PNJ envers toi (aussi <=, >, <)
#   stat For>=n   ta caractéristique ; comp crochetage ; objet BRV011 ; bourse>=n (cuivre)
#   peuple homme_bete|demon ; sexe femme ; vu ID / pasvu ID (une autre scène)
#   ves capturee|libre|rachetee|hangar|partie|- (Vesperine) ; present ID (le PNJ est là, vivant) ;
#   bien id (ce bien est à toi)
# Effets (séparés par « , ») :
#   fil X=val, aff ID +n, desir ID +n, cuivre +n, objet ID +n, xp n, temps n (minutes),
#   ragot texte (entendu ensuite aux ragots), lecon comp, ves libre|capturee,
#   bien id, pret id, combat ID bagarre|mortel [vesperine], voyage pierrefane, scene ID (enchaîne),
#   ves libre|hangar|partie|capturee, maison (la falaise est à toi), acheter id / racheter id
#   (ouvre l'achat de data/biens.csv), liberer ID (déchire un contrat), partir ID (il quitte le pays),
#   captif charrette|vente|vendu|fin (toi, captif : captif.gd)
class_name Scenes
extends RefCounted

static var _scenes := {}
static var _choix := {}
static var _t := 0.0


static func charger() -> void:
	if not _scenes.is_empty():
		return
	for l in Donnees.lire_csv("res://data/scenes.csv"):
		l.debut = float(l.debut)
		l.fin = float(l.fin)
		l.rayon = float(l.get("rayon", "")) if str(l.get("rayon", "")) != "" else 30.0
		l.pnjs = Array(str(l.pnj).replace(" ", "").split(",", false))
		_scenes[l.id] = l
		_choix[l.id] = []
	for c in Donnees.lire_csv("res://data/scenes_choix.csv"):
		if _choix.has(c.scene):
			_choix[c.scene].append(c)


static func toutes() -> Dictionary:
	charger()
	return _scenes


static func choix_de(id: String) -> Array:
	charger()
	return _choix.get(id, [])


# ---------------------------------------------------------------- les fils

static func fil(m: Node, nom: String) -> String:
	return str(m.fiche.drapeaux.get("fil_" + nom, "-"))


static func poser(m: Node, nom: String, val: String) -> void:
	m.fiche.drapeaux["fil_" + nom] = val


static func vu(m: Node, id: String) -> bool:
	return m.fiche.drapeaux.has("scene_" + id)


# ---------------------------------------------------------------- chaque seconde

static func surveiller(m: Node, delta: float) -> void:
	_t += delta
	if _t < 1.0:
		return
	_t = 0.0
	charger()
	var jour: int = Horloge.jour()
	var h: float = Horloge.heure()
	var actives := {}
	for id in _scenes:
		var s: Dictionary = _scenes[id]
		if s.carte != m.carte or int(s.jour) != jour or not m.lieux.has(s.lieu):
			continue
		if h >= s.fin:
			_finir_sans_toi(m, s)
			continue
		if h < s.debut or m.fiche.drapeaux.has("fin_" + id) or not condition(m, str(s.condition)):
			continue
		for p in s.pnjs:
			actives[p] = s
		if _peut_declencher(m, s):
			declencher(m, s)
	_mettre_en_scene(m, actives)


## Les PNJ d'une scène vont à son lieu (et y apparaissent d'un coup si tu ne les vois pas).
static func _mettre_en_scene(m: Node, actives: Dictionary) -> void:
	for n in m.pnjs:
		if n.suit or n.mort or n.hostile:
			continue
		if actives.has(n.id):
			var s: Dictionary = actives[n.id]
			if n.scene_lieu != s.lieu:
				n.scene_lieu = s.lieu
				n.scene_activite = str(s.titre).to_lower()
				var cible: Vector2 = m.lieux[s.lieu].pos
				var moi: Vector2 = m.joueur.pos2d()
				if n.pos2d().distance_to(cible) > 40.0 and moi.distance_to(n.pos2d()) > 60.0 and moi.distance_to(cible) > 60.0:
					n.position = Vector3(cible.x + randf_range(-3, 3), m.hauteur(cible.x, cible.y), cible.y + randf_range(-3, 3))
		elif n.scene_lieu != "":
			n.scene_lieu = ""


static func _peut_declencher(m: Node, s: Dictionary) -> bool:
	if vu(m, s.id) or m.joueur == null or m.combat != null or Illustrations.ouvert or m.fenetres.ouvert != "" or m.get_tree().paused:
		return false
	return m.joueur.pos2d().distance_to(m.lieux[s.lieu].pos) <= s.rayon


## La scène s'ouvre : le texte, puis les choix possibles.
static func declencher(m: Node, s: Dictionary) -> void:
	m.fiche.drapeaux["scene_" + s.id] = true
	var cles: Array = s.pnjs + [s.lieu, "defaut"]
	Illustrations.montrer(s.id, cles, _remplacer(m, str(s.texte)))
	await Illustrations.ferme
	var options := []
	for c in choix_de(s.id):
		if condition(m, str(c.condition)):
			options.append([str(c.texte), choisir.bind(m, s, c), _detail(c)])
	if options.is_empty():
		m.fiche.drapeaux["fin_" + s.id] = true
		return
	options.append(["Ne rien faire", _rien.bind(m, s), "Le monde continue sans toi."])
	m.fenetres.choix(str(s.titre), _remplacer(m, str(s.texte)), options)


static func _detail(c: Dictionary) -> String:
	var d := str(c.get("detail", ""))
	if str(c.get("test", "")) != "":
		d += ("  " if d != "" else "") + "(jet : %s)" % c.test
	return d


static func _rien(m: Node, s: Dictionary) -> void:
	_finir_sans_toi(m, s)


static func choisir(m: Node, s: Dictionary, c: Dictionary) -> void:
	m.fiche.drapeaux["fin_" + s.id] = true
	var reussi := jet(m, str(c.get("test", "")))
	var effets := str(c.effets) if reussi else str(c.get("effets_rate", ""))
	var texte := str(c.texte_ok) if reussi else str(c.get("texte_rate", ""))
	if texte == "":
		texte = str(c.texte_ok)
	var suite := appliquer(m, effets)
	m.fiche.sauver()
	m.sauver_etat()
	if texte != "":
		Illustrations.montrer("%s_%s" % [s.id, c.id], s.pnjs + [s.lieu, "defaut"], _remplacer(m, texte))
		await Illustrations.ferme
	_suite(m, suite)


static func _finir_sans_toi(m: Node, s: Dictionary) -> void:
	if m.fiche.drapeaux.has("fin_" + s.id):
		return
	m.fiche.drapeaux["fin_" + s.id] = true
	if condition(m, str(s.condition)):
		appliquer(m, str(s.get("sans_toi", "")))
		m.fiche.sauver()


## Après les effets : un combat ou une autre scène à lancer.
static func _suite(m: Node, suite: Dictionary) -> void:
	if suite.has("combat"):
		var n: Node = m._pnj_par_id(suite.combat[0])
		if n and not n.mort:
			if suite.combat[2]:
				m.fiche.drapeaux["vesperine"] = "combat"
				m.combat_contre_pnj(n, suite.combat[1], {"vesperine": true})
			else:
				m.combat_contre_pnj(n, suite.combat[1])
	elif suite.has("acheter"):
		Biens.acheter(m, suite.acheter)
	elif suite.has("racheter"):
		Biens.racheter(m, suite.racheter)
	elif suite.has("scene") and _scenes.has(suite.scene):
		declencher(m, _scenes[suite.scene])
	elif suite.has("voyage"):
		m.voyager(suite.voyage)
	elif suite.has("montrer"):
		Illustrations.montrer("captif_vendu", ["captif"], suite.montrer)


static func _remplacer(m: Node, t: String) -> String:
	return t.replace("{bourse}", Objets.texte_prix(m.fiche.bourse))


# ---------------------------------------------------------------- conditions et jets

static func condition(m: Node, c: String) -> bool:
	for morceau in c.split(";", false):
		if not _vrai(m, morceau.strip_edges()):
			return false
	return true


static func _comparer(a: float, op: String, b: float) -> bool:
	match op:
		">=": return a >= b
		"<=": return a <= b
		">": return a > b
		"<": return a < b
		"=": return a == b
	return false


static func _op(t: String) -> Array:
	for op in [">=", "<=", "!=", ">", "<", "="]:
		var i := t.find(op)
		if i > 0:
			return [t.substr(0, i), op, t.substr(i + op.length())]
	return [t, "", ""]


static func _vrai(m: Node, t: String) -> bool:
	if t == "":
		return true
	if t.begins_with("bourse"):
		var ob := _op(t)
		return _comparer(float(m.fiche.bourse), ob[1], float(ob[2]))
	var mot := t.get_slice(" ", 0)
	var reste := t.substr(mot.length()).strip_edges()
	var f: Fiche = m.fiche
	match mot:
		"fil":
			var o := _op(reste)
			var vals := Array(str(o[2]).split("|"))
			var v := fil(m, o[0])
			return (v in vals) if o[1] == "=" else not (v in vals)
		"aff":
			var o := _op(reste)
			return _comparer(float(m.relations.get(o[0], 0)), o[1], float(o[2]))
		"stat":
			var o := _op(reste)
			return _comparer(float(f.stats_totales().get(o[0], 0)), o[1], float(o[2]))
		"comp":
			return reste in f.competences()
		"objet":
			return f.nombre(reste) > 0
		"bourse":
			var o := _op("bourse" + reste)
			return _comparer(float(f.bourse), o[1], float(o[2]))
		"peuple":
			return f.peuple in Array(reste.split("|"))
		"sexe":
			return f.sexe.to_lower() == reste
		"vu":
			return vu(m, reste)
		"pasvu":
			return not vu(m, reste)
		"ves":
			var e := Vesperine.etat(m)
			return (e if e != "" else "-") in Array(reste.split("|"))
		"present":
			var n: Node = m._pnj_par_id(reste)
			return n != null and not n.mort and m.present(reste)
		"bien":
			return Biens.statut(m, reste) != ""
	push_warning("condition inconnue : " + t)
	return false


## « Agi 20 » : ta caractéristique + 1d20 contre 20 ; « Int 25 +crochetage 5 ».
static func jet(m: Node, test: String) -> bool:
	if test.strip_edges() == "":
		return true
	var p := test.split(" ", false)
	var total: int = int(m.fiche.stats_totales().get(p[0], 0)) + randi_range(1, 20)
	var i := 2
	while i + 1 < p.size():
		if p[i].begins_with("+") and p[i].substr(1) in m.fiche.competences():
			total += int(p[i + 1])
		i += 2
	return total >= int(p[1])


# ---------------------------------------------------------------- effets

## Applique les effets ; renvoie ce qui doit suivre (combat, scène, voyage).
static func appliquer(m: Node, effets: String) -> Dictionary:
	var suite := {}
	var f: Fiche = m.fiche
	for morceau in effets.split(",", false):
		var t := morceau.strip_edges()
		var mot := t.get_slice(" ", 0)
		var reste := t.substr(mot.length()).strip_edges()
		var p := reste.split(" ", false)
		match mot:
			"fil":
				var o := _op(reste)
				poser(m, o[0], o[2])
			"aff":
				m.relations[p[0]] = clampi(int(m.relations.get(p[0], 0)) + int(p[1]), -100, 100)
			"desir":
				m.desirs[p[0]] = clampi(Intime.desir(m, p[0]) + int(p[1]), 0, 100)
			"cuivre":
				f.bourse = maxi(0, f.bourse + int(p[0]))
			"objet":
				if int(p[1]) >= 0:
					f.ajouter(p[0], int(p[1]))
				else:
					for k in -int(p[1]):
						f.retirer(p[0])
			"xp":
				f.gagner_xp(int(p[0]))
			"temps":
				Horloge.avancer(float(p[0]))
			"ragot":
				m.journal_liens.append({"jour": Horloge.jour(), "texte": reste, "ids": ["BRU000", "BRU000"] if m.carte == "brumeval" else ["PIE000", "PIE000"]})
			"lecon":
				if not reste in f.apprises:
					f.apprises.append(reste)
			"ves":
				_vesperine(m, reste)
			"bien":
				Biens.offrir(m, reste, "achat", "", false)
			"pret":
				Biens.offrir(m, reste, "pret", "", false)
			"combat":
				suite.combat = [p[0], p[1] if p.size() > 1 else "bagarre", p.size() > 2 and p[2] == "vesperine"]
			"maison":
				if Maison.niveau(m) == 0:
					Maison._devenir_proprietaire(m)
			"acheter":
				suite.acheter = reste
			"racheter":
				suite.racheter = reste
			"liberer":
				Biens._liberer_id(m, reste)
			"partir":
				f.drapeaux["parti_" + reste] = true
				f.equipiers.erase(reste)
			"captif":
				match reste:
					"fin":
						Captif.fin(m)
					"vendu":
						suite.montrer = Captif.vendu(m)
						Biens.installer.call_deferred(m)
					_:
						poser(m, "captif", reste)
			"scene":
				suite.scene = reste
			"voyage":
				suite.voyage = reste
			_:
				push_warning("effet inconnu : " + t)
	return suite


## Vesperine change d'état : libre (à Brumeval), hangar (cachée à Pierrefane), partie (en mer),
## capturee (reprise).
static func _vesperine(m: Node, etat: String) -> void:
	var n: Node = Vesperine.noeud(m)
	match etat:
		"libre":
			Vesperine.liberer(m, "")
			if m.carte == "brumeval":
				Vesperine.installer(m)
			elif n:
				m.pnjs.erase(n)
				n.queue_free()
			return
		"partie", "capturee", "hangar":
			if n:
				m.pnjs.erase(n)
				n.queue_free()
	m.fiche.drapeaux["vesperine"] = etat
	if etat == "capturee":
		m.fiche.drapeaux["vente_faite"] = true
	m.fiche.sauver()
	if m.carte == "pierrefane":
		Biens.installer.call_deferred(m)
