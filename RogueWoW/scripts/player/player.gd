class_name Player
extends CharacterBody3D
## Jogador. A classe (Guerreiro, Mago, Caçador, Bruxo) e a raça vêm de Game.class_id / Game.race.
## Câmera estilo WoW: segure o botão direito para girar a câmera e virar o personagem.
## TAB trava o mouse (modo action, sem precisar segurar o botão direito).

signal died
signal leveled_up(new_level: int)

const WALK_SPEED := 7.0
const MOUNT_SPEED := 14.0
const JUMP_VELOCITY := 6.5
const MOUNT_CAST_TIME := 1.5
const INTERACT_RANGE := 3.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Classe e raça
var class_id := "mago"
var class_data: Dictionary
var race_data: Dictionary
var abilities: Dictionary  ## basic / a1 / a2

# Câmera
var cam_yaw := 0.0
var cam_pitch := -0.35
var cam_distance := 7.0
var mouse_look := false
var mouse_locked := false
var cam_pivot: Node3D
var spring: SpringArm3D
var camera: Camera3D

# Visual
var model: Node3D
var rider: Node3D
var horse: Node3D
var _body_mat: StandardMaterial3D
var _body_color: Color
var _flash_t := 0.0
var _shield_fx: MeshInstance3D
var anim: ProcAnim
var rig: CharacterRig  ## personagem animado de verdade (anão com esqueleto)
var visual: Node3D  ## modelo 3D (ou null se estiver usando o boneco cinza)
var horse_anim: AnimationPlayer

# Recurso da classe (mana / fúria / foco)
var res_type := "mana"
var res := 100.0
var res_max := 100.0
var _res_regen := 5.0
var _combat_t := 0.0
const MODEL_HEIGHT := 1.9

# Atributos (o nível só vale dentro da partida)
var class_name_display := "Mago"
var max_hp := 100.0
var hp := 100.0
var level := 1
var xp := 0
var xp_to_next := 10
var damage_mult := 1.0
var armor_power := 0
## Loot da partida (só vira seu de verdade quando extrair)
var run_gold := 0
var run_materials := {}
var _potion_cd := 0.0

# Estado
var cooldowns := {"basic": 0.0, "a1": 0.0, "a2": 0.0}
var chosen_cards: Array[String] = []
## Modificadores aplicados pelas cartas (genéricos para todas as classes)
var mods := {
	"basic_dmg": 1.0, "spread": false, "explode": false, "pierce": false, "proj_speed": 1.0,
	"a1_cd": 1.0, "a2_cd": 1.0, "a1_radius": 1.0, "a2_radius": 1.0, "a1_dmg": 1.0,
	"blink_blast": false, "melee_range": 1.0, "melee_heal": 0.0, "shield_dmg": 1.0, "shield_dur": 0.0,
	"berserk": false, "pet_dmg": 1.0, "spirit_dur": 0.0, "spirit_count": 1, "spirit_dmg": 1.0,
	"drain_heal": 0.5, "xp_heal": 0.0, "move_speed": 1.0,
}
var mounted := false
var mount_cast := -1.0  ## < 0 = não está invocando o cavalo
var can_mount := true
var input_locked := false
var dead := false
var shield_t := 0.0  ## Muralha de Escudo ativa
var _face_attack_t := 0.0
var pets: Array[Ally] = []
var last_target: Enemy  ## último inimigo atingido (quadro de alvo no HUD)


func _ready() -> void:
	add_to_group("player")
	class_id = Game.class_id
	class_data = ClassData.for_class(class_id)
	race_data = ClassData.race(Game.race)
	abilities = class_data["abilities"]
	class_name_display = class_data["name"]
	res_type = class_data.get("resource", "mana")
	var rd: Dictionary = ClassData.RESOURCES[res_type]
	res_max = rd["max"]
	res = rd["start"]
	_res_regen = rd["regen"]
	# Vida base da classe + Poder de Armadura (+2 vida e +1% dano por ponto)
	armor_power = Game.armor_power()
	max_hp = float(class_data["hp"]) + 2.0 * armor_power
	hp = max_hp
	damage_mult = 1.0 + 0.01 * armor_power
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	_build_model()
	_build_camera()
	if class_id == "cacador":
		_summon_pet.call_deferred()


func _build_model() -> void:
	model = Node3D.new()
	add_child(model)
	rider = Node3D.new()
	model.add_child(rider)
	var h: float = race_data["height"]
	rider.scale = Vector3(h, h, h)

	_body_color = class_data["color"]
	rig = CharacterRig.for_character(class_id, Game.race, Game.sex)
	if rig:
		rider.scale = Vector3.ONE
		rider.add_child(rig)
		visual = rig
		horse = _build_horse()
		horse.visible = false
		model.add_child(horse)
		return
	visual = Models.instance(class_data.get("model", ""), MODEL_HEIGHT, class_data.get("tint", Color.WHITE))
	if visual:
		rider.add_child(visual)
		anim = ProcAnim.new().setup(visual, MODEL_HEIGHT)
		add_child(anim)
		_build_class_prop()
		horse = _build_horse()
		horse.visible = false
		model.add_child(horse)
		return
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.4
	body_mesh.height = 1.8
	var b := Build.mesh(body_mesh, _body_color)
	_body_mat = b.material_override
	b.position.y = 0.9
	rider.add_child(b)
	# Cabeça com a cor da pele da raça
	var head := SphereMesh.new()
	head.radius = 0.26
	head.height = 0.52
	var hd := Build.mesh(head, race_data["skin"])
	hd.position.y = 1.85
	rider.add_child(hd)
	# Ombreiras exageradas (assinatura visual estilo WoW)
	for side in [-1.0, 1.0]:
		var sm := SphereMesh.new()
		sm.radius = 0.26
		sm.height = 0.4
		var s := Build.mesh(sm, Color(0.85, 0.68, 0.2))
		s.position = Vector3(0.45 * side, 1.5, 0)
		rider.add_child(s)
	_build_weapon()

	horse = _build_horse()
	horse.visible = false
	model.add_child(horse)


