class_name LyraArt
extends RefCounted
## Sprites pixel et portraits de Lyra (extraits par tools/extract_lyra.py).
## Pour remplacer l'art : écraser les PNG dans assets/lyra/, sans toucher au code.

const SPRITE_DIR := "res://assets/lyra/sprites/"
const PORTRAIT_DIR := "res://assets/lyra/portraits/"
## Les sprites de la planche regardent vers la gauche.
const FACES_LEFT := true

static var _cache := {}


static func sprite(pose: String) -> Texture2D:
	return _load(SPRITE_DIR + pose + ".png")


static func portrait(expression: String) -> Texture2D:
	return _load(PORTRAIT_DIR + expression + ".png")


## Dessine un sprite les pieds sur `feet`, retourné si besoin.
static func draw(canvas: CanvasItem, pose: String, feet: Vector2, look_right: bool, modulate := Color.WHITE) -> void:
	var tex := sprite(pose)
	if tex == null:
		return
	var flip := look_right == FACES_LEFT
	canvas.draw_set_transform(feet, 0, Vector2(-1 if flip else 1, 1))
	canvas.draw_texture(tex, Vector2(-tex.get_width() / 2.0, -tex.get_height()), modulate)
	canvas.draw_set_transform(Vector2.ZERO)


static func _load(path: String) -> Texture2D:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]
