extends Node2D
## Combat tactique sur grille isométrique (style Final Fantasy Tactics Advance)
## avec le système Faiblesse/Break d'Octopath Traveler.
## Le groupe dépend des choix faits au village (GameState).

const TILE_W := 64
const TILE_H := 32
const STEP_H := 12
const BASE_DEPTH := 10
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

## Hauteur de chaque case (un chiffre par case), ligne = y.
const MAP_ROWS: Array[String] = [
	"0000112222",
	"0000112332",
	"0001111232",
	"0011100111",
	"0010000011",
	"0000000001",
	"1100000000",
	"2210000000",
	"3221000000",
	"3321100000",
]

const PLAYER_UNITS := {
	"Lyra": {"job": "Soldate", "color": Color(0.25, 0.4, 0.85), "hp": 42, "atk": 14, "def": 8,
		"move": 4, "jump": 2, "range": 1, "speed": 9, "type": "épée", "cell": Vector2i(2, 6)},
	"Bran": {"job": "Lancier", "color": Color(0.85, 0.55, 0.2), "hp": 46, "atk": 13, "def": 9,
		"move": 4, "jump": 3, "range": 2, "speed": 7, "type": "lance", "cell": Vector2i(3, 7)},
	"Kael": {"job": "Archer", "color": Color(0.3, 0.65, 0.3), "hp": 32, "atk": 12, "def": 5,
		"move": 4, "jump": 2, "range": 4, "speed": 11, "type": "arc", "cell": Vector2i(1, 8)},
	"Mira": {"job": "Mage noire", "color": Color(0.55, 0.3, 0.75), "hp": 28, "atk": 16, "def": 4,
		"move": 3, "jump": 1, "range": 3, "speed": 8, "type": "feu", "cell": Vector2i(0, 7)},
}

const ENEMY_UNITS: Array[Dictionary] = [
	{"name": "Gobelin A", "job": "Gobelin", "color": Color(0.75, 0.25, 0.25), "hp": 30, "atk": 11, "def": 5,
		"move": 4, "jump": 2, "range": 1, "speed": 8, "type": "griffe",
		"weaknesses": ["feu", "lance"], "shield": 2, "cell": Vector2i(7, 1)},
	{"name": "Gobelin B", "job": "Gobelin", "color": Color(0.75, 0.25, 0.25), "hp": 30, "atk": 11, "def": 5,
		"move": 4, "jump": 2, "range": 1, "speed": 8, "type": "griffe",
		"weaknesses": ["feu", "lance"], "shield": 2, "cell": Vector2i(6, 3)},
	{"name": "Loup", "job": "Bête", "color": Color(0.5, 0.5, 0.55), "hp": 26, "atk": 12, "def": 4,
		"move": 5, "jump": 3, "range": 1, "speed": 12, "type": "griffe",
		"weaknesses": ["arc", "épée"], "shield": 2, "cell": Vector2i(8, 3)},
	{"name": "Sorcier", "job": "Gobelin mage", "color": Color(0.6, 0.2, 0.45), "hp": 24, "atk": 15, "def": 3,
		"move": 3, "jump": 1, "range": 3, "speed": 9, "type": "feu",
		"weaknesses": ["épée", "arc"], "shield": 1, "cell": Vector2i(9, 0)},
	{"name": "Golem", "job": "Golem", "color": Color(0.45, 0.4, 0.35), "hp": 60, "atk": 14, "def": 12,
		"move": 2, "jump": 1, "range": 1, "speed": 5, "type": "poing",
		"weaknesses": ["lance", "feu"], "shield": 4, "cell": Vector2i(8, 1)},
]

enum State { BUSY, CHOOSE_ACTION, CHOOSE_MOVE, CHOOSE_TARGET, GAME_OVER }

