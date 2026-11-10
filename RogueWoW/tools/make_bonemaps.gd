extends SceneTree
## Gera os BoneMaps (perfil humanoide) dos heróis para o retarget no import.
func _map(dict: Dictionary, path: String) -> void:
	var bm := BoneMap.new()
	bm.profile = SkeletonProfileHumanoid.new()
	for k in dict:
		bm.set_skeleton_bone_name(k, dict[k])
	print(path, " ", ResourceSaver.save(bm, path))


func _arms(d: Dictionary, names: Array, fingers: Dictionary) -> void:
	# names: [clavicle, upper, lower, hand] com %s = lado
	for side in [["Left", "L", "l"], ["Right", "R", "r"]]:
		var P: String = side[0]
		var keys := ["Shoulder", "UpperArm", "LowerArm", "Hand"]
		for i in 4:
			d[P + keys[i]] = (names[i] as String).replace("{S}", side[1]).replace("{s}", side[2])
		for f in fingers:
			var segs := ["Metacarpal", "Proximal", "Distal"] if f == "Thumb" else ["Proximal", "Intermediate", "Distal"]
			var arr: Array = fingers[f]
			for i in arr.size():
				d[P + f + segs[i]] = (arr[i] as String).replace("{S}", side[1]).replace("{s}", side[2])


func _legs(d: Dictionary, names: Array) -> void:
	for side in [["Left", "L", "l"], ["Right", "R", "r"]]:
		var keys := ["UpperLeg", "LowerLeg", "Foot", "Toes"]
		for i in names.size():
			d[side[0] + keys[i]] = (names[i] as String).replace("{S}", side[1]).replace("{s}", side[2])


func _init() -> void:
	var drow := {"Hips": "root", "Spine": "spine1", "Chest": "spine2", "UpperChest": "spine3", "Neck": "neck1", "Head": "head"}
	_arms(drow, ["clavicle_{S}", "bicep_{S}", "elbow_{S}", "wrist_{S}"], {"Thumb": ["thumb_0_{S}", "thumb_1_{S}", "thumb_2_{S}"], "Index": ["index_0_{S}", "index_1_{S}", "index_2_{S}"], "Middle": ["mid_0_{S}", "mid_1_{S}"]})
	_legs(drow, ["thigh_{S}", "knee_{S}", "ankle_{S}", "toeBase_{S}"])
	_map(drow, "res://assets/characters/heroes/ranger/map.tres")
	var enigma := {"Hips": "Root_0", "Spine": "Spine_0", "Chest": "Spine_1", "UpperChest": "Spine_3", "Neck": "Head_0", "Head": "Head_1"}
	_arms(enigma, ["clavicle_{S}", "bicep_{S}", "elbow_{S}", "wrist_{S}"], {"Thumb": ["thumb_0_{S}", "thumb_1_{S}", "thumb_2_{S}"], "Index": ["index_0_{S}", "index_1_{S}", "index_2_{S}"], "Middle": ["mid_0_{S}", "mid_1_{S}", "mid_2_{S}"], "Ring": ["ring_0_{S}", "ring_1_{S}", "ring_2_{S}"]})
	_map(enigma, "res://assets/characters/heroes/wizard/map.tres")
	var wl := {"Root": "root", "Hips": "pelvis", "Spine": "spine_01", "Chest": "spine_03", "UpperChest": "spine_05", "Neck": "neck_01", "Head": "head"}
	_arms(wl, ["clavicle_{s}", "upperarm_{s}", "lowerarm_{s}", "hand_{s}"], {"Thumb": ["thumb_01_{s}", "thumb_02_{s}", "thumb_03_{s}"], "Index": ["index_01_{s}", "index_02_{s}", "index_03_{s}"], "Middle": ["middle_01_{s}", "middle_02_{s}", "middle_03_{s}"], "Ring": ["ring_01_{s}", "ring_02_{s}", "ring_03_{s}"], "Little": ["pinky_01_{s}", "pinky_02_{s}", "pinky_03_{s}"]})
	_legs(wl, ["thigh_{s}", "calf_{s}", "foot_{s}", "ball_{s}"])
	_map(wl, "res://assets/characters/heroes/warlock/map.tres")
	_map(wl, "res://assets/characters/heroes/mage/map.tres")
	var bear := {"Hips": "Root_0", "Spine": "Spine_0", "Chest": "Spine_1", "UpperChest": "Spine_3", "Neck": "Head_0", "Head": "Head_1"}
	_arms(bear, ["clavicle_{S}", "bicep_{S}", "elbow_{S}", "wrist_{S}"], {"Thumb": ["thumb_0_{S}", "thumb_1_{S}"]})
	_legs(bear, ["thigh_{S}", "knee_{S}", "ankle_{S}", "toeBase_{S}"])
	_map(bear, "res://assets/characters/heroes/pet/map.tres")
	quit()
