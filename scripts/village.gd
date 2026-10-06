extends Node2D
## Village en vue de dessus : exploration, dialogues avec les PNJ,
## et témoins qui réagissent à tes actions.

const SPEED := 180.0
const TALK_RADIUS := 60.0
## Distance à laquelle un PNJ voit ce que tu fais.
const WITNESS_RADIUS := 300.0

const DialogueBox := preload("res://scripts/dialogue_box.gd")

var player_pos := Vector2(640, 620)
var facing := Vector2.DOWN
var walk_time := 0.0
var time := 0.0
var talk_cooldown := 0.0
var pending_battle := false

var npcs := [
	{"id": "chef", "pos": Vector2(330, 300), "body": Color(0.55, 0.35, 0.6), "hair": Color(0.85, 0.85, 0.85)},
	{"id": "forge", "pos": Vector2(980, 300), "body": Color(0.6, 0.3, 0.2), "hair": Color(0.85, 0.45, 0.15)},
	{"id": "kael", "pos": Vector2(1150, 420), "body": Color(0.3, 0.5, 0.3), "hair": Color(0.3, 0.2, 0.12)},
	{"id": "mira", "pos": Vector2(440, 530), "body": Color(0.45, 0.2, 0.55), "hair": Color(0.85, 0.2, 0.2)},
	{"id": "pip", "pos": Vector2(780, 470), "body": Color(0.3, 0.55, 0.85), "hair": Color(0.95, 0.85, 0.4)},
]

var houses: Array[Rect2] = [
	Rect2(200, 110, 240, 150),
	Rect2(860, 110, 240, 150),
	Rect2(120, 470, 200, 140),
	Rect2(980, 490, 200, 130),
]
var well := Rect2(612, 432, 56, 56)
var trees: Array[Vector2] = [
	Vector2(60, 60), Vector2(130, 330), Vector2(500, 80), Vector2(770, 70),
	Vector2(1220, 80), Vector2(1230, 300), Vector2(60, 680), Vector2(1220, 680),
	Vector2(500, 660), Vector2(820, 660),
]

## Textes flottants : {text, pos, age, color}
var popups: Array = []
var hud_label: Label
var dialogue: CanvasLayer


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.33, 0.55, 0.3))
	dialogue = DialogueBox.new()
	add_child(dialogue)
	dialogue.closed.connect(_on_dialogue_closed)
	GameState.opinion_changed.connect(_on_opinion_changed)
	GameState.reputation_changed.connect(_on_reputation_changed)
	GameState.action_witnessed.connect(_on_action_witnessed)
	GameState.battle_requested.connect(func(): pending_battle = true)
	_build_hud()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.1, 0.8)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(panel)
	hud_label = Label.new()
	panel.add_child(hud_label)

	var help := Label.new()
	help.text = "Flèches / ZQSD : se déplacer   ·   E : parler   ·   Espace / Entrée / clic : choisir"
	help.position = Vector2(12, 692)
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	help.add_theme_color_override("font_outline_color", Color.BLACK)
	help.add_theme_constant_override("outline_size", 4)
	layer.add_child(help)


func _process(delta: float) -> void:
	time += delta
	talk_cooldown = maxf(0.0, talk_cooldown - delta)
	if not dialogue.is_open():
		_move_player(delta)
	for p in popups:
		p["age"] += delta
	popups = popups.filter(func(p): return p["age"] < 1.6)
	var rep := GameState.reputation
	hud_label.text = "Or : %d     Réputation : %+d (%s)\nGroupe : %s" % [
		GameState.gold, rep, GameState.attitude_name(rep), ", ".join(GameState.party_names())]
	queue_redraw()


func _move_player(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# ZQSD/WASD : touches physiques, marche en AZERTY comme en QWERTY.
	if Input.is_physical_key_pressed(KEY_A): dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): dir.x += 1
	if Input.is_physical_key_pressed(KEY_W): dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S): dir.y += 1
	if dir == Vector2.ZERO:
		walk_time = 0.0
		return
	dir = dir.normalized()
	facing = dir
	walk_time += delta
	var step := dir * SPEED * delta
	# Collision séparée par axe pour glisser le long des murs.
	if not _blocked(player_pos + Vector2(step.x, 0)):
		player_pos.x += step.x
	if not _blocked(player_pos + Vector2(0, step.y)):
		player_pos.y += step.y


