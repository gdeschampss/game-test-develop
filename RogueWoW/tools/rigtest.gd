extends Node3D
## Ferramenta: fila de personagens para conferir armas na mão e animações.
## godot --path . res://tools/rigtest.tscn -- [--clip=combat_idle] [--out=/tmp/x.png] [--yaw=30]
func _ready() -> void:
	var clip := "combat_idle"
	var out := "/tmp/shots/rigtest.png"
	var yaw := 25.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--clip="): clip = a.trim_prefix("--clip=")
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--yaw="): yaw = float(a.trim_prefix("--yaw="))
	var cam := Camera3D.new(); add_child(cam); cam.fov = 40
	cam.look_at_from_position(Vector3(0, 1.4, 8.0), Vector3(0, 1.0, 0))
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 25, 0); add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.32, 0.36, 0.4); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color.WHITE; env.ambient_light_energy = 0.55; we.environment = env; add_child(we)
	var specs := [["cacador", "", ""], ["mago", "", ""], ["bruxo", "", ""], ["guerreiro", "", ""], ["spirit", "", ""], ["pet_bear", "", ""], ["wolf", "", ""]]
	for i in specs.size():
		var sp: Array = specs[i]
		var r: CharacterRig
		if sp[0] in ["spirit", "pet_bear", "wolf"]:
			r = CharacterRig.make(sp[0], {"spirit": 1.7, "pet_bear": 1.9, "wolf": 1.0}[sp[0]])
		elif sp[0] in ["cacador", "mago", "bruxo", "guerreiro"]:
			r = CharacterRig.for_character(sp[0], "humano", "m")
		elif sp[0] == "skeleton":
			r = CharacterRig.make("skeleton", 1.85)
			if r: r._weapon("weapons/w_falchion", "hand_r", 0.9)
		elif sp[0] == "peasant":
			r = CharacterRig.make("peasant_m", 1.78, Color.WHITE, CharacterRig.palette("cacador", "humano"))
		else:
			r = CharacterRig.for_character(sp[0], sp[1], sp[2])
		if r == null:
			continue
		var holder := Node3D.new()
		holder.position = Vector3(-5.4 + i * 1.8, 0, 0)
		holder.rotation_degrees.y = 180 + yaw  # de frente para a câmera
		add_child(holder)
		holder.add_child(r)
		var c := clip
		if clip == "attack":
			c = {"guerreiro": "attack_1h", "mago": "attack_cast", "cacador": "attack_cast", "bruxo": "attack_2h", "peasant": "talk", "skeleton": "attack_1h", "spirit": "attack_cast", "pet_bear": "punch", "wolf": "attack_1h"}[sp[0]]
		r.anim.play(c)
		r.anim.seek(0.35 if clip == "attack" else 0.6, true)
		r.anim.pause()
	for f in 10: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out); get_tree().quit()
