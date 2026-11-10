class_name CharacterRig
extends Node3D
## Personagem com esqueleto e animações de verdade (hoje: o anão do pacote Dwarf Melee Animations).
## Locomoção (parado / correr em 4 direções), ataques e reação a dano, com mistura suave entre clipes.

const KINDS := {
	"dwarf_m": {"family": "dwarf", "model": "res://assets/characters/dwarf/DwarfM_Model.fbx", "anims": "res://assets/characters/dwarf/dwarf_m_anims.res", "ref_h": 1.355},
	"dwarf_f": {"family": "dwarf", "model": "res://assets/characters/dwarf/DwarfF_Model.fbx", "anims": "res://assets/characters/dwarf/dwarf_f_anims.res", "ref_h": 1.355},
	# Humanos (Quaternius: Modular Character Outfits + Universal Animation Library, mesmo esqueleto)
	"human_m": {"family": "human", "model": "res://assets/characters/human/Male_Ranger.glb", "anims": "res://assets/characters/human/human_anims.res", "ref_h": 1.83},
	"human_f": {"family": "human", "model": "res://assets/characters/human/Female_Ranger.glb", "anims": "res://assets/characters/human/human_anims.res", "ref_h": 1.74},
	"peasant_m": {"family": "human", "model": "res://assets/characters/human/Male_Peasant.glb", "anims": "res://assets/characters/human/human_anims.res", "ref_h": 1.83},
	# Esqueleto (mob): AccuRig retargetado para o perfil humanoide no import (map_cc.tres) + animações UAL retargetadas
	"skeleton": {"family": "humanoid", "model": "res://assets/characters/skeleton/skeleton.fbx", "anims": "res://assets/characters/skeleton/skeleton_anims.res", "ref_h": 1.93,
		"tex": "res://assets/characters/skeleton/skeleton_a.png"},
	# Criatura do pacote Monster04 (11 animações próprias, renomeadas para os nomes do jogo)
	"monster04": {"family": "creature", "model": "res://assets/characters/monster04/monster04.glb", "anims": "", "ref_h": 2.0,
		"clips": {"idle": "Monster04_Idle", "combat_idle": "Monster04_Idle_v02", "run": "Monster04_Run", "walk": "Monster04_Walk",
			"attack_1h": "Monster04_Attack01", "attack_2h": "Monster04_Attack02", "attack_cast": "Monster04_Shoot", "hit": "Monster04_GetHit", "death": "Monster04_Die"}},
	# Heróis (um por classe): modelos com esqueleto próprio, retargetados no import para o perfil humanoide
	# (map.tres de cada um) e animados com a biblioteca UAL retargetada (hero_anims.res).
	"hero_ranger": {"family": "humanoid", "model": "res://assets/characters/heroes/ranger/ranger.glb", "anims": "res://assets/characters/heroes/hero_anims.res", "ref_h": 3.75,
		"hide": ["weapon"]},
	# Guerreiro: modelo estático com pesos transferidos do manequim UAL (mesmo esqueleto dos humanos)
	"hero_warrior": {"family": "human", "plain": true, "model": "res://assets/characters/heroes/warrior/warrior.glb", "anims": "res://assets/characters/human/human_anims.res", "ref_h": 1.83,
		"tex_map": {"varian_2": "res://assets/characters/heroes/warrior/sword.png"}, "hide_mats": ["varian_0"]},
	"hero_mage": {"family": "humanoid", "model": "res://assets/characters/heroes/mage/mage.fbx", "anims": "res://assets/characters/heroes/hero_anims.res", "ref_h": 1.86,
		"tex_map": {"Body": "res://assets/characters/heroes/mage/T_1046301_Body_D.png", "Equip_01": "res://assets/characters/heroes/mage/T_1046301_Equip_01_D.png",
			"Equip_02": "res://assets/characters/heroes/mage/T_1046301_Equip_02_D.png", "Equip_03": "res://assets/characters/heroes/mage/T_1046301_Equip_03_D.png",
			"Equip_04": "res://assets/characters/heroes/mage/T_1046301_Equip_04_D.png", "Equip_05": "res://assets/characters/heroes/mage/T_1046301_Equip_05_D.png"}},
	# Espírito invocado pelo Bruxo (sem pernas, flutua)
	"spirit": {"family": "humanoid", "model": "res://assets/characters/heroes/wizard/wizard.fbx", "anims": "res://assets/characters/heroes/hero_anims.res", "ref_h": 2.6,
		"tex_map": {"blinn1": "res://assets/characters/heroes/wizard/wizard_color.png"}},
	# Animal do Caçador
	"pet_bear": {"family": "humanoid", "model": "res://assets/characters/heroes/pet/bear.fbx", "anims": "res://assets/characters/heroes/hero_anims.res", "ref_h": 3.05,
		"tex_map": {"blinn": "res://assets/characters/heroes/pet/bear_color.png"}, "hide": ["lod1"]},
	"hero_warlock": {"family": "humanoid", "model": "res://assets/characters/heroes/warlock/warlock.fbx", "anims": "res://assets/characters/heroes/hero_anims.res", "ref_h": 1.86,
		"tex_map": {"Cloak": "res://assets/characters/heroes/warlock/T_1046302_Cloak_D.png", "Body_02": "res://assets/characters/heroes/warlock/T_1046302_Body_02_D.png",
			"Equip": "res://assets/characters/heroes/warlock/T_1046302_Equip_D.png", "Body_01": "res://assets/characters/heroes/warlock/T_1046302_Body_01_D.png"}},
	# Bestiário (Quaternius): mesmo esqueleto dos humanos -> animações UAL direto
	"imp": {"family": "human", "plain": true, "model": "res://assets/characters/bestiary/Imp.glb", "anims": "res://assets/characters/human/human_anims.res", "ref_h": 1.5},
	"puglin": {"family": "human", "plain": true, "model": "res://assets/characters/bestiary/Puglin.glb", "anims": "res://assets/characters/human/human_anims.res", "ref_h": 0.8},
	# Lobo (mob e animal do Caçador): animações próprias
	"wolf": {"family": "creature", "model": "res://assets/characters/wolf/wolf.fbx", "anims": "", "ref_h": 1.6, "tex": "res://assets/characters/wolf/wolf_a.png",
		"clips": {"idle": "Wolf|Wolf_Stand", "combat_idle": "Wolf|Wolf_Stand2", "run": "Wolf|Wolf_Run", "walk": "Wolf|Wolf_Run",
			"attack_1h": "Wolf|Wolf_Attack", "attack_2h": "Wolf|Wolf_Attack2", "death": "Wolf|Wolf_Death"}},
	"peasant_f": {"family": "human", "model": "res://assets/characters/human/Female_Peasant.glb", "anims": "res://assets/characters/human/human_anims.res", "ref_h": 1.74},
}
## Nomes "lógicos" dos ossos por família (para prender armas, ombreiras, chapéus).
const BONES := {
	"dwarf": {"hand_r": "B-handProp.R", "hand_l": "B-handProp.L", "head": "B-head", "arm_l": "B-upperArm.L", "arm_r": "B-upperArm.R"},
	"human": {"hand_r": "hand_r", "hand_l": "hand_l", "head": "Head", "arm_l": "upperarm_l", "arm_r": "upperarm_r"},
	"humanoid": {"hand_r": "RightHand", "hand_l": "LeftHand", "head": "Head", "arm_l": "LeftUpperArm", "arm_r": "RightUpperArm"},
}
## Como a arma (eixo +Y = lâmina, origem = pegada) gira dentro do osso da mão de cada família.
## Ajustado olhando prints das poses de combate.
const GRIP := {
	"dwarf": {"hand_r": Vector3(0, 0, 0), "hand_l": Vector3(0, 0, 0)},
	"human": {"hand_r": Vector3(0, 0, -35), "hand_l": Vector3(0, 0, 35)},
	"humanoid": {"hand_r": Vector3(0, 0, -90), "hand_l": Vector3(0, 0, 90)},
}
## Cabeça com rosto (Universal Base Characters) e cabelos, presos no mesmo esqueleto da roupa.
const HUMAN_DIR := "res://assets/characters/human/"
## Tom de pele por raça (multiplica a textura de pele do rosto e das mãos).
const SKIN_TINT := {"humano": Color(1, 1, 1), "elfo": Color(0.97, 0.93, 1.05), "orc": Color(0.55, 0.85, 0.42), "anao": Color(1.0, 0.92, 0.85)}
const HAIR_COLORS := [Color(0.35, 0.22, 0.12), Color(0.12, 0.1, 0.09), Color(0.85, 0.7, 0.4), Color(0.6, 0.25, 0.1), Color(0.8, 0.8, 0.82)]
## Roupa por classe (textura recolorida do pacote Ranger) e se usa capuz.
const OUTFITS := {
	"guerreiro": {"tex": "red", "hood": false},
	"mago": {"tex": "blue", "hood": false},
	"cacador": {"tex": "green", "hood": true},
	"bruxo": {"tex": "purple", "hood": true},
	"inimigo": {"tex": "steel", "hood": true},
}
const TEXTURE := "res://assets/characters/dwarf/dwarf_shade.png"