var heights: Array = []
var map_size := Vector2i.ZERO
var origin := Vector2(640, 170)
var units: Array[Unit] = []
var active: Unit
var state: State = State.BUSY
## Case -> couleur de surbrillance.
var highlighted: Dictionary = {}
## Case -> case précédente, pour reconstruire le chemin de déplacement.
var move_parents: Dictionary = {}
var hover_cell := Vector2i(-1, -1)
## Textes flottants : {text, pos, age, color, size}
var popups: Array = []
var time := 0.0
## Lancer avec `-- --autoplay` : l'IA joue aussi le groupe (test rapide).
## Ajouter `--full-party` pour tester avec Kael, Mira et l'épée.
var autoplay := false

var info_label: Label
var order_label: RichTextLabel
var log_label: Label
var menu_panel: PanelContainer
var btn_move: Button
var btn_attack: Button
var btn_wait: Button
var end_panel: PanelContainer
var end_label: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.09, 0.1, 0.16))
	autoplay = "--autoplay" in OS.get_cmdline_user_args()
	if autoplay:
		Engine.time_scale = 8.0
	if "--full-party" in OS.get_cmdline_user_args():
		for f in ["kael_recrute", "mira_recrutee", "epee_obtenue"]:
			GameState.set_flag(f)
	for row in MAP_ROWS:
		var r: Array[int] = []
		for ch in row:
			r.append(int(ch))
		heights.append(r)
	map_size = Vector2i(MAP_ROWS[0].length(), MAP_ROWS.size())
	_spawn_units()
	_build_ui()
	_log("Les gobelins attaquent ! Frappe leurs faiblesses pour les briser.")
	_start_next_turn()


func _spawn_units() -> void:
	for unit_name in GameState.party_names():
		var data: Dictionary = PLAYER_UNITS[unit_name].duplicate()
		data["name"] = unit_name
		data["team"] = Unit.Team.PLAYER
		units.append(Unit.create(data))
	if GameState.has_flag("epee_obtenue"):
		units[0].atk += 4
	for data in ENEMY_UNITS:
		var d := data.duplicate()
		d["team"] = Unit.Team.ENEMY
		units.append(Unit.create(d))
	for u in units:
		u.draw_pos = cell_to_screen(u.cell)
		u.ct = u.speed * 3


# --- Grille ---------------------------------------------------------------

func height(c: Vector2i) -> int:
	return heights[c.y][c.x]


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < map_size.x and c.y < map_size.y


func cell_to_screen(c: Vector2i) -> Vector2:
	return origin + Vector2((c.x - c.y) * TILE_W / 2.0, (c.x + c.y) * TILE_H / 2.0 - height(c) * STEP_H)


func _top_poly(c: Vector2i) -> PackedVector2Array:
	var top := cell_to_screen(c)
	return PackedVector2Array([
		top + Vector2(0, -TILE_H / 2.0), top + Vector2(TILE_W / 2.0, 0),
		top + Vector2(0, TILE_H / 2.0), top + Vector2(-TILE_W / 2.0, 0),
	])


func screen_to_cell(p: Vector2) -> Vector2i:
	# Parcours de l'avant vers l'arrière : la case visible au premier plan gagne.
	for s in range(map_size.x + map_size.y - 2, -1, -1):
		for x in range(map_size.x - 1, -1, -1):
			var c := Vector2i(x, s - x)
			if in_bounds(c) and Geometry2D.is_point_in_polygon(p, _top_poly(c)):
				return c
	return Vector2i(-1, -1)


func unit_at(c: Vector2i) -> Unit:
	for u in units:
		if u.is_alive() and u.cell == c:
			return u
	return null


## Cases atteignables (parcours en largeur avec contrainte de saut).
func reachable(u: Unit) -> Array[Vector2i]:
	move_parents = {}
	var dist := {u.cell: 0}
	var queue: Array[Vector2i] = [u.cell]
	var result: Array[Vector2i] = []
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		var d: int = dist[c]
		if c != u.cell and unit_at(c) == null:
			result.append(c)
		if d >= u.move:
			continue
		for dir in DIRS:
			var n := c + dir
			if not in_bounds(n) or dist.has(n):
				continue
			if absi(height(n) - height(c)) > u.jump:
				continue
			var other := unit_at(n)
			if other != null and other.team != u.team:
				continue
			dist[n] = d + 1
			move_parents[n] = c
			queue.append(n)
	return result


