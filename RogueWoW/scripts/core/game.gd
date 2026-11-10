extends Node
## Autoload "Game": estado global, dificuldades, economia (ouro, materiais, equipamento),
## save e controles.

signal scene_requested(scene_name: String)
signal toast(text: String)
signal logged(text: String, color: Color)  ## registro de eventos (canto inferior esquerdo)

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 3
const MAX_CHARACTERS := 4

## 6 dificuldades: multiplicadores dos mobs, recompensa e Poder de Armadura mínimo.
const DIFFICULTIES := [
	{"name": "Normal", "hp": 1.0, "dmg": 1.0, "reward": 1.0, "min_pa": 0},
	{"name": "Difícil", "hp": 1.6, "dmg": 1.4, "reward": 1.5, "min_pa": 10},
	{"name": "Heroico", "hp": 2.5, "dmg": 1.9, "reward": 2.2, "min_pa": 25},
	{"name": "Mítico", "hp": 4.0, "dmg": 2.6, "reward": 3.2, "min_pa": 45},
	{"name": "Lendário", "hp": 6.5, "dmg": 3.5, "reward": 4.5, "min_pa": 70},
	{"name": "Pesadelo", "hp": 10.0, "dmg": 5.0, "reward": 6.5, "min_pa": 95},
]

## Materiais que caem dos mobs e bosses.
const MATERIALS := {
	"pele_lobo": "Pele de Lobo",
	"osso_carnical": "Osso de Carniçal",
	"couro_yeti": "Couro de Yeti",
	"fragmento_sombrio": "Fragmento Sombrio",
	"crina_flamejante": "Crina Flamejante",
	"presa_alfa": "Casca Ancestral",
	"coracao_lodo": "Escama do Dragão do Pântano",
	"chifre_anciao": "Chifre do Dragão da Montanha",
	"coroa_cripta": "Chifre Demoníaco",
}

## Raridade dos materiais (cor do nome e da borda do ícone)
const MATERIAL_RARITY := {
	"pele_lobo": "comum", "osso_carnical": "comum", "couro_yeti": "comum",
	"fragmento_sombrio": "incomum", "crina_flamejante": "incomum",
	"presa_alfa": "rara", "coracao_lodo": "rara", "chifre_anciao": "rara", "coroa_cripta": "mítica",
}

## Ícone (assets/icons/<nome>.png) de cada coisa
const SLOT_ICONS := {"head": "slot_head", "shoulders": "slot_shoulders", "chest": "slot_chest", "hands": "slot_hands", "feet": "slot_feet", "back": "slot_back"}

const SLOT_NAMES := {"head": "Cabeça", "shoulders": "Ombros", "chest": "Peito", "hands": "Mãos", "feet": "Pés", "back": "Costas"}

## Receitas do ferreiro: materiais + ouro → peça de armadura (Poder de Armadura = PA).
const RECIPES := [
	{"id": "capuz_lobo", "name": "Capuz de Pele de Lobo", "slot": "head", "pa": 6, "gold": 40, "mats": {"pele_lobo": 6}},
	{"id": "ombreiras_osso", "name": "Ombreiras de Osso", "slot": "shoulders", "pa": 10, "gold": 80, "mats": {"osso_carnical": 6, "pele_lobo": 4}},
	{"id": "peitoral_yeti", "name": "Peitoral de Couro de Yeti", "slot": "chest", "pa": 16, "gold": 150, "mats": {"couro_yeti": 8, "osso_carnical": 4}},
	{"id": "manto_flamejante", "name": "Manto Flamejante", "slot": "back", "pa": 14, "gold": 140, "mats": {"crina_flamejante": 4, "pele_lobo": 6}},
	{"id": "botas_alfa", "name": "Botas Ancestrais", "slot": "feet", "pa": 12, "gold": 120, "mats": {"presa_alfa": 1, "pele_lobo": 8}},
	{"id": "manoplas_lodo", "name": "Manoplas de Escama", "slot": "hands", "pa": 18, "gold": 200, "mats": {"coracao_lodo": 1, "osso_carnical": 6}},
	{"id": "elmo_anciao", "name": "Elmo Dracônico", "slot": "head", "pa": 22, "gold": 260, "mats": {"chifre_anciao": 1, "couro_yeti": 10}},
	{"id": "manto_cripta", "name": "Manto do Senhor da Cripta", "slot": "back", "pa": 30, "gold": 400, "mats": {"coroa_cripta": 1, "fragmento_sombrio": 10}},
]

