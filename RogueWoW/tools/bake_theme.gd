extends SceneTree
## Regrava assets/ui_theme.tres a partir de UITheme.build(). Rodar depois de mudar ui_theme.gd:
## godot --headless --path . -s tools/bake_theme.gd
func _init() -> void:
	print("theme ", ResourceSaver.save(UITheme.build(), "res://assets/ui_theme.tres"))
	quit()
