extends Node
## Cena raiz: troca entre a cidade-hub e o mapa de partida.
## Na extração de PAUSA o mapa sai da árvore mas continua na memória (congelado),
## e volta exatamente como estava quando o jogador retoma.

const MenuScreen := preload("res://scripts/world/menu.gd")
const HubWorld := preload("res://scripts/world/hub.gd")
const FieldWorld := preload("res://scripts/world/field.gd")
const DemoWorld := preload("res://scripts/world/demo.gd")

var current: Node
var paused_field: Node


func _ready() -> void:
	Game.scene_requested.connect(func(n: String) -> void: _go.call_deferred(n))
	var args := OS.get_cmdline_user_args()
	if "--models" in args:
		add_child(preload("res://scripts/world/model_preview.gd").new())
	elif Game.smoke_test or "--field" in args or "--hub" in args or "--demo-scene" in args:
		# Testes e prints: cria um personagem temporário (--class=bruxo --race=orc)
		var cls := "mago"
		var rc := "humano"
		for a in args:
			if a.begins_with("--class="):
				cls = a.trim_prefix("--class=")
			if a.begins_with("--race="):
				rc = a.trim_prefix("--race=")
		Game.no_save = true
		Game.characters.clear()
		Game.select_character(Game.create_character("Teste", rc, cls))
		if "--hub" in args:
			_go("hub")
		elif "--demo-scene" in args:
			Game.setup_demo_inventory()
			_go("demo")
		else:
			Game.start_run(0)
	else:
		_go("menu")
	# Ferramenta de desenvolvimento: godot -- --shot /caminho/print.png
	var i := args.find("--shot")
	if i >= 0 and i + 1 < args.size():
		for f in 120:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(args[i + 1])
		get_tree().quit()


func _go(target: String) -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	match target:
		"menu":
			_free_paused_field()
			_set_current(MenuScreen.new(), "Menu")
		"hub":
			_free_paused_field()
			_set_current(HubWorld.new(), "Hub")
		"demo":
			_free_paused_field()
			_set_current(DemoWorld.new(), "Demo")
		"field":
			_free_paused_field()
			_set_current(FieldWorld.new(), "Field")
		"pause":
			# Tira o mapa da árvore sem destruir.
			paused_field = current
			remove_child(paused_field)
			current = null
			_set_current(HubWorld.new(), "Hub")
		"resume":
			if paused_field == null:
				_set_current(HubWorld.new(), "Hub")
				return
			if current:
				current.queue_free()
			current = paused_field
			paused_field = null
			add_child(current)
			current.call("on_resumed")


func _set_current(node: Node, node_name: String) -> void:
	if current:
		current.queue_free()
	current = node
	current.name = node_name
	add_child(current)


func _free_paused_field() -> void:
	if paused_field:
		paused_field.free()
		paused_field = null