func _blocked(p: Vector2) -> bool:
	if p.x < 16 or p.x > 1264 or p.y < 30 or p.y > 700:
		return true
	var feet := Rect2(p - Vector2(10, 6), Vector2(20, 10))
	for h in houses:
		if h.intersects(feet):
			return true
	if well.intersects(feet):
		return true
	for t in trees:
		if p.distance_to(t + Vector2(0, 10)) < 26:
			return true
	for n in npcs:
		if p.distance_to(n["pos"]) < 26:
			return true
	return false


func _nearest_npc() -> Dictionary:
	var best := {}
	var best_d := TALK_RADIUS
	for n in npcs:
		var d := player_pos.distance_to(n["pos"])
		if d < best_d:
			best_d = d
			best = n
	return best


func _unhandled_input(event: InputEvent) -> void:
	if dialogue.is_open() or talk_cooldown > 0.0:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
		var n := _nearest_npc()
		if not n.is_empty():
			get_viewport().set_input_as_handled()
			facing = (n["pos"] - player_pos).normalized()
			dialogue.open(n["id"])


func _on_dialogue_closed() -> void:
	talk_cooldown = 0.25
	if pending_battle:
		pending_battle = false
		get_tree().change_scene_to_file("res://scenes/battle.tscn")


func _npc_by_id(id: String) -> Dictionary:
	for n in npcs:
		if n["id"] == id:
			return n
	return {}


func _on_opinion_changed(id: String, delta: int) -> void:
	var n := _npc_by_id(id)
	if n.is_empty():
		return
	var col := Color(0.5, 1, 0.5) if delta > 0 else Color(1, 0.45, 0.4)
	_popup(n["pos"] + Vector2(0, -70), "%+d" % delta, col)


func _on_reputation_changed(delta: int) -> void:
	var col := Color(0.6, 0.85, 1) if delta > 0 else Color(1, 0.6, 0.3)
	_popup(player_pos + Vector2(0, -80), "Réputation %+d" % delta, col)


## Les PNJ assez proches voient la scène et changent d'avis.
func _on_action_witnessed(delta: int, speaker: String) -> void:
	for n in npcs:
		if n["id"] == speaker:
			continue
		if n["pos"].distance_to(player_pos) <= WITNESS_RADIUS:
			GameState.change_opinion(n["id"], delta)
			_popup(n["pos"] + Vector2(0, -90), "a vu la scène !", Color(1, 0.9, 0.5))


func _popup(pos: Vector2, text: String, color: Color) -> void:
	popups.append({"text": text, "pos": pos, "age": 0.0, "color": color})


# --- Dessin ---------------------------------------------------------------

func _draw() -> void:
	_draw_ground()
	for h in houses:
		_draw_house(h)
	_draw_well()

	# Personnages et arbres triés par profondeur (y).
	var drawables := []
	for t in trees:
		drawables.append({"y": t.y + 10, "kind": "tree", "pos": t})
	for n in npcs:
		drawables.append({"y": n["pos"].y, "kind": "npc", "npc": n})
	drawables.append({"y": player_pos.y, "kind": "player"})
	drawables.sort_custom(func(a, b): return a["y"] < b["y"])
	for d in drawables:
		match d["kind"]:
			"tree":
				_draw_tree(d["pos"])
			"npc":
				_draw_npc(d["npc"])
			"player":
				_draw_shadow(player_pos, 14)
				var pose := "idle"
				if walk_time > 0.0:
					pose = "marche" if int(walk_time * 6.0) % 2 == 0 else "idle"
				LyraArt.draw(self, pose, player_pos + Vector2(0, 2), facing.x > 0.0)

	if not dialogue.is_open():
		var n := _nearest_npc()
		if not n.is_empty():
			_text(n["pos"] + Vector2(0, 24), "[E] Parler", 15, Color.WHITE)

	for p in popups:
		var a := clampf(1.6 - p["age"], 0.0, 1.0)
		var c: Color = p["color"]
		c.a = a
		_text(p["pos"] + Vector2(0, -p["age"] * 30.0), p["text"], 18, c)


