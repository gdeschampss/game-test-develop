class_name QuestLog
extends CanvasLayer
## Diário de missões (tecla L): missões ativas com objetivos e progresso reais do mapa.

var _panel: PanelContainer
var _box: VBoxContainer


func _ready() -> void:
	layer = 16
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("ui_window")
	_panel = PanelContainer.new()
	var st := StyleBoxTexture.new()
	st.texture = load("res://assets/ui/parchment.png")
	st.content_margin_left = 26
	st.content_margin_right = 26
	st.content_margin_top = 20
	st.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", st)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -260
	_panel.offset_right = 260
	_panel.offset_top = -300
	_panel.offset_bottom = 300
	add_child(_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_box)
	_panel.visible = false


func is_open() -> bool:
	return _panel.visible


func open() -> void:
	refresh()
	_panel.visible = true
	UIWin.sync_lock(get_tree())


func close() -> void:
	_panel.visible = false
	UIWin.sync_lock(get_tree())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quest_log") and not get_tree().paused:
		if is_open():
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func refresh() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var t := Label.new()
	t.text = "Diário de Missões"
	t.add_theme_font_override("font", UITheme.title_font())
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", Color(0.35, 0.12, 0.05))
	t.add_theme_constant_override("outline_size", 0)
	_box.add_child(t)
	var provider := get_tree().get_first_node_in_group("quest_provider")
	var entries: Array = provider.call("quest_entries") if provider else []
	if entries.is_empty():
		_box.add_child(_ink("Nenhuma missão ativa. Fale com os NPCs marcados com \"!\" no mapa."))
	for e in entries:
		_box.add_child(_ink(e["title"], 20, Color(0.45, 0.15, 0.05)))
		_box.add_child(_ink(e["text"], 15))
		_box.add_child(_ink("— " + e["progress"], 16, Color(0.1, 0.3, 0.1)))
	var b := Button.new()
	b.text = "Fechar (L)"
	b.pressed.connect(close)
	_box.add_child(b)


func _ink(text: String, size := 16, color := Color(0.18, 0.12, 0.06)) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 440
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	return l
