extends Node
## État global de la partie (autoload "GameState") : or, réputation,
## opinion de chaque PNJ et drapeaux de progression.

signal opinion_changed(npc_id: String, delta: int)
signal reputation_changed(delta: int)
## Émis quand une action est faite devant témoins : le village décide
## quels PNJ l'ont vue et applique `delta` à leur opinion.
signal action_witnessed(delta: int, speaker_id: String)
signal battle_requested

var gold := 30
## Réputation globale dans le village : elle colore la perception de tous.
var reputation := 0
## Opinion personnelle de chaque PNJ envers l'héroïne.
var opinions := {
	"chef": 10,
	"forge": 0,
	"kael": 0,
	"mira": 0,
	"pip": 10,
}
var flags := {}


## Ce que le PNJ pense vraiment : son avis perso + ce que dit la rumeur.
func perception(npc_id: String) -> int:
	return clampi(opinions.get(npc_id, 0) + reputation / 2, -100, 100)


static func attitude_name(value: int) -> String:
	if value <= -50:
		return "Hostile"
	if value < -10:
		return "Méfiant"
	if value < 20:
		return "Neutre"
	if value < 50:
		return "Amical"
	return "Dévoué"


static func attitude_color(value: int) -> Color:
	if value <= -50:
		return Color(0.9, 0.2, 0.2)
	if value < -10:
		return Color(0.95, 0.6, 0.25)
	if value < 20:
		return Color(0.85, 0.85, 0.85)
	if value < 50:
		return Color(0.45, 0.85, 0.45)
	return Color(0.95, 0.75, 0.95)


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


func set_flag(flag: String, value := true) -> void:
	flags[flag] = value


func change_opinion(npc_id: String, delta: int) -> void:
	if delta == 0:
		return
	opinions[npc_id] = clampi(opinions.get(npc_id, 0) + delta, -100, 100)
	opinion_changed.emit(npc_id, delta)


func change_reputation(delta: int) -> void:
	if delta == 0:
		return
	reputation = clampi(reputation + delta, -100, 100)
	reputation_changed.emit(delta)


## Vérifie une condition de dialogue, par ex. {"opinion_min": 30, "flag": "x"}.
func check(cond: Dictionary, speaker: String) -> bool:
	if cond.has("opinion_min") and perception(speaker) < cond["opinion_min"]:
		return false
	if cond.has("opinion_max") and perception(speaker) > cond["opinion_max"]:
		return false
	if cond.has("rep_min") and reputation < cond["rep_min"]:
		return false
	if cond.has("rep_max") and reputation > cond["rep_max"]:
		return false
	if cond.has("gold_min") and gold < cond["gold_min"]:
		return false
	for f in _as_list(cond.get("flag", [])):
		if not has_flag(f):
			return false
	for f in _as_list(cond.get("not_flag", [])):
		if has_flag(f):
			return false
	return true


## Applique les effets d'un nœud de dialogue.
func apply_effects(effects: Dictionary, speaker: String) -> void:
	if effects.has("gold"):
		gold = maxi(0, gold + effects["gold"])
	if effects.has("opinion"):
		change_opinion(speaker, effects["opinion"])
	for id in effects.get("opinion_of", {}):
		change_opinion(id, effects["opinion_of"][id])
	if effects.has("reputation"):
		change_reputation(effects["reputation"])
	for f in _as_list(effects.get("set", [])):
		set_flag(f)
	for f in _as_list(effects.get("unset", [])):
		set_flag(f, false)
	if effects.has("witnessed"):
		action_witnessed.emit(effects["witnessed"], speaker)
	if effects.get("battle", false):
		battle_requested.emit()


func party_names() -> Array[String]:
	var names: Array[String] = ["Lyra", "Bran"]
	if has_flag("kael_recrute"):
		names.append("Kael")
	if has_flag("mira_recrutee"):
		names.append("Mira")
	return names


static func _as_list(value) -> Array:
	return value if value is Array else [value]
