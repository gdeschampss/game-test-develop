extends Node3D
## Cidade-hub (substitui o menu principal). Praça central, ruas, prédios placeholder,
## Mestre dos Portais (nova partida / continuar partida pausada), loja e baú pessoal.

const HALF := 60.0  ## cidade de 120 x 120 m

var player: Player
var hud: Hud
var _panel: PanelContainer
var _panel_box: VBoxContainer
var character_ui: CharacterUI
var bag_ui: BagUI


func _ready() -> void:
	for n in Build.classic_environment(Color(0.7, 0.78, 0.86), 0.004):
		add_child(n)
	add_child(Build.textured_ground(Vector3(HALF * 2, 1, HALF * 2), Vector3(0, -0.5, 0), "res://assets/textures/ground_hp/grass_soft.png", 5.0))
	var hub_rng := RandomNumberGenerator.new()
	add_child(Build.scatter(Vector3.ZERO, HALF - 3.0, 900, Color(0.38, 0.6, 0.24), hub_rng, 0.5, func(p: Vector3) -> bool: return absf(p.x) < 18 or absf(p.z) < 18 or (absf(p.x) < 6) or (absf(p.z) < 6)))
	# Praça e ruas de pedra
	for spec in [[Vector2(30, 30), Vector3.ZERO], [Vector2(8, HALF * 2), Vector3.ZERO], [Vector2(HALF * 2, 8), Vector3.ZERO]]:
		add_child(Build.ground_patch(spec[0], spec[1], 0.0, "res://assets/textures/ground_hp/dirt.png", 4.0))
	_build_walls_and_buildings()

	add_child(Build.label("Cidadela de Pedraforte", Vector3(0, 12, -20), Color(1, 0.85, 0.5), 160))
	_add_portal_master()
	_add_simple_npc("Mercadora Lirien", Vector3(-12, 0, 4), "Loja", func(_p: Player) -> void:
		_open_menu(_fill_shop))
	_add_simple_npc("Baú pessoal", Vector3(12, 0, 4), "Ver baú pessoal", func(_p: Player) -> void:
		_open_menu(_fill_stash))
	_add_simple_npc("Ferreiro Dunmar", Vector3(-30, 0, -8), "Ferreiro", func(_p: Player) -> void:
		_open_menu(_fill_smith))
	_add_simple_npc("Mestra de Cartas Ysolde", Vector3(30, 0, -8), "Cartas", func(_p: Player) -> void:
		Game.show_toast("Ysolde: \"Seu deck de %s tem 10 cartas. Elas aparecem embaralhadas nos níveis 3 e 6 da partida.\"" % ClassData.for_class(Game.class_id)["name"]))
	_add_simple_npc("Pedra do Destino", Vector3(0, 0, 30), "Trocar de personagem", func(_p: Player) -> void:
		Game.go_to_character_select())

	player = Player.new()
	add_child(player)
	player.global_position = Vector3(0, 1, 18)

	hud = Hud.new()
	hud.player = player
	hud.show_combat = false
	add_child(hud)
	_build_panel()
	hud.minimap.zone_name = "Cidadela de Pedraforte"
	hud.minimap.provider = _map_markers
	add_to_group("ui_window")
	character_ui = CharacterUI.new()
	character_ui.player = player
	add_child(character_ui)
	bag_ui = BagUI.new()
	bag_ui.player = player
	add_child(bag_ui)
	var menu := GameMenu.new()
	add_child(menu)
	add_child(QuestLog.new())

	if Game.smoke_test:
		if Game.run_paused:
			print("SMOKE hub (pausa): ", Game.last_result)
			Game.resume_run()
		else:
			print("SMOKE hub ok: ", Game.last_result, " gold=", Game.gold, " mats=", Game.materials)
			Game.gold += 100
			Game.materials["pele_lobo"] = 6
			print("SMOKE craft=", Game.craft("capuz_lobo"), " pa=", Game.armor_power(), " potion=", Game.buy_potion(), " potions=", Game.potions)
			_open_menu(_fill_smith)
			_open_menu(_fill_shop)
			_open_menu(_fill_stash)
			_open_menu(_fill_portal_menu)
			Game.unequip("head")
			print("SMOKE unequip pa=", Game.armor_power(), " bag=", Game.bag)
			Game.equip("capuz_lobo")
			print("SMOKE equip pa=", Game.armor_power(), " bag=", Game.bag)
			character_ui.open()
			bag_ui.open()
			character_ui._tab = "cards"
			character_ui.refresh()
			print("SMOKE windows ok any_open=", UIWin.any_open(get_tree()))
			UIWin.close_all(get_tree())
			get_tree().quit()
		return
	for a in OS.get_cmdline_user_args():  # ferramentas de dev para prints
		if a == "--demo-char":
			Game.materials = {"pele_lobo": 12, "crina_flamejante": 3, "presa_alfa": 1, "fragmento_sombrio": 5}
			Game.bag = ["capuz_lobo", "ombreiras_osso"]
			Game.equipment = {"chest": "peitoral_yeti", "feet": "botas_alfa", "back": "manto_flamejante"}
			Game.potions = 3
			Game.gold = 340
			character_ui.open.call_deferred()
			bag_ui.open.call_deferred()
		if a == "--demo-cards-tab":
			character_ui._tab = "cards"
			character_ui.open.call_deferred()
	if "--demo-smith" in OS.get_cmdline_user_args():  # ferramenta de dev
		Game.gold = 130
		Game.materials = {"pele_lobo": 9, "osso_carnical": 3, "presa_alfa": 1}
		_open_menu.call_deferred(_fill_smith)
	if Game.last_result != "":
		Game.show_toast.call_deferred(Game.last_result)
		Game.last_result = ""
	elif Game.run_paused:
		Game.show_toast.call_deferred("Você tem uma partida pausada. Fale com o Mestre dos Portais para continuar.")
	else:
		Game.show_toast.call_deferred("Fale com o Mestre dos Portais (E) para começar uma partida")


