class_name CardPicker
extends CanvasLayer
## Tela de escolha de cartas ao subir de nível. Pausa o jogo enquanto está aberta.
## Visual próprio (moldura simples colorida pela raridade), sem copiar o Magic.

signal finished

var _row: HBoxContainer
var _title: Label
var _pick_left := 0
var _on_pick: Callable


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("card_picker")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 24)
	add_child(center)
	_title = UITheme.title("", 34)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_title)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 20)
	center.add_child(_row)
	visible = false


## cards: lista de dicionários da carta; pick: quantas escolher; on_pick(card) é chamado a cada escolha.
func open(cards: Array, pick: int, on_pick: Callable) -> void:
	_pick_left = mini(pick, cards.size())
	_on_pick = on_pick
	for c in _row.get_children():
		c.queue_free()
	for card in cards:
		_row.add_child(_make_card(card))
	_update_title()
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Game.smoke_test:
		for i in _pick_left:
			_choose.call_deferred(cards[i], null)


func _update_title() -> void:
	_title.text = "Escolha %d carta%s" % [_pick_left, "s" if _pick_left > 1 else ""]


func _make_card(card: Dictionary) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(250, 358)
	var cv := CardView.make(card, ClassData.for_class(Game.class_id), 250.0)
	holder.add_child(cv)
	var btn := Button.new()
	btn.flat = true
	btn.size = Vector2(250, 358)
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(st, empty)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1, 1, 1, 0.06)
	hover.border_color = UITheme.GOLD_LIGHT
	hover.set_border_width_all(4)
	hover.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("hover", hover)
	btn.mouse_entered.connect(func() -> void: cv.scale = Vector2(1.04, 1.04))
	btn.mouse_exited.connect(func() -> void: cv.scale = Vector2.ONE)
	holder.add_child(btn)
	btn.pressed.connect(func() -> void: _choose(card, btn))
	return holder


func _text(t: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _choose(card: Dictionary, btn: Button) -> void:
	if _pick_left <= 0:
		return
	_pick_left -= 1
	if btn:
		btn.disabled = true
		btn.get_parent().modulate = Color(1, 1, 1, 0.3)
	_on_pick.call(card)
	if _pick_left <= 0:
		visible = false
		get_tree().paused = false
		finished.emit()
	else:
		_update_title()
