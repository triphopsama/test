# La grotte de Brumeval (monde/donjons/grotte_de_brumeval.md) : huit salles sous la maison de la falaise,
# du puits du jardin Marbre jusqu'à la Bouche de mer.
# Elle est construite à l'écart de la carte, sous le niveau de la mer. Dès que le joueur y est,
# monde.gd lui passe la main pour le sol (hauteur, praticable), et elle éteint le ciel.
# Tout ce qui s'y passe est gardé dans fiche.drapeaux (clés « g_… »).
class_name Grotte
extends RefCounted

const ORIGINE := Vector2(6000, 0)        # loin à l'est de la carte (2 400 m de large)
const SOL := -40.0

## Les salles : rectangle en mètres depuis ORIGINE, et l'endroit où « E : agir » les propose.
const SALLES := {
	"puits": {"nom": "Fond du puits", "rect": Rect2(0, 0, 16, 16), "lieu": Vector2(8, 8)},
	"galerie": {"nom": "Galerie des contrebandiers", "rect": Rect2(26, 4, 34, 8), "lieu": Vector2(36, 8)},
	"inondee": {"nom": "Salle inondée", "rect": Rect2(68, 0, 18, 18), "lieu": Vector2(69, 8.5)},
	"camp": {"nom": "Campement de Gaspard", "rect": Rect2(34, 20, 14, 12), "lieu": Vector2(41, 26)},
	"gouffre": {"nom": "Le Gouffre", "rect": Rect2(28, 40, 26, 18), "lieu": Vector2(41, 44)},
	"lea": {"nom": "Chambre de Léa", "rect": Rect2(72, 42, 10, 10), "lieu": Vector2(77, 47)},
	"veine": {"nom": "La veine d'étoile", "rect": Rect2(28, 66, 26, 24), "lieu": Vector2(41, 70)},
	"bouche": {"nom": "Bouche de mer", "rect": Rect2(34, 98, 14, 12), "lieu": Vector2(41, 103)},
}
const COULOIRS := [Rect2(16, 6, 10, 4), Rect2(60, 7, 8, 3), Rect2(40, 12, 3, 8), Rect2(40, 32, 3, 8),
	Rect2(54, 52, 22, 3), Rect2(76, 18, 3, 24), Rect2(40, 58, 3, 8), Rect2(40, 90, 3, 8)]
## Les autres endroits où agir (en plus du lieu de chaque salle).
const AUTRES_LIEUX := {
	"porte": {"nom": "Porte des astres", "pos": Vector2(53, 8)},
	"inondee_sud": {"nom": "Salle inondée (côté sud)", "pos": Vector2(77.5, 17)},
	"gouffre_sud": {"nom": "Le Gouffre (côté sud)", "pos": Vector2(41, 55)},
}
const PORTE := Rect2(56, 4, 2, 8)              # fermée tant que l'énigme n'est pas résolue
const FAILLE := Rect2(28, 47, 26, 4)           # le vide du gouffre
const MER := Rect2(34, 106, 14, 4)             # le fond de la Bouche de mer est sous l'eau
## Salle inondée à marée haute : seuls ces deux bords restent à sec.
const BORD_OUEST := Rect2(68, 6, 2.5, 5)
const BORD_SUD := Rect2(74, 16, 8, 2)

const ASTRES := ["soleil", "rouge", "mer", "berger", "pale", "lune", "derniere"]
const NOMS_ASTRES := {"soleil": "le Soleil", "rouge": "la Rouge", "mer": "l'Étoile de la Mer", "berger": "l'Étoile du Berger",
	"pale": "la Pâle", "lune": "la Lune", "derniere": "la Dernière"}
const ORDRE_PORTE := ["soleil", "rouge", "mer", "berger", "pale", "lune", "derniere"]
const ORDRE_COFFRE := ["pale", "lune", "rouge", "mer"]
const COMPTINE := "« Le marin part avec le Soleil, la Rouge lui montre le cap, l'Étoile de la Mer le porte, l'Étoile du Berger le garde, la Pâle l'endort, la Lune le berce, et il rentre avec la Dernière. »"

## Les bêtes de la grotte (monde/bestiaire.md), aux niveaux du donjon.
const BETES := {
	"rat": {"nom": "Rat géant", "niveau": 2, "planche": "res://sprites/rat_planche.png", "arme": {"nom": "dents", "degats": 3, "portee": 1, "stat": "Agi"},
		"elements": {"feu": 1.5, "lumière": 1.25},
		"stats": {"For": 4, "Agi": 8, "End": 5, "Vit": 2, "Rob": 3, "Int": 1, "Sag": 1, "Per": 7, "Vol": 2}},
	"crabe": {"nom": "Crabe-rocher", "niveau": 4, "planche": "res://sprites/crabe_planche.png", "arme": {"nom": "pinces", "degats": 8, "portee": 1, "stat": "For"},
		"armure": 10, "ventre_mou": true, "elements": {"foudre": 1.5, "eau": 0.5, "feu": 0.75},
		"stats": {"For": 8, "Agi": 4, "End": 7, "Vit": 6, "Rob": 13, "Int": 1, "Sag": 1, "Per": 5, "Vol": 4}},
	"slime": {"nom": "Slime des profondeurs", "niveau": 5, "planche": "res://sprites/slime_planche.png", "arme": {"nom": "acide", "degats": 7, "portee": 1, "stat": "For"},
		"elements": {"feu": 2.0, "glace": 0.75, "foudre": 1.25},
		"stats": {"For": 7, "Agi": 3, "End": 9, "Vit": 9, "Rob": 5, "Int": 1, "Sag": 1, "Per": 4, "Vol": 8}},
	"araignee": {"nom": "Araignée des cavernes", "niveau": 6, "planche": "res://sprites/araignee_planche.png", "arme": {"nom": "chélicères", "degats": 4, "portee": 1, "stat": "Agi"},
		"competences": ["morsure"], "elements": {"feu": 1.75},
		"stats": {"For": 6, "Agi": 8, "End": 6, "Vit": 3, "Rob": 4, "Int": 1, "Sag": 2, "Per": 10, "Vol": 5}},
	"reine": {"nom": "Reine du nid", "niveau": 9, "planche": "res://sprites/araignee_planche.png", "echelle": 1.6, "arme": {"nom": "chélicères", "degats": 6, "portee": 1, "stat": "Agi"},
		"competences": ["morsure"], "elements": {"feu": 1.5},
		"stats": {"For": 10, "Agi": 9, "End": 10, "Vit": 9, "Rob": 7, "Int": 2, "Sag": 3, "Per": 12, "Vol": 9}},
	"bete": {"nom": "La Bête aveugle", "niveau": 10, "planche": "res://sprites/bete_aveugle_planche.png", "echelle": 2.4, "arme": {"nom": "mâchoires", "degats": 16, "portee": 1, "stat": "For"},
		"competences": ["charge"], "elements": {"lumière": 1.25},
		"stats": {"For": 22, "Agi": 7, "End": 14, "Vit": 28, "Rob": 15, "Int": 1, "Sag": 2, "Per": 3, "Vol": 12}},
}

static var _monde: Node3D
static var _racine: Node3D
static var _torche: OmniLight3D
static var _eau: MeshInstance3D
static var _porte: MeshInstance3D
static var _toiles: Array = []
static var _dedans := false
static var _salle := ""
static var _sequence: Array = []


# ---------------------------------------------------------------- le sol

static func local(p: Vector2) -> Vector2:
	return p - ORIGINE


static func monde_de(l: Vector2) -> Vector2:
	return l + ORIGINE


## Vrai si ce point (coordonnées du monde) est dans la zone de la grotte.
static func contient(p: Vector2) -> bool:
	return p.x >= ORIGINE.x - 4.0 and is_instance_valid(_racine)


static func _creuse(l: Vector2) -> bool:
	for k in SALLES:
		if SALLES[k].rect.has_point(l):
			return true
	for r in COULOIRS:
		if r.has_point(l):
			return true
	return false


