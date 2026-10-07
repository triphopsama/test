# Les fenêtres du joueur : le sac (I), le personnage (C) et les marchands.
# 1 à 9 ou un clic choisit une ligne, Échap ferme. Le monde est en pause pendant ce temps.
extends CanvasLayer

signal ferme

var monde: Node3D
var ouvert := ""                  # "", "sac", "perso", "marchand", "offre", "lecon", "vaincus", "choix"
var _panneau: PanelContainer
var _titre: Label
var _entete: Label
var _liste: VBoxContainer
var _detail: Label
var _message: Label
var _marchand: Node = null
var _vente := false


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panneau = PanelContainer.new()
	_panneau.set_anchors_preset(Control.PRESET_CENTER)
	_panneau.offset_left = -360
	_panneau.offset_right = 360
	_panneau.offset_top = -225
	_panneau.offset_bottom = 330
	var fond := StyleBoxFlat.new()
	fond.bg_color = Color(0.08, 0.08, 0.1, 0.94)
	fond.border_color = Color(0.55, 0.5, 0.4)
	fond.set_border_width_all(2)
	fond.set_corner_radius_all(6)
	_panneau.add_theme_stylebox_override("panel", fond)
	_panneau.visible = false
	add_child(_panneau)
	var marge := MarginContainer.new()
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 14)
	_panneau.add_child(marge)
	var boite := VBoxContainer.new()
	boite.add_theme_constant_override("separation", 8)
	marge.add_child(boite)
	_titre = Label.new()
	_titre.add_theme_font_size_override("font_size", 22)
	boite.add_child(_titre)
	_entete = Label.new()
	_entete.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boite.add_child(_entete)
	var defile := ScrollContainer.new()
	defile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	boite.add_child(defile)
	_liste = VBoxContainer.new()
	_liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defile.add_child(_liste)
	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(0, 48)
	_detail.modulate = Color(1, 1, 1, 0.8)
	boite.add_child(_detail)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	boite.add_child(_message)
	var aide := Label.new()
	aide.text = "1-9 ou clic : choisir · Échap : fermer"
	aide.modulate = Color(1, 1, 1, 0.6)
	boite.add_child(aide)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: Key = event.physical_keycode
	if ouvert != "":
		if k == KEY_ESCAPE or (k == KEY_I and ouvert == "sac") or (k == KEY_C and ouvert == "perso"):
			fermer()
		elif k >= KEY_1 and k <= KEY_9:
			var i: int = k - KEY_1
			if i < _liste.get_child_count():
				var b: Button = _liste.get_child(i)
				if not b.disabled:
					b.pressed.emit()
		get_viewport().set_input_as_handled()
		return
	if Illustrations.ouvert or monde.combat != null or get_tree().paused:
		return
	if k == KEY_I:
		sac()
		get_viewport().set_input_as_handled()
	elif k == KEY_C:
		personnage()
		get_viewport().set_input_as_handled()


func _ouvrir(quoi: String) -> void:
	ouvert = quoi
	_panneau.visible = true
	get_tree().paused = true


func fermer() -> void:
	var etait := ouvert
	ouvert = ""
	_panneau.visible = false
	_message.text = ""
	_marchand = null
	get_tree().paused = false
	monde.fiche.sauver()
	if etait != "":
		ferme.emit()


func _vider() -> void:
	for c in _liste.get_children():
		_liste.remove_child(c)
		c.queue_free()
	_detail.text = ""


func _ligne(texte: String, appel: Callable, detail := "", actif := true) -> void:
	var b := Button.new()
	var n := _liste.get_child_count() + 1
	b.text = ("%d. " % n if n <= 9 else "    ") + texte
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.disabled = not actif
	b.pressed.connect(appel)
	if detail != "":
		b.mouse_entered.connect(func(): _detail.text = detail)
		b.focus_entered.connect(func(): _detail.text = detail)
	_liste.add_child(b)


func _detail_objet(id: String) -> String:
	var o := Objets.get_(id)
	var t := str(o.get("description", ""))
	if str(o.get("conditions", "—")) != "—":
		t += "  (il faut %s)" % o.conditions
	return t


func _ids_tries() -> Array:
	var ordre := ["arme", "bouclier", "armure", "bijou", "consommable", "materiau", "outil"]
	var ids: Array = monde.fiche.sac.keys()
	ids.sort_custom(func(a, b):
		var ta := ordre.find(Objets.get_(a).get("type", ""))
		var tb := ordre.find(Objets.get_(b).get("type", ""))
		return ta < tb if ta != tb else str(a) < str(b))
	return ids


# ---------------------------------------------------------------- le sac

