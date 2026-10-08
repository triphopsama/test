# L'interface : heure, marée, lieu, menu d'actions (E) et plan du village (Tab).
extends CanvasLayer

var monde: Node3D
var _infos: Label
var _invite: Label
var _annonce: Label
var _t_annonce := 0.0
var _aide: Label
var _menu: PanelContainer
var _liste: VBoxContainer
var _titre: Label
var _plan: TextureRect
var _point: ColorRect
var _cible_pnj: Node = null
var _cible_lieu := ""
var _choix: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_infos = _label(Vector2(16, 12), 18)
	_annonce = _label(Vector2(16, 520), 16)
	_annonce.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_annonce.size = Vector2(760, 0)
	_invite = _label(Vector2(0, 0), 20)
	_invite.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_invite.offset_top = -90
	_invite.offset_left = -300
	_invite.offset_right = 300
	_invite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aide = _label(Vector2(0, 0), 14)
	_aide.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_aide.offset_top = -30
	_aide.offset_left = 16
	_aide.modulate = Color(1, 1, 1, 0.7)

	_menu = PanelContainer.new()
	_menu.set_anchors_preset(Control.PRESET_CENTER)
	_menu.offset_left = -220
	_menu.offset_right = 220
	_menu.offset_top = -180
	_menu.visible = false
	add_child(_menu)
	var boite := VBoxContainer.new()
	_menu.add_child(boite)
	_titre = Label.new()
	_titre.add_theme_font_size_override("font_size", 20)
	boite.add_child(_titre)
	_liste = VBoxContainer.new()
	boite.add_child(_liste)

	_plan = TextureRect.new()
	_plan.texture = load("res://images/plan.png" if monde.carte == "brumeval" else "res://images/plan_%s.png" % monde.carte)
	_plan.set_anchors_preset(Control.PRESET_FULL_RECT)
	_plan.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_plan.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_plan.visible = false
	add_child(_plan)
	_point = ColorRect.new()
	_point.color = Color(1, 0.1, 0.1)
	_point.size = Vector2(10, 10)
	_plan.add_child(_point)