static func praticable(p: Vector2) -> bool:
	var l := local(p)
	if not _creuse(l) or FAILLE.has_point(l) or MER.has_point(l):
		return false
	if PORTE.has_point(l) and not _drapeau("g_porte"):
		return false
	if SALLES.inondee.rect.has_point(l) and not Horloge.maree_basse():
		return BORD_OUEST.has_point(l) or BORD_SUD.has_point(l)
	return true


static func hauteur(_x: float, _z: float) -> float:
	return SOL


static func salle_de(p: Vector2) -> String:
	var l := local(p)
	for k in SALLES:
		if SALLES[k].rect.has_point(l):
			return k
	return ""


# ---------------------------------------------------------------- construction

static func construire(m: Node3D) -> void:
	_monde = m
	_dedans = false
	_salle = ""
	_toiles = []
	_racine = null
	if m.carte != "brumeval":
		return
	_racine = Node3D.new()
	_racine.name = "Grotte"
	m.add_child(_racine)
	for k in SALLES:
		m.lieux["g_" + k] = {"id": "GRO_" + k, "nom": SALLES[k].nom, "type": "donjon", "pos": monde_de(SALLES[k].lieu), "h": SOL, "ligne": {}}
	for k in AUTRES_LIEUX:
		m.lieux["g_" + k] = {"id": "GRO_" + k, "nom": AUTRES_LIEUX[k].nom, "type": "donjon", "pos": monde_de(AUTRES_LIEUX[k].pos), "h": SOL, "ligne": {}}
	var roche := _mat(Color(0.24, 0.22, 0.21))
	var sable := _mat(Color(0.5, 0.45, 0.36))
	for k in SALLES:
		var r: Rect2 = SALLES[k].rect
		if k == "gouffre":
			_sol(Rect2(r.position, Vector2(r.size.x, FAILLE.position.y - r.position.y)), roche)
			_sol(Rect2(Vector2(r.position.x, FAILLE.end.y), Vector2(r.size.x, r.end.y - FAILLE.end.y)), roche)
		elif k == "bouche":
			_sol(Rect2(r.position, Vector2(r.size.x, MER.position.y - r.position.y)), sable)
		else:
			_sol(r, roche)
	for r in COULOIRS:
		_sol(r, roche)
	_murs()
	_decor()
	_torche = OmniLight3D.new()
	_torche.light_color = Color(1.0, 0.72, 0.42)
	_torche.light_energy = 1.6
	_torche.omni_range = 9.0
	_torche.position = Vector3(0, 1.8, 0.4)
	_torche.visible = false
	m.joueur.add_child(_torche)