func sac() -> void:
	if ouvert != "sac":
		_ouvrir("sac")
	var f: Fiche = monde.fiche
	_titre.text = "Sac"
	var porte := []
	for e in Objets.EMPLACEMENTS:
		if f.equipement.has(e):
			porte.append("%s : %s" % [Objets.NOMS_EMPLACEMENTS[e], Objets.get_(f.equipement[e]).nom])
	_entete.text = "Bourse : %s · PV %d/%d\nPorté : %s" % [Objets.texte_prix(f.bourse), f.pv, f.pv_max(), ", ".join(porte) if porte else "rien"]
	_vider()
	for id in _ids_tries():
		var o := Objets.get_(id)
		var t := Objets.resume(id)
		if f.nombre(id) > 1:
			t += "  ×%d" % f.nombre(id)
		if f.equipe(id):
			t = "[porté] " + t
		_ligne(t, _choisir_objet.bind(id), _detail_objet(id), Objets.emplacement(id) != "" or o.get("type", "") == "consommable")


func _choisir_objet(id: String) -> void:
	var f: Fiche = monde.fiche
	var o := Objets.get_(id)
	var msg := ""
	if o.type == "consommable":
		msg = f.utiliser(id)
	elif o.type == "parchemin":
		msg = f.lire_parchemin(id)
		if msg.begins_with("Deux heures"):
			Horloge.avancer(120.0)
	elif id == Objets.PIERRE_AFFINITE:
		f.drapeaux["affinites_lues"] = true
		msg = "La pierre tiédit, puis chauffe sous certains doigts plus que d'autres. Tu sais maintenant (C : le personnage)."
	elif f.equipe(id):
		msg = f.desequiper(id)
		if msg == "":
			msg = "Tu retires : %s." % o.nom
	else:
		msg = f.equiper(id)
		if msg == "":
			msg = "Tu prends en main : %s." % o.nom if o.type == "arme" else "Tu portes : %s." % o.nom
	_message.text = msg
	f.sauver()
	sac()


# ---------------------------------------------------------------- le personnage

func personnage() -> void:
	if ouvert != "perso":
		_ouvrir("perso")
	var f: Fiche = monde.fiche
	var t := f.stats_totales()
	_titre.text = "%s · niveau %d" % [f.nom if f.nom != "" else "Toi", f.niveau]
	var classe := "aucune, elle s'éveillera après ton premier vrai combat"
	if f.classe != "":
		classe = "%s niveau %d (%d / %d)" % [Classes.classe(f.classe).nom, f.niveau_classe, f.xp_classe, f.xp_classe_suivant()]
	var metier := "aucun : travaille une journée quelque part pour en apprendre un"
	if f.metier != "":
		metier = "%s, niveau %d (%d / %d h)" % [f.titre_metier(), f.niveau_metier, int(f.xp_metier), int(f.xp_metier_suivant())]
	_entete.text = "Expérience : %d / %d · PV %d/%d · points à répartir : %d\nClasse : %s\nMétier : %s" % [
		f.xp, f.xp_suivant(), f.pv, f.pv_max(), f.points, classe, metier]
	_vider()
	_detail.text = "Survole une ligne pour le détail."
	const NOMS := {"For": "Force", "Agi": "Agilité", "End": "Endurance", "Vit": "Vitalité", "Rob": "Robustesse",
		"Int": "Intelligence", "Sag": "Sagesse", "Per": "Perception", "Vol": "Volonté"}
	const ROLES := {"For": "dégâts des armes lourdes, porter", "Agi": "ordre des tours, déplacement, esquive, dagues et arcs",
		"End": "endurance pour les compétences", "Vit": "points de vie", "Rob": "défense, bouclier",
		"Int": "sorts, fabrication", "Sag": "mana, soins", "Per": "toucher, critiques", "Vol": "résister à la magie"}
	var fav: Array = Classes.classe(f.classe).get("favorites", [])
	for s in Combattant.STATS:
		var bonus: int = t[s] - f.stats[s]
		var texte := "%s : %d" % [NOMS[s], t[s]]
		if bonus != 0:
			texte += " (%d %+d)" % [f.stats[s], bonus]
		if s in fav:
			texte += "  ★"
		if f.points > 0:
			texte += "   [+1]"
		_ligne(texte, _monter.bind(s), ROLES[s] + (" · favorite de ta classe : elle monte d'office à chaque niveau" if s in fav else ""), f.points > 0)
	# les compétences : celles qu'on peut utiliser, celles qui attendent des caractéristiques
	var actives := f.competences()
	for k in f.competences(true):
		var c: Dictionary = Combattant.COMPETENCES[k]
		var etat := "" if k in actives else "  (pas encore : " + _manque(c, t) + ")"
		_ligne("Compétence · %s%s" % [c.nom, etat], func(): pass, _detail_comp(k))
	if f.classe != "":
		var cl := Classes.classe(f.classe)
		for p in cl.competences:
			if not p[0] in f.apprises:
				_ligne("À venir · %s (niveau de classe %d)" % [Combattant.COMPETENCES[p[0]].nom, p[1]], func(): pass, _detail_comp(p[0]))
		_ligne("Évolutions · %s" % cl.evolutions, func(): pass, "Aux niveaux de classe 25, 50 et 75, selon la façon dont tu te bats (pas encore en jeu).")
	if f.metier != "":
		var m := Classes.metier(f.metier)
		for p in m.competences:
			_ligne("Métier · %s%s" % [p[0], "" if f.niveau_metier >= p[1] else " (niveau %d)" % p[1]], func(): pass, m.description)
	# la magie : la mana, et ce qu'on sent de ses affinités (les chiffres avec une pierre d'affinité)
	_ligne("Mana · %d / %d" % [f.mana_actuelle(), f.mana_max()], func(): pass, "Sag × 6 + Int × 2. Revient d'un quart par heure, en entier en dormant.")
	var lues: bool = f.drapeaux.get("affinites_lues", false)
	for e in Combattant.OPPOSES:
		if lues:
			_ligne("Affinité · %s : %d" % [e, f.affinite(e)], func(): pass, "Lue à la pierre d'affinité. Au-dessus de 50, tes sorts de %s sont plus forts et coûtent moins ; sous 20, plus faibles." % e)
		elif f.style.has("magie_" + e):
			_ligne("Affinité · le %s %s" % [e, f.ressenti(e)], func(): pass, "Ce que tu sens en lançant des sorts de %s. Une pierre d'affinité dirait les vrais chiffres." % e)


