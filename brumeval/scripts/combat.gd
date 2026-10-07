# Le combat tactique, sur le décor même (combat.md).
# Une grille de 15 × 15 cases de 1 m se pose autour de l'endroit où ça commence.
# Tour par tour avec une jauge d'action (Vitesse), toucher, flanc et dos,
# hauteur, critiques, états, KO en 3 tours, reddition, fuite.
#
# Modes : "bagarre" (à mains nues, personne ne meurt), "mortel".
extends Node3D

signal fini(resultat: String)
signal _action_joueur

const TAILLE := 15
const MAX_LOG := 9

var monde: Node3D
var mode := "mortel"
var combattants: Array = []
var actif: Combattant
var resultat := ""
var auto := false               # l'IA joue aussi ton camp (test)

var _origine := Vector2.ZERO    # coin de la grille, en mètres
var _cases := {}                # Vector2i -> {pos: Vector3, niveau: int}
var _grille: MultiMeshInstance3D
var _surbrillance: MultiMeshInstance3D
var _choix_cases := {}          # Vector2i -> chemin (déplacement) ou combattant (cible)
var _etat := ""                 # "", "deplacer", "cible"
var _action_en_cours := {}
var _a_bouge := false
var _a_agi := false
var _journal: Array = []

var _ui: CanvasLayer
var _menu: VBoxContainer
var _log: Label
var _ordre: Label
var _info: Label


# ---------------------------------------------------------------- mise en place

func commencer(m: Node3D, allies: Array, ennemis: Array, centre: Vector2, mode_combat: String) -> void:
	monde = m
	mode = mode_combat
	for c in allies:
		c.camp = 0
		combattants.append(c)
	for c in ennemis:
		c.camp = 1
		combattants.append(c)
	if mode == "bagarre":
		for c in combattants:
			c.arme = c.arme if c.arme == Combattant.ARMES.lutte else Combattant.ARMES.poings
			c.competences = c.competences.filter(func(k): return k == "prise")
	_origine = Vector2(floor(centre.x) - TAILLE / 2, floor(centre.y) - TAILLE / 2)
	for j in TAILLE:
		for i in TAILLE:
			var p := _origine + Vector2(i + 0.5, j + 0.5)
			if monde.praticable(p):
				var h: float = monde.hauteur(p.x, p.y)
				_cases[Vector2i(i, j)] = {"pos": Vector3(p.x, h, p.y), "niveau": roundi(h)}
	for c in combattants:
		c.case = _case_libre_proche(c.noeud.position, 3 if c.camp == 1 else 0)
		if not _cases.has(c.case):
			c.case = _case_libre_proche(c.noeud.position)
		if not _cases.has(c.case):
			c.sorti = true
			continue
		c.noeud.position = _cases[c.case].pos
		c.ct = randf_range(0.0, 30.0) + c.vitesse
		c.noeud.set_process(false)
	for c in combattants:
		if c.est_joueur:
			var en_face := ennemis.filter(func(e): return not e.sorti)
			if en_face.size() >= 2:
				_noter(c, "plusieurs")
			if en_face.any(func(e): return e.est_bete):
				_noter(c, "betes")
	_dessiner_grille()
	_construire_ui()
	monde.focus = actif.noeud if actif else combattants[0].noeud
	_ecrire("Le combat commence%s." % (" : une bagarre, à mains nues" if mode == "bagarre" else ""))
	_boucle()


## La case libre la plus proche de p3, à au moins « ecart » cases du camp du joueur.
func _case_libre_proche(p3: Vector3, ecart := 0) -> Vector2i:
	var p := Vector2(p3.x, p3.z)
	var meilleure := Vector2i(-1, -1)
	var dm := INF
	for c in _cases:
		if _occupant(c) != null:
			continue
		var trop_pres := false
		for u in combattants:
			if ecart > 0 and u.camp == 0 and _cases.has(u.case) and absi(u.case.x - c.x) + absi(u.case.y - c.y) < ecart:
				trop_pres = true
		if trop_pres:
			continue
		var d := p.distance_to(Vector2(_cases[c].pos.x, _cases[c].pos.z))
		if d < dm:
			dm = d
			meilleure = c
	return meilleure


func _occupant(c: Vector2i) -> Combattant:
	for u in combattants:
		if u.case == c and not u.mort and not u.sorti:
			return u
	return null


# ---------------------------------------------------------------- dessin

func _tuile() -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(0.94, 0.04, 0.94)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	b.material = m
	return b


func _dessiner_grille() -> void:
	_grille = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _tuile()
	mm.instance_count = _cases.size()
	var i := 0
	for c in _cases:
		mm.set_instance_transform(i, Transform3D(Basis(), _cases[c].pos + Vector3(0, 0.2, 0)))
		mm.set_instance_color(i, Color(1, 1, 1, 0.18))
		i += 1
	_grille.multimesh = mm
	add_child(_grille)
	_surbrillance = MultiMeshInstance3D.new()
	add_child(_surbrillance)


func _surligner(cases: Array, couleur: Color) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _tuile()
	mm.instance_count = cases.size()
	for i in cases.size():
		mm.set_instance_transform(i, Transform3D(Basis(), _cases[cases[i]].pos + Vector3(0, 0.24, 0)))
		mm.set_instance_color(i, couleur)
	_surbrillance.multimesh = mm