## Detalhe da classe por cima do modelo (o modelo já tem armadura e espada).
func _build_class_prop() -> void:
	match class_data["weapon"]:
		"bow":
			var bow := TorusMesh.new()
			bow.inner_radius = 0.5
			bow.outer_radius = 0.56
			var bw := Build.mesh(bow, Color(0.45, 0.28, 0.12))
			bw.position = Vector3(-0.15, 1.15, 0.28)
			bw.rotation = Vector3(0, PI / 2.0, PI / 2.0)
			bw.scale = Vector3(1, 1, 0.5)
			rider.add_child(bw)
		"orb":
			var orb := SphereMesh.new()
			orb.radius = 0.14
			orb.height = 0.28
			var o := Build.mesh(orb, Color(0.6, 0.2, 0.9), 4.0)
			o.position = Vector3(0.55, 1.35, -0.2)
			rider.add_child(o)
			FX.trail(o, Color(0.6, 0.2, 0.9), 0.25, 16, 0.5, false)
		"staff":
			var orb := SphereMesh.new()
			orb.radius = 0.12
			orb.height = 0.24
			var o := Build.mesh(orb, Color(1.0, 0.55, 0.15), 4.0)
			o.position = Vector3(0.55, 1.4, -0.2)
			rider.add_child(o)
			FX.trail(o, Color(1.0, 0.5, 0.1), 0.25, 16, 0.5, false)


func _build_weapon() -> void:
	match class_data["weapon"]:
		"sword_shield":
			var blade := BoxMesh.new()
			blade.size = Vector3(0.1, 0.1, 1.3)
			var bl := Build.mesh(blade, Color(0.8, 0.82, 0.9))
			bl.position = Vector3(0.45, 1.0, -0.6)
			rider.add_child(bl)
			var shield := CylinderMesh.new()
			shield.top_radius = 0.45
			shield.bottom_radius = 0.45
			shield.height = 0.1
			var sh := Build.mesh(shield, Color(0.55, 0.35, 0.15))
			sh.position = Vector3(-0.5, 1.05, -0.25)
			sh.rotation = Vector3(PI / 2.0, 0, 0)
			rider.add_child(sh)
		"bow":
			var bow := TorusMesh.new()
			bow.inner_radius = 0.5
			bow.outer_radius = 0.56
			var bw := Build.mesh(bow, Color(0.45, 0.28, 0.12))
			bw.position = Vector3(0.45, 1.1, -0.35)
			bw.rotation = Vector3(0, 0, PI / 2.0)
			bw.scale = Vector3(1, 1, 0.5)
			rider.add_child(bw)
		"orb":
			var orb := SphereMesh.new()
			orb.radius = 0.18
			orb.height = 0.36
			var o := Build.mesh(orb, Color(0.6, 0.2, 0.9), 3.0)
			o.position = Vector3(0.45, 1.2, -0.5)
			rider.add_child(o)
		_:
			var staff := BoxMesh.new()
			staff.size = Vector3(0.08, 0.08, 1.1)
			var st := Build.mesh(staff, Color(0.45, 0.28, 0.14))
			st.position = Vector3(0.38, 1.1, -0.45)
			rider.add_child(st)
			var gem := SphereMesh.new()
			gem.radius = 0.12
			gem.height = 0.24
			var g := Build.mesh(gem, Color(1.0, 0.45, 0.1), 3.0)
			g.position = Vector3(0.38, 1.1, -1.0)
			rider.add_child(g)


## Montaria: Warhorse (modelo animado). Sem o arquivo, usa o cavalo de blocos.
func _build_horse() -> Node3D:
	var wh := Models.instance("warhorse", 2.0)
	if wh:
		var aps := wh.find_children("*", "AnimationPlayer", true, false)
		if not aps.is_empty():
			horse_anim = aps[0]
			for n in horse_anim.get_animation_list():
				if n != "rear":
					horse_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
			horse_anim.play("idle")
		return wh
	return _build_block_horse()


