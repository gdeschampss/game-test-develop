class_name Hud
extends CanvasLayer
## Interface no estilo dos MMORPGs clássicos (2004):
## - Quadro do jogador (retrato, nome, nível, vida vermelha, mana/fúria/foco) e quadro do alvo, em cima à esquerda.
## - Minimapa redondo com moldura, placa da zona e zoom (+/−), em cima à direita; missões embaixo dele.
## - Barra de ações longa no rodapé (pedra + moldura dourada), barra de XP roxa e micro-menu.
## - Registro de eventos no canto inferior esquerdo.

var player: Player
var show_combat := true
var minimap: Minimap

var _name_l: Label
var _level_l: Label
var _portrait_icon: TextureRect
var _hp_bar: ProgressBar
var _hp_text: Label
var _res_bar: ProgressBar
var _res_text: Label
var _target_root: Control
var _t_name: Label
var _t_level: Label
var _t_bar: ProgressBar
var _t_text: Label
var _t_letter: Label
var _xp_bar: ProgressBar
var _xp_text: Label
var _slots := {}
var _prompt: Label
var _toast: Label
var _toast_t := 0.0
var _cast_bar: ProgressBar
var _cast_label: Label
var _zone: Label
var _info: Label
var _quests: RichTextLabel
var _log: RichTextLabel
var _log_lines: Array[String] = []
var quest_lines: Array[String] = []

var external_progress := -1.0
var external_label := ""

const SLOT := 56.0
const SLOT_IDS := ["basic", "a1", "a2", "potion", "mount"]


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_player_frame(root)
	_build_target_frame(root)
	_build_minimap(root)
	_build_action_bar(root)
	_build_log(root)

	_prompt = _label(20, Color(1, 0.88, 0.35))
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_prompt, Control.PRESET_CENTER_BOTTOM, -300, -200, 600, 30)
	root.add_child(_prompt)
	_cast_bar = _bar(Color(0.95, 0.7, 0.15), Vector2(300, 16))
	_place(_cast_bar, Control.PRESET_CENTER_BOTTOM, -150, -250, 300, 16)
	root.add_child(_cast_bar)
	_cast_label = _label(15)
	_cast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_cast_label, Control.PRESET_CENTER_BOTTOM, -150, -274, 300, 22)
	root.add_child(_cast_label)
	# Mensagens no topo (estilo "texto de erro/aviso" amarelo do MMO clássico)
	_toast = _label(22, Color(1, 0.85, 0.2))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(_toast, Control.PRESET_CENTER_TOP, -420, 130, 840, 64)
	root.add_child(_toast)
	var cross := _label(20, Color(1, 1, 1, 0.5))
	cross.text = "+"
	_place(cross, Control.PRESET_CENTER, -6, -16, 20, 30)
	root.add_child(cross)

	Game.toast.connect(show_toast)
	Game.logged.connect(add_log)


# --- Construção --------------------------------------------------------------------

static func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func _nine(path: String, margin: int, sz: Vector2) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = _tex(path)
	n.patch_margin_left = margin
	n.patch_margin_right = margin
	n.patch_margin_top = margin
	n.patch_margin_bottom = margin
	n.size = sz
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n


func _ring(size: float, drop := true, flip := false) -> TextureRect:
	var r := TextureRect.new()
	r.texture = _tex("res://assets/ui/hud_ring_drop.png" if drop else "res://assets/ui/hud_ring.png")
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.size = Vector2(size, size)
	r.flip_h = flip
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _round_icon(size: float) -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.size = Vector2(size, size)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# máscara redonda
	var sh := Shader.new()
	sh.code = "shader_type canvas_item; void fragment(){ vec4 c = texture(TEXTURE, UV); float d = distance(UV, vec2(0.5)); COLOR = vec4(c.rgb, c.a * (1.0 - smoothstep(0.47, 0.5, d))); }"
	var m := ShaderMaterial.new()
	m.shader = sh
	t.material = m
	return t


## Quadro de unidade (jogador ou alvo), no layout da referência:
## retrato redondo com anel dourado + bloco de barras (faixa do nome, vida verde, recurso).
const BARS_W := 230.0
const PORTRAIT := 92.0


