extends Node3D
## Mapa 1 — "Vale das Três Terras" (protótipo cinza, ~440 x 440 m).
## 3 biomas com estradas, mobs com respawn rápido que dropam XP, ouro e materiais,
## 3 bosses (um por bioma) que prendem o jogador, masmorra com chefe, 10 NPCs com missões,
## baús, 2 portais de PAUSA e 1 portal de SAÍDA perto do início.

const BIOME_SIZE := 220.0
const MAP_MIN := Vector2(-110, -330)
const MAP_MAX := Vector2(330, 110)
const SPAWN_POINT := Vector3(0, 1, 80)
const EXIT_PORTAL := Vector3(-22, 0, 95)
const EXTRACT_TIME := 6.0
const PORTAL_RADIUS := 3.0

const WOLF := {"name": "Lobo Faminto", "level": [2, 4], "hp": 30, "dmg": 6, "speed": 5.2, "xp": 3, "gold": [1, 3], "mat": "pele_lobo", "mat_chance": 0.5, "color": Color(0.45, 0.4, 0.35), "size": 0.9,
	"rig": "wolf", "model_h": 1.1}
const GHOUL := {"name": "Carniçal", "level": [5, 7], "hp": 55, "dmg": 9, "speed": 4.2, "xp": 5, "gold": [2, 5], "mat": "osso_carnical", "mat_chance": 0.45, "color": Color(0.45, 0.55, 0.3), "size": 1.0,
	"rig": "monster04", "model_h": 2.0}
const PUGLIN := {"name": "Puglin Saqueador", "level": [3, 5], "hp": 45, "dmg": 7, "speed": 4.6, "xp": 4, "gold": [2, 4], "mat": "pele_lobo", "mat_chance": 0.35,
	"color": Color(0.5, 0.6, 0.3), "size": 0.9, "rig": "puglin", "weapon": "weapons/w_dwarven_war_axe", "model_h": 1.1}
const SWAMP_IMP := {"name": "Diabrete do Brejo", "level": [6, 8], "hp": 60, "dmg": 11, "speed": 5.0, "xp": 6, "gold": [3, 6], "mat": "osso_carnical", "mat_chance": 0.4,
	"color": Color(0.35, 0.15, 0.45), "size": 1.0, "rig": "imp", "model_h": 1.6}
const FROST_SKELETON := {"name": "Esqueleto Congelado", "level": [9, 11], "hp": 100, "dmg": 14, "speed": 4.6, "xp": 8, "gold": [4, 8], "mat": "couro_yeti", "mat_chance": 0.35,
	"color": Color(0.8, 0.9, 1.0), "size": 1.0, "rig": "skeleton", "weapon": "weapons/w_falchion", "model_h": 1.9}
const YETI := {"name": "Yeti", "level": [8, 10], "hp": 95, "dmg": 14, "speed": 4.5, "xp": 8, "gold": [4, 8], "mat": "couro_yeti", "mat_chance": 0.45, "color": Color(0.92, 0.95, 1.0), "size": 1.4}

## Texturas pintadas à mão por bioma (chão).
const BIOME_TEX := {"forest": "res://assets/textures/ground_hp/grass_soft.png", "dead": "res://assets/textures/ground_hp/moss.png",
	"pine": "res://assets/textures/ground/snow2C.png"}
const BIOMES := [
	{"name": "Floresta Sombria", "levels": "2-5", "center": Vector3(0, 0, 0), "ground": Color(0.3, 0.45, 0.2), "deco": "forest", "deco_count": 280, "mob_count": 90, "enemy": WOLF, "extra": [PUGLIN]},
	{"name": "Pântano Pútrido", "levels": "5-9", "center": Vector3(220, 0, 0), "ground": Color(0.28, 0.3, 0.2), "deco": "dead", "deco_count": 190, "mob_count": 80, "enemy": GHOUL, "extra": [SWAMP_IMP]},
	{"name": "Picos Gelados", "levels": "8-12", "center": Vector3(110, 0, -220), "ground": Color(0.85, 0.88, 0.92), "deco": "pine", "deco_count": 190, "mob_count": 70, "enemy": YETI, "extra": [FROST_SKELETON]},
]

## Um boss por bioma, bem longe um do outro.
const BOSSES := [
	{"name": "Ancião da Floresta", "level": [6, 6], "hp": 480, "dmg": 18, "speed": 4.8, "xp": 40, "gold": [60, 90], "color": Color(0.3, 0.45, 0.25), "size": 2.4, "boss": true,
		"model": "treegiant", "model_h": 7.5,
		"drops": {"presa_alfa": 1, "pele_lobo": 3}, "home": Vector3(-80, 1, -85), "achievement": "Lenhador Lendário"},
	{"name": "Dragão do Pântano", "level": [9, 9], "hp": 700, "dmg": 22, "speed": 5.5, "xp": 60, "gold": [90, 130], "color": Color(0.3, 0.5, 0.15), "size": 2.8, "boss": true,
		"model": "swampdragon", "model_h": 5.5,
		"drops": {"coracao_lodo": 1, "osso_carnical": 3}, "home": Vector3(300, 1, -70), "achievement": "Caçador de Dragões"},
	{"name": "Dragão da Montanha", "level": [12, 12], "hp": 950, "dmg": 28, "speed": 5.5, "xp": 80, "gold": [120, 170], "color": Color(0.8, 0.85, 0.95), "size": 3.0, "boss": true,
		"model": "mountaindragon", "model_h": 6.5,
		"drops": {"chifre_anciao": 1, "couro_yeti": 4}, "home": Vector3(200, 1, -300), "achievement": "Matador do Dragão da Montanha"},
]

## Elite da floresta: centauros que andam em grupo e dropam Crina Flamejante.
const CENTAUR := {"name": "Centauro Chama-Viva", "level": [4, 5], "hp": 170, "dmg": 17, "speed": 6.2, "xp": 15, "gold": [8, 14], "mat": "crina_flamejante", "mat_chance": 0.55,
	"color": Color(0.6, 0.3, 0.2), "size": 1.4, "model": "centaur", "model_h": 3.2}
const CENTAUR_COUNT := 10
const RESPAWN_TIME := 25.0  ## segundos até um mob morto renascer

## Masmorra: construída longe do mapa (x = 1000) e acessada por teleporte.
const DUNGEON_ORIGIN := Vector3(1000, 0, 0)
const DUNGEON_ENTRANCE := Vector3(110, 0, -316)
const SKELETON := {"name": "Esqueleto Guerreiro", "level": [10, 11], "hp": 120, "dmg": 16, "speed": 4.8, "xp": 10, "gold": [5, 9], "mat": "fragmento_sombrio", "mat_chance": 0.6, "color": Color(0.85, 0.82, 0.7), "size": 1.1,
	"rig": "skeleton", "weapon": "weapons/w_falchion", "model_h": 1.9}