const POTION_PRICE := 25
const POTION_MAX := 5

## Partida em andamento. Extrair num portal de PAUSA guarda o loot e deixa o mapa
## congelado para continuar depois. O portal de SAÍDA encerra a partida.
const PAUSES_PER_RUN := 2
var difficulty := 0
var run_active := false
var run_paused := false
var pauses_used := 0

# Personagens salvos (até 4). Os campos abaixo são o personagem ATIVO;
# save_game() copia de volta para characters[current_char].
var characters: Array = []
var current_char := -1
var char_name := ""
var race := "humano"
var sex := "m"  ## "m" ou "f" (muda o modelo do anão animado)
var class_id := "mago"
var gold := 0
var materials := {}  ## id -> quantidade
var equipment := {}  ## slot -> id da receita
var bag: Array = []  ## itens forjados que não estão equipados (ids de receita)
var potions := 0
var runs_extracted := 0
var best_difficulty := -1
var achievements: Array = []  ## da conta (todos os personagens)
var last_result := ""

var tooltip: Tooltip

## Modo de teste automático (rodar com: godot -- --smoke)
var smoke_test := false
## Prints/ferramentas de dev: não grava o save do jogador.
var no_save := false


func _ready() -> void:
	_setup_input()
	tooltip = Tooltip.new()
	add_child(tooltip)
	smoke_test = "--smoke" in OS.get_cmdline_user_args()
	if not smoke_test:
		load_game()


func diff() -> Dictionary:
	return DIFFICULTIES[difficulty]


## Multiplicador extra: o mapa endurece 25% a cada pausa usada.
func pause_scaling() -> float:
	return 1.0 + 0.25 * pauses_used


func pauses_left() -> int:
	return PAUSES_PER_RUN - pauses_used


# --- Equipamento / ferreiro ---------------------------------------------------

## Raridade de uma peça pelo PA (cor do nome)
func gear_rarity(r: Dictionary) -> String:
	var pa := int(r.get("pa", 0))
	if pa >= 25:
		return "mítica"
	if pa >= 16:
		return "rara"
	if pa >= 10:
		return "incomum"
	return "comum"


static func icon(icon_name: String) -> Texture2D:
	# Ícones pintados (pacote Craftpix) têm prioridade sobre os gerados.
	var painted := "res://assets/icons/craftpix/%s.png" % icon_name
	if ResourceLoader.exists(painted):
		return load(painted)
	var path := "res://assets/icons/%s.png" % icon_name
	if ResourceLoader.exists(path):
		return load(path)
	return null


func recipe(id: String) -> Dictionary:
	for r in RECIPES:
		if r["id"] == id:
			return r
	return {}


func armor_power() -> int:
	var total := 0
	for slot in equipment:
		total += int(recipe(equipment[slot]).get("pa", 0))
	return total


func can_craft(r: Dictionary) -> bool:
	if gold < int(r["gold"]):
		return false
	for m in r["mats"]:
		if int(materials.get(m, 0)) < int(r["mats"][m]):
			return false
	return true


## Forja o item: vai para a bolsa e é equipado se o espaço estiver vazio ou se for melhor.
func craft(id: String) -> bool:
	var r := recipe(id)
	if r.is_empty() or not can_craft(r):
		return false
	gold -= int(r["gold"])
	for m in r["mats"]:
		materials[m] = int(materials.get(m, 0)) - int(r["mats"][m])
	bag.append(id)
	var current := recipe(equipment.get(r["slot"], ""))
	if current.is_empty() or int(r["pa"]) > int(current["pa"]):
		equip(id)
	save_game()
	return true


func equip(id: String) -> void:
	var r := recipe(id)
	if r.is_empty() or not id in bag:
		return
	bag.erase(id)
	var slot: String = r["slot"]
	if equipment.has(slot):
		bag.append(equipment[slot])
	equipment[slot] = id
	save_game()


