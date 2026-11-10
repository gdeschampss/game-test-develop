extends SceneTree
## Ferramenta: junta as animações FBX do anão numa AnimationLibrary (.res) para o jogo.
## Rodar: godot --headless --path . -s tools/build_dwarf_anims.gd
## (copie antes os FBX de animação do pacote para assets/characters/dwarf/anims_m e anims_f;
##  depois de gerar os .res, eles podem ser apagados)

const CLIPS := {
	"idle": "Idle01", "combat_idle": "CombatIdle1H01", "run": "Run01_Forward", "run_back": "Run01_Backward",
	"run_left": "Run01_Left", "run_right": "Run01_Right", "attack_1h": "Attack1H01_R", "attack_cast": "Attack1H02_R",
	"attack_2h": "Attack2H01", "attack_shield": "AttackShield01", "attack_polearm": "AttackPolearm01",
	"hit": "CombatDamage01", "death": "Death01",
}
const LOOPS := ["idle", "combat_idle", "run", "run_back", "run_left", "run_right"]


func _build(prefix: String, folder: String, out: String) -> void:
	var lib := AnimationLibrary.new()
	for key in CLIPS:
		var path := "res://assets/characters/dwarf/%s/%s@%s.fbx" % [folder, prefix, CLIPS[key]]
		if not ResourceLoader.exists(path):
			print("faltando ", path)
			continue
		var sc: Node = load(path).instantiate()
		var ap: AnimationPlayer = sc.find_children("*", "AnimationPlayer", true, false)[0]
		var anim: Animation = ap.get_animation(ap.get_animation_list()[0]).duplicate(true)
		anim.loop_mode = Animation.LOOP_LINEAR if key in LOOPS else Animation.LOOP_NONE
		lib.add_animation(key, anim)
		sc.free()
	print(out, " -> ", ResourceSaver.save(lib, out), " clips=", lib.get_animation_list().size())


func _init() -> void:
	_build("DwarfM", "anims_m", "res://assets/characters/dwarf/dwarf_m_anims.res")
	_build("DwarfF", "anims_f", "res://assets/characters/dwarf/dwarf_f_anims.res")
	quit()
