# Outils communs au joueur et aux PNJ : sprite 3D à partir d'une planche 16 × 24.
# Planche : 4 colonnes (marche) × 4 lignes (bas, gauche, droite, haut).
class_name Personnage
extends RefCounted


static func sprite(chemin: String) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = load(chemin)
	s.hframes = 4
	s.vframes = 4
	s.pixel_size = 0.075                       # 24 px = 1,8 m
	s.offset = Vector2(0, 12)                  # les pieds au sol
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = true
	return s


static func ligne_de(d: Vector2) -> int:
	if absf(d.x) > absf(d.y):
		return 1 if d.x < 0.0 else 2
	return 3 if d.y < 0.0 else 0
