# Un habitant : suit son emploi du temps (data/emplois.csv) sur l'horloge réelle,
# marche d'un lieu à l'autre par les chemins, flâne une fois arrivé,
# et rentre chez lui (invisible) pour dormir ou se reposer.
extends Node3D

const MARCHE := 1.5
const PLANCHES := {
	"BRU001": "res://sprites/mara_boulangere_planche.png",
	"BRU016": "res://sprites/nina_renarde_planche.png",
	"BRU020": "res://sprites/pierrick_demi_elfe_planche.png",
}
const REPOS := ["nuit", "maison", "sieste", "dort", "retour", "lever"]

var monde: Node3D
var id := ""
var donnees := {}
var emploi: Array = []     # [[heure, lieu, activité], …] trié par heure
var activite := ""
var lieu_cible := ""
var lieu_actuel := ""
var maison := ""
var mort := false
var hostile := false             # fonce sur le joueur pour l'agresser
var suit := false                # compagnon : te suit au lieu de son emploi du temps
var prochaine_agression := 0.0   # heure du monde (secondes) avant laquelle il ne recommence pas
var sprite: Sprite3D
var _chemin := PackedVector2Array()
var _ligne := 0
var _t := 0.0
var _attente := 0.0


func _ready() -> void:
	sprite = Personnage.sprite(PLANCHES.get(id, "res://sprites/villageois_planche.png"))
	if not PLANCHES.has(id):
		var teinte := float(hash(id) % 360) / 360.0
		sprite.modulate = Color.from_hsv(teinte, 0.35, 1.0)
	if int(donnees.get("age", "30")) <= 13:
		sprite.scale = Vector3.ONE * 0.75
	add_child(sprite)
	var nom := Label3D.new()
	nom.text = donnees.get("nom", id)
	nom.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nom.font_size = 32
	nom.pixel_size = 0.01
	nom.outline_size = 8
	nom.position = Vector3(0, 2.3, 0)
	nom.visibility_range_end = 25.0
	add_child(nom)
	maison = emploi[0][1]
	var e := _entree_courante()
	activite = e[2]
	lieu_cible = e[1]
	lieu_actuel = e[1]
	_poser(monde.lieux[lieu_actuel].pos + _au_hasard(5.0))


func pos2d() -> Vector2:
	return Vector2(position.x, position.z)


func _entree_courante() -> Array:
	var h: float = Horloge.heure()
	var courante: Array = emploi[emploi.size() - 1]
	for e in emploi:
		if e[0] <= h:
			courante = e
	return courante


func _au_hasard(r: float) -> Vector2:
	for i in 10:
		var d := Vector2(randf_range(-r, r), randf_range(-r, r))
		var p: Vector2 = monde.lieux[lieu_cible].pos + d
		if monde.praticable(p):
			return d
	return Vector2.ZERO


func _poser(p: Vector2) -> void:
	position = Vector3(p.x, monde.hauteur(p.x, p.y), p.y)


func au_repos() -> bool:
	if lieu_actuel != maison or not _chemin.is_empty():
		return false
	for mot in REPOS:
		if activite.to_lower().contains(mot):
			return true
	return false


## Valeur d'un trait (-100 à +100) : « colerique +70 » → 70.
func trait_(nom: String) -> int:
	for t in str(donnees.get("traits", "")).split(","):
		var morceaux := t.strip_edges().split(" ")
		if morceaux.size() >= 2 and morceaux[0] == nom:
			return int(morceaux[1])
	return 0


func _process(delta: float) -> void:
	if mort:
		visible = false
		return
	if hostile:
		visible = true
		var cible: Vector2 = monde.joueur.pos2d()
		var d := cible - pos2d()
		if d.length() < 1.8:
			hostile = false
			monde.agression_par(self)
			return
		_ligne = Personnage.ligne_de(d)
		_poser(pos2d() + d.normalized() * minf(3.5 * delta, d.length()))
		_t += delta * 10.0
		sprite.frame = _ligne * 4 + int(_t) % 4
		_chemin.clear()
		return
	if suit:
		visible = true
		var but: Vector2 = monde.joueur.pos2d()
		var ecart := but - pos2d()
		if ecart.length() > 2.2:
			_ligne = Personnage.ligne_de(ecart)
			_poser(pos2d() + ecart.normalized() * minf(4.5 * delta, ecart.length() - 2.0))
			_t += delta * 6.0
			sprite.frame = _ligne * 4 + int(_t) % 4
		else:
			sprite.frame = _ligne * 4
		lieu_actuel = monde.lieu_proche(pos2d(), INF)
		_chemin.clear()
		return
	var e := _entree_courante()
	activite = e[2]
	if e[1] != lieu_cible:
		lieu_cible = e[1]
		_chemin = monde.chemin(monde.lieu_proche(pos2d(), INF), lieu_cible)
		_chemin.append(monde.lieux[lieu_cible].pos + _au_hasard(5.0))
	visible = not au_repos()
	var vitesse := minf(MARCHE * Horloge.acceleration, 40.0)
	if _chemin.is_empty():
		_attente -= delta * Horloge.acceleration
		if _attente <= 0.0:
			_attente = randf_range(20.0, 60.0)
			_chemin.append(monde.lieux[lieu_cible].pos + _au_hasard(6.0))
		sprite.frame = _ligne * 4
		return
	var p := pos2d()
	var cible := _chemin[0]
	var d := cible - p
	var pas := vitesse * delta
	if d.length() <= pas:
		p = cible
		_chemin.remove_at(0)
		if _chemin.size() <= 1:
			lieu_actuel = lieu_cible
	else:
		p += d.normalized() * pas
		_ligne = Personnage.ligne_de(d)
	_poser(p)
	_t += delta * 6.0
	sprite.frame = _ligne * 4 + int(_t) % 4