func _build_block_horse() -> Node3D:
	var h := Node3D.new()
	var coat := Color(0.86, 0.84, 0.82)
	var steel := Color(0.72, 0.74, 0.82)
	var trim := Color(0.85, 0.65, 0.25)
	var cloth := Color(0.45, 0.2, 0.55)
	var body := CapsuleMesh.new()
	body.radius = 0.45
	body.height = 2.1
	var bm := Build.mesh(body, coat)
	bm.position.y = 1.15
	bm.rotation.x = PI / 2.0
	h.add_child(bm)
	# Manta (barding) de pano com borda dourada
	var blanket := BoxMesh.new()
	blanket.size = Vector3(1.0, 0.55, 1.3)
	var bl := Build.mesh(blanket, cloth)
	bl.position = Vector3(0, 1.05, 0.15)
	h.add_child(bl)
	var edge := BoxMesh.new()
	edge.size = Vector3(1.04, 0.08, 1.34)
	var ed := Build.mesh(edge, trim)
	ed.position = Vector3(0, 0.78, 0.15)
	h.add_child(ed)
	# Sela
	var saddle := BoxMesh.new()
	saddle.size = Vector3(0.6, 0.18, 0.7)
	var sd := Build.mesh(saddle, Color(0.35, 0.18, 0.1))
	sd.position = Vector3(0, 1.62, 0.05)
	h.add_child(sd)
	# Pescoço com placas de aço
	var neck := CylinderMesh.new()
	neck.top_radius = 0.2
	neck.bottom_radius = 0.3
	neck.height = 1.0
	var nm := Build.mesh(neck, steel)
	nm.position = Vector3(0, 1.75, -0.95)
	nm.rotation.x = -0.6
	h.add_child(nm)
	var head := BoxMesh.new()
	head.size = Vector3(0.32, 0.35, 0.75)
	var hm := Build.mesh(head, steel)
	hm.position = Vector3(0, 2.15, -1.4)
	hm.rotation.x = 0.35
	h.add_child(hm)
	# Chifre/ornamento da armadura da cabeça
	var spike := CylinderMesh.new()
	spike.top_radius = 0.0
	spike.bottom_radius = 0.07
	spike.height = 0.35
	var sp := Build.mesh(spike, trim)
	sp.position = Vector3(0, 2.4, -1.55)
	sp.rotation.x = -0.4
	h.add_child(sp)
	# Crina e rabo
	var mane := BoxMesh.new()
	mane.size = Vector3(0.1, 0.25, 0.8)
	var mn := Build.mesh(mane, Color(0.2, 0.15, 0.12))
	mn.position = Vector3(0, 2.05, -0.9)
	mn.rotation.x = -0.6
	h.add_child(mn)
	var tail := CylinderMesh.new()
	tail.top_radius = 0.08
	tail.bottom_radius = 0.03
	tail.height = 0.8
	var tl := Build.mesh(tail, Color(0.2, 0.15, 0.12))
	tl.position = Vector3(0, 1.0, 1.25)
	tl.rotation.x = 0.5
	h.add_child(tl)
	for x in [-0.25, 0.25]:
		for z in [-0.7, 0.7]:
			var leg := CylinderMesh.new()
			leg.top_radius = 0.1
			leg.bottom_radius = 0.07
			leg.height = 0.85
			var lm := Build.mesh(leg, coat.darkened(0.1))
			lm.position = Vector3(x, 0.42, z)
			h.add_child(lm)
			var hoof := CylinderMesh.new()
			hoof.top_radius = 0.09
			hoof.bottom_radius = 0.1
			hoof.height = 0.12
			var hf := Build.mesh(hoof, steel.darkened(0.3))
			hf.position = Vector3(x, 0.06, z)
			h.add_child(hf)
	return h


func _build_camera() -> void:
	cam_pivot = Node3D.new()
	cam_pivot.top_level = true
	add_child(cam_pivot)
	spring = SpringArm3D.new()
	spring.spring_length = cam_distance
	spring.margin = 0.3
	var sphere := SphereShape3D.new()
	sphere.radius = 0.25
	spring.shape = sphere
	spring.add_excluded_object(get_rid())
	cam_pivot.add_child(spring)
	camera = Camera3D.new()
	camera.fov = 70.0
	camera.far = 500.0
	spring.add_child(camera)
	camera.make_current()


# --- Entrada ------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if input_locked:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			mouse_look = mb.pressed
			_update_mouse_mode()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			cam_distance = maxf(2.5, cam_distance - 0.8)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			cam_distance = minf(16.0, cam_distance + 0.8)
	elif event is InputEventMouseMotion and (mouse_look or mouse_locked):
		var mm := event as InputEventMouseMotion
		cam_yaw -= mm.relative.x * 0.004
		cam_pitch = clampf(cam_pitch - mm.relative.y * 0.004, -1.3, 0.5)
	elif event.is_action_pressed("toggle_mouse_lock"):
		mouse_locked = not mouse_locked
		_update_mouse_mode()
		Game.show_toast("Mouse travado (modo action)" if mouse_locked else "Mouse livre")


func _update_mouse_mode() -> void:
	var capture := (mouse_look or mouse_locked) and not input_locked
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE


func set_input_locked(v: bool) -> void:
	input_locked = v
	mouse_look = false
	_update_mouse_mode()


# --- Loop -----------------------------------------------------------------------

func _process(delta: float) -> void:
	var cam_height := 1.7 + (0.9 if mounted else 0.0)
	cam_pivot.global_position = global_position + Vector3(0, cam_height, 0)
	cam_pivot.rotation = Vector3(cam_pitch, cam_yaw, 0)
	if _shake_t > 0.0:
		_shake_t -= get_process_delta_time()
		cam_pivot.rotation += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake_amp * 0.15
		if _shake_t <= 0.0:
			_shake_amp = 0.0
	spring.spring_length = lerpf(spring.spring_length, cam_distance, 10.0 * delta)
	if _flash_t > 0.0:
		_flash_t -= delta
		if _body_mat:
			_body_mat.albedo_color = Color(1, 0.3, 0.3) if _flash_t > 0.0 else _body_color