func _manque(c: Dictionary, t: Dictionary) -> String:
	var r := []
	for st in c.get("cond", {}):
		if t[st] < c.cond[st]:
			r.append("%s %d" % [st, c.cond[st]])
	if c.has("arme"):
		r.append({"dague": "une dague", "arc": "un arc", "lance": "une lance", "bouclier": "un bouclier"}.get(c.arme, c.arme))
	return ", ".join(r)


func _detail_comp(k: String) -> String:
	var c: Dictionary = Combattant.COMPETENCES[k]
	var cout := []
	for r in ["endurance", "mana"]:
		if c.has(r):
			cout.append("%d %s" % [c[r], r])
	var cond := []
	for st in c.get("cond", {}):
		cond.append("%s %d" % [st, c.cond[st]])
	if c.has("arme"):
		cond.append(c.arme)
	return "%s%s%s" % [c.get("desc", c.nom), ("  Coût : " + ", ".join(cout) + ".") if cout else "", ("  Il faut : " + ", ".join(cond) + ".") if cond else ""]


func _detail_classe(id: String) -> String:
	var c := Classes.classe(id)
	var comps: Array = c.competences.map(func(p): return "%s (niv. %d)" % [Combattant.COMPETENCES[p[0]].nom, p[1]])
	return "%s\nFavorites : %s · Compétences : %s\nÉvolutions : %s" % [c.description, ", ".join(c.favorites), ", ".join(comps), c.evolutions]


# ---------------------------------------------------------------- les leçons

## Ce qu'un PNJ peut t'apprendre, et à quel prix : 3 argent pour une compétence de début
## de classe, 6 au-delà ; moitié prix s'il t'apprécie (40), rien s'il t'aime bien (70).
func prix_lecon(pnj: Node, k: String) -> int:
	var id_classe := Classes.par_nom(str(pnj.donnees.get("classe", "")))
	var niveau := 1
	for p in Classes.classe(id_classe).get("competences", []):
		if p[0] == k:
			niveau = p[1]
	var p := 36 if niveau <= 1 else 72
	var aff: int = monde.relations.get(pnj.id, 0)
	if aff >= 70:
		return 0
	return p / 2 if aff >= 40 else p