func _unit_frame(root: Control, x: float, mirrored: bool) -> Dictionary:
	var f := Control.new()
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(f, Control.PRESET_TOP_LEFT, x, 10, PORTRAIT + BARS_W, PORTRAIT + 8)
	root.add_child(f)
	var px := BARS_W - 18.0 if mirrored else 0.0
	var bx := 0.0 if mirrored else PORTRAIT - 18.0
	# bloco das barras (moldura de metal) — fica atrás do retrato
	var block := _nine("res://assets/ui/hud_bar_frame.png", 6, Vector2(BARS_W + 18, 62))
	block.position = Vector2(bx, 18)
	f.add_child(block)
	var inner_x := bx + (6.0 if mirrored else 24.0)
	var inner_w := BARS_W + 18 - 30.0
	var name_strip := ColorRect.new()
	name_strip.color = Color(0.45, 0.07, 0.05, 0.9) if mirrored else Color(0.06, 0.06, 0.07, 0.92)
	name_strip.position = Vector2(inner_x, 23)
	name_strip.size = Vector2(inner_w, 18)
	name_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.add_child(name_strip)
	var name_l := _label(15, Color(1, 0.82, 0.25))
	name_l.position = Vector2(inner_x + 6, 21)
	name_l.size = Vector2(inner_w - 40, 20)
	name_l.clip_text = true
	f.add_child(name_l)
	var lvl := _label(15, Color(1, 0.82, 0.25))
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lvl.position = Vector2(inner_x + inner_w - 44, 21)
	lvl.size = Vector2(38, 20)
	f.add_child(lvl)
	var hp := _bar(Color(0.18, 0.72, 0.1), Vector2(inner_w, 20))
	hp.position = Vector2(inner_x, 42)
	f.add_child(hp)
	var hp_t := _label(13)
	hp_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_t.position = Vector2(inner_x, 42)
	hp_t.size = Vector2(inner_w, 20)
	f.add_child(hp_t)
	var res := _bar(Color(0.1, 0.32, 0.95), Vector2(inner_w, 11))
	res.position = Vector2(inner_x, 63)
	f.add_child(res)
	var res_t := _label(10)
	res_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res_t.position = Vector2(inner_x, 61)
	res_t.size = Vector2(inner_w, 14)
	f.add_child(res_t)
	# retrato: fundo escuro + ícone circular + anel por cima (o anel só cobre a borda, não a imagem)
	var disc := _round_icon(PORTRAIT - 22)
	var dark := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	dark.fill(Color(0.08, 0.06, 0.05))
	var back := _round_icon(PORTRAIT - 20)
	back.texture = ImageTexture.create_from_image(dark)
	back.position = Vector2(px + 10, 10)
	f.add_child(back)
	disc.position = Vector2(px + 11, 11)
	f.add_child(disc)
	var letter := _label(38, Color(1, 0.85, 0.6))
	letter.add_theme_font_override("font", UITheme.title_font())
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter.position = disc.position
	letter.size = disc.size
	f.add_child(letter)
	var ring := _ring(PORTRAIT, true, mirrored)
	ring.position = Vector2(px, 0)
	f.add_child(ring)
	return {"root": f, "name": name_l, "level": lvl, "hp": hp, "hp_text": hp_t, "res": res, "res_text": res_t, "portrait": disc, "letter": letter, "strip": name_strip}


func _build_player_frame(root: Control) -> void:
	var u := _unit_frame(root, 12, false)
	_name_l = u["name"]
	_level_l = u["level"]
	_hp_bar = u["hp"]
	_hp_text = u["hp_text"]
	_res_bar = u["res"]
	_res_text = u["res_text"]
	_portrait_icon = u["portrait"]
	_info = _label(13, Color(0.85, 0.82, 0.72))
	_info.position = Vector2(PORTRAIT + 6, 84)
	_info.size = Vector2(300, 18)
	(u["root"] as Control).add_child(_info)


func _build_target_frame(root: Control) -> void:
	var u := _unit_frame(root, 360, true)
	_target_root = u["root"]
	_t_name = u["name"]
	_t_level = u["level"]
	_t_bar = u["hp"]
	_t_text = u["hp_text"]
	_t_letter = u["letter"]
	(u["res"] as Control).visible = false
	(u["res_text"] as Control).visible = false


