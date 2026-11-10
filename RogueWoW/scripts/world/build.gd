class_name Build
extends RefCounted
## Atalhos para montar cenário cinza (placeholder) por código.
## Quando os modelos de verdade chegarem, estes blocos são trocados por cenas .glb.


static func mat(color: Color, emission := 0.0, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.roughness = 0.9
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


static func mesh(m: Mesh, color: Color, emission := 0.0, alpha := 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat(color, emission, alpha)
	return mi


static func static_box(size: Vector3, color: Color, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var bm := BoxMesh.new()
	bm.size = size
	body.add_child(mesh(bm, color))
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	return body


static func label(text: String, pos: Vector3, color := Color.WHITE, size := 48) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.modulate = color
	l.font_size = size
	l.outline_size = 12
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return l


## Céu, névoa e sol. Devolve os nós para adicionar na cena.
static func environment(sky_top: Color, horizon: Color, fog_density := 0.006) -> Array:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = sky_top
	sky_mat.sky_horizon_color = horizon
	sky_mat.ground_horizon_color = horizon
	sky_mat.ground_bottom_color = horizon.darkened(0.6)
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = horizon
	env.fog_density = fog_density
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.ssao_enabled = true
	env.ssao_intensity = 1.5
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.18
	env.adjustment_contrast = 1.05
	env_node.environment = env

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_color = Color(1.0, 0.92, 0.78)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	return [env_node, sun]


## Árvore placeholder. kind: "forest", "dead", "pine"
static func tree(pos: Vector3, kind: String, rng: RandomNumberGenerator) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var h := rng.randf_range(3.5, 6.5)
	var trunk_color := Color(0.35, 0.22, 0.12)
	if kind == "dead":
		trunk_color = Color(0.22, 0.2, 0.18)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.18 if kind == "dead" else 0.25
	trunk.bottom_radius = 0.35
	trunk.height = h
	var t := mesh(trunk, trunk_color)
	t.position.y = h / 2.0
	body.add_child(t)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.35
	shape.height = h
	cs.shape = shape
	cs.position.y = h / 2.0
	body.add_child(cs)
	match kind:
		"forest":
			var crown := SphereMesh.new()
			crown.radius = rng.randf_range(1.6, 2.4)
			crown.height = crown.radius * 1.6
			var greens := [Color(0.2, 0.45, 0.12), Color(0.28, 0.5, 0.1), Color(0.15, 0.38, 0.15), Color(0.35, 0.48, 0.12)]
			var c := mesh(crown, (greens[rng.randi() % greens.size()] as Color).lightened(rng.randf_range(0.0, 0.1)))
			c.position.y = h
			body.add_child(c)
		"pine":
			for i in 3:
				var cone := CylinderMesh.new()
				cone.top_radius = 0.0
				cone.bottom_radius = 1.8 - i * 0.45
				cone.height = 2.0
				var c := mesh(cone, Color(0.85, 0.9, 0.95) if i == 2 else Color(0.15, 0.32, 0.22))
				c.position.y = h * 0.45 + i * 1.2
				body.add_child(c)
		"dead":
			var branch := BoxMesh.new()
			branch.size = Vector3(1.6, 0.12, 0.12)
			var b := mesh(branch, trunk_color)
			b.position.y = h * 0.75
			b.rotation.z = 0.5
			body.add_child(b)
	body.rotation.y = rng.randf() * TAU
	return body


static func rock(pos: Vector3, color: Color, rng: RandomNumberGenerator) -> StaticBody3D:
	var s := rng.randf_range(0.8, 2.2)
	var body := static_box(Vector3(s * 1.3, s, s), color, pos + Vector3(0, s * 0.4, 0))
	body.rotation = Vector3(rng.randf() * 0.3, rng.randf() * TAU, rng.randf() * 0.3)
	return body


## Material de chão com "pintura" de ruído (duas cores misturadas), estilo pintado à mão.
static func ground_material(a: Color, b: Color, scale := 0.05) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.03
	noise.fractal_octaves = 4
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	tex.noise = noise
	var ramp := Gradient.new()
	ramp.set_color(0, a)
	ramp.set_color(1, b)
	tex.color_ramp = ramp
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.roughness = 1.0
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	return m


## Chão com colisão e material pintado.
static func ground(size: Vector3, pos: Vector3, a: Color, b: Color, scale := 0.05) -> StaticBody3D:
	var body := static_box(size, a, pos)
	(body.get_child(0) as MeshInstance3D).material_override = ground_material(a, b, scale)
	return body


## Tufos de grama/junco/neve espalhados com MultiMesh (barato para a placa de vídeo).
static func scatter(center: Vector3, half: float, count: int, color: Color, rng: RandomNumberGenerator, height := 0.6, avoid: Callable = Callable()) -> MultiMeshInstance3D:
	var blade := CylinderMesh.new()
	blade.top_radius = 0.0
	blade.bottom_radius = 0.09
	blade.height = height
	blade.radial_segments = 4
	blade.rings = 1
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	m.vertex_color_use_as_albedo = false
	blade.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = blade
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var tries := 0
	while transforms.size() < count and tries < count * 3:
		tries += 1
		var p := center + Vector3(rng.randf_range(-half, half), 0, rng.randf_range(-half, half))
		if avoid.is_valid() and avoid.call(p):
			continue
		# tufos de 3 folhas
		for k in 3:
			var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.35, 0.35))
			var sc := rng.randf_range(0.7, 1.3)
			transforms.append(Transform3D(b.scaled(Vector3(sc, sc, sc)), p + Vector3(rng.randf_range(-0.2, 0.2), height * 0.5 * sc, rng.randf_range(-0.2, 0.2))))
			colors.append(color.lightened(rng.randf_range(-0.15, 0.2)))
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])
	m.vertex_color_use_as_albedo = true
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi


