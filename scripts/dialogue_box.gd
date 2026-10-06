extends CanvasLayer
## Boîte de dialogue : texte progressif, choix, et affichage de
## l'attitude du PNJ (qui évolue en direct selon tes réponses).

signal closed

const CHARS_PER_SEC := 70.0

var npc_id := ""
var panel: PanelContainer
var name_label: Label
var mood_label: Label
var text_label: Label
var choices_box: VBoxContainer
var typing: Tween
var current_node: Dictionary = {}


func _ready() -> void:
	layer = 10
	panel = PanelContainer.new()
	panel.position = Vector2(140, 450)
	panel.custom_minimum_size = Vector2(1000, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.12, 0.94)
	sb.border_color = Color(0.85, 0.72, 0.42)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", sb)
	panel.gui_input.connect(_on_panel_input)
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var header := HBoxContainer.new()
	vb.add_child(header)
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	header.add_child(name_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	mood_label = Label.new()
	header.add_child(mood_label)

	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(970, 60)
	text_label.add_theme_font_size_override("font_size", 18)
	vb.add_child(text_label)

	choices_box = VBoxContainer.new()
	vb.add_child(choices_box)

	GameState.opinion_changed.connect(func(_id, _d): _update_header())
	GameState.reputation_changed.connect(func(_d): _update_header())
	visible = false


func is_open() -> bool:
	return visible


func open(id: String) -> void:
	npc_id = id
	visible = true
	_show(Dialogues.entry_node(id))


func close() -> void:
	visible = false
	closed.emit()


func _show(node_id: String) -> void:
	current_node = Dialogues.DATA[npc_id]["nodes"][node_id]
	for child in choices_box.get_children():
		child.queue_free()
	text_label.text = Dialogues.resolve_text(current_node["text"], npc_id)
	GameState.apply_effects(current_node.get("effects", {}), npc_id)
	_update_header()

	text_label.visible_ratio = 0.0
	typing = create_tween()
	typing.tween_property(text_label, "visible_ratio", 1.0, text_label.text.length() / CHARS_PER_SEC)
	typing.finished.connect(_show_choices)


func _skip_typing() -> void:
	if typing and typing.is_running():
		typing.kill()
		text_label.visible_ratio = 1.0
		_show_choices()


func _show_choices() -> void:
	var first: Button = null
	for choice in current_node.get("choices", []):
		if not GameState.check(choice.get("if", {}), npc_id):
			continue
		var label: String = choice["text"]
		if choice.has("roll"):
			label += "  (%d%% de réussite)" % roundi(choice["roll"]["chance"] * 100)
		var b := _add_button("▸ " + label, _on_choice.bind(choice))
		if first == null:
			first = b
	if first == null:
		if current_node.has("next"):
			first = _add_button("Continuer ▸", _show.bind(current_node["next"]))
		else:
			first = _add_button("Fin", close)
	first.grab_focus()


func _add_button(label: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 32)
	b.pressed.connect(callback)
	choices_box.add_child(b)
	return b


func _on_choice(choice: Dictionary) -> void:
	if choice.has("roll"):
		var roll: Dictionary = choice["roll"]
		_show(roll["success"] if randf() < roll["chance"] else roll["fail"])
	else:
		_show(choice["next"])


func _update_header() -> void:
	if npc_id == "":
		return
	name_label.text = Dialogues.DATA[npc_id]["name"]
	var p := GameState.perception(npc_id)
	mood_label.text = "Attitude : %s (%+d)" % [GameState.attitude_name(p), p]
	mood_label.add_theme_color_override("font_color", GameState.attitude_color(p))


func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_skip_typing()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_E):
		_skip_typing()
		get_viewport().set_input_as_handled()
