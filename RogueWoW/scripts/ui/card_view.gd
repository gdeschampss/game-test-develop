class_name CardView
extends RefCounted
## Desenha uma carta com moldura própria (estrutura clássica de card game: nome, arte, tipo, texto),
## cores pela escola de magia e pedra de raridade. Não copia moldura nem símbolos do Magic.

const SPELLS := ["leque_chamas", "combustao", "ruptura", "tiro_triplo", "flecha_perfurante", "matilha", "rajada_sombria", "explosao_sombria", "legiao", "sede_sangue"]
const RELICS := ["pele_geada", "pele_ferro", "vigor_selvagem", "carapaca_ossos", "celeridade", "vigor", "sede_arcana", "furia_berserker", "instinto_feral"]


static func card_type(id: String) -> String:
	if id in SPELLS:
		return "Feitiço"
	if id in RELICS:
		return "Relíquia"
	return "Encantamento"


## Arte da carta: ícone da habilidade que ela melhora.
static func art_icon(card: Dictionary, class_data: Dictionary) -> String:
	var ab: Dictionary = class_data["abilities"]
	var id: String = card["id"]
	var txt: String = card["text"]
	for key in ["basic", "a1", "a2"]:
		if txt.begins_with(ab[key]["name"]) or txt.find(ab[key]["name"]) >= 0:
			return ab[key]["icon"]
	if id in ["pele_geada", "pele_ferro", "vigor_selvagem", "carapaca_ossos"]:
		return "slot_chest"
	if id in ["celeridade", "vigor"]:
		return "leap"
	if id in ["sede_arcana"]:
		return "potion"
	if id in ["instinto_feral", "matilha"]:
		return "class_cacador"
	if id in ["furia_berserker"]:
		return "charge"
	return class_data.get("icon", "fireball")


static func make(card: Dictionary, class_data: Dictionary, w := 230.0) -> Control:
	var h := w * 1.43
	var school_col: Color = ClassData.SCHOOL_COLORS.get(card["school"], Color.GRAY)
	var rarity_col: Color = ClassData.RARITY_COLORS.get(card["rarity"], Color.WHITE)

	var root := Panel.new()
	root.custom_minimum_size = Vector2(w, h)
	var frame := StyleBoxFlat.new()
	frame.bg_color = school_col.darkened(0.55)
	frame.border_color = Color(0.08, 0.06, 0.05)
	frame.set_border_width_all(int(w * 0.035))
	frame.set_corner_radius_all(int(w * 0.05))
	frame.shadow_color = Color(0, 0, 0, 0.6)
	frame.shadow_size = 10
	root.add_theme_stylebox_override("panel", frame)
	var pad := w * 0.06

	# Barra do nome
	var name_bar := Panel.new()
	name_bar.position = Vector2(pad, pad)
	name_bar.size = Vector2(w - pad * 2, h * 0.09)
	name_bar.add_theme_stylebox_override("panel", _plate(Color(0.93, 0.86, 0.68), school_col))
	name_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(name_bar)
	var nm := Label.new()
	nm.text = card["name"]
	nm.add_theme_font_override("font", UITheme.title_font())
	nm.add_theme_font_size_override("font_size", int(w * 0.068))
	nm.add_theme_color_override("font_color", Color(0.12, 0.08, 0.05))
	nm.add_theme_constant_override("outline_size", 0)
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.position = Vector2(8, 0)
	nm.size = Vector2(name_bar.size.x - 40, name_bar.size.y)
	nm.clip_text = true
	name_bar.add_child(nm)
	# Pedra da escola (canto direito da barra)
	var pip := Panel.new()
	var pip_st := StyleBoxFlat.new()
	pip_st.bg_color = school_col
	pip_st.border_color = Color(0.1, 0.07, 0.04)
	pip_st.set_border_width_all(2)
	pip_st.set_corner_radius_all(100)
	pip.add_theme_stylebox_override("panel", pip_st)
	var ps := name_bar.size.y * 0.72
	pip.size = Vector2(ps, ps)
	pip.position = Vector2(name_bar.size.x - ps - 6, (name_bar.size.y - ps) / 2.0)
	pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_bar.add_child(pip)

	# Arte
	var art_box := Panel.new()
	art_box.position = Vector2(pad, pad + h * 0.1)
	art_box.size = Vector2(w - pad * 2, h * 0.42)
	var art_st := StyleBoxFlat.new()
	art_st.bg_color = school_col.darkened(0.3)
	art_st.border_color = Color(0.1, 0.07, 0.04)
	art_st.set_border_width_all(3)
	art_box.add_theme_stylebox_override("panel", art_st)
	art_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(art_box)
	var art := TextureRect.new()
	art.texture = Game.icon(art_icon(card, class_data))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.position = Vector2(3, 3)
	art.size = art_box.size - Vector2(6, 6)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_box.add_child(art)

	# Linha de tipo + raridade
	var type_bar := Panel.new()
	type_bar.position = Vector2(pad, pad + h * 0.53)
	type_bar.size = Vector2(w - pad * 2, h * 0.075)
	type_bar.add_theme_stylebox_override("panel", _plate(Color(0.88, 0.8, 0.62), school_col))
	type_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(type_bar)
	var tl := Label.new()
	tl.text = "%s — %s" % [card_type(card["id"]), card["school"]]
	tl.add_theme_font_size_override("font_size", int(w * 0.058))
	tl.add_theme_color_override("font_color", Color(0.15, 0.1, 0.06))
	tl.add_theme_constant_override("outline_size", 0)
	tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tl.position = Vector2(8, 0)
	tl.size = Vector2(type_bar.size.x - 30, type_bar.size.y)
	type_bar.add_child(tl)
	var gem := Panel.new()
	var gem_st := StyleBoxFlat.new()
	gem_st.bg_color = rarity_col
	gem_st.border_color = Color(0.1, 0.07, 0.04)
	gem_st.set_border_width_all(2)
	gem_st.set_corner_radius_all(3)
	gem.add_theme_stylebox_override("panel", gem_st)
	var gs := type_bar.size.y * 0.55
	gem.size = Vector2(gs, gs)
	gem.position = Vector2(type_bar.size.x - gs - 8, (type_bar.size.y - gs) / 2.0)
	gem.rotation = PI / 4.0
	gem.pivot_offset = gem.size / 2.0
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_bar.add_child(gem)

	# Caixa de texto (pergaminho)
	var text_box := Panel.new()
	text_box.position = Vector2(pad, pad + h * 0.615)
	text_box.size = Vector2(w - pad * 2, h * 0.3)
	var tb := StyleBoxFlat.new()
	tb.bg_color = Color(0.95, 0.91, 0.8)
	tb.border_color = school_col.darkened(0.2)
	tb.set_border_width_all(2)
	text_box.add_theme_stylebox_override("panel", tb)
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(text_box)
	var desc := Label.new()
	desc.text = card["text"]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", int(w * 0.068))
	desc.add_theme_color_override("font_color", Color(0.12, 0.09, 0.06))
	desc.add_theme_constant_override("outline_size", 0)
	desc.position = Vector2(8, 6)
	desc.size = text_box.size - Vector2(16, 12)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(desc)

	var foot := Label.new()
	foot.text = "%s · %s" % [class_data["name"], card["rarity"].capitalize()]
	foot.add_theme_font_size_override("font_size", int(w * 0.05))
	foot.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	foot.position = Vector2(pad + 4, h - pad - w * 0.065)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(foot)
	return root


static func _plate(bg: Color, border: Color) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border.darkened(0.3)
	st.set_border_width_all(2)
	st.set_corner_radius_all(8)
	return st
