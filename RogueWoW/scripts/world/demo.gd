extends Node3D
## Etapa 2 da direção de arte — cena de demonstração "Clareira do Bandido".
## Pequeno ambiente medieval para validar o visual clássico antes de padronizar o jogo:
## chão pintado (PSX), céu panorâmico, neblina colorida, árvores/tocos/troncos do pacote,
## grama e flores, casa, adereços, 1 NPC com missão, bandidos anões, cavalo e HUD completa.
## Abrir: menu "Cena de demonstração" ou `godot -- --demo-scene`. Não salva nada.

# Texturas pintadas à mão (512 px) — chão "meio antigo, meio novo"
const GRASS := "res://assets/textures/ground_hp/grass_soft.png"
const SHORT_GRASS := "res://assets/textures/ground_hp/grass_mix.png"
const EARTH := "res://assets/textures/ground_hp/dirt.png"
const GRAVEL := "res://assets/textures/ground_hp/forest_floor.png"

const SPAWN := Vector3(0, 1, 22)
const HOUSE := Vector3(-14, 0, -6)
const CAMP := Vector3(10, 0, -22)
const NPC_POS := Vector3(-7, 0, 4)
const HALF := 70.0

const BANDIT := {"name": "Puglin Saqueador", "level": [3, 4], "hp": 60, "dmg": 7, "speed": 4.6, "xp": 6, "gold": [3, 6],
	"mat": "pele_lobo", "mat_chance": 0.6, "color": Color(0.5, 0.3, 0.25), "size": 1.0,
	"rig": "puglin", "weapon": "weapons/w_dwarven_war_axe", "model_h": 1.1}
const GHOUL := {"name": "Carniçal", "level": [5, 6], "hp": 55, "dmg": 9, "speed": 4.2, "xp": 5, "gold": [2, 5], "mat": "osso_carnical", "mat_chance": 0.45,
	"color": Color(0.45, 0.55, 0.3), "size": 1.0, "rig": "monster04", "model_h": 2.0}
const SKELETON := {"name": "Esqueleto Guerreiro", "level": [5, 6], "hp": 70, "dmg": 9, "speed": 4.6, "xp": 6, "gold": [2, 5], "mat": "fragmento_sombrio", "mat_chance": 0.5,
	"color": Color(0.85, 0.82, 0.7), "size": 1.0, "rig": "skeleton", "weapon": "weapons/w_falchion", "model_h": 1.9}
const IMP := {"name": "Diabrete", "level": [5, 6], "hp": 50, "dmg": 10, "speed": 5.0, "xp": 6, "gold": [2, 5], "mat": "fragmento_sombrio", "mat_chance": 0.5,
	"color": Color(0.35, 0.15, 0.45), "size": 1.0, "rig": "imp", "model_h": 1.6}
const WOLF := {"name": "Lobo Faminto", "level": [3, 4], "hp": 30, "dmg": 6, "speed": 5.2, "xp": 3, "gold": [1, 3], "mat": "pele_lobo", "mat_chance": 0.5,
	"color": Color(0.45, 0.4, 0.35), "size": 0.9, "rig": "wolf", "model_h": 1.1}
const QUEST := {"id": "bandidos", "title": "Saqueadores na clareira", "giver": "Guarda Aldric", "type": "kill", "target": "Puglin Saqueador", "count": 3, "gold": 25, "xp": 15,
	"text": "Uns puglins montaram acampamento ali na clareira, perto da fogueira. Já roubaram duas carroças esta semana. Expulse três deles e eu te pago do meu bolso."}

var rng := RandomNumberGenerator.new()
var player: Player
var hud: Hud
var quest_dialog: QuestDialog
var _quest := {"status": "available", "progress": 0}
var _npc_mark: Label3D
var _respawn_t := 0.0
var _smoke_t := 0.0


