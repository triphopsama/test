# Le village de Brumeval, construit à partir du plan (data/*.csv).
# 1 unité = 1 mètre. x vers l'est, z vers le sud, y vers le haut.
extends Node3D

const TAILLE := Vector2(1720, 1180)
const PAS := 8.0
const ENFANT_MAX := 17

var lieux := {}            # cle -> {id, nom, type, pos, h, ligne}
var graphe := {}           # cle -> [{vers, d, maree}]
var cote := PackedVector2Array()
var bois := PackedVector2Array()
var landes := PackedVector2Array()
var ruisseau := PackedVector2Array()
var batiments: Array[Rect2] = []
var pnj_donnees := {}      # id -> ligne de pnj.csv
var pnjs: Array = []
var relations := {}        # id -> affection du PNJ envers le joueur
var desirs := {}           # id -> désir du PNJ, 0 à 100 (intime.gd)
var joueur: Node3D
var camera: Camera3D
var hud: CanvasLayer
var actions: RefCounted
var focus: Node3D                # ce que suit la caméra
var combat: Node3D = null
var morts := {}                  # id -> true
var _dernier_jour_loups := 0
var _loups: Array = []
var _t_hostiles := 0.0
var combat_auto := false        # test : l'IA joue aussi ton camp
var _proposer_classe := false   # après un vrai combat, sans classe : on t'en propose
var _dernier_jour_silas := 0
var fiche: Fiche                 # le joueur : caractéristiques, niveau, sac, bourse
var fenetres: CanvasLayer        # sac (I), personnage (C), marchands
var _derniere_regen := -1.0
var _t_rencontres := 0.0
var _prochaine_rencontre := {}   # type de bête -> heure du monde (secondes) avant laquelle elle ne revient pas
## Ce que laissent les bêtes (bestiaire.md) : [objet, chance].
const BUTIN := {
	"loup": [["OBJ407", 1.0], ["BRV002", 0.5]],
	"rat": [],
	"crabe": [["BRV020", 1.0]],
	"sanglier": [["BRV021", 1.0], ["BRV021", 1.0], ["BRV022", 1.0]],
}

var _lp := PackedVector2Array()
var _lh := PackedFloat32Array()
var _soleil: DirectionalLight3D
var _lune: DirectionalLight3D
var _env: Environment
var _ciel: ProceduralSkyMaterial
var _lumieres: Array[OmniLight3D] = []
var _bruit := FastNoiseLite.new()
var _zoom := 1.6


func _ready() -> void:
	randomize()
	_bruit.frequency = 0.02
	_charger()
	_charger_etat()
	fiche = Fiche.charger()
	_construire_environnement()
	_construire_terrain()
	_construire_chemins()
	_construire_batiments()
	_construire_arbres()
	_construire_decor()
	actions = preload("res://scripts/actions.gd").new(self)
	_creer_joueur()
	_creer_pnjs()
	Compagnons.restaurer(self)
	hud = preload("res://scripts/hud.gd").new()
	hud.monde = self
	add_child(hud)
	fenetres = preload("res://scripts/fenetres.gd").new()
	fenetres.monde = self
	add_child(fenetres)
	var args := Array(OS.get_cmdline_user_args())
	var outil: bool = "--autotest" in args or "--equilibre" in args or args.any(func(a): return a.begins_with("--capture="))
	if not outil and ("--nouveau" in args or not fiche.drapeaux.has("cree")):
		_creation()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capture="):
			var cap := preload("res://scripts/capture.gd").new()
			cap.monde = self
			add_child(cap)
	if "--equilibre" in OS.get_cmdline_user_args():
		var eq := preload("res://scripts/equilibre.gd").new()
		eq.monde = self
		add_child(eq)
	if "--autotest" in OS.get_cmdline_user_args():
		var t := preload("res://scripts/test_auto.gd").new()
		t.monde = self
		add_child(t)


# ---------------------------------------------------------------- données

func _charger() -> void:
	for l in Donnees.lire_csv("res://data/lieux.csv"):
		var pos := Vector2(float(l.x), float(l.y))
		lieux[l.cle] = {"id": l.id, "nom": l.nom, "type": l.type, "pos": pos, "h": float(l.hauteur), "ligne": l}
		graphe[l.cle] = []
		_lp.append(pos)
		_lh.append(float(l.hauteur))
	var par_id := {}
	for cle in lieux:
		par_id[lieux[cle].id] = cle
	for c in Donnees.lire_csv("res://data/chemins.csv"):
		var a: String = par_id[c.de]
		var b: String = par_id[c.a]
		var maree: bool = c.condition.contains("marée basse")
		graphe[a].append({"vers": b, "d": float(c.distance_m), "maree": maree})
		graphe[b].append({"vers": a, "d": float(c.distance_m), "maree": maree})
	var zones := {"cote": cote, "bois": bois, "landes": landes, "ruisseau": ruisseau}
	for z in Donnees.lire_csv("res://data/zones.csv"):
		zones[z.zone].append(Vector2(float(z.x), float(z.y)))
	cote = zones.cote
	bois = zones.bois
	landes = zones.landes
	ruisseau = zones.ruisseau
	for p in Donnees.lire_csv("res://data/pnj.csv"):
		pnj_donnees[p.id] = p
		relations[p.id] = 0


# ---------------------------------------------------------------- terrain

## Hauteur du sol en un point (mètres). La mer est à -4.
func hauteur(x: float, z: float) -> float:
	var p := Vector2(clampf(x, 0.0, TAILLE.x), clampf(z, 0.0, TAILLE.y))
	if not sur_terre(p):
		return -4.0
	var num := 0.0
	var den := 0.0
	for i in _lp.size():
		var w := 1.0 / (p.distance_squared_to(_lp[i]) + 900.0)
		num += w * _lh[i]
		den += w
	var h := num / den + _bruit.get_noise_2d(p.x, p.y) * 1.2
	var dc := distance_cote(p)
	if h < 10.0:
		h *= clampf(dc / 45.0, 0.0, 1.0)   # plages en pente douce
	return maxf(h, 0.05)


