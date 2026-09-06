extends SceneTree


func _initialize() -> void:
	root.ready.connect(_go, CONNECT_ONE_SHOT)


func _go() -> void:
	change_scene_to_file("res://levels/main.tscn")
	await create_timer(0.6).timeout
	var scene: Node = current_scene
	if scene == null:
		print("DEMO_FAIL no_scene")
		quit()
		return
	var tz: Node = scene.get_node_or_null("%TouchZones")
	var slide: Node = scene.get_node_or_null("%SlideZone")
	var jump: Node = scene.get_node_or_null("%JumpZone")
	var player: Node = scene.get_node_or_null("%Player")
	var px: float = -1.0
	if player is Node2D:
		px = (player as Node2D).position.x
	var vw: float = root.get_visible_rect().size.x
	var expect_x: float = vw * 0.22
	print("touchzones=", tz != null)
	print("slidezone=", slide != null)
	print("jumpzone=", jump != null)
	print("player_x=", px, " expect=", expect_x, " vw=", vw)
	var ok: bool = tz != null and slide != null and jump != null
	ok = ok and absf(px - expect_x) < 2.0
	print("DEMO_OK" if ok else "DEMO_FAIL")
	quit()
