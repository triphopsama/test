# La fenêtre d'une nuit : ton image ou ton animation en haut, les jauges de chacun,
# les gestes, et à la fin ce qu'on fait « après ».
#
# Images et animations (même règles que illustrations/LISEZMOI.md) :
#   illustrations/scene_<geste>/<ids>.<ext>   ex. scene_embrasser/BRU013.png,
#                                            scene_a_plusieurs/BRU013+BRU022/ (animation)
#   puis <pnj>, puis le lieu, puis defaut ; à défaut, illustrations/passer_la_nuit/…
extends CanvasLayer

signal finie(texte: String)

var monde: Node
var scene: Dictionary
var _media: TextureRect
var _video: VideoStreamPlayer
var _images: Array = []
var _fps := 12.0
var _t := 0.0
var _jauges: VBoxContainer
var _boutons: VBoxContainer
var _journal: Label


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fond := ColorRect.new()
	fond.color = Color(0.03, 0.02, 0.04)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)
	_media = TextureRect.new()
	_media.set_anchors_preset(Control.PRESET_FULL_RECT)
	_media.offset_bottom = -300
	_media.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_media.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_media)
	_video = VideoStreamPlayer.new()
	_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video.offset_bottom = -300
	_video.expand = true
	_video.loop = true
	add_child(_video)
	var bas := HBoxContainer.new()
	bas.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bas.offset_top = -290
	bas.offset_left = 20
	bas.offset_right = -20
	bas.offset_bottom = -10
	bas.add_theme_constant_override("separation", 20)
	add_child(bas)
	_jauges = VBoxContainer.new()
	_jauges.custom_minimum_size = Vector2(380, 0)
	bas.add_child(_jauges)
	var milieu := VBoxContainer.new()
	milieu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bas.add_child(milieu)
	_journal = Label.new()
	_journal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_journal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	milieu.add_child(_journal)
	var aide := Label.new()
	aide.text = "1-9 ou clic : un geste · Échap : arrêter. Mot d'arrêt : « %s », toujours respecté." % Intime.MOT_D_ARRET
	aide.modulate = Color(1, 1, 1, 0.6)
	aide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	milieu.add_child(aide)
	var defile := ScrollContainer.new()
	defile.custom_minimum_size = Vector2(400, 0)
	defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bas.add_child(defile)
	_boutons = VBoxContainer.new()
	_boutons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defile.add_child(_boutons)


func commencer(m: Node, pnjs: Array, lieu: String, defi := {}) -> void:
	monde = m
	scene = Intime.nouvelle_scene(m, pnjs, lieu)
	if not defi.is_empty():
		if defi.has("risque"):
			scene["risque"] = true
		else:
			scene["defi"] = defi
	get_tree().paused = true
	_montrer_media("passer_la_nuit")
	_journal.text = "Vous êtes seuls. Le reste du monde attend dehors."
	_afficher()


func _cles() -> Array:
	var ids: Array = scene.pnjs.map(func(n): return n.id)
	ids.sort()
	return ["+".join(ids)] + ids + [scene.lieu, "defaut"]


func _montrer_media(action: String) -> void:
	var trouve: Dictionary = Illustrations._chercher(action, _cles())
	if trouve.is_empty() and action != "passer_la_nuit":
		trouve = Illustrations._chercher("passer_la_nuit", _cles())
	if trouve.is_empty():
		return   # on garde l'image d'avant
	_video.stop()
	_video.visible = trouve.has("video")
	_media.visible = not _video.visible
	_images = []
	if trouve.has("video"):
		_video.stream = trouve.video
		_video.play()
	elif trouve.has("images"):
		_images = trouve.images
		_fps = trouve.fps
		_media.texture = _images[0]
	else:
		_media.texture = trouve.image


func _process(delta: float) -> void:
	if _images.size() > 1:
		_t += delta
		_media.texture = _images[int(_t * _fps) % _images.size()]


