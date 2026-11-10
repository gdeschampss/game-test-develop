class_name UIWin
extends RefCounted
## Utilitários das janelas (mochila, personagem, menus): saber se alguma está aberta,
## travar/destravar o jogador e textos de dica (tooltip) dos itens.
## Toda janela entra no grupo "ui_window" e tem is_open() e close().


static func any_open(tree: SceneTree) -> bool:
	for w in tree.get_nodes_in_group("ui_window"):
		if w.call("is_open"):
			return true
	return false


static func close_all(tree: SceneTree) -> bool:
	var closed := false
	for w in tree.get_nodes_in_group("ui_window"):
		if w.call("is_open"):
			w.call("close")
			closed = true
	return closed


static func sync_lock(tree: SceneTree) -> void:
	var p := tree.get_first_node_in_group("player") as Player
	if p:
		p.set_input_locked(any_open(tree))


static func rarity_color(r: String) -> Color:
	return UITheme.RARITY.get(r, Color.WHITE)


static func hex(c: Color) -> String:
	return c.to_html(false)


## Dica de material
static func material_tip(id: String, count: int, unextracted := false) -> String:
	var r: String = Game.MATERIAL_RARITY.get(id, "comum")
	var t := "[font_size=20][color=#%s]%s[/color][/font_size]\n[color=#bbbbbb]Material · %s[/color]\nQuantidade: %d" % [hex(rarity_color(r)), Game.MATERIALS.get(id, id), r.capitalize(), count]
	var uses: Array[String] = []
	for rec in Game.RECIPES:
		if rec["mats"].has(id):
			uses.append(rec["name"])
	if not uses.is_empty():
		t += "\n[color=#e8c060]Ferreiro: %s[/color]" % ", ".join(uses)
	if unextracted:
		t += "\n[color=#ff7060]Ainda não extraído — perde se morrer[/color]"
	return t


## Dica de peça de armadura
static func gear_tip(id: String, action := "") -> String:
	var r := Game.recipe(id)
	if r.is_empty():
		return ""
	var c := rarity_color(Game.gear_rarity(r))
	var t := "[font_size=20][color=#%s]%s[/color][/font_size]\n%s\n[color=#80ff80]+%d Poder de Armadura[/color]\n[color=#bbbbbb](+%d vida, +%d%% dano)[/color]" % [hex(c), r["name"], Game.SLOT_NAMES[r["slot"]], r["pa"], int(r["pa"]) * 2, int(r["pa"])]
	if action != "":
		t += "\n[color=#e8c060]%s[/color]" % action
	return t