func _ready() -> void:
	rng.seed = 2004
	for n in Build.classic_environment(Color(0.66, 0.74, 0.82), 0.012):
		add_child(n)
	_build_ground()
	_build_trees()
	_build_vegetation()
	_build_house()
	_build_camp()
	_add_npc()

	player = Player.new()
	add_child(player)
	player.global_position = SPAWN
	player.cam_yaw = 0.0
	player.leveled_up.connect(func(lv: int) -> void: Game.show_toast("Nível %d!" % lv))
	player.died.connect(func() -> void:
		Game.show_toast("Você caiu. Voltando para a seleção de personagem...")
		get_tree().create_timer(3.0).timeout.connect(Game.go_to_character_select))

	hud = Hud.new()
	hud.player = player
	add_child(hud)
	hud.minimap.provider = _markers
	hud.minimap.lines = [[Vector3(0, 0, 60), Vector3(0, 0, 0)], [Vector3(0, 0, 0), CAMP]]
	var cui := CharacterUI.new()
	cui.player = player
	cui.editable = true
	add_child(cui)
	var bag := BagUI.new()
	bag.player = player
	bag.editable = true
	add_child(bag)
	var menu := GameMenu.new()
	menu.in_run = false
	add_child(menu)
	quest_dialog = QuestDialog.new()
	add_child(quest_dialog)
	var ql := QuestLog.new()
	add_child(ql)
	add_to_group("quest_provider")

	for i in 3:
		_spawn_bandit()
	# Vitrine dos mobs novos: um carniçal e um esqueleto vagando perto das ruínas a oeste
	for data in [GHOUL, SKELETON, IMP, WOLF]:
		var e := Enemy.new().setup(data, Game.diff()["hp"], Game.diff()["dmg"])
		add_child(e)
		e.global_position = Vector3(-30 + rng.randf_range(-4, 4), 0.2, -22 + rng.randf_range(-4, 4))
	# Ferramentas de print: --demo-view=camp|house, --demo-ui (abre personagem + bolsa)
	for a in OS.get_cmdline_user_args():
		if a == "--demo-view=camp":
			player.global_position = CAMP + Vector3(-3, 1, 14)
			player.cam_yaw = atan2(3.0, 14.0) * -1.0
		elif a == "--demo-view=mobs":
			player.global_position = Vector3(-22, 1, -6)
			player.cam_yaw = atan2(6.0, 12.0)
		elif a == "--demo-view=house":
			player.global_position = HOUSE + Vector3(8, 1, 12)
			player.cam_yaw = atan2(8.0, 12.0)
		elif a == "--demo-fight":
			# ferramenta de print: atira na direção do acampamento sem parar
			player.global_position = CAMP + Vector3(-2, 1, 12)
			player.cam_yaw = atan2(2.0, 12.0)
			player.max_hp = 99999.0
			player.hp = 99999.0
			var t := Timer.new()
			t.wait_time = 0.35
			t.autostart = true
			t.timeout.connect(func() -> void:
				player.res = player.res_max
				player.cooldowns["basic"] = 0.0
				player.try_ability("basic"))
			add_child(t)
		elif a == "--demo-mount":
			player.global_position = HOUSE + Vector3(10, 1, 14)
			player.cam_yaw = 0.9
			player._set_mounted(true)
		elif a == "--demo-ui":
			cui.open.call_deferred()
			bag.open.call_deferred()
	_refresh_quest()
	Game.log_event("Bem-vindo à Clareira do Bandido (cena de demonstração).", Game.LOG_SYSTEM)
	Game.show_toast("Cena de demonstração — nada aqui é salvo. ESC abre o menu.")


# --- Ambiente ------------------------------------------------------------------------