const ACOLYTE := {"name": "Diabrete da Cripta", "level": [10, 11], "hp": 90, "dmg": 22, "speed": 5.2, "xp": 12, "gold": [6, 10], "mat": "fragmento_sombrio", "mat_chance": 0.6, "color": Color(0.35, 0.15, 0.45), "size": 1.0,
	"rig": "imp", "model_h": 1.6}
const CRYPT_LORD := {"name": "Senhor da Cripta", "level": [13, 13], "hp": 1500, "dmg": 30, "speed": 4.5, "xp": 120, "gold": [200, 300], "color": Color(0.25, 0.1, 0.35), "size": 2.2, "boss": true,
	"model": "devil", "model_h": 5.0,
	"drops": {"coroa_cripta": 1, "fragmento_sombrio": 4}, "achievement": "Purificador da Cripta"}

const PAUSE_CANDIDATES := [Vector3(200, 0, 95), Vector3(315, 0, -95), Vector3(190, 0, -318), Vector3(25, 0, -310), Vector3(-95, 0, -40), Vector3(95, 0, -95), Vector3(-90, 0, 95)]

const ROADS := [
	[Vector3(0, 0, 100), Vector3(0, 0, 0)],
	[Vector3(0, 0, 0), Vector3(220, 0, 0)],
	[Vector3(0, 0, 0), Vector3(110, 0, -220)],
	[Vector3(110, 0, -220), Vector3(110, 0, -312)],
	[Vector3(220, 0, 0), Vector3(300, 0, -70)],
	[Vector3(110, 0, -220), Vector3(200, 0, -300)],
	[Vector3(0, 0, 0), Vector3(-80, 0, -85)],
]

## NPCs e missões. type: kill (matar X), collect (entregar materiais), boss, deliver (levar item a outro NPC).
const NPCS := {
	"Batedora Elandra": Vector3(7, 0, 76),
	"Mensageiro Pip": Vector3(-9, 0, 74),
	"Ermitão do Bosque": Vector3(-60, 0, -30),
	"Caçador Toren": Vector3(-40, 0, -62),
	"Alquimista Vosk": Vector3(180, 0, 40),
	"Bruxa do Brejo": Vector3(262, 0, 30),
	"Sentinela Haldor": Vector3(250, 0, -48),
	"Anão Brumgar": Vector3(92, 0, -160),
	"Guardiã Selvira": Vector3(170, 0, -268),
	"Monge Oradin": Vector3(98, 0, -305),
}
const QUESTS := [
	{"id": "lobos", "text": "Os lobos famintos estão atacando quem passa pela estrada do vale. Meus batedores não dão conta sozinhos. Dê um jeito neles, aventureiro.", "giver": "Batedora Elandra", "title": "Matilha na estrada", "type": "kill", "target": "Lobo Faminto", "count": 8, "gold": 40, "xp": 20},
	{"id": "centauros", "text": "Centauros de crina em chamas cruzam a floresta a leste. Eles queimam tudo por onde passam. Reduza o bando antes que o fogo chegue às árvores antigas.", "giver": "Ermitão do Bosque", "title": "Cavaleiros em chamas", "type": "kill", "target": "Centauro Chama-Viva", "count": 4, "gold": 90, "xp": 35},
	{"id": "carta", "text": "Esta carta precisa chegar ao Alquimista Vosk, no Pântano Pútrido. Não abra, não perca e, pelo amor da Luz, não molhe.", "giver": "Mensageiro Pip", "turn_in": "Alquimista Vosk", "title": "Carta selada para Vosk", "type": "deliver", "item": "Carta Selada", "count": 1, "gold": 30, "xp": 15},
	{"id": "peles", "text": "O inverno vai ser duro aqui no bosque. Traga peles de lobo e eu costuro agasalhos para os viajantes.", "giver": "Ermitão do Bosque", "title": "Peles para o inverno", "type": "collect", "target": "pele_lobo", "count": 5, "gold": 50, "xp": 20},
	{"id": "alfa", "text": "Uma árvore ancestral despertou com raiva no coração da floresta. Ela esmaga quem chega perto. Acalme-a — para sempre.", "giver": "Caçador Toren", "title": "O Ancião da Floresta", "type": "boss", "target": "Ancião da Floresta", "count": 1, "gold": 120, "xp": 40},
	{"id": "carnicais", "text": "Os carniçais se multiplicam no brejo e roubam meus ingredientes. Limpe o pântano para eu poder trabalhar.", "giver": "Alquimista Vosk", "title": "Limpeza do brejo", "type": "kill", "target": "Carniçal", "count": 10, "gold": 70, "xp": 30},
	{"id": "ossos", "text": "Meu caldeirão pede ossos de carniçal. Muitos. Não pergunte para quê.", "giver": "Bruxa do Brejo", "title": "Ossos para o caldeirão", "type": "collect", "target": "osso_carnical", "count": 6, "gold": 80, "xp": 30},
	{"id": "rei", "text": "Um dragão se instalou no fundo do pântano. Os viajantes somem perto do covil dele. Precisamos de alguém corajoso — ou tolo.", "giver": "Sentinela Haldor", "title": "O Dragão do Pântano", "type": "boss", "target": "Dragão do Pântano", "count": 1, "gold": 200, "xp": 60},
	{"id": "yetis", "text": "Os yetis desceram dos picos e cercam a passagem. Abra caminho para as caravanas.", "giver": "Anão Brumgar", "title": "Fera da neve", "type": "kill", "target": "Yeti", "count": 8, "gold": 110, "xp": 40},
	{"id": "anciao", "text": "O Dragão da Montanha voltou a rondar os picos gelados. Enquanto ele viver, ninguém atravessa a neve em paz.", "giver": "Guardiã Selvira", "title": "O Dragão da Montanha", "type": "boss", "target": "Dragão da Montanha", "count": 1, "gold": 250, "xp": 80},
	{"id": "cripta", "text": "Algo profano acordou na Cripta. Os mortos não descansam e um senhor demoníaco comanda tudo lá embaixo. Purifique aquele lugar.", "giver": "Monge Oradin", "title": "A Cripta Profanada", "type": "boss", "target": "Senhor da Cripta", "count": 1, "gold": 400, "xp": 120},
]

var rng := RandomNumberGenerator.new()
var player: Player
var hud: Hud
var card_picker: CardPicker
var character_ui: CharacterUI
var quest_dialog: QuestDialog
var quest_log: QuestLog
var bag_ui: BagUI
var bosses: Array[Enemy] = []
var in_dungeon := false
var _alive := {}
var _spawn_t := 0.0
var _portals: Array = []
var _extract_t := 0.0
var _wave_cd := 0.0
var _ending := false
var _deck: Array = []
var _card_queue: Array = []
var _boss_warned := false
var _quest_state := {}  ## id -> {"status": "available"/"active"/"done", "progress": int}