## O anão do pacote grátis vem "manequim" (uma cor só). Pintamos cada parte do corpo pela influência
## dos ossos (barba, cabelo, pele, peito, braços, pernas, pés, capa) com a paleta da classe/raça.
const PALETTES := {
	"guerreiro": {"armor": Color(0.62, 0.64, 0.7), "cape": Color(0.62, 0.12, 0.1), "legs": Color(0.42, 0.28, 0.16), "boots": Color(0.28, 0.2, 0.14), "hands": Color(0.55, 0.56, 0.62), "belt": Color(0.75, 0.58, 0.25), "beard": Color(0.72, 0.34, 0.12)},
	"mago": {"armor": Color(0.2, 0.3, 0.72), "cape": Color(0.14, 0.18, 0.45), "legs": Color(0.2, 0.28, 0.65), "boots": Color(0.3, 0.22, 0.15), "hands": Color(0.85, 0.82, 0.75), "belt": Color(0.85, 0.7, 0.3), "beard": Color(0.85, 0.85, 0.88)},
	"cacador": {"armor": Color(0.32, 0.42, 0.2), "cape": Color(0.22, 0.3, 0.14), "legs": Color(0.45, 0.32, 0.18), "boots": Color(0.3, 0.2, 0.12), "hands": Color(0.45, 0.32, 0.2), "belt": Color(0.55, 0.4, 0.2), "beard": Color(0.4, 0.25, 0.12)},
	"bruxo": {"armor": Color(0.38, 0.14, 0.46), "cape": Color(0.12, 0.08, 0.14), "legs": Color(0.25, 0.1, 0.3), "boots": Color(0.15, 0.1, 0.12), "hands": Color(0.3, 0.12, 0.35), "belt": Color(0.6, 0.55, 0.3), "beard": Color(0.12, 0.1, 0.1)},
	"inimigo": {"armor": Color(0.45, 0.35, 0.25), "cape": Color(0.3, 0.25, 0.2), "legs": Color(0.35, 0.28, 0.2), "boots": Color(0.2, 0.15, 0.1), "hands": Color(0.4, 0.3, 0.22), "belt": Color(0.5, 0.4, 0.2), "beard": Color(0.3, 0.2, 0.12)},
}
const SKINS := {"humano": Color(0.93, 0.74, 0.6), "anao": Color(0.9, 0.68, 0.55), "elfo": Color(0.92, 0.86, 0.95), "orc": Color(0.45, 0.62, 0.32)}
static var _mesh_cache := {}
const RUN_SPEED := 7.0  ## velocidade em que a animação de correr fica natural

