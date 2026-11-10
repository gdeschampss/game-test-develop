class_name UITheme
extends RefCounted
## Tema visual da interface (inspirado em RPGs dos anos 2000): painéis escuros com moldura dourada,
## botões em relevo, fonte Alegreya Sans no texto e Cinzel nos títulos.

const GOLD := Color(0.86, 0.68, 0.32)
const GOLD_LIGHT := Color(1.0, 0.85, 0.45)
const DARK := Color(0.07, 0.055, 0.045, 0.94)
const TEXT := Color(0.95, 0.92, 0.85)
const RARITY := {
	"comum": Color(0.92, 0.92, 0.92),
	"incomum": Color(0.3, 0.9, 0.35),
	"rara": Color(0.35, 0.6, 1.0),
	"mítica": Color(0.75, 0.4, 1.0),
}

static var _title_font: Font
static var _body_font: Font


static func title_font() -> Font:
	if _title_font == null:
		_title_font = load("res://assets/fonts/Cinzel.ttf")
	return _title_font


static func body_font() -> Font:
	if _body_font == null:
		_body_font = load("res://assets/fonts/Alegreya.ttf")
	return _body_font


static func panel_style(bg := DARK, border := GOLD, width := 3, radius := 6) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(width)
	st.set_corner_radius_all(radius)
	st.shadow_color = Color(0, 0, 0, 0.6)
	st.shadow_size = 8
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	return st


## Estilo de janela com textura (metal escuro + filete dourado), 9-patch.
static func window_style(margin := 14) -> StyleBox:
	var path := "res://assets/ui/hud_window.png"
	if not ResourceLoader.exists(path):
		return panel_style()
	var st := StyleBoxTexture.new()
	st.texture = load(path)
	st.texture_margin_left = 14
	st.texture_margin_right = 14
	st.texture_margin_top = 14
	st.texture_margin_bottom = 14
	st.content_margin_left = margin + 4
	st.content_margin_right = margin + 4
	st.content_margin_top = margin
	st.content_margin_bottom = margin
	return st


static func tex_button(path: String) -> StyleBox:
	if not ResourceLoader.exists(path):
		return button_style(Color(0.22, 0.12, 0.07), Color(0.6, 0.45, 0.2))
	var st := StyleBoxTexture.new()
	st.texture = load(path)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_texture_margin(side, 8)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 6
	st.content_margin_bottom = 6
	return st


static func button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(2)
	st.border_width_bottom = 4
	st.set_corner_radius_all(4)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 6
	st.content_margin_bottom = 6
	return st


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 18
	t.set_stylebox("panel", "PanelContainer", window_style())
	t.set_stylebox("panel", "Panel", window_style())

	t.set_stylebox("normal", "Button", tex_button("res://assets/ui/hud_button.png"))
	t.set_stylebox("hover", "Button", tex_button("res://assets/ui/hud_button_hover.png"))
	t.set_stylebox("pressed", "Button", tex_button("res://assets/ui/hud_button_pressed.png"))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("disabled", "Button", tex_button("res://assets/ui/hud_button_disabled.png"))
	t.set_color("font_color", "Button", GOLD_LIGHT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.47, 0.42))

	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.85))
	t.set_constant("outline_size", "Label", 4)

	var le := button_style(Color(0.05, 0.04, 0.03), Color(0.55, 0.42, 0.2))
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", button_style(Color(0.05, 0.04, 0.03), GOLD_LIGHT))
	t.set_color("font_color", "LineEdit", TEXT)

	var tip := panel_style(Color(0.03, 0.03, 0.06, 0.96), Color(0.6, 0.6, 0.7), 2, 4)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", TEXT)

	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(0.55, 0.42, 0.2)
	grabber.set_corner_radius_all(4)
	t.set_stylebox("grabber", "VScrollBar", grabber)
	t.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.4)
	t.set_stylebox("scroll", "VScrollBar", track)
	return t


## Label de título com a fonte Cinzel dourada.
static func title(text: String, size := 26, color := GOLD_LIGHT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", title_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 6)
	return l


static func text(t: String, size := 17, color := TEXT, wrap := false) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 200
	return l


## Quadradinho com ícone, borda pela raridade e número (pilha) no canto.
static func icon_slot(tex: Texture2D, size := 56.0, border := Color(0.45, 0.38, 0.28), count := 0) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(size, size)
	p.size = Vector2(size, size)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.03, 0.035, 0.95)
	p.add_theme_stylebox_override("panel", st)
	var inset := roundf(size * 0.1)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.position = Vector2(inset, inset)
	tr.size = Vector2(size - inset * 2, size - inset * 2)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(tr)
	# moldura de metal em volta (o miolo é transparente: não cobre o ícone)
	var fr := NinePatchRect.new()
	fr.texture = load("res://assets/ui/hud_slot.png") if ResourceLoader.exists("res://assets/ui/hud_slot.png") else null
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		fr.set_patch_margin(side, 8)
	fr.size = Vector2(size, size)
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(fr)
	# raridade: filete colorido logo por dentro da moldura
	var rar := Panel.new()
	var rs := StyleBoxFlat.new()
	rs.draw_center = false
	rs.border_color = border
	rs.set_border_width_all(2)
	rar.add_theme_stylebox_override("panel", rs)
	rar.position = Vector2(inset - 2, inset - 2)
	rar.size = Vector2(size - inset * 2 + 4, size - inset * 2 + 4)
	rar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(rar)
	if count > 1:
		var c := Label.new()
		c.text = str(count)
		c.add_theme_font_size_override("font_size", 16)
		c.add_theme_constant_override("outline_size", 6)
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		c.position = Vector2(0, size - 24)
		c.size = Vector2(size - 5, 22)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(c)
	return p
