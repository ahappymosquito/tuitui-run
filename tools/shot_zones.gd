extends SceneTree

const OUT: String = "D:/code/tuitui/tuitui_run/tools/shots/60_touch_zones.png"


func _initialize() -> void:
	root.ready.connect(_go, CONNECT_ONE_SHOT)


func _go() -> void:
	change_scene_to_file("res://levels/main.tscn")
	await create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	var img: Image = root.get_viewport().get_texture().get_image()
	var err: Error = img.save_png(OUT)
	print("shot %s %dx%d err=%s" % [OUT, img.get_width(), img.get_height(), err])
	quit()
