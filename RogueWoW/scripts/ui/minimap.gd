class_name Minimap
extends Control
## Minimapa redondo (norte para cima) desenhado em 2D. O mundo informa os marcadores
## por `provider` (Callable que devolve uma lista de dicionários):
##   {"pos": Vector3, "color": Color, "shape": "dot"/"square"/"text"/"skull", "text": "!", "edge": true}
## "edge": true = se estiver fora do alcance, fica preso na borda (missões, portais).
## `lines`: lista de [Vector3, Vector3] desenhada como estradas.

var range_m := 110.0  ## alcance (zoom com os botões + e −)

var player: Player
var provider: Callable
var lines: Array = []
var zone_name := ""
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _to_map(world: Vector3, center: Vector2, radius: float) -> Vector2:
	var rel := Vector2(world.x - player.global_position.x, world.z - player.global_position.z)
	return center + rel * (radius / range_m)


func _draw() -> void:
	if player == null:
		return
	var radius := minf(size.x, size.y) / 2.0
	var center := size / 2.0
	draw_circle(center, radius, Color(0.16, 0.2, 0.12, 0.92))

	for l in lines:
		var a := _to_map(l[0], center, radius)
		var b := _to_map(l[1], center, radius)
		var ca := _clip(a, center, radius - 2.0)
		var cb := _clip(b, center, radius - 2.0)
		if (a - center).length() < radius or (b - center).length() < radius:
			draw_line(ca, cb, Color(0.6, 0.5, 0.3, 0.8), 3.0)

	if provider.is_valid():
		for m in provider.call():
			var p := _to_map(m["pos"], center, radius)
			var inside := (p - center).length() <= radius - 6.0
			if not inside:
				if not m.get("edge", false):
					continue
				p = center + (p - center).normalized() * (radius - 7.0)
			var c: Color = m["color"]
			match m.get("shape", "dot"):
				"dot":
					draw_circle(p, 3.0, c)
				"square":
					draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), c)
				"skull":
					draw_circle(p, 6.0, c)
					draw_string(_font, p + Vector2(-4, 5), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLACK)
				"text":
					draw_string_outline(_font, p + Vector2(-4, 7), m["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 4, Color.BLACK)
					draw_string(_font, p + Vector2(-4, 7), m["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, c)

	# Jogador: seta apontando para onde o personagem olha
	var yaw := player.model.rotation.y
	var fwd := Vector2(-sin(yaw), -cos(yaw))
	var right := Vector2(-fwd.y, fwd.x)
	var tri := PackedVector2Array([center + fwd * 9.0, center - fwd * 6.0 + right * 6.0, center - fwd * 6.0 - right * 6.0])
	draw_colored_polygon(tri, Color.WHITE)
	draw_string_outline(_font, Vector2(center.x - 4, 14), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 3, Color.BLACK)
	draw_string(_font, Vector2(center.x - 4, 14), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.85, 0.4))


func _clip(p: Vector2, center: Vector2, radius: float) -> Vector2:
	if (p - center).length() <= radius:
		return p
	return center + (p - center).normalized() * radius