func _label(pos: Vector2, taille: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(l)
	return l


const AIDE := "ZQSD / flèches : marcher · Maj : courir · E : agir · I : sac · C : personnage · Tab : plan · T : accélérer le temps · molette : zoom"
const AIDE_COMBAT := "1-9 : choisir une action · clic : choisir une case · Échap : revenir au menu · molette : zoom"


func _process(_delta: float) -> void:
	_aide.text = AIDE_COMBAT if monde.combat != null else AIDE
	var j: Node3D = monde.joueur
	var p: Vector2 = j.pos2d()
	var lieu: String = monde.lieu_proche(p, 40.0)
	var acc := "" if Horloge.acceleration == 1.0 else "  (temps ×%d)" % int(Horloge.acceleration)
	var bm: Array = Horloge.basses_mers()
	var maree := "basse : rochers praticables" if Horloge.maree_basse() else "haute"
	var f: Fiche = monde.fiche
	_infos.text = "Jour %d · %s%s\nMarée %s (basse mer à %s et %s)\n%s\nPV %d/%d · niveau %d%s%s · bourse : %s" % [
		Horloge.jour(), Horloge.texte_heure(), acc, maree,
		Horloge.texte_heure(bm[0]), Horloge.texte_heure(fposmod(bm[1], 24.0)),
		monde.lieux[lieu].nom if lieu != "" else "Dans la nature",
		f.pv, f.pv_max(), f.niveau, " (%d points à répartir)" % f.points if f.points > 0 else "",
		(" · %s %d" % [Classes.classe(f.classe).nom, f.niveau_classe]) if f.classe != "" else "", Objets.texte_prix(f.bourse)]
	var corps := []
	if f.affame():
		corps.append("Affamé (-1 For, Vol)")
	if f.fatigue():
		corps.append("Fatigué (-2 Per, Agi)")
	if Captif.est(monde):
		corps.append("Captif : un collier de fer")
	if not corps.is_empty():
		_infos.text += "\n" + " · ".join(corps)
	if not f.equipiers.is_empty():
		_infos.text += "\nÉquipe : " + ", ".join(f.equipiers.map(func(id): return _membre(id)))
	if _t_annonce > 0.0:
		_t_annonce -= get_process_delta_time()
		if _t_annonce <= 0.0:
			_annonce.text = ""
	# qui ou quoi est à portée
	_cible_pnj = null
	var dmin := 3.0
	for n in monde.pnjs:
		if n.visible and n.pos2d().distance_to(p) < dmin:
			dmin = n.pos2d().distance_to(p)
			_cible_pnj = n
	_cible_lieu = monde.lieu_proche(p, 15.0)
	if _menu.visible or Illustrations.ouvert or monde.combat != null or monde.fenetres.ouvert != "":
		_invite.text = ""
	elif _cible_pnj:
		_invite.text = "E : %s (%s)" % [_cible_pnj.donnees.nom, _cible_pnj.activite]
	elif _cible_lieu != "" and not monde.actions.disponibles(null, _cible_lieu).is_empty():
		_invite.text = "E : agir ici (%s)" % monde.lieux[_cible_lieu].nom
	else:
		_invite.text = ""
	if _plan.visible:
		var tex_taille: Vector2 = _plan.texture.get_size()
		var echelle := minf(_plan.size.x / tex_taille.x, _plan.size.y / tex_taille.y)
		var origine := (_plan.size - tex_taille * echelle) / 2.0
		_point.position = origine + p * (tex_taille.x / monde.TAILLE.x) * echelle - Vector2(5, 5)


func _membre(id: String) -> String:
	var n: Node = monde._pnj_par_id(id)
	var d := Compagnons.description(monde, id)
	return (Donnees.prenom(n.donnees.nom) if n else id) + (" (%s)" % d if d != "" else "")


## Un message qui s'affiche quelques secondes (les passants qui réagissent…).
func annoncer(texte: String) -> void:
	_annonce.text = texte
	_t_annonce = 8.0


func _unhandled_key_input(event: InputEvent) -> void:
	if Illustrations.ouvert or monde.combat != null or monde.fenetres.ouvert != "" or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: Key = event.physical_keycode
	if _menu.visible:
		if k == KEY_ESCAPE:
			_fermer_menu()
		elif k >= KEY_1 and k <= KEY_9 and k - KEY_1 < _choix.size():
			_choisir(k - KEY_1)
		get_viewport().set_input_as_handled()
		return
	if k == KEY_TAB:
		_plan.visible = not _plan.visible
		get_viewport().set_input_as_handled()
	elif k == KEY_E:
		_ouvrir_menu()
		get_viewport().set_input_as_handled()


func _ouvrir_menu() -> void:
	var lieu: String = monde.lieu_proche(monde.joueur.pos2d(), 40.0)
	_choix = monde.actions.disponibles(_cible_pnj, lieu if _cible_pnj else _cible_lieu)
	if _choix.is_empty():
		return
	_titre.text = _cible_pnj.donnees.nom if _cible_pnj else monde.lieux[_cible_lieu].nom
	for c in _liste.get_children():
		c.queue_free()
	for i in _choix.size():
		var b := Button.new()
		b.text = "%d. %s" % [i + 1, str(_choix[i].nom).replace("{nom}", Donnees.prenom(_cible_pnj.donnees.nom) if _cible_pnj else "")]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_choisir.bind(i))
		_liste.add_child(b)
	var fermer := Button.new()
	fermer.text = "Échap. Rien"
	fermer.pressed.connect(_fermer_menu)
	_liste.add_child(fermer)
	_menu.visible = true
	get_tree().paused = true


func _fermer_menu() -> void:
	_menu.visible = false
	get_tree().paused = false


func _choisir(i: int) -> void:
	var l: Dictionary = _choix[i]
	var pnj := _cible_pnj
	var lieu: String = monde.lieu_proche(monde.joueur.pos2d(), 40.0)
	if pnj == null:
		lieu = _cible_lieu
	_fermer_menu()
	monde.actions.executer(l, pnj, lieu)