func _physics_process(delta: float) -> void:
	if dead:
		return
	for k in cooldowns.keys():
		cooldowns[k] = maxf(0.0, cooldowns[k] - delta)
	_face_attack_t = maxf(0.0, _face_attack_t - delta)
	_potion_cd = maxf(0.0, _potion_cd - delta)
	if shield_t > 0.0:
		shield_t -= delta
		if shield_t <= 0.0 and _shield_fx:
			_shield_fx.queue_free()
			_shield_fx = null

	if not is_on_floor():
		velocity.y -= gravity * delta

	var input := Vector2.ZERO
	if not input_locked:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Basis(Vector3.UP, cam_yaw) * Vector3(input.x, 0, input.y)
	if dir.length() > 1.0:
		dir = dir.normalized()

	# Invocar cavalo: 1,5 s parado; mexer cancela.
	if mount_cast >= 0.0:
		if input != Vector2.ZERO:
			_cancel_mount("Montaria cancelada (você se moveu)")
		else:
			mount_cast += delta
			if mount_cast >= MOUNT_CAST_TIME:
				_set_mounted(true)

	var speed: float = MOUNT_SPEED if mounted else WALK_SPEED * float(mods["move_speed"])
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	if not input_locked:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		if Input.is_action_just_pressed("attack"):
			try_ability("basic")
		if Input.is_action_just_pressed("ability_1"):
			try_ability("a1")
		if Input.is_action_just_pressed("ability_2"):
			try_ability("a2")
		if Input.is_action_just_pressed("mount"):
			toggle_mount()
		if Input.is_action_just_pressed("interact"):
			_try_interact()
		if Input.is_action_just_pressed("use_potion"):
			use_potion()

	move_and_slide()
	var hs := Vector2(velocity.x, velocity.z).length()
	if anim:
		anim.set_moving(0.0 if mounted else hs / WALK_SPEED)
	if rig:
		var local := model.global_transform.basis.inverse() * Vector3(velocity.x, 0, velocity.z)
		rig.set_locomotion(Vector2(local.x, -local.z), 0.0 if mounted else hs, delta)
	if horse.visible:
		if horse_anim:
			var want := "idle" if hs < 0.5 else ("canter" if hs > 9.0 else "walk")
			if horse_anim.current_animation != want and horse_anim.current_animation != "rear":
				horse_anim.play(want, 0.2)
			horse_anim.speed_scale = 1.0 if hs < 0.5 else clampf(hs / (12.0 if want == "canter" else 4.0), 0.6, 1.6)
		else:
			var hv := hs / MOUNT_SPEED
			horse.position.y = absf(sin(Time.get_ticks_msec() * 0.012)) * 0.15 * hv
			rider.position.y = 0.95 + horse.position.y
	_update_resource(delta)

	# Virar o personagem: para onde a câmera olha (mirando) ou para onde anda.
	var target_yaw := model.rotation.y
	if mouse_look or mouse_locked or _face_attack_t > 0.0:
		target_yaw = cam_yaw
	elif dir.length() > 0.1:
		target_yaw = atan2(-dir.x, -dir.z)
	model.rotation.y = lerp_angle(model.rotation.y, target_yaw, 12.0 * delta)


# --- Habilidades -------------------------------------------------------------

func aim_dir() -> Vector3:
	return Vector3(-sin(cam_yaw), 0, -cos(cam_yaw))


func is_unlocked(id: String) -> bool:
	return level >= int(abilities[id]["unlock"])


func cooldown_of(id: String) -> float:
	var cd: float = abilities[id]["cooldown"]
	if id == "a1":
		cd *= float(mods["a1_cd"])
	elif id == "a2":
		cd *= float(mods["a2_cd"])
	return cd


func current_damage_mult() -> float:
	var m := damage_mult
	if mods["berserk"] and hp < max_hp * 0.5:
		m *= 1.4
	return m


func try_ability(id: String) -> bool:
	if dead or input_locked:
		return false
	if mounted:
		Game.show_toast("Desmonte (F) para atacar")
		return false
	if mount_cast >= 0.0:
		_cancel_mount("Montaria cancelada")
	if not is_unlocked(id):
		Game.show_toast("%s destrava no nível %d" % [abilities[id]["name"], abilities[id]["unlock"]])
		return false
	if cooldowns[id] > 0.0:
		return false
	var cost := float(class_data.get("costs", {}).get(id, 0))
	if res < cost:
		Game.show_toast("%s insuficiente" % ClassData.RESOURCES[res_type]["name"])
		return false
	res -= cost
	_combat_t = 5.0
	cooldowns[id] = cooldown_of(id)
	_face_attack_t = 0.35
	if anim:
		anim.attack()
	if rig:
		var clip: String = class_data.get("anims", {}).get(id, "attack_1h")
		if not rig.anim.has_animation(clip):
			clip = "attack_cast" if rig.anim.has_animation("attack_cast") else "attack_1h"
		rig.play_once(clip, 1.3)
	model.rotation.y = cam_yaw
	# brilho na mão ao lançar (magias e flechas)
	if class_id != "guerreiro":
		var hand_col: Color = {"mago": Color(1.0, 0.55, 0.15), "bruxo": Color(0.65, 0.25, 1.0), "cacador": Color(0.6, 0.9, 1.0)}.get(class_id, Color.WHITE)
		FX.vfx(get_parent(), "hit2", global_position + Vector3(0, 1.4, 0) + aim_dir() * 0.8, 0.35, 0.6, Vector3.ZERO, hand_col)
	match class_id:
		"guerreiro":
			match id:
				"basic": _sword_slash()
				"a1": _charge()
				"a2": _shield_wall()
		"cacador":
			match id:
				"basic": _shoot(Color(0.85, 0.75, 0.5), 13.0, 40.0)
				"a1": _arrow_rain()
				"a2": _evasive_leap()
		"bruxo":
			match id:
				"basic": _shoot(Color(0.6, 0.2, 0.9), 12.0, 28.0)
				"a1": _summon_spirits()
				"a2": _soul_drain()
		_:
			match id:
				"basic": _shoot(Color(1.0, 0.45, 0.1), 14.0, 30.0)
				"a1": _frost_nova()
				"a2": _blink()
	return true