func sur_terre(p: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(p, cote)


func distance_cote(p: Vector2) -> float:
	var m := INF
	for i in cote.size() - 3:   # les deux derniers points ferment la carte
		var q := Geometry2D.get_closest_point_to_segment(p, cote[i], cote[i + 1])
		m = minf(m, p.distance_to(q))
	return m


## Vrai si on peut marcher en ce point (sur terre, hors des murs).
func praticable(p: Vector2) -> bool:
	if p.x < 0.0 or p.y < 0.0 or p.x > TAILLE.x or p.y > TAILLE.y:
		return false
	if not sur_terre(p):
		return false
	for r in batiments:
		if r.has_point(p):
			return false
	return true


func _couleur_sol(p: Vector2, h: float) -> Color:
	var n := _bruit.get_noise_2d(p.x * 3.0, p.y * 3.0) * 0.06
	if not sur_terre(p):
		return Color(0.45, 0.42, 0.32)
	if h < 1.6 and distance_cote(p) < 50.0:
		return Color(0.86, 0.79, 0.6) + Color(n, n, n)
	if Geometry2D.is_point_in_polygon(p, bois):
		return Color(0.2, 0.33, 0.17) + Color(n, n, n)
	if Geometry2D.is_point_in_polygon(p, landes):
		return Color(0.5, 0.43, 0.38) + Color(n, n * 0.5, n)
	return Color(0.4, 0.56, 0.26) + Color(n, n, n * 0.5)


func _construire_terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0 := -240.0
	var z0 := -240.0
	var nx := int((TAILLE.x + 480.0) / PAS) + 1
	var nz := int((TAILLE.y + 480.0) / PAS) + 1
	for j in nz:
		for i in nx:
			var x := x0 + i * PAS
			var z := z0 + j * PAS
			var h := hauteur(x, z)
			st.set_color(_couleur_sol(Vector2(clampf(x, 0, TAILLE.x), clampf(z, 0, TAILLE.y)), h))
			st.add_vertex(Vector3(x, h, z))
	for j in nz - 1:
		for i in nx - 1:
			var a := j * nx + i
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + nx)
			st.add_index(a + 1)
			st.add_index(a + nx + 1)
			st.add_index(a + nx)
	st.generate_normals()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	st.set_material(mat)
	var sol := MeshInstance3D.new()
	sol.mesh = st.commit()
	sol.name = "Sol"
	add_child(sol)

	var mer := MeshInstance3D.new()
	var plan := PlaneMesh.new()
	plan.size = Vector2(6000, 6000)
	mer.mesh = plan
	mer.position = Vector3(TAILLE.x / 2.0, 0.0, TAILLE.y / 2.0)
	var eau := StandardMaterial3D.new()
	eau.albedo_color = Color(0.17, 0.36, 0.52, 0.85)
	eau.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	eau.metallic = 0.0
	eau.roughness = 0.35
	mer.material_override = eau
	mer.name = "Mer"
	add_child(mer)


func _ruban(st: SurfaceTool, a: Vector2, b: Vector2, largeur: float, couleur: Color, dessus: float) -> void:
	var dir := (b - a).normalized()
	var cote_v := Vector2(-dir.y, dir.x) * largeur * 0.5
	var n := maxi(1, int(a.distance_to(b) / 4.0))
	for k in n:
		var p1 := a.lerp(b, float(k) / n)
		var p2 := a.lerp(b, float(k + 1) / n)
		var q := [p1 - cote_v, p1 + cote_v, p2 + cote_v, p2 - cote_v]
		var v := []
		for pt in q:
			v.append(Vector3(pt.x, hauteur(pt.x, pt.y) + dessus, pt.y))
		st.set_color(couleur)
		for idx in [0, 2, 1, 0, 3, 2]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v[idx])


func _construire_chemins() -> void:
	var sortes := {"route": Color(0.66, 0.56, 0.4), "rochers": Color(0.5, 0.5, 0.5), "eau": Color(0.22, 0.42, 0.6)}
	var outils := {}
	for s in sortes:
		outils[s] = SurfaceTool.new()
		outils[s].begin(Mesh.PRIMITIVE_TRIANGLES)
	var vus := {}
	for a in graphe:
		for arete in graphe[a]:
			var cle := [a, arete.vers]
			cle.sort()
			if vus.has(str(cle)):
				continue
			vus[str(cle)] = true
			var st: SurfaceTool = outils["rochers" if arete.maree else "route"]
			_ruban(st, lieux[a].pos, lieux[arete.vers].pos, 2.4, Color.WHITE, 0.12)
	for i in ruisseau.size() - 1:
		_ruban(outils["eau"], ruisseau[i], ruisseau[i + 1], 2.6, Color.WHITE, 0.1)
	for s in sortes:
		var mat := _mat(sortes[s])
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		outils[s].set_material(mat)
		var m := MeshInstance3D.new()
		m.mesh = outils[s].commit()
		m.name = "Chemins_" + s
		add_child(m)


# ---------------------------------------------------------------- bâtiments

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


func _boite(taille: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = taille
	mi.mesh = b
	mi.position = pos
	mi.material_override = mat
	add_child(mi)
	return mi


func _construire_batiments() -> void:
	var tailles := {"maison": Vector2(7, 6), "métier": Vector2(9, 7), "ferme": Vector2(13, 8), "sacré": Vector2(8, 16)}
	var murs := _mat(Color(0.86, 0.82, 0.72))
	var pierre := _mat(Color(0.6, 0.58, 0.55))
	var toit := _mat(Color(0.45, 0.2, 0.15))
	var ardoise := _mat(Color(0.25, 0.27, 0.32))
	var bois_m := _mat(Color(0.4, 0.28, 0.18))
	for cle in lieux:
		var l: Dictionary = lieux[cle]
		var p: Vector2 = l.pos
		var h := hauteur(p.x, p.y)
		if tailles.has(l.type):
			var t: Vector2 = tailles[l.type]
			if cle == "mairie":
				t = Vector2(12, 9)
			var centre := Vector2(p.x, p.y - t.y / 2.0 - 2.0)
			var hc := hauteur(centre.x, centre.y)
			var haut := 7.0 if l.type == "sacré" else 4.0
			var m := pierre if l.type in ["sacré", "ferme"] or cle == "falaise" else murs
			_boite(Vector3(t.x, haut + 3.0, t.y), Vector3(centre.x, hc - 3.0 + (haut + 3.0) / 2.0, centre.y), m)
			var prisme := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(t.x + 1.0, 2.6, t.y + 1.0)
			prisme.mesh = pm
			prisme.position = Vector3(centre.x, hc + haut + 1.3, centre.y)
			prisme.material_override = ardoise if l.type == "sacré" else toit
			add_child(prisme)
			if l.type == "sacré":
				_boite(Vector3(4, 16, 4), Vector3(centre.x, hc + 6.0, centre.y + t.y / 2.0 - 2.0), pierre)
			if cle == "moulin":
				var roue := _boite(Vector3(1.0, 6.0, 6.0), Vector3(centre.x + t.x / 2.0 + 0.6, hc + 3.0, centre.y), bois_m)
				roue.name = "RoueMoulin"
			batiments.append(Rect2(centre - t / 2.0 + Vector2(0.4, 0.4), t - Vector2(0.8, 0.8)))
			# lumière aux fenêtres la nuit
			var lum := OmniLight3D.new()
			lum.light_color = Color(1.0, 0.72, 0.4)
			lum.omni_range = 9.0
			lum.light_energy = 1.4
			lum.position = Vector3(p.x, h + 2.5, p.y - 1.5)
			lum.visible = false
			add_child(lum)
			_lumieres.append(lum)
		elif cle in ["place", "puits"]:
			var puits := MeshInstance3D.new()
			var cy := CylinderMesh.new()
			cy.top_radius = 1.0
			cy.bottom_radius = 1.0
			cy.height = 1.0
			puits.mesh = cy
			puits.position = Vector3(p.x + (6.0 if cle == "place" else 0.0), h + 0.5, p.y)
			puits.material_override = pierre
			add_child(puits)
			batiments.append(Rect2(Vector2(puits.position.x - 1.0, puits.position.z - 1.0), Vector2(2, 2)))
		elif cle == "port":
			_boite(Vector3(30, 2.0, 5), Vector3(p.x - 20.0, 0.4, p.y), pierre)
			for k in 4:
				_boite(Vector3(1.6, 0.6, 4.5), Vector3(p.x - 12.0 - k * 6.0, 0.25, p.y + 5.0), bois_m)
		var etiquette := Label3D.new()
		etiquette.text = l.nom
		etiquette.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		etiquette.font_size = 48
		etiquette.pixel_size = 0.012
		etiquette.outline_size = 10
		etiquette.position = Vector3(p.x, h + 8.0, p.y - 4.0)
		etiquette.visibility_range_end = 70.0
		add_child(etiquette)


func _construire_arbres() -> void:
	var tronc := CylinderMesh.new()
	tronc.top_radius = 0.25
	tronc.bottom_radius = 0.4
	tronc.height = 3.0
	tronc.material = _mat(Color(0.33, 0.24, 0.16))
	var feuilles := SphereMesh.new()
	feuilles.radius = 2.6
	feuilles.height = 4.2
	feuilles.radial_segments = 8
	feuilles.rings = 4
	feuilles.material = _mat(Color(0.16, 0.3, 0.15))
	var positions := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var essais := 0
	while positions.size() < 2200 and essais < 20000:
		essais += 1
		var p := Vector2(rng.randf_range(960, 1720), rng.randf_range(0, 620))
		if not Geometry2D.is_point_in_polygon(p, bois):
			continue
		var proche := false
		for cle in lieux:
			if p.distance_to(lieux[cle].pos) < 12.0:
				proche = true
				break
		if proche or _pres_chemin(p, 4.0):
			continue
		positions.append(p)
	for partie in [[tronc, 1.5], [feuilles, 4.4]]:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = partie[0]
		mm.instance_count = positions.size()
		for i in positions.size():
			var p: Vector2 = positions[i]
			var e := 0.8 + 0.5 * fposmod(p.x * 13.1 + p.y * 7.7, 1.0)
			var t := Transform3D(Basis().scaled(Vector3(e, e, e)), Vector3(p.x, hauteur(p.x, p.y) + partie[1] * e, p.y))
			mm.set_instance_transform(i, t)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		add_child(mmi)


func _pres_chemin(p: Vector2, d: float) -> bool:
	for a in graphe:
		for arete in graphe[a]:
			var q := Geometry2D.get_closest_point_to_segment(p, lieux[a].pos, lieux[arete.vers].pos)
			if p.distance_to(q) < d:
				return true
	return false


# ---------------------------------------------------------------- lumière et ciel

func _construire_environnement() -> void:
	_ciel = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = _ciel
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.55, 0.6, 0.7)
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.glow_enabled = true
	_env.glow_intensity = 0.4
	_env.glow_bloom = 0.08
	_env.ssao_enabled = true
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.62, 0.66, 0.7)
	_env.fog_density = 0.0015
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)

	_soleil = DirectionalLight3D.new()
	_soleil.shadow_enabled = true
	_soleil.directional_shadow_max_distance = 120.0
	add_child(_soleil)
	_lune = DirectionalLight3D.new()
	_lune.light_color = Color(0.55, 0.65, 0.9)
	_lune.rotation = Vector3(deg_to_rad(-50), deg_to_rad(30), 0)
	add_child(_lune)

	camera = Camera3D.new()
	camera.fov = 32.0
	camera.far = 900.0
	var attr := CameraAttributesPractical.new()
	attr.dof_blur_far_enabled = true
	attr.dof_blur_far_distance = 40.0
	attr.dof_blur_far_transition = 30.0
	attr.dof_blur_near_enabled = true
	attr.dof_blur_near_distance = 8.0
	attr.dof_blur_near_transition = 4.0
	attr.dof_blur_amount = 0.12
	camera.attributes = attr
	add_child(camera)