func _ready() -> void:
	rng.randomize()
	for n in Build.classic_environment(Color(0.68, 0.76, 0.84), 0.0035):
		add_child(n)
	_build_ground()
	_build_roads()
	_build_decorations()
	_build_rocks()
	_build_points_of_interest()
	_build_dungeon()

	player = Player.new()
	add_child(player)
	player.global_position = SPAWN_POINT
	player.died.connect(_on_player_died)
	player.leveled_up.connect(_on_level_up)

	hud = Hud.new()
	hud.player = player
	add_child(hud)
	card_picker = CardPicker.new()
	card_picker.finished.connect(_next_card_round)
	add_child(card_picker)
	_deck = ClassData.for_class(Game.class_id)["deck"].duplicate()
	character_ui = CharacterUI.new()
	character_ui.player = player
	character_ui.editable = false
	add_child(character_ui)
	bag_ui = BagUI.new()
	bag_ui.player = player
	bag_ui.editable = false
	add_child(bag_ui)
	var menu := GameMenu.new()
	menu.in_run = true
	add_child(menu)
	quest_dialog = QuestDialog.new()
	add_child(quest_dialog)
	quest_log = QuestLog.new()
	add_child(quest_log)
	add_to_group("quest_provider")
	hud.minimap.provider = _map_markers
	hud.minimap.lines = ROADS
	for q in QUESTS:
		_quest_state[q["id"]] = {"status": "available", "progress": 0}

	for i in BIOMES.size():
		_alive[i] = 0
		# matilhas/grupos de 2 a 4, mesma criatura, perto um do outro
		while _alive[i] < BIOMES[i]["mob_count"]:
			var center := _random_point_in(BIOMES[i])
			var data := _pick_enemy(i)
			for k in rng.randi_range(2, 4):
				_spawn_enemy(i, center + Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-4, 4)), data)
	for p in _portals:
		if p["kind"] == "pause":
			_spawn_guards(p["pos"], 5)
	for b in BOSSES:
		var boss := _make_enemy(b)
		add_child(boss)
		boss.global_position = b["home"]
		bosses.append(boss)
		add_child(Build.label("Covil: " + b["name"], b["home"] + Vector3(0, 12, 0), Color(1, 0.6, 0.3), 120))

	for i in CENTAUR_COUNT:
		_spawn_centaur()

	for a in OS.get_cmdline_user_args():  # ferramenta de dev: --demo-at=Nome do Boss
		if a.begins_with("--demo-at="):
			var b := _boss_named(a.trim_prefix("--demo-at=").replace("_", " "))
			if b:
				var bp := b.global_position
				player.global_position = bp + Vector3(8, 0, 30)
				player.max_hp = 99999.0
				player.hp = 99999.0
				player.cam_yaw = atan2(-(bp.x - player.global_position.x), -(bp.z - player.global_position.z))
				player.cam_pitch = -0.15
				player.cam_distance = 9.0
	if "--demo-cards" in OS.get_cmdline_user_args():
		player.add_xp.call_deferred(25)  # ferramenta de dev: abre a escolha de cartas
	Game.show_toast("Dificuldade %s — 2 portais de PAUSA (verdes) e 1 de SAÍDA (dourado) perto do início" % Game.diff()["name"])


## Chamado quando o jogador volta de uma extração de pausa.
func on_resumed() -> void:
	player.camera.make_current()
	player.set_input_locked(false)
	Game.show_toast("De volta ao Vale. Os inimigos ficaram mais fortes (x%.2f)." % Game.pause_scaling())
	_extract_t = 0.0
	if Game.smoke_test:
		_smoke_stage = 10


# --- Construção do mapa -------------------------------------------------------

func _build_ground() -> void:
	var size := MAP_MAX - MAP_MIN
	var center := (MAP_MIN + MAP_MAX) / 2.0
	add_child(Build.textured_ground(Vector3(size.x, 1, size.y), Vector3(center.x, -0.52, center.y), "res://assets/textures/ground_hp/leaves.png", 5.0))
	for b in BIOMES:
		var c: Vector3 = b["center"]
		var g: Color = b["ground"]
		add_child(Build.textured_ground(Vector3(BIOME_SIZE, 1, BIOME_SIZE), Vector3(c.x, -0.5, c.z), BIOME_TEX.get(b["deco"], BIOME_TEX["forest"]), 5.0))
		add_child(Build.label(b["name"], c + Vector3(0, 10, 0), Color(1, 0.9, 0.6), 200))
	var wall_color := Color(0.35, 0.3, 0.28)
	add_child(Build.static_box(Vector3(size.x, 16, 2), wall_color, Vector3(center.x, 8, MAP_MIN.y)))
	add_child(Build.static_box(Vector3(size.x, 16, 2), wall_color, Vector3(center.x, 8, MAP_MAX.y)))
	add_child(Build.static_box(Vector3(2, 16, size.y), wall_color, Vector3(MAP_MIN.x, 8, center.y)))
	add_child(Build.static_box(Vector3(2, 16, size.y), wall_color, Vector3(MAP_MAX.x, 8, center.y)))


func _build_roads() -> void:
	for r in ROADS:
		var a: Vector3 = r[0]
		var b: Vector3 = r[1]
		add_child(Build.ground_patch(Vector2(7, a.distance_to(b) + 7), (a + b) / 2.0, atan2(b.x - a.x, b.z - a.z), "res://assets/textures/ground_hp/dirt.png", 4.0))


func _near_road(p: Vector3, margin: float) -> bool:
	for r in ROADS:
		var closest := Geometry3D.get_closest_point_to_segment(p, r[0], r[1])
		if Vector2(closest.x - p.x, closest.z - p.z).length() < margin:
			return true
	return false


func _clear_spot(p: Vector3) -> bool:
	if p.distance_to(SPAWN_POINT) < 14.0 or _near_road(p, 7.0):
		return false
	for b in BOSSES:
		if p.distance_to(b["home"]) < 12.0:
			return false
	for n in NPCS.values():
		if p.distance_to(n) < 5.0:
			return false
	return true


