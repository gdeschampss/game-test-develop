class_name Models
extends RefCounted
## Carrega os modelos 3D de assets/models, ajusta tamanho, apoia no chão e vira para a frente (-Z).
## Se o arquivo não existir, devolve null e quem chamou usa o placeholder cinza.

## yaw: correção de rotação em graus para o modelo olhar para -Z (frente no Godot).
const INFO := {
	"knight": {"yaw": 180.0},
	"darkelf": {"yaw": 180.0},
	"devil": {"yaw": 180.0},
	"centaur": {"yaw": 180.0},
	"treegiant": {"yaw": 180.0},
	"swampdragon": {"yaw": 180.0},
	"mountaindragon": {"yaw": 180.0},
	"house": {"yaw": 0.0},
	"sword": {"yaw": 0.0},
	"warhorse": {"yaw": 180.0},  # o modelo olha para +Z
}

static var _cache := {}


static func exists(id: String) -> bool:
	return _path(id) != ""


## Caminho do modelo: .glb ou .gltf (os props do Fantasy Props MegaKit vêm em .gltf com texturas compartilhadas).
static func _path(id: String) -> String:
	for ext in ["glb", "gltf"]:
		var p := "res://assets/models/%s.%s" % [id, ext]
		if ResourceLoader.exists(p):
			return p
	return ""


## Instancia o modelo com a altura pedida (em metros). tint multiplica a cor (para variar classes).
## fit_longest: true = "height" vira o tamanho do maior lado (armas deitadas, por exemplo).
static func instance(id: String, height: float, tint := Color.WHITE, fit_longest := false) -> Node3D:
	var path := _path(id)
	if path == "":
		return null
	var ps: PackedScene = _cache.get(id)
	if ps == null:
		ps = load(path)
		_cache[id] = ps
	var model := ps.instantiate() as Node3D
	var holder := Node3D.new()
	holder.name = "Model_" + id
	var pivot := Node3D.new()
	holder.add_child(pivot)
	pivot.add_child(model)
	pivot.rotation_degrees.y = float(INFO.get(id, {}).get("yaw", 0.0))

	var aabb := _aabb(model)
	var ref := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z)) if fit_longest else aabb.size.y
	if ref > 0.001:
		var s := height / ref
		model.scale = Vector3.ONE * s
		var center := aabb.get_center() * s
		model.position = Vector3(-center.x, -aabb.position.y * s, -center.z)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# visual clássico: fosco, sem reflexo especular
		for i in m.mesh.get_surface_count():
			var base := m.get_active_material(i)
			if base is StandardMaterial3D and m.get_surface_override_material(i) == null:
				var fosco := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
				fosco.metallic = 0.0
				fosco.roughness = 1.0
				fosco.metallic_specular = 0.2
				m.set_surface_override_material(i, fosco)
		if tint != Color.WHITE:
			for i in m.mesh.get_surface_count():
				var mat := m.get_active_material(i)
				if mat is StandardMaterial3D:
					mat = m.get_surface_override_material(i) if m.get_surface_override_material(i) else mat
					var copy := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
					copy.albedo_color = copy.albedo_color * tint
					m.set_surface_override_material(i, copy)
	# Modelos animados (ex.: dragão da montanha): toca a animação em loop
	for ap in model.find_children("*", "AnimationPlayer", true, false):
		var player := ap as AnimationPlayer
		var names := player.get_animation_list()
		if not names.is_empty():
			var anim := player.get_animation(names[0])
			anim.loop_mode = Animation.LOOP_LINEAR
			player.play(names[0])
	return holder