func _process(delta: float) -> void:
	var h: float = Horloge.heure()
	var elev := sin((h - 6.0) / 12.0 * PI)          # 1 à midi, < 0 la nuit
	var az := lerpf(100.0, -100.0, clampf((h - 6.0) / 12.0, 0.0, 1.0))
	_soleil.rotation = Vector3(-deg_to_rad(maxf(elev, 0.05) * 70.0), deg_to_rad(az), 0)
	_soleil.light_energy = clampf(elev * 1.2, 0.0, 0.8)
	_soleil.light_color = Color(1.0, 0.75, 0.5).lerp(Color(1.0, 0.97, 0.9), clampf(elev * 2.0, 0.0, 1.0))
	_soleil.visible = elev > 0.0
	_lune.light_energy = clampf(-elev * 0.6 + 0.08, 0.0, 0.25)
	var jour_f := clampf(elev * 2.0 + 0.3, 0.0, 1.0)
	_ciel.sky_top_color = Color(0.03, 0.04, 0.1).lerp(Color(0.3, 0.5, 0.8), jour_f)
	_ciel.sky_horizon_color = Color(0.08, 0.08, 0.15).lerp(Color(0.75, 0.75, 0.75), jour_f)
	_ciel.ground_horizon_color = _ciel.sky_horizon_color
	_env.ambient_light_energy = lerpf(0.12, 0.45, jour_f)
	var brume := h >= 5.0 and h < 10.0
	_env.fog_density = lerpf(_env.fog_density, 0.012 if brume else 0.0015, clampf(delta, 0.0, 1.0))
	var nuit := h < 6.5 or h > 19.5
	for l in _lumieres:
		l.visible = nuit
	_suivre_camera(delta)
	_surveiller_loups()
	_surveiller_rencontres(delta)
	_surveiller_desirs(delta)
	_surveiller_equipe(delta)
	_surveiller_defis(delta)
	_surveiller_hostiles(delta)
	_regenerer()


## L'écran de création, puis le réveil dans le bois de Ronceval.
func _creation() -> void:
	var ecran := preload("res://scripts/creation.gd").new()
	add_child(ecran)
	get_tree().paused = true
	var f: Fiche = await ecran.fini
	get_tree().paused = false
	fiche = f
	nouvelle_vie()
	var texte := "Tu ouvres les yeux. Des fougères, une odeur de mousse et de sel, un ciel blanc entre les branches. Le bois de Ronceval, mais ce nom-là, tu ne le connais pas encore."
	match fiche.tenue:
		"nu":
			texte += " Et tu es nu%s comme au premier jour. Le vent du large te le fait savoir." % fiche.accord("", "e", "")
		"haillons":
			texte += " Tu portes des loques qui ne sont pas à toi."
		"ailleurs":
			texte += " Tu portes encore tes vêtements de là-bas."
	texte += " À ton doigt, un anneau que tu n'as jamais mis."
	if fiche.objet_ailleurs != "":
		texte += " Dans ta poche : %s." % Objets.get_(fiche.objet_ailleurs).nom.to_lower()
	texte += "\n\nAu loin, une cloche. Un village, peut-être. (I : sac · C : personnage)"
	Illustrations.montrer("reveil", ["reveil"], texte)


## Une nouvelle vie : le monde oublie l'ancien personnage, et accueille le nouveau selon qui il est.
func nouvelle_vie() -> void:
	relations.clear()
	morts.clear()
	for n in pnjs:
		n.mort = false
		n.hostile = false
	var p: Vector2 = lieux.reveil.pos
	joueur.position = Vector3(p.x, hauteur(p.x, p.y), p.y)
	var r := {}
	match fiche.peuple:
		"nain":
			r["BRU011"] = 20                       # Rosalie te traite en cousin
		"elfe":
			r["BRU020"] = 10                       # Pierrick, demi-elfe
		"demi_sang":
			r["BRU020"] = 15                       # Pierrick se reconnaît en toi
	if fiche.peuple == "homme_bete" and fiche.lignee == "renard":
		r["BRU016"] = 15                           # Nina, renarde elle aussi
	for n in pnjs:
		if fiche.a("beaute") and int(n.donnees.age) >= 18:
			r[n.id] = r.get(n.id, 0) + 5
	if fiche.a("ami_enfants"):
		for id in ["BRU005", "BRU016"]:
			r[id] = r.get(id, 0) + 15
	if fiche.a("louche"):
		r["BRU014"] = r.get("BRU014", 0) - 15      # Corentin te surveille
	if fiche.a("ennemi"):
		var adultes := pnjs.filter(func(n): return int(n.donnees.age) >= 18)
		var e: Node = adultes.pick_random()
		r[e.id] = r.get(e.id, 0) - 45
		fiche.drapeaux["ennemi"] = e.id
	for id in r:
		relations[id] = r[id]
	sauver_etat()
	fiche.sauver()