## Visual "da demo" no mapa todo: árvores e plantas dos pacotes, grama em cards, vila de casas modulares.
const TREES := {
	"forest": [["env/fp_pine_1", 8.0, 12.0], ["env/fp_pine_2", 8.0, 12.0], ["env/fp_spruce_1", 7.0, 10.0], ["env/fp_spruce_2", 6.0, 9.0], ["env/psx_tree1", 6.0, 8.0]],
	"dead": [["env/psx_tree1", 5.0, 8.0], ["env/fp_spruce_3", 4.0, 6.0], ["env/psx_treetrunk", 1.2, 1.6]],
	"pine": [["env/snow_snowy_pinetree", 7.0, 11.0], ["env/snow_snowy_tree", 6.0, 9.0]],
}
const SMALL := {
	"forest": [["env/fp_stump_1", 0.7, 0.4], ["env/fp_fern", 0.9, 0.0], ["env/fp_blueberrybush", 0.7, 0.0], ["env/fp_mushroom_1", 0.35, 0.0], ["env/fp_log_4", -2.4, 0.0], ["env/psx_rock", 1.2, 0.8]],
	"dead": [["env/fp_stump_2", 0.6, 0.4], ["env/snow_old_woodlog", -2.6, 0.0], ["env/fp_bracketfungus", 0.5, 0.0], ["env/psx_rock", 1.0, 0.7]],
	"pine": [["env/snow_rock", 1.4, 0.9], ["env/snow_old_woodlog", -2.6, 0.0], ["env/snow_rocky_wall", 2.5, 1.5]],
}
const TREE_TINT := {"forest": Color.WHITE, "dead": Color(0.55, 0.6, 0.45), "pine": Color.WHITE}


func _build_decorations() -> void:
	for b in BIOMES:
		var kind: String = b["deco"]
		var trees: Array = TREES[kind]
		for i in b["deco_count"]:
			var p := _random_point_in(b)
			if not _clear_spot(p):
				continue
			var t: Array = trees[rng.randi() % trees.size()]
			var o := Build.prop(t[0], p, rng.randf_range(t[1], t[2]), rng, 0.45, false, TREE_TINT[kind])
			if o:
				add_child(o)
			else:
				add_child(Build.tree(p, kind, rng))
		var small: Array = SMALL[kind]
		for i in int(b["deco_count"] * 0.6):
			var p := _random_point_in(b)
			if not _clear_spot(p):
				continue
			var sm: Array = small[rng.randi() % small.size()]
			var h := float(sm[1])
			var o := Build.prop(sm[0], p, absf(h) * rng.randf_range(0.8, 1.3), rng, float(sm[2]), h < 0.0, TREE_TINT[kind])
			if o:
				add_child(o)
	# Grama e flores em cards (floresta), juncos (pântano), tufos claros (neve)
	var avoid := func(p: Vector3) -> bool: return _near_road(p, 4.0)
	for spec in [[0, "env/psx_grass", 6000, 0.6], [0, "env/psx_dandelion", 700, 0.45], [0, "env/psx_lavender", 400, 0.5], [1, "env/psx_reed", 3000, 1.2], [1, "env/psx_grass", 1500, 0.5]]:
		var mm := Build.scatter_model(spec[1], BIOMES[spec[0]]["center"], BIOME_SIZE / 2.0 - 3.0, spec[2], spec[3], rng, avoid)
		if mm:
			if spec[0] == 1:
				mm.material_override = (mm.material_override as Material).duplicate() if mm.material_override else null
				if mm.material_override is StandardMaterial3D:
					(mm.material_override as StandardMaterial3D).albedo_color = Color(0.65, 0.7, 0.5)
			add_child(mm)
	add_child(Build.scatter(BIOMES[2]["center"], BIOME_SIZE / 2.0 - 3.0, 2500, Color(0.85, 0.9, 0.95), rng, 0.35, avoid))
	# Poças no pântano
	for i in 18:
		var c: Vector3 = BIOMES[1]["center"]
		var pos := c + Vector3(rng.randf_range(-100, 100), 0.03, rng.randf_range(-100, 100))
		if _near_road(pos, 6.0):
			continue
		var puddle := CylinderMesh.new()
		puddle.top_radius = rng.randf_range(3.0, 8.0)
		puddle.bottom_radius = puddle.top_radius
		puddle.height = 0.04
		var w := Build.mesh(puddle, Color(0.2, 0.35, 0.2), 0.3, 0.75)
		(w.material_override as StandardMaterial3D).roughness = 0.1
		w.position = pos
		add_child(w)
	_build_start_village()


## Vila de partida: casas modulares dos dois lados da estrada, cercas e props.
func _build_start_village() -> void:
	var houses := [[Vector3(-22, 0, 68), PI / 2.0, 3, 4, 2, "plaster"], [Vector3(-22, 0, 84), PI / 2.0, 3, 3, 1, "brick"],
		[Vector3(22, 0, 62), -PI / 2.0, 4, 4, 2, "wood"], [Vector3(22, 0, 80), -PI / 2.0, 3, 4, 2, "plaster"], [Vector3(-20, 0, 50), PI / 2.0, 3, 3, 2, "brick"]]
	for h in houses:
		var house := Village.build_house(h[2], h[3], h[4], h[5], rng)
		house.position = h[0]
		house.rotation.y = h[1]
		add_child(house)
	Village.fence(self, Vector3(-12, 0, 44), Vector3(-12, 0, 92))
	Village.fence(self, Vector3(12, 0, 44), Vector3(12, 0, 56))
	Village.fence(self, Vector3(12, 0, 88), Vector3(12, 0, 100))
	var props := [["props/Stall_Cart_Empty", Vector3(9, 0, 72), 2.4, -PI / 2], ["props/Barrel", Vector3(-9, 0, 64), 1.0, 0.0], ["props/Barrel_Apples", Vector3(-9.5, 0, 66), 1.0, 0.0],
		["props/Crate_Wooden", Vector3(9.5, 0, 66), 0.9, 0.4], ["props/FarmCrate_Carrot", Vector3(9, 0, 76), 0.5, 0.0], ["props/Bench", Vector3(-8, 0, 80), 0.55, PI / 2],
		["props/Banner_1", Vector3(-6, 0, 98), 3.6, 0.0], ["props/Banner_2", Vector3(6, 0, 98), 3.6, 0.0], ["props/Dummy", Vector3(-16, 0, 96), 1.8, 0.0], ["props/WeaponStand", Vector3(-15, 0, 92), 1.4, 0.0]]
	for p in props:
		var o := Build.prop(p[0], p[1], p[2], rng, 0.5)
		if o:
			o.rotation.y = p[3]
			add_child(o)
	var wagon := Village.piece("Prop_Wagon")
	if wagon:
		wagon.position = Vector3(8, 0, 86)
		wagon.rotation.y = 0.3
		add_child(wagon)


func _build_rocks() -> void:
	for i in 90:
		var p := Vector3(rng.randf_range(-108, 0), 0, rng.randf_range(-328, -112))
		if i % 2 == 0:
			p = Vector3(rng.randf_range(220, 328), 0, rng.randf_range(-328, -112))
		if _clear_spot(p):
			var o := Build.prop("env/snow_rock" if p.x > 200 or p.z < -200 else "env/psx_rock", p, rng.randf_range(2.0, 4.5), rng, 1.5)
			add_child(o if o else Build.rock(p, Color(0.45, 0.42, 0.4), rng))


