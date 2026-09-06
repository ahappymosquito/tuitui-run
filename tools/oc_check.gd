extends SceneTree

const LOG: String = "D:/code/tuitui/tuitui_run/tools/oc_check_out.txt"


func _log(t: String) -> void:
	var prev: String = ""
	if FileAccess.file_exists(LOG):
		var rf: FileAccess = FileAccess.open(LOG, FileAccess.READ)
		if rf != null:
			prev = rf.get_as_text()
	var wf: FileAccess = FileAccess.open(LOG, FileAccess.WRITE)
	if wf != null:
		wf.store_string(prev + t + "\n")
	print(t)


func _initialize() -> void:
	_log("init")
	call_deferred("_go")


func _go() -> void:
	change_scene_to_file("res://levels/main.tscn")
	await create_timer(0.7).timeout
	var scene: Node = current_scene
	if scene == null:
		_log("DEMO_FAIL no_scene")
		quit()
		return
	var player: Player = scene.get_node_or_null("%Player") as Player
	if player == null:
		_log("OC_FAIL no_player")
		quit()
		return
	var def: CharacterDef = player.def
	_log("player_def=" + (String(def.id) if def != null else "null"))
	_log("max_jumps=" + str(player.jumps_used))
	var slide: bool = def != null and def.sprite_frames != null and def.sprite_frames.has_animation(&"slide")
	_log("has_slide=" + str(slide))
	_log("col_slide=" + str(player.get_node_or_null("%ColSlide") != null))
	var save_n: Node = root.get_node_or_null("/root/Save")
	var owned: PackedStringArray = PackedStringArray()
	if save_n != null:
		owned = save_n.get("owned") as PackedStringArray
		_log("owned=" + ",".join(owned))
		_log("equipped=" + str(save_n.get("equipped")))
		_log("coins=" + str(save_n.get("coins")))
	var ok: bool = def != null and def.id == &"oc_a" and def.max_jumps == 2 and slide
	ok = ok and owned.has("oc_a")
	_log("OC_OK" if ok else "OC_FAIL")
	quit()