## Hors combat, on reprend 10 % de ses PV par heure du monde.
func _regenerer() -> void:
	var t: float = Horloge.maintenant()
	if _derniere_regen < 0.0 or t < _derniere_regen:
		_derniere_regen = t
	if combat != null or t - _derniere_regen < 3600.0:
		return
	var heures := floori((t - _derniere_regen) / 3600.0)
	_derniere_regen += heures * 3600.0
	Intime.passer_temps(self, heures)
	Defis.expirer(self)
	if fiche.pv < fiche.pv_max() or fiche.mana_actuelle() < fiche.mana_max():
		fiche.pv = mini(fiche.pv_max(), fiche.pv + maxi(1, fiche.pv_max() / 10) * heures)
		# la mana revient plus vite que le sang : un quart par heure
		fiche.mana = mini(fiche.mana_max(), fiche.mana_actuelle() + maxi(1, fiche.mana_max() / 4) * heures)
		fiche.sauver()


func _suivre_camera(delta: float) -> void:
	if joueur == null:
		return
	var suivi: Node3D = focus if focus != null and is_instance_valid(focus) else joueur
	var cible := suivi.position + Vector3(0, 10.0, 14.0) * _zoom
	camera.position = camera.position.lerp(cible, clampf(delta * 5.0, 0.0, 1.0))
	camera.look_at(suivi.position + Vector3(0, 1.0, 0))
	var attr := camera.attributes as CameraAttributesPractical
	attr.dof_blur_far_distance = 22.0 * _zoom + 12.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom - 0.1, 0.4, 3.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom + 0.1, 0.4, 3.0)


# ---------------------------------------------------------------- personnages

func _creer_joueur() -> void:
	joueur = preload("res://scripts/joueur.gd").new()
	joueur.monde = self
	var p: Vector2 = lieux.reveil.pos
	joueur.position = Vector3(p.x, hauteur(p.x, p.y), p.y)
	add_child(joueur)
	camera.position = joueur.position + Vector3(0, 10, 14)


func _creer_pnjs() -> void:
	var emplois := {}
	for e in Donnees.lire_csv("res://data/emplois.csv"):
		if not emplois.has(e.pnj):
			emplois[e.pnj] = []
		emplois[e.pnj].append([float(e.heure), e.lieu, e.activite])
	for id in emplois:
		if not pnj_donnees.has(id):
			continue
		var n := preload("res://scripts/pnj.gd").new()
		n.monde = self
		n.id = id
		n.donnees = pnj_donnees[id]
		n.emploi = emplois[id]
		n.mort = morts.has(id)
		add_child(n)
		pnjs.append(n)


## Le chemin le plus court entre deux lieux, en points 2D.
func chemin(depart: String, arrivee: String) -> PackedVector2Array:
	var maree: bool = Horloge.maree_basse()
	var dist := {depart: 0.0}
	var avant := {}
	var a_voir := [depart]
	while not a_voir.is_empty():
		var meilleur: String = a_voir[0]
		for c in a_voir:
			if dist[c] < dist[meilleur]:
				meilleur = c
		a_voir.erase(meilleur)
		if meilleur == arrivee:
			break
		for arete in graphe[meilleur]:
			if arete.maree and not maree:
				continue
			var d: float = dist[meilleur] + arete.d
			if d < dist.get(arete.vers, INF):
				dist[arete.vers] = d
				avant[arete.vers] = meilleur
				if not a_voir.has(arete.vers):
					a_voir.append(arete.vers)
	var pts := PackedVector2Array()
	var c := arrivee
	if not avant.has(c) and c != depart:
		pts.append(lieux[arrivee].pos)
		return pts
	while c != depart:
		pts.insert(0, lieux[c].pos)
		c = avant[c]
	return pts


## Le lieu le plus proche d'un point, s'il est à moins de d mètres.
func lieu_proche(p: Vector2, d: float = 30.0) -> String:
	var meilleur := ""
	var dm := d
	for cle in lieux:
		var x: float = p.distance_to(lieux[cle].pos)
		if x < dm:
			dm = x
			meilleur = cle
	return meilleur


## Vrai si un enfant est à moins de d mètres du point.
func enfant_proche(p: Vector2, d: float = 20.0) -> bool:
	for n in pnjs:
		if n.visible and int(n.donnees.age) <= ENFANT_MAX and n.pos2d().distance_to(p) < d:
			return true
	return false


# ---------------------------------------------------------------- décor

## Dalles des places, buissons, rochers, remises et clôtures autour du village.
func _construire_decor() -> void:
	var dalle := _mat(Color(0.5, 0.48, 0.45))
	for cle in ["place", "port"]:
		var p: Vector2 = lieux[cle].pos
		var d := MeshInstance3D.new()
		var cy := CylinderMesh.new()
		cy.top_radius = 16.0 if cle == "place" else 10.0
		cy.bottom_radius = cy.top_radius
		cy.height = 0.6
		cy.radial_segments = 24
		d.mesh = cy
		d.position = Vector3(p.x, hauteur(p.x, p.y) + 0.05, p.y)
		d.material_override = dalle
		add_child(d)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var buisson := SphereMesh.new()
	buisson.radius = 1.0
	buisson.height = 1.3
	buisson.radial_segments = 8
	buisson.rings = 4
	buisson.material = _mat(Color(0.22, 0.38, 0.18))
	var rocher := SphereMesh.new()
	rocher.radius = 0.9
	rocher.height = 1.0
	rocher.radial_segments = 6
	rocher.rings = 3
	rocher.material = _mat(Color(0.5, 0.5, 0.48))
	var arbre := SphereMesh.new()
	arbre.radius = 2.8
	arbre.height = 5.0
	arbre.radial_segments = 8
	arbre.rings = 4
	arbre.material = _mat(Color(0.2, 0.36, 0.16))
	for modele in [[buisson, 900, 0.5], [rocher, 350, 0.3], [arbre, 260, 4.5]]:
		var pts := []
		while pts.size() < modele[1]:
			var p := Vector2(rng.randf_range(80, 1100), rng.randf_range(40, 1150))
			if not sur_terre(p) or Geometry2D.is_point_in_polygon(p, bois):
				continue
			if modele[0] == rocher and distance_cote(p) > 60.0 and not Geometry2D.is_point_in_polygon(p, landes):
				continue
			if _pres_chemin(p, 3.5) or not praticable(p) or lieu_proche(p, 14.0) != "":
				continue
			pts.append(p)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = modele[0]
		mm.instance_count = pts.size()
		for i in pts.size():
			var p: Vector2 = pts[i]
			var e := rng.randf_range(0.7, 1.4)
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(e, e, e)), Vector3(p.x, hauteur(p.x, p.y) + modele[2] * e, p.y)))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		add_child(mmi)
	# remises et granges le long des chemins du village (sans habitants)
	var bois_m := _mat(Color(0.45, 0.32, 0.2))
	var toit := _mat(Color(0.35, 0.22, 0.15))
	var poses := 0
	var essais := 0
	while poses < 16 and essais < 4000:
		essais += 1
		var p := Vector2(rng.randf_range(250, 900), rng.randf_range(450, 900))
		if not praticable(p) or _pres_chemin(p, 6.0) or not _pres_chemin(p, 14.0) or lieu_proche(p, 25.0) == "" or lieu_proche(p, 16.0) != "":
			continue
		var t := Vector2(rng.randf_range(4, 6), rng.randf_range(3, 5))
		var h := hauteur(p.x, p.y)
		_boite(Vector3(t.x, 5.0, t.y), Vector3(p.x, h, p.y), bois_m)
		var pr := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(t.x + 0.6, 1.6, t.y + 0.6)
		pr.mesh = pm
		pr.position = Vector3(p.x, h + 3.3, p.y)
		pr.material_override = toit
		add_child(pr)
		batiments.append(Rect2(p - t / 2.0, t))
		poses += 1