func _build_points_of_interest() -> void:
	for b in BIOMES:
		for i in 4:
			_add_chest(_random_point_in(b))
	for npc_name in NPCS:
		_add_npc(npc_name, NPCS[npc_name])

	# Entrada da masmorra
	var arch := Node3D.new()
	arch.position = DUNGEON_ENTRANCE
	var stone := Color(0.2, 0.2, 0.25)
	arch.add_child(Build.static_box(Vector3(2.5, 10, 2.5), stone, Vector3(-5, 5, 0)))
	arch.add_child(Build.static_box(Vector3(2.5, 10, 2.5), stone, Vector3(5, 5, 0)))
	arch.add_child(Build.static_box(Vector3(13, 2.5, 2.5), stone, Vector3(0, 11, 0)))
	arch.add_child(Build.label("Cripta Profanada", Vector3(0, 14, 0), Color(0.8, 0.6, 1.0), 120))
	add_child(arch)
	var door := Interactable.new()
	door.prompt = "Entrar na Cripta Profanada (masmorra)"
	door.position = DUNGEON_ENTRANCE + Vector3(0, 0, 1)
	door.on_interact = func(_p: Player) -> void: _enter_dungeon()
	add_child(door)

	_add_portal(EXIT_PORTAL, "exit")
	var candidates := PAUSE_CANDIDATES.duplicate()
	candidates.shuffle()
	for i in Game.PAUSES_PER_RUN:
		_add_portal(candidates[i], "pause")


func _build_dungeon() -> void:
	var o := DUNGEON_ORIGIN
	var stone := Color(0.22, 0.21, 0.24)
	var floor_len := 240.0
	add_child(Build.static_box(Vector3(44, 1, floor_len), Color(0.18, 0.17, 0.2), o + Vector3(0, -0.5, -floor_len / 2.0 + 15)))
	add_child(Build.static_box(Vector3(44, 1, floor_len), Color(0.1, 0.1, 0.12), o + Vector3(0, 9, -floor_len / 2.0 + 15)))  # teto
	add_child(Build.static_box(Vector3(2, 10, floor_len), stone, o + Vector3(-22, 4, -floor_len / 2.0 + 15)))
	add_child(Build.static_box(Vector3(2, 10, floor_len), stone, o + Vector3(22, 4, -floor_len / 2.0 + 15)))
	add_child(Build.static_box(Vector3(44, 10, 2), stone, o + Vector3(0, 4, 15)))
	add_child(Build.static_box(Vector3(44, 10, 2), stone, o + Vector3(0, 4, -floor_len + 15)))
	# Paredes internas com passagem no meio: separam as salas
	for z in [-30.0, -90.0, -150.0]:
		add_child(Build.static_box(Vector3(18, 10, 2), stone, o + Vector3(-13, 4, z)))
		add_child(Build.static_box(Vector3(18, 10, 2), stone, o + Vector3(13, 4, z)))
	# Tochas
	for z in [0.0, -20.0, -45.0, -75.0, -105.0, -135.0, -165.0, -190.0, -215.0]:
		for x in [-18.0, 18.0]:
			var torch := OmniLight3D.new()
			torch.light_color = Color(1.0, 0.6, 0.3)
			torch.omni_range = 18.0
			torch.light_energy = 1.6
			torch.position = o + Vector3(x, 5, z)
			add_child(torch)
	var boss_light := OmniLight3D.new()
	boss_light.light_color = Color(0.7, 0.3, 1.0)
	boss_light.omni_range = 35.0
	boss_light.light_energy = 2.0
	boss_light.position = o + Vector3(0, 7, -190)
	add_child(boss_light)

	var exit := Interactable.new()
	exit.prompt = "Sair da masmorra"
	exit.position = o + Vector3(0, 0, 8)
	exit.add_child(Build.label("SAÍDA DA CRIPTA", Vector3(0, 3, 0), Color(0.8, 0.6, 1.0), 64))
	exit.on_interact = func(_p: Player) -> void: _exit_dungeon()
	add_child(exit)

	# Mobs da masmorra (não renascem)
	for i in 6:
		_spawn_at(SKELETON, o + Vector3(rng.randf_range(-15, 15), 0.2, rng.randf_range(-45, -80)))
	for i in 5:
		_spawn_at(SKELETON, o + Vector3(rng.randf_range(-15, 15), 0.2, rng.randf_range(-105, -140)))
	for i in 3:
		_spawn_at(ACOLYTE, o + Vector3(rng.randf_range(-15, 15), 0.2, rng.randf_range(-105, -140)))
	var lord := _make_enemy(CRYPT_LORD)
	add_child(lord)
	lord.global_position = o + Vector3(0, 1, -195)
	bosses.append(lord)


func _add_portal(pos: Vector3, kind: String) -> void:
	var color := Color(1.0, 0.8, 0.3) if kind == "exit" else Color(0.3, 1.0, 0.6)
	var text := "SAÍDA" if kind == "exit" else "PAUSA"
	var nodes: Array = []
	var ring := CylinderMesh.new()
	ring.top_radius = PORTAL_RADIUS
	ring.bottom_radius = PORTAL_RADIUS
	ring.height = 7.0
	var mi := Build.mesh(ring, color, 1.5, 0.35)
	mi.position = pos + Vector3(0, 3.5, 0)
	nodes.append(mi)
	var light := OmniLight3D.new()
	light.light_color = color
	light.omni_range = 14.0
	light.position = pos + Vector3(0, 3.5, 0)
	nodes.append(light)
	nodes.append(Build.label(text, pos + Vector3(0, 9, 0), color, 140))
	for n in nodes:
		add_child(n)
	_portals.append({"pos": pos, "kind": kind, "used": false, "nodes": nodes})


func _add_chest(pos: Vector3) -> void:
	var chest := Interactable.new()
	chest.prompt = "Abrir baú"
	chest.once = true
	chest.position = pos
	var box := BoxMesh.new()
	box.size = Vector3(1.2, 0.8, 0.8)
	var mi := Build.mesh(box, Color(0.75, 0.55, 0.15), 0.4)
	mi.position.y = 0.4
	chest.add_child(mi)
	chest.on_interact = func(p: Player) -> void:
		var reward: float = Game.diff()["reward"]
		var g := roundi(rng.randi_range(10, 25) * reward)
		p.add_gold(g)
		p.add_xp(roundi(5 * reward))
		var mat: String = BIOMES[_biome_at(pos)]["enemy"]["mat"]
		p.add_material(mat, rng.randi_range(1, 2))
		mi.material_override = Build.mat(Color(0.3, 0.25, 0.2))
		Game.show_toast("Baú aberto: +%d de ouro" % g)
	add_child(chest)