func attack_cells(u: Unit, from: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in map_size.y:
		for x in map_size.x:
			var c := Vector2i(x, y)
			var d := absi(c.x - from.x) + absi(c.y - from.y)
			if d < 1 or d > u.attack_range:
				continue
			# Corps à corps impossible sur une falaise trop haute.
			if u.attack_range == 1 and absi(height(c) - height(from)) > 2:
				continue
			result.append(c)
	return result


func targets_from(u: Unit, from: Vector2i) -> Array[Unit]:
	var result: Array[Unit] = []
	for c in attack_cells(u, from):
		var t := unit_at(c)
		if t != null and t.team != u.team:
			result.append(t)
	return result


# --- Tours ----------------------------------------------------------------

func _advance_ct() -> Unit:
	while true:
		var best: Unit = null
		for u in units:
			if u.is_alive() and u.ct >= 100 and (best == null or u.ct > best.ct):
				best = u
		if best != null:
			return best
		for u in units:
			if u.is_alive():
				u.ct += u.speed
	return null


func _predict_order(count: int) -> Array[Unit]:
	var cts := {}
	for u in units:
		if u.is_alive():
			cts[u] = u.ct
	var order: Array[Unit] = []
	while order.size() < count:
		var best: Unit = null
		for u in cts:
			if cts[u] >= 100 and (best == null or cts[u] > cts[best]):
				best = u
		if best != null:
			order.append(best)
			cts[best] -= 100
		else:
			for u in cts:
				cts[u] += u.speed
	return order


func _start_next_turn() -> void:
	if _check_end():
		return
	active = _advance_ct()
	active.has_moved = false
	active.has_acted = false
	_update_order()
	_update_info(active)

	if active.is_broken():
		state = State.BUSY
		_update_menu()
		_popup(active.draw_pos + Vector2(0, -70), "Brisé...", Color(1, 0.6, 0.3), 16)
		_log("%s est brisé et passe son tour." % active.unit_name)
		active.broken_turns -= 1
		if not active.is_broken():
			active.shield = active.max_shield
		active.has_moved = true
		active.has_acted = true
		await get_tree().create_timer(0.8).timeout
		_end_turn()
		return

	if active.team == Unit.Team.PLAYER and not autoplay:
		state = State.CHOOSE_ACTION
		_log("Tour de %s." % active.unit_name)
	else:
		state = State.BUSY
		_run_ai()
	_update_menu()


func _end_turn() -> void:
	# Comme dans FFT : attendre sans agir fait revenir plus vite.
	var cost := 60
	if active.has_moved:
		cost += 20
	if active.has_acted:
		cost += 20
	active.ct -= cost
	_clear_highlight()
	_start_next_turn()


func _after_player_action() -> void:
	if _check_end():
		return
	if active.has_moved and active.has_acted:
		_end_turn()
	else:
		state = State.CHOOSE_ACTION
		_update_menu()


func _check_end() -> bool:
	if state == State.GAME_OVER:
		return true
	var players := units.any(func(u): return u.is_alive() and u.team == Unit.Team.PLAYER)
	var enemies := units.any(func(u): return u.is_alive() and u.team == Unit.Team.ENEMY)
	if players and enemies:
		return false
	state = State.GAME_OVER
	_clear_highlight()
	_update_menu()
	if players:
		# Conséquences de la victoire sur le village.
		var reward := 20 if GameState.has_flag("paye_avance") else 50
		GameState.gold += reward
		GameState.change_reputation(20)
		GameState.change_opinion("chef", 20)
		GameState.set_flag("gobelins_vaincus")
		end_label.text = "Victoire !\n+%d or · Réputation +20" % reward
	else:
		GameState.change_reputation(-10)
		end_label.text = "Défaite...\nRéputation -10"
	end_panel.show()
	if autoplay:
		print("RÉSULTAT : ", "victoire" if players else "défaite")
		get_tree().quit()
	return true


# --- Actions --------------------------------------------------------------

func _walk(u: Unit, dest: Vector2i) -> void:
	var path: Array[Vector2i] = []
	var c := dest
	while move_parents.has(c):
		path.push_front(c)
		c = move_parents[c]
	for step in path:
		u.cell = step
		var tw := create_tween()
		tw.tween_property(u, "draw_pos", cell_to_screen(step), 0.12)
		await tw.finished
	u.has_moved = true


func _perform_attack(att: Unit, target: Unit) -> void:
	var base := att.draw_pos
	var dir := (target.draw_pos - base).normalized()
	var tw := create_tween()
	tw.tween_property(att, "draw_pos", base + dir * 12, 0.08)
	tw.tween_property(att, "draw_pos", base, 0.1)
	await tw.finished

	var dmg := maxf(1.0, att.atk - target.defense * 0.5)
	# Bonus de hauteur : frapper d'en haut fait plus mal.
	dmg *= 1.0 + clampi(height(att.cell) - height(target.cell), -3, 3) * 0.1
	dmg *= randf_range(0.9, 1.1)
	var weak := target.weaknesses.has(att.damage_type)
	var broke := false
	if weak:
		dmg *= 1.3
		if not target.is_broken() and target.shield > 0:
			target.shield -= 1
			if target.shield == 0:
				target.broken_turns = 1
				broke = true
	if target.is_broken() and not broke:
		dmg *= 2.0
	var amount := maxi(1, roundi(dmg))
	target.hp = maxi(0, target.hp - amount)
	att.has_acted = true

	var head := target.draw_pos + Vector2(0, -50)
	_popup(head, str(amount), Color(1, 0.9, 0.3) if weak else Color.WHITE, 22)
	var msg := "%s attaque %s : %d dégâts." % [att.unit_name, target.unit_name, amount]
	if weak:
		_popup(head + Vector2(0, -22), "Faiblesse !", Color(0.5, 0.9, 1), 14)
	if broke:
		_popup(head + Vector2(0, -42), "BREAK !", Color(1, 0.55, 0.15), 26)
		msg += " BREAK !"
	if not target.is_alive():
		_popup(head + Vector2(0, -20), "K.O.", Color(1, 0.3, 0.3), 20)
		msg += " %s est vaincu." % target.unit_name
	_log(msg)

	var shake := create_tween()
	var p := target.draw_pos
	shake.tween_property(target, "draw_pos", p + Vector2(4, 0), 0.04)
	shake.tween_property(target, "draw_pos", p + Vector2(-4, 0), 0.04)
	shake.tween_property(target, "draw_pos", p, 0.04)
	await shake.finished
	_update_order()


func _run_ai() -> void:
	var u := active
	await get_tree().create_timer(0.5).timeout
	var targets := targets_from(u, u.cell)
	if targets.is_empty():
		var best_cell := u.cell
		var best_score := _distance_to_foe(u, u.cell)
		for c in reachable(u):
			var ts := targets_from(u, c)
			# Préférer une case d'où l'on peut frapper la cible la plus faible.
			var score := _distance_to_foe(u, c)
			if not ts.is_empty():
				score = -1000.0 + _weakest(ts).hp
			if score < best_score:
				best_score = score
				best_cell = c
		if best_cell != u.cell:
			await _walk(u, best_cell)
		targets = targets_from(u, u.cell)
	if not targets.is_empty():
		await get_tree().create_timer(0.2).timeout
		await _perform_attack(u, _pick_target(u, targets))
	if _check_end():
		return
	_end_turn()


func _pick_target(u: Unit, targets: Array[Unit]) -> Unit:
	# Viser d'abord une faiblesse, sinon la cible la plus faible.
	for t in targets:
		if t.weaknesses.has(u.damage_type):
			return t
	return _weakest(targets)


func _weakest(list: Array[Unit]) -> Unit:
	var best: Unit = list[0]
	for t in list:
		if t.hp < best.hp:
			best = t
	return best


func _distance_to_foe(u: Unit, from: Vector2i) -> float:
	var best := INF
	for o in units:
		if o.is_alive() and o.team != u.team:
			best = minf(best, absi(o.cell.x - from.x) + absi(o.cell.y - from.y))
	return best


# --- Entrées --------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover_cell = screen_to_cell(get_local_mouse_position())
		var hovered := unit_at(hover_cell)
		_update_info(hovered if hovered != null else active)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_cell_clicked(screen_to_cell(get_local_mouse_position()))
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel()
	elif event.is_action_pressed("ui_cancel"):
		_cancel()


func _on_cell_clicked(c: Vector2i) -> void:
	if not highlighted.has(c):
		return
	match state:
		State.CHOOSE_MOVE:
			if unit_at(c) == null:
				state = State.BUSY
				_clear_highlight()
				_update_menu()
				await _walk(active, c)
				_after_player_action()
		State.CHOOSE_TARGET:
			var t := unit_at(c)
			if t != null and t.team != active.team:
				state = State.BUSY
				_clear_highlight()
				_update_menu()
				await _perform_attack(active, t)
				_after_player_action()


func _cancel() -> void:
	if state == State.CHOOSE_MOVE or state == State.CHOOSE_TARGET:
		state = State.CHOOSE_ACTION
		_clear_highlight()


func _on_move_pressed() -> void:
	state = State.CHOOSE_MOVE
	_set_highlight(reachable(active), Color(0.3, 0.6, 1.0))


func _on_attack_pressed() -> void:
	state = State.CHOOSE_TARGET
	_set_highlight(attack_cells(active, active.cell), Color(1.0, 0.3, 0.3))


func _on_wait_pressed() -> void:
	state = State.BUSY
	_update_menu()
	_end_turn()


func _set_highlight(cells: Array[Vector2i], color: Color) -> void:
	highlighted = {}
	for c in cells:
		highlighted[c] = color


func _clear_highlight() -> void:
	highlighted = {}


# --- Interface ------------------------------------------------------------

func _panel(pos: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = pos
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.1, 0.88)
	sb.border_color = Color(0.85, 0.72, 0.42)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var info_panel := _panel(Vector2(16, 16))
	layer.add_child(info_panel)
	info_label = Label.new()
	info_label.custom_minimum_size = Vector2(300, 0)
	info_panel.add_child(info_label)

	var order_panel := _panel(Vector2(1074, 16))
	layer.add_child(order_panel)
	order_label = RichTextLabel.new()
	order_label.bbcode_enabled = true
	order_label.fit_content = true
	order_label.custom_minimum_size = Vector2(170, 0)
	order_panel.add_child(order_label)

	menu_panel = _panel(Vector2(16, 540))
	layer.add_child(menu_panel)
	var vb := VBoxContainer.new()
	menu_panel.add_child(vb)
	btn_move = _menu_button(vb, "Déplacer", _on_move_pressed)
	btn_attack = _menu_button(vb, "Attaquer", _on_attack_pressed)
	btn_wait = _menu_button(vb, "Attendre", _on_wait_pressed)

	var log_panel := _panel(Vector2(260, 650))
	layer.add_child(log_panel)
	log_label = Label.new()
	log_label.custom_minimum_size = Vector2(760, 0)
	log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_panel.add_child(log_label)

	var help := Label.new()
	help.text = "Clic gauche : choisir · Clic droit / Échap : annuler"
	help.position = Vector2(470, 16)
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	layer.add_child(help)

	end_panel = _panel(Vector2(470, 260))
	layer.add_child(end_panel)
	var end_box := VBoxContainer.new()
	end_box.custom_minimum_size = Vector2(320, 0)
	end_panel.add_child(end_box)
	end_label = Label.new()
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.add_theme_font_size_override("font_size", 28)
	end_box.add_child(end_label)
	var back := Button.new()
	back.text = "Retour au village"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/village.tscn"))
	end_box.add_child(back)
	end_panel.hide()


func _menu_button(parent: Control, label: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(160, 36)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


func _update_menu() -> void:
	var player_turn := active != null and active.team == Unit.Team.PLAYER and not autoplay
	menu_panel.visible = player_turn and state in [State.CHOOSE_ACTION, State.CHOOSE_MOVE, State.CHOOSE_TARGET]
	if active != null:
		btn_move.disabled = active.has_moved
		btn_attack.disabled = active.has_acted


func _update_info(u: Unit) -> void:
	if u == null:
		info_label.text = ""
		return
	var t := "%s — %s\n" % [u.unit_name, u.job]
	t += "PV %d/%d   ATQ %d   DÉF %d\n" % [u.hp, u.max_hp, u.atk, u.defense]
	t += "Dépl. %d   Saut %d   Portée %d   Vit. %d\n" % [u.move, u.jump, u.attack_range, u.speed]
	t += "Attaque : %s" % u.damage_type
	if u.max_shield > 0:
		t += "\nFaiblesses : %s" % ", ".join(PackedStringArray(u.weaknesses))
		t += "\nBouclier : %d/%d%s" % [u.shield, u.max_shield, "  (BRISÉ)" if u.is_broken() else ""]
	info_label.text = t


func _update_order() -> void:
	var t := "[b]Ordre des tours[/b]\n"
	var first := true
	for u in _predict_order(8):
		var col := "#8fbaff" if u.team == Unit.Team.PLAYER else "#ff8f8f"
		t += "%s[color=%s]%s[/color]\n" % ["▶ " if first else "    ", col, u.unit_name]
		first = false
	order_label.text = t


func _log(msg: String) -> void:
	log_label.text = msg


func _popup(pos: Vector2, text: String, color: Color, size: int) -> void:
	popups.append({"text": text, "pos": pos, "age": 0.0, "color": color, "size": size})


# --- Dessin ---------------------------------------------------------------

func _process(delta: float) -> void:
	time += delta
	for p in popups:
		p["age"] += delta
	popups = popups.filter(func(p): return p["age"] < 1.2)
	queue_redraw()


func _draw() -> void:
	for s in map_size.x + map_size.y - 1:
		for x in map_size.x:
			var c := Vector2i(x, s - x)
			if in_bounds(c):
				_draw_tile(c)
		for u in units:
			if u.is_alive() and u.cell.x + u.cell.y == s:
				_draw_unit(u)
	for p in popups:
		var c: Color = p["color"]
		c.a = clampf(1.2 - p["age"], 0.0, 1.0)
		_text(p["pos"] + Vector2(0, -p["age"] * 30.0), p["text"], p["size"], c)


func _draw_tile(c: Vector2i) -> void:
	var top := cell_to_screen(c)
	var h := height(c)
	var down := Vector2(0, h * STEP_H + BASE_DEPTH)
	var n := top + Vector2(0, -TILE_H / 2.0)
	var e := top + Vector2(TILE_W / 2.0, 0)
	var s := top + Vector2(0, TILE_H / 2.0)
	var w := top + Vector2(-TILE_W / 2.0, 0)
	draw_colored_polygon(PackedVector2Array([w, s, s + down, w + down]), Color(0.42, 0.31, 0.2))
	draw_colored_polygon(PackedVector2Array([s, e, e + down, s + down]), Color(0.3, 0.22, 0.14))
	var grass := Color(0.34, 0.58, 0.3).lightened(h * 0.07)
	if (c.x + c.y) % 2 == 0:
		grass = grass.darkened(0.06)
	var poly := PackedVector2Array([n, e, s, w])
	draw_colored_polygon(poly, grass)
	if highlighted.has(c):
		var hc: Color = highlighted[c]
		hc.a = 0.35 + 0.12 * sin(time * 5.0)
		draw_colored_polygon(poly, hc)
	var outline := PackedVector2Array([n, e, s, w, n])
	draw_polyline(outline, Color(0, 0, 0, 0.25), 1.0)
	if c == hover_cell:
		draw_polyline(outline, Color.WHITE, 2.0)


func _draw_unit(u: Unit) -> void:
	var p := u.draw_pos
	var big := 1.4 if u.job == "Golem" else 1.0
	draw_set_transform(p + Vector2(0, 2), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 14 * big, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)

	var body := u.color.darkened(0.45) if u.is_broken() else u.color
	var body_rect := Rect2(p + Vector2(-9, -30) * big, Vector2(18, 26) * big)
	draw_rect(body_rect, body)
	draw_rect(body_rect, Color(0, 0, 0, 0.6), false, 1.5)
	var head_col := Color(0.96, 0.82, 0.68) if u.team == Unit.Team.PLAYER else u.color.lightened(0.25)
	var head := p + Vector2(0, -38 * big)
	draw_circle(head, 8 * big, head_col)
	if u.team == Unit.Team.ENEMY:
		draw_circle(head + Vector2(-3, -1), 1.6, Color(1, 0.9, 0.2))
		draw_circle(head + Vector2(3, -1), 1.6, Color(1, 0.9, 0.2))

	match u.damage_type:
		"épée":
			draw_line(p + Vector2(9, -14), p + Vector2(20, -34), Color(0.85, 0.85, 0.92), 3)
		"lance":
			draw_line(p + Vector2(12, -2), p + Vector2(16, -52), Color(0.6, 0.45, 0.28), 2)
			draw_colored_polygon(PackedVector2Array([p + Vector2(13, -52), p + Vector2(19, -52), p + Vector2(16, -60)]), Color(0.85, 0.85, 0.92))
		"arc":
			draw_arc(p + Vector2(12, -20), 12, -PI / 2, PI / 2, 12, Color(0.55, 0.38, 0.2), 2)
		"feu":
			draw_line(p + Vector2(12, -2), p + Vector2(12, -44), Color(0.5, 0.35, 0.2), 2)
			draw_circle(p + Vector2(12, -46), 4 + sin(time * 8.0), Color(1, 0.5, 0.15))

	# Barre de PV
	var bar := Rect2(p + Vector2(-16, -56 * big), Vector2(32, 4))
	draw_rect(bar, Color(0.1, 0.1, 0.1))
	var ratio := float(u.hp) / u.max_hp
	var bar_col := Color(0.35, 0.85, 0.4) if u.team == Unit.Team.PLAYER else Color(0.9, 0.3, 0.3)
	draw_rect(Rect2(bar.position, Vector2(32 * ratio, 4)), bar_col)

	# Bouclier (Break) des ennemis
	if u.max_shield > 0:
		var sp := p + Vector2(24, -50 * big)
		if u.is_broken():
			_text(sp + Vector2(4, 0), "BREAK", 11, Color(1, 0.55, 0.15))
		else:
			draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -8), sp + Vector2(7, 0), sp + Vector2(0, 8), sp + Vector2(-7, 0)]), Color(0.65, 0.7, 0.8))
			_text(sp + Vector2(0, 4), str(u.shield), 11, Color.BLACK, false)

	if u == active and state != State.GAME_OVER:
		var a := p + Vector2(0, -70 * big + sin(time * 5.0) * 3.0)
		draw_colored_polygon(PackedVector2Array([a + Vector2(-6, -8), a + Vector2(6, -8), a]), Color(1, 0.9, 0.3))


func _text(center: Vector2, text: String, size: int, color: Color, outline := true) -> void:
	var font := ThemeDB.fallback_font
	var w := 160.0
	var pos := center - Vector2(w / 2.0, 0)
	if outline:
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, size, 4, Color(0, 0, 0, color.a))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, size, color)