var anim: AnimationPlayer
var skeleton: Skeleton3D
var model: Node3D
var _one_shot := ""
var _dead := false
var _combat_t := 0.0
var weapons: Array[Node3D] = []
var family := "dwarf"
var _base_yaw := PI
var _strafe := 0.0
var hero := false  ## modelo de herói (sem ombreiras/chapéus procedurais)
var riding := false  ## montado: pose sentada (humanos) ou parada


static func available(kind: String) -> bool:
	if not KINDS.has(kind) or not ResourceLoader.exists(KINDS[kind]["model"]):
		return false
	return KINDS[kind]["anims"] == "" or ResourceLoader.exists(KINDS[kind]["anims"])


static func _part(bone: String) -> String:
	if bone.contains("beard") or bone.contains("hair"):
		return "beard"
	if bone.contains("head") or bone.contains("jaw") or bone.contains("neck"):
		return "skin"
	if bone.contains("cape"):
		return "cape"
	if bone.contains("hand") or bone.contains("Finger") or bone.contains("pinky") or bone.contains("thumb"):
		return "hands"
	if bone.contains("forearm"):
		return "hands"
	if bone.contains("foot") or bone.contains("toe"):
		return "boots"
	if bone.contains("thigh") or bone.contains("shin"):
		return "legs"
	if bone.contains("hips"):
		return "belt"
	return "armor"


