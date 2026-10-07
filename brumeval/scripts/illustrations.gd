# Une image ou une animation à chaque action.
#
# Où ranger tes fichiers (le premier trouvé gagne) :
#   illustrations/<action>/<pnj>.<ext>     ex. illustrations/parler/BRU001.png
#   illustrations/<action>/<lieu>.<ext>    ex. illustrations/dormir/taverne.png
#   illustrations/<action>/defaut.<ext>    ex. illustrations/pecher/defaut.ogv
# Le dossier est cherché dans le projet (res://illustrations) puis dans
# user://illustrations (pratique pour ajouter des fichiers sans rouvrir Godot).
#
# Formats : png, jpg, jpeg, webp (image) ; ogv (vidéo Theora) ;
# ou un dossier d'images numérotées (01.png, 02.png…) pour une animation,
# avec un fichier fps.txt facultatif (12 images par seconde par défaut).
#
# Sans fichier : écran noir et description de l'action.
extends CanvasLayer

signal ferme

const IMAGES := ["png", "jpg", "jpeg", "webp"]
const RACINES := ["res://illustrations", "user://illustrations"]

var _fond: ColorRect
var _image: TextureRect
var _video: VideoStreamPlayer
var _texte: Label
var _aide: Label
var _images_anim: Array = []
var _fps := 12.0
var _t := 0.0
var ouvert := false


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fond = ColorRect.new()
	_fond.color = Color.BLACK
	_fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fond)
	_image = TextureRect.new()
	_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	_image.offset_bottom = -150
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_image)
	_video = VideoStreamPlayer.new()
	_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video.offset_bottom = -150
	_video.expand = true
	_video.loop = true
	add_child(_video)
	_texte = Label.new()
	_texte.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_texte.offset_top = -140
	_texte.offset_bottom = -40
	_texte.offset_left = 80
	_texte.offset_right = -80
	_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texte.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texte.add_theme_font_size_override("font_size", 22)
	add_child(_texte)
	_aide = Label.new()
	_aide.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_aide.offset_left = -260
	_aide.offset_top = -34
	_aide.offset_right = -16
	_aide.offset_bottom = -10
	_aide.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_aide.text = "Espace ou E : continuer"
	_aide.modulate = Color(1, 1, 1, 0.6)
	add_child(_aide)
	visible = false


## Affiche l'illustration d'une action. cles = [pnj, lieu] par ordre de priorité.
func montrer(action: String, cles: Array, description: String) -> void:
	_texte.text = description
	_image.texture = null
	_images_anim = []
	_video.stop()
	_video.stream = null
	_video.visible = false
	_image.visible = true
	var trouve := _chercher(action, cles + ["defaut"])
	if trouve.has("video"):
		_video.stream = trouve.video
		_video.visible = true
		_image.visible = false
		_video.play()
	elif trouve.has("images"):
		_images_anim = trouve.images
		_fps = trouve.fps
		_t = 0.0
		_image.texture = _images_anim[0]
	elif trouve.has("image"):
		_image.texture = trouve.image
	visible = true
	ouvert = true
	get_tree().paused = true


func fermer() -> void:
	_video.stop()
	visible = false
	ouvert = false
	get_tree().paused = false
	ferme.emit()


func _process(delta: float) -> void:
	if ouvert and _images_anim.size() > 1:
		_t += delta
		_image.texture = _images_anim[int(_t * _fps) % _images_anim.size()]


func _unhandled_key_input(event: InputEvent) -> void:
	if not ouvert:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_SPACE, KEY_E, KEY_ENTER, KEY_ESCAPE]:
			get_viewport().set_input_as_handled()
			fermer()


func _chercher(action: String, cles: Array) -> Dictionary:
	for racine in RACINES:
		for cle in cles:
			if str(cle) == "":
				continue
			var base: String = "%s/%s/%s" % [racine, action, cle]
			for ext in IMAGES:
				var tex := _charger_image(base + "." + ext)
				if tex:
					return {"image": tex}
			var vid := _charger_video(base + ".ogv")
			if vid:
				return {"video": vid}
			var anim := _charger_dossier(base)
			if not anim.is_empty():
				return anim
	return {}


func _charger_image(chemin: String) -> Texture2D:
	if chemin.begins_with("res://") and ResourceLoader.exists(chemin):
		return load(chemin)
	if FileAccess.file_exists(chemin):
		var img := Image.load_from_file(chemin)
		if img:
			return ImageTexture.create_from_image(img)
	return null


func _charger_video(chemin: String) -> VideoStream:
	if chemin.begins_with("res://") and ResourceLoader.exists(chemin):
		return load(chemin)
	if FileAccess.file_exists(chemin):
		var v := VideoStreamTheora.new()
		v.file = chemin
		return v
	return null


func _charger_dossier(chemin: String) -> Dictionary:
	var dir := DirAccess.open(chemin)
	if dir == null:
		return {}
	var noms := []
	for f in dir.get_files():
		var nom := f.trim_suffix(".import")
		if nom.get_extension().to_lower() in IMAGES and not noms.has(nom):
			noms.append(nom)
	if noms.is_empty():
		return {}
	noms.sort()
	var images := []
	for n in noms:
		var tex := _charger_image(chemin + "/" + n)
		if tex:
			images.append(tex)
	if images.is_empty():
		return {}
	var fps := 12.0
	if FileAccess.file_exists(chemin + "/fps.txt"):
		fps = maxf(1.0, FileAccess.get_file_as_string(chemin + "/fps.txt").strip_edges().to_float())
	return {"images": images, "fps": fps}