func lecons(pnj: Node) -> void:
	_marchand = pnj
	if ouvert != "lecon":
		_ouvrir("lecon")
	var f: Fiche = monde.fiche
	_titre.text = "Leçons de %s" % pnj.donnees.nom
	_entete.text = "Ce que %s veut bien t'apprendre. Une leçon dure deux heures. Bourse : %s." % [pnj.donnees.nom.get_slice(" ", 0), Objets.texte_prix(f.bourse)]
	_vider()
	var t := f.stats_totales()
	for k in monde.lecons_de(pnj):
		var c: Dictionary = Combattant.COMPETENCES[k]
		var prix := prix_lecon(pnj, k)
		var manque := ""
		for st in c.get("cond", {}):
			if t[st] < c.cond[st]:
				manque = "il te faut %s %d" % [st, c.cond[st]]
		var texte := "%s · %s" % [c.nom, "gratuit" if prix == 0 else Objets.texte_prix(prix)]
		if manque != "":
			texte += " (%s)" % manque
		_ligne(texte, _apprendre.bind(pnj, k), _detail_comp(k), manque == "" and f.bourse >= prix)
	if _liste.get_child_count() == 0:
		_detail.text = "Tu sais déjà tout ce que %s pourrait t'apprendre." % pnj.donnees.nom.get_slice(" ", 0)


func _apprendre(pnj: Node, k: String) -> void:
	var f: Fiche = monde.fiche
	var prix := prix_lecon(pnj, k)
	f.bourse -= prix
	f.apprises.append(k)
	monde.relations[pnj.id] = clampi(monde.relations.get(pnj.id, 0) + 2, -100, 100)
	Horloge.avancer(120.0)
	f.sauver()
	monde.sauver_etat()
	lecons(pnj)
	_message.text = "Deux heures avec %s. Tu sais maintenant : %s." % [pnj.donnees.nom.get_slice(" ", 0), Combattant.COMPETENCES[k].nom]


# ---------------------------------------------------------------- un choix

## Une question et ses réponses : options = [[texte, appel, détail], …]. Fermer = la dernière.
func choix(titre: String, texte: String, options: Array) -> void:
	_ouvrir("choix")
	_titre.text = titre
	_entete.text = texte
	_vider()
	for o in options:
		_ligne(o[0], _choisir_option.bind(o[1]), o[2] if o.size() > 2 else "")


func _choisir_option(appel: Callable) -> void:
	fermer()
	appel.call()


# ---------------------------------------------------------------- le sort des vaincus

## Après un vrai combat gagné : ceux qui sont à terre. Fermer la fenêtre, c'est les épargner.
func sort_des_vaincus(vaincus: Array) -> void:
	_ouvrir("vaincus")
	_titre.text = "Le sort des vaincus"
	_vider()
	var restants := vaincus.filter(func(c): return not c.mort and not monde.fiche.drapeaux.has("sort_" + c.id + str(Horloge.jour())))
	if restants.is_empty():
		fermer()
		return
	var c: Combattant = restants[0]
	_entete.text = "%s est à terre, à ta merci. Le village saura ce que tu as choisi." % c.nom
	_ligne("Épargner %s" % c.nom, _sort.bind(vaincus, c, "epargner"), "Tu le laisses vivre, et tu poses un bandage. Il te devra la vie (+15), les témoins s'en souviendront (+3).")
	_ligne("Tuer %s" % c.nom, _sort.bind(vaincus, c, "tuer"), "Tu l'achèves. Les morts restent morts, et ceux qui l'ont vu t'en voudront (−30).")


func _sort(vaincus: Array, c: Combattant, choix: String) -> void:
	monde.fiche.drapeaux["sort_" + c.id + str(Horloge.jour())] = true
	if choix == "tuer":
		c.mort = true
		c.noeud.visible = false
		monde.tuer(c)
		_message.text = "%s ne se relèvera pas." % c.nom
	else:
		monde.epargner(c)
		_message.text = "%s respire encore. Il s'en souviendra." % c.nom
	sort_des_vaincus(vaincus)


# ---------------------------------------------------------------- classes et métiers

## Après un vrai combat, sans classe : trois classes selon ce que tu as fait.
func offre_classe() -> void:
	var ids := Classes.offre(monde.fiche.style)
	if ids.is_empty():
		return
	_ouvrir("offre")
	_titre.text = "Une classe s'éveille"
	_entete.text = "Ce combat t'a appris quelque chose sur toi-même. Tu peux prendre une de ces classes, ou attendre une meilleure offre."
	_vider()
	for id in ids:
		var c := Classes.classe(id)
		_ligne("%s · %s" % [c.nom, c.famille], _prendre_classe.bind(id), _detail_classe(id))
	_ligne("Attendre une meilleure offre", fermer, "On te reproposera après un prochain vrai combat, selon ce que tu y feras.")


func _prendre_classe(id: String) -> void:
	var f: Fiche = monde.fiche
	f.prendre_classe(id)
	var annonces := " ".join(f.annonces)
	f.annonces.clear()
	f.sauver()
	personnage()
	_message.text = "Te voilà %s. %s" % [Classes.classe(id).nom.to_lower(), annonces]


