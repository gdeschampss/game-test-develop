class_name GameMenu
extends CanvasLayer
## Menu do ESC. Se alguma janela estiver aberta, o ESC fecha ela primeiro.
## Na partida o jogo pausa enquanto o menu está aberto.

var in_run := false
var _panel: PanelContainer
var _box: VBoxContainer
var _confirm := false


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -190
	_panel.offset_right = 190
	_panel.offset_top = -250
	_panel.offset_bottom = 250
	add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	_panel.add_child(_box)
	_panel.visible = false


func is_open() -> bool:
	return _panel.visible


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("game_menu"):
		return
	get_viewport().set_input_as_handled()
	if _panel.visible:
		close()
		return
	# Escolha de cartas não pode ser fechada
	for cp in get_tree().get_nodes_in_group("card_picker"):
		if cp.visible:
			return
	if UIWin.close_all(get_tree()):
		return
	open()


func open() -> void:
	_confirm = false
	_fill()
	_panel.visible = true
	if in_run:
		get_tree().paused = true
	var p := get_tree().get_first_node_in_group("player") as Player
	if p:
		p.set_input_locked(true)


func close() -> void:
	_panel.visible = false
	if in_run:
		get_tree().paused = false
	UIWin.sync_lock(get_tree())


func _fill() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var t := UITheme.title("Menu do Jogo", 28)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	_button("Continuar", close)
	_button("Personagem (I)", func() -> void: _open_window(CharacterUI))
	_button("Mochila (U)", func() -> void: _open_window(BagUI))
	_button("Missões (L)", func() -> void: _open_window(QuestLog))
	_button("Controles", _show_controls)
	if in_run:
		_button("Clique de novo para confirmar" if _confirm else "Voltar para a cidade (abandona a partida)", func() -> void:
			if not _confirm:
				_confirm = true
				_fill()
				return
			get_tree().paused = false
			Game.abandon_run())
	else:
		_button("Trocar de personagem", func() -> void: Game.go_to_character_select())
	_button("Sair do jogo", func() -> void:
		Game.save_game()
		get_tree().quit())


func _button(text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 46
	b.pressed.connect(action)
	_box.add_child(b)


func _open_window(type) -> void:
	close()
	for w in get_tree().get_nodes_in_group("ui_window"):
		if is_instance_of(w, type):
			w.call("open")


func _show_controls() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	_box.add_child(UITheme.title("Controles", 24))
	_box.add_child(UITheme.text("WASD — andar\nEspaço — pular\nBotão direito (segurar) — girar câmera\nTAB — travar o mouse (modo action)\nScroll — zoom\nBotão esquerdo — ataque\n1 / 2 — habilidades\nQ — poção · F — cavalo\nE — interagir\nI — personagem · U — mochila · L — missões\nESC — menu", 17))
	_button("Voltar", _fill)