func _add_npc(npc_name: String, pos: Vector3) -> void:
	var npc := Interactable.new()
	npc.prompt = "Falar com " + npc_name
	npc.position = pos
	npc.add_child(NpcLook.make(npc_name))
	var mark := Build.label("!", Vector3(0, 3.0, 0), Color(1, 0.85, 0.1), 120)
	npc.add_child(mark)
	npc.add_child(Build.label(npc_name, Vector3(0, 2.2, 0), Color(0.6, 1, 0.6), 32))
	npc.set_meta("mark", mark)
	npc.on_interact = func(_p: Player) -> void: _talk(npc_name)
	add_child(npc)


# --- Missões ------------------------------------------------------------------------

func _talk(npc_name: String) -> void:
	# 1) Entregar missão concluída
	for q in QUESTS:
		var st: Dictionary = _quest_state[q["id"]]
		if st["status"] == "active" and q.get("turn_in", q["giver"]) == npc_name and _quest_complete(q):
			quest_dialog.show_quest(npc_name, q, "complete", _quest_line(q), func() -> void: _finish_quest(q))
			return
	# 2) Oferecer missão nova
	for q in QUESTS:
		var st: Dictionary = _quest_state[q["id"]]
		if q["giver"] == npc_name and st["status"] == "available":
			quest_dialog.show_quest(npc_name, q, "offer", _quest_goal(q).capitalize(), func() -> void: _accept_quest(q))
			return
	# 3) Lembrar o progresso
	for q in QUESTS:
		var st: Dictionary = _quest_state[q["id"]]
		if q["giver"] == npc_name and st["status"] == "active":
			quest_dialog.show_quest(npc_name, q, "progress", _quest_line(q), Callable())
			return
	quest_dialog.show_quest(npc_name, {"title": npc_name, "text": "Obrigado pela ajuda, aventureiro. Que a estrada lhe seja leve."}, "talk", "", Callable())


func _accept_quest(q: Dictionary) -> void:
	_quest_state[q["id"]]["status"] = "active"
	var extra := ""
	if q["type"] == "deliver":
		extra = " Você recebeu: %s." % q["item"]
	Game.show_toast("Missão aceita: %s" % q["title"])
	Game.log_event("Missão aceita: %s.%s" % [q["title"], extra], Game.LOG_QUEST)
	_refresh_quests()


## Dados para o diário de missões (tecla L).
func quest_entries() -> Array:
	var out: Array = []
	for q in QUESTS:
		if _quest_state[q["id"]]["status"] == "active":
			out.append({"title": q["title"], "text": q.get("text", ""), "progress": _quest_line(q).trim_prefix("• ")})
	return out


func _quest_goal(q: Dictionary) -> String:
	match q["type"]:
		"kill":
			return "mate %d %s" % [q["count"], q["target"]]
		"collect":
			return "traga %d %s" % [q["count"], Game.MATERIALS[q["target"]]]
		"boss":
			return "derrote %s" % q["target"]
		"deliver":
			return "leve %s para %s" % [q["item"], q["turn_in"]]
	return ""


func _quest_progress(q: Dictionary) -> int:
	match q["type"]:
		"collect":
			return mini(int(player.run_materials.get(q["target"], 0)), int(q["count"]))
		"deliver":
			return 0
	return int(_quest_state[q["id"]]["progress"])


func _quest_complete(q: Dictionary) -> bool:
	if q["type"] == "deliver":
		return true
	return _quest_progress(q) >= int(q["count"])


func _quest_line(q: Dictionary) -> String:
	if q["type"] == "deliver":
		return "• %s (fale com %s)" % [q["title"], q["turn_in"]]
	var done := " — volte para %s" % q["giver"] if _quest_complete(q) else ""
	return "• %s (%d/%d)%s" % [q["title"], _quest_progress(q), q["count"], done]


func _finish_quest(q: Dictionary) -> void:
	_quest_state[q["id"]]["status"] = "done"
	if q["type"] == "collect":
		player.run_materials[q["target"]] = int(player.run_materials[q["target"]]) - int(q["count"])
	var reward: float = Game.diff()["reward"]
	var g := roundi(int(q["gold"]) * reward)
	player.add_gold(g)
	player.add_xp(roundi(int(q["xp"]) * reward))
	Game.show_toast("Missão concluída: %s (+%d de ouro)" % [q["title"], g])
	Game.log_event("Missão concluída: %s." % q["title"], Game.LOG_QUEST)
	_refresh_quests()


func _on_enemy_killed(e: Enemy) -> void:
	for q in QUESTS:
		var st: Dictionary = _quest_state[q["id"]]
		if st["status"] == "active" and (q["type"] == "kill" or q["type"] == "boss") and q["target"] == e.display_name:
			st["progress"] = int(st["progress"]) + 1
			Game.log_event("%s: %d/%d" % [q["title"], mini(int(st["progress"]), int(q["count"])), q["count"]], Game.LOG_QUEST)
	if e.is_boss:
		for b in BOSSES + [CRYPT_LORD]:
			if b["name"] == e.display_name:
				Game.unlock_achievement(b["achievement"])
	_refresh_quests()


func _refresh_quests() -> void:
	var lines: Array[String] = []
	for q in QUESTS:
		if _quest_state[q["id"]]["status"] == "active":
			lines.append(_quest_line(q))
	hud.quest_lines = lines
	# "!" amarelo = missão disponível, "?" = pronta para entregar
	for n in get_tree().get_nodes_in_group("interactable"):
		if not n.has_meta("mark"):
			continue
		var npc_name := str(n.get("prompt")).trim_prefix("Falar com ")
		var mark: Label3D = n.get_meta("mark")
		mark.text = ""
		for q in QUESTS:
			var st: Dictionary = _quest_state[q["id"]]
			if st["status"] == "available" and q["giver"] == npc_name and mark.text == "":
				mark.text = "!"
			if st["status"] == "active" and q.get("turn_in", q["giver"]) == npc_name and _quest_complete(q):
				mark.text = "?"


# --- Mobs ----------------------------------------------------------------------

func _random_point_in(b: Dictionary) -> Vector3:
	var c: Vector3 = b["center"]
	var h: float = BIOME_SIZE / 2.0 - 5.0
	return Vector3(c.x + rng.randf_range(-h, h), 0, c.z + rng.randf_range(-h, h))


func _biome_at(p: Vector3) -> int:
	for i in BIOMES.size():
		var c: Vector3 = BIOMES[i]["center"]
		if absf(p.x - c.x) <= BIOME_SIZE / 2.0 and absf(p.z - c.z) <= BIOME_SIZE / 2.0:
			return i
	return 0


func _make_enemy(data: Dictionary) -> Enemy:
	var mult := Game.pause_scaling()
	var e := Enemy.new().setup(data, Game.diff()["hp"] * mult, Game.diff()["dmg"] * mult)
	e.killed.connect(_on_enemy_killed)
	return e


