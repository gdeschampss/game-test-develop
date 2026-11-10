class_name NpcLook
extends RefCounted
## Visual dos NPCs: usa os modelos com cores diferentes (variação pelo nome) e respiração.

const TINTS := [Color(1, 1, 1), Color(0.8, 0.9, 1.0), Color(1.0, 0.9, 0.75), Color(0.85, 1.0, 0.85), Color(1.0, 0.82, 0.82)]


const NPC_CLASSES := ["guerreiro", "mago", "cacador", "bruxo"]
const NPC_RACES := ["humano", "anao", "elfo", "orc"]


static func make(npc_name: String) -> Node3D:
	var h := absi(npc_name.hash())
	var rig: CharacterRig = null
	var race: String = NPC_RACES[(h / 4) % 4]
	if h % 3 == 0 and race != "anao":
		# morador comum: roupa de camponês
		var kind := "peasant_f" if (h / 3) % 2 == 0 else "peasant_m"
		if CharacterRig.available(kind):
			var colors := CharacterRig.palette("cacador", race)
			colors["outfit_alt"] = (h / 7) % 2 == 0
			rig = CharacterRig.make(kind, 1.78, Color.WHITE, colors)
			rig.scale = ClassData.race(race).get("rig_scale", Vector3.ONE)
			rig.race_details(race, colors)
	else:
		# NPCs usam os humanos da Quaternius (os heróis são só do jogador)
		var cls: String = NPC_CLASSES[h % 4]
		var nk := CharacterRig.kind_for(race, "f" if h % 5 == 0 else "m")
		if CharacterRig.available(nk):
			var colors := CharacterRig.palette(cls, race)
			rig = CharacterRig.make(nk, 1.35 if race == "anao" else 1.78, Color.WHITE, colors)
			rig.equip_class(cls, colors)
			rig.scale = ClassData.race(race).get("rig_scale", Vector3.ONE)
			rig.race_details(race, colors)
	if rig:
		rig.anim.play("talk" if rig.anim.has_animation("talk") and h % 2 == 0 else "idle")
		var holder := Node3D.new()
		holder.rotation.y = PI  # olha para o sul
		holder.add_child(rig)
		return holder
	var model_id := "knight" if h % 2 == 0 else "darkelf"
	var root := Node3D.new()
	var m := Models.instance(model_id, 1.85, TINTS[h % TINTS.size()])
	if m:
		# vira para o sul (onde o jogador costuma chegar)
		m.rotation.y = PI
		root.add_child(m)
		var a := ProcAnim.new().setup(m, 1.85)
		root.add_child(a)
	else:
		var mi := Build.mesh(CapsuleMesh.new(), Color(0.7, 0.6, 0.45))
		mi.position.y = 1.0
		root.add_child(mi)
	return root