func _build_walls_and_buildings() -> void:
	var stone := Color(0.42, 0.38, 0.34)
	add_child(Build.static_box(Vector3(HALF * 2, 9, 2), stone, Vector3(0, 4.5, -HALF)))
	add_child(Build.static_box(Vector3(HALF * 2, 9, 2), stone, Vector3(0, 4.5, HALF)))
	add_child(Build.static_box(Vector3(2, 9, HALF * 2), stone, Vector3(-HALF, 4.5, 0)))
	add_child(Build.static_box(Vector3(2, 9, HALF * 2), stone, Vector3(HALF, 4.5, 0)))
	var spots := [
		Vector3(-24, 0, -30), Vector3(24, 0, -30), Vector3(-42, 0, -30), Vector3(42, 0, -30),
		Vector3(-24, 0, 26), Vector3(24, 0, 26), Vector3(-42, 0, 26), Vector3(42, 0, 26),
		Vector3(-42, 0, -2), Vector3(42, 0, -2),
	]
	var hrng := RandomNumberGenerator.new()
	hrng.seed = 1234
	var styles := ["plaster", "brick", "wood", "plaster"]
	for i in spots.size():
		var sp: Vector3 = spots[i]
		var house := Village.build_house(3 + hrng.randi() % 2, 4, 2 if i % 3 != 2 else 1, styles[i % styles.size()], hrng)
		house.position = sp
		# a porta vira para a praça
		house.rotation.y = PI if sp.z > 10 else (0.0 if sp.z < -10 else (PI / 2.0 if sp.x < 0 else -PI / 2.0))
		add_child(house)
	_build_town_props()