# ---------------------------------------------------------------- interface

func _construire_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 20
	add_child(_ui)
	# à gauche : les combattants, puis le menu juste en dessous
	var colonne := VBoxContainer.new()
	colonne.position = Vector2(16, 150)
	colonne.add_theme_constant_override("separation", 10)
	_ui.add_child(colonne)
	_info = Label.new()
	_info.add_theme_constant_override("outline_size", 6)
	_info.add_theme_color_override("font_outline_color", Color.BLACK)
	colonne.add_child(_info)
	var panneau := PanelContainer.new()
	colonne.add_child(panneau)
	_menu = VBoxContainer.new()
	panneau.add_child(_menu)
	var fond_log := PanelContainer.new()
	fond_log.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fond_log.offset_left = -470
	fond_log.offset_top = 90
	fond_log.offset_right = -16
	_ui.add_child(fond_log)
	_log = Label.new()
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.custom_minimum_size = Vector2(440, 0)
	_log.add_theme_font_size_override("font_size", 14)
	fond_log.add_child(_log)
	_ordre = Label.new()
	_ordre.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_ordre.offset_left = -400
	_ordre.offset_right = 400
	_ordre.offset_top = 12
	_ordre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ordre.add_theme_constant_override("outline_size", 6)
	_ordre.add_theme_color_override("font_outline_color", Color.BLACK)
	_ui.add_child(_ordre)


func _ecrire(t: String) -> void:
	_journal.append(t)
	while _journal.size() > MAX_LOG:
		_journal.pop_front()
	if _log:
		_log.text = "\n".join(_journal)
	print("[combat] ", t)


func _maj_ordre() -> void:
	var simu := {}
	for c in combattants:
		simu[c] = c.ct
	var noms := []
	for k in 6:
		var prochain: Combattant = null
		var temps := INF
		for c in combattants:
			if not c.en_jeu():
				continue
			var t: float = (100.0 - simu[c]) / _vitesse(c)
			if t < temps:
				temps = t
				prochain = c
		if prochain == null:
			break
		for c in combattants:
			if c.en_jeu():
				simu[c] += _vitesse(c) * temps
		simu[prochain] = 0.0
		noms.append(prochain.nom)
	_ordre.text = "Ordre : " + " → ".join(noms)
	var lignes := []
	for c in combattants:
		var niv := " (niv %d)" % c.niveau if monde.fiche and monde.fiche.vie == "joueur" and not c.est_joueur else ""
		lignes.append("%s%s%s : %s" % ["▶ " if c == actif else "", c.nom, niv, c.etat_texte()])
	_info.text = "\n".join(lignes)


func _vider_menu() -> void:
	for b in _menu.get_children():
		b.queue_free()


func _bouton(texte: String, appel: Callable, actif_b := true) -> void:
	var b := Button.new()
	b.text = "%d. %s" % [_menu.get_child_count() + 1, texte]
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.disabled = not actif_b
	b.pressed.connect(appel)
	_menu.add_child(b)


# ---------------------------------------------------------------- boucle

func _vitesse(c: Combattant) -> float:
	return c.vitesse * (0.5 if c.etats.has("ralenti") else 1.0) * (0.7 if c.etats.has("gel") else 1.0)


func _boucle() -> void:
	while resultat == "":
		actif = _prochain()
		if actif == null:
			break
		monde.focus = actif.noeud
		_maj_ordre()
		await _tour(actif)
		_verifier_fin()
		await get_tree().create_timer(0.05).timeout
	_terminer()


## Fait avancer les jauges jusqu'au prochain qui joue. Les combattants à terre saignent.
func _prochain() -> Combattant:
	for garde in 10000:
		for c in combattants:
			if c.mort or c.sorti:
				continue
			if c.ct >= 100.0:
				if c.a_terre:
					c.ct = 0.0
					if not c.stable:
						c.tours_saignement -= 1
						if c.tours_saignement <= 0:
							_mourir(c)
						else:
							_ecrire("%s saigne à terre : %d tour(s) avant la mort." % [c.nom, c.tours_saignement])
					continue
				return c
		for c in combattants:
			if not (c.mort or c.sorti):
				c.ct += _vitesse(c) * (0.5 if c.a_terre else 1.0) / 10.0
	return null


func _tour(c: Combattant) -> void:
	_a_bouge = false
	_a_agi = false
	c.etats.erase("garde")
	c.etats.erase("piques")
	if c.a_comp("dernier_debout") and not c.utilise.has("dernier_debout") and c.pv < c.pv_max * 0.3 \
			and combattants.filter(func(o): return o != c and o.camp == c.camp and o.en_jeu()).is_empty():
		c.utilise["dernier_debout"] = true
		c.pv = int(c.pv_max * 0.3)
		_ecrire("%s, dernier debout, serre les dents : %d PV." % [c.nom, c.pv])
	c.endurance = mini(c.endurance_max, c.endurance + int(c.stats.End / 2.0))
	c.mana = mini(c.mana_max, c.mana + int(c.stats.Sag / 4.0))
	if c.etats.has("saignement"):
		var d := maxi(1, int(c.pv_max * 0.03))
		_degats(c, d, "saignement")
		if not c.en_jeu():
			c.ct = 0.0
			return
	if c.etats.has("brulure"):
		_degats(c, maxi(1, int(c.pv_max * 0.05)), "brûlure")
		if not c.en_jeu():
			c.ct = 0.0
			return
	if c.etats.has("etourdi"):
		_ecrire("%s est étourdi et perd son tour." % c.nom)
		_fin_tour(c, 20.0)
		return
	if c.etats.has("renverse"):
		c.etats.erase("renverse")
		_a_bouge = true
		_ecrire("%s se relève." % c.nom)
	if c.camp == 0 and c.est_joueur and not auto:
		await _tour_joueur(c)
	else:
		await _tour_ia(c)