## Une journée de travail dans un autre métier que le tien : on propose de changer.
func offre_metier(id: String) -> void:
	var f: Fiche = monde.fiche
	var m := Classes.metier(id)
	_ouvrir("offre")
	_titre.text = "Changer de métier ?"
	_entete.text = "Tu pourrais devenir %s. Tu es %s : en changeant, ton niveau de métier repart de 1." % [
		Classes.titre_metier(m.nom, 1).to_lower(), f.titre_metier().to_lower()]
	_vider()
	_ligne("Devenir %s" % Classes.titre_metier(m.nom, 1).to_lower(), _prendre_metier.bind(id), m.description)
	_ligne("Rester %s" % f.titre_metier().to_lower(), fermer, Classes.metier(f.metier).description)


func _prendre_metier(id: String) -> void:
	monde.fiche.prendre_metier(id)
	monde.fiche.sauver()
	personnage()
	_message.text = "Te voilà %s." % monde.fiche.titre_metier().to_lower()


func _monter(s: String) -> void:
	if monde.fiche.depenser_point(s):
		_message.text = "+1 en %s." % s
	personnage()


# ---------------------------------------------------------------- les marchands

## Ouvre la boutique d'un PNJ (vente = false : tu achètes ; true : tu vends).
func marchand(pnj: Node, vente: bool) -> void:
	_marchand = pnj
	_vente = vente
	_ouvrir("marchand")
	_afficher_marchand()


func prix_achat(id: String) -> int:
	var p := Objets.prix(id)
	if _marchand and monde.relations.get(_marchand.id, 0) >= 50:
		p = int(p * 0.9)            # un ami fait un geste
	if monde.fiche.vie == "commercant":
		p = int(p * 0.95)           # marchandage
	if _marchand and _marchand.id == "BRU011" and monde.fiche.lignee == "marchand":
		p = int(p * 0.95)           # Clan Marchand : entre nains
	return maxi(1, p)


func prix_vente(id: String) -> int:
	var p := Objets.prix(id) / 2.0
	if monde.fiche.vie == "commercant":
		p *= 1.1
	# le métier : un forgeron sait ce que vaut une lame, un couturier un cuir
	var o := Objets.get_(id)
	var n := str(o.get("nom", "")).to_lower()
	var metal := ["maille", "fer", "acier", "plate"].any(func(m): return n.contains(m))
	if o.get("type", "") in ["arme", "bouclier"] or (o.get("type", "") == "armure" and metal):
		p *= 1.0 + monde.fiche.bonus_metier("vente_armes") / 100.0
	elif (o.get("type", "") == "armure" and not metal) or n.begins_with("peau"):
		p *= 1.0 + monde.fiche.bonus_metier("vente_tissus") / 100.0
	return maxi(1, int(p))


func _afficher_marchand() -> void:
	var f: Fiche = monde.fiche
	_titre.text = "%s · %s" % [_marchand.donnees.nom, "tu vends" if _vente else "tu achètes"]
	_entete.text = "Ta bourse : %s" % Objets.texte_prix(f.bourse)
	_vider()
	if _vente:
		for id in _ids_tries():
			if Objets.prix(id) < 0 or f.equipe(id):
				continue
			_ligne("%s ×%d · %s" % [Objets.get_(id).nom, f.nombre(id), Objets.texte_prix(prix_vente(id))], _vendre.bind(id), _detail_objet(id))
		if _liste.get_child_count() == 0:
			_detail.text = "Rien à vendre : ce que tu portes, retire-le d'abord (touche I)."
	else:
		for id in Objets.tous():
			if not str(Objets.get_(id).vendeurs).split(",").has(_marchand.id):
				continue
			var p := prix_achat(id)
			_ligne("%s · %s" % [Objets.resume(id), Objets.texte_prix(p)], _acheter.bind(id), _detail_objet(id), f.bourse >= p)


func _acheter(id: String) -> void:
	var p := prix_achat(id)
	var f: Fiche = monde.fiche
	if f.bourse < p:
		_message.text = "Pas assez d'argent."
		return
	f.bourse -= p
	f.ajouter(id)
	_message.text = "Tu achètes : %s (%s). Pour le porter : touche I." % [Objets.get_(id).nom, Objets.texte_prix(p)]
	f.sauver()
	_afficher_marchand()


func _vendre(id: String) -> void:
	var f: Fiche = monde.fiche
	if not f.retirer(id):
		return
	f.bourse += prix_vente(id)
	_message.text = "Tu vends : %s (%s)." % [Objets.get_(id).nom, Objets.texte_prix(prix_vente(id))]
	f.sauver()
	_afficher_marchand()
