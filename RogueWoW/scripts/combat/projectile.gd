class_name Projectile
extends Area3D
## Projétil genérico: Bola de Fogo, Flecha, Raio Sombrio.

var direction := Vector3.FORWARD
var speed := 30.0
var damage := 10.0
var lifetime := 1.4
var color := Color(1.0, 0.45, 0.1)
var explode_radius := 0.0  ## > 0: explode em área ao acertar
var pierce := false  ## atravessa inimigos
var small := false  ## flecha (visual fino)
var vfx_id := ""  ## efeito pronto do projétil (Binbun); vazio = visual simples
var _hit := {}


func _ready() -> void:
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.35
	cs.shape = s
	add_child(cs)
	var fx_node: Node3D = null
	if vfx_id != "":
		fx_node = FX.vfx(self, vfx_id, Vector3.ZERO, 1.1 if small else 1.7, 0.0)
		var glow := OmniLight3D.new()
		glow.light_color = color
		glow.light_energy = 2.5
		glow.omni_range = 5.0
		add_child(glow)
	look_at_from_position(position, position + direction, Vector3.UP)
	if fx_node:
		# os projéteis prontos andam para -Z do próprio nó (frente)
		body_entered.connect(_on_body_entered)
		return
	if small:
		var arrow := BoxMesh.new()
		arrow.size = Vector3(0.06, 0.06, 0.9)
		var a := Build.mesh(arrow, color, 1.0)
		add_child(a)
		look_at_from_position(position, position + direction, Vector3.UP)
	else:
		var sm := SphereMesh.new()
		sm.radius = 0.3
		sm.height = 0.6
		add_child(Build.mesh(sm, color, 4.0))
		var light := OmniLight3D.new()
		light.light_color = color
		light.omni_range = 4.0
		add_child(light)
	FX.trail(self, color, 0.2 if small else 0.55, 18 if small else 36, 0.25 if small else 0.4)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body is Player or body is Ally:
		return
	FX.burst(get_parent(), global_position, color, 12, 4.0, 0.4, 0.35)
	FX.vfx(get_parent(), "explosion" if explode_radius > 0.0 else "impact", global_position, 0.5 if explode_radius > 0.0 else 0.7, 1.2, Vector3.ZERO, color)
	if body is Enemy:
		if _hit.has(body):
			return
		_hit[body] = true
		(body as Enemy).take_damage(damage)
		if explode_radius > 0.0:
			_explode(body)
		if pierce:
			return
	elif explode_radius > 0.0:
		_explode(null)
	queue_free()


func _explode(direct_hit: Node) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy and enemy != direct_hit and enemy.global_position.distance_to(global_position) <= explode_radius:
			enemy.take_damage(damage * 0.6)
	var ring := SphereMesh.new()
	ring.radius = explode_radius
	ring.height = explode_radius * 2.0
	var fx := Build.mesh(ring, color, 2.0, 0.4)
	get_parent().add_child(fx)
	fx.global_position = global_position
	var tw := fx.create_tween()
	tw.tween_property(fx, "transparency", 1.0, 0.3)
	tw.tween_callback(fx.queue_free)
