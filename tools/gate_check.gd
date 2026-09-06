extends SceneTree

const LOG: String = "D:/code/tuitui/tuitui_run/tools/gate_check_out.txt"


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
	call_deferred("_go")


func _go() -> void:
	var backup: String = ""
	if FileAccess.file_exists("user://save.json"):
		var bf: FileAccess = FileAccess.open("user://save.json", FileAccess.READ)
		if bf != null:
			backup = bf.get_as_text()
	var save_n: Node = root.get_node("/root/Save")
	save_n.call("wipe_progress")
	var fail: PackedStringArray = PackedStringArray()
	change_scene_to_file("res://levels/main.tscn")
	await create_timer(0.6).timeout
	var p: Player = _player()
	if p == null or p.def == null or p.def.id != &"oc_a":
		fail.append("new_save_not_oc_a")
	elif p.jump_limit() != 2:
		fail.append("oc_a_jumps")
	if bool(save_n.call("is_owned", "oc_b")):
		fail.append("new_save_owns_b")
	var score: int = int(10000.0 * 0.04) + 10 * 12 + 2 * 80
	if score != 680:
		fail.append("score_formula")
	if Engine.physics_ticks_per_second != 60:
		fail.append("ticks")
	if not InputMap.has_action("jump"):
		fail.append("no_jump_action")
	if not InputMap.has_action("slide"):
		fail.append("no_slide_action")
	if not is_equal_approx(RunnerConfig.SCORE_DIST, 0.04) or RunnerConfig.SCORE_COIN != 12 or RunnerConfig.SCORE_RING != 80:
		fail.append("score_consts")
	var cat_n: Node = root.get_node_or_null("/root/Catalog")
	var need_anims: PackedStringArray = PackedStringArray(["idle", "run", "jump", "fall", "slide", "dead"])
	if cat_n == null:
		fail.append("no_catalog")
	else:
		for cid: String in ["oc_a", "oc_b", "oc_c"]:
			var def_v: Variant = cat_n.call("get_def", StringName(cid))
			var cdef: CharacterDef = def_v as CharacterDef
			if cdef == null or cdef.shop_portrait == null or cdef.sprite_frames == null:
				fail.append("oc_art_" + cid)
				continue
			for anim: String in need_anims:
				if not cdef.sprite_frames.has_animation(StringName(anim)):
					fail.append("oc_anim_" + cid + "_" + anim)
	if not ResourceLoader.exists("res://assets/ui/lobby_clean.png"):
		fail.append("no_lobby")
	if not ResourceLoader.exists("res://assets/backgrounds/sky_night.png"):
		fail.append("no_stage")
	var game_first: Node = current_scene
	if p != null and game_first != null:
		p.invincible = false
		p.has_shield = false
		p.kill(Vector2.ZERO)
		await create_timer(0.08).timeout
		if p.alive:
			fail.append("death_still_alive")
		if bool(game_first.get("running")):
			fail.append("death_still_running")
	var spawner_n: Node = current_scene.get_node_or_null("%ObstacleSpawner")
	if spawner_n == null or int(spawner_n.call("chunk_pool_size")) < 12:
		fail.append("chunk_pool")
	save_n.call("add_coins", 2400)
	if not bool(save_n.call("buy_with_coins", "oc_b")):
		fail.append("buy_b")
	if not bool(save_n.call("equip", "oc_b")):
		fail.append("equip_b")
	save_n.call("persist")
	save_n.call("reload_from_disk")
	await create_timer(0.2).timeout
	if str(save_n.get("equipped")) != "oc_b":
		fail.append("persist_b")
	change_scene_to_file("res://levels/main.tscn")
	await create_timer(0.6).timeout
	p = _player()
	if p == null or p.def == null or p.def.id != &"oc_b":
		fail.append("run_not_b")
	elif p.jump_limit() != 3:
		fail.append("oc_b_jumps")
	if not bool(save_n.call("grant_iap", "oc_c")):
		fail.append("grant_c")
	if not bool(save_n.call("equip", "oc_c")):
		fail.append("equip_c")
	change_scene_to_file("res://levels/main.tscn")
	await create_timer(0.6).timeout
	p = _player()
	if p == null or p.def == null or p.def.id != &"oc_c":
		fail.append("run_not_c")
	elif p.jump_limit() != 2:
		fail.append("oc_c_jumps")
	elif p.start_sprint_sec != 2.0:
		fail.append("oc_c_sprint")
	var game_n: Node = current_scene
	if game_n == null or float(game_n.get("_sprint_t")) <= 0.0:
		fail.append("sprint_armed")
	save_n.call("wipe_progress")
	if str(save_n.get("equipped")) != "oc_a":
		fail.append("wipe_equip")
	if not bool(save_n.call("is_owned", "oc_c")):
		fail.append("wipe_keeps_iap")
	if backup != "":
		var wf: FileAccess = FileAccess.open("user://save.json", FileAccess.WRITE)
		if wf != null:
			wf.store_string(backup)
		save_n.call("reload_from_disk")
	if fail.is_empty():
		_log("GATE_OK")
	else:
		_log("GATE_FAIL " + ",".join(fail))
	quit()


func _player() -> Player:
	if current_scene == null:
		return null
	return current_scene.get_node_or_null("%Player") as Player
