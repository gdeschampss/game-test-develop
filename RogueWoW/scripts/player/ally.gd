class_name Ally
extends CharacterBody3D
## Aliado que luta junto: animal do Caçador (permanente) ou espírito do Bruxo (temporário).
## MVP: aliados não tomam dano; os mobs continuam focando o jogador.

var kind := "pet"  ## "pet" ou "spirit"
var display_name := "Lobo"
var color := Color.GRAY
var size := 1.0
var damage := 8.0
var speed := 9.0
var lifetime := -1.0  ## < 0 = permanente
var follow_offset := Vector3(2.0, 0, 1.5)

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _player: Player
var _target: Enemy
var _attack_t := 0.0
var _t := 0.0


func _ready() -> void:
	add_to_group("allies")
	collision_layer = 0  # não empurra nem é empurrado
	collision_mask = 1
	_player = get_tree().get_first_node_in_group("player") as Player
	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.4
	cs.shape = sphere
	cs.position.y = 0.4
	add_child(cs)
	if kind == "spirit" and CharacterRig.available("spirit"):
		# espírito do Bruxo: a criatura cósmica flutuando, com brilho
		_rig = CharacterRig.make("spirit", 1.7)
		_rig.position.y = 0.3
		add_child(_rig)
		var glow := OmniLight3D.new()
		glow.light_color = color
		glow.omni_range = 5.0
		glow.position.y = 1.3
		add_child(glow)
	elif kind == "spirit":
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.4
		var m := Build.mesh(sm, color, 2.5, 0.6)
		m.position.y = 1.3
		add_child(m)
		var light := OmniLight3D.new()
		light.light_color = color
		light.omni_range = 5.0
		light.position.y = 1.3
		add_child(light)
	else:
		_build_animal()
	add_child(Build.label(display_name, Vector3(0, 1.6 * size + 0.4, 0), Color(0.5, 0.9, 1.0), 24))


var _rig: CharacterRig


func _build_animal() -> void:
	# animal do Caçador: o urso espiritual (os lobos agora são mobs do mapa)
	for k in ["pet_bear", "wolf"]:
		if CharacterRig.available(k):
			_rig = CharacterRig.make(k, (1.9 if k == "pet_bear" else 1.05) * size)
			add_child(_rig)
			return
	var body := BoxMesh.new()
	body.size = Vector3(0.6, 0.6, 1.3) * size
	var b := Build.mesh(body, color)
	b.position.y = 0.6 * size
	add_child(b)
	var head := BoxMesh.new()
	head.size = Vector3(0.45, 0.45, 0.5) * size
	var h := Build.mesh(head, color.lightened(0.1))
	h.position = Vector3(0, 0.85 * size, -0.8 * size)
	add_child(h)
	for x in [-0.2, 0.2]:
		for z in [-0.45, 0.45]:
			var leg := BoxMesh.new()
			leg.size = Vector3(0.15, 0.4, 0.15) * size
			var l := Build.mesh(leg, color.darkened(0.3))
			l.position = Vector3(x, 0.2, z) * size
			add_child(l)


func _physics_process(delta: float) -> void:
	_t += delta
	_attack_t = maxf(0.0, _attack_t - delta)
	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()
			return
	if _player == null:
		return
	if kind == "pet" and not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if _target == null or not is_instance_valid(_target) or _target.hp <= 0.0 or _target.global_position.distance_to(_player.global_position) > 22.0:
		_target = _find_target()

	var goal: Vector3
	var reach := 1.6 + 0.4 * size
	if _target:
		goal = _target.global_position
	else:
		goal = _player.global_position + Basis(Vector3.UP, _player.model.rotation.y) * follow_offset
	var to_goal := goal - global_position
	to_goal.y = 0.0
	var dist := to_goal.length()
	# Ficou muito para trás (ex.: jogador montado ou teleportou): aparece do lado.
	if global_position.distance_to(_player.global_position) > 40.0:
		global_position = _player.global_position + follow_offset
		return
	var stop := reach if _target else 0.8
	if dist > stop:
		var s := speed * (1.6 if _player.mounted else 1.0)
		velocity.x = to_goal.normalized().x * s
		velocity.z = to_goal.normalized().z * s
		look_at(global_position + to_goal, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _target and _attack_t <= 0.0:
			_attack_t = 1.0
			_target.take_damage(damage)
			if _rig:
				_rig.play_once(("attack_1h" if randf() < 0.6 else "punch") if kind == "pet" else "attack_cast", 1.3)
	if kind == "spirit":
		global_position.y = _player.global_position.y + sin(_t * 3.0) * 0.2
	if _rig:
		_rig.set_locomotion(Vector2(0, 1), Vector2(velocity.x, velocity.z).length(), delta)
	move_and_slide()


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_d := 16.0
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.hp <= 0.0:
			continue
		var d := enemy.global_position.distance_to(_player.global_position)
		if d < best_d:
			best = enemy
			best_d = d
	return best