func _fin_tour(c: Combattant, ct_restant: float) -> void:
	c.ct = ct_restant
	for e in c.etats.keys():
		if e == "saignement":
			continue
		c.etats[e] -= 1
		if c.etats[e] <= 0:
			c.etats.erase(e)


func _verifier_fin() -> void:
	var vivants := [0, 0]
	for c in combattants:
		if c.en_jeu():
			vivants[c.camp] += 1
	var joueur_debout := false
	for c in combattants:
		if c.est_joueur and c.en_jeu():
			joueur_debout = true
	if not joueur_debout:
		for c in combattants:
			if c.est_joueur and c.sorti:
				resultat = "fuite"
				return
		resultat = "defaite"
	elif vivants[1] == 0:
		resultat = "victoire"


# ---------------------------------------------------------------- grille : portée

func _voisins(c: Vector2i) -> Array:
	var r := []
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if _cases.has(c + d):
			r.append(c + d)
	return r


## Cases atteignables : {case: chemin}. On traverse ses alliés, pas ses ennemis.
func _atteignables(u: Combattant) -> Dictionary:
	var res := {u.case: [u.case]}
	var file := [u.case]
	var cout := {u.case: 0}
	while not file.is_empty():
		var c: Vector2i = file.pop_front()
		for v in _voisins(c):
			if cout.has(v):
				continue
			if absi(_cases[v].niveau - _cases[c].niveau) > u.saut + (1 if _cases[v].niveau < _cases[c].niveau else 0):
				continue
			var o := _occupant(v)
			if o != null and o.camp != u.camp and not o.a_terre:
				continue
			if cout[c] + 1 > u.deplacement - (2 if u.etats.has("gel") else 0):
				continue
			cout[v] = cout[c] + 1
			res[v] = res[c] + [v]
			file.append(v)
	for c in res.keys():
		if c != u.case and _occupant(c) != null:
			res.erase(c)
	return res


func _distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _cibles(u: Combattant, cle: String) -> Array:
	var comp: Dictionary = Combattant.COMPETENCES.get(cle, {})
	var type: String = comp.get("type", "attaque")
	if type in ["soi", "allies"] or comp.has("zone_soi"):
		return [u]
	if type == "purifier":
		return combattants.filter(func(c): return _a_purifier(u, c, int(comp.portee)))
	var portee: int = comp.get("portee", u.arme.portee)
	var r := []
	if type == "soin" and u.pv < u.pv_max:
		r.append(u)   # les herbes, ça marche aussi sur soi
	for c in combattants:
		if c.mort or c.sorti:
			continue
		var d := _distance(u.case, c.case)
		if d == 0 or d > portee:
			continue
		if c.camp != u.camp and c.etats.has("cache") and d > 1:
			continue
		if comp.get("vs_betes", false) and not c.est_bete:
			continue
		if type == "soin":
			if c.camp == u.camp and not c.a_terre and c.pv < c.pv_max:
				r.append(c)
		elif cle == "bandage":
			if c.camp == u.camp and c.a_terre and not c.stable and d == 1:
				r.append(c)
		elif cle == "achever":
			if c.camp != u.camp and c.a_terre and d == 1:
				r.append(c)
		elif c.camp != u.camp and not c.a_terre:
			r.append(c)
	return r


func _a_purifier(u: Combattant, c: Combattant, portee: int) -> bool:
	if c.camp != u.camp or not c.en_jeu() or _distance(c.case, u.case) > portee:
		return false
	for e in Combattant.ETATS_NEFASTES:
		if c.etats.has(e):
			return true
	return false


# ---------------------------------------------------------------- déplacement

func _deplacer(u: Combattant, chemin: Array) -> void:
	var t := create_tween()
	for c in chemin.slice(1):
		t.tween_property(u.noeud, "position", _cases[c].pos, 0.22 if not auto else 0.01)
	if chemin.size() > 1:
		var d: Vector2i = chemin[-1] - chemin[-2]
		u.orientation = d
		_animer(u, d)
		u.case = chemin[-1]
		if u.etats.has("saignement"):
			_degats(u, maxi(1, int(u.pv_max * 0.02)), "saignement qui s'aggrave")
	await t.finished
	_a_bouge = true
	_noter(u, "bouge")


func _animer(u: Combattant, d: Vector2i) -> void:
	var spr: Sprite3D = u.noeud.get("sprite")
	if spr:
		spr.frame = Personnage.ligne_de(Vector2(d)) * 4


