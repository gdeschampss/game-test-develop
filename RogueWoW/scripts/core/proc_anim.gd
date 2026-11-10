class_name ProcAnim
extends Node
## Animação procedural para modelos estáticos (sem esqueleto): respiração parado, balanço ao andar,
## investida ao atacar e "tranco" ao tomar dano. Mexe só no nó visual (target), nunca na física.
## Quando tivermos modelos com animação de verdade (Mixamo), isto é substituído pelo AnimationPlayer.

var target: Node3D
var height := 2.0
var bob := 0.08  ## amplitude do balanço ao andar (proporcional à altura)
var flying := false

var _t := 0.0
var _speed := 0.0
var _attack_t := 0.0
var _hit_t := 0.0
var _base_pos := Vector3.ZERO
var _base_rot := Vector3.ZERO


func setup(p_target: Node3D, p_height: float) -> ProcAnim:
	target = p_target
	height = p_height
	_base_pos = target.position
	_base_rot = target.rotation
	return self


## speed_ratio: 0 parado, 1 correndo
func set_moving(speed_ratio: float) -> void:
	_speed = clampf(speed_ratio, 0.0, 1.5)


func attack() -> void:
	_attack_t = 0.3


func hit() -> void:
	_hit_t = 0.2


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	_t += delta * (6.0 + 6.0 * _speed)
	_attack_t = maxf(0.0, _attack_t - delta)
	_hit_t = maxf(0.0, _hit_t - delta)
	var pos := _base_pos
	var rot := _base_rot
	var sc := 1.0
	if _speed > 0.05:
		pos.y += absf(sin(_t)) * bob * height * _speed
		rot.z += sin(_t) * 0.06 * _speed
		rot.x -= 0.08 * _speed
	else:
		# respiração
		sc = 1.0 + sin(_t * 0.35) * 0.012
	if flying:
		pos.y += sin(_t * 0.4) * 0.15 * height
	if _attack_t > 0.0:
		var k := sin((_attack_t / 0.3) * PI)
		pos.z -= k * 0.25 * height
		rot.x -= k * 0.25
	if _hit_t > 0.0:
		var k2 := _hit_t / 0.2
		sc *= 1.0 - 0.08 * k2
		rot.x += 0.12 * k2
	target.position = pos
	target.rotation = rot
	target.scale = Vector3(1.0 / sc, sc, 1.0 / sc) if sc != 1.0 else Vector3.ONE