## Copia a malha colorindo cada vértice pela parte do corpo do osso que mais o influencia.
static func _colored_mesh(mi: MeshInstance3D, colors: Dictionary, key: String) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var src := mi.mesh
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
		var n: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var per := bones.size() / maxi(1, n)
		var cols := PackedColorArray()
		cols.resize(n)
		for v in n:
			var best := 0
			var best_w := -1.0
			for k in per:
				if weights[v * per + k] > best_w:
					best_w = weights[v * per + k]
					best = bones[v * per + k]
			var bone_name := String(mi.skin.get_bind_name(best)) if mi.skin and best < mi.skin.get_bind_count() else ""
			cols[v] = colors.get(_part(bone_name), Color.WHITE)
		arr[Mesh.ARRAY_COLOR] = cols
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_mesh_cache[key] = out
	return out


## Cores do personagem: paleta da classe + pele da raça.
static func palette(class_id: String, race_id: String) -> Dictionary:
	var p: Dictionary = PALETTES.get(class_id, PALETTES["guerreiro"]).duplicate()
	p["skin"] = SKINS.get(race_id, SKINS["anao"])
	var o: Dictionary = OUTFITS.get(class_id, OUTFITS["cacador"])
	p["outfit"] = o["tex"]
	p["hood"] = o["hood"]
	p["skin_tint"] = SKIN_TINT.get(race_id, Color.WHITE)
	p["hair"] = "simpleparted"
	p["hair_color"] = HAIR_COLORS[absi(class_id.hash() + race_id.hash()) % HAIR_COLORS.size()]
	p["beard"] = class_id == "guerreiro" or race_id == "anao"
	return p


## Tipo de corpo para a raça: anão usa o anão; as outras raças usam o humano (com proporção própria).
static func kind_for(race_id: String, sex: String) -> String:
	if race_id == "anao":
		return "dwarf_f" if sex == "f" else "dwarf_m"
	return "human_f" if sex == "f" else "human_m"


## Monta o personagem pronto de uma classe/raça/sexo (jogador, prévia, NPCs).
## Herói de cada classe (modelo próprio) e a arma que ele recebe se o modelo não tiver.
const HEROES := {
	"guerreiro": {"kind": "hero_warrior", "h": 1.9, "weapon": ""},
	"mago": {"kind": "hero_mage", "h": 1.9, "weapon": "weapons/w_wizards_staff"},
	"cacador": {"kind": "hero_ranger", "h": 1.85, "weapon": "weapons/wpn_battle_bow", "hand": "hand_l"},
	"bruxo": {"kind": "hero_warlock", "h": 2.0, "weapon": "weapons/w_reapers_scythe"},
}


static func for_character(class_id: String, race_id: String, sex: String) -> CharacterRig:
	var hero: Dictionary = HEROES.get(class_id, {})
	if not hero.is_empty() and available(hero["kind"]):
		var hr := make(hero["kind"], hero["h"])
		hr.hero = true
		var wl: Dictionary = {"weapons/w_wizards_staff": 1.6, "weapons/wpn_battle_bow": 1.25, "weapons/w_reapers_scythe": 1.6}
		if hero["weapon"] != "":
			hr._weapon(hero["weapon"], hero.get("hand", "hand_r"), wl.get(hero["weapon"], 1.0))
		return hr
	var kind := kind_for(race_id, sex)
	if not available(kind):
		return null
	var colors := palette(class_id, race_id)
	var h := 1.35 if race_id == "anao" else 1.78
	if sex == "f":
		colors["hair"] = "long" if class_id != "guerreiro" else "buns"
	var rig := make(kind, h, Color.WHITE, colors)
	rig.equip_class(class_id, colors)
	rig.scale = ClassData.race(race_id).get("rig_scale", Vector3.ONE)
	rig.race_details(race_id, colors)
	return rig


