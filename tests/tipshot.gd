extends SceneTree
# 0.56: снимок всплывающей подсказки: desk=N match=текст out=путь.png (tip_delay=0 — сразу)
var found: Control = null
func _init():
	var desk := 0
	var outp := "/tmp/tip.png"
	var match_t := "\n"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("desk="): desk = int(String(a).substr(5))
		if String(a).begins_with("out="): outp = String(a).substr(4)
		if String(a).begins_with("match="): match_t = String(a).substr(6)
	var g = load("res://main.gd").new()
	root.add_child(g)
	g.game_opts["tip_delay"] = 0
	for i in 5: await process_frame
	for m in 2:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
	if g.election_open: g.election_continue()
	if not g.current_event.is_empty(): g.choose(0)
	g.show_desk(desk)
	node_added.connect(func(n: Node) -> void:
		if n is Label and n.get_parent() is PopupPanel: print("TIP NODE ", n.get_class(), " ", n.get_parent().theme_type_variation))
	for i in 8: await process_frame
	scan(g, match_t)
	if found == null:
		dbg(g, 0)
		print("no control"); quit(); return
	print("tip of ", found.get_class(), ": ", found.tooltip_text.left(60))
	var c: Vector2 = found.get_global_rect().get_center()
	for k in 3:
		var ev := InputEventMouseMotion.new(); ev.position = c + Vector2(k, 0); ev.global_position = ev.position
		root.push_input(ev)
		await create_timer(0.3).timeout
	await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png(outp)
	print("saved ", outp)
	quit()
func scan(n: Node, t: String) -> void:
	if found != null: return
	if n is Control and (n as Control).is_visible_in_tree() and (n as Control).tooltip_text.contains(t) and (n as Control).get_global_rect().size.x > 10:
		var r := (n as Control).get_global_rect()
		if r.position.x >= 0 and r.position.y >= 0:
			found = n; return
	for ch in n.get_children(): scan(ch, t)
var nd := 0
func dbg(n: Node, d: int) -> void:
	if nd > 15: return
	if n is Control and (n as Control).tooltip_text != "":
		nd += 1
		print("C ", n.get_class(), " vis=", (n as Control).is_visible_in_tree(), " r=", (n as Control).get_global_rect(), " t=", (n as Control).tooltip_text.left(30).replace("\n", "|"))
	for ch in n.get_children(): dbg(ch, d + 1)
