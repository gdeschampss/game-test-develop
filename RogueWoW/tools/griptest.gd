extends Node3D
var CANDS := [Vector3(0, 0, 0), Vector3(90, 0, 0), Vector3(-90, 0, 0), Vector3(0, 0, 90), Vector3(0, 0, -90), Vector3(180, 0, 0)]
var race := "humano"
var yaw := 90.0
func _ready() -> void:
	var cam := Camera3D.new(); add_child(cam); cam.fov = 40
	cam.look_at_from_position(Vector3(0, 1.3, 6.0 if race == "cacador" else 9.0), Vector3(0, 1.1, 0))
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 25, 0); add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.32, 0.36, 0.4); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color.WHITE; env.ambient_light_energy = 0.55; we.environment = env; add_child(we)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--race="): race = a.trim_prefix("--race=")
		if a.begins_with("--yaw="): yaw = float(a.trim_prefix("--yaw="))
		if a.begins_with("--cands="):
			CANDS = []
			for c in a.trim_prefix("--cands=").split(";"):
				var v := c.split(",")
				CANDS.append(Vector3(float(v[0]), float(v[1]), float(v[2])))
	for row in 1:
		for i in CANDS.size():
			var r := CharacterRig.for_character(race if race in ["mago", "cacador", "bruxo", "guerreiro"] else "guerreiro", race, "m")
			var holder := Node3D.new()
			holder.position = Vector3((-5.0 + i * 2.0) * (0.7 if race == "cacador" else 1.0), 0, 0)
			holder.position.y = 0.0
			holder.rotation_degrees.y = 180 + yaw
			add_child(holder)
			holder.add_child(r)
			for w in r.weapons:
				w.rotation_degrees = CANDS[i]
			r.anim.play("idle"); r.anim.seek(0.6, true); r.anim.pause()
			var l := Label3D.new(); l.text = "%d" % i; l.font_size = 72; l.position = holder.position + Vector3(0, 2.3 if row == 0 else 1.9, 0); l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; add_child(l)
	for f in 10: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/shots/grip_%s_%d.png" % [race, int(yaw)]); get_tree().quit()
