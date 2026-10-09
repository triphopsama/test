# Une bête (loup…) : juste un sprite, le combat la déplace.
extends Node3D

var planche := ""
var sprite: Sprite3D
var suit := false            # apprivoisée : elle te suit
var _t := 0.0


func _ready() -> void:
	sprite = Personnage.sprite(planche)
	add_child(sprite)


func _process(delta: float) -> void:
	if not suit:
		return
	var m := get_parent()
	var but: Vector2 = m.joueur.pos2d()
	var ecart := but - pos2d()
	if ecart.length() > 2.5:
		var p := pos2d() + ecart.normalized() * minf(5.0 * delta, ecart.length() - 2.2)
		position = Vector3(p.x, m.hauteur(p.x, p.y), p.y)
		_t += delta * 8.0
		sprite.frame = Personnage.ligne_de(ecart) * 4 + int(_t) % 4


func pos2d() -> Vector2:
	return Vector2(position.x, position.z)
