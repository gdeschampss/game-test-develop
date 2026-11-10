class_name BagUI
extends CanvasLayer
## Mochila (tecla U), estilo WoW: grade de espaços com ícones, pilhas e dicas.
## Na cidade: clique numa peça para equipar. Na partida: mostra também o loot ainda não extraído.

const COLS := 8
const SLOT := 58.0
const MIN_SLOTS := 32

var player: Player
var editable := true
var _panel: PanelContainer
var _box: VBoxContainer


func _ready() -> void:
	layer = 16
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("ui_window")
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	var w := COLS * (SLOT + 6) + 40
	_panel.offset_left = -w - 24
	_panel.offset_right = -24
	_panel.offset_top = -640
	_panel.offset_bottom = -130
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
	Game.tooltip.hide_tip()
	UIWin.sync_lock(get_tree())


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("bag") and not get_tree().paused:
		toggle()
		get_viewport().set_input_as_handled()


func _grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = COLS
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	return g


func refresh() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var head := HBoxContainer.new()
	head.add_child(UITheme.title("Mochila", 24))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var x := Button.new()
	x.text = "X"
	x.pressed.connect(close)
	head.add_child(x)
	_box.add_child(head)

	var grid := _grid()
	_box.add_child(grid)
	var used := 0
	# Peças de armadura na bolsa
	for id in Game.bag.duplicate():
		var r := Game.recipe(id)
		var slot := UITheme.icon_slot(Game.icon(Game.SLOT_ICONS[r["slot"]]), SLOT, UIWin.rarity_color(Game.gear_rarity(r)))
		Tooltip.attach(slot, UIWin.gear_tip(id, "Clique para equipar" if editable else "Troque de equipamento na cidade"))
		if editable:
			slot.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton and ev.pressed:
					Game.equip(id)
					Game.tooltip.hide_tip()
					_refresh_all())
		grid.add_child(slot)
		used += 1
	# Poções
	if Game.potions > 0:
		var ps := UITheme.icon_slot(Game.icon("potion"), SLOT, UIWin.rarity_color("comum"), Game.potions)
		Tooltip.attach(ps, "[font_size=20]Poção de Vida[/font_size]\nCura 50%% da vida (tecla Q)\nQuantidade: %d / %d" % [Game.potions, Game.POTION_MAX])
		grid.add_child(ps)
		used += 1
	# Materiais guardados
	for m in Game.MATERIALS:
		var n := int(Game.materials.get(m, 0))
		if n <= 0:
			continue
		var ms := UITheme.icon_slot(Game.icon(m), SLOT, UIWin.rarity_color(Game.MATERIAL_RARITY.get(m, "comum")), n)
		Tooltip.attach(ms, UIWin.material_tip(m, n))
		grid.add_child(ms)
		used += 1
	for i in maxi(0, MIN_SLOTS - used):
		grid.add_child(UITheme.icon_slot(null, SLOT))

	# Loot da partida (ainda não extraído)
	if player and not editable:
		_box.add_child(UITheme.title("Loot da partida — extraia para guardar", 17, Color(1, 0.55, 0.45)))
		var g2 := _grid()
		_box.add_child(g2)
		if player.run_gold > 0:
			var gs := UITheme.icon_slot(Game.icon("gold"), SLOT, Color(0.9, 0.35, 0.3), player.run_gold)
			Tooltip.attach(gs, "[font_size=20]Ouro da partida[/font_size]\n%d moedas\n[color=#ff7060]Ainda não extraído — perde se morrer[/color]" % player.run_gold)
			g2.add_child(gs)
		for m in player.run_materials:
			var n := int(player.run_materials[m])
			if n <= 0:
				continue
			var rs := UITheme.icon_slot(Game.icon(m), SLOT, Color(0.9, 0.35, 0.3), n)
			Tooltip.attach(rs, UIWin.material_tip(m, n, true))
			g2.add_child(rs)
		if g2.get_child_count() == 0:
			_box.add_child(UITheme.text("(nada ainda)", 15, Color(0.7, 0.7, 0.7)))

	var foot := HBoxContainer.new()
	var coin := TextureRect.new()
	coin.texture = Game.icon("gold")
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.custom_minimum_size = Vector2(28, 28)
	foot.add_child(coin)
	foot.add_child(UITheme.text("  %d de ouro guardado" % Game.gold, 18, Color(1, 0.85, 0.4)))
	_box.add_child(foot)


func _refresh_all() -> void:
	refresh()
	for w in get_tree().get_nodes_in_group("ui_window"):
		if w != self and w.has_method("refresh") and w.call("is_open"):
			w.call("refresh")
