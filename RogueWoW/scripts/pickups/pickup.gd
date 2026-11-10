class_name Pickup
extends Area3D
## Item no chão: XP (verde), ouro (dourado) ou material (roxo).
## É puxado para o jogador quando ele chega perto.

var kind := "xp"  ## "xp", "gold" ou "material"
var amount := 1
var material_id := ""
var _t := 0.0
var _player: Player


static func make(p_kind: String, p_amount: int, p_material := "") -> Pickup:
	var p := Pickup.new()
	p.kind = p_kind
	p.amount = p_amount
	p.material_id = p_material
	return p


func _ready() -> void:
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.7
	cs.shape = s
	add_child(cs)
	match kind:
		"xp":
			var sm := SphereMesh.new()
			sm.radius = 0.2
			sm.height = 0.4
			add_child(Build.mesh(sm, Color(0.35, 1.0, 0.45), 3.0))
		"gold":
			var c := CylinderMesh.new()
			c.top_radius = 0.25
			c.bottom_radius = 0.25
			c.height = 0.08
			var mi := Build.mesh(c, Color(1.0, 0.8, 0.2), 2.0)
			mi.rotation.x = PI / 2.0
			add_child(mi)
		"material":
			var b := BoxMesh.new()
			b.size = Vector3(0.35, 0.35, 0.35)
			add_child(Build.mesh(b, Color(0.75, 0.4, 1.0), 2.0))
			add_child(Build.label(Game.MATERIALS.get(material_id, "?"), Vector3(0, 0.6, 0), Color(0.85, 0.6, 1.0), 24))
	# brilho de loot no chão (comum para XP/ouro, raro para materiais, épico para materiais de chefe)
	var rar := "loot_common"
	if kind == "material":
		rar = "loot_epic" if Game.MATERIAL_RARITY.get(material_id, "") in ["rara", "mítica"] else "loot_rare"
	elif kind == "gold":
		rar = "loot_uncommon"
	FX.vfx(self, rar, Vector3.ZERO, 0.6, 0.0)
	body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("player") as Player


func _physics_process(delta: float) -> void:
	_t += delta
	rotation.y += delta * 2.0
	if _player and not _player.dead and _t > 0.3:
		var to_player := _player.global_position + Vector3(0, 0.8, 0) - global_position
		if to_player.length() < 1.2 and not is_queued_for_deletion():
			_player.collect(self)
			queue_free()
			return
		if to_player.length() < 9.0:
			global_position += to_player.normalized() * minf(20.0 * delta, to_player.length())
			return
	position.y += sin(_t * 4.0) * 0.01


func _on_body_entered(body: Node) -> void:
	if body is Player and _t > 0.3 and not is_queued_for_deletion():
		(body as Player).collect(self)
		queue_free()