## Props da cidade (Fantasy Props MegaKit): bancas de mercado, barris, bigorna, estandartes, tochas.
func _build_town_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var props := [
		["props/Stall_Empty", Vector3(-11, 0, 9), 3.0, PI / 2], ["props/Stall_Cart_Empty", Vector3(11, 0, 9), 2.4, -PI / 2],
		["props/Barrel", Vector3(-12.5, 0, 12), 1.0, 0.0], ["props/Barrel_Apples", Vector3(-12, 0, 6.5), 1.0, 0.0], ["props/FarmCrate_Carrot", Vector3(12.5, 0, 12), 0.5, 0.0],
		["props/Crate_Wooden", Vector3(13, 0, 6), 0.9, 0.3], ["props/Anvil", Vector3(-27, 0, -10), 0.9, 0.0], ["props/Workbench", Vector3(-33.5, 0, -11), 1.1, PI / 2],
		["props/WeaponStand", Vector3(-27, 0, -4.5), 1.5, PI / 2], ["props/Whetstone", Vector3(-33, 0, -5), 0.9, 0.0],
		["props/Banner_1", Vector3(-6, 0, -14.5), 4.0, 0.0], ["props/Banner_2", Vector3(6, 0, -14.5), 4.0, 0.0],
		
		
		["props/Bench", Vector3(-8, 0, 0), 0.55, PI / 2], ["props/Bench", Vector3(8, 0, 0), 0.55, -PI / 2],
		["props/Cauldron", Vector3(27, 0, -11), 0.8, 0.0], ["props/Chest_Wood", Vector3(14.5, 0, 4), 0.8, -PI / 2], ["props/Shelf_Simple", Vector3(33, 0, -11), 2.0, 0.0],
	]
	for p in props:
		var o := Build.prop(p[0], p[1], p[2], rng, 0.5)
		if o:
			o.rotation.y = p[3]
			add_child(o)


## Casa: modelo 3D (fantasy house) com colisão em caixa; sem o modelo, usa o bloco cinza.
func _house(pos: Vector3) -> Node3D:
	var body := StaticBody3D.new()
	body.position = pos
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(9, 8, 8)
	cs.shape = shape
	cs.position.y = 4
	body.add_child(cs)
	var m := Models.instance("house", 10.0)
	if m:
		m.rotation.y = 0.0 if pos.z < 0 else PI
		body.add_child(m)
	else:
		body.add_child(Build.static_box(Vector3(12, 7, 10), Color(0.75, 0.68, 0.55), Vector3(0, 3.5, 0)))
	return body


func _add_portal_master() -> void:
	var ring := CylinderMesh.new()
	ring.top_radius = 3.5
	ring.bottom_radius = 3.5
	ring.height = 8.0
	var portal := Build.mesh(ring, Color(0.5, 0.4, 1.0), 1.5, 0.35)
	portal.position = Vector3(0, 4, -12)
	add_child(portal)
	_add_simple_npc("Mestre dos Portais", Vector3(0, 0, -6), "Mestre dos Portais", func(_p: Player) -> void:
		_open_menu(_fill_portal_menu))


func _map_markers() -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group("interactable"):
		out.append({"pos": n.global_position, "color": Color(0.6, 1, 0.6), "shape": "dot"})
	out.append({"pos": Vector3(0, 0, -12), "color": Color(0.6, 0.5, 1.0), "shape": "square", "edge": true})
	return out


func _add_simple_npc(npc_name: String, pos: Vector3, prompt: String, action: Callable) -> void:
	var npc := Interactable.new()
	npc.prompt = prompt
	npc.position = pos
	npc.add_child(NpcLook.make(npc_name))
	npc.add_child(Build.label(npc_name, Vector3(0, 2.4, 0), Color(0.6, 1, 0.6), 36))
	npc.on_interact = action
	add_child(npc)


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -300
	_panel.offset_right = 300
	_panel.offset_top = -330
	_panel.offset_bottom = 330
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	_panel_box = VBoxContainer.new()
	_panel_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_panel_box)
	_panel.visible = false
	hud.add_child(_panel)


var _current_fill: Callable


## Abre o painel e preenche com a função dada (refeita a cada compra/craft).
func _open_menu(fill: Callable) -> void:
	_current_fill = fill
	_refresh_menu()
	_panel.visible = true
	player.set_input_locked(true)


func _refresh_menu() -> void:
	for c in _panel_box.get_children():
		_panel_box.remove_child(c)
		c.queue_free()
	_current_fill.call()
	_add_button("Fechar", _close_panel)


