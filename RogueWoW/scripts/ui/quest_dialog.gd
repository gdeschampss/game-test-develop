class_name QuestDialog
extends CanvasLayer
## Janela de missão em pergaminho (estilo MMO clássico): texto do NPC, objetivos, recompensas,
## Aceitar/Recusar ou Concluir. Também serve para falas simples do NPC.

var _panel: PanelContainer
var _box: VBoxContainer
var _on_ok: Callable


func _ready() -> void:
	layer = 17
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("ui_window")
	_panel = PanelContainer.new()
	var st := StyleBoxTexture.new()
	st.texture = load("res://assets/ui/parchment.png")
	st.content_margin_left = 28
	st.content_margin_right = 28
	st.content_margin_top = 22
	st.content_margin_bottom = 22
	_panel.add_theme_stylebox_override("panel", st)
	_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_panel.offset_left = 40
	_panel.offset_right = 40 + 440
	_panel.offset_top = -300
	_panel.offset_bottom = 300
	add_child(_panel)
	var border := Panel.new()
	var bs := StyleBoxFlat.new()
	bs.draw_center = false
	bs.border_color = Color(0.45, 0.3, 0.12)
	bs.set_border_width_all(5)
	bs.set_corner_radius_all(4)
	border.add_theme_stylebox_override("panel", bs)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(border)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	_panel.add_child(_box)
	_panel.visible = false


func is_open() -> bool:
	return _panel.visible


func close() -> void:
	_panel.visible = false
	UIWin.sync_lock(get_tree())


func _ink(text: String, size := 17, color := Color(0.18, 0.12, 0.06)) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 380
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	return l


func _title(text: String, size := 26) -> Label:
	var l := _ink(text, size, Color(0.35, 0.12, 0.05))
	l.add_theme_font_override("font", UITheme.title_font())
	return l


## mode: "offer" (Aceitar/Recusar), "complete" (Concluir), "progress" ou "talk" (só Fechar)
func show_quest(npc_name: String, quest: Dictionary, mode: String, progress_text: String, on_ok: Callable) -> void:
	_on_ok = on_ok
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	_box.add_child(_ink(npc_name, 15, Color(0.4, 0.25, 0.1)))
	_box.add_child(_title(quest.get("title", npc_name)))
	_box.add_child(_ink(quest.get("text", "")))
	if mode != "talk":
		_box.add_child(_title("Objetivos", 20))
		_box.add_child(_ink(progress_text))
		_box.add_child(_title("Recompensas", 20))
		var rew := HBoxContainer.new()
		rew.add_theme_constant_override("separation", 10)
		var g := UITheme.icon_slot(Game.icon("gold"), 44, Color(0.5, 0.35, 0.15))
		rew.add_child(g)
		var reward: float = Game.diff()["reward"]
		rew.add_child(_ink("%d de ouro   ·   %d de experiência" % [roundi(int(quest.get("gold", 0)) * reward), roundi(int(quest.get("xp", 0)) * reward)], 16))
		_box.add_child(rew)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	match mode:
		"offer":
			_btn(buttons, "Aceitar", true)
			_btn(buttons, "Recusar", false)
		"complete":
			_btn(buttons, "Concluir missão", true)
		_:
			_btn(buttons, "Fechar", false)
	_box.add_child(buttons)
	_panel.visible = true
	UIWin.sync_lock(get_tree())
	if Game.smoke_test:
		_choose(mode == "offer" or mode == "complete")


func _btn(parent: Control, text: String, ok: bool) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(150, 40)
	b.pressed.connect(func() -> void: _choose(ok))
	parent.add_child(b)


func _choose(ok: bool) -> void:
	close()
	if ok and _on_ok.is_valid():
		_on_ok.call()