# ---------------------------------------------------------------- frapper

func _cote(att: Combattant, cible: Combattant) -> String:
	var d := att.case - cible.case
	var axe := Vector2i(signi(d.x), 0) if absi(d.x) >= absi(d.y) else Vector2i(0, signi(d.y))
	if axe == cible.orientation:
		return "face"
	if axe == -cible.orientation:
		return "dos"
	return "flanc"


func _attaquer(att: Combattant, cible: Combattant, cle: String) -> void:
	var comp: Dictionary = Combattant.COMPETENCES.get(cle, {"nom": "attaque", "mult": 1.0, "stat": att.arme.stat})
	var type: String = comp.get("type", "attaque")
	att.endurance -= int(comp.get("endurance", 0))
	att.mana -= att.cout_mana(comp)
	if comp.has("element") and comp.get("magique", false):
		_noter(att, "magie_" + comp.element)
		# competences.md : sous 10 d'affinité, le sort rate une fois sur quatre
		if att.affinite(comp.element) < 10 and randi_range(1, 4) == 1:
			_a_agi = true
			_ecrire("%s tente %s, mais l'élément se refuse : rien ne vient." % [att.nom, comp.nom])
			return
	if cible != att:
		var d := cible.case - att.case
		att.orientation = Vector2i(signi(d.x), 0) if absi(d.x) >= absi(d.y) else Vector2i(0, signi(d.y))
		_animer(att, att.orientation)
	_a_agi = true
	match type:
		"soin":
			var bonus := att.bonus_affinite(comp.element) if comp.has("element") else 1.0
			var soin := int(comp.soin * att.stats[comp.stat] * bonus)
			var soignes := [cible]
			if comp.has("zone_soi"):
				soignes = combattants.filter(func(c): return c.camp == att.camp and c.en_jeu() and _distance(c.case, att.case) <= int(comp.zone_soi))
			for c in soignes:
				c.pv = mini(c.pv_max, c.pv + soin)
			_noter(att, "soin")
			_ecrire("%s soigne %s : +%d PV." % [att.nom, ", ".join(soignes.map(func(c): return c.nom)) if cible != att or soignes.size() > 1 else "ses plaies", soin])
			return
		"purifier":
			var chasses := []
			for e in Combattant.ETATS_NEFASTES:
				if cible.etats.has(e):
					cible.etats.erase(e)
					chasses.append(Combattant.NOMS_ETATS.get(e, e))
			_noter(att, "soin")
			_ecrire("%s purifie %s%s." % [att.nom, cible.nom, (" : plus " + ", ".join(chasses)) if chasses else ""])
			return
		"soi":
			att.etats[comp.etat_soi] = int(comp.get("duree", 99))
			if cle == "souffle":
				att.endurance = mini(att.endurance_max, att.endurance + int(att.endurance_max * 0.2))
				att.mana = mini(att.mana_max, att.mana + int(att.mana_max * 0.1))
			if cle == "bouclier_leve":
				_noter(att, "bouclier")
			if cle == "arme_enflammee":
				_noter(att, "enchanter")
			_ecrire("%s : %s." % [att.nom, comp.nom])
			return
		"allies":
			var touches := []
			for c in combattants:
				if c.camp == att.camp and c.en_jeu() and _distance(c.case, att.case) <= int(comp.zone):
					c.etats[comp.etat_allies] = int(comp.duree)
					touches.append(c.nom)
			if cle == "rune_garde":
				_noter(att, "enchanter")
			_ecrire("%s : %s ! (%s)" % [att.nom, comp.nom, ", ".join(touches)])
			return
		"provoquer":
			var resiste: int = 30 + (cible.stats[comp.resiste] - att.stats[comp.stat]) * 3
			if randi_range(1, 100) > clampi(resiste, 5, 95):
				cible.etats["provoque"] = 2
				cible.provoque_par = att
				_ecrire("%s provoque %s, qui ne voit plus que lui." % [att.nom, cible.nom])
			else:
				_ecrire("%s provoque %s, qui ne s'en laisse pas conter." % [att.nom, cible.nom])
			return
		"maudire":
			_noter(att, "maudire")
			var resiste: int = 30 + (cible.stats[comp.resiste] - att.stats[comp.stat]) * 3
			if randi_range(1, 100) > clampi(resiste, 5, 95):
				cible.etats[comp.etat] = Combattant.DUREES.get(comp.etat, 2)
				_ecrire("%s : %s est %s." % [comp.nom, cible.nom, Combattant.NOMS_ETATS.get(comp.etat, comp.etat)])
			else:
				_ecrire("%s : %s résiste." % [comp.nom, cible.nom])
			return
	for i in int(comp.get("coups", 1)):
		if not cible.en_jeu():
			break
		_frapper(att, cible, comp, cle, i == 0)
	if comp.has("zone"):
		for c in combattants:
			if c != cible and c.camp != att.camp and c.en_jeu() and _distance(c.case, cible.case) <= int(comp.zone):
				_frapper(att, c, comp, cle, false)
	if comp.has("recul") and att.en_jeu():
		_degats(att, maxi(1, roundi(comp.recul * att.stats.For)), "le contrecoup")


