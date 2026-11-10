extends Node
## Tela inicial: escolher, criar e apagar personagens (até 4). Sem personalização por enquanto:
## só nome, raça e classe.

var _ui: Control
var _slots_box: VBoxContainer
var _name_edit: LineEdit
var _race_box: HBoxContainer
var _class_box: HBoxContainer
var _desc: Label
var _create_btn: Button
var _play_btn: Button
var _demo_btn: Button
var _delete_btn: Button
var _selected := -1
var _new_race := "humano"
var _new_class := "guerreiro"
var _new_sex := "m"
var _sex_box: HBoxContainer
var _confirm_delete := false
var _preview_holder: VBoxContainer
var _preview_pivot: Node3D
var _preview_key := ""
var _creating := false


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_ui)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.06, 0.08)
	_ui.add_child(bg)
	# fundo pintado da tela de personagens + véu escuro para o texto ficar legível
	var art_path := "res://assets/ui/backgrounds/forest_ruins.jpg"
	if ResourceLoader.exists(art_path):
		var art := TextureRect.new()
		art.texture = load(art_path)
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_ui.add_child(art)
		var veil := ColorRect.new()
		veil.set_anchors_preset(Control.PRESET_FULL_RECT)
		veil.color = Color(0, 0, 0, 0.45)
		_ui.add_child(veil)

	var title := UITheme.title("Vale das Três Terras", 54)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -500
	title.offset_right = 500
	title.offset_top = 40
	title.offset_bottom = 110
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.add_child(title)

	var columns := HBoxContainer.new()
	columns.set_anchors_preset(Control.PRESET_FULL_RECT)
	columns.offset_left = 80
	columns.offset_right = -80
	columns.offset_top = 140
	columns.offset_bottom = -40
	columns.add_theme_constant_override("separation", 30)
	_ui.add_child(columns)

	# Coluna esquerda: personagens
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 400
	left.add_theme_constant_override("separation", 12)
	columns.add_child(left)
	left.add_child(_label("Seus personagens (%d no máximo)" % Game.MAX_CHARACTERS, 24, Color(1, 0.9, 0.7)))
	_slots_box = VBoxContainer.new()
	_slots_box.add_theme_constant_override("separation", 8)
	left.add_child(_slots_box)
	_play_btn = _button("Entrar no mundo", _play, 58)
	left.add_child(_play_btn)
	_demo_btn = _button("Cena de demonstração (visual)", _demo, 36)
	left.add_child(_demo_btn)
	_delete_btn = _button("Apagar personagem", _delete, 40)
	left.add_child(_delete_btn)

	# Coluna do meio: personagem em 3D
	_preview_holder = VBoxContainer.new()
	_preview_holder.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_child(_preview_holder)

	# Coluna direita: criar personagem
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)
	right.add_child(_label("Criar personagem", 24, Color(1, 0.9, 0.7)))
	right.add_child(_label("Nome", 16, Color(0.8, 0.8, 0.8)))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Nome do personagem"
	_name_edit.max_length = 16
	_name_edit.custom_minimum_size.y = 40
	right.add_child(_name_edit)
	# Cada classe é um herói fixo: não se escolhe mais raça nem corpo (caixas ficam fora da tela)
	_race_box = HBoxContainer.new()
	_sex_box = HBoxContainer.new()
	for sx in [["m", "Masculino"], ["f", "Feminino"]]:
		var sid: String = sx[0]
		var sb := _button(sx[1], func() -> void:
			_new_sex = sid
			_creating = true
			_refresh(), 44)
		sb.custom_minimum_size.x = 140
		sb.set_meta("id", sid)
		_sex_box.add_child(sb)
	right.add_child(_label("Herói", 16, Color(0.8, 0.8, 0.8)))
	_class_box = HBoxContainer.new()
	right.add_child(_class_box)
	_desc = _label("", 17, Color(0.92, 0.92, 0.92))
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size.y = 150
	right.add_child(_desc)
	_create_btn = _button("Criar personagem", _create, 50)
	right.add_child(_create_btn)

	for r in ClassData.RACE_ORDER:
		var b := _button(ClassData.race(r)["name"], func() -> void:
			_new_race = r
			_creating = true
			_refresh(), 44)
		b.toggle_mode = true
		b.custom_minimum_size.x = 140
		b.set_meta("id", r)
		_race_box.add_child(b)
	for c in ClassData.CLASS_ORDER:
		var b := _button(ClassData.for_class(c)["name"], func() -> void:
			_new_class = c
			_creating = true
			_refresh(), 44)
		b.toggle_mode = true
		b.custom_minimum_size.x = 140
		b.set_meta("id", c)
		_class_box.add_child(b)

	if not Game.characters.is_empty():
		_selected = clampi(Game.current_char, 0, Game.characters.size() - 1)
	else:
		_creating = true
	_refresh()


func _process(delta: float) -> void:
	if _preview_pivot:
		_preview_pivot.rotation.y += delta * 0.5


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, action: Callable, height := 44) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = height
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(action)
	return b