func _build_minimap(root: Control) -> void:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(holder, Control.PRESET_TOP_RIGHT, -236, 6, 228, 262)
	root.add_child(holder)
	var plate := _nine("res://assets/ui/hud_panel.png", 8, Vector2(212, 30))
	plate.position = Vector2(8, 0)
	holder.add_child(plate)
	_zone = _label(15, Color(1, 0.82, 0.25))
	_zone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone.position = Vector2(14, 4)
	_zone.size = Vector2(200, 22)
	_zone.clip_text = true
	holder.add_child(_zone)
	minimap = Minimap.new()
	minimap.position = Vector2(30, 46)
	minimap.size = Vector2(172, 172)
	holder.add_child(minimap)
	var ring := _ring(196, false)
	ring.position = Vector2(18, 34)
	holder.add_child(ring)
	for i in 2:
		var b := TextureButton.new()
		b.texture_normal = _tex("res://assets/ui/hud_round_button.png")
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_SCALE
		b.size = Vector2(26, 26)
		b.position = Vector2(196, 168 + i * 28)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = "Aproximar" if i == 0 else "Afastar"
		var glyph := _label(18, Color(1, 0.85, 0.35))
		glyph.text = "+" if i == 0 else "−"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.size = Vector2(26, 26)
		b.add_child(glyph)
		var zoom_in := i == 0
		b.pressed.connect(func() -> void: minimap.range_m = clampf(minimap.range_m * (0.7 if zoom_in else 1.4), 40.0, 260.0))
		holder.add_child(b)
	_quests = RichTextLabel.new()
	_quests.bbcode_enabled = true
	_quests.fit_content = true
	_quests.scroll_active = false
	_quests.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quests.add_theme_font_size_override("normal_font_size", 15)
	_quests.add_theme_color_override("font_outline_color", Color.BLACK)
	_quests.add_theme_constant_override("outline_size", 5)
	_place(_quests, Control.PRESET_TOP_RIGHT, -330, 280, 320, 400)
	root.add_child(_quests)


## Barra de ações compacta: só o que existe (3 habilidades + poção + montaria) e o micro-menu.
func _build_action_bar(root: Control) -> void:
	var n := SLOT_IDS.size()
	var gap := 6.0
	var group_gap := 14.0  # separa habilidades de poção/montaria
	var micro := 4
	var micro_w := 34.0
	var slots_w := n * SLOT + (n - 1) * gap + group_gap
	var w := 18.0 + slots_w + 18.0 + micro * (micro_w + 4.0) + 10.0
	var h := SLOT + 26.0
	var bar := Control.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(bar, Control.PRESET_CENTER_BOTTOM, -w / 2.0, -h - 8, w, h)
	root.add_child(bar)
	var back := _nine("res://assets/ui/hud_panel.png", 10, Vector2(w, SLOT + 18))
	back.position = Vector2(0, 8)
	bar.add_child(back)
	_xp_bar = _bar(Color(0.55, 0.22, 0.8), Vector2(w - 24, 8))
	_xp_bar.position = Vector2(12, 0)
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.add_child(_xp_bar)
	_xp_text = _label(10)
	_xp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_text.position = Vector2(12, -4)
	_xp_text.size = Vector2(w - 24, 14)
	bar.add_child(_xp_text)
	var x := 18.0
	for i in n:
		if i == 3:
			x += group_gap
		var slot := _make_slot()
		slot["panel"].position = Vector2(x, 17)
		bar.add_child(slot["panel"])
		_slots[SLOT_IDS[i]] = slot
		x += SLOT + gap
	x += 12.0
	# micro-menu (funcional): personagem, mochila, missões, menu
	var micro_defs := [["I", "inventory", "Personagem (I)", "class_" + Game.class_id], ["U", "bag", "Mochila (U)", "bag"], ["L", "quest_log", "Missões (L)", "quest"], ["≡", "game_menu", "Menu (ESC)", ""]]
	for i in micro:
		var b := Button.new()
		b.flat = true
		b.tooltip_text = micro_defs[i][2]
		b.focus_mode = Control.FOCUS_NONE
		b.position = Vector2(x + i * (micro_w + 4.0), 17 + (SLOT - micro_w * 1.3) / 2.0)
		b.size = Vector2(micro_w, micro_w * 1.3)
		var fr := _nine("res://assets/ui/hud_slot.png", 8, b.size)
		b.add_child(fr)
		var gl := _label(16, Color(1, 0.85, 0.35))
		gl.text = micro_defs[i][0]
		gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		gl.size = b.size
		b.add_child(gl)
		var action: String = micro_defs[i][1]
		b.pressed.connect(func() -> void:
			var ev := InputEventAction.new()
			ev.action = action
			ev.pressed = true
			Input.parse_input_event(ev))
		bar.add_child(b)


