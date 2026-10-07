# Une bête (loup…) : juste un sprite, le combat la déplace.
extends Node3D

var planche := ""
var sprite: Sprite3D


func _ready() -> void:
	sprite = Personnage.sprite(planche)
	add_child(sprite)


func pos2d() -> Vector2:
	return Vector2(position.x, position.z)