func _build_ground() -> void:
	add_child(Build.textured_ground(Vector3(HALF * 2 + 40, 1, HALF * 2 + 40), Vector3(0, -0.5, 0), GRASS, 5.0))
	add_child(Build.ground_patch(Vector2(30, 26), Vector3(0, 0, -4), 0.0, SHORT_GRASS, 4.0))
	# Estrada de terra do sul até o centro e depois para o acampamento
	add_child(Build.ground_patch(Vector2(4, 64), Vector3(0, 0.01, 30), 0.0, EARTH, 4.0))
	var d := CAMP - Vector3.ZERO
	add_child(Build.ground_patch(Vector2(4, d.length() + 4), d / 2.0 + Vector3(0, 0.01, 0), atan2(d.x, d.z), EARTH, 3.0))
	add_child(Build.ground_patch(Vector2(13, 13), CAMP + Vector3(0, 0.015, 0), 0.4, GRAVEL, 4.0))
	add_child(Build.ground_patch(Vector2(10, 9), HOUSE + Vector3(4, 0.015, 3), 0.0, EARTH, 3.0))
	# Bordas invisíveis
	for s in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var size := Vector3(2, 10, HALF * 2) if s.x != 0 else Vector3(HALF * 2, 10, 2)
		var wall := Build.static_box(size, Color.WHITE, s * HALF + Vector3(0, 5, 0))
		wall.get_child(0).visible = false
		add_child(wall)


func _clear(p: Vector3) -> bool:
	if absf(p.x) < 5.0 and p.z > -2.0:  # estrada
		return false
	if Geometry3D.get_closest_point_to_segment(p, Vector3.ZERO, CAMP).distance_to(p) < 4.0:
		return false
	return p.distance_to(HOUSE) > 12.0 and p.distance_to(CAMP) > 9.0 and p.distance_to(Vector3(-30, 0, -22)) > 7.0 and p.distance_to(NPC_POS) > 4.0 and p.distance_to(SPAWN) > 5.0


func _build_trees() -> void:
	var trees := ["env/fp_pine_1", "env/fp_pine_2", "env/fp_spruce_1", "env/fp_spruce_2", "env/fp_spruce_3", "env/psx_tree1", "env/fp_pine_1", "env/fp_spruce_1"]
	# Anel denso de floresta em volta da clareira + algumas árvores soltas dentro
	var placed := 0
	var tries := 0
	while placed < 150 and tries < 900:
		tries += 1
		var ang := rng.randf() * TAU
		var r := rng.randf_range(24.0, HALF - 2.0) if placed > 18 else rng.randf_range(12.0, 30.0)
		var p := Vector3(cos(ang) * r, 0, sin(ang) * r)
		if absf(p.x) > HALF - 2 or absf(p.z) > HALF - 2 or not _clear(p):
			continue
		var id: String = trees[rng.randi() % trees.size()]
		var h := rng.randf_range(7.0, 12.0) if id.begins_with("env/fp") else rng.randf_range(5.0, 8.0)
		var t := Build.prop(id, p, h, rng, 0.45)
		if t:
			add_child(t)
			placed += 1
	var smalls := [["env/fp_stump_1", 0.7, 0.5], ["env/fp_stump_2", 0.6, 0.5], ["env/fp_log_4", -2.2, 0.0], ["env/snow_old_woodlog", -3.0, 0.0],
		["env/psx_treetrunk", 1.0, 0.9], ["env/psx_rock", 1.1, 0.7], ["env/fp_fern", 0.9, 0.0], ["env/fp_blueberrybush", 0.7, 0.0],
		["env/fp_mushroom_1", 0.35, 0.0], ["env/fp_bracketfungus", 0.4, 0.0]]
	for i in 70:
		var p := Vector3(rng.randf_range(-HALF + 4, HALF - 4), 0, rng.randf_range(-HALF + 4, HALF - 4))
		if not _clear(p):
			continue
		var s: Array = smalls[rng.randi() % smalls.size()]
		var h := float(s[1])  # negativo = medir pelo comprimento (troncos deitados)
		var o := Build.prop(s[0], p, absf(h) * rng.randf_range(0.8, 1.3), rng, float(s[2]), h < 0.0)
		if o:
			add_child(o)


func _build_vegetation() -> void:
	var avoid := func(p: Vector3) -> bool: return not _clear(p) and p.distance_to(HOUSE) > 7.0
	for spec in [["env/psx_grass", 2600, 0.55], ["env/psx_dandelion", 260, 0.4], ["env/psx_lavender", 160, 0.5]]:
		var mm := Build.scatter_model(spec[0], Vector3.ZERO, HALF - 3, spec[1], spec[2], rng, avoid)
		if mm:
			add_child(mm)