func _spawn_at(data: Dictionary, pos: Vector3) -> Enemy:
	var e := _make_enemy(data)
	add_child(e)
	e.global_position = pos
	return e


## Criatura do bioma: a principal na maioria das vezes, às vezes uma das extras.
func _pick_enemy(biome_index: int) -> Dictionary:
	var b: Dictionary = BIOMES[biome_index]
	var extra: Array = b.get("extra", [])
	if not extra.is_empty() and rng.randf() < 0.35:
		return extra[rng.randi() % extra.size()]
	return b["enemy"]


func _spawn_enemy(biome_index: int, at := Vector3.INF, data: Dictionary = {}) -> void:
	var b: Dictionary = BIOMES[biome_index]
	var pos := at
	if pos == Vector3.INF:
		pos = _random_point_in(b)
		for attempt in 6:
			if player == null or pos.distance_to(player.global_position) > 30.0:
				break
			pos = _random_point_in(b)
	if not _clear_spot(pos) and at == Vector3.INF:
		pos = _random_point_in(b)
	if data.is_empty():
		data = _pick_enemy(biome_index)
	var e := _spawn_at(data, pos + Vector3(0, 0.2, 0))
	e.killed.connect(func(_e: Enemy) -> void:
		_alive[biome_index] -= 1
		# renasce depois de um tempo (em outro ponto do bioma, longe do jogador)
		get_tree().create_timer(RESPAWN_TIME + rng.randf_range(0.0, 15.0)).timeout.connect(func() -> void:
			if is_inside_tree() and not _ending and _alive[biome_index] < BIOMES[biome_index]["mob_count"]:
				_spawn_enemy(biome_index)))
	_alive[biome_index] += 1


## Centauros andam pela metade leste da floresta e renascem depois de um tempo.
func _spawn_centaur() -> void:
	var pos := Vector3(rng.randf_range(20, 100), 0.2, rng.randf_range(-90, 40))
	var e := _spawn_at(CENTAUR, pos)
	e.killed.connect(func(_e: Enemy) -> void:
		get_tree().create_timer(25.0).timeout.connect(func() -> void:
			if is_inside_tree() and not _ending:
				_spawn_centaur()))


## Grupo extra de mobs ao redor de um ponto (guardas de portal e ondas da extração).
func _spawn_guards(center: Vector3, count: int) -> void:
	var data: Dictionary = BIOMES[_biome_at(center)]["enemy"]
	for i in count:
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(8.0, 14.0)
		_spawn_at(data, center + Vector3(cos(ang) * dist, 0.2, sin(ang) * dist))


# --- Masmorra -------------------------------------------------------------------

func _enter_dungeon() -> void:
	if player.mounted:
		player._set_mounted(false)
	in_dungeon = true
	player.global_position = DUNGEON_ORIGIN + Vector3(0, 1, 0)
	player.cam_yaw = 0.0
	Game.show_toast("Cripta Profanada — sem montaria aqui. O Senhor da Cripta espera no fundo.")


func _exit_dungeon() -> void:
	in_dungeon = false
	player.global_position = DUNGEON_ENTRANCE + Vector3(0, 1, 10)
	player.cam_yaw = PI


# --- Loop ------------------------------------------------------------------------

func _process(delta: float) -> void:
	if _ending:
		return
	_spawn_t -= delta
	if _spawn_t <= 0.0:
		_spawn_t = 20.0  # rede de segurança; o renascimento normal é por mob (RESPAWN_TIME)
		for i in BIOMES.size():
			if _alive[i] < BIOMES[i]["mob_count"]:
				_spawn_enemy(i)

	_update_mount_lock()
	_update_extraction(delta)
	hud.minimap.zone_name = _zone_name()
	if Engine.get_process_frames() % 30 == 0:
		_refresh_quests()

	if Game.smoke_test:
		_run_smoke_test(delta)


func _zone_name() -> String:
	if in_dungeon:
		return "Cripta Profanada (nv 10-13)"
	var p := player.global_position
	for b in BIOMES:
		var c: Vector3 = b["center"]
		if absf(p.x - c.x) <= BIOME_SIZE / 2.0 and absf(p.z - c.z) <= BIOME_SIZE / 2.0:
			return "%s (nv %s)" % [b["name"], b["levels"]]
	return "Vale das Três Terras"


## Marcadores do minimapa: missões (!/?), portais, bosses, masmorra.
func _map_markers() -> Array:
	var out: Array = []
	if in_dungeon:
		out.append({"pos": DUNGEON_ORIGIN + Vector3(0, 0, 8), "color": Color(0.8, 0.6, 1.0), "shape": "square", "edge": true})
		for b in bosses:
			if is_instance_valid(b) and b.global_position.x > 900.0:
				out.append({"pos": b.global_position, "color": Color(0.9, 0.2, 0.2), "shape": "skull", "edge": true})
		return out
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.has_meta("mark"):
			var mark: Label3D = n.get_meta("mark")
			if mark.text != "":
				out.append({"pos": n.global_position, "color": Color(1, 0.85, 0.1), "shape": "text", "text": mark.text, "edge": mark.text == "?"})
			else:
				out.append({"pos": n.global_position, "color": Color(0.6, 1, 0.6), "shape": "dot"})
		elif str(n.get("prompt")) == "Abrir baú":
			out.append({"pos": n.global_position, "color": Color(0.9, 0.7, 0.2), "shape": "dot"})
	# Objetivos de missões ativas de boss: seta na borda
	for b in bosses:
		if is_instance_valid(b) and b.global_position.x < 900.0:
			out.append({"pos": b.global_position, "color": Color(0.9, 0.2, 0.2), "shape": "skull", "edge": _boss_quest_active(b.display_name)})
	for p in _portals:
		if not p["used"]:
			out.append({"pos": p["pos"], "color": Color(1, 0.8, 0.3) if p["kind"] == "exit" else Color(0.3, 1.0, 0.6), "shape": "square", "edge": true})
	out.append({"pos": DUNGEON_ENTRANCE, "color": Color(0.8, 0.6, 1.0), "shape": "square", "edge": _boss_quest_active("Senhor da Cripta")})
	return out


func _boss_quest_active(boss_name: String) -> bool:
	for q in QUESTS:
		if q["type"] == "boss" and q["target"] == boss_name and _quest_state[q["id"]]["status"] == "active":
			return true
	return false


func _update_mount_lock() -> void:
	var engaged: Enemy = null
	for b in bosses:
		if is_instance_valid(b) and b.is_engaged():
			engaged = b
	player.can_mount = engaged == null and not in_dungeon
	if engaged and player.mounted:
		player._set_mounted(false)
		Game.show_toast("%s te arrancou do cavalo! Lute ou fuja para bem longe." % engaged.display_name)
	if engaged and not _boss_warned:
		_boss_warned = true
		Game.show_toast("%s te viu! Não dá para montar até vencer ou despistar." % engaged.display_name)
	if engaged == null:
		_boss_warned = false


