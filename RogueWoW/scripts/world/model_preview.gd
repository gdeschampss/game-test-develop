extends Node3D
## Ferramenta de dev (--models): mostra todos os modelos lado a lado, olhando para a câmera.

func _ready() -> void:
	for n in Build.environment(Color(0.3, 0.45, 0.75), Color(0.8, 0.75, 0.65), 0.001):
		add_child(n)
	add_child(Build.static_box(Vector3(80, 1, 30), Color(0.35, 0.45, 0.25), Vector3(0, -0.5, 0)))
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
	var ids := ["knight", "darkelf", "devil", "centaur", "treegiant", "swampdragon", "mountaindragon", "house", "sword"]
	var x := -26.0
	if only == "rig":
		ids = []
		var specs := [["dwarf_m", "run", -3.0, "guerreiro", "anao"], ["dwarf_m", "attack_cast", -1.0, "mago", "humano"], ["dwarf_f", "idle", 1.0, "cacador", "elfo"], ["dwarf_m", "attack_2h", 3.0, "bruxo", "orc"]]
		for sp in specs:
			var rig := CharacterRig.make(sp[0], 1.35, Color.WHITE, CharacterRig.palette(sp[3], sp[4]))
			add_child(rig)
			rig.position = Vector3(sp[2], 0, 0)
			rig.rotation_degrees.y = 180.0
			rig.equip_class(sp[3], CharacterRig.palette(sp[3], sp[4]))
			rig.anim.play(sp[1])
			rig.anim.seek(0.3, true)
		var horse := Models.instance("warhorse", 1.9)
		if horse:
			add_child(horse)
			horse.position = Vector3(7, 0, 0)
			horse.rotation_degrees.y = 180.0
		for i in 4:
			var w := Models.instance(["weapons/w_knights_longsword", "weapons/w_wizards_staff", "weapons/wpn_battle_bow", "weapons/w_reapers_scythe"][i], 1.2, Color.WHITE, true)
			if w:
				add_child(w)
				w.position = Vector3(-6 + i * 0.8, 0, 2)
	elif only != "":
		ids = [only]
		x = 0.0
	for id in ids:
		var h := 2.0
		if id in ["treegiant", "swampdragon", "mountaindragon", "house"]:
			h = 4.5
		var m := Models.instance(id, h)
		if m:
			add_child(m)
			m.position = Vector3(x, 0, 0)
			# Os modelos olham para -Z; giramos para olhar para a câmera (+Z)
			m.rotation_degrees.y = 180.0
		add_child(Build.label(id, Vector3(x, h + 0.8, 0), Color.WHITE, 48))
		x += 6.5
	var cam := Camera3D.new()
	cam.position = Vector3(0, 5, 22) if only == "" else (Vector3(0, 1.2, 4.0) if only == "rig" else Vector3(0, 3, 9))
	cam.rotation_degrees = Vector3(-10, 0, 0)
	add_child(cam)
	cam.make_current()