func _build_house() -> void:
	var h := Build.prop("house", HOUSE, 7.5, rng, 0.0)
	if h:
		h.rotation.y = 0.35
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(7, 6, 7)
		cs.shape = box
		cs.position.y = 3
		h.add_child(cs)
		add_child(h)
	for spec in [["props/Barrel", HOUSE + Vector3(5.5, 0, 3.0), 1.0], ["props/Barrel_Apples", HOUSE + Vector3(6.5, 0, 4.2), 1.0], ["props/Crate_Wooden", HOUSE + Vector3(4.6, 0, 5.4), 0.8],
			["props/Bench", HOUSE + Vector3(1.5, 0, 6.0), 0.55], ["props/Stall_Cart_Empty", HOUSE + Vector3(9.5, 0, 0.0), 2.4], ["props/FarmCrate_Apple", HOUSE + Vector3(9.0, 0, 2.2), 0.5],
			["props/Banner_1", HOUSE + Vector3(-4.0, 0, 4.5), 3.2], ["props/Dummy", HOUSE + Vector3(-7.0, 0, 9.0), 1.8], ["props/WeaponStand", HOUSE + Vector3(-5.0, 0, 7.5), 1.4],
			["env/snow_old_woodlog", HOUSE + Vector3(-2.5, 0, 9.5), -2.4]]:
		var o := Build.prop(spec[0], spec[1], absf(spec[2]), rng, 0.4 if spec[2] > 0 else 0.0, spec[2] < 0)
		if o:
			add_child(o)


func _build_camp() -> void:
	var fire := Build.prop("dungeon/Brazier", CAMP, 1.1, rng, 0.5)
	if fire:
		add_child(fire)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.25)
	light.light_energy = 2.0
	light.omni_range = 9.0
	light.position = CAMP + Vector3(0, 1.6, 0)
	add_child(light)
	FX.burst(self, CAMP + Vector3(0, 1.2, 0), Color(1.0, 0.55, 0.2), 1, 0.1, 0.1, 0.1)
	for i in 4:
		var ang := float(i) / 4.0 * TAU + 0.3
		var p := CAMP + Vector3(cos(ang), 0, sin(ang)) * 3.2
		var log := Build.prop("env/fp_log_4" if i % 2 == 0 else "env/snow_old_woodlog", p, 2.4, rng, 0.0, true)
		if log:
			log.rotation.y = -ang
			add_child(log)
	for spec in [["props/Crate_Wooden", CAMP + Vector3(4.5, 0, -2.5), 0.9], ["props/Cauldron", CAMP + Vector3(-1.2, 0, 1.6), 0.8], ["props/Chest_Wood", CAMP + Vector3(3.6, 0, -4.2), 0.7],
			["props/Barrel", CAMP + Vector3(-4.6, 0, -2.6), 1.0],
			["props/Bag", CAMP + Vector3(-3.4, 0, -3.6), 0.45], ["props/Coin_Pile", CAMP + Vector3(3.0, 0, -3.0), 0.25]]:
		var o := Build.prop(spec[0], spec[1], spec[2], rng, 0.4)
		if o:
			add_child(o)


func _add_npc() -> void:
	var npc := Interactable.new()
	npc.prompt = "Falar com " + QUEST["giver"]
	npc.position = NPC_POS
	npc.rotation.y = PI * 0.15
	npc.add_child(NpcLook.make(QUEST["giver"]))
	_npc_mark = Build.label("!", Vector3(0, 3.0, 0), Color(1, 0.85, 0.1), 120)
	npc.add_child(_npc_mark)
	npc.add_child(Build.label(QUEST["giver"], Vector3(0, 2.2, 0), Color(0.6, 1, 0.6), 32))
	npc.set_meta("mark", _npc_mark)
	npc.on_interact = func(_p: Player) -> void: _talk()
	add_child(npc)


