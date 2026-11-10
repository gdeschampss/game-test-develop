class_name Enemy
extends CharacterBody3D
## Mob genérico: fica parado até ver o jogador, persegue e ataca corpo a corpo.
## Os dados (vida, dano, cor...) vêm do bioma em field.gd.

signal killed(enemy: Enemy)

var display_name := "Mob"
var max_hp := 30.0
var hp := 30.0
var damage := 6.0
var speed := 4.5
var xp_reward := 3
var gold_range := Vector2i(1, 2)
var material_id := ""
var material_chance := 0.0
var guaranteed_drops := {}  ## bosses: material -> quantidade
var color := Color.GRAY
var size := 1.0
var is_boss := false
var aggro_range := 18.0  ## mobs agressivos: avançam em quem passa perto
const SOCIAL_RANGE := 10.0  ## mobs perto de um que entrou em combate vêm junto
const GIVE_UP_RANGE := 50.0  ## longe disso do "lar", o mob desiste e volta
var _wander_t := 0.0
var _wander_goal := Vector3.ZERO
var _returning := false
var attack_cd := 1.2
## Boss: se o jogador fugir para longe do covil por alguns segundos, o boss reseta.
var leash_range := 0.0
var home := Vector3.ZERO
var _leash_t := 0.0
var _home_set := false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _attack_t := 0.0
var _slow_t := 0.0
var _flash_t := 0.0
var _aggro := false
var _player: Player
var _mat: StandardMaterial3D
var _label: Label3D
var model_id := ""
var model_height := 0.0
var model_tint := Color.WHITE
var anim: ProcAnim
var rig: CharacterRig
var level := 1
var rig_kind := ""
var rig_palette := "inimigo"
var rig_weapon := ""
var _dying := false
var _bar_fill: QuadMesh
var _bar_root: Node3D
const BAR_W := 1.4


## data: name, hp, dmg, speed, xp, mana, color, size, boss
func setup(data: Dictionary, hp_mult: float, dmg_mult: float) -> Enemy:
	display_name = data.get("name", "Mob")
	max_hp = float(data.get("hp", 30)) * hp_mult
	hp = max_hp
	damage = float(data.get("dmg", 6)) * dmg_mult
	speed = float(data.get("speed", 4.5))
	xp_reward = int(data.get("xp", 3))
	var g: Array = data.get("gold", [1, 2])
	gold_range = Vector2i(int(g[0]), int(g[1]))
	material_id = data.get("mat", "")
	material_chance = float(data.get("mat_chance", 0.0))
	guaranteed_drops = data.get("drops", {})
	color = data.get("color", Color.GRAY)
	size = float(data.get("size", 1.0))
	is_boss = bool(data.get("boss", false))
	model_id = data.get("model", "")
	var lv: Array = data.get("level", [1, 1])
	level = randi_range(int(lv[0]), int(lv[1]))
	rig_kind = data.get("rig", "")
	rig_palette = data.get("palette", "inimigo")
	rig_weapon = data.get("weapon", "")
	model_height = float(data.get("model_h", 1.6 * size))
	model_tint = data.get("tint", Color.WHITE)
	if is_boss:
		aggro_range = 22.0
		leash_range = 55.0
	return self


func _ready() -> void:
	add_to_group("enemies")
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45 * size
	cap.height = 1.6 * size
	cs.shape = cap
	cs.position.y = 0.8 * size
	add_child(cs)

	var top := 1.6 * size
	var visual: Node3D = null
	if rig_kind != "" and CharacterRig.available(rig_kind):
		var colors: Dictionary = CharacterRig.PALETTES.get(rig_palette, CharacterRig.PALETTES["inimigo"]).duplicate()
		colors["skin"] = model_tint if model_tint != Color.WHITE else CharacterRig.SKINS["anao"]
		rig = CharacterRig.make(rig_kind, model_height, Color.WHITE, colors)
		if rig_weapon != "":
			rig._weapon(rig_weapon, "hand_r", 0.9)
		add_child(rig)
		top = model_height
	elif model_id != "":
		visual = Models.instance(model_id, model_height, model_tint)
	if rig:
		pass
	elif visual:
		add_child(visual)
		anim = ProcAnim.new().setup(visual, model_height)
		add_child(anim)
		top = model_height
	else:
		var bm := CapsuleMesh.new()
		bm.radius = 0.45 * size
		bm.height = 1.6 * size
		var body := Build.mesh(bm, color)
		_mat = body.material_override
		body.position.y = 0.8 * size
		add_child(body)
		# "Olhos" para indicar a frente
		var eye := BoxMesh.new()
		eye.size = Vector3(0.5, 0.1, 0.1) * size
		var e := Build.mesh(eye, Color(1, 0.2, 0.1), 3.0)
		e.position = Vector3(0, 1.25 * size, -0.42 * size)
		add_child(e)

	_label = Build.label(display_name, Vector3(0, top + 0.55, 0), Color(1, 0.82, 0.3) if is_boss else Color(1, 0.45, 0.4), 40 if is_boss else 26)
	add_child(_label)
	_build_bar(top + 0.25)
	_update_label()
	_player = get_tree().get_first_node_in_group("player") as Player


