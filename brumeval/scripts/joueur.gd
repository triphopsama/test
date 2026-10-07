# Le joueur : ZQSD ou flèches pour marcher, Maj pour courir.
# Ctrl : voyage rapide ×8 (pour tester, à retirer du vrai jeu).
extends Node3D

const MARCHE := 1.5
const COURSE := 4.0

var monde: Node3D
var sprite: Sprite3D
var ligne := 0          # 0 bas, 1 gauche, 2 droite, 3 haut
var _t := 0.0


func _ready() -> void:
	sprite = Personnage.sprite("res://sprites/villageois_planche.png")
	sprite.modulate = Color(0.75, 0.9, 1.0)
	add_child(sprite)


func pos2d() -> Vector2:
	return Vector2(position.x, position.z)


func _process(delta: float) -> void:
	var d := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		d.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		d.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		d.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		d.x += 1.0
	if d == Vector2.ZERO:
		sprite.frame = ligne * 4
		return
	d = d.normalized()
	var court := Input.is_key_pressed(KEY_SHIFT)
	var v := COURSE if court else MARCHE
	if Input.is_key_pressed(KEY_CTRL):
		v *= 8.0
	var p := pos2d()
	var px := p + Vector2(d.x, 0.0) * v * delta
	if monde.praticable(px):
		p = px
	var pz := p + Vector2(0.0, d.y) * v * delta
	if monde.praticable(pz):
		p = pz
	position = Vector3(p.x, monde.hauteur(p.x, p.y), p.y)
	ligne = Personnage.ligne_de(d)
	_t += delta * (10.0 if court else 6.0)
	sprite.frame = ligne * 4 + int(_t) % 4