# ---------------------------------------------------------------- état sauvegardé

const ETAT := "user://etat.cfg"


func _charger_etat() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(ETAT) != OK:
		return
	for id in cfg.get_value("monde", "relations", {}):
		relations[id] = cfg.get_value("monde", "relations")[id]
	morts = cfg.get_value("monde", "morts", {})
	desirs = cfg.get_value("monde", "desirs", {})
	_dernier_jour_loups = cfg.get_value("monde", "loups", 0)


func sauver_etat() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("monde", "relations", relations)
	cfg.set_value("monde", "morts", morts)
	cfg.set_value("monde", "desirs", desirs)
	cfg.set_value("monde", "loups", _dernier_jour_loups)
	cfg.save(ETAT)


## Ceux qui voient la scène : PNJ visibles à moins de d mètres du joueur.
func temoins(d: float = 30.0) -> Array:
	return pnjs.filter(func(n): return n.visible and not n.mort and n.pos2d().distance_to(joueur.pos2d()) < d)


# ---------------------------------------------------------------- combats

## Ce qu'un PNJ peut t'apprendre : les compétences qu'il sait utiliser (sa classe, à son
## niveau), que tu n'as pas encore. Les enfants n'enseignent pas.
## Les compétences de l'intime, et qui les enseigne (s'il t'apprécie : affection 30).
const MAITRES_INTIMES := {"BRU003": ["seduction", "jeu_pouvoir", "discretion"], "BRU013": ["danse_lascive", "seduction"],
	"BRU017": ["lecture_envies"], "BRU015": ["massage"], "BRU022": ["discretion"]}


func lecons_de(n: Node) -> Array:
	if n == null or int(n.donnees.get("age", "0")) < 18:
		return []
	var intimes: Array = []
	if actions.intime_possible(n) and relations.get(n.id, 0) >= 30:
		intimes = MAITRES_INTIMES.get(n.id, []).filter(func(k): return not k in fiche.apprises)
	var c := Combattant.depuis_pnj(n.donnees, n)
	var connues: Array = fiche.competences(true)
	var r := []
	for k in Classes.competences_jusqua(Classes.par_nom(str(n.donnees.get("classe", ""))), c.niveau):
		if k in c.competences and not k in connues and not k in r and not k in Fiche.DE_BASE:
			r.append(k)
	return r + intimes


var _t_desirs := 0.0


## Toutes les 3 secondes : un PNJ au désir à son comble, près de toi, se soulage (seul, ou avec
## quelqu'un selon leurs relations) ; tu le surprends. Une fois par jour et par PNJ.
func _surveiller_desirs(delta: float) -> void:
	_t_desirs += delta
	if _t_desirs < 3.0:
		return
	_t_desirs = 0.0
	if combat != null or Illustrations.ouvert or fenetres.ouvert != "" or get_tree().paused or not fiche.options.get("adulte", true):
		return
	for n in pnjs:
		if not n.visible or n.mort or Intime.profil(n.id).is_empty() or Intime.desir(self, n.id) < 100:
			continue
		if n.pos2d().distance_to(joueur.pos2d()) > 10.0 or enfant_proche(n.pos2d()) or enfant_proche(joueur.pos2d()):
			continue
		var cle := "surpris_%s_%d" % [n.id, Horloge.jour()]
		if fiche.drapeaux.has(cle):
			continue
		fiche.drapeaux[cle] = true
		surprendre(n)
		return


func surprendre(n: Node) -> void:
	var autre: Node = Intime.partenaire_pour(self, n)
	var groupe := [n] if autre == null else [n, autre]
	var ids: Array = groupe.map(func(x): return x.id)
	ids.sort()
	for x in groupe:
		desirs[x.id] = 0
	var noms: Array = groupe.map(func(x): return x.donnees.nom.get_slice(" ", 0))
	var texte := ""
	if autre == null:
		texte = "Tu surprends %s, seul·e, qui ne t'a pas vu·e. Le désir a été le plus fort." % noms[0]
	else:
		texte = "Tu surprends %s et %s, l'un contre l'autre, qui ne t'ont pas vu·e." % noms
	for x in groupe:
		if fiche.partenaires.has(x.id):
			texte += " %s… ton %s. Ça serre le cœur." % [x.donnees.nom.get_slice(" ", 0), "couple" if fiche.partenaires[x.id] == "couple" else "amant"]
	var lieu := lieu_proche(n.pos2d(), 40.0)
	Illustrations.montrer("se_soulager" if autre == null else "surpris_ensemble", ["+".join(ids)] + ids + [lieu], texte)
	await Illustrations.ferme
	fenetres.choix("Que fais-tu ?", texte, [
		["Te montrer", _se_montrer.bind(groupe), "Ils te verront. Selon leur pudeur : un sourire et une invitation, ou la honte et la colère. Puis tu leur parles."],
		["Partir sans bruit", _partir_sans_bruit.bind(groupe), "Ils ne sauront rien… sauf si on te voit filer (moins avec Discrétion)."]])


func _se_montrer(groupe: Array) -> void:
	var lignes := []
	for x in groupe:
		var p := Intime.profil(x.id)
		var nom: String = x.donnees.nom.get_slice(" ", 0)
		var aff: int = relations.get(x.id, 0)
		if "risque" in p.aime or (p.pudeur < 40 and aff >= 20):
			relations[x.id] = clampi(aff + 3, -100, 100)
			desirs[x.id] = 60
			lignes.append("%s ne se cache même pas. Un sourire : « Tu restes ? »" % nom)
		elif p.pudeur >= 60:
			relations[x.id] = clampi(aff - 8, -100, 100)
			lignes.append("%s se rhabille, rouge de honte et de colère (−8)." % nom)
		else:
			relations[x.id] = clampi(aff - 3, -100, 100)
			lignes.append("%s, gêné·e, cherche ses mots (−3)." % nom)
	sauver_etat()
	Illustrations.montrer("se_montrer", groupe.map(func(x): return x.id), " ".join(lignes))
	await Illustrations.ferme
	# puis tu leur parles : le menu des actions avec le premier
	var n: Node = groupe[0]
	joueur.position = n.position + Vector3(1.5, 0, 0)
	hud._cible_pnj = n
	hud._ouvrir_menu()