func _draw_ground() -> void:
	var dirt := Color(0.62, 0.5, 0.33)
	draw_rect(Rect2(0, 340, 1280, 70), dirt)
	draw_rect(Rect2(600, 0, 80, 720), dirt)
	draw_circle(Vector2(640, 375), 110, dirt)
	# Petites touffes d'herbe pour la texture.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 160:
		var p := Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 720))
		draw_line(p, p + Vector2(2, -5), Color(0.25, 0.45, 0.22), 1.5)
	# Panneau vers la colline.
	draw_rect(Rect2(690, 30, 6, 40), Color(0.4, 0.28, 0.15))
	draw_rect(Rect2(668, 22, 70, 22), Color(0.55, 0.4, 0.22))
	_text(Vector2(703, 39), "Colline ↑", 12, Color.WHITE)


func _draw_house(r: Rect2) -> void:
	draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.25))
	draw_rect(r, Color(0.85, 0.78, 0.62))
	var roof := Rect2(r.position - Vector2(10, 40), Vector2(r.size.x + 20, r.size.y * 0.55 + 40))
	draw_rect(roof, Color(0.65, 0.25, 0.2))
	for i in range(1, 5):
		var y := roof.position.y + roof.size.y * i / 5.0
		draw_line(Vector2(roof.position.x, y), Vector2(roof.end.x, y), Color(0.5, 0.18, 0.15), 2)
	var door := Rect2(r.position.x + r.size.x / 2 - 16, r.end.y - 44, 32, 44)
	draw_rect(door, Color(0.4, 0.26, 0.14))
	draw_rect(Rect2(r.position.x + 22, r.end.y - 50, 30, 24), Color(0.55, 0.75, 0.9))
	draw_rect(Rect2(r.end.x - 52, r.end.y - 50, 30, 24), Color(0.55, 0.75, 0.9))


func _draw_well() -> void:
	var c := well.get_center()
	draw_circle(c + Vector2(4, 6), 30, Color(0, 0, 0, 0.25))
	draw_circle(c, 30, Color(0.55, 0.55, 0.58))
	draw_circle(c, 20, Color(0.15, 0.25, 0.4))


func _draw_tree(p: Vector2) -> void:
	draw_set_transform(p + Vector2(0, 14), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 26, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(p + Vector2(-6, -10), Vector2(12, 24)), Color(0.4, 0.27, 0.15))
	draw_circle(p + Vector2(0, -28), 28, Color(0.18, 0.4, 0.2))
	draw_circle(p + Vector2(-10, -36), 16, Color(0.24, 0.5, 0.26))


func _draw_npc(n: Dictionary) -> void:
	var p: Vector2 = n["pos"] + Vector2(0, sin(time * 2.0 + n["pos"].x) * 1.5)
	_draw_character(p, n["body"], n["hair"])
	var perception := GameState.perception(n["id"])
	var col := GameState.attitude_color(perception)
	_text(p + Vector2(0, -56), Dialogues.DATA[n["id"]]["name"], 13, col)
	# Petite bulle d'humeur au-dessus de la tête.
	var mood := "♥" if perception >= 20 else ("!" if perception <= -10 else "…")
	if n["id"] == "chef" and not GameState.has_flag("quete_acceptee") and not GameState.has_flag("gobelins_vaincus"):
		mood = "?"
	_text(p + Vector2(0, -74 + sin(time * 4.0) * 2.0), mood, 16, col)


func _draw_shadow(p: Vector2, radius: float) -> void:
	draw_set_transform(p + Vector2(0, 2), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, radius, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)


func _draw_character(p: Vector2, body: Color, hair: Color) -> void:
	_draw_shadow(p, 14)
	draw_rect(Rect2(p + Vector2(-10, -26), Vector2(20, 24)), body)
	draw_rect(Rect2(p + Vector2(-10, -26), Vector2(20, 24)), Color(0, 0, 0, 0.5), false, 1.5)
	draw_circle(p + Vector2(0, -34), 10, Color(0.96, 0.82, 0.68))
	draw_arc(p + Vector2(0, -36), 10, PI, TAU, 12, hair, 6)


func _text(center: Vector2, text: String, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var w := 240.0
	var pos := center - Vector2(w / 2.0, 0)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, size, 4, Color(0, 0, 0, color.a))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, size, color)