func _title(text: String) -> void:
	var title := Label.new()
	title.text = text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 20)
	_panel_box.add_child(title)


func _fill_portal_menu() -> void:
	if Game.run_paused:
		_title("Partida pausada — %s\n(%d pausa(s) restante(s))" % [Game.diff()["name"], Game.pauses_left()])
		_add_button("Continuar partida", func() -> void: Game.resume_run())
		_add_button("Abandonar partida", func() -> void: Game.abandon_run())
		return
	_title("Vale das Três Terras — seu Poder de Armadura: %d" % Game.armor_power())
	for i in Game.DIFFICULTIES.size():
		var d: Dictionary = Game.DIFFICULTIES[i]
		var ok := Game.armor_power() >= int(d["min_pa"])
		var text := "%d. %s  (recompensa x%.1f)" % [i + 1, d["name"], d["reward"]]
		if not ok:
			text = "%d. %s  — precisa de PA %d" % [i + 1, d["name"], d["min_pa"]]
		_add_button(text, func() -> void: Game.start_run(i), not ok)


func _fill_shop() -> void:
	_title("Mercadora Lirien — Ouro: %d" % Game.gold)
	_add_button("Poção de Vida (%d de ouro) — você tem %d/%d" % [Game.POTION_PRICE, Game.potions, Game.POTION_MAX], func() -> void:
		if Game.buy_potion():
			Game.show_toast("Comprou uma Poção de Vida")
		_refresh_menu(), Game.gold < Game.POTION_PRICE or Game.potions >= Game.POTION_MAX)


func _fill_smith() -> void:
	_title("Ferreiro Dunmar — Ouro: %d · PA: %d\nTraga materiais do Vale e eu forjo armaduras." % [Game.gold, Game.armor_power()])
	for r in Game.RECIPES:
		var parts: Array[String] = []
		for m in r["mats"]:
			parts.append("%d/%d %s" % [int(Game.materials.get(m, 0)), r["mats"][m], Game.MATERIALS[m]])
		var equipped: bool = Game.equipment.get(r["slot"], "") == r["id"]
		var text := "%s (%s, +%d PA)\n%d ouro · %s" % [r["name"], Game.SLOT_NAMES[r["slot"]], r["pa"], r["gold"], ", ".join(parts)]
		if equipped:
			text = "✔ " + text
		_add_button(text, func() -> void:
			if Game.craft(r["id"]):
				Game.show_toast("Forjado: %s" % r["name"])
			_refresh_menu(), not Game.can_craft(r))


func _fill_stash() -> void:
	var lines: Array[String] = ["Ouro: %d   ·   Poções: %d   ·   Poder de Armadura: %d" % [Game.gold, Game.potions, Game.armor_power()], ""]
	lines.append("EQUIPAMENTO")
	for slot in Game.SLOT_NAMES:
		var r := Game.recipe(Game.equipment.get(slot, ""))
		lines.append("%s: %s" % [Game.SLOT_NAMES[slot], r.get("name", "—")])
	lines.append("")
	lines.append("MATERIAIS")
	var any := false
	for m in Game.MATERIALS:
		if int(Game.materials.get(m, 0)) > 0:
			lines.append("%s × %d" % [Game.MATERIALS[m], Game.materials[m]])
			any = true
	if not any:
		lines.append("(vazio)")
	lines.append("")
	lines.append("Saídas: %d · Conquistas: %s" % [Game.runs_extracted, ", ".join(Game.achievements) if not Game.achievements.is_empty() else "nenhuma"])
	_title("\n".join(lines))


func _add_button(text: String, action: Callable, disabled := false) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size.y = 44
	btn.disabled = disabled
	btn.pressed.connect(action)
	_panel_box.add_child(btn)


func _close_panel() -> void:
	_panel.visible = false
	UIWin.sync_lock(get_tree())


## A cidade também é uma "janela" (painéis do Mestre dos Portais, loja e ferreiro) para o ESC fechar.
func is_open() -> bool:
	return _panel != null and _panel.visible


func close() -> void:
	_close_panel()