func _partir_sans_bruit(groupe: Array) -> void:
	var vu := randf() < (0.1 if "discretion" in fiche.competences() else 0.2)
	if vu:
		for x in groupe:
			relations[x.id] = clampi(relations.get(x.id, 0) - 5, -100, 100)
		sauver_etat()
		Illustrations.montrer("partir_sans_bruit", groupe.map(func(x): return x.id), "Une latte qui craque. Un regard qui se tourne vers toi au moment où tu files. Ils savent (−5).")
	else:
		Illustrations.montrer("partir_sans_bruit", groupe.map(func(x): return x.id), "Tu recules sans un bruit. Personne ne saura.")


var _t_equipe := 0.0


## Toutes les 4 secondes : un enfant près d'un compagnon dévêtu, on le couvre ; sinon les passants réagissent.
func _surveiller_equipe(delta: float) -> void:
	_t_equipe += delta
	if _t_equipe < 4.0 or fiche.equipiers.is_empty() or combat != null or get_tree().paused:
		return
	_t_equipe = 0.0
	var t := Compagnons.couvrir_si_enfant(self)
	if t != "":
		hud.annoncer(t)
		return
	var lignes := Compagnons.reactions(self)
	if not lignes.is_empty():
		hud.annoncer("\n".join(lignes))


## Une nuit avec un ou plusieurs PNJ : la fenêtre de scène.
func scene_intime(pnjs: Array, lieu: String, defi := {}) -> void:
	var s = preload("res://scripts/scene_intime.gd").new()
	add_child(s)
	s.commencer(self, pnjs, lieu, defi)
	var texte: String = await s.finie
	Horloge.avancer(480.0)
	Illustrations.montrer("passer_la_nuit_fin", pnjs.map(func(n): return n.id) + [lieu], texte)
	if not defi.is_empty():
		await Illustrations.ferme
		Defis.resoudre(self, pnjs[0], defi.defi, int(defi.get("compte", 0)) >= int(defi.fois))


var _t_defis := 0.0


## Toutes les 20 secondes : un PNJ près de toi peut te lancer un de ses défis (une fois par jour).
func _surveiller_defis(delta: float) -> void:
	_t_defis += delta
	if _t_defis < 20.0:
		return
	_t_defis = 0.0
	if combat != null or Illustrations.ouvert or fenetres.ouvert != "" or get_tree().paused or combat_auto:
		return
	for n in pnjs:
		if not n.visible or n.mort or n.suit or n.pos2d().distance_to(joueur.pos2d()) > 6.0:
			continue
		var cle := "propose_%s_%d" % [n.id, Horloge.jour()]
		var offres := Defis.de(self, n).filter(func(d): return d.propose == "1")
		if offres.is_empty() or fiche.drapeaux.has(cle) or randf() > 0.25:
			continue
		fiche.drapeaux[cle] = true
		var d: Dictionary = offres.pick_random()
		fenetres.choix(d.nom, d.texte, [["Accepter", Defis.accepter.bind(self, n, d.id), d.recompense],
			["Refuser", func(): relations[n.id] = clampi(relations.get(n.id, 0) - 1, -100, 100), "Il haussera les épaules."]])
		return


func _pnj_par_id(id: String) -> Node:
	for n in pnjs:
		if n.id == id:
			return n
	return null


## Le joueur s'en prend à un PNJ : "bagarre" (à mains nues) ou "mortel".
func combat_contre_pnj(cible: Node, mode: String, extra := {}) -> void:
	var amical: bool = extra.has("defi") or extra.has("entrainement")
	if cible.suit and not amical:
		Compagnons.laisser(self, cible)   # on ne frappe pas son équipe en la gardant
	var ennemis := [Combattant.depuis_pnj(cible.donnees, cible)]
	var contexte := {"cible": cible}
	contexte.merge(extra)
	if amical:
		# un défi ou un entraînement : personne ne t'en veut
		_lancer([Combattant.joueur(joueur, fiche)], ennemis, mode, contexte)
		return
	if mode == "mortel":
		relations[cible.id] = clampi(relations.get(cible.id, 0) - 40, -100, 100)
		for t in temoins():
			if t != cible:
				relations[t.id] = clampi(relations.get(t.id, 0) - 15, -100, 100)
		# le garde intervient, sauf la nuit (il a peur du noir)
		var garde := _pnj_par_id("BRU014")
		var h: float = Horloge.heure()
		if garde and garde != cible and not garde.suit and garde.visible and garde.pos2d().distance_to(joueur.pos2d()) < 40.0 and h > 6.0 and h < 21.0:
			ennemis.append(Combattant.depuis_pnj(garde.donnees, garde))
	else:
		relations[cible.id] = clampi(relations.get(cible.id, 0) - 5, -100, 100)
	sauver_etat()
	_lancer([Combattant.joueur(joueur, fiche)], ennemis, mode, contexte)


func _surveiller_loups() -> void:
	if combat != null or Illustrations.ouvert or joueur == null:
		return
	if Horloge.jour() == _dernier_jour_loups:
		return
	if joueur.pos2d().distance_to(lieux.loups.pos) > 28.0:
		return
	_dernier_jour_loups = Horloge.jour()
	if fiche.a("ami_betes"):
		sauver_etat()
		Illustrations.montrer("loups_passent", ["loups"], "Des yeux jaunes dans les fourrés. La meute te regarde longtemps, renifle l'air, puis s'écarte. Les bêtes n'attaquent pas d'abord ceux qui sont des leurs.")
		return
	sauver_etat()
	attaque_de_betes("loup", 2 + randi() % 2, lieux.loups.pos + Vector2(0, 7),
		"Des grognements dans les fourrés. Des yeux jaunes, bas, qui s'approchent. La meute t'a senti.", {"loups": true})


## Des bêtes surgissent autour de « centre » et attaquent après l'illustration.
func attaque_de_betes(type: String, nombre: int, centre: Vector2, texte: String, contexte := {}) -> void:
	var ennemis := []
	for i in nombre:
		var n := preload("res://scripts/bete.gd").new()
		n.planche = Combattant.BETES[type].planche
		var p := centre + Vector2(randf_range(-4, 4), randf_range(-4, 4))
		if not praticable(p):
			p = centre
		n.position = Vector3(p.x, hauteur(p.x, p.y), p.y)
		add_child(n)
		_loups.append(n)
		ennemis.append(Combattant.bete(type, i + 1 if nombre > 1 else 0, n))
	contexte.betes = type
	Illustrations.montrer("loups" if contexte.has("loups") else "betes_" + type, [type], texte)
	await Illustrations.ferme
	_lancer([Combattant.joueur(joueur, fiche)], ennemis, "mortel", contexte)