func _enemies_in_radius(center: Vector3, radius: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy and enemy.hp > 0.0 and enemy.global_position.distance_to(center) <= radius:
			out.append(enemy)
	return out


## Projétil genérico (Bola de Fogo, Flecha, Raio Sombrio)
func _shoot(color: Color, base_dmg: float, speed: float) -> void:
	var angles := [0.0]
	if mods["spread"]:
		angles = [-0.22, 0.0, 0.22]
	for a in angles:
		var p := Projectile.new()
		p.color = color
		p.direction = aim_dir().rotated(Vector3.UP, a)
		p.damage = base_dmg * current_damage_mult() * float(mods["basic_dmg"])
		p.speed = speed * float(mods["proj_speed"])
		p.lifetime = 1.4 * float(mods["proj_speed"])
		p.explode_radius = 3.0 if mods["explode"] else 0.0
		p.pierce = mods["pierce"]
		p.small = class_id == "cacador"
		p.vfx_id = {"mago": "proj_fire", "bruxo": "proj_shadow", "cacador": "proj_arrow"}.get(class_id, "")
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(0, 1.2, 0) + aim_dir() * 0.9


# Mago
func _frost_nova() -> void:
	var radius := 6.5 * float(mods["a1_radius"])
	for enemy in _enemies_in_radius(global_position, radius):
		enemy.take_damage(24.0 * current_damage_mult())
		enemy.apply_slow(2.5)
	_spawn_ring(radius, Color(0.5, 0.85, 1.0))
	FX.ring(get_parent(), global_position, Color(0.55, 0.85, 1.0), radius)
	FX.burst(get_parent(), global_position + Vector3(0, 1, 0), Color(0.7, 0.9, 1.0), 30, 9.0, 0.4, 0.5)
	FX.vfx(get_parent(), "ground_explosion", global_position, radius / 4.0, 1.6, Vector3.ZERO, Color(0.4, 0.75, 1.0))
	shake(0.2, 0.2)


func _blink() -> void:
	var from := global_position + Vector3(0, 1.0, 0)
	var to := from + aim_dir() * 9.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		to = hit["position"] - aim_dir() * 0.7
	_spawn_ring(1.5, Color(0.8, 0.5, 1.0))
	FX.burst(get_parent(), global_position + Vector3(0, 1, 0), Color(0.8, 0.5, 1.0), 26, 4.0, 0.5, 0.5)
	global_position = Vector3(to.x, global_position.y, to.z)
	FX.burst(get_parent(), global_position + Vector3(0, 1, 0), Color(0.8, 0.5, 1.0), 26, 4.0, 0.5, 0.5)
	if mods["blink_blast"]:
		for enemy in _enemies_in_radius(global_position, 5.0):
			enemy.take_damage(30.0 * current_damage_mult())
		_spawn_ring(5.0, Color(0.8, 0.4, 1.0))
	else:
		_spawn_ring(1.5, Color(0.8, 0.5, 1.0))


# Guerreiro
func _sword_slash() -> void:
	var reach := 3.2 * float(mods["melee_range"])
	var hits := 0
	for enemy in _enemies_in_radius(global_position, reach + 0.6):
		var to_e := enemy.global_position - global_position
		to_e.y = 0.0
		if to_e.length() < 0.5 or aim_dir().angle_to(to_e.normalized()) < deg_to_rad(65):
			enemy.take_damage(20.0 * current_damage_mult() * float(mods["basic_dmg"]))
			hits += 1
	FX.burst(get_parent(), global_position + Vector3(0, 1.1, 0) + aim_dir() * reach * 0.6, Color(1.0, 0.85, 0.6), 14, 6.0, 0.35, 0.35)
	FX.vfx(get_parent(), "slash", global_position + Vector3(0, 1.1, 0) + aim_dir() * 1.2, 1.6, 0.8, aim_dir())
	FX.vfx(get_parent(), "swing", global_position + Vector3(0, 1.0, 0), 1.4, 0.8, aim_dir())
	if hits > 0:
		shake(0.1, 0.12)
	if hits > 0 and res_type == "furia":
		gain_resource(8.0 * hits)
	if hits > 0 and mods["melee_heal"] > 0.0:
		hp = minf(max_hp, hp + float(mods["melee_heal"]) * hits)
	var arc := TorusMesh.new()
	arc.inner_radius = reach * 0.85
	arc.outer_radius = reach
	var fx := Build.mesh(arc, Color(0.9, 0.9, 1.0), 1.5, 0.5)
	get_parent().add_child(fx)
	fx.global_position = global_position + Vector3(0, 1.0, 0)
	fx.scale = Vector3(1, 0.05, 1)
	var tw := fx.create_tween()
	tw.tween_property(fx, "transparency", 1.0, 0.15)
	tw.tween_callback(fx.queue_free)


func _charge() -> void:
	var dist := 10.0
	var from := global_position + Vector3(0, 1.0, 0)
	var to := from + aim_dir() * dist
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		to = hit["position"] - aim_dir() * 0.7
	var start := global_position
	var end := Vector3(to.x, global_position.y, to.z)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var en := enemy as Enemy
		if en == null or en.hp <= 0.0:
			continue
		var closest := Geometry3D.get_closest_point_to_segment(en.global_position, start, end)
		if closest.distance_to(en.global_position) < 2.5:
			en.take_damage(22.0 * current_damage_mult() * float(mods["a1_dmg"]))
			en.apply_slow(1.5)
	FX.burst(get_parent(), global_position + Vector3(0, 0.4, 0), Color(0.75, 0.6, 0.4), 20, 4.0, 0.8, 0.6)
	FX.vfx(get_parent(), "charge", global_position + Vector3(0, 1.0, 0), 1.0, 1.0, aim_dir())
	global_position = end
	FX.vfx(get_parent(), "impact", global_position + Vector3(0, 0.3, 0), 1.5, 1.2)
	shake(0.25, 0.25)
	_spawn_ring(2.5, Color(0.9, 0.5, 0.2))
	FX.ring(get_parent(), global_position, Color(1.0, 0.6, 0.25), 2.5)


func _shield_wall() -> void:
	shield_t = 4.0 + float(mods["shield_dur"])
	for enemy in _enemies_in_radius(global_position, 4.0):
		enemy.take_damage(10.0 * current_damage_mult() * float(mods["shield_dmg"]))
		var push := enemy.global_position - global_position
		push.y = 0.0
		enemy.global_position += push.normalized() * 3.0
	if _shield_fx:
		_shield_fx.queue_free()
	var sm := SphereMesh.new()
	sm.radius = 1.3
	sm.height = 2.6
	_shield_fx = Build.mesh(sm, Color(0.95, 0.8, 0.3), 1.0, 0.25)
	_shield_fx.position.y = 1.0
	add_child(_shield_fx)
	FX.burst(get_parent(), global_position + Vector3(0, 1, 0), Color(1.0, 0.85, 0.3), 30, 5.0, 0.5, 0.6)
	FX.vfx(self, "shield", Vector3(0, 1.0, 0), 1.2, shield_t)
	Game.show_toast("Muralha de Escudo: -70%% de dano por %.0f s" % shield_t)


# Caçador
func _arrow_rain() -> void:
	var center := global_position + aim_dir() * 10.0
	var radius := 5.0 * float(mods["a1_radius"])
	for enemy in _enemies_in_radius(center, radius):
		enemy.take_damage(26.0 * current_damage_mult())
	var ring := CylinderMesh.new()
	ring.top_radius = radius
	ring.bottom_radius = radius
	ring.height = 0.2
	var fx := Build.mesh(ring, Color(0.9, 0.85, 0.5), 1.5, 0.45)
	get_parent().add_child(fx)
	fx.global_position = center + Vector3(0, 0.2, 0)
	FX.ring(get_parent(), center, Color(1.0, 0.9, 0.55), radius)
	FX.vfx(get_parent(), "ground_explosion", center, radius / 4.0, 1.6, Vector3.ZERO, Color(1.0, 0.85, 0.5))
	for k in 6:
		var off := Vector3(randf_range(-radius, radius), 0, randf_range(-radius, radius)) * 0.7
		FX.vfx(get_parent(), "proj_arrow", center + off + Vector3(0, 7, 0), 0.7, 0.5, Vector3.DOWN)
	for i in 8:
		var off := Vector3(randf_range(-radius, radius), 0, randf_range(-radius, radius)) * 0.7
		FX.burst(get_parent(), center + off + Vector3(0, 0.3, 0), Color(1.0, 0.9, 0.6), 6, 3.0, 0.3, 0.4)
	var tw := fx.create_tween()
	tw.tween_property(fx, "transparency", 1.0, 0.5)
	tw.tween_callback(fx.queue_free)


func _evasive_leap() -> void:
	for enemy in _enemies_in_radius(global_position, 5.0):
		enemy.apply_slow(3.0)
	FX.burst(get_parent(), global_position + Vector3(0, 0.5, 0), Color(0.55, 1.0, 0.45), 30, 6.0, 0.5, 0.5)
	_spawn_ring(5.0, Color(0.5, 0.9, 0.4))
	var from := global_position + Vector3(0, 1.0, 0)
	var to := from - aim_dir() * 8.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		to = hit["position"] + aim_dir() * 0.7
	global_position = Vector3(to.x, global_position.y, to.z)
	velocity.y = 4.0


## Tremor curto de câmera (golpes fortes, explosões).
var _shake_t := 0.0
var _shake_amp := 0.0


func shake(amp := 0.12, dur := 0.18) -> void:
	_shake_amp = maxf(_shake_amp, amp)
	_shake_t = maxf(_shake_t, dur)


func _summon_pet() -> void:
	var a := Ally.new()
	a.kind = "pet"
	a.display_name = class_data.get("pet", race_data["pet"])
	a.color = race_data["pet_color"]
	a.size = race_data["pet_size"]
	a.damage = 9.0 * damage_mult * float(mods["pet_dmg"])
	a.follow_offset = Vector3(2.0 if pets.is_empty() else -2.0, 0, 1.5)
	get_parent().add_child(a)
	a.global_position = global_position + a.follow_offset
	pets.append(a)


# Bruxo
func _summon_spirits() -> void:
	for i in int(mods["spirit_count"]):
		var a := Ally.new()
		a.kind = "spirit"
		a.display_name = "Espírito"
		a.color = Color(0.45, 0.95, 0.8)
		a.damage = 12.0 * current_damage_mult() * float(mods["spirit_dmg"])
		a.speed = 10.0
		a.lifetime = 15.0 + float(mods["spirit_dur"])
		a.follow_offset = Vector3(1.8 * (1 if i == 0 else -1), 0, 1.0)
		get_parent().add_child(a)
		a.global_position = global_position + a.follow_offset + Vector3(0, 1, 0)
		FX.burst(get_parent(), a.global_position + Vector3(0, 1, 0), Color(0.45, 1.0, 0.85), 30, 5.0, 0.5, 0.7)
	Game.show_toast("Um espírito atende ao seu chamado")


func _soul_drain() -> void:
	var radius := 7.0 * float(mods["a2_radius"])
	var total := 0.0
	for enemy in _enemies_in_radius(global_position, radius):
		var dmg := 16.0 * current_damage_mult()
		enemy.take_damage(dmg)
		total += dmg
	hp = minf(max_hp, hp + total * float(mods["drain_heal"]))
	_spawn_ring(radius, Color(0.4, 0.95, 0.7))
	FX.ring(get_parent(), global_position, Color(0.45, 1.0, 0.7), radius)
	FX.vfx(get_parent(), "proj_wave", global_position + Vector3(0, 1, 0), 1.0, 1.0, aim_dir())
	for enemy in _enemies_in_radius(global_position, radius):
		FX.burst(get_parent(), enemy.global_position + Vector3(0, 1.2, 0), Color(0.5, 1.0, 0.6), 10, 2.0, 0.4, 0.5)
	if total > 0.0:
		FX.number(get_parent(), global_position + Vector3(0, 2.4, 0), "+%d" % roundi(total * float(mods["drain_heal"])), Color(0.4, 1.0, 0.5))


func _spawn_ring(radius: float, color: Color) -> void:
	var ring := CylinderMesh.new()
	ring.top_radius = 1.0
	ring.bottom_radius = 1.0
	ring.height = 0.15
	var mi := Build.mesh(ring, color, 2.0, 0.55)
	get_parent().add_child(mi)
	mi.global_position = global_position + Vector3(0, 0.2, 0)
	mi.scale = Vector3(0.2, 1, 0.2)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(radius, 1, radius), 0.25)
	tw.tween_property(mi, "transparency", 1.0, 0.25)
	tw.tween_callback(mi.queue_free)