## Un sort qui frappe : il touche toujours (combat.md, section 5, dégâts magiques).
func _frapper_sort(att: Combattant, cible: Combattant, comp: Dictionary) -> void:
	var e: String = comp.element
	var brut: float = comp.mult * att.stats[comp.stat] * att.bonus_affinite(e)
	var final := brut * 100.0 / (100.0 + cible.def_mag)
	var facteur := cible.facteur_element(e)
	final *= facteur
	var details := [e]
	if facteur >= 1.2:
		details.append("faiblesse")
	elif facteur <= 0.8:
		details.append("résiste")
	if cible.etats.has("mouille"):
		if e == "foudre":
			final *= 1.5
			details.append("trempé")
		elif e == "feu":
			final *= 0.5
			details.append("trempé")
	var ecart_h: int = _cases[att.case].niveau - _cases[cible.case].niveau
	final *= clampf(pow(1.05, ecart_h), 0.8, 1.25)
	if att.etats.has("affaibli"):
		final *= 0.7
	if att.etats.has("concentre"):
		att.etats.erase("concentre")
		final *= 1.3
	final *= randf_range(0.9, 1.1)
	var n := maxi(1, roundi(final))
	_ecrire("%s lance %s sur %s : %d dégâts (%s)." % [att.nom, comp.nom, cible.nom, n, ", ".join(details)])
	_noter(cible, "encaisse")
	_degats(cible, n, "")
	if comp.has("etat") and cible.en_jeu():
		var tient := true
		if comp.has("resiste"):
			var resiste: int = 30 + (cible.stats[comp.resiste] - att.stats[comp.stat]) * 3
			tient = randi_range(1, 100) > clampi(resiste, 5, 95)
		if tient:
			cible.etats[comp.etat] = Combattant.DUREES.get(comp.etat, 2)
			if comp.etat == "mouille":
				cible.etats.erase("brulure")
			if comp.etat == "brulure" and cible.etats.has("mouille"):
				cible.etats.erase("brulure")
			elif cible.etats.has(comp.etat):
				_ecrire("%s est %s." % [cible.nom, Combattant.NOMS_ETATS.get(comp.etat, comp.etat)])


## Note ce que fait le joueur (pour les classes proposées après le combat).
func _noter(c: Combattant, tag: String) -> void:
	if c.est_joueur:
		c.style[tag] = c.style.get(tag, 0) + 1