static func _aabb(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var local_xf := _relative_transform(root, m)
		var box := local_xf * m.get_aabb()
		if first:
			result = box
			first = false
		else:
			result = result.merge(box)
	return result


static func _relative_transform(root: Node3D, node: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != root:
		if n is Node3D:
			xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf


## Arma pronta para segurar: o eixo comprido do modelo (achado pelos vértices, PCA) vira +Y,
## a ponta do cabo fica embaixo e a origem fica no ponto de empunhadura (grip = fração do comprimento).
## flip: inverte se o cabo do modelo estiver do lado "largo". Resultado é cacheado por id.
static var _weapon_cache := {}


static func weapon(id: String, length: float, grip := 0.12, flip := false) -> Node3D:
	var path := _path(id)
	if path == "":
		return null
	var ps: PackedScene = _cache.get(id)
	if ps == null:
		ps = load(path)
		_cache[id] = ps
	var model := ps.instantiate() as Node3D
	var key := id
	var info: Dictionary = _weapon_cache.get(key, {})
	if info.is_empty():
		info = _weapon_axes(model)
		_weapon_cache[key] = info
	var axis: Vector3 = info["axis"]
	var side: Vector3 = info["side"]
	var lo: float = info["lo"]
	var hi: float = info["hi"]
	var center: Vector3 = info["center"]
	# o lado "largo" (cabeça/lâmina) deve ficar para cima, a menos que flip
	if info["wide_low"] != flip:
		axis = -axis
		var t := lo
		lo = -hi
		hi = -t
	var up := axis
	var x := side - up * side.dot(up)
	x = x.normalized()
	var z := x.cross(up).normalized()
	var basis := Basis(x, up, z).transposed()  # leva coordenadas do modelo para o espaço da arma
	var len_model := hi - lo
	var s := length / maxf(0.001, len_model)
	var holder := Node3D.new()
	holder.name = "Weapon_" + id.get_file()
	holder.add_child(model)
	# ponto de pegada: no eixo, a "grip" do comprimento a partir do cabo
	var grip_pt := center + up * (lo + len_model * grip)
	model.transform = Transform3D(basis.scaled(Vector3.ONE * s), -(basis * grip_pt) * s)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for i in m.mesh.get_surface_count():
			var base := m.get_active_material(i)
			if base is StandardMaterial3D:
				var fosco := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
				fosco.metallic = 0.0
				fosco.roughness = 0.85
				m.set_surface_override_material(i, fosco)
	return holder


static func _weapon_axes(model: Node3D) -> Dictionary:
	var pts := PackedVector3Array()
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var xf := _relative_transform(model, m)
		for sidx in m.mesh.get_surface_count():
			var verts: PackedVector3Array = m.mesh.surface_get_arrays(sidx)[Mesh.ARRAY_VERTEX]
			var step := maxi(1, verts.size() / 4000)
			for i in range(0, verts.size(), step):
				pts.append(xf * verts[i])
	var c := Vector3.ZERO
	for p in pts:
		c += p
	c /= maxf(1.0, pts.size())
	# matriz de covariância
	var cxx := 0.0; var cxy := 0.0; var cxz := 0.0; var cyy := 0.0; var cyz := 0.0; var czz := 0.0
	for p in pts:
		var d := p - c
		cxx += d.x * d.x; cxy += d.x * d.y; cxz += d.x * d.z
		cyy += d.y * d.y; cyz += d.y * d.z; czz += d.z * d.z
	var cov := Basis(Vector3(cxx, cxy, cxz), Vector3(cxy, cyy, cyz), Vector3(cxz, cyz, czz))
	var v := Vector3(0.3, 1.0, 0.2).normalized()
	for it in 60:
		v = (cov * v).normalized()
	# segundo eixo (largura da lâmina/cabeça)
	var w := Vector3(1, 0, 0) if absf(v.x) < 0.9 else Vector3(0, 0, 1)
	w = (w - v * w.dot(v)).normalized()
	for it in 60:
		w = cov * w
		w = (w - v * w.dot(v)).normalized()
	var lo := INF
	var hi := -INF
	for p in pts:
		var t := (p - c).dot(v)
		lo = minf(lo, t)
		hi = maxf(hi, t)
	# qual ponta é mais larga? (média da distância ao eixo no último terço de cada lado)
	var span := hi - lo
	var wl := 0.0; var nl := 0; var wh := 0.0; var nh := 0
	for p in pts:
		var d := p - c
		var t := d.dot(v)
		var r := (d - v * t).length()
		if t < lo + span * 0.33:
			wl += r; nl += 1
		elif t > hi - span * 0.33:
			wh += r; nh += 1
	var wide_low := (wl / maxf(1, nl)) > (wh / maxf(1, nh))
	return {"axis": v, "side": w, "lo": lo, "hi": hi, "center": c, "wide_low": wide_low}