## Slot da barra: fundo escuro, ícone no miolo e moldura de metal EM VOLTA (não cobre a arte do ícone).
const SLOT_INSET := 6.0


func _make_slot() -> Dictionary:
	var panel := Control.new()
	panel.size = Vector2(SLOT, SLOT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.035, 0.95)
	bg.position = Vector2(SLOT_INSET, SLOT_INSET)
	bg.size = Vector2(SLOT - SLOT_INSET * 2, SLOT - SLOT_INSET * 2)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	icon.position = bg.position
	icon.size = bg.size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)
	# recarga radial (como no MMO clássico)
	var cd_sweep := TextureProgressBar.new()
	cd_sweep.fill_mode = TextureProgressBar.FILL_COUNTER_CLOCKWISE
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0.66))
	cd_sweep.texture_progress = ImageTexture.create_from_image(img)
	cd_sweep.nine_patch_stretch = true
	cd_sweep.position = bg.position
	cd_sweep.size = bg.size
	cd_sweep.max_value = 1.0
	cd_sweep.step = 0.001
	cd_sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(cd_sweep)
	var frame := _nine("res://assets/ui/hud_slot.png", 8, Vector2(SLOT, SLOT))
	panel.add_child(frame)
	var key := _label(12, Color(0.95, 0.95, 0.95))
	key.position = Vector2(SLOT_INSET + 2, SLOT_INSET - 1)
	panel.add_child(key)
	var cd := _label(20, Color(1, 0.95, 0.6))
	cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd.size = Vector2(SLOT, SLOT)
	panel.add_child(cd)
	var cnt := _label(13)
	cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cnt.position = Vector2(0, SLOT - SLOT_INSET - 18)
	cnt.size = Vector2(SLOT - SLOT_INSET - 3, 18)
	panel.add_child(cnt)
	return {"panel": panel, "key": key, "cd": cd, "icon": icon, "sweep": cd_sweep, "frame": frame, "count": cnt, "active": false}


func _build_log(root: Control) -> void:
	var bg := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0.35)
	st.set_corner_radius_all(3)
	bg.add_theme_stylebox_override("panel", st)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(bg, Control.PRESET_BOTTOM_LEFT, 10, -300, 440, 190)
	root.add_child(bg)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.add_theme_font_size_override("normal_font_size", 14)
	_log.add_theme_color_override("font_outline_color", Color.BLACK)
	_log.add_theme_constant_override("outline_size", 4)
	_log.position = Vector2(6, 4)
	_log.size = Vector2(428, 182)
	bg.add_child(_log)


func add_log(text: String, color: Color) -> void:
	_log_lines.append("[color=#%s]%s[/color]" % [color.to_html(false), text])
	if _log_lines.size() > 60:
		_log_lines.pop_front()
	if _log:
		_log.text = "\n".join(_log_lines)


func _place(c: Control, preset: int, left: float, top: float, w: float, h: float) -> void:
	c.set_anchors_preset(preset)
	c.offset_left = left
	c.offset_top = top
	c.offset_right = left + w
	c.offset_bottom = top + h


func _label(font_size: int, color := Color(0.95, 0.93, 0.88)) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _bar(color: Color, sz: Vector2) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.size = sz
	b.custom_minimum_size = sz
	var fill := StyleBoxTexture.new()
	fill.texture = _tex("res://assets/ui/hud_bar_fill.png")
	fill.modulate_color = color
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.02, 0.02, 0.9)
	b.add_theme_stylebox_override("fill", fill)
	b.add_theme_stylebox_override("background", bg)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func show_toast(text: String) -> void:
	_toast.text = text
	_toast_t = 3.0


# --- Atualização ----------------------------------------------------------------

func _set_slot(id: String, key: String, cd_left: float, cd_total: float, locked_text := "", active := false, icon_name := "", count := -1, usable := true) -> void:
	var s: Dictionary = _slots[id]
	s["key"].text = key
	var tr: TextureRect = s["icon"]
	if icon_name != "" and tr.texture == null:
		tr.texture = Game.icon(icon_name)
	var sweep: TextureProgressBar = s["sweep"]
	var cd_label: Label = s["cd"]
	if locked_text != "":
		sweep.value = 1.0
		cd_label.text = locked_text
	elif cd_left > 0.0 and cd_total > 0.0:
		sweep.value = clampf(cd_left / cd_total, 0.0, 1.0)
		cd_label.text = "%.0f" % ceilf(cd_left) if cd_left >= 1.0 else ""
	else:
		sweep.value = 0.0
		cd_label.text = ""
	# sem recurso: ícone azulado (como no MMO clássico)
	tr.modulate = Color(1, 1, 1) if usable else Color(0.45, 0.45, 0.9)
	if s["active"] != active:
		s["active"] = active
		(s["frame"] as NinePatchRect).texture = _tex("res://assets/ui/hud_slot_active.png" if active else "res://assets/ui/hud_slot.png")
	(s["count"] as Label).text = str(count) if count >= 0 else ""