## Detalhes de raça no corpo humano: orelhas pontudas (elfo), presas (orc).
func race_details(race_id: String, colors: Dictionary) -> void:
	if family != "human":
		return
	var skin: Color = colors.get("skin", Color.WHITE)
	if race_id == "elfo":
		for sd in [-1.0, 1.0]:
			var ear := CylinderMesh.new()
			ear.top_radius = 0.0
			ear.bottom_radius = 0.035
			ear.height = 0.2
			var e := Build.mesh(ear, skin)
			e.position = Vector3(0.085 * sd, 0.1, -0.01)
			e.rotation = Vector3(-0.35, 0, -1.15 * sd)
			attach("head", e)
	elif race_id == "orc":
		for sd in [-1.0, 1.0]:
			var tusk := CylinderMesh.new()
			tusk.top_radius = 0.0
			tusk.bottom_radius = 0.016
			tusk.height = 0.07
			var t := Build.mesh(tusk, Color(0.95, 0.92, 0.82))
			t.position = Vector3(0.035 * sd, 0.03, 0.09)
			t.rotation = Vector3(-0.3, 0, 0.2 * sd)
			attach("head", t)


func bone(logical: String) -> String:
	return BONES.get(family, {}).get(logical, logical)


static func make(kind: String, height := 1.35, tint := Color.WHITE, colors: Dictionary = {}) -> CharacterRig:
	if not available(kind):
		return null
	var rig := CharacterRig.new()
	rig.name = "Rig_" + kind
	rig.family = KINDS[kind]["family"]
	rig.model = (load(KINDS[kind]["model"]) as PackedScene).instantiate()
	# O modelo do pacote olha para +Z; o jogo usa -Z como frente.
	rig._base_yaw = float(KINDS[kind].get("yaw", PI))
	rig.model.rotation.y = rig._base_yaw
	var s := height / float(KINDS[kind]["ref_h"])
	rig.model.scale = Vector3.ONE * s
	rig.add_child(rig.model)
	rig.skeleton = rig.model.find_children("*", "Skeleton3D", true, false)[0]
	if colors.is_empty():
		colors = palette("guerreiro", "anao")
	if KINDS[kind].get("plain", false):
		rig._map_materials(KINDS[kind].get("tex_map", {}), tint, KINDS[kind].get("hide_mats", []))
	elif rig.family == "human":
		rig._dress_human(kind, colors, tint)
	elif KINDS[kind].has("tex_map") or (rig.family == "humanoid" and not KINDS[kind].has("tex")):
		rig._map_materials(KINDS[kind].get("tex_map", {}), tint)
	elif rig.family == "humanoid" or rig.family == "creature":
		var tex := _tex(colors.get("tex", KINDS[kind].get("tex", "")))
		for mi in rig.model.find_children("*", "MeshInstance3D", true, false):
			if kind == "wolf" and not String(mi.name).ends_with("body"):
				continue  # olhos e dentes mantêm o material do modelo
			var m := StandardMaterial3D.new()
			if tex == null:
				var base := (mi as MeshInstance3D).get_active_material(0)
				if base is StandardMaterial3D:
					tex = (base as StandardMaterial3D).albedo_texture
			m.albedo_texture = tex
			m.albedo_color = tint
			m.roughness = 1.0
			(mi as MeshInstance3D).material_override = m
	else:
		rig._paint_dwarf(kind, colors, tint)
	for hide in KINDS[kind].get("hide", []):
		for mi in rig.model.find_children("*", "MeshInstance3D", true, false):
			if String(mi.name).contains(hide):
				mi.visible = false
	var lib: AnimationLibrary
	if KINDS[kind].has("clips"):
		# animações que vêm dentro do próprio modelo: copia com os nomes do jogo e remove o player original
		lib = AnimationLibrary.new()
		for ap in rig.model.find_children("*", "AnimationPlayer", true, false):
			var src := ap as AnimationPlayer
			var clips: Dictionary = KINDS[kind]["clips"]
			for k in clips:
				if src.has_animation(clips[k]):
					var a: Animation = src.get_animation(clips[k]).duplicate(true)
					a.loop_mode = Animation.LOOP_LINEAR if k in ["idle", "combat_idle", "run", "walk"] else Animation.LOOP_NONE
					lib.add_animation(k, a)
			src.stop()
			src.get_parent().remove_child(src)
			src.free()
	else:
		lib = load(KINDS[kind]["anims"])
	rig.anim = AnimationPlayer.new()
	rig.model.add_child(rig.anim)
	rig.anim.root_node = NodePath("..")
	rig.anim.add_animation_library("", lib)
	rig.anim.animation_finished.connect(rig._on_finished)
	rig.anim.play("idle")
	return rig


func _paint_dwarf(kind: String, colors: Dictionary, tint: Color) -> void:
	var tex: Texture2D = load(TEXTURE) if ResourceLoader.exists(TEXTURE) else null
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		m3.mesh = _colored_mesh(m3, colors, kind + str(colors))
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.albedo_color = tint
		m.vertex_color_use_as_albedo = true
		m.roughness = 1.0
		m3.material_override = m


