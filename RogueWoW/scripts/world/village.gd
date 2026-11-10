class_name Village
extends RefCounted
## Casas montadas com o Medieval Village MegaKit (Quaternius, CC0): peças modulares de 2 m.
## build_house(largura, profundidade, andares, estilo) devolve um StaticBody3D com colisão em caixa.
## Frente da casa (porta) = +Z local.

const DIR := "res://assets/models/village/"
const FLOOR_H := 3.0
static var _cache := {}


static func piece(id: String) -> Node3D:
	var path := DIR + id + ".gltf"
	if not ResourceLoader.exists(path):
		return null
	if not _cache.has(path):
		_cache[path] = load(path)
	var n := (_cache[path] as PackedScene).instantiate() as Node3D
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return n


static func _put(parent: Node3D, id: String, pos: Vector3, yaw := 0.0) -> Node3D:
	var p := piece(id)
	if p:
		p.position = pos
		p.rotation.y = yaw
		parent.add_child(p)
	return p


## w, d: tamanho em módulos de 2 m (use pares para o telhado encaixar: 3x4, 3x3, 4x4, 2x3...).
## style: "plaster" (enxaimel claro), "brick" (pedra) ou "wood".
static func build_house(w: int, d: int, floors := 2, style := "plaster", rng: RandomNumberGenerator = null) -> StaticBody3D:
	if rng == null:
		rng = RandomNumberGenerator.new()
	var body := StaticBody3D.new()
	var W := w * 2.0
	var D := d * 2.0
	var base_wall := "Wall_UnevenBrick" if style != "wood" else "Wall_Plaster"
	for f in floors:
		var y := f * FLOOR_H
		var wall := base_wall if f == 0 else "Wall_Plaster"
		# frente (+Z) e fundos (-Z)
		for i in w:
			var x := -W / 2.0 + 1.0 + i * 2.0
			var front := wall + "_Straight"
			if f == 0 and i == w / 2:
				front = wall + "_Door_Round"
			elif f == 0:
				front = wall + "_Window_Wide_Round"
			elif rng.randf() < 0.6:
				front = "Wall_Plaster_Window_Wide_Flat" if style != "brick" else "Wall_Plaster_Window_Thin_Round"
			else:
				front = "Wall_Plaster_WoodGrid"
			_put(body, front, Vector3(x, y, D / 2.0), 0.0)
			# porta e janelas de verdade dentro dos vãos
			if front.ends_with("_Door_Round"):
				_put(body, "Door_1_Round", Vector3(x, y, D / 2.0), 0.0)
			elif front.ends_with("_Window_Wide_Round"):
				_put(body, "Window_Wide_Round1", Vector3(x, y, D / 2.0), 0.0)
			elif front.ends_with("_Window_Wide_Flat"):
				_put(body, "Window_Wide_Flat1", Vector3(x, y, D / 2.0), 0.0)
			elif front.ends_with("_Window_Thin_Round"):
				_put(body, "Window_Thin_Round1", Vector3(x, y, D / 2.0), 0.0)
			var back := wall + ("_Window_Wide_Round" if rng.randf() < 0.4 else "_Straight")
			_put(body, back, Vector3(x, y, -D / 2.0), PI)
		# laterais
		for j in d:
			var z := -D / 2.0 + 1.0 + j * 2.0
			var side := wall + ("_Window_Wide_Round" if (j % 2 == 1) else "_Straight")
			if f > 0 and rng.randf() < 0.4:
				side = "Wall_Plaster_WoodGrid"
			_put(body, side, Vector3(W / 2.0, y, z), PI / 2.0)
			_put(body, side, Vector3(-W / 2.0, y, z), -PI / 2.0)
		# cantos
		for c in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			_put(body, "Corner_Exterior_Wood" if f > 0 or style == "wood" else "Corner_Exterior_Brick", Vector3(c.x * W / 2.0, y, c.y * D / 2.0), 0.0)
		# piso
		for i in w:
			for j in d:
				_put(body, "Floor_WoodDark" if f > 0 else "Floor_Brick", Vector3(-W / 2.0 + 1.0 + i * 2.0, y + 0.01, -D / 2.0 + 1.0 + j * 2.0), 0.0)
	var top := floors * FLOOR_H
	# telhado (cumeeira ao longo de Z) + empenas na frente e atrás
	var roof_id := "Roof_RoundTiles_%dx%d" % [int(W), int(D)]
	if piece(roof_id) == null:
		roof_id = "Roof_RoundTiles_6x8"
	_put(body, roof_id, Vector3(0, top, 0), 0.0)
	var gable := "Roof_Front_Brick%d" % int(W)
	_put(body, gable, Vector3(0, top, D / 2.0), 0.0)
	_put(body, gable, Vector3(0, top, -D / 2.0), PI)
	_put(body, "Prop_Chimney", Vector3(W / 2.0 - 1.2, top - 0.5, -D / 4.0), 0.0)
	# degraus da porta e trepadeira
	_put(body, "Stairs_Exterior_Straight", Vector3(0, 0, D / 2.0 + 1.0), 0.0)
	if rng.randf() < 0.6:
		_put(body, "Prop_Vine%d" % [1, 2, 4, 5][rng.randi() % 4], Vector3(-W / 2.0 + 0.6, 0, D / 2.0 + 0.1), 0.0)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(W, top + 2.0, D)
	cs.shape = box
	cs.position.y = (top + 2.0) / 2.0
	body.add_child(cs)
	return body


## Cerca de madeira entre dois pontos (peças de 2 m).
static func fence(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var dir := b - a
	var n := int(dir.length() / 2.0)
	var yaw := atan2(dir.x, dir.z) - PI / 2.0
	for i in n:
		_put(parent, "Prop_WoodenFence_Single", a + dir.normalized() * (1.0 + i * 2.0), yaw)