## Un coup : toucher, esquives, dégâts, états.
func _frapper(att: Combattant, cible: Combattant, comp: Dictionary, cle: String, principal: bool) -> void:
	if comp.get("magique", false):
		_frapper_sort(att, cible, comp)
		return
	var cote := _cote(att, cible)
	if principal and att.etats.has("cache"):
		att.etats.erase("cache")
		cote = "dos"   # sorti de nulle part
	var melee := _distance(att.case, cible.case) == 1
	var imparable: bool = comp.get("imparable", false)
	var cat := Combattant.categorie_arme(att.arme)
	if cle in ["couteaux", "javelot", "pluie_lames"]:
		_noter(att, "lancer")
	elif cle in ["prise", "projection", "coup_tete"]:
		_noter(att, "prise")
	elif principal:
		_noter(att, {"for": "arme_for", "poings": "poings", "lance": "lance", "dague": "dague", "arc": "arc"}[cat])
	_noter(att, "frappe" if melee else "distance")
	if cote != "face":
		_noter(att, "dos")
	var ecart_h: int = _cases[att.case].niveau - _cases[cible.case].niveau
	var chance: int = 85 + (att.stats.Per - cible.stats.Agi) * 2 + int(comp.get("toucher", 0))
	chance += {"face": 0, "flanc": 15, "dos": 30}[cote]
	chance += clampi(ecart_h * 5, -20, 20)
	chance += att.bonus_toucher + (att.bonus_distance if not melee else 0)
	if att.etats.has("aveugle"):
		chance -= 40
	if att.etats.has("inspire"):
		chance += 10
	if att.endurance <= 0:
		chance -= 20
	if cible.etats.has("renverse") or cible.etats.has("etourdi"):
		chance = 100
	chance = clampi(chance, 5, 99) if chance < 100 else 100
	var titre := "%s utilise %s sur %s" % [att.nom, comp.nom, cible.nom] if cle != "" else "%s frappe %s (%s)" % [att.nom, cible.nom, att.arme.nom]
	var touche := randi_range(1, 100) <= chance
	if not touche and att.chance > 0:
		att.chance = 0
		_ecrire("%s : raté… la chance s'en mêle, on rejoue." % titre)
		touche = randi_range(1, 100) <= chance
	elif touche and att.chance < 0:
		att.chance = 0
		_ecrire("%s : touché… la malchance s'en mêle, on rejoue." % titre)
		touche = randi_range(1, 100) <= chance
	# les esquives de la cible
	if touche and melee and not imparable and not (cible.etats.has("renverse") or cible.etats.has("etourdi")):
		if cible.a_comp("esquive_parfaite") and not cible.utilise.has("esquive_parfaite"):
			cible.utilise["esquive_parfaite"] = true
			touche = false
			_ecrire("%s : %s esquive parfaitement." % [titre, cible.nom])
		elif cible.a_comp("pas_de_cote") and randi_range(1, 100) <= 20:
			touche = false
			_ecrire("%s : %s fait un pas de côté." % [titre, cible.nom])
		if not touche:
			_noter(cible, "esquive")
	elif not touche:
		_ecrire("%s : raté (%d %%)." % [titre, chance])
		_noter(cible, "esquive")
	if not touche:
		if melee and cle != "riposte" and cible.a_comp("riposte") and cible.en_jeu() and cible.endurance >= 3:
			cible.endurance -= 3
			_frapper(cible, att, Combattant.RIPOSTE, "riposte", false)
		return
	var brut: float = att.arme.degats + comp.mult * att.stats[comp.stat]
	var defense: int = cible.def_phys
	if cible.ventre_mou and cote != "face":
		defense = cible.stats.Rob / 2   # sur le ventre, la carapace ne protège plus
	if comp.get("vs_betes", false) and cible.est_bete:
		defense /= 2
	if cible.etats.has("rune"):
		defense += 10
	var final := brut * 100.0 / (100.0 + defense)
	final *= {"face": 1.0, "flanc": 1.15, "dos": 1.3}[cote]
	final *= clampf(pow(1.05, ecart_h), 0.8, 1.25)
	var details := []
	if cote != "face":
		details.append("de " + cote)
	if att.etats.has("galvanise"):
		final *= 1.1
	if att.etats.has("affaibli"):
		final *= 0.7
	# la magie dans l'arme : Arme enflammée, Masse sainte (dégâts d'élément en plus)
	var elem := ""
	if att.etats.has("arme_feu"):
		elem = "feu"
		final += 0.5 * att.stats.Int * att.bonus_affinite("feu") * 100.0 / (100.0 + cible.def_mag) * cible.facteur_element("feu")
	elif comp.has("element_bonus"):
		elem = comp.element_bonus
		final += 0.3 * att.stats.Sag * att.bonus_affinite(elem) * 100.0 / (100.0 + cible.def_mag) * cible.facteur_element(elem)
	if elem != "":
		details.append(elem)
	if att.etats.has("concentre"):
		att.etats.erase("concentre")
		final *= 1.3
		details.append("concentré")
	if cote == "face" and cible.etats.has("garde"):
		final *= 0.6
		details.append("bouclier levé")
		_noter(cible, "bouclier")
	var bloque := false
	if not imparable and cote == "face" and cible.bouclier > 0 and randi_range(1, 100) <= cible.bouclier + int(cible.stats.Rob / 2.0):
		final *= 0.4
		bloque = true
		_noter(cible, "bouclier")
	elif not imparable and melee and cible.a_comp("parade") and cible.endurance >= 3 and randi_range(1, 100) <= 30:
		cible.endurance -= 3
		final *= 0.3
		details.append("paré")
		_noter(cible, "bouclier")
	var crit_chance := 5 + int(att.stats.Per / 10.0) + (10 if cote == "dos" else 0) + int(comp.get("crit", 0)) + int(att.arme.get("crit", 0))
	var crit := randi_range(1, 100) <= crit_chance
	if crit:
		final *= 1.5
	final *= randf_range(0.9, 1.1)
	var n := maxi(1, roundi(final))
	if crit:
		details.append("critique")
	if bloque:
		details.append("bloqué au bouclier")
	_ecrire("%s : touché%s, %d dégâts." % [titre, (" " + ", ".join(details)) if details else "", n])
	_noter(cible, "encaisse")
	_degats(cible, n, "", crit)
	if comp.has("etat") and cible.en_jeu():
		var resiste: int = 30 + (cible.stats[comp.resiste] - att.stats[comp.stat]) * 3
		if randi_range(1, 100) > clampi(resiste, 5, 95):
			cible.etats[comp.etat] = Combattant.DUREES.get(comp.etat, 2)
			_ecrire("%s est %s." % [cible.nom, Combattant.NOMS_ETATS.get(comp.etat, comp.etat)])
	if melee and cote == "face" and cible.etats.has("piques") and cible.en_jeu() and att.en_jeu():
		_degats(att, maxi(1, roundi(0.5 * cible.stats.For)), "les piques de " + cible.nom)


func _degats(c: Combattant, n: int, cause: String, crit := false) -> void:
	c.pv -= n
	if c.pv <= 0 and c.increvable:
		c.increvable = false
		c.pv = 1
		_ecrire("%s devrait tomber, mais reste debout à 1 PV." % c.nom)
	if cause != "":
		_ecrire("%s perd %d PV (%s)." % [c.nom, n, cause])
	if c.pv <= 0:
		c.pv = 0
		c.a_terre = true
		c.etats.clear()
		if mode == "bagarre":
			c.stable = true
			_ecrire("%s est au tapis." % c.nom)
		else:
			_ecrire("%s tombe à terre. Il saigne : 3 tours pour le stabiliser." % c.nom)
			if crit and not c.est_bete and randi_range(1, 4) == 1:
				_ecrire("Le coup laisse une blessure grave à %s." % c.nom)
		var spr: Sprite3D = c.noeud.get("sprite")
		if spr:
			spr.rotation_degrees.z = 90.0
			spr.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			spr.rotation_degrees.x = -90.0


