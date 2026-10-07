# Les fenêtres du joueur : le sac (I), le personnage (C) et les marchands.
# 1 à 9 ou un clic choisit une ligne, Échap ferme. Le monde est en pause pendant ce temps.
extends CanvasLayer

var monde: Node3D
var ouvert := ""                  # "", "sac", "perso", "marchand"
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
	ouvert = ""
	_panneau.visible = false
	_message.text = ""
	_marchand = null
	get_tree().paused = false
	monde.fiche.sauver()


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
	_titre.text = "Toi · niveau %d" % f.niveau
	var comps: Array = f.competences().map(func(k): return Combattant.COMPETENCES[k].nom)
	_entete.text = "Expérience : %d / %d · PV %d/%d · points à répartir : %d\nCompétences : %s" % [
		f.xp, f.xp_suivant(), f.pv, f.pv_max(), f.points, ", ".join(comps) if comps else "aucune"]
	_vider()
	_detail.text = "Frappe lourde à For 10 ; Coup sournois à Agi 10 avec une dague ; Tir précis à Per 10 avec un arc."
	const NOMS := {"For": "Force", "Agi": "Agilité", "End": "Endurance", "Vit": "Vitalité", "Rob": "Robustesse",
		"Int": "Intelligence", "Sag": "Sagesse", "Per": "Perception", "Vol": "Volonté"}
	const ROLES := {"For": "dégâts des armes lourdes, porter", "Agi": "ordre des tours, déplacement, esquive, dagues et arcs",
		"End": "endurance pour les compétences", "Vit": "points de vie", "Rob": "défense, bouclier",
		"Int": "sorts, fabrication", "Sag": "mana, soins", "Per": "toucher, critiques", "Vol": "résister à la magie"}
	for s in Combattant.STATS:
		var bonus: int = t[s] - f.stats[s]
		var texte := "%s : %d" % [NOMS[s], t[s]]
		if bonus != 0:
			texte += " (%d %+d)" % [f.stats[s], bonus]
		if f.points > 0:
			texte += "   [+1]"
		_ligne(texte, _monter.bind(s), ROLES[s], f.points > 0)


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
	return maxi(1, p)


func prix_vente(id: String) -> int:
	return maxi(1, Objets.prix(id) / 2)


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
