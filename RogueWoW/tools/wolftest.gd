extends Node3D
func _ready() -> void:
	var cam := Camera3D.new(); add_child(cam); cam.look_at_from_position(Vector3(4, 1.6, 3), Vector3(0, 0.5, 0))
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 60, 0); add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.32, 0.36, 0.4); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color.WHITE; env.ambient_light_energy = 0.5; we.environment = env; add_child(we)
	var w := CharacterRig.make("wolf", 1.1); add_child(w); w.anim.play("run")
	var dot := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.15; sm.height = 0.3; dot.mesh = sm; dot.position = Vector3(0, 0.6, -2.0); add_child(dot)
	var h := CharacterRig.make("human_m", 1.78, Color.WHITE, CharacterRig.palette("guerreiro", "humano")); h.position = Vector3(-1.5, 0, 0); add_child(h)
	for f in 10: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/shots/wolftest.png"); get_tree().quit()