func _process(delta: float) -> void:
	_toast_t -= delta
	_toast.modulate.a = clampf(_toast_t, 0.0, 1.0)
	if player == null:
		return
	minimap.player = player
	if _portrait_icon.texture == null:
		_portrait_icon.texture = Game.icon(player.class_data.get("icon", ""))

	var d: Dictionary = Game.diff()
	_name_l.text = Game.char_name
	_level_l.text = str(player.level)
	_hp_bar.max_value = player.max_hp
	_hp_bar.value = player.hp
	_hp_text.text = "%d / %d" % [ceili(player.hp), ceili(player.max_hp)]
	var rd: Dictionary = ClassData.RESOURCES[player.res_type]
	(_res_bar.get_theme_stylebox("fill") as StyleBoxTexture).modulate_color = rd["color"]
	_res_bar.max_value = player.res_max
	_res_bar.value = player.res
	_res_text.text = "%s %d / %d" % [rd["name"], floori(player.res), roundi(player.res_max)]
	if show_combat:
		_info.text = "PA %d  ·  Ouro %d  ·  %s" % [player.armor_power, player.run_gold, d["name"]]
		_zone.text = minimap.zone_name
	else:
		_info.text = "PA %d  ·  Ouro %d  ·  Poções %d" % [player.armor_power, Game.gold, Game.potions]
		_zone.text = minimap.zone_name
	_xp_bar.max_value = player.xp_to_next
	_xp_bar.value = player.xp
	_xp_text.text = "XP %d / %d" % [player.xp, player.xp_to_next] if show_combat else ""

	var costs: Dictionary = player.class_data.get("costs", {})
	for id in ["basic", "a1", "a2"]:
		var a: Dictionary = player.abilities[id]
		var locked := "" if player.is_unlocked(id) else "nv%d" % a["unlock"]
		var usable := player.res >= float(costs.get(id, 0))
		_set_slot(id, a["key"], player.cooldowns[id], player.cooldown_of(id), locked, false, a.get("icon", ""), -1, usable)
	_set_slot("potion", "Q", player._potion_cd, 8.0, "" if Game.potions > 0 else "0", false, "potion", Game.potions)
	var mount_locked := "" if player.can_mount or player.mounted else "X"
	_set_slot("mount", "F", 0.0, 0.0, mount_locked, player.mounted, "horse")

	var t := player.last_target
	if show_combat and t != null and is_instance_valid(t) and t.hp > 0.0 and t.global_position.distance_to(player.global_position) < 40.0:
		_target_root.visible = true
		_t_name.text = t.display_name
		_t_name.add_theme_color_override("font_color", Color(1, 0.82, 0.25))
		_t_level.text = ("%d" % t.level) if not t.is_boss else "☠"
		_t_letter.text = t.display_name.substr(0, 1)
		_t_bar.max_value = t.max_hp
		_t_bar.value = t.hp
		_t_text.text = "%d / %d" % [ceili(t.hp), ceili(t.max_hp)]
	else:
		_target_root.visible = false

	if not quest_lines.is_empty() and show_combat:
		_quests.text = "[color=#ffd040][font_size=17]Missões[/font_size][/color]\n" + "\n".join(quest_lines)
	else:
		_quests.text = ""

	var target := player.nearest_interactable()
	_prompt.text = ("[E] " + str(target.get("prompt"))) if target else ""

	if player.mount_cast >= 0.0:
		_cast_bar.visible = true
		_cast_label.visible = true
		_cast_bar.max_value = Player.MOUNT_CAST_TIME
		_cast_bar.value = player.mount_cast
		_cast_label.text = "Invocando montaria..."
	elif external_progress >= 0.0:
		_cast_bar.visible = true
		_cast_label.visible = true
		_cast_bar.max_value = 1.0
		_cast_bar.value = external_progress
		_cast_label.text = external_label
	else:
		_cast_bar.visible = false
		_cast_label.visible = false