# --- Montaria ----------------------------------------------------------------

func toggle_mount() -> void:
	if mounted:
		_set_mounted(false)
		return
	if not can_mount:
		Game.show_toast("Não é possível montar aqui")
		return
	if mount_cast < 0.0:
		mount_cast = 0.0


func _set_mounted(v: bool) -> void:
	mounted = v
	mount_cast = -1.0
	horse.visible = v
	# na sela do Warhorse (a 1,67 m); o cavalo de blocos é mais baixo
	var seat := 1.25
	if rig and rig.family != "dwarf":
		seat = 1.08  # pose sentada: o quadril fica na sela
	rider.position.y = (seat if horse_anim else 0.95) if v else 0.0
	if v and horse_anim:
		horse_anim.play("rear")
		horse_anim.queue("idle")
	if rig:
		rig.riding = v
		rig.anim.play("idle")


func _cancel_mount(msg: String) -> void:
	mount_cast = -1.0
	Game.show_toast(msg)


# --- Vida, XP, loot ---------------------------------------------------------

func take_damage(amount: float) -> void:
	if dead:
		return
	if shield_t > 0.0:
		amount *= 0.3
	hp -= amount
	_flash_t = 0.12
	if anim:
		anim.hit()
	if rig:
		rig.hit()
	_combat_t = 5.0
	if res_type == "furia":
		gain_resource(amount * 0.6)
	FX.number(get_parent(), global_position + Vector3(0, 2.2, 0), "-%d" % roundi(amount), Color(1.0, 0.3, 0.25), 44)
	if mounted:
		_set_mounted(false)
		Game.show_toast("Você foi derrubado do cavalo!")
	if mount_cast >= 0.0:
		_cancel_mount("Montaria interrompida")
	if hp <= 0.0:
		hp = 0.0
		dead = true
		if rig:
			rig.die()
		Game.log_event("Você morreu.", Game.LOG_HURT)
		died.emit()