static func _mat(c: Color, emission := Color.BLACK, alpha := 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(c.r, c.g, c.b, alpha)
	mat.roughness = 0.95
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 0.8
	return mat


static func _boite(taille: Vector3, pos_locale: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = taille
	mi.mesh = b
	mi.material_override = mat
	mi.position = Vector3(pos_locale.x + ORIGINE.x, pos_locale.y, pos_locale.z + ORIGINE.y)
	_racine.add_child(mi)
	return mi


static func _sol(r: Rect2, mat: Material) -> void:
	_boite(Vector3(r.size.x, 0.6, r.size.y), Vector3(r.get_center().x, SOL - 0.3, r.get_center().y), mat)


static func _lumiere(pos_locale: Vector3, couleur: Color, portee: float, energie: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = couleur
	l.omni_range = portee
	l.light_energy = energie
	l.position = Vector3(pos_locale.x + ORIGINE.x, pos_locale.y, pos_locale.z + ORIGINE.y)
	_racine.add_child(l)
	return l


## Les parois : un bloc de roche sur chaque case pleine qui touche une case creusée.
## Côté caméra (au sud du passage), les blocs restent bas pour ne pas cacher le joueur.
static func _murs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1897
	var blocs := []
	for z in range(-2, 114):
		for x in range(-2, 92):
			var c := Vector2(x + 0.5, z + 0.5)
			if _creuse(c) or FAILLE.has_point(c):
				continue
			var touche := false
			for dz in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					if _creuse(c + Vector2(dx, dz)):
						touche = true
			if not touche:
				continue
			var devant := _creuse(c + Vector2(0, -1)) or _creuse(c + Vector2(-1, -1)) or _creuse(c + Vector2(1, -1))
			var h := rng.randf_range(0.5, 1.1) if devant else rng.randf_range(2.5, 5.5)
			blocs.append([c, h, rng.randf_range(0.8, 1.15)])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var b := BoxMesh.new()
	b.size = Vector3.ONE
	mm.mesh = b
	mm.instance_count = blocs.size()
	for i in blocs.size():
		var c: Vector2 = blocs[i][0]
		var h: float = blocs[i][1]
		var t := Transform3D(Basis.from_scale(Vector3(1.0, h + 0.6, 1.0)), Vector3(c.x + ORIGINE.x, SOL - 0.6 + (h + 0.6) / 2.0, c.y + ORIGINE.y))
		mm.set_instance_transform(i, t)
		var v: float = blocs[i][2]
		mm.set_instance_color(i, Color(0.27 * v, 0.24 * v, 0.22 * v))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mmi.material_override = mat
	_racine.add_child(mmi)


static func _decor() -> void:
	var bois := _mat(Color(0.36, 0.25, 0.16))
	var fer := _mat(Color(0.3, 0.3, 0.32))
	var os_ := _mat(Color(0.85, 0.82, 0.74))
	# 1. le fond du puits : la corde qui pend, le jour qui tombe d'en haut, des os de moutons
	_boite(Vector3(0.12, 12.0, 0.12), Vector3(8, SOL + 6.0, 8), _mat(Color(0.6, 0.5, 0.3)))
	_lumiere(Vector3(8, SOL + 9.0, 8), Color(0.75, 0.85, 1.0), 12.0, 1.1)
	for p in [Vector2(5, 11), Vector2(11, 4), Vector2(12, 12)]:
		_boite(Vector3(0.8, 0.15, 0.25), Vector3(p.x, SOL + 0.08, p.y), os_)
	# 2. la galerie : le rail, des caisses, les sept plaques des astres, la porte de chêne
	for z in [7.4, 8.6]:
		_boite(Vector3(28.0, 0.1, 0.12), Vector3(41, SOL + 0.05, z), fer)
	for p in [Vector2(30, 5), Vector2(31.2, 5.2), Vector2(44, 11)]:
		_boite(Vector3(1.0, 0.9, 1.0), Vector3(p.x, SOL + 0.45, p.y), bois)
	var couleurs := [Color(0.9, 0.75, 0.3), Color(0.8, 0.25, 0.2), Color(0.3, 0.55, 0.8), Color(0.75, 0.8, 0.9),
		Color(0.85, 0.85, 0.8), Color(0.7, 0.7, 0.85), Color(0.4, 0.35, 0.5)]
	for i in 7:
		_boite(Vector3(0.9, 0.05, 0.9), Vector3(47.0 + i * 1.2, SOL + 0.03, 8), _mat(couleurs[i] * 0.7))
	_porte = _boite(Vector3(2.0, 4.0, 8.0), Vector3(57, SOL + 2.0, 8), _mat(Color(0.3, 0.2, 0.12)))
	_porte.visible = not _drapeau("g_porte")
	# 3. la salle inondée : l'eau monte avec la marée, des tonneaux contre la paroi
	_eau = _boite(Vector3(18.0, 0.1, 18.0), Vector3(77, SOL + 0.4, 9), _mat(Color(0.12, 0.3, 0.38), Color(0.02, 0.06, 0.08), 0.75))
	for p in [Vector2(84.5, 16.5), Vector2(83.3, 16.8)]:
		var t := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.45
		cyl.bottom_radius = 0.45
		cyl.height = 1.1
		t.mesh = cyl
		t.material_override = bois
		t.position = Vector3(p.x + ORIGINE.x, SOL + 0.55, p.y + ORIGINE.y)
		_racine.add_child(t)
	# 4. le campement : table, couchettes, poêle, le coffre de Gaspard
	_boite(Vector3(2.4, 0.9, 1.2), Vector3(41, SOL + 0.45, 24), bois)
	for x in [36.0, 38.0]:
		_boite(Vector3(1.0, 0.5, 2.2), Vector3(x, SOL + 0.25, 22.5), bois)
	_boite(Vector3(0.9, 1.2, 0.9), Vector3(46, SOL + 0.6, 22), fer)
	_boite(Vector3(1.2, 0.7, 0.8), Vector3(45, SOL + 0.35, 29), _mat(Color(0.45, 0.3, 0.15)))
	_lumiere(Vector3(41, SOL + 2.5, 26), Color(1.0, 0.6, 0.3), 6.0, 0.25)
	# 5. le gouffre : les toiles sur la paroi gauche
	for i in 6:
		var toile := _boite(Vector3(0.1, 2.0, 2.2), Vector3(28.6 + (i % 2) * 0.4, SOL + 1.2, 42.0 + i * 2.5), _mat(Color(0.9, 0.9, 0.92), Color.BLACK, 0.45))
		_toiles.append(toile)
		toile.visible = not _drapeau("g_toiles_brulees")
	# 6. la chambre de Léa
	if not _drapeau("g_lea_fait"):
		_boite(Vector3(1.6, 0.2, 0.5), Vector3(79, SOL + 0.1, 49), os_)
		_boite(Vector3(0.4, 0.4, 0.4), Vector3(80.1, SOL + 0.2, 49), os_)
		_boite(Vector3(0.3, 0.45, 0.3), Vector3(78, SOL + 0.22, 50.2), fer)
	# 7. la veine d'étoile : le métal bleu au plafond, les stalactites au-dessus du centre
	for x in [33.0, 49.0]:
		_boite(Vector3(9.0, 0.6, 0.4), Vector3(x, SOL + 4.5, 66.3), _mat(Color(0.3, 0.4, 0.7), Color(0.12, 0.2, 0.5)))
	_lumiere(Vector3(41, SOL + 5.0, 72), Color(0.45, 0.6, 1.0), 20.0, 1.3)
	for i in 6:
		var s := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.5
		cone.bottom_radius = 0.0
		cone.height = 2.4
		s.mesh = cone
		s.material_override = _mat(Color(0.32, 0.3, 0.3))
		var a := i * TAU / 6.0
		s.position = Vector3(41 + cos(a) * 2.0 + ORIGINE.x, SOL + 6.5, 80 + sin(a) * 2.0 + ORIGINE.y)
		_racine.add_child(s)
	# 8. la Bouche de mer : la mer, la barque noire, des traces de pas
	_boite(Vector3(14.0, 0.1, 4.0), Vector3(41, SOL + 0.1, 108), _mat(Color(0.1, 0.3, 0.35), Color(0.03, 0.1, 0.12), 0.85))
	_lumiere(Vector3(41, SOL + 3.0, 108), Color(0.5, 0.8, 0.85), 12.0, 0.9)
	_boite(Vector3(1.2, 0.5, 3.0), Vector3(45.5, SOL + 0.25, 102), _mat(Color(0.06, 0.06, 0.07)))
	for i in 5:
		_boite(Vector3(0.25, 0.02, 0.5), Vector3(43.0 - i * 0.9, SOL + 0.01, 103.0 - i * 0.7 + (i % 2) * 0.3), _mat(Color(0.3, 0.26, 0.2)))


# ---------------------------------------------------------------- chaque image

static func surveiller(m: Node3D, _delta: float) -> void:
	if not is_instance_valid(_racine) or m.joueur == null:
		return
	var dedans := contient(m.joueur.pos2d())
	if dedans:
		m._soleil.visible = false
		m._lune.light_energy = 0.0
		m._env.background_mode = Environment.BG_COLOR
		m._env.background_color = Color(0.01, 0.01, 0.015)
		m._env.ambient_light_color = Color(0.35, 0.38, 0.5)
		m._env.ambient_light_energy = 0.12
		m._env.fog_enabled = false
		_torche.visible = true
		_torche.omni_range = (16.0 if m.fiche.nombre("OBJ464") > 0 else 10.0) + (4.0 if m.combat != null else 0.0)
	elif _dedans:
		m._env.background_mode = Environment.BG_SKY
		m._env.fog_enabled = true
		_torche.visible = false
		_salle = ""
	_dedans = dedans
	if not dedans:
		return
	var basse: bool = Horloge.maree_basse()
	_eau.position.y = SOL + (0.15 if basse else 0.5)
	_eau.scale = Vector3(0.35, 1.0, 0.35) if basse else Vector3.ONE
	if m.combat != null or Illustrations.ouvert or m.fenetres.ouvert != "":
		return
	# la marée monte pendant que tu es au milieu de la salle inondée
	var p: Vector2 = m.joueur.pos2d()
	if not praticable(p):
		_placer(m, "inondee_sud" if local(p).y > 9.0 else "inondee")
		Illustrations.montrer("grotte_maree", ["grotte"], "L'eau monte d'un coup, glacée. La marée ! Tu regagnes le bord en nageant, trempé jusqu'aux os.")
		return
	var s := salle_de(p)
	if s != "" and s != _salle:
		_salle = s
		_entrer(m, s)


# ---------------------------------------------------------------- les salles

static func _entrer(m: Node3D, s: String) -> void:
	m.fiche.drapeaux["g_visitee"] = true
	var premiere: bool = not _drapeau("g_vu_" + s)
	m.fiche.drapeaux["g_vu_" + s] = true
	match s:
		"puits":
			if not _drapeau("g_rats"):
				_combat(m, [["rat", 4]], Vector2(8, 4), "rats",
					"Une odeur de pourriture. Des os de moutons, ceux de Basile. Et dans le noir, des yeux rouges, beaucoup d'yeux rouges.")
		"galerie":
			if premiere:
				Illustrations.montrer("grotte_galerie", ["grotte"], "Un vieux rail, des caisses pourries, des anneaux de fer scellés dans la roche. Au bout, une lourde porte de chêne. Devant elle, sept plaques au sol, chacune marquée d'un astre. Au-dessus, une phrase gravée : « Le marin part avec le Soleil et rentre avec la Dernière. »")
		"inondee":
			if Horloge.maree_basse() and not _drapeau("g_inondee"):
				_combat(m, [["crabe", 2], ["slime", 1]], Vector2(78, 9), "inondee",
					"La mer s'est retirée de la salle. Tu poses le pied sur un rocher… qui bouge. Ce ne sont pas des rochers. Et dans une flaque, quelque chose de gélatineux se soulève.")
			elif premiere:
				Illustrations.montrer("grotte_inondee", ["grotte"], "Une grande salle noyée par la mer. L'eau clapote contre la roche. À marée basse, on doit pouvoir passer à pied ; à marée haute, il faudrait nager sous l'eau jusqu'à l'autre bord.")
		"camp":
			if premiere:
				Illustrations.montrer("grotte_camp", ["grotte"], "Le repaire des Marbre, intact depuis trente-deux ans : une table, des couchettes, un poêle froid, des cartes moisies au mur. Sur la table, un journal relié de cuir. Sous une couchette, un coffre fermé par une serrure à quatre symboles d'astres.")
		"gouffre":
			if premiere:
				Illustrations.montrer("grotte_gouffre", ["grotte"], "Une faille de vingt mètres coupe la salle en deux. Le pont de corde des contrebandiers pend, effondré. La paroi de gauche est couverte de toiles épaisses, et quelque chose remue derrière.")
		"lea":
			if premiere and not _drapeau("g_lea_fait"):
				Illustrations.montrer("grotte_lea", ["grotte"], "Au fond d'une faille, un squelette de femme. Une jambe brisée, une lanterne vide, un carnet, et à son doigt une alliance. Elle est tombée ici et n'a jamais pu remonter. Léa, la femme de Pierrick.")
		"veine":
			if not _drapeau("g_bete_morte"):
				_bete(m)
		"bouche":
			if premiere:
				m.fiche.drapeaux["barque_noire"] = true
				m.fiche.drapeaux["connait_bouche"] = true
				Illustrations.montrer("grotte_bouche", ["grotte"], "Une grotte marine qui s'ouvre au ras de l'eau. Sur le sable, des traces de pas toutes fraîches, longues et étroites. Et derrière un rocher, une petite barque noire tirée sur les galets, sans aucune marque. Quelqu'un est arrivé par ici, et pas un pêcheur.")
	m.fiche.sauver()


static func _placer(m: Node3D, cle: String) -> void:
	var p: Vector2 = m.lieux["g_" + cle].pos
	m.joueur.position = Vector3(p.x, SOL, p.y)
	m.camera.position = m.joueur.position + Vector3(0, 10, 14)


static func _drapeau(k: String) -> bool:
	return _monde != null and _monde.fiche != null and bool(_monde.fiche.drapeaux.get(k, false))


static func _stat(m: Node3D, s: String) -> int:
	return int(m.fiche.stats_totales().get(s, 0))


static func _a_comp(m: Node3D, k: String) -> bool:
	return k in m.fiche.competences()


static func _blesser(m: Node3D, part: float) -> int:
	var perte := maxi(1, roundi(m.fiche.pv_max() * part))
	m.fiche.pv = maxi(1, m.fiche.pv - perte)
	return perte


static func _montrer(t: String) -> void:
	Illustrations.montrer("grotte", ["grotte"], t)


# ---------------------------------------------------------------- les combats

static func _combat(m: Node3D, groupes: Array, centre: Vector2, quoi: String, texte: String, preparer := Callable()) -> void:
	var ennemis := []
	for g in groupes:
		for i in int(g[1]):
			ennemis.append(_creer_bete(m, g[0], i + 1 if int(g[1]) > 1 else 0, monde_de(centre)))
	if preparer.is_valid():
		preparer.call(ennemis)
	if texte != "":
		Illustrations.montrer("grotte_" + quoi, ["grotte"], texte)
		await Illustrations.ferme
	m._lancer([Combattant.joueur(m.joueur, m.fiche)], ennemis, "mortel", {"betes": "grotte", "grotte": quoi})


static func _creer_bete(m: Node3D, type: String, i: int, centre: Vector2) -> Combattant:
	var b: Dictionary = BETES[type]
	var n := preload("res://scripts/bete.gd").new()
	n.planche = b.planche
	var p := centre + Vector2(randf_range(-4, 4), randf_range(-4, 4))
	if not praticable(p):
		p = centre
	n.position = Vector3(p.x, SOL, p.y)
	n.scale = Vector3.ONE * float(b.get("echelle", 1.0))
	m.add_child(n)
	m._loups.append(n)
	var c := Combattant.new()
	c.id = "%s%d" % [type, i]
	c.nom = b.nom + (" %d" % i if i > 0 else "")
	c.est_bete = true
	c.noeud = n
	c.niveau = b.niveau
	c.stats = b.stats.duplicate()
	c.arme = b.arme
	c.competences = b.get("competences", []).duplicate()
	c.def_phys = b.get("armure", 0)
	c.ventre_mou = b.get("ventre_mou", false)
	c.elements = b.get("elements", {})
	c._calculer()
	return c


## Appelé par monde._fin_combat : ce que le combat change dans la grotte. Renvoie le texte à montrer.
static func fin_combat(m: Node3D, resultat: String, contexte: Dictionary, ennemis: Array, texte: String) -> String:
	var quoi: String = contexte.grotte
	if resultat == "defaite":
		return "Le noir. Puis la voix de Pierrick, quelque part au-dessus de toi, et une corde qui te hisse. Tu te réveilles chez Agnès. « Personne ne descend là-dedans, grogne Pierrick. Personne. »"
	if resultat != "victoire":
		return "Tu recules dans le noir, le cœur battant. Elles ne te suivent pas plus loin."
	var butin := {}
	match quoi:
		"rats":
			m.fiche.drapeaux["g_rats"] = true
			texte = "Le dernier rat file dans une fissure. Dans un coin, une corde neuve et une lanterne éteinte : quelqu'un est descendu ici récemment."
		"inondee":
			m.fiche.drapeaux["g_inondee"] = true
			butin = {"BRV020": 2, "BRV065": 1}
			texte = "Les crabes gisent sur le dos, et le slime n'est plus qu'une flaque tiède."
		"gouffre", "nid":
			m.fiche.drapeaux["g_araignees"] = true
			m.fiche.drapeaux["g_gouffre_passe"] = true
			var n := ennemis.size()
			butin = {"BRV064": 3 if quoi == "nid" else 2, "BRV066": maxi(1, n / 2)}
			texte = "Plus rien ne bouge dans les toiles. Le chemin vers l'autre côté du gouffre est libre." if quoi == "gouffre" else "La reine du nid s'est recroquevillée. Tu remontes de l'autre côté de la faille, couvert de soie."
		"bete":
			m.fiche.drapeaux["g_bete_morte"] = true
			butin = {"BRV070": 2}
			texte = "La Bête aveugle s'effondre sous la veine, et la caverne retombe dans le silence. Au plafond, le fer d'étoile luit doucement. Tu en détaches deux éclats."
	for id in butin:
		m.fiche.ajouter(id, butin[id])
	if butin:
		texte += " Tu prends : %s." % ", ".join(butin.keys().map(func(id): return "%s ×%d" % [Objets.get_(id).nom.to_lower(), butin[id]]))
	m.fiche.sauver()
	return texte


# ---------------------------------------------------------------- la Bête aveugle

static func _bete(m: Node3D) -> void:
	var options := []
	var moyens := _moyens_stalactites(m)
	var t := "Une immense caverne. Au plafond, une veine de métal bleuté luit doucement : le fer d'étoile. Et dessous, roulée sur elle-même, une chose énorme et pâle dort. Elle n'a pas d'yeux. Elle a tourné la tête vers toi au premier bruit de pas.\n\nDes stalactites pendent au-dessus du centre de la caverne."
	if moyens != "":
		options.append(["Faire du bruit pour l'attirer sous les stalactites, puis les faire tomber (%s)" % moyens, func(): _combat_bete(m, "stalactites")])
	else:
		t += " Pour les faire tomber, il te faudrait un arc, un sort lancé à distance ou de la force (For 12)."
	options.append(["Contourner la Bête en silence et prendre du fer d'étoile (Agi 14 ou Discrétion)", func(): _contourner(m)])
	options.append(["L'attaquer de front", func(): _combat_bete(m, "front")])
	options.append(["Reculer sans bruit", func(): _reculer(m)])
	m.fenetres.choix("La Bête aveugle", t, options)


static func _moyens_stalactites(m: Node3D) -> String:
	for e in m.fiche.equipement:
		var o := Objets.get_(m.fiche.equipement[e])
		if o.get("type", "") == "arme" and int(o.get("portee", "1")) > 1:
			return "à l'arc"
	for k in ["flamme", "bourrasque", "boule_feu", "eclat_glace", "vague", "lumiere_pale"]:
		if _a_comp(m, k):
			return "d'un sort"
	if _stat(m, "For") >= 12:
		return "d'un coup dans la roche"
	return ""


static func _combat_bete(m: Node3D, comment: String) -> void:
	var preparer := func(ennemis: Array) -> void:
		var b: Combattant = ennemis[0]
		if comment == "stalactites":
			b.pv = b.pv_max / 2
			b.etats["renverse"] = 2
		elif comment == "reveil":
			b.ct = 200.0
	var texte: String = {"stalactites": "Tu frappes la roche. La Bête se déroule et fonce vers le bruit, droit sous les stalactites. Elles tombent dans un fracas de tonnerre. Quand la poussière retombe, elle est blessée, renversée, et furieuse.",
		"front": "Tu avances. La Bête aveugle se dresse, la gueule ouverte, et charge vers le bruit de ton cœur.",
		"reveil": "Un caillou roule sous ton pied. La Bête se retourne d'un coup, et elle sait exactement où tu es."}[comment]
	_combat(m, [["bete", 1]], Vector2(41, 80), "bete", texte, preparer)


static func _contourner(m: Node3D) -> void:
	var chance := 35 + (_stat(m, "Agi") - 10) * 10 + (40 if _a_comp(m, "discretion") else 0)
	if _stat(m, "Agi") >= 14 or randi_range(1, 100) <= chance:
		if not _drapeau("g_fer_vole"):
			m.fiche.drapeaux["g_fer_vole"] = true
			m.fiche.ajouter("BRV070")
			_montrer("Pas après pas, sans un souffle, tu longes la paroi. La Bête tourne la tête, renifle, puis se rendort. Tu détaches un éclat de fer d'étoile et tu repars comme tu es venu. Tu prends : fer d'étoile ×1.")
		else:
			_montrer("Tu repasses sans bruit. La Bête dort toujours. Il reste du fer d'étoile au plafond, mais pas à portée sans la réveiller.")
		_salle = "veine"
	else:
		_combat_bete(m, "reveil")


static func _reculer(m: Node3D) -> void:
	_placer(m, "gouffre_sud")
	_salle = "gouffre"


# ---------------------------------------------------------------- les actions (E)

## Faux = l'action n'apparaît pas dans le menu.
static func dispo(m: Node3D, donne: String) -> bool:
	_monde = m
	var f = m.fiche
	match donne:
		"grotte_bouche":
			return _drapeau("connait_bouche") or f.nombre("BRV062") > 0
		"grotte_rumeur":
			return not _drapeau("connait_bouche")
		"grotte_comptine":
			return not _drapeau("comptine")
		"grotte_fouiller_puits":
			return _drapeau("g_rats") and not _drapeau("g_puits_fouille")
		"grotte_porte":
			return not _drapeau("g_porte")
		"grotte_tonneaux":
			return not _drapeau("g_tonneaux") and (Horloge.maree_basse() or m.lieu_proche(m.joueur.pos2d()) == "g_inondee_sud")
		"grotte_nager":
			return not Horloge.maree_basse()
		"grotte_journal":
			return not _drapeau("g_journal")
		"grotte_coffre":
			return not _drapeau("g_coffre")
		"grotte_lea":
			return not _drapeau("g_lea_fait")
		"grotte_fer":
			return _drapeau("g_bete_morte") and not _drapeau("g_fer_detache")
		"grotte_pierrick":
			return f.nombre("BRV067") + f.nombre("BRV068") + f.nombre("BRV069") > 0 or (_drapeau("g_lea_fait") and not _drapeau("pierrick_sait"))
		"grotte_bram":
			return f.nombre("BRV070") > 0
		"grotte_ysolde":
			return f.nombre("BRV061") + f.nombre("BRV063") > 0
		"grotte_aldric":
			return f.nombre("BRV063") > 0
		"grotte_silas":
			return f.nombre("BRV060") > 0 or (_drapeau("g_visitee") and not _drapeau("silas_grotte"))
		"grotte_isaure":
			return f.nombre("BRV064") > 0
		"grotte_souvenir":
			return _drapeau("g_vu_camp") and not _drapeau("g_coffre") and not _drapeau("g_souvenir_ysolde")
	return true


static func action(m: Node3D, donne: String, _l: Dictionary, pnj: Node) -> void:
	_monde = m
	var f = m.fiche
	match donne:
		"grotte_descendre":
			_descendre(m)
		"grotte_remonter":
			var p: Vector2 = m.lieux.puits.pos + Vector2(0, 3)
			m.joueur.position = Vector3(p.x, m.hauteur(p.x, p.y), p.y)
			_montrer("Tu remontes à la force des bras, et le jour t'éblouit. Le jardin des Marbre, les herbes folles, le bruit de la mer.")
		"grotte_bouche":
			if not Horloge.maree_basse():
				_montrer("La mer bat le pied de la falaise et couvre l'entrée. Basse mer à %s." % _prochaine_basse_mer())
				return
			_placer(m, "bouche")
			_salle = "bouche"
			_montrer("Tu passes par les rochers, de flaque en flaque, et tu te glisses sous la falaise. Une grotte marine s'ouvre au ras de l'eau.")
		"grotte_sortir_mer":
			if not Horloge.maree_basse():
				_montrer("La mer couvre la sortie. Il faudra attendre la basse mer, à %s, ou repartir par le puits." % _prochaine_basse_mer())
				return
			var p: Vector2 = m.lieux.bouche.pos + Vector2(0, -3)
			m.joueur.position = Vector3(p.x, m.hauteur(p.x, p.y), p.y)
			_montrer("Tu sors au ras de l'eau, dans le vent salé. La crique est à deux cents pas.")
		"grotte_rumeur":
			f.drapeaux["connait_bouche"] = true
			var nom: String = pnj.donnees.nom.get_slice(" ", 0) if pnj else "On"
			_montrer("%s baisse la voix : « Sous la falaise, il y a une bouche dans la roche. On ne la voit qu'à marée basse. Les Marbre s'en servaient, dans le temps. Si tu tiens à la vie, tu n'y vas pas. »" % nom)
		"grotte_comptine":
			f.drapeaux["comptine"] = true
			var qui: String = pnj.id if pnj else ""
			var avant: String = {"BRU006": "Joss pose sa chope, ferme les yeux et chante, la voix cassée :", "BRU005": "Tim récite d'une traite, fier comme tout :",
				"BRU004": "Ysolde sourit : « Mes élèves la savent par cœur. » Elle récite :"}.get(qui, "On te récite :")
			_montrer("%s %s" % [avant, COMPTINE])
		"grotte_fouiller_puits":
			f.drapeaux["g_puits_fouille"] = true
			f.ajouter("OBJ462")
			f.ajouter("OBJ464")
			_montrer("Contre la paroi : une corde neuve, roulée, et une lanterne éteinte, encore grasse d'huile. Tu prends : corde de chanvre, lanterne sourde. Avec la lanterne, tu y verras plus loin.")
		"grotte_porte":
			_porte_menu(m)
		"grotte_nager":
			_nager(m)
		"grotte_tonneaux":
			f.drapeaux["g_tonneaux"] = true
			f.ajouter("BRV060", 3)
			_montrer("Des tonneaux cerclés de fer, marqués d'un M. Tu en perces un : de l'eau-de-vie, quarante ans d'âge, encore pleine. Tu prends : eau-de-vie des Marbre ×3. Silas paierait pour savoir d'où elle vient.")
		"grotte_journal":
			f.drapeaux["g_journal"] = true
			f.ajouter("BRV063")
			_montrer("Le journal de Gaspard Marbre. Les dernières pages racontent la descente des soldats, et le nom de celui qui les a dénoncés : le père d'Aldric Montval, qui a ensuite racheté leurs biens pour rien. Plus haut, une page tendre : « La nuit où ma petite Ysolde est née, sous la Pâle, la Lune, la Rouge et la Mer. » Tu prends le journal.")
		"grotte_coffre":
			_coffre_menu(m)
		"grotte_gouffre":
			_gouffre(m)
		"grotte_lea":
			_lea(m)
		"grotte_veine":
			if _drapeau("g_bete_morte"):
				_montrer("La caverne est silencieuse. La veine d'étoile luit au plafond.")
			else:
				_bete(m)
		"grotte_fer":
			f.drapeaux["g_fer_detache"] = true
			f.ajouter("BRV070", 2)
			_montrer("À coups de pierre, tu détaches encore deux éclats de fer d'étoile. Ils sont froids, et ils luisent dans ta main. Tu prends : fer d'étoile ×2.")
		"grotte_barque":
			f.drapeaux["barque_noire"] = true
			_montrer("Une barque étroite, peinte en noir, sans nom ni marque. Le bois est d'une essence que tu ne connais pas. Au fond, des algues mâchées et une écaille noire, longue comme un doigt.")
		"grotte_pierrick":
			_pierrick(m, pnj)
		"grotte_bram":
			_bram(m, pnj)
		"grotte_ysolde":
			_ysolde(m, pnj)
		"grotte_aldric":
			_aldric(m, pnj)
		"grotte_silas":
			_silas(m, pnj)
		"grotte_souvenir":
			f.drapeaux["g_souvenir_ysolde"] = true
			f.drapeaux["ysolde_marbre"] = true
			_montrer("Ysolde se tait longtemps. « Mon père disait que je suis née une nuit de tempête, sous la Pâle, la Lune, la Rouge et la Mer. Il le répétait comme une prière. » Elle te regarde. « Pourquoi tu me demandes ça ? Tu as trouvé quelque chose, là-bas. » Elle vient de te dire, sans le dire, qu'elle est une Marbre.")
		"grotte_isaure":
			var n: int = f.nombre("BRV064")
			f.retirer("BRV064", n)
			f.bourse += n * 240
			_relation(m, "BRU019", 10)
			_montrer("Isaure tend la soie à la lumière, émerveillée : « De la soie des cavernes… Je peux en faire une cape qui arrête une lame. » Elle te paie %s." % Objets.texte_prix(n * 240))
	f.sauver()


static func _prochaine_basse_mer() -> String:
	var h: float = Horloge.heure()
	for b in Horloge.basses_mers() + Horloge.basses_mers(Horloge.jour() + 1).map(func(x): return x + 24.0):
		if b - 2.0 > h:
			return Horloge.texte_heure(fposmod(b, 24.0))
	return "demain"


static func _relation(m: Node3D, id: String, n: int) -> void:
	m.relations[id] = clampi(m.relations.get(id, 0) + n, -100, 100)
	m.sauver_etat()


static func _descendre(m: Node3D) -> void:
	var f = m.fiche
	var avant := ""
	for t in m.temoins(40.0):
		if t.id == "BRU020":
			if m.relations.get("BRU020", 0) < 20:
				_relation(m, "BRU020", -5)
				_montrer("Une main se pose sur ton épaule. Pierrick. « Pas là. Personne ne descend là. » Il ne lâche pas ton épaule tant que tu ne t'es pas éloigné.")
				return
			avant = "Pierrick te regarde soulever les planches. Il ne t'arrête pas. « Fais attention en bas. Il y a… fais attention, c'est tout. »\n\n"
			break
	if not _drapeau("g_corde"):
		if f.nombre("OBJ462") == 0:
			_montrer("Douze mètres de vide sous les planches. Sans corde, c'est un aller simple. (Joss et Silas vendent des cordes.)")
			return
		f.retirer("OBJ462")
		f.drapeaux["g_corde"] = true
	var texte := avant + "Tu attaches la corde à la margelle et tu descends dans le froid."
	if _stat(m, "For") < 8 and _stat(m, "Agi") < 8:
		texte += " À mi-hauteur, tes mains glissent. Tu tombes les derniers mètres (-%d PV)." % _blesser(m, 0.2)
	_placer(m, "puits")
	_salle = ""
	_montrer(texte)


# ---------------------------------------------------------------- la porte des astres

static func _porte_menu(m: Node3D) -> void:
	_sequence = []
	var t := "Sept plaques au sol, sept astres. Au-dessus de la porte : « Le marin part avec le Soleil et rentre avec la Dernière. »"
	if _drapeau("comptine"):
		t += "\n\nTu te souviens de la comptine des marins : " + COMPTINE
	var options := [["Marcher sur les plaques, dans un ordre", func(): _plaques(m)]]
	if _stat(m, "For") >= 14:
		options.append(["Enfoncer la porte (For %d)" % _stat(m, "For"), func(): _ouvrir_porte(m, "Tu prends ton élan. Au troisième coup d'épaule, les gonds rouillés cèdent.")])
	if _stat(m, "Agi") >= 12 and _a_comp(m, "crochetage"):
		options.append(["Crocheter la serrure (Agi %d, Crochetage)" % _stat(m, "Agi"), func(): _ouvrir_porte(m, "La serrure est vieille et grasse. Elle cède sous tes crochets avec un claquement sec.")])
	options.append(["Laisser la porte", func(): pass])
	m.fenetres.choix("La porte des astres", t, options)


static func _plaques(m: Node3D) -> void:
	var options := []
	for a in ASTRES:
		if a not in _sequence:
			options.append([_majuscule(NOMS_ASTRES[a]), _plaque.bind(m, a)])
	options.append(["Reculer", func(): pass])
	var deja := ", ".join(_sequence.map(func(a): return NOMS_ASTRES[a]))
	m.fenetres.choix("La porte des astres", "Plaque %d sur 7.%s" % [_sequence.size() + 1, (" Déjà : " + deja + ".") if deja != "" else ""], options)


static func _plaque(m: Node3D, a: String) -> void:
	_sequence.append(a)
	if _sequence.size() < 7:
		_plaques(m)
		return
	if _sequence == ORDRE_PORTE:
		_ouvrir_porte(m, "À la septième plaque, un déclic sourd. La porte de chêne s'ouvre d'elle-même, en grinçant. Le marin est rentré au port.")
	else:
		var perte := _blesser(m, 0.1)
		_placer(m, "puits")
		_salle = "puits"
		_montrer("Un craquement sous tes pieds. Une trappe s'ouvre, tu glisses dans une fosse d'eau croupie, et un boyau te recrache… au fond du puits (-%d PV)." % perte)


static func _majuscule(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1)


static func _ouvrir_porte(m: Node3D, texte: String) -> void:
	m.fiche.drapeaux["g_porte"] = true
	_porte.visible = false
	m.fiche.sauver()
	_montrer(texte)


# ---------------------------------------------------------------- la salle inondée

static func _nager(m: Node3D) -> void:
	var vers_sud: bool = m.lieu_proche(m.joueur.pos2d()) == "g_inondee"
	var texte := "Tu prends ta respiration et tu plonges dans l'eau noire."
	if _a_comp(m, "respiration_eau"):
		texte = "Tu respires l'eau comme de l'air et tu traverses la salle sans te presser."
	elif _stat(m, "End") >= 10:
		texte += " Trente secondes d'apnée, les poumons en feu, et tu refais surface de l'autre côté."
	else:
		texte += " À mi-chemin, l'air te manque. Tu avales de l'eau salée, tu te cognes à la roche, et tu arrives de l'autre côté à moitié noyé (-%d PV)." % _blesser(m, 0.25)
	_placer(m, "inondee_sud" if vers_sud else "inondee")
	_montrer(texte)


# ---------------------------------------------------------------- le coffre de Gaspard

static func _coffre_menu(m: Node3D) -> void:
	_sequence = []
	var t := "Un coffre cerclé de fer. La serrure porte quatre roues, et sur chacune les sept astres."
	if _drapeau("g_journal"):
		t += "\n\nDans le journal : « La nuit où ma petite Ysolde est née, sous la Pâle, la Lune, la Rouge et la Mer. »"
	if _drapeau("g_souvenir_ysolde"):
		t += "\n\nYsolde t'a confié la nuit de sa naissance : sous la Pâle, la Lune, la Rouge et la Mer."
	var options := [["Tourner les roues", func(): _roues(m)]]
	if _stat(m, "For") >= 16:
		options.append(["Forcer le coffre (For %d)" % _stat(m, "For"), func(): _ouvrir_coffre(m, true)])
	if _stat(m, "Agi") >= 12 and _a_comp(m, "crochetage"):
		options.append(["Crocheter la serrure (Agi %d, Crochetage)" % _stat(m, "Agi"), func(): _ouvrir_coffre(m, false)])
	options.append(["Laisser le coffre", func(): pass])
	m.fenetres.choix("Le coffre de Gaspard", t, options)


static func _roues(m: Node3D) -> void:
	var options := []
	for a in ASTRES:
		options.append([_majuscule(NOMS_ASTRES[a]), _roue.bind(m, a)])
	options.append(["Laisser", func(): pass])
	var deja := ", ".join(_sequence.map(func(a): return NOMS_ASTRES[a]))
	m.fenetres.choix("Le coffre de Gaspard", "Roue %d sur 4.%s" % [_sequence.size() + 1, (" Déjà : " + deja + ".") if deja != "" else ""], options)


static func _roue(m: Node3D, a: String) -> void:
	_sequence.append(a)
	if _sequence.size() < 4:
		_roues(m)
	elif _sequence == ORDRE_COFFRE:
		_ouvrir_coffre(m, false)
	else:
		_montrer("Les quatre roues sont en place. Rien ne bouge. La serrure attend autre chose.")


static func _ouvrir_coffre(m: Node3D, force: bool) -> void:
	var f = m.fiche
	f.drapeaux["g_coffre"] = true
	f.bourse += 480
	f.ajouter("BRV061")
	f.ajouter("BRV062")
	var t := "Le couvercle se soulève. " if not force else "Le couvercle cède dans un craquement, et une fiole se brise à l'intérieur : une odeur de mer et de fleurs, perdue pour toujours. "
	t += "Dedans : deux pièces d'or, les bijoux de famille des Marbre, et une carte marine roulée. Sur la carte, loin à l'ouest, une grande île dessinée à la main, et une note : « Vue une seule fois, par temps clair, après la tempête. Elle n'est sur aucune carte. On y voyait des lumières. » Tu prends : 2 or, bijoux de famille des Marbre, carte marine de Gaspard."
	f.sauver()
	_montrer(t)


# ---------------------------------------------------------------- le gouffre

static func _gouffre(m: Node3D) -> void:
	var au_sud: bool = m.lieu_proche(m.joueur.pos2d()) == "g_gouffre_sud"
	if _drapeau("g_gouffre_passe"):
		_placer(m, "gouffre" if au_sud else "gouffre_sud")
		_montrer("Tu repasses la faille par le chemin que tu connais, sans regarder en bas.")
		return
	var options := []
	var feu: bool = _a_comp(m, "flamme") or _a_comp(m, "boule_feu") or m.fiche.nombre("OBJ464") > 0
	var t := "Vingt mètres de vide. Trois façons de passer : longer la corniche de gauche, mais elle est noyée sous les toiles ; lancer une corde sur une stalactite et se balancer ; ou descendre au fond et remonter de l'autre côté, là où quelque chose remue."
	if feu:
		options.append(["Brûler les toiles et longer la corniche (Agi 10)", func(): _bruler(m, au_sud)])
	if m.fiche.nombre("OBJ462") > 0:
		options.append(["Lancer ta corde et te balancer (For 10 et Per 10)", func(): _balancer(m, au_sud)])
	options.append(["Descendre au fond de la faille", func(): _descendre_faille(m, au_sud)])
	options.append(["Rester de ce côté", func(): pass])
	if not feu:
		t += " Pour brûler les toiles, il faudrait une flamme (le sort, ou une lanterne)."
	m.fenetres.choix("Le Gouffre", t, options)


static func _bruler(m: Node3D, au_sud: bool) -> void:
	m.fiche.drapeaux["g_toiles_brulees"] = true
	for toile in _toiles:
		toile.visible = false
	var t := "Les toiles s'embrasent d'un coup, et la corniche apparaît. Mais le feu réveille le nid : des araignées grosses comme des chiens jaillissent de partout, toutes en même temps."
	if _stat(m, "Agi") < 10:
		t += " En reculant, tu glisses au bord de la faille et tu te rattrapes de justesse (-%d PV)." % _blesser(m, 0.1)
	_combat(m, [["araignee", 4]], local(m.joueur.pos2d()), "gouffre", t, Grotte.roussir)


## Les araignées sortent des toiles en feu : déjà roussies, elles brûlent encore.
static func roussir(ennemis: Array) -> void:
	for c in ennemis:
		c.pv = roundi(c.pv_max * 0.7)
		c.etats["brulure"] = 2


static func _balancer(m: Node3D, au_sud: bool) -> void:
	if _stat(m, "For") >= 10 and _stat(m, "Per") >= 10:
		m.fiche.retirer("OBJ462")
		m.fiche.drapeaux["g_gouffre_passe"] = true
		_placer(m, "gouffre" if au_sud else "gouffre_sud")
		_montrer("Ta corde s'enroule autour de la stalactite au premier essai. Tu t'élances, le vide sous les pieds, et tu atterris de l'autre côté. La corde reste en place pour le retour.")
	else:
		var perte := _blesser(m, 0.15)
		_nid(m, au_sud, "La corde glisse. Tu tombes dans le noir, rebondis sur des toiles épaisses (-%d PV)… en plein dans le nid. Les araignées descendent vers toi, et derrière elles, une forme bien plus grosse." % perte)


static func _descendre_faille(m: Node3D, au_sud: bool) -> void:
	_nid(m, au_sud, "Tu descends en t'accrochant aux toiles. Au fond, des cocons, des os, et le nid. Les araignées descendent des parois, et derrière elles s'avance la reine, deux fois plus grosse que les autres. Il faudra remonter de l'autre côté.")


## Le combat du nid se joue au pied de la paroi d'en face : c'est là que tu remontes.
static func _nid(m: Node3D, au_sud: bool, texte: String) -> void:
	var cote := "gouffre" if au_sud else "gouffre_sud"
	_placer(m, cote)
	_salle = "gouffre"
	_combat(m, [["araignee", 2], ["reine", 1]], local(m.lieux["g_" + cote].pos), "nid", texte)


# ---------------------------------------------------------------- la chambre de Léa

static func _lea(m: Node3D) -> void:
	var options := [
		["Envelopper ses restes dans ta cape, avec le carnet et l'alliance", func(): _prendre_lea(m, ["BRV067", "BRV068", "BRV069"])],
		["Prendre seulement le carnet", func(): _prendre_lea(m, ["BRV068"])],
		["Prendre seulement l'alliance", func(): _prendre_lea(m, ["BRV069"])],
		["La laisser en paix", func(): pass],
	]
	m.fenetres.choix("Léa", "Le carnet est ouvert à la dernière page. « Pierrick. Je l'ai trouvé, le fer d'étoile, plus bas. J'aurais dû t'écouter. Je n'arrive plus à remonter. Ne me cherche pas trop longtemps. »", options)


static func _prendre_lea(m: Node3D, ids: Array) -> void:
	var f = m.fiche
	f.drapeaux["g_lea_fait"] = true
	for id in ids:
		f.ajouter(id)
	if "BRV069" in ids:
		f.drapeaux["g_alliance_prise"] = true
	f.sauver()
	_montrer("Tu prends : %s." % ", ".join(ids.map(func(id): return Objets.get_(id).nom.to_lower())))


# ---------------------------------------------------------------- les suites au village

static func _pierrick(m: Node3D, pnj: Node) -> void:
	var f = m.fiche
	var options := []
	if f.nombre("BRV067") > 0:
		options.append(["Lui rendre les restes de Léa", func(): _rendre_lea(m, "restes")])
	if f.nombre("BRV068") > 0:
		options.append(["Lui donner le carnet de Léa", func(): _rendre_lea(m, "carnet")])
	if f.nombre("BRV069") > 0:
		options.append(["Lui donner l'alliance de Léa", func(): _rendre_lea(m, "alliance")])
	if not _drapeau("pierrick_sait"):
		options.append(["Lui dire seulement que tu l'as trouvée", func(): _rendre_lea(m, "dire")])
	options.append(["Ne rien dire", func(): pass])
	m.fenetres.choix(pnj.donnees.nom if pnj else "Pierrick", "Pierrick lève les yeux de ses flèches. Il voit ton visage, et il pose son couteau.", options)


static func _rendre_lea(m: Node3D, quoi: String) -> void:
	var f = m.fiche
	f.drapeaux["pierrick_sait"] = true
	var t := ""
	match quoi:
		"restes":
			f.retirer("BRV067")
			var plus := ""
			for id in ["BRV068", "BRV069"]:
				if f.nombre(id) > 0:
					f.retirer(id)
					if id == "BRV069":
						f.drapeaux["g_alliance_rendue"] = true
			f.drapeaux["pierrick_deuil"] = true
			_relation(m, "BRU020", 50)
			t = "Pierrick prend la cape dans ses bras sans un mot. Il reste longtemps comme ça. Puis : « Dix ans que je garde cette falaise. » Le lendemain, il l'enterre sous le vieux chêne. Il ne garde plus la falaise. Et il te regarde maintenant comme quelqu'un sur qui on peut compter."
			if _drapeau("g_alliance_prise") and not _drapeau("g_alliance_rendue"):
				_relation(m, "BRU020", -60)
				f.drapeaux["pierrick_alliance"] = true
				t += "\n\nPuis il regarde sa main, longtemps. « Elle ne l'enlevait jamais. Où est son alliance ? » Tu ne réponds pas. Il ne te le pardonnera pas."
		"carnet":
			f.retirer("BRV068")
			_relation(m, "BRU020", 25)
			t = "Pierrick lit la dernière page, debout, sans bouger. Ses mains tremblent. « Elle l'a trouvé. Cette tête de mule l'a trouvé. » Il garde le carnet contre lui."
		"alliance":
			f.retirer("BRV069")
			f.drapeaux["g_alliance_rendue"] = true
			_relation(m, "BRU020", 20)
			t = "Pierrick referme la main sur l'anneau. « P. pour toujours. » Il le passe à une cordelette, autour de son cou."
		"dire":
			_relation(m, "BRU020", 8)
			t = "« Au fond de la grotte. » Pierrick hoche la tête, lentement. « Alors je sais. C'est déjà ça. »"
	f.sauver()
	_montrer(t)


static func _bram(m: Node3D, pnj: Node) -> void:
	var options := [
		["Le lui donner, pour l'épée de sa vie", func(): _fer(m, "donner")],
		["Le lui vendre (5 or l'éclat)", func(): _fer(m, "vendre")],
		["Le garder", func(): pass],
	]
	m.fenetres.choix(pnj.donnees.nom if pnj else "Bram", "Bram prend l'éclat entre deux doigts, le tourne vers le feu de la forge, et sa voix se casse : « Du fer d'étoile. Du vrai. Trente ans que j'en rêve. »", options)


static func _fer(m: Node3D, quoi: String) -> void:
	var f = m.fiche
	f.retirer("BRV070")
	if quoi == "donner":
		f.drapeaux["bram_fer_etoile"] = true
		_relation(m, "BRU002", 40)
		_montrer("Bram ne dit rien pendant un long moment. Puis il te serre la main à te broyer les os. « Je vais forger l'épée de ma vie. Et la première chose qu'elle coupera, ce sera le ruban de ta victoire. Tu n'as plus jamais à payer une réparation ici. »")
	else:
		f.bourse += 1200
		_relation(m, "BRU002", 10)
		_montrer("Bram compte cinq pièces d'or sur l'enclume, une à une. « C'est tout ce que j'ai de côté. Il le vaut. » Tu prends : 5 or.")
	f.sauver()


static func _ysolde(m: Node3D, pnj: Node) -> void:
	var f = m.fiche
	var options := []
	if f.nombre("BRV061") > 0:
		options.append(["Lui rendre les bijoux des Marbre", func(): _marbre(m, "bijoux")])
	if f.nombre("BRV063") > 0:
		options.append(["Lui montrer le journal de Gaspard", func(): _marbre(m, "journal")])
	options.append(["Ne rien dire", func(): pass])
	m.fenetres.choix(pnj.donnees.nom if pnj else "Ysolde", "Ysolde corrige des ardoises. Elle lève les yeux vers toi, et vers ce que tu tiens.", options)


static func _marbre(m: Node3D, quoi: String) -> void:
	var f = m.fiche
	f.drapeaux["ysolde_marbre"] = true
	if quoi == "bijoux":
		f.retirer("BRV061")
		_relation(m, "BRU004", 35)
		_montrer("Ysolde reconnaît la broche avant même de la toucher. « C'était à ma mère. » Elle ferme la porte de l'école. « Je m'appelle Ysolde Marbre. Personne ici ne doit le savoir. Maintenant, toi, tu le sais. »")
	else:
		f.retirer("BRV063")
		f.drapeaux["secret_montval"] = "ysolde"
		_relation(m, "BRU004", 20)
		_montrer("Ysolde lit, pâle comme la craie. « Montval. Le père d'Aldric. » Elle referme le journal et le garde. « Je savais qu'on nous avait vendus. Je ne savais pas qui. » Ce qu'elle en fera, c'est son affaire, maintenant.")
	f.sauver()


static func _aldric(m: Node3D, pnj: Node) -> void:
	var options := [
		["Le lui vendre, pour qu'il le brûle (3 or)", func(): _journal_aldric(m, "vendre")],
		["Le menacer de tout révéler au conseil", func(): _journal_aldric(m, "menacer")],
		["Ne rien montrer", func(): pass],
	]
	m.fenetres.choix(pnj.donnees.nom if pnj else "Aldric", "Aldric Montval te reçoit entre deux rendez-vous. Quand il voit le nom sur la couverture du journal, il cesse de sourire.", options)


static func _journal_aldric(m: Node3D, quoi: String) -> void:
	var f = m.fiche
	f.retirer("BRV063")
	if quoi == "vendre":
		f.bourse += 720
		f.drapeaux["secret_montval"] = "brule"
		_relation(m, "BRU007", 25)
		_montrer("Aldric pose trois pièces d'or sur le bureau et jette le journal dans la cheminée. « Mon père a fait ce qu'il fallait pour cette ville. Nous n'en parlerons plus. » Tu prends : 3 or. Le secret des Marbre part en fumée.")
	else:
		f.bourse += 480
		f.drapeaux["secret_montval"] = "chantage"
		_relation(m, "BRU007", -50)
		_montrer("Aldric devient blanc, puis très calme. Il te tend deux pièces d'or. « Pour ton silence. » Tu gardes le journal en tête, lui garde ton visage en mémoire. Un homme comme lui ne paie jamais deux fois. Tu prends : 2 or.")
		f.ajouter("BRV063")
	f.sauver()


static func _silas(m: Node3D, pnj: Node) -> void:
	var f = m.fiche
	var options := []
	if f.nombre("BRV060") > 0:
		options.append(["Lui vendre l'eau-de-vie des Marbre (3 argent le tonnelet)", func(): _vendre_silas(m, "eau")])
	if _drapeau("g_visitee") and not _drapeau("silas_grotte"):
		options.append(["Lui vendre le secret de la grotte (3 or)", func(): _vendre_silas(m, "secret")])
	options.append(["Rien", func(): pass])
	m.fenetres.choix(pnj.donnees.nom if pnj else "Silas", "Silas te sert un verre, sans te le proposer. « On dirait que tu as quelque chose à me vendre. »", options)


static func _vendre_silas(m: Node3D, quoi: String) -> void:
	var f = m.fiche
	if quoi == "eau":
		var n: int = f.nombre("BRV060")
		f.retirer("BRV060", n)
		f.bourse += n * 36
		_relation(m, "BRU003", 5)
		_montrer("Silas goûte, et ses yeux s'allument. « Ça, c'est du Marbre. Quarante ans d'âge. D'où ça sort ? » Tu ne réponds pas. Il paie quand même : %s." % Objets.texte_prix(n * 36))
	else:
		f.bourse += 720
		f.drapeaux["silas_grotte"] = true
		_relation(m, "BRU003", 25)
		_montrer("Tu lui dessines le puits, la galerie, la Bouche de mer. Silas t'écoute sans un mot, puis pose trois pièces d'or sur la table. « Plus besoin de la crique. Plus de gardes, plus de témoins. Tu viens de me rendre invisible. » Tu prends : 3 or.")
	f.sauver()