func is_engaged() -> bool:
	return _aggro


func _physics_process(delta: float) -> void:
	if not _home_set:
		_home_set = true
		home = global_position
	if not is_on_floor():
		velocity.y -= gravity * delta
	_attack_t = maxf(0.0, _attack_t - delta)
	_slow_t = maxf(0.0, _slow_t - delta)
	if _dying:
		return
	if _flash_t > 0.0:
		_flash_t -= delta
		if _mat:
			_mat.albedo_color = Color.WHITE if _flash_t > 0.0 else color

	velocity.x = 0.0
	velocity.z = 0.0
	if _player and not _player.dead:
		var to_p := _player.global_position - global_position
		to_p.y = 0.0
		var dist := to_p.length()
		# Longe e parado: não gasta processamento (nem anima)
		if not _aggro and dist > 70.0 and is_on_floor():
			if rig and rig.visible:
				rig.visible = false
				rig.anim.pause()
			return
		if rig and not rig.visible:
			rig.visible = true
			rig.anim.play()
		if dist < aggro_range and not _aggro and not _returning:
			_set_aggro()
		# desiste se foi puxado para muito longe (não vale para bosses: eles têm a coleira)
		if _aggro and leash_range <= 0.0 and global_position.distance_to(home) > GIVE_UP_RANGE:
			_aggro = false
			_returning = true
			_update_label()
		if leash_range > 0.0 and _aggro:
			if _player.global_position.distance_to(home) > leash_range:
				_leash_t += delta
				if _leash_t > 4.0:
					_reset_boss()
					return
			else:
				_leash_t = 0.0
		if not _aggro:
			_idle_move(delta)
		if _aggro and dist > 0.05:
			look_at(global_position + to_p, Vector3.UP)
			var reach := 1.4 + 0.45 * size
			if dist > reach:
				# em combate o mob corre um pouco mais rápido (perseguição)
				var s := speed * 1.2 * (0.45 if _slow_t > 0.0 else 1.0)
				velocity.x = to_p.normalized().x * s
				velocity.z = to_p.normalized().z * s
			elif _attack_t <= 0.0:
				_attack_t = attack_cd
				if anim:
					anim.attack()
				if rig:
					rig.play_once("attack_1h", 1.2)
				Game.log_event("%s acerta você: %d." % [display_name, roundi(damage)], Game.LOG_HURT)
				_player.take_damage(damage)
	move_and_slide()
	if anim:
		anim.set_moving(Vector2(velocity.x, velocity.z).length() / 6.0)
	if rig:
		var sp := Vector2(velocity.x, velocity.z).length()
		rig.set_locomotion(Vector2(0, 1), sp, delta)


func _set_aggro() -> void:
	if _aggro or hp <= 0.0:
		return
	_aggro = true
	_returning = false
	_update_label()
	# chama os vizinhos (matilhas e acampamentos atacam juntos)
	for e in get_tree().get_nodes_in_group("enemies"):
		var other := e as Enemy
		if other and other != self and not other._aggro and not other.is_boss and other.global_position.distance_to(global_position) < SOCIAL_RANGE:
			other.call_deferred("_set_aggro")


## Fora de combate: passeia perto de casa; se desistiu da perseguição, volta e recupera a vida.
func _idle_move(delta: float) -> void:
	if is_boss:
		return
	var goal := _wander_goal
	if _returning:
		goal = home
		if global_position.distance_to(home) < 2.0:
			_returning = false
			hp = max_hp
			_update_label()
			return
	else:
		_wander_t -= delta
		if _wander_t <= 0.0:
			_wander_t = randf_range(3.0, 8.0)
			var ang := randf() * TAU
			_wander_goal = home + Vector3(cos(ang), 0, sin(ang)) * randf_range(2.0, 8.0) if randf() < 0.6 else global_position
			goal = _wander_goal
	var to_g := goal - global_position
	to_g.y = 0.0
	if to_g.length() > 0.8:
		var s := speed * (1.3 if _returning else 0.35)
		velocity.x = to_g.normalized().x * s
		velocity.z = to_g.normalized().z * s
		look_at(global_position + to_g, Vector3.UP)


