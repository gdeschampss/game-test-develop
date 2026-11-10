class_name FX
extends RefCounted
## Efeitos visuais simples (CPUParticles3D funciona em qualquer placa de vídeo):
## explosões de partículas, rastro, números de dano flutuantes e textos de loot.

static var _smoke: Texture2D
static var _trail: Texture2D


static func smoke_tex() -> Texture2D:
	if _smoke == null:
		_smoke = load("res://assets/textures/fx/particle_smoke.png")
	return _smoke


static func trail_tex() -> Texture2D:
	if _trail == null:
		_trail = load("res://assets/textures/fx/trail.png")
	return _trail


static func _particle_material(color: Color, tex: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_color = color
	if tex:
		m.albedo_texture = tex
	return m


static func _particles(color: Color, amount: int, size: float, tex: Texture2D) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = _particle_material(color, tex)
	p.mesh = q
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color.r, color.g, color.b, 1.0))
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = ramp
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 0.2))
	p.scale_amount_curve = curve
	return p


## Explosão única de partículas (impacto, nova, cura, subir de nível).
static func burst(parent: Node, pos: Vector3, color: Color, amount := 24, speed := 6.0, size := 0.5, lifetime := 0.6, up := 0.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := _particles(color, amount, size, smoke_tex())
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = lifetime
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, up, 0)
	p.damping_min = 2.0
	p.damping_max = 4.0
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.get_tree().create_timer(lifetime + 0.3).timeout.connect(p.queue_free)


## Anel de partículas no chão (nova, sugar alma, chuva de flechas).
static func ring(parent: Node, pos: Vector3, color: Color, radius: float) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := _particles(color, int(clampf(radius * 10.0, 20, 90)), 0.7, smoke_tex())
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.7
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = radius
	p.emission_ring_inner_radius = radius * 0.8
	p.emission_ring_height = 0.2
	p.direction = Vector3.UP
	p.spread = 20.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 3.0
	p.gravity = Vector3(0, 2.0, 0)
	parent.add_child(p)
	p.global_position = pos + Vector3(0, 0.2, 0)
	p.emitting = true
	p.get_tree().create_timer(1.2).timeout.connect(p.queue_free)


## Rastro contínuo preso a um nó (projéteis, espírito, portal).
static func trail(node: Node3D, color: Color, size := 0.45, amount := 30, lifetime := 0.4, local := false) -> CPUParticles3D:
	var p := _particles(color, amount, size, smoke_tex())
	p.lifetime = lifetime
	p.local_coords = local
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.8
	p.gravity = Vector3.ZERO
	node.add_child(p)
	p.emitting = true
	return p


## Número flutuante (dano, cura, ouro).
static func number(parent: Node, pos: Vector3, text: String, color := Color.WHITE, size := 56) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var l := Label3D.new()
	l.text = text
	l.font = UITheme.title_font()
	l.font_size = size
	l.outline_size = 14
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.01
	parent.add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "global_position", l.global_position + Vector3(0, 1.6, 0), 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)


## Coluna de luz (subir de nível, extração).
static func pillar(parent: Node, pos: Vector3, color: Color, height := 6.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var c := CylinderMesh.new()
	c.top_radius = 0.9
	c.bottom_radius = 1.3
	c.height = height
	var mi := MeshInstance3D.new()
	mi.mesh = c
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(color.r, color.g, color.b, 0.5)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	parent.add_child(mi)
	mi.global_position = pos + Vector3(0, height / 2.0, 0)
	var tw := mi.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, 1.0)
	tw.tween_callback(mi.queue_free)
	burst(parent, pos + Vector3(0, 1, 0), color, 40, 5.0, 0.5, 1.0, 4.0)


# --- Efeitos prontos (Binbun VFX: projéteis mágicos, impactos, explosões, golpes, loot) ---------------

