extends Node3D
func _ready() -> void:
	for n in Build.classic_environment(): add_child(n)
	add_child(Build.textured_ground(Vector3(80, 1, 80), Vector3(0, -0.5, 0), "res://assets/textures/ground_hp/grass_soft.png", 5.0))
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var specs := [[3, 4, 2, "plaster", Vector3(-9, 0, 0)], [3, 3, 1, "brick", Vector3(0, 0, 2)], [4, 4, 2, "wood", Vector3(10, 0, 0)]]
	for sp in specs:
		var h := Village.build_house(sp[0], sp[1], sp[2], sp[3], rng)
		h.position = sp[4]
		add_child(h)
	Village.fence(self, Vector3(-14, 0, 9), Vector3(14, 0, 9))
	var cam := Camera3D.new(); add_child(cam); cam.look_at_from_position(Vector3(0, 6, 22), Vector3(0, 3, 0))
	for f in 10: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/shots/housetest.png"); get_tree().quit()
