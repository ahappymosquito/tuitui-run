extends SceneTree

## Headless viewport dumps of home + in-run for ship evidence.
## TUITUI_SHOT_DIR must be set by the caller.


func _initialize() -> void:
	call_deferred("_go")


func _go() -> void:
	var dest: String = OS.get_environment("TUITUI_SHOT_DIR")
	if dest == "":
		print("SHIP_SHOTS_FAIL no_dir")
		quit()
		return
	change_scene_to_file("res://ui/home.tscn")
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	_save(dest + "/cute_home.png")
	change_scene_to_file("res://levels/main.tscn")
	await create_timer(1.1).timeout
	await RenderingServer.frame_post_draw
	_save(dest + "/cute_run.png")
	print("SHIP_SHOTS_OK")
	quit()


func _save(path: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	var err: Error = img.save_png(path)
	print("shot %s %dx%d err=%s" % [path, img.get_width(), img.get_height(), err])
