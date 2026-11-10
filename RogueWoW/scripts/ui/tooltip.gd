class_name Tooltip
extends CanvasLayer
## Caixa de dica que segue o mouse (estilo WoW). Fica no autoload Game: Game.tooltip.show_text(...)

var _panel: PanelContainer
var _label: RichTextLabel


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UITheme.panel_style(Color(0.03, 0.03, 0.07, 0.96), Color(0.55, 0.55, 0.65), 2, 4))
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.custom_minimum_size = Vector2(260, 0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("normal_font_size", 16)
	_panel.add_child(_label)
	add_child(_panel)
	_panel.visible = false


func show_text(bbcode: String) -> void:
	if bbcode == "":
		hide_tip()
		return
	_label.text = bbcode
	_panel.reset_size()
	_panel.visible = true
	_follow()


func hide_tip() -> void:
	_panel.visible = false


func _process(_delta: float) -> void:
	if _panel.visible:
		_follow()


func _follow() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var m := vp.get_mouse_position()
	var sz := _panel.size
	var screen := vp.get_visible_rect().size
	var pos := m + Vector2(18, 18)
	if pos.x + sz.x > screen.x:
		pos.x = m.x - sz.x - 12
	if pos.y + sz.y > screen.y:
		pos.y = m.y - sz.y - 12
	_panel.position = pos


## Liga a dica a um controle (mostra ao passar o mouse).
static func attach(c: Control, bbcode: String) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_entered.connect(func() -> void: Game.tooltip.show_text(bbcode))
	c.mouse_exited.connect(func() -> void: Game.tooltip.hide_tip())
	c.tree_exiting.connect(func() -> void: Game.tooltip.hide_tip())