## Materiais do próprio modelo, foscos; tex_map troca a textura pelo pedaço do nome do material.
func _map_materials(tex_map: Dictionary, tint: Color, hide_mats: Array = []) -> void:
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		for i in m3.mesh.get_surface_count():
			var base := m3.get_active_material(i)
			var m: StandardMaterial3D
			if base is StandardMaterial3D:
				m = (base as StandardMaterial3D).duplicate() as StandardMaterial3D
			else:
				m = StandardMaterial3D.new()
			var nm := base.resource_name if base else ""
			if nm in hide_mats:
				# superfície que não ficou boa (ex.: capa chapada do Guerreiro): invisível
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				m.albedo_color = Color(1, 1, 1, 0)
				m3.set_surface_override_material(i, m)
				continue
			for key in tex_map:
				if nm.contains(key):
					m.albedo_texture = _tex(tex_map[key])
					m.albedo_color = Color.WHITE
					break
			if nm.ends_with("_OP") or nm.contains("eye_shadow"):
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.albedo_color = m.albedo_color * tint
			m.metallic = 0.0
			m.roughness = 0.9
			m.normal_enabled = false
			m.emission_enabled = false
			m3.set_surface_override_material(i, m)


static var _tex_cache := {}


static func _tex(path: String) -> Texture2D:
	if path == "":
		return null
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[path]


## Humano: roupa do pacote (textura recolorida pela classe), pele da raça nas mãos e na cabeça.
func _dress_human(kind: String, colors: Dictionary, tint: Color) -> void:
	var skin_tint: Color = colors.get("skin_tint", Color.WHITE) * tint
	var outfit_tex: Texture2D = null
	var is_ranger := kind.begins_with("human")
	if is_ranger and colors.has("outfit"):
		outfit_tex = _tex("res://assets/characters/human/T_Ranger_%s.png" % colors["outfit"])
	elif not is_ranger and colors.get("outfit_alt", false):
		outfit_tex = _tex("res://assets/characters/human/T_Peasant_2_BaseColor.png")
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.name.ends_with("Head_Hood") and not colors.get("hood", true):
			m3.visible = false
			continue
		for i in m3.mesh.get_surface_count():
			var base := m3.get_active_material(i)
			if base == null:
				continue
			var m := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
			if base.resource_name.begins_with("MI_Regular"):
				m.albedo_color = m.albedo_color * skin_tint
				m.roughness = 0.9
				m.normal_enabled = false
				m3.set_surface_override_material(i, m)
				continue
			if outfit_tex:
				m.albedo_texture = outfit_tex
			m.albedo_color = m.albedo_color * tint
			m.metallic = 0.0
			m.roughness = 1.0
			m.normal_enabled = false
			m3.set_surface_override_material(i, m)
	# cabeça com rosto + cabelo/barba (mesmo esqueleto: as malhas são movidas para dentro dele)
	var female := kind.ends_with("_f")
	_add_skinned(HUMAN_DIR + ("head_f.glb" if female else "head_m.glb"), skin_tint, Color.WHITE)
	var hair: String = colors.get("hair", "")
	if hair != "" and not (colors.get("hood", false) and kind.begins_with("human")):
		_add_skinned(HUMAN_DIR + "hair_%s.glb" % hair, Color.WHITE, colors.get("hair_color", HAIR_COLORS[0]))
	if colors.get("beard", false) and not female:
		_add_skinned(HUMAN_DIR + "hair_beard.glb", Color.WHITE, colors.get("hair_color", HAIR_COLORS[0]))


static var _scene_cache := {}


## Carrega um GLB com malhas presas no esqueleto humano e move as malhas para o nosso esqueleto.
## skin_tint: tinge a pele; hair_tint: tinge o cabelo (textura cinza do pacote).
func _add_skinned(path: String, skin_tint: Color, hair_tint: Color) -> void:
	if not ResourceLoader.exists(path):
		return
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path)
	var src: Node = (_scene_cache[path] as PackedScene).instantiate()
	for mi in src.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		var skin := m3.skin
		m3.get_parent().remove_child(m3)
		m3.owner = null
		skeleton.add_child(m3)
		m3.skin = skin
		m3.skeleton = NodePath("..")
		for i in m3.mesh.get_surface_count():
			var base := m3.get_active_material(i)
			if base is StandardMaterial3D:
				var m := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
				m.metallic = 0.0
				m.roughness = 0.85
				m.normal_enabled = false
				if m3.name.begins_with("Head"):
					m.albedo_color = m.albedo_color * skin_tint
				elif hair_tint != Color.WHITE:
					m.albedo_color = m.albedo_color * hair_tint
				m3.set_surface_override_material(i, m)
	src.free()