func unequip(slot: String) -> void:
	if not equipment.has(slot):
		return
	bag.append(equipment[slot])
	equipment.erase(slot)
	save_game()


# --- Personagens ---------------------------------------------------------------

func create_character(p_name: String, p_race: String, p_class: String, p_sex := "m") -> int:
	if characters.size() >= MAX_CHARACTERS:
		return -1
	# cada classe é um herói fixo: raça e corpo vêm do herói
	var h := ClassData.hero(p_class)
	p_race = h["race"]
	p_sex = h["sex"]
	characters.append({
		"name": p_name, "race": p_race, "class": p_class, "sex": p_sex, "gold": 0, "materials": {},
		"equipment": {}, "bag": [], "potions": 1, "runs_extracted": 0, "best_difficulty": -1,
	})
	save_game()
	return characters.size() - 1


func delete_character(index: int) -> void:
	if index < 0 or index >= characters.size():
		return
	characters.remove_at(index)
	if current_char == index:
		current_char = -1
	elif current_char > index:
		current_char -= 1
	save_game()


func select_character(index: int) -> void:
	var c: Dictionary = characters[index]
	current_char = index
	char_name = c["name"]
	class_id = c["class"]
	race = ClassData.hero(class_id)["race"]
	sex = ClassData.hero(class_id)["sex"]
	gold = int(c.get("gold", 0))
	materials = c.get("materials", {})
	equipment = c.get("equipment", {})
	bag = c.get("bag", [])
	potions = int(c.get("potions", 0))
	runs_extracted = int(c.get("runs_extracted", 0))
	best_difficulty = int(c.get("best_difficulty", -1))
	run_active = false
	run_paused = false
	last_result = ""


func _store_active() -> void:
	if current_char < 0 or current_char >= characters.size():
		return
	characters[current_char] = {
		"name": char_name, "race": race, "class": class_id, "sex": sex, "gold": gold, "materials": materials,
		"equipment": equipment, "bag": bag, "potions": potions, "runs_extracted": runs_extracted,
		"best_difficulty": best_difficulty,
	}


func go_to_character_select() -> void:
	if demo_active:
		_end_demo()
	save_game()
	scene_requested.emit("menu")


# --- Cena de demonstração (direção de arte) -------------------------------------------

var demo_active := false
var _demo_backup := {}


## Abre a Clareira do Bandido com o personagem escolhido e um inventário de exemplo.
## Nada é salvo: ao sair, o personagem volta exatamente como estava.
func start_demo() -> void:
	_store_active()
	_demo_backup = {"characters": characters.duplicate(true), "achievements": achievements.duplicate(true), "current": current_char, "no_save": no_save}
	demo_active = true
	no_save = true
	setup_demo_inventory()
	scene_requested.emit("demo")


func _end_demo() -> void:
	demo_active = false
	characters = _demo_backup.get("characters", characters)
	achievements = _demo_backup.get("achievements", achievements)
	no_save = bool(_demo_backup.get("no_save", false))
	var idx := int(_demo_backup.get("current", -1))
	if idx >= 0 and idx < characters.size():
		select_character(idx)
	else:
		current_char = -1


## Inventário de demonstração: alguns materiais, ouro, poções e peças forjadas.
func setup_demo_inventory() -> void:
	gold = 345
	potions = 3
	materials = {"pele_lobo": 12, "osso_carnical": 7, "couro_yeti": 4, "crina_flamejante": 2, "presa_alfa": 1}
	equipment = {"head": "capuz_lobo", "shoulders": "ombreiras_osso", "feet": "botas_alfa"}
	bag = ["manto_flamejante", "peitoral_yeti"]


func buy_potion() -> bool:
	if gold < POTION_PRICE or potions >= POTION_MAX:
		return false
	gold -= POTION_PRICE
	potions += 1
	save_game()
	return true


# --- Partida ----------------------------------------------------------------------

func start_run(diff_index: int) -> void:
	difficulty = clampi(diff_index, 0, DIFFICULTIES.size() - 1)
	run_active = true
	run_paused = false
	pauses_used = 0
	scene_requested.emit("field")


