extends SceneTree

const OUT: String = "D:/code/tuitui/tuitui_run/tools/shots/"


func _initialize() -> void:
	root.ready.connect(_go, CONNECT_ONE_SHOT)


func _go() -> void:
	change_scene_to_file("res://levels/main.tscn")
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	_save_now("56_intro.png")
	var game: Node = current_scene
	if game != null and game.has_node("%HUD"):
		var hud: Node = game.get_node("%HUD")
		if hud.has_method("show_game_over"):
			hud.call("show_game_over", 1234, true, 80, 240, 160, 20)
			await create_timer(0.35).timeout
			await RenderingServer.frame_post_draw
			_save_now("56_over.png")
	quit()


func _save_now(name: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	var path: String = OUT + name
	var err: Error = img.save_png(path)
	print("shot %s %dx%d err=%s" % [path, img.get_width(), img.get_height(), err])