## Prende um objeto (arma) num osso: "hand_r", "hand_l", "B-chest"...
func attach(bone_name: String, node: Node3D) -> void:
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone(bone_name)
	skeleton.add_child(ba)
	ba.add_child(node)


## local_dir: direção do movimento no espaço do personagem (x = direita, y = frente); speed em m/s.
func set_locomotion(local_dir: Vector2, speed: float, delta: float) -> void:
	if _dead:
		return
	_combat_t = maxf(0.0, _combat_t - delta)
	if _one_shot != "":
		return
	if riding:
		var ride := "sit" if anim.has_animation("sit") else "idle"
		if anim.current_animation != ride:
			anim.play(ride, 0.2)
		anim.speed_scale = 1.0
		model.rotation.y = _base_yaw
		return
	# a pose "Sword_Idle" da biblioteca humana é de lado; em combate o humano fica na pose normal de frente
	var clip := "combat_idle" if _combat_t > 0.0 and family == "dwarf" else "idle"
	var sp := 1.0
	if speed > 0.4:
		if absf(local_dir.y) >= absf(local_dir.x):
			clip = "run" if local_dir.y >= 0.0 else "run_back"
		else:
			clip = "run_right" if local_dir.x > 0.0 else "run_left"
		sp = clampf(speed / RUN_SPEED, 0.6, 2.0)
	# Humanos não têm correr de lado/para trás: usa o correr normal girando o corpo (ou ao contrário).
	var want_strafe := 0.0
	if not anim.has_animation(clip):
		match clip:
			"run_back":
				clip = "run"
				sp = -sp * 0.8
			"run_left":
				clip = "run"
				want_strafe = 1.2
			"run_right":
				clip = "run"
				want_strafe = -1.2
	_strafe = lerpf(_strafe, want_strafe, clampf(delta * 10.0, 0.0, 1.0))
	model.rotation.y = _base_yaw + _strafe
	if anim.current_animation != clip:
		anim.play(clip, 0.15)
	anim.speed_scale = sp


func play_once(clip: String, speed := 1.0) -> void:
	if _dead or not anim.has_animation(clip):
		return
	_one_shot = clip
	_combat_t = 4.0
	_strafe = 0.0
	model.rotation.y = _base_yaw
	anim.play(clip, 0.08)
	anim.speed_scale = speed
	anim.seek(0.0, true)


func hit() -> void:
	if _one_shot == "" or _one_shot == "hit":
		play_once("hit", 1.4)
	_combat_t = 4.0


func die() -> void:
	_dead = true
	_one_shot = "death"
	anim.play("death", 0.1)
	anim.speed_scale = 1.0


func _on_finished(clip: StringName) -> void:
	if String(clip) == _one_shot and not _dead:
		_one_shot = ""


