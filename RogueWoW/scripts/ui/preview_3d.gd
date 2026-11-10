class_name Preview3D
extends RefCounted
## Janelinha com o personagem em 3D (usada na tela de personagens e na janela do personagem).
## Devolve {"control": Control, "pivot": Node3D} — gire o pivot para o modelo rodar.


static func make(class_id: String, race_id: String, px: Vector2i, sex := "m") -> Dictionary:
	var cls := ClassData.for_class(class_id)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UITheme.panel_style(Color(0.02, 0.02, 0.03, 1.0), Color(0.5, 0.4, 0.2), 2, 4))
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(px)
	frame.add_child(svc)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.size = px
	svc.add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.08, 0.07, 0.1)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.5, 0.6)
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	vp.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 30, 0)
	key.light_energy = 1.4
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 200, 0)
	rim.light_color = Color(1.0, 0.8, 0.5)
	rim.light_energy = 0.8
	vp.add_child(rim)
	var pivot := Node3D.new()
	vp.add_child(pivot)
	var h: float = ClassData.race(race_id)["height"]
	var m: Node3D = null
	var rig := CharacterRig.for_character(class_id, race_id, sex)
	var has_rig := rig != null
	if has_rig:
		var rs: Vector3 = rig.scale
		var full_h := (1.35 if race_id == "anao" else 1.78) * rs.y
		rig.scale = rs * (1.7 / full_h)  # cabe na moldura
		rig.rotation.y = PI
		pivot.add_child(rig)
		rig.anim.play("combat_idle" if rig.family == "dwarf" else "idle")
	else:
		m = Models.instance(cls.get("model", ""), 1.9 * h, cls.get("tint", Color.WHITE))
	if m:
		m.rotation.y = PI
		pivot.add_child(m)
	elif not has_rig:
		var cap := Build.mesh(CapsuleMesh.new(), cls["color"])
		cap.position.y = 1.0
		pivot.add_child(cap)
	var floor_disc := CylinderMesh.new()
	floor_disc.top_radius = 1.0
	floor_disc.bottom_radius = 1.0
	floor_disc.height = 0.05
	pivot.add_child(Build.mesh(floor_disc, Color(0.25, 0.2, 0.15)))
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.15, 3.3)
	cam.rotation_degrees = Vector3(-6, 0, 0)
	cam.fov = 45.0
	vp.add_child(cam)
	cam.current = true
	return {"control": frame, "pivot": pivot}
