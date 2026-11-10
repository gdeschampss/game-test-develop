extends Node3D
## Ferramenta: mostra armas alinhadas (cabo embaixo, origem = pegada). godot --path . res://tools/wtest.tscn
const IDS := ["weapons/w_knights_longsword", "weapons/w_wizards_staff", "weapons/wpn_battle_bow", "weapons/w_reapers_scythe", "weapons/w_dwarven_war_axe", "weapons/w_warhammer", "weapons/w_falchion", "weapons/wpn_sword", "weapons/wpn_battle_axe", "weapons/w_hunting_spear"]
func _ready() -> void:
	var cam := Camera3D.new(); add_child(cam); cam.look_at_from_position(Vector3(0, 0.5, 6), Vector3(0, 0.5, 0))
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-30, 20, 0); add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.25, 0.27, 0.3); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color.WHITE; env.ambient_light_energy = 0.6; we.environment = env; add_child(we)
	for i in IDS.size():
		var w := Models.weapon(IDS[i], 1.2)
		var x := -4.5 + i * 1.0
		if w:
			w.position = Vector3(x, 0, 0); add_child(w)
		var dot := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.04; sm.height = 0.08; dot.mesh = sm; dot.position = Vector3(x, 0, 0.2); add_child(dot)
		var l := Label3D.new(); l.text = str(i); l.position = Vector3(x, -0.3, 0); l.font_size = 64; add_child(l)
	for f in 8: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/shots/wtest.png"); get_tree().quit()