func _mourir(c: Combattant) -> void:
	c.mort = true
	_ecrire("%s est mort." % c.nom)
	c.noeud.visible = false
	monde.marquer_mort(c)


# ---------------------------------------------------------------- tour du joueur

func _tour_joueur(u: Combattant) -> void:
	_etat = ""
	while not (_a_bouge and _a_agi):
		_menu_joueur(u)
		var choix = await _action_joueur
		if choix == "attendre":
			_vider_menu()
			_surbrillance.multimesh = null
			u.endurance = mini(u.endurance_max, u.endurance + 10)
			_ecrire("%s attend." % u.nom)
			_fin_tour(u, 40.0 if not (_a_bouge or _a_agi) else 20.0)
			return
		if choix == "fini":
			break
		_maj_ordre()
		if resultat != "" or not u.en_jeu():
			break
		_verifier_fin()
		if resultat != "":
			break
	_vider_menu()
	_surbrillance.multimesh = null
	_fin_tour(u, 0.0 if (_a_bouge and _a_agi) else 20.0)


func _menu_joueur(u: Combattant) -> void:
	_vider_menu()
	_etat = ""
	_surbrillance.multimesh = null
	_bouton("Se déplacer", _choisir_deplacement.bind(u), not _a_bouge)
	_bouton("Attaquer (%s)" % u.arme.nom, _choisir_cible.bind(u, ""), not _a_agi and not _cibles(u, "").is_empty())
	for k in u.competences:
		var comp: Dictionary = Combattant.COMPETENCES[k]
		if comp.get("type", "") in ["passif", "hors_combat"]:
			continue
		var cout := ""
		if u.cout_mana(comp) > 0:
			cout = " (%d mana)" % u.cout_mana(comp)
		elif comp.has("endurance"):
			cout = " (%d end.)" % comp.endurance
		_bouton(comp.nom + cout, _choisir_cible.bind(u, k), not _a_agi and u.peut_payer(comp) and not _cibles(u, k).is_empty())
	if not _cibles(u, "bandage").is_empty():
		_bouton("Bandage (stabiliser)", _choisir_cible.bind(u, "bandage"), not _a_agi)
	if mode != "bagarre" and not _cibles(u, "achever").is_empty():
		_bouton("Achever", _choisir_cible.bind(u, "achever"), not _a_agi)
	if u.est_joueur and monde.fiche and not monde.fiche.soins().is_empty():
		_bouton("Manger ou se soigner (sac)", _menu_soins.bind(u), not _a_agi)
	if u.case.x == 0 or u.case.y == 0 or u.case.x == TAILLE - 1 or u.case.y == TAILLE - 1:
		_bouton("Fuir", _fuir.bind(u))
	_bouton("Se rendre", _se_rendre.bind(u))
	_bouton("Attendre (fin du tour)", func(): _action_joueur.emit("attendre"))


func _choisir_deplacement(u: Combattant) -> void:
	_choix_cases = _atteignables(u)
	_choix_cases.erase(u.case)
	_etat = "deplacer"
	_surligner(_choix_cases.keys(), Color(0.3, 0.6, 1.0, 0.5))


func _choisir_cible(u: Combattant, cle: String) -> void:
	var c_choisie: Dictionary = Combattant.COMPETENCES.get(cle, {})
	if c_choisie.get("type", "") in ["soi", "allies"] or c_choisie.has("zone_soi"):
		await _agir(u, u, cle)
		_action_joueur.emit("ok")
		return
	_choix_cases = {}
	_action_en_cours = {"u": u, "cle": cle}
	for c in _cibles(u, cle):
		_choix_cases[c.case] = c
	_etat = "cible"
	_surligner(_choix_cases.keys(), Color(1.0, 0.3, 0.25, 0.55))


## Les objets qui soignent, pris dans le sac. Ça prend l'action du tour.
func _menu_soins(u: Combattant) -> void:
	_vider_menu()
	for id in monde.fiche.soins():
		_bouton("%s ×%d" % [Objets.resume(id), monde.fiche.nombre(id)], _utiliser.bind(u, id))
	_bouton("Retour", func(): _action_joueur.emit("ok"))


func _utiliser(u: Combattant, id: String) -> void:
	monde.fiche.pv = u.pv
	var t: String = monde.fiche.utiliser(id)
	u.pv = mini(u.pv_max, monde.fiche.pv)
	_ecrire("Toi : " + t)
	_noter(u, "soin")
	_a_agi = true
	_action_joueur.emit("ok")


func _fuir(u: Combattant) -> void:
	u.sorti = true
	_noter(u, "fuite")
	_ecrire("%s prend la fuite." % u.nom)
	_action_joueur.emit("fini")


func _se_rendre(u: Combattant) -> void:
	u.sorti = true
	_ecrire("%s se rend." % u.nom)
	resultat = "reddition"
	_action_joueur.emit("fini")