# --- Mobs e missão ---------------------------------------------------------------------

func _spawn_bandit() -> void:
	var e := Enemy.new().setup(BANDIT, Game.diff()["hp"], Game.diff()["dmg"])
	e.killed.connect(_on_killed)
	add_child(e)
	var ang := rng.randf() * TAU
	e.global_position = CAMP + Vector3(cos(ang), 0, sin(ang)) * rng.randf_range(4.5, 8.0) + Vector3(0, 0.2, 0)


func _on_killed(_e: Enemy) -> void:
	if _quest["status"] == "active":
		_quest["progress"] = mini(_quest["progress"] + 1, QUEST["count"])
	_respawn_t = 12.0
	_refresh_quest()


func _talk() -> void:
	match _quest["status"]:
		"available":
			quest_dialog.show_quest(QUEST["giver"], QUEST, "offer", "Derrote 3 Puglins Saqueadores", func() -> void:
				_quest["status"] = "active"
				Game.log_event("Missão aceita: %s." % QUEST["title"], Game.LOG_QUEST)
				_refresh_quest())
		"active":
			if _quest["progress"] >= QUEST["count"]:
				quest_dialog.show_quest(QUEST["giver"], QUEST, "complete", _line(), func() -> void:
					_quest["status"] = "done"
					player.add_xp(QUEST["xp"])
					player.run_gold += QUEST["gold"]
					Game.log_event("Missão concluída: %s. +%d de ouro." % [QUEST["title"], QUEST["gold"]], Game.LOG_QUEST)
					_refresh_quest())
			else:
				quest_dialog.show_quest(QUEST["giver"], QUEST, "progress", _line(), Callable())
		_:
			quest_dialog.show_quest(QUEST["giver"], {"title": QUEST["giver"], "text": "A estrada está mais tranquila graças a você."}, "talk", "", Callable())


func _line() -> String:
	return "%s: %d/%d" % [QUEST["target"], _quest["progress"], QUEST["count"]]


func _refresh_quest() -> void:
	match _quest["status"]:
		"available":
			_npc_mark.text = "!"
		"active":
			_npc_mark.text = "?" if _quest["progress"] >= QUEST["count"] else ""
		_:
			_npc_mark.text = ""
	var lines: Array[String] = []
	if _quest["status"] == "active":
		var back := " — volte para %s" % QUEST["giver"] if _quest["progress"] >= QUEST["count"] else ""
		lines.append("• %s (%d/%d)%s" % [QUEST["title"], _quest["progress"], QUEST["count"], back])
	if hud:
		hud.quest_lines = lines


func quest_entries() -> Array:
	var out: Array = []
	if _quest["status"] == "active":
		out.append({"title": QUEST["title"], "text": QUEST["text"], "progress": _line()})
	return out


func _markers() -> Array:
	var out: Array = [{"pos": CAMP, "color": Color(0.9, 0.3, 0.2), "shape": "dot"}]
	if _npc_mark.text != "":
		out.append({"pos": NPC_POS, "color": Color(1, 0.85, 0.1), "shape": "text", "text": _npc_mark.text, "edge": true})
	else:
		out.append({"pos": NPC_POS, "color": Color(0.6, 1, 0.6), "shape": "dot"})
	return out


func _process(delta: float) -> void:
	hud.minimap.zone_name = "Clareira do Bandido (nv 3-4)"
	if _respawn_t > 0.0:
		_respawn_t -= delta
		if _respawn_t <= 0.0 and get_tree().get_nodes_in_group("enemies").size() < 3:
			_spawn_bandit()
	if Game.smoke_test:
		_smoke_t += delta
		if _smoke_t > 1.0 and _quest["status"] == "available":
			_talk()
		if _smoke_t > 2.0 and _smoke_t < 2.1:
			player.global_position = CAMP + Vector3(0, 1, 6)
		if _smoke_t > 8.0:
			print("SMOKE demo ok enemies=", get_tree().get_nodes_in_group("enemies").size(), " quest=", _quest["status"])
			get_tree().quit()
