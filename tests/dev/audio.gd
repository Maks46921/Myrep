extends SceneTree
# dev: загрузка музыки и звуков (запускать НЕ headless: xvfb + opengl3)
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	print("music files: ", g.music_list)
	print("music playing: ", g.music_player != null and g.music_player.playing, " stream ", g.music_player.stream if g.music_player else null)
	for n in ["click", "event", "election", "good", "bad"]:
		var st = g.audio_load("res://audio/sfx/%s.ogg" % n)
		print(n, " -> ", st, " len ", st.get_length() if st else -1)
	g.sfx("event")
	await create_timer(0.3).timeout
	quit()