func _reset_boss() -> void:
	_aggro = false
	_leash_t = 0.0
	hp = max_hp
	global_position = home
	_update_label()
	Game.show_toast("%s desistiu da perseguição e recuperou a vida" % display_name)


func apply_slow(seconds: float) -> void:
	_slow_t = maxf(_slow_t, seconds)


func take_damage(amount: float) -> void:
	if hp <= 0.0:
		return
	hp -= amount
	_set_aggro()
	_flash_t = 0.08
	if _player:
		_player.last_target = self
	if anim:
		anim.hit()
	if rig:
		rig.hit()
	Game.log_event("Você causa %d de dano em %s." % [roundi(amount), display_name], Game.LOG_DAMAGE)
	FX.vfx(get_parent(), "hit" if randf() < 0.5 else "hit2", global_position + Vector3(0, 1.0 * size, 0), 0.5 * size, 0.9)
	FX.number(get_parent(), global_position + Vector3(0, (model_height if anim else 1.6 * size) + 0.3, 0), str(roundi(amount)), Color(1, 0.95, 0.8) if not is_boss else Color(1, 0.8, 0.3))
	_update_label()
	if hp <= 0.0:
		_die()


## Barra de vida acima da cabeça (dois retângulos virados para a câmera).
func _build_bar(y: float) -> void:
	_bar_root = Node3D.new()
	_bar_root.position.y = y
	add_child(_bar_root)
	var w := BAR_W * (2.2 if is_boss else 1.0)
	var bg := QuadMesh.new()
	bg.size = Vector2(w + 0.06, 0.16)
	var bgm := MeshInstance3D.new()
	bgm.mesh = bg
	bgm.material_override = _bar_material(Color(0, 0, 0, 0.8))
	bgm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar_root.add_child(bgm)
	_bar_fill = QuadMesh.new()
	_bar_fill.size = Vector2(w, 0.1)
	var fm := MeshInstance3D.new()
	fm.mesh = _bar_fill
	fm.material_override = _bar_material(Color(0.85, 0.15, 0.1) if not is_boss else Color(0.9, 0.55, 0.1))
	fm.material_override.render_priority = 1
	fm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar_root.add_child(fm)


func _bar_material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.albedo_color = c
	return m


func _update_label() -> void:
	if _bar_fill == null:
		return
	var w := BAR_W * (2.2 if is_boss else 1.0)
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	_bar_fill.size = Vector2(maxf(0.001, w * ratio), 0.1)
	_bar_fill.center_offset = Vector3(-(w - w * ratio) / 2.0, 0, 0.001)
	_bar_root.visible = is_boss or hp < max_hp or _aggro


func _die() -> void:
	var reward: float = Game.diff()["reward"]
	# XP em orbes (até 5 orbes)
	var xp_total := maxi(1, roundi(xp_reward * reward))
	var n_orbs := mini(5, xp_total)
	for i in n_orbs:
		_drop(Pickup.make("xp", ceili(float(xp_total) / n_orbs)))
	# Ouro
	var g := roundi(randi_range(gold_range.x, gold_range.y) * reward)
	if g > 0:
		_drop(Pickup.make("gold", g))
	# Material com chance (mobs) e drops garantidos (bosses)
	if material_id != "" and randf() < material_chance:
		_drop(Pickup.make("material", 1, material_id))
	for m in guaranteed_drops:
		for i in int(guaranteed_drops[m]):
			_drop(Pickup.make("material", 1, m))
	FX.burst(get_parent(), global_position + Vector3(0, 1.0, 0), color.lerp(Color(0.6, 0.1, 0.1), 0.4), 26 if not is_boss else 80, 5.0, 0.6 if not is_boss else 1.2, 0.7, 1.0)
	Game.log_event("%s (nível %d) morre." % [display_name, level], Game.LOG_SYSTEM)
	killed.emit(self)
	FX.vfx(get_parent(), "impact", global_position + Vector3(0, 0.8 * size, 0), 0.9 * size, 1.2)
	if rig:
		# toca a animação de morte e some depois
		_dying = true
		rig.die()
		remove_from_group("enemies")
		collision_layer = 0
		_bar_root.visible = false
		_label.visible = false
		get_tree().create_timer(3.0).timeout.connect(queue_free)
		return
	queue_free()


func _drop(p: Pickup) -> void:
	get_parent().add_child(p)
	p.global_position = global_position + Vector3(randf_range(-1.2, 1.2), 0.8, randf_range(-1.2, 1.2))