func _unhandled_input(event: InputEvent) -> void:
	if _etat == "" or Illustrations.ouvert:
		if event is InputEventKey and event.pressed and not event.echo:
			var k: int = event.physical_keycode - KEY_1
			if k >= 0 and k < _menu.get_child_count():
				var b: Button = _menu.get_child(k)
				if not b.disabled:
					b.pressed.emit()
				get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		_etat = ""
		_surbrillance.multimesh = null
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := _case_sous(event.position)
		if not _choix_cases.has(c):
			return
		get_viewport().set_input_as_handled()
		var etat := _etat
		_etat = ""
		_surbrillance.multimesh = null
		if etat == "deplacer":
			await _deplacer(actif, _choix_cases[c])
		else:
			await _agir(_action_en_cours.u, _choix_cases[c], _action_en_cours.cle)
		_action_joueur.emit("ok")


func _case_sous(ecran: Vector2) -> Vector2i:
	var cam: Camera3D = monde.camera
	var meilleure := Vector2i(-1, -1)
	var dm := 40.0
	for c in _choix_cases:
		var p: Vector3 = _cases[c].pos
		if cam.is_position_behind(p):
			continue
		var d := cam.unproject_position(p).distance_to(ecran)
		if d < dm:
			dm = d
			meilleure = c
	return meilleure


func _agir(u: Combattant, cible: Combattant, cle: String) -> void:
	if cle == "bandage":
		cible.stable = true
		_a_agi = true
		_ecrire("%s pose un bandage à %s : il ne mourra pas." % [u.nom, cible.nom])
		_noter(u, "soin")
	elif cle == "achever":
		_a_agi = true
		_ecrire("%s achève %s." % [u.nom, cible.nom])
		_noter(u, "achever")
		_mourir(cible)
		if u.est_joueur:
			monde.tuer(cible)
	else:
		_attaquer(u, cible, cle)
	await get_tree().create_timer(0.3 if not auto else 0.01).timeout


# ---------------------------------------------------------------- tour de l'IA

func _tour_ia(u: Combattant) -> void:
	# reddition ou fuite quand ça tourne mal
	if u.pv < u.pv_max * 0.25 and not u.est_joueur:
		var allies_debout := combattants.filter(func(c): return c.camp == u.camp and c.en_jeu() and c != u).size()
		if randf() < (0.5 if allies_debout == 0 else 0.25):
			u.sorti = true
			_ecrire("%s %s." % [u.nom, "s'enfuit dans les fourrés" if u.est_bete else "lève les mains et se rend"])
			_fin_tour(u, 0.0)
			return
	# un soigneur soigne d'abord
	for k in u.competences:
		var cs: Dictionary = Combattant.COMPETENCES[k]
		if cs.get("type", "") != "soin" or not u.peut_payer(cs):
			continue
		var blesses := _cibles(u, k).filter(func(c): return c.pv < c.pv_max * 0.5)
		if not blesses.is_empty():
			_attaquer(u, blesses[0], k)
			await get_tree().create_timer(0.3 if not auto else 0.01).timeout
			_fin_tour(u, 20.0)
			return
	# un allié à terre à côté : bandage
	var a_bander := _cibles(u, "bandage")
	if not a_bander.is_empty():
		await _agir(u, a_bander[0], "bandage")
		_fin_tour(u, 20.0)
		return
	var cle := ""
	for k in u.competences:
		var comp: Dictionary = Combattant.COMPETENCES[k]
		if comp.get("type", "attaque") != "attaque":
			continue
		if u.peut_payer(comp) and randf() < (0.7 if comp.get("magique", false) else 0.5):
			cle = k
	# provoqué : il ne voit que celui qui l'a provoqué
	var force: Combattant = u.provoque_par if u.etats.has("provoque") and u.provoque_par and u.provoque_par.en_jeu() else null
	var cibles := _cibles(u, cle)
	if force:
		cibles = cibles.filter(func(c): return c == force)
	if cibles.is_empty():
		var options := _atteignables(u)
		var meilleure: Vector2i = u.case
		var score := INF
		var portee: int = u.arme.portee
		for c in options:
			for e in combattants:
				if e.camp == u.camp or not e.en_jeu() or (force and e != force):
					continue
				var d := _distance(c, e.case)
				var s: float = float(absi(d - portee)) * 10.0 + options[c].size() * 0.1
				if d <= portee and d > 0:
					var tmp := Combattant.new()
					tmp.case = c
					s -= {"face": 0, "flanc": 2, "dos": 4}[_cote(tmp, e)]
				if s < score:
					score = s
					meilleure = c
		if meilleure != u.case:
			await _deplacer(u, options[meilleure])
		cibles = _cibles(u, cle)
		if cibles.is_empty():
			cle = ""
			cibles = _cibles(u, "")
		if force:
			cibles = cibles.filter(func(c): return c == force)
	if not cibles.is_empty():
		cibles.sort_custom(func(a, b): return a.pv < b.pv)
		_attaquer(u, cibles[0], cle)
		await get_tree().create_timer(0.35 if not auto else 0.01).timeout
	_fin_tour(u, 0.0 if (_a_bouge and _a_agi) else 20.0)


# ---------------------------------------------------------------- fin

func _terminer() -> void:
	_vider_menu()
	for c in combattants:
		var spr: Sprite3D = c.noeud.get("sprite")
		if spr:
			spr.rotation_degrees = Vector3.ZERO
			spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		if not c.mort:
			c.noeud.set_process(true)
	_ecrire("Fin du combat : %s." % resultat)
	monde.focus = monde.joueur
	fini.emit(resultat)
	queue_free()