func _update_extraction(delta: float) -> void:
	_wave_cd = maxf(0.0, _wave_cd - delta)
	var portal = null
	for p in _portals:
		if p["used"]:
			continue
		var pos: Vector3 = p["pos"]
		if Vector2(player.global_position.x - pos.x, player.global_position.z - pos.z).length() < PORTAL_RADIUS:
			portal = p
	if portal == null or player.dead:
		_extract_t = 0.0
		hud.external_progress = -1.0
		return
	if portal["kind"] == "pause" and Game.pauses_left() <= 0:
		hud.external_progress = 0.0
		hud.external_label = "Sem pausas restantes — use a SAÍDA"
		return

	if _extract_t == 0.0 and _wave_cd <= 0.0:
		_wave_cd = 15.0
		_spawn_guards(portal["pos"], 5 + 2 * Game.pauses_used)
		Game.show_toast("O portal atraiu inimigos! Aguente firme.")
	_extract_t += delta
	hud.external_progress = _extract_t / EXTRACT_TIME
	hud.external_label = "Saindo do mapa..." if portal["kind"] == "exit" else "Extraindo (pausa)..."
	if _extract_t < EXTRACT_TIME:
		return

	_extract_t = 0.0
	hud.external_progress = -1.0
	if portal["kind"] == "exit":
		_ending = true
		Game.end_run(true, player.run_gold, player.run_materials)
	else:
		portal["used"] = true
		for n in portal["nodes"]:
			(n as Node3D).visible = false
		var g := player.run_gold
		var mats := player.run_materials.duplicate()
		player.run_gold = 0
		player.run_materials.clear()
		player.set_input_locked(true)
		Game.pause_run(g, mats)


func _on_player_died() -> void:
	_ending = true
	Game.show_toast("Você morreu! O loot não extraído foi perdido.")
	await get_tree().create_timer(2.5).timeout
	Game.end_run(false, 0, {})


# --- Cartas e habilidades ao subir de nível -----------------------------------------

func _on_level_up(new_level: int) -> void:
	for id in player.abilities.keys():
		if int(player.abilities[id]["unlock"]) == new_level:
			Game.show_toast("Nova habilidade: %s [%s]" % [player.abilities[id]["name"], player.abilities[id]["key"]])
	if ClassData.CARD_ROUNDS.has(new_level):
		_card_queue.append(ClassData.CARD_ROUNDS[new_level])
		if not card_picker.visible:
			_next_card_round()


func _next_card_round() -> void:
	if _card_queue.is_empty() or _deck.is_empty():
		_card_queue.clear()
		return
	var round_data: Dictionary = _card_queue.pop_front()
	_deck.shuffle()
	var shown: Array = _deck.slice(0, mini(int(round_data["show"]), _deck.size()))
	card_picker.open(shown, int(round_data["pick"]), func(card: Dictionary) -> void:
		_deck.erase(card)
		player.apply_card(card["id"])
		Game.show_toast("Carta: %s" % card["name"]))


# --- Teste automático ----------------------------------------------------------------
var _smoke_stage := 0
var _smoke_t := 0.0


func _boss_named(n: String) -> Enemy:
	for b in bosses:
		if is_instance_valid(b) and b.display_name == n:
			return b
	return null


func _run_smoke_test(delta: float) -> void:
	_smoke_t += delta
	match _smoke_stage:
		0:
			if _smoke_t > 0.5:
				_smoke_stage = 1
				player.add_xp(200)
				player.res = player.res_max
				for id in ["basic", "a1", "a2"]:
					print("SMOKE ability ", id, " ", player.abilities[id]["name"], " ok=", player.try_ability(id))
				print("SMOKE allies=", get_tree().get_nodes_in_group("allies").size(), " class=", player.class_name_display, " hp=", player.max_hp)
				player.toggle_mount()
		1:
			if _smoke_t > 2.5:
				_smoke_stage = 2
				print("SMOKE level=", player.level, " cards=", player.chosen_cards, " mounted=", player.mounted)
				_talk("Batedora Elandra")
				_talk("Mensageiro Pip")
				for e in get_tree().get_nodes_in_group("enemies"):
					if (e as Enemy).display_name == "Lobo Faminto" and not (e as Enemy).is_boss:
						(e as Enemy).take_damage(99999.0)
				var drop := Pickup.make("material", 2, "pele_lobo")
				add_child(drop)
				drop.global_position = player.global_position + Vector3(0, 0.8, 0)
		2:
			if _smoke_t > 3.2:
				_smoke_stage = 3
				_talk("Batedora Elandra")
				_talk("Alquimista Vosk")
				bag_ui.open()
				character_ui.open()
				UIWin.close_all(get_tree())
				print("SMOKE quests lobos=", _quest_state["lobos"]["status"], " carta=", _quest_state["carta"]["status"], " gold=", player.run_gold, " mats=", player.run_materials)
				_enter_dungeon()
		3:
			if _smoke_t > 3.6:
				_smoke_stage = 4
				print("SMOKE dungeon can_mount=", player.can_mount)
				_boss_named("Senhor da Cripta").take_damage(99999.0)
				_exit_dungeon()
				var rei := _boss_named("Dragão do Pântano")
				player.global_position = rei.global_position + Vector3(8, 0, 0)
		4:
			if _smoke_t > 4.2:
				_smoke_stage = 5
				var rei := _boss_named("Dragão do Pântano")
				print("SMOKE boss_engaged=", rei.is_engaged(), " can_mount=", player.can_mount, " achievements=", Game.achievements)
				rei.take_damage(100.0)
				player.global_position = Vector3(0, 1, 0)
		5:
			if _smoke_t > 10.0:
				_smoke_stage = 6
				var rei := _boss_named("Dragão do Pântano")
				print("SMOKE boss_reset hp=", rei.hp, "/", rei.max_hp, " engaged=", rei.is_engaged())
				for e in get_tree().get_nodes_in_group("enemies"):
					if not (e as Enemy).is_boss:
						(e as Enemy).take_damage(99999.0)
				player.max_hp = 99999.0
				player.hp = 99999.0
				var pause_portal: Vector3 = _portals.filter(func(p): return p["kind"] == "pause")[0]["pos"]
				player.global_position = pause_portal + Vector3(0, 1, 0)
		10:
			_smoke_stage = 11
			print("SMOKE resumed level=", player.level, " pauses_left=", Game.pauses_left(), " run_gold=", player.run_gold, " bank_gold=", Game.gold)
			player.global_position = EXIT_PORTAL + Vector3(0, 1, 0)
