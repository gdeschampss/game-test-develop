extends Node3D
func _ready() -> void:
	var cam := Camera3D.new(); add_child(cam); cam.look_at_from_position(Vector3(7, 2.0, 0.5), Vector3(0, 1.0, 0))
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 60, 0); add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.32, 0.36, 0.4); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color.WHITE; env.ambient_light_energy = 0.5; we.environment = env; add_child(we)
	var h := Models.instance("warhorse", 2.0); add_child(h)
	var dot := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.25; sm.height = 0.5; dot.mesh = sm; dot.position = Vector3(0, 1.5, -3.0); add_child(dot)
	var l := Label3D.new(); l.text = "FRENTE (-Z)"; l.position = Vector3(0, 2.2, -3.0); l.font_size = 64; l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; add_child(l)
	var r := CharacterRig.make("skeleton", 1.85); r.position = Vector3(0, 0, 2.5); add_child(r); r._weapon("weapons/w_falchion", "hand_r", 0.9); r.anim.play("combat_idle")
	for f in 10: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/shots/horsetest.png"); get_tree().quit()
