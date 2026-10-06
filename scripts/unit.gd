class_name Unit
extends RefCounted
## Une unité sur la grille de combat (alliée ou ennemie).

enum Team { PLAYER, ENEMY }

var unit_name: String
var job: String
var team: Team
var color: Color
var max_hp: int
var hp: int
var atk: int
var defense: int
var move: int
var jump: int
var attack_range: int
var speed: int
## Type de dégâts infligés : "épée", "lance", "arc", "feu", "griffe"...
var damage_type: String
## Système Break inspiré d'Octopath Traveler : frapper une faiblesse
## retire un point de bouclier ; à 0, l'unité est brisée.
var weaknesses: Array[String] = []
var max_shield := 0
var shield := 0
var broken_turns := 0

var cell: Vector2i
## Charge Time (style FFT) : l'unité agit quand il atteint 100.
var ct := 0
var draw_pos: Vector2
var has_moved := false
var has_acted := false


static func create(data: Dictionary) -> Unit:
	var u := Unit.new()
	u.unit_name = data["name"]
	u.job = data["job"]
	u.team = data["team"]
	u.color = data["color"]
	u.max_hp = data["hp"]
	u.hp = u.max_hp
	u.atk = data["atk"]
	u.defense = data["def"]
	u.move = data["move"]
	u.jump = data["jump"]
	u.attack_range = data["range"]
	u.speed = data["speed"]
	u.damage_type = data["type"]
	u.weaknesses.assign(data.get("weaknesses", []))
	u.max_shield = data.get("shield", 0)
	u.shield = u.max_shield
	u.cell = data["cell"]
	return u


func is_alive() -> bool:
	return hp > 0


func is_broken() -> bool:
	return broken_turns > 0