func _bank(run_gold: int, run_mats: Dictionary) -> String:
	gold += run_gold
	var count := 0
	for m in run_mats:
		materials[m] = int(materials.get(m, 0)) + int(run_mats[m])
		count += int(run_mats[m])
	return "+%d de ouro e %d materiais guardados" % [run_gold, count]


## Extração de pausa: guarda o loot e volta para a cidade com o mapa congelado.
func pause_run(run_gold: int, run_mats: Dictionary) -> void:
	var banked := _bank(run_gold, run_mats)
	pauses_used += 1
	run_paused = true
	last_result = "Extração de pausa: %s. O mapa te espera (%d pausa(s) restante(s))." % [banked, pauses_left()]
	save_game()
	scene_requested.emit("pause")


func resume_run() -> void:
	run_paused = false
	scene_requested.emit("resume")


func end_run(extracted: bool, run_gold: int, run_mats: Dictionary) -> void:
	if extracted:
		var banked := _bank(run_gold, run_mats)
		runs_extracted += 1
		best_difficulty = maxi(best_difficulty, difficulty)
		last_result = "Saída concluída: %s. Partida encerrada." % banked
	else:
		last_result = "Você morreu e perdeu o ouro e os materiais que não tinha extraído."
	run_active = false
	run_paused = false
	save_game()
	scene_requested.emit("hub")


func abandon_run() -> void:
	run_active = false
	run_paused = false
	last_result = "Partida abandonada."
	scene_requested.emit("hub")


func unlock_achievement(achievement: String) -> void:
	if achievement in achievements:
		return
	achievements.append(achievement)
	toast.emit("Conquista desbloqueada: %s" % achievement)
	log_event("Conquista desbloqueada: [%s]" % achievement, LOG_QUEST)
	save_game()


func show_toast(text: String) -> void:
	toast.emit(text)


## Linha no registro de eventos (dano, loot, XP, missões, conquistas).
func log_event(text: String, color := Color(0.95, 0.92, 0.85)) -> void:
	logged.emit(text, color)


const LOG_DAMAGE := Color(1.0, 0.95, 0.75)
const LOG_HURT := Color(1.0, 0.45, 0.4)
const LOG_LOOT := Color(0.4, 1.0, 0.45)
const LOG_XP := Color(0.75, 0.6, 1.0)
const LOG_QUEST := Color(1.0, 0.85, 0.2)
const LOG_SYSTEM := Color(0.6, 0.85, 1.0)


# --- Save -------------------------------------------------------------------

func save_game() -> void:
	_store_active()
	if smoke_test or no_save:
		return
	var data := {
		"version": SAVE_VERSION,
		"characters": characters,
		"achievements": achievements,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	achievements = data.get("achievements", [])
	if int(data.get("version", 1)) >= 3:
		characters = data.get("characters", [])
		return
	# Save antigo (v2, sem personagens): vira o primeiro personagem.
	characters = [{
		"name": "Herói", "race": "humano", "class": "mago", "gold": int(data.get("gold", 0)),
		"materials": data.get("materials", {}), "equipment": data.get("equipment", {}),
		"bag": [], "potions": int(data.get("potions", 0)), "runs_extracted": int(data.get("runs_extracted", 0)),
		"best_difficulty": int(data.get("best_difficulty", -1)),
	}]


# --- Controles ----------------------------------------------------------------

func _setup_input() -> void:
	_key("move_forward", KEY_W)
	_key("move_back", KEY_S)
	_key("move_left", KEY_A)
	_key("move_right", KEY_D)
	_key("jump", KEY_SPACE)
	_key("ability_1", KEY_1)
	_key("ability_2", KEY_2)
	_key("mount", KEY_F)
	_key("interact", KEY_E)
	_key("use_potion", KEY_Q)
	_key("inventory", KEY_I)
	_key("quest_log", KEY_L)
	_key("bag", KEY_U)
	_key("game_menu", KEY_ESCAPE)
	_key("toggle_mouse_lock", KEY_TAB)
	_mouse("attack", MOUSE_BUTTON_LEFT)


func _key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)


func _mouse(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