func add_xp(amount: int) -> void:
	xp += amount
	Game.log_event("Você ganha %d de experiência." % amount, Game.LOG_XP)
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = int(10 * pow(1.35, level - 1))
		max_hp += 15.0
		hp = max_hp
		damage_mult += 0.12
		Game.show_toast("Nível %d na partida! (+vida, +dano)" % level)
		Game.log_event("Você subiu para o nível %d!" % level, Game.LOG_QUEST)
		res = res_max if res_type != "furia" else res
		FX.pillar(get_parent(), global_position, Color(1.0, 0.85, 0.35))
		leveled_up.emit(level)


func collect(p: Pickup) -> void:
	match p.kind:
		"xp":
			add_xp(p.amount)
			if mods["xp_heal"] > 0.0:
				hp = minf(max_hp, hp + float(mods["xp_heal"]))
		"gold":
			add_gold(p.amount)
		"material":
			add_material(p.material_id, p.amount)


func add_gold(amount: int) -> void:
	run_gold += amount
	Game.log_event("Você recebe %d de ouro." % amount, Game.LOG_LOOT)
	FX.number(get_parent(), global_position + Vector3(0, 2.0, 0), "+%d ouro" % amount, Color(1.0, 0.85, 0.3), 36)


func add_material(id: String, amount := 1) -> void:
	run_materials[id] = int(run_materials.get(id, 0)) + amount
	Game.show_toast("+%d %s" % [amount, Game.MATERIALS.get(id, id)])
	Game.log_event("Você recebe: [%s] x%d." % [Game.MATERIALS.get(id, id), amount], Game.LOG_LOOT)