## Equipa visual da classe: arma(s) nas mãos e ombreiras grandes (silhueta clássica de MMORPG).
func equip_class(class_id: String, colors: Dictionary) -> void:
	if hero:
		return
	var trim := Color(0.85, 0.66, 0.25)
	var armor: Color = colors.get("armor", Color.GRAY)
	for side in ["L", "R"]:
		var pad := Node3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.16
		sm.height = 0.2
		sm.is_hemisphere = false
		var p := Build.mesh(sm, armor.lightened(0.1))
		p.scale = Vector3(1.0, 0.75, 1.15)
		pad.add_child(p)
		var rim := TorusMesh.new()
		rim.inner_radius = 0.13
		rim.outer_radius = 0.17
		var r := Build.mesh(rim, trim)
		r.position.y = -0.02
		pad.add_child(r)
		if class_id == "guerreiro" or class_id == "bruxo":
			var spike := CylinderMesh.new()
			spike.top_radius = 0.0
			spike.bottom_radius = 0.045
			spike.height = 0.16
			var sp := Build.mesh(spike, trim if class_id == "guerreiro" else Color(0.85, 0.85, 0.8))
			sp.position.y = 0.12
			pad.add_child(sp)
		pad.position = Vector3(0, 0.03, 0)
		attach("arm_l" if side == "L" else "arm_r", pad)
	match class_id:
		"guerreiro":
			_weapon("weapons/w_knights_longsword", "hand_r", 0.95)
			var shield := Node3D.new()
			var disc := CylinderMesh.new()
			disc.top_radius = 0.3
			disc.bottom_radius = 0.3
			disc.height = 0.05
			var d := Build.mesh(disc, colors.get("cape", Color.RED))
			d.rotation.z = PI / 2.0
			shield.add_child(d)
			var boss := SphereMesh.new()
			boss.radius = 0.08
			boss.height = 0.1
			var b := Build.mesh(boss, trim)
			b.position.x = 0.04
			shield.add_child(b)
			var ring := TorusMesh.new()
			ring.inner_radius = 0.27
			ring.outer_radius = 0.31
			var rg := Build.mesh(ring, trim)
			rg.rotation.z = PI / 2.0
			shield.add_child(rg)
			attach("hand_l", shield)
			var helm := Node3D.new()
			var dome := SphereMesh.new()
			dome.radius = 0.17
			dome.height = 0.22
			dome.is_hemisphere = true
			helm.add_child(Build.mesh(dome, armor))
			for hs in [-1.0, 1.0]:
				var horn := CylinderMesh.new()
				horn.top_radius = 0.0
				horn.bottom_radius = 0.04
				horn.height = 0.2
				var h := Build.mesh(horn, Color(0.9, 0.88, 0.8))
				h.position = Vector3(0.15 * hs, 0.08, 0)
				h.rotation.z = -0.9 * hs
				helm.add_child(h)
			helm.position.y = 0.08
			attach("head", helm)
		"mago":
			_weapon("weapons/w_wizards_staff", "hand_r", 1.45)
			var hat := Node3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.2
			cone.height = 0.45
			var c := Build.mesh(cone, colors.get("armor", Color.BLUE))
			c.position.y = 0.32
			c.rotation.x = -0.2
			hat.add_child(c)
			var brim := CylinderMesh.new()
			brim.top_radius = 0.3
			brim.bottom_radius = 0.3
			brim.height = 0.03
			var br := Build.mesh(brim, colors.get("armor", Color.BLUE).darkened(0.2))
			br.position.y = 0.12
			hat.add_child(br)
			attach("head", hat)
		"cacador":
			_weapon("weapons/wpn_battle_bow", "hand_l", 1.1)
		"bruxo":
			_weapon("weapons/w_reapers_scythe", "hand_r", 1.4)


## Arma na mão: alinhada pelo eixo comprido (Models.weapon), pegada na origem, girada pelo GRIP da família.
const WEAPON_FIX := {"weapons/w_knights_longsword": {"flip": true}, "weapons/wpn_battle_bow": {"grip": 0.5, "rot_human": Vector3(180, 0, 0)}, "weapons/w_wizards_staff": {"grip": 0.45, "rot_human": Vector3(180, 0, 0)},
	"weapons/w_reapers_scythe": {"grip": 0.35, "rot_human": Vector3(180, 0, 0)}, "weapons/w_hunting_spear": {"grip": 0.4}}


func _weapon(id: String, hand: String, length: float) -> void:
	var fix: Dictionary = WEAPON_FIX.get(id, {})
	var w := Models.weapon(id, length, float(fix.get("grip", 0.12)), bool(fix.get("flip", false)))
	if w == null:
		return
	var holder := Node3D.new()
	holder.add_child(w)
	var rot: Vector3 = GRIP.get(family, {}).get(hand, Vector3.ZERO)
	# armas compridas (cajado, foice) ficam em pé ao longo do braço, como um bastão
	if family != "dwarf" and fix.has("rot_human"):
		rot = fix["rot_human"]
	holder.rotation_degrees = rot
	# o osso fica dentro do modelo escalado (e alguns esqueletos têm escala nos ossos):
	# compensa para a arma ter o tamanho pedido em metros
	var bi := skeleton.find_bone(bone(hand))
	var sc := model.scale.x * Models._relative_transform(model, skeleton).basis.get_scale().x
	if bi >= 0:
		sc *= skeleton.get_bone_global_rest(bi).basis.get_scale().x
	holder.scale = holder.scale / maxf(0.0001, sc)
	attach(hand, holder)
	weapons.append(holder)