# --- Estilo clássico (2004) ---------------------------------------------------------

## Céu pintado (panorama), luz simples e neblina de distância colorida.
static func classic_environment(fog_color := Color(0.62, 0.72, 0.85), fog_density := 0.008, sun_color := Color(1.0, 0.92, 0.78)) -> Array:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var pano := PanoramaSkyMaterial.new()
	if ResourceLoader.exists("res://assets/textures/sky/daysky.png"):
		pano.panorama = load("res://assets/textures/sky/daysky.png")
	sky.sky_material = pano
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.64, 0.7)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = fog_color
	env.fog_density = fog_density
	env.fog_sky_affect = 0.25
	env.glow_enabled = false
	env.ssao_enabled = false
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.92
	env.adjustment_contrast = 1.05
	env_node.environment = env
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -40, 0)
	sun.light_color = sun_color
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.65
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 80.0
	return [env_node, sun]


## Chão com textura pintada que se repete (texturas PSX de 128 px).
static func textured_ground(size: Vector3, pos: Vector3, tex_path: String, meters_per_tile := 3.0) -> StaticBody3D:
	var body := static_box(size, Color.WHITE, pos)
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(tex_path):
		m.albedo_texture = load(tex_path)
	m.roughness = 1.0
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	var k := 1.0 / meters_per_tile
	m.uv1_scale = Vector3(k, k, k)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	(body.get_child(0) as MeshInstance3D).material_override = m
	return body


## Faixa de terreno (estrada/clareira) sem colisão, por cima do chão.
static func ground_patch(size: Vector2, pos: Vector3, rot_y: float, tex_path: String, meters_per_tile := 3.0) -> MeshInstance3D:
	var pm := PlaneMesh.new()
	pm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(tex_path):
		m.albedo_texture = load(tex_path)
	m.roughness = 1.0
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	var k := 1.0 / meters_per_tile
	m.uv1_scale = Vector3(k, k, k)
	mi.material_override = m
	mi.position = pos + Vector3(0, 0.02, 0)
	mi.rotation.y = rot_y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Espalha muitas cópias de um modelo pequeno (grama, flores) com MultiMesh.
static func scatter_model(id: String, center: Vector3, half: float, count: int, height: float, rng: RandomNumberGenerator, avoid: Callable = Callable()) -> MultiMeshInstance3D:
	var inst := Models.instance(id, height)
	if inst == null:
		return null
	var mis := inst.find_children("*", "MeshInstance3D", true, false)
	if mis.is_empty():
		inst.free()
		return null
	var src := mis[0] as MeshInstance3D
	var base_xf := Models._relative_transform(inst, src)
	var mesh := src.mesh
	var mat := src.get_active_material(0)
	inst.free()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	var xfs: Array[Transform3D] = []
	var tries := 0
	while xfs.size() < count and tries < count * 3:
		tries += 1
		var p := center + Vector3(rng.randf_range(-half, half), 0, rng.randf_range(-half, half))
		if avoid.is_valid() and avoid.call(p):
			continue
		var s := rng.randf_range(0.7, 1.3)
		var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s)), p) * base_xf
		xfs.append(xf)
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi


## Objeto de cenário com colisão em cilindro (árvores, pedras, troncos).
static func prop(id: String, pos: Vector3, height: float, rng: RandomNumberGenerator, collide_radius := 0.0, fit_longest := false, tint := Color.WHITE) -> Node3D:
	var m := Models.instance(id, height, tint, fit_longest)
	if m == null:
		return null
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = rng.randf() * TAU
	body.add_child(m)
	if collide_radius > 0.0:
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = collide_radius
		cyl.height = height
		cs.shape = cyl
		cs.position.y = height / 2.0
		body.add_child(cs)
	return body