const VFX := {
	"proj_fire": "res://assets/BinbunVFX/magic_projectiles/effects/mprojectile_basic/mprojectile_basic_vfx_01.tscn",
	"proj_shadow": "res://assets/BinbunVFX/magic_projectiles/effects/mprojectile_basic/mprojectile_basic_vfx_03.tscn",
	"proj_arrow": "res://assets/BinbunVFX/magic_projectiles/effects/mprojectile_javelin/mprojectile_javelin_vfx_01.tscn",
	"proj_wave": "res://assets/BinbunVFX/magic_projectiles/effects/mprojectile_wave/mprojectile_wave_vfx_01.tscn",
	"explosion": "res://assets/BinbunVFX_Vol2/ExplosionFX/effects/air/vfx_air_explosion_01.tscn",
	"ground_explosion": "res://assets/BinbunVFX_Vol2/ExplosionFX/effects/ground/vfx_ground_explosion_01.tscn",
	"hit": "res://assets/BinbunVFX_Vol2/StylizedHitFX/effects/hit/vfx_hit_01.tscn",
	"hit2": "res://assets/BinbunVFX_Vol2/StylizedHitFX/effects/hit/vfx_hit_02.tscn",
	"impact": "res://assets/BinbunVFX_Vol2/StylizedHitFX/effects/impact/vfx_impact_01.tscn",
	"slash": "res://assets/BinbunVFX_Vol2/BattleFX/effects/slash/vfx_blank_slash.tscn",
	"swing": "res://assets/BinbunVFX_Vol2/BattleFX/effects/swing/vfx_blank_swing.tscn",
	"claw": "res://assets/BinbunVFX_Vol2/BattleFX/effects/claw/vfx_blank_claw.tscn",
	"shield": "res://assets/BinbunVFX_Vol2/BattleFX/effects/shield/vfx_blank_shield_01.tscn",
	"charge": "res://assets/BinbunVFX_Vol2/BattleFX/effects/charge/vfx_blank_charge.tscn",
	"loot_common": "res://assets/BinbunVFX/loot_effects/effects/ground/ground_loot_vfx_common.tscn",
	"loot_uncommon": "res://assets/BinbunVFX/loot_effects/effects/ground/ground_loot_vfx_uncommon.tscn",
	"loot_rare": "res://assets/BinbunVFX/loot_effects/effects/ground/ground_loot_vfx_rare.tscn",
	"loot_epic": "res://assets/BinbunVFX/loot_effects/effects/ground/ground_loot_vfx_epic.tscn",
}
static var _vfx_cache := {}


## Toca um efeito pronto. life <= 0: fica (projéteis/loot, some com o pai). facing: direção para onde o efeito aponta.
static func vfx(parent: Node, id: String, pos: Vector3, scale := 1.0, life := 1.5, facing := Vector3.ZERO, color := Color(0, 0, 0, 0)) -> Node3D:
	var path: String = VFX.get(id, "")
	if path == "" or parent == null or not ResourceLoader.exists(path):
		return null
	if not _vfx_cache.has(path):
		_vfx_cache[path] = load(path)
	var n := (_vfx_cache[path] as PackedScene).instantiate() as Node3D
	if n == null:
		return null
	var looping := life <= 0.0
	if not looping and "one_shot" in n:
		n.set("one_shot", true)
	if color.a > 0.0 and "primary_color" in n:
		n.set("primary_color", color)
	parent.add_child(n)
	if parent is Node3D and looping:
		n.position = pos
	else:
		n.global_position = pos
	n.scale = Vector3.ONE * scale
	if facing.length() > 0.01:
		var f := facing.normalized()
		var up := Vector3.UP if absf(f.y) < 0.95 else Vector3.FORWARD
		n.look_at(n.global_position + f, up)
	if n.has_method("play"):
		n.call("play")
	if not looping:
		parent.get_tree().create_timer(life).timeout.connect(func() -> void:
			if is_instance_valid(n):
				n.queue_free())
	return n