## Les rencontres de la côte, une chance toutes les 6 secondes selon l'endroit :
## un loup isolé ou un sanglier dans le bois, un crabe-rocher sur la grève à marée basse.
func _surveiller_rencontres(delta: float) -> void:
	_t_rencontres += delta
	if _t_rencontres < 6.0:
		return
	_t_rencontres = 0.0
	if combat != null or Illustrations.ouvert or joueur == null or get_tree().paused:
		return
	var p: Vector2 = joueur.pos2d()
	var t: float = Horloge.maintenant()
	if t < _prochaine_rencontre.get("toutes", 0.0):
		return
	var dans_bois := Geometry2D.is_point_in_polygon(p, bois)
	var dans_landes := Geometry2D.is_point_in_polygon(p, landes)
	var greve := false
	for k in ["plage", "crique", "bouche"]:
		if lieux.has(k) and p.distance_to(lieux[k].pos) < 25.0:
			greve = true
	var loin_taniere: bool = p.distance_to(lieux.loups.pos) > 40.0
	var choix := ""
	if dans_bois and loin_taniere and randf() < 1.0 / 20.0:
		choix = "loup"
	elif (dans_bois or dans_landes) and randf() < 1.0 / 35.0:
		choix = "sanglier"
	elif greve and Horloge.maree_basse() and randf() < 1.0 / 8.0:
		choix = "crabe"
	if choix == "" or t < _prochaine_rencontre.get(choix, 0.0):
		return
	_prochaine_rencontre[choix] = t + {"loup": 7200.0, "sanglier": 14400.0, "crabe": 10800.0}[choix]
	_prochaine_rencontre["toutes"] = t + 1200.0
	if choix != "crabe" and fiche.a("ami_betes"):
		Illustrations.montrer("betes_passent", [choix], "Une bête dans les fourrés. Elle te regarde, renifle, et passe son chemin.")
		return
	var centre: Vector2 = p + Vector2(randf_range(-5, 5), randf_range(4, 6))
	match choix:
		"loup":
			attaque_de_betes("loup", 1, centre, "Un loup seul, maigre, la queue basse. Chassé de sa meute, il a faim, et toi tu marches seul. Un loup isolé fuit quand ça tourne mal.")
		"sanglier":
			attaque_de_betes("sanglier", 1, centre, "Les ronces craquent. Un sanglier sort du fourré, la hure basse, et gratte la terre. Il va charger : écarte-toi de sa ligne.")
		"crabe":
			attaque_de_betes("crabe", 1, p + Vector2(2, 0), "Le rocher sous ton pied bouge. Ce n'est pas un rocher : c'est un crabe-rocher, et il n'aime pas qu'on lui marche dessus. Sa carapace est dure ; son ventre, beaucoup moins.")


func _lancer(allies: Array, ennemis: Array, mode: String, contexte: Dictionary) -> void:
	combat = preload("res://scripts/combat.gd").new()
	combat.auto = combat_auto
	add_child(combat)
	joueur.set_process(false)
	contexte.mode = mode
	if mode != "bagarre":
		allies = allies + Compagnons.allies(self, contexte.cible.id if contexte.has("cible") else "")
	combat.fini.connect(_fin_combat.bind(contexte, allies, ennemis))
	combat.commencer(self, allies, ennemis, joueur.pos2d(), mode)


## Épargner un vaincu : il te doit la vie, et ceux qui l'ont vu aussi s'en souviennent.
func epargner(c: Combattant) -> void:
	relations[c.id] = clampi(relations.get(c.id, 0) + 15, -100, 100)
	for t in temoins(40.0):
		if t.id != c.id:
			relations[t.id] = clampi(relations.get(t.id, 0) + 3, -100, 100)
	fiche.drapeaux["doit_la_vie_" + c.id] = true
	sauver_etat()


func tuer(c: Combattant) -> void:
	var n := _pnj_par_id(c.id)
	if n == null:
		return
	morts[c.id] = true
	n.mort = true
	for t in temoins(40.0):
		relations[t.id] = clampi(relations.get(t.id, 0) - 30, -100, 100)
	sauver_etat()


func _fin_combat(resultat: String, contexte: Dictionary, allies: Array, ennemis: Array) -> void:
	combat = null
	joueur.set_process(true)
	var texte := ""
	var action := "combat_" + resultat
	var cles := ["loups"] if contexte.has("loups") else ([contexte.betes] if contexte.has("betes") else ([contexte.cible.id] if contexte.has("cible") else []))
	var tues := ennemis.filter(func(c): return c.mort).map(func(c): return c.nom)
	match resultat:
		"victoire":
			if contexte.has("loups"):
				texte = "La meute est dispersée. Tu as les mains qui tremblent."
			elif contexte.has("betes"):
				texte = {"loup": "Le loup ne bouge plus, ou il a fui dans les fougères.", "rat": "Le dernier rat couine et file dans un trou. La cave est à toi.",
					"crabe": "Retourné sur le dos, le crabe agite ses pattes une dernière fois.", "sanglier": "Le sanglier s'effondre dans les ronces. De quoi manger pour des jours."}.get(contexte.betes, "Les bêtes sont parties.")
			elif contexte.has("cible"):
				texte = "%s est au sol." % contexte.cible.donnees.nom
				if tues:
					texte += " Tu as tué : %s. Le village le saura avant ce soir." % ", ".join(tues)
				else:
					texte += " Personne n'est mort. Ça se racontera quand même."
		"defaite":
			if contexte.has("loups"):
				texte = "Le noir. Puis l'odeur des herbes : Pierrick t'a trouvé et porté chez Agnès. « T'as de la chance que j'aie entendu les loups. »"
			elif contexte.has("betes"):
				texte = "Le noir. Tu te réveilles chez Agnès, qui recoud en grommelant : « Battu par une bête. Ça arrive aux meilleurs, et surtout aux autres. »"
			else:
				texte = "Tu te réveilles plus tard, chez Agnès, le visage en sang." if contexte.mode == "bagarre" else "Tu te réveilles plus tard, chez Agnès, le visage en sang et la bourse plus légère."
			Horloge.avancer(180.0)
			var p: Vector2 = lieux.agnes.pos + Vector2(0, 4)
			joueur.position = Vector3(p.x, hauteur(p.x, p.y), p.y)
		"fuite":
			texte = "Tu as pris tes jambes à ton cou. Ceux qui t'ont vu fuir s'en souviendront."
		"reddition":
			texte = "Tu lèves les mains. On te laisse partir, cette fois, avec un dernier coup pour la route."
	if contexte.has("entrainement"):
		texte = "L'entraînement est fini. %s" % ("Tu l'as mis au tapis." if resultat == "victoire" else "Tu as mordu la poussière, mais tu as appris.")
	texte += _apres_combat(resultat, contexte, allies, ennemis)
	for n in _loups:
		n.queue_free()
	_loups.clear()
	sauver_etat()
	if texte != "":
		Illustrations.montrer(action, cles, texte)
	if contexte.has("defi"):
		if Illustrations.ouvert:
			await Illustrations.ferme
		Defis.resoudre(self, contexte.cible, contexte.defi, resultat == "victoire")
	# les vaincus encore à terre : à toi de décider de leur sort
	var vaincus := ennemis.filter(func(c): return c.a_terre and not c.mort and not c.est_bete)
	if resultat == "victoire" and contexte.mode != "bagarre" and not vaincus.is_empty() and not combat_auto:
		if Illustrations.ouvert:
			await Illustrations.ferme
		fenetres.sort_des_vaincus(vaincus)
		await fenetres.ferme
	if _proposer_classe:
		_proposer_classe = false
		if Illustrations.ouvert:
			await Illustrations.ferme
		fenetres.offre_classe()