func use_potion() -> void:
	if dead or _potion_cd > 0.0:
		return
	if Game.potions <= 0:
		Game.show_toast("Sem poções. Compre na loja da cidade.")
		return
	Game.potions -= 1
	Game.save_game()
	_potion_cd = 8.0
	hp = minf(max_hp, hp + max_hp * 0.5)
	_spawn_ring(1.2, Color(1.0, 0.3, 0.4))
	FX.burst(get_parent(), global_position + Vector3(0, 1, 0), Color(1.0, 0.35, 0.45), 30, 3.0, 0.4, 0.8, 3.0)
	Game.show_toast("Poção de Vida (+50%%) — restam %d" % Game.potions)


## Aplica o efeito de uma carta do deck da classe.
func apply_card(card_id: String) -> void:
	chosen_cards.append(card_id)
	match card_id:
		# Mago
		"brasa_viva", "lamina_afiada", "ponta_aco", "sombra_densa":
			mods["basic_dmg"] *= 1.35
		"leque_chamas", "tiro_triplo", "rajada_sombria":
			mods["spread"] = true
		"combustao", "explosao_sombria":
			mods["explode"] = true
		"inverno_eterno", "chuva_intensa":
			mods["a1_radius"] *= 1.45 if card_id == "inverno_eterno" else 1.4
		"coracao_gelo", "passos_trovao", "aljava_rapida":
			mods["a1_cd"] *= 0.6
		"passo_arcano", "passo_leve":
			mods["a2_cd"] *= 0.55
		"pacto_sombrio":
			mods["a2_cd"] *= 0.6
		"ruptura":
			mods["blink_blast"] = true
		"sede_arcana":
			mods["xp_heal"] += 3.0
		"celeridade":
			mods["move_speed"] *= 1.18
		"vigor":
			mods["move_speed"] *= 1.15
		"pele_geada", "vigor_selvagem", "carapaca_ossos":
			max_hp += 40.0
			hp += 40.0
		"pele_ferro":
			max_hp += 50.0
			hp += 50.0
		# Guerreiro
		"golpe_amplo":
			mods["melee_range"] *= 1.4
		"sede_sangue":
			mods["melee_heal"] += 3.0
		"investida_brutal":
			mods["a1_dmg"] *= 1.6
		"escudo_espinhos":
			mods["shield_dmg"] *= 3.0
		"bastiao":
			mods["shield_dur"] += 2.0
		"furia_berserker":
			mods["berserk"] = true
		# Caçador
		"flecha_perfurante":
			mods["pierce"] = true
		"olhos_aguia":
			mods["proj_speed"] *= 1.4
		"instinto_feral":
			mods["pet_dmg"] *= 1.6
			for p in pets:
				if is_instance_valid(p):
					p.damage *= 1.6
		"matilha":
			_summon_pet()
		# Bruxo
		"espirito_ancestral":
			mods["spirit_dur"] += 10.0
		"legiao":
			mods["spirit_count"] = 2
		"furia_espectral":
			mods["spirit_dmg"] *= 1.6
		"fome_almas":
			mods["drain_heal"] = 1.0
		"colheita":
			mods["a2_radius"] *= 1.4


# --- Interação ----------------------------------------------------------------

func nearest_interactable() -> Node3D:
	var best: Node3D = null
	var best_d := INTERACT_RANGE
	for n in get_tree().get_nodes_in_group("interactable"):
		var node := n as Node3D
		var d := node.global_position.distance_to(global_position)
		if d < best_d:
			best = node
			best_d = d
	return best


func _try_interact() -> void:
	var target := nearest_interactable()
	if target:
		target.call("interact", self)


# --- Recurso -------------------------------------------------------------------

func gain_resource(amount: float) -> void:
	res = clampf(res + amount, 0.0, res_max)


func in_combat() -> bool:
	return _combat_t > 0.0


func _update_resource(delta: float) -> void:
	_combat_t = maxf(0.0, _combat_t - delta)
	if res_type == "furia":
		# a fúria só cai fora de combate
		if _combat_t <= 0.0:
			res = maxf(0.0, res + _res_regen * delta)
	else:
		res = minf(res_max, res + _res_regen * delta)