func _refresh() -> void:
	for c in _slots_box.get_children():
		_slots_box.remove_child(c)
		c.queue_free()
	for i in Game.characters.size():
		var ch: Dictionary = Game.characters[i]
		var text := "%s\n%s · PA %d" % [ch["name"], ClassData.for_class(ch["class"])["name"], _pa_of(ch)]
		var b := _button(text, func() -> void:
			_selected = i
			_creating = false
			_refresh(), 70)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_highlight(b, i == _selected)
		_slots_box.add_child(b)
	for i in Game.MAX_CHARACTERS - Game.characters.size():
		var empty := _label("— espaço livre —", 16, Color(0.5, 0.5, 0.5))
		empty.custom_minimum_size.y = 70
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_slots_box.add_child(empty)

	for b in _race_box.get_children():
		_highlight(b as Button, b.get_meta("id") == _new_race)
	for b in _class_box.get_children():
		_highlight(b as Button, b.get_meta("id") == _new_class)
	for b in _sex_box.get_children():
		_highlight(b as Button, b.get_meta("id") == _new_sex)
	var rc := ClassData.race(_new_race)
	var cl := ClassData.for_class(_new_class)
	var ab: Dictionary = cl["abilities"]
	var extra := ""
	if _new_class == "cacador":
		extra = "\nAnimal: %s." % cl.get("pet", rc["pet"])
	_desc.text = "%s — %s\n\nHabilidades: %s (nv 1), %s (nv 2), %s (nv 4).%s" % [cl["name"], cl.get("hero_desc", cl["desc"]), ab["basic"]["name"], ab["a1"]["name"], ab["a2"]["name"], extra]

	# Prévia: personagem selecionado ou o que está sendo criado
	var pv_class := _new_class
	var pv_race := _new_race
	var pv_sex := _new_sex
	if _selected >= 0 and _selected < Game.characters.size() and not _creating:
		pv_class = Game.characters[_selected]["class"]
		pv_race = Game.characters[_selected]["race"]
		pv_sex = Game.characters[_selected].get("sex", "m")
	var key := pv_class + pv_race + pv_sex
	if key != _preview_key:
		_preview_key = key
		for c in _preview_holder.get_children():
			c.queue_free()
		var pv := Preview3D.make(pv_class, pv_race, Vector2i(320, 420), pv_sex)
		_preview_pivot = pv["pivot"]
		_preview_holder.add_child(pv["control"])
		var cap := UITheme.title(ClassData.for_class(pv_class)["name"], 22)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_preview_holder.add_child(cap)

	var full := Game.characters.size() >= Game.MAX_CHARACTERS
	_create_btn.disabled = full
	_create_btn.text = "Todos os espaços ocupados" if full else "Criar personagem"
	_play_btn.disabled = _selected < 0 or _selected >= Game.characters.size()
	_delete_btn.disabled = _play_btn.disabled
	_demo_btn.disabled = _play_btn.disabled
	_confirm_delete = false
	_delete_btn.text = "Apagar personagem"


## Destaca o botão escolhido com borda dourada.
func _highlight(b: Button, on: bool) -> void:
	b.button_pressed = on
	if on:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.28, 0.2, 0.08)
		st.border_color = Color(1, 0.8, 0.35)
		st.set_border_width_all(3)
		st.set_corner_radius_all(4)
		for state in ["normal", "pressed", "hover", "focus"]:
			b.add_theme_stylebox_override(state, st)
		b.add_theme_color_override("font_color", Color(1, 0.88, 0.5))
		b.add_theme_color_override("font_pressed_color", Color(1, 0.88, 0.5))
	else:
		for state in ["normal", "pressed", "hover", "focus"]:
			b.remove_theme_stylebox_override(state)
		b.remove_theme_color_override("font_color")
		b.remove_theme_color_override("font_pressed_color")


func _pa_of(ch: Dictionary) -> int:
	var total := 0
	for slot in ch.get("equipment", {}):
		total += int(Game.recipe(ch["equipment"][slot]).get("pa", 0))
	return total


func _create() -> void:
	var n := _name_edit.text.strip_edges()
	if n == "":
		n = ClassData.for_class(_new_class)["name"]
	var idx := Game.create_character(n, _new_race, _new_class, _new_sex)
	if idx >= 0:
		_selected = idx
		_name_edit.text = ""
	_refresh()


func _delete() -> void:
	if _selected < 0:
		return
	if not _confirm_delete:
		_confirm_delete = true
		_delete_btn.text = "Clique de novo para apagar %s para sempre" % Game.characters[_selected]["name"]
		return
	_confirm_delete = false
	Game.delete_character(_selected)
	_selected = mini(_selected, Game.characters.size() - 1)
	_refresh()


func _play() -> void:
	if _selected < 0 or _selected >= Game.characters.size():
		return
	Game.select_character(_selected)
	Game.save_game()
	Game.scene_requested.emit("hub")


## Abre a cena de demonstração da direção de arte com o personagem escolhido (não salva).
func _demo() -> void:
	if _selected < 0 or _selected >= Game.characters.size():
		return
	Game.select_character(_selected)
	Game.start_demo()