func _jauge(parent: Control, nom: String, valeur: float, couleur: Color) -> void:
	var l := HBoxContainer.new()
	var t := Label.new()
	t.text = nom
	t.custom_minimum_size = Vector2(80, 0)
	l.add_child(t)
	var b := ProgressBar.new()
	b.max_value = 100
	b.value = valeur
	b.custom_minimum_size = Vector2(260, 16)
	b.show_percentage = false
	b.modulate = couleur
	l.add_child(b)
	parent.add_child(l)


func _afficher() -> void:
	for c in _jauges.get_children():
		_jauges.remove_child(c)
		c.queue_free()
	for n in scene.pnjs:
		var b: Dictionary = scene.barres[n.id]
		var titre := Label.new()
		titre.text = "%s%s" % [n.donnees.nom, "  · comblé·e" if b.comble else ("  · arrêté" if b.stop else "")]
		_jauges.add_child(titre)
		_jauge(_jauges, "Plaisir", b.plaisir, Color(1.0, 0.5, 0.7))
		_jauge(_jauges, "Désir", b.desir, Color(0.9, 0.25, 0.25))
		_jauge(_jauges, "Malaise", b.malaise, Color(0.6, 0.6, 0.65))
		if b.intensite > 0.0:
			_jauge(_jauges, "Intensité", b.intensite, Color(0.6, 0.35, 0.9))
	var moi := Label.new()
	moi.text = "Toi"
	_jauges.add_child(moi)
	_jauge(_jauges, "Plaisir", scene.joueur.plaisir, Color(1.0, 0.5, 0.7))
	_jauge(_jauges, "Désir", scene.joueur.desir, Color(0.9, 0.25, 0.25))
	for c in _boutons.get_children():
		_boutons.remove_child(c)
		c.queue_free()
	if scene.fini:
		_bouton("Rester dormir ensemble", _finir.bind("rester"))
		_bouton("Partir avant l'aube", _finir.bind("partir"))
		_bouton("Lui promettre d'être ensemble", _finir.bind("promettre"))
		return
	for g in Intime.gestes_possibles(monde, scene):
		_bouton(g.nom, _geste.bind(g.id))
	for n in _invitables():
		_bouton("Inviter %s à se joindre" % Donnees.prenom(n.donnees.nom), _inviter.bind(n))
	_bouton("Arrêter", _arreter)


func _bouton(texte: String, appel: Callable) -> void:
	var b := Button.new()
	var i := _boutons.get_child_count() + 1
	b.text = ("%d. " % i if i <= 9 else "") + texte
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.tooltip_text = texte
	b.pressed.connect(appel)
	_boutons.add_child(b)


## Ceux qui sont à côté et voudraient se joindre (harem, nuit à plusieurs).
func _invitables() -> Array:
	return monde.temoins(15.0).filter(_peut_rejoindre)


func _peut_rejoindre(n: Node) -> bool:
	if n in scene.pnjs or Intime.profil(n.id).is_empty():
		return false
	for x in scene.pnjs:
		if Intime.profil(x.id).partage < 50:
			return false
	return Intime.consentement(monde, n, "groupe", scene.pnjs) == ""


func _geste(id: String) -> void:
	var lignes := Intime.jouer(monde, scene, id)
	if lignes.is_empty():
		lignes = [Intime.geste(id).nom + "."]
	_journal.text = "\n".join(lignes)
	_montrer_media("scene_" + id)
	_afficher()


func _inviter(n: Node) -> void:
	Intime.ajouter(monde, scene, n)
	_journal.text = "%s vous rejoint." % Donnees.prenom(n.donnees.nom)
	_montrer_media("scene_a_plusieurs")
	_afficher()


## Le joueur arrête : c'est respecté aussi.
func _arreter() -> void:
	scene.fini = true
	_journal.text = "Tu arrêtes. Personne ne t'en veut."
	_afficher()


func _finir(apres: String) -> void:
	var texte := Intime.finir(monde, scene, apres)
	_video.stop()
	get_tree().paused = false
	finie.emit(texte)
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: int = event.physical_keycode
	if k == KEY_ESCAPE and not scene.fini:
		_arreter()
	elif k >= KEY_1 and k <= KEY_9 and k - KEY_1 < _boutons.get_child_count():
		(_boutons.get_child(k - KEY_1) as Button).pressed.emit()
	get_viewport().set_input_as_handled()
