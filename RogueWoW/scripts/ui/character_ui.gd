class_name CharacterUI
extends CanvasLayer
## Janela do personagem (tecla I), estilo WoW: equipamento dos dois lados, o personagem em 3D
## girando no meio, atributos embaixo e uma aba com o deck de cartas da classe.

var player: Player
var editable := true
var _panel: PanelContainer
var _box: VBoxContainer
var _tab := "char"
var _preview_pivot: Node3D


func _ready() -> void:
	layer = 16
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("ui_window")
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_panel.offset_left = 30
	_panel.offset_right = 30 + 780
	_panel.offset_top = -350
	_panel.offset_bottom = 350
	add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	_panel.add_child(_box)
	_panel.visible = false


func is_open() -> bool:
	return _panel.visible


func open() -> void:
	refresh()
	_panel.visible = true
	UIWin.sync_lock(get_tree())


func close() -> void:
	_panel.visible = false
	Game.tooltip.hide_tip()
	UIWin.sync_lock(get_tree())


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and not get_tree().paused:
		toggle()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _panel.visible and _preview_pivot:
		_preview_pivot.rotation.y += delta * 0.6


func refresh() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	_preview_pivot = null
	var cls := ClassData.for_class(Game.class_id)
	var rc := ClassData.race(Game.race)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var portrait := UITheme.icon_slot(Game.icon(cls["icon"]), 54, UITheme.GOLD)
	head.add_child(portrait)
	var names := VBoxContainer.new()
	names.add_child(UITheme.title(Game.char_name, 26))
	names.add_child(UITheme.text("%s · Poder de Armadura %d" % [cls["name"], Game.armor_power()], 17, Color(1, 0.85, 0.45)))
	head.add_child(names)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var x := Button.new()
	x.text = "X"
	x.pressed.connect(close)
	head.add_child(x)
	_box.add_child(head)

	var tabs := HBoxContainer.new()
	for t in [["char", "Personagem"], ["cards", "Cartas (%d)" % cls["deck"].size()]]:
		var b := Button.new()
		b.text = t[1]
		b.toggle_mode = true
		b.button_pressed = _tab == t[0]
		var tab_id: String = t[0]
		b.pressed.connect(func() -> void:
			_tab = tab_id
			refresh())
		tabs.add_child(b)
	_box.add_child(tabs)

	if _tab == "cards":
		_build_cards(cls)
	else:
		_build_char(cls)


func _build_char(cls: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(row)
	row.add_child(_slot_column(["head", "shoulders", "back"]))
	row.add_child(_preview(cls))
	row.add_child(_slot_column(["chest", "hands", "feet"]))

	# Arma da classe (fixa por enquanto)
	var weapon := HBoxContainer.new()
	weapon.alignment = BoxContainer.ALIGNMENT_CENTER
	var ws := UITheme.icon_slot(Game.icon(cls["abilities"]["basic"]["icon"]), 52, UITheme.GOLD)
	Tooltip.attach(ws, "[font_size=20]Arma de %s[/font_size]\n%s" % [cls["name"], cls["desc"]])
	weapon.add_child(ws)
	weapon.add_child(UITheme.text("  Arma da classe — " + cls["abilities"]["basic"]["name"], 16, Color(0.85, 0.85, 0.85)))
	_box.add_child(weapon)

	# Atributos
	var pa := Game.armor_power()
	var stats := GridContainer.new()
	stats.columns = 4
	stats.add_theme_constant_override("h_separation", 26)
	var max_hp := float(cls["hp"]) + 2.0 * pa
	var dmg := 1.0 + 0.01 * pa
	var lines := [
		["Vida máxima", "%d" % max_hp], ["Dano", "+%d%%" % roundi((dmg - 1.0) * 100.0)],
		["Poder de Armadura", "%d" % pa], ["Velocidade", "%.0f m/s" % Player.WALK_SPEED],
	]
	if player and not editable:
		lines.append(["Nível na partida", "%d" % player.level])
		lines.append(["Vida atual", "%d / %d" % [ceili(player.hp), ceili(player.max_hp)]])
	for l in lines:
		stats.add_child(UITheme.text(l[0], 16, Color(1, 0.85, 0.45)))
		stats.add_child(UITheme.text(l[1], 16, Color.WHITE))
	_box.add_child(stats)
	if not editable:
		_box.add_child(UITheme.text("Durante a partida o equipamento fica travado. Troque na cidade.", 14, Color(0.7, 0.7, 0.7), true))


func _slot_column(slots: Array) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	for slot in slots:
		var id: String = Game.equipment.get(slot, "")
		var r := Game.recipe(id)
		var border := UIWin.rarity_color(Game.gear_rarity(r)) if not r.is_empty() else Color(0.35, 0.3, 0.25)
		var s := UITheme.icon_slot(Game.icon(Game.SLOT_ICONS[slot]), 70, border)
		if r.is_empty():
			s.modulate = Color(0.45, 0.45, 0.45)
			Tooltip.attach(s, "[font_size=20]%s[/font_size]\n[color=#999999]Vazio — forje uma peça no Ferreiro[/color]" % Game.SLOT_NAMES[slot])
		else:
			Tooltip.attach(s, UIWin.gear_tip(id, "Clique para tirar" if editable else ""))
			if editable:
				var slot_id: String = slot
				s.gui_input.connect(func(ev: InputEvent) -> void:
					if ev is InputEventMouseButton and ev.pressed:
						Game.unequip(slot_id)
						Game.tooltip.hide_tip()
						_refresh_all())
		var cap := UITheme.text(Game.SLOT_NAMES[slot], 13, Color(0.8, 0.75, 0.6))
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(s)
		col.add_child(cap)
	return col


## Personagem em 3D numa janelinha (SubViewport com mundo próprio).
func _preview(cls: Dictionary) -> Control:
	var r := Preview3D.make(Game.class_id, Game.race, Vector2i(300, 330), Game.sex)
	_preview_pivot = r["pivot"]
	return r["control"]


func _build_cards(cls: Dictionary) -> void:
	_box.add_child(UITheme.text("Seu deck tem 10 cartas. Nos níveis 3 e 6 da partida, elas são embaralhadas e você escolhe 2 e depois 1.", 15, Color(0.85, 0.85, 0.85), true))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(740, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	for card in cls["deck"]:
		var cv := CardView.make(card, cls, 136.0)
		if player and card["id"] in player.chosen_cards:
			cv.modulate = Color(1.15, 1.1, 0.8)
		grid.add_child(cv)


func _refresh_all() -> void:
	refresh()
	for w in get_tree().get_nodes_in_group("ui_window"):
		if w != self and w.has_method("refresh") and w.call("is_open"):
			w.call("refresh")
