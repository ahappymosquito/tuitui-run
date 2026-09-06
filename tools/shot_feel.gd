extends SceneTree

const OUT: String = "D:/code/tuitui/tuitui_run/tools/shots/"


func _initialize() -> void:
	call_deferred("_go")


func _go() -> void:
	change_scene_to_file("res://ui/home.tscn")
	await create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	_save("70_home.png")
	change_scene_to_file("res://levels/main.tscn")
	await create_timer(0.7).timeout
	Input.action_press("jump")
	await create_timer(0.16).timeout
	Input.action_release("jump")
	await RenderingServer.frame_post_draw
	_save("71_jump.png")
	quit()


func _save(name: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	var path: String = OUT + name
	var err: Error = img.save_png(path)
	print("shot %s %dx%d err=%s" % [path, img.get_width(), img.get_height(), err])