## Ce que le combat laisse : PV, expérience, butin, argent. Renvoie le texte à ajouter.
func _apres_combat(resultat: String, contexte: Dictionary, allies: Array, ennemis: Array) -> String:
	var lignes := []
	var moi: Combattant = allies[0]
	fiche.pv = maxi(1, moi.pv) if not (moi.a_terre or moi.mort) else maxi(1, fiche.pv_max() / 4)
	fiche.mana = moi.mana
	# lancer un élément le fait monter (competences.md : l'affinité bouge avec la vie)
	for tag in moi.style:
		if tag.begins_with("magie_"):
			fiche.pratiquer_element(tag.trim_prefix("magie_"), moi.style[tag])
	var bagarre: bool = contexte.mode == "bagarre"
	# l'expérience : vaincre plus fort que soi rapporte beaucoup, écraser plus faible presque rien
	# perdre apprend aussi quelque chose : un quart de l'expérience
	if resultat in ["victoire", "defaite", "reddition"]:
		var xp := 0.0
		for e in ennemis:
			if e.sorti and not e.a_terre:
				xp += 0.5 * _xp_contre(e)
			else:
				xp += _xp_contre(e)
		if bagarre:
			xp *= 0.5
		if resultat != "victoire":
			xp *= 0.25
		if moi.a_comp("trophee") and (contexte.has("betes") or contexte.has("loups")):
			xp *= 1.25
		var gain := maxi(1, roundi(xp))
		var niveaux := fiche.gagner_xp(gain)
		lignes.append("+%d expérience%s." % [gain, "" if resultat == "victoire" else " (on apprend en prenant des coups)"])
		if niveaux:
			lignes.append("Niveau %d ! %d points à répartir (touche C)." % [fiche.niveau, fiche.points])
	# ce que tu as fait dans ce combat dit quelle classe s'éveille en toi (classes_metiers.md)
	fiche.noter_style(moi.style)
	lignes.append_array(fiche.annonces)
	fiche.annonces.clear()
	if fiche.classe == "" and not bagarre and not combat_auto and not Classes.offre(fiche.style).is_empty():
		_proposer_classe = true
	# le butin
	if resultat == "victoire" and contexte.has("betes"):
		var pris := {}
		for e in ennemis:
			if e.a_terre or e.mort:
				for b in BUTIN.get(contexte.betes, []):
					if randf() < b[1] + (0.25 if moi.a_comp("pillage") else 0.0):
						pris[b[0]] = pris.get(b[0], 0) + 1
		for id in pris:
			fiche.ajouter(id, pris[id])
		if pris:
			lignes.append("Tu prends : %s." % ", ".join(pris.keys().map(func(id): return "%s ×%d" % [Objets.get_(id).nom.to_lower(), pris[id]])))
		if contexte.has("paie"):
			fiche.bourse += contexte.paie
			lignes.append("%s te paie %s." % [contexte.get("payeur", "On"), Objets.texte_prix(contexte.paie)])
			if contexte.has("payeur_id"):
				relations[contexte.payeur_id] = clampi(relations.get(contexte.payeur_id, 0) + 5, -100, 100)
	elif resultat == "victoire" and bagarre:
		lignes.append("Le perdant paie la tournée : +6 cuivre.")
		fiche.bourse += 6
	elif resultat == "victoire":
		var cuivre := 0
		for e in ennemis:
			if not (e.a_terre or e.mort) or e.est_bete:
				continue
			cuivre += roundi(randi_range(4, 24) * (2 if fiche.a("trouvaille") else 1) * (1.5 if moi.a_comp("pillage") else 1.0))
			if e.arme.has("objet"):
				fiche.ajouter(e.arme.objet)
				lignes.append("Tu prends %s de %s." % [Objets.get_(e.arme.objet).nom.to_lower(), e.nom])
			if not e.mort:
				relations[e.id] = clampi(relations.get(e.id, 0) - 10, -100, 100)
		if cuivre:
			fiche.bourse += cuivre
			lignes.append("Tu fouilles les poches : %s." % Objets.texte_prix(cuivre))
	elif resultat == "defaite" and bagarre and fiche.bourse > 0:
		var paye := mini(6, fiche.bourse)
		fiche.bourse -= paye
		lignes.append("Tu paies la tournée : %s." % Objets.texte_prix(paye))
	elif resultat == "defaite" and not contexte.has("betes") and fiche.bourse > 0:
		var perdu := ceili(fiche.bourse / 2.0)
		fiche.bourse -= perdu
		lignes.append("On t'a pris %s." % Objets.texte_prix(perdu))
	fiche.sauver()
	return "" if lignes.is_empty() else "\n\n" + " ".join(lignes)


func _xp_contre(e: Combattant) -> float:
	return 10.0 * e.niveau * clampf(float(e.niveau) / fiche.niveau, 0.2, 3.0)


# ---------------------------------------------------------------- les PNJ qui t'en veulent

## Toutes les 5 secondes : un PNJ adulte qui te déteste et te voit peut venir t'agresser,
## selon sa colère, son courage et sa prudence. Silas, lui, envoie ses hommes la nuit.
func _surveiller_hostiles(delta: float) -> void:
	_t_hostiles += delta
	if _t_hostiles < 5.0:
		return
	_t_hostiles = 0.0
	if combat != null or Illustrations.ouvert or joueur == null:
		return
	var maintenant: float = Horloge.maintenant()
	for n in pnjs:
		if n.mort or n.hostile or not n.visible or int(n.donnees.age) < 18:
			continue
		if maintenant < n.prochaine_agression:
			continue
		var aff: int = relations.get(n.id, 0)
		if aff > -40 or n.pos2d().distance_to(joueur.pos2d()) > 25.0:
			continue
		var p := clampf((-aff - 30) / 70.0, 0.0, 1.0)
		p *= (n.trait_("colerique") + 100) / 200.0
		p *= (n.trait_("courageux") + 100) / 200.0
		p *= (100 - n.trait_("prudent")) / 200.0 + 0.25
		p *= 0.6
		n.prochaine_agression = maintenant + 600.0
		if randf() < p:
			n.prochaine_agression = maintenant + 7200.0
			n.hostile = true
			return
	_silas_envoie_ses_hommes()


func _silas_envoie_ses_hommes() -> void:
	var h: float = Horloge.heure()
	if relations.get("BRU003", 0) > -60 or Horloge.jour() == _dernier_jour_silas or (h > 5.0 and h < 21.0):
		return
	var envoyes := 0
	for id in ["BRU021", "BRU022"]:
		var n := _pnj_par_id(id)
		if n and not n.mort:
			var p: Vector2 = joueur.pos2d() + Vector2(randf_range(-20, 20), 22.0)
			if praticable(p):
				n.position = Vector3(p.x, hauteur(p.x, p.y), p.y)
			n.hostile = true
			envoyes += 1
	if envoyes > 0:
		_dernier_jour_silas = Horloge.jour()


## Un PNJ hostile t'a rejoint : il attaque, avec ceux qui foncent aussi sur toi.
func agression_par(n: Node) -> void:
	if combat != null:
		return
	var aff: int = relations.get(n.id, 0)
	var mode := "mortel" if aff <= -70 or n.id in ["BRU021", "BRU022"] else "bagarre"
	var ennemis := [Combattant.depuis_pnj(n.donnees, n)]
	for autre in pnjs:
		if autre != n and autre.hostile and autre.pos2d().distance_to(joueur.pos2d()) < 30.0:
			autre.hostile = false
			ennemis.append(Combattant.depuis_pnj(autre.donnees, autre))
	var phrase := "« Cette fois, je vais te crever. »" if mode == "mortel" else "« T'as cru que j'allais oublier ? Viens là, que je t'arrange la gueule. »"
	if n.id in ["BRU021", "BRU022"]:
		phrase = "« Silas te passe le bonjour. »"
	Illustrations.montrer("agression", [n.id], "%s fonce sur toi. %s" % [n.donnees.nom, phrase])
	await Illustrations.ferme
	_lancer([Combattant.joueur(joueur, fiche)], ennemis, mode, {"cible": n, "agresseur": true})


func marquer_mort(c: Combattant) -> void:
	var n := _pnj_par_id(c.id)
	if n:
		morts[c.id] = true
		n.mort = true
		sauver_etat()
